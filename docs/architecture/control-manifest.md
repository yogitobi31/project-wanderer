# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-05-07
> **Manifest Version**: 2026-05-07
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns

- **Autoload 등록 순서를 반드시 지킨다**: EventBus(1) → ItemDB(2) → NPCRegistry(3) → PartyManager(4) → Inventory(5) → QuestManager(6) → InputMapManager(7) → SceneTransitionManager(8) → **SaveManager(9)** → AudioManager(10). 순서 변경 시 ADR-0007 / ADR-0002 Supersede 필요. — source: ADR-0002, ADR-0007
- **NPCRegistry 접근 전 `is_initialized()` 확인**: `registry_initialized` 신호 이전에 `get_npc()` / `set_state()`를 호출하면 경고 로그 발생. 초기화 이전 접근이 필요한 시스템은 `await NPCRegistry.registry_initialized` 사용. — source: ADR-0002
- **모든 Autoload는 `src/core/[snake_case_name].gd`에 위치**: 씬 파일 없이 스크립트만으로 등록 (`*` 접두사). — source: ADR-0002
- **SceneTransitionManager FSM 4-state를 준수**: `IDLE → FADING_OUT → LOADING → FADING_IN → IDLE`. 상태를 건너뛰거나 역방향 전환 금지. — source: ADR-0003
- **씬 전환은 비동기 로딩 사용**: `ResourceLoader.load_threaded_request()` → `_process()`에서 `load_threaded_get_status()` 폴링 → 완료 시 `change_scene_to_packed()`. — source: ADR-0003
- **페이드 상수를 고정값으로 사용**: `FADE_OUT_DURATION = 0.3s`, `FADE_IN_DURATION = 0.4s`. — source: ADR-0003
- **전환 중 PROCESS_MODE_DISABLED 적용 대상**: PlayerController, CompanionAI, EnemyAI, CombatEncounter. 예외: SceneTransitionManager(`PROCESS_MODE_ALWAYS`), AudioManager(BGM fade 유지). — source: ADR-0003
- **모든 맵 씬에 `SpawnPoint_Default` 노드 필수**: `"spawn_points"` 그룹에 등록. 폴백 규칙: spawn_id 미존재 시 `SpawnPoint_Default`로 이동. 둘 다 없으면 `push_error` 후 Vector2.ZERO. — source: ADR-0003
- **세이브 포맷은 JSON + FileAccess**: `JSON.stringify()` / `JSON.parse_string()` 사용. `user://saves/save_001.json`에 저장. — source: ADR-0007
- **`FileAccess.open()` 반환값 null 체크 필수**: Godot 4.x에서 실패 시 null 반환 (Godot 3 ERR_* 패턴 혼용 금지). `if file == null: push_error(...)` 가드 필수. — source: ADR-0007
- **데이터 Autoload는 `get_save_data()` / `load_save_data()` 계약 구현**: 직렬화 대상: QuestManager, Inventory, NPCRegistry, PartyManager. 반환 딕셔너리는 JSON-serializable 타입만 포함 (String, int, float, bool, Array, Dictionary). — source: ADR-0007
- **저장 파일에 `SAVE_VERSION` 필드 포함**: 포맷 버전 마이그레이션 기반. 현재 값: `1`. — source: ADR-0007
- **저장 트리거는 명시적 SavePoint 인터랙션**: 자동 저장 없음 (Post-MVP 스코프). — source: ADR-0007
- **SceneTransitionManager는 씬 전환 완료 후 `SaveManager.record_player_location(scene_path, spawn_name)` 호출 필수**: 플레이어 위치 영속 관리. — source: ADR-0007
- **StringName → String 명시적 캐스팅**: `load_save_data()` 구현 시 JSON 로드 후 `StringName(data["key"])` 캐스팅 필수. — source: ADR-0007

### Forbidden Approaches

- **Never Autoload 등록 순서를 project.godot에서 임의 변경** — 초기화 타이밍 버그 발생. 변경 필요 시 ADR-0002 Supersede 후 팀 공유. — source: ADR-0002
- **Never TileMap 노드 사용** — Godot 4.3에서 deprecated. 모든 맵에서 `TileMapLayer` 사용. — source: ADR-0003
- **Never `change_scene_to_file()` 직접 호출(동기 로딩)** — 대형 씬에서 프레임 스킵. 반드시 SceneTransitionManager를 통해 전환. — source: ADR-0003
- **Never 대화 중 씬 전환** — 포탈 진입 핸들러에서 `DialogueManager.is_active` 체크 필수. — source: ADR-0003
- **Never `var_to_bytes()` 바이너리 직렬화** — 사람이 읽을 수 없어 디버그 불가. JSON 사용. — source: ADR-0007
- **Never `ConfigFile` 또는 `ResourceSaver`로 세이브 데이터 저장** — JSON + FileAccess가 지정 포맷. — source: ADR-0007
- **Never `FileAccess.open()` null 반환 무시** — 크래시 원인. 항상 null 체크 후 처리. — source: ADR-0007

### Performance Guardrails

- **저장/로드**: < 5ms / < 10ms 목표. 씬 전환 블랙스크린 중 실행하여 사용자 체감 없도록. — source: ADR-0007

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision, stats*

### Required Patterns

- **Autoload 허용 기준 (Track 1 — 데이터 레지스트리)**: 신규 Autoload 추가 전 4가지 기준 체크: (1) 순수 데이터 레지스트리, (2) 3개+ 비관련 다운스트림, (3) API 10개 이하, (4) 단순 초기화. — source: ADR-0001
- **Autoload 허용 기준 (Track 2 — 서비스 싱글톤)**: 4가지 기준 체크: S-1 전역 생명주기 필요, S-2 씬 계층 주입 불가, S-3 단일 서비스 책임, S-4 순환 의존 없음. — source: ADR-0002
- **NPCRecord 스냅샷 복사 시 `duplicate_deep()` 필수**: 얕은 복사는 레지스트리 데이터 오염 위험 (Godot 4.5+ API). NPCRecord의 모든 Resource 타입 필드는 `_init()`에서 초기화 필수. — source: ADR-0001
- **Physics 레이어 번호 고정값 사용**: world(1), player_body(2), enemy_body(3), player_hitbox(4), enemy_hitbox(5), player_hurtbox(6), enemy_hurtbox(7). 이 번호는 프로젝트 전체 단일 진실 출처. — source: ADR-0004
- **캐릭터 루트 노드 구조 준수 (플레이어·동료·적 공통)**:
  ```
  CharacterBody2D (Layer: player_body 또는 enemy_body. Mask: world)
  ├── CollisionShape2D
  ├── HealthComponent
  ├── HurtboxArea2D  (Layer: *_hurtbox. Mask: 상대 *_hitbox)
  │   └── CollisionShape2D
  └── HitboxArea2D   (Layer: *_hitbox. Mask: 상대 *_hurtbox. 기본 monitoring=false)
      └── CollisionShape2D
  ```
  — source: ADR-0004
- **Hitbox는 데미지 계산 안 함**: `HitboxArea2D.area_entered` → `hit_confirmed(attack_data)` 신호 전달 → HealthComponent가 데미지 계산. Hitbox는 신호 전달만. — source: ADR-0004
- **`attack_data` Dictionary 스펙 준수**: `{"damage": int, "knockback": float, "source": Node}`. — source: ADR-0004
- **데미지 공식**: `final_damage = max(1, attack_data["damage"] - target_defense)`. 방어력 ≥ 공격력이어도 최소 1 데미지. — source: ADR-0004
- **Iframes 상수**: `IFRAMES_DURATION = 0.5초`. HealthComponent 내부 Timer 노드로 관리. 피격 시 `HurtboxArea2D.monitoring = false` → 0.5초 후 `true`. — source: ADR-0004
- **HitboxArea2D 기본 `monitoring = false`**: 공격 애니메이션 지정 프레임에서만 `true`, 프레임 종료 시 즉시 `false`. — source: ADR-0004
- **`CharacterStats` 클래스 선언**: `class_name CharacterStats extends Resource`. 파일 위치: `src/core/stats/character_stats.gd`. — source: ADR-0005
- **`@export` 필드 (base_*)**: `base_max_hp: int = 80`, `base_atk: int = 20`, `base_def: int = 8`, `base_spd: float = 130.0`. Inspector 편집 가능, `.tres`에 직렬화. — source: ADR-0005
- **computed 프로퍼티만 외부에서 읽음**: `max_hp`, `atk`, `def`, `spd`. 클램핑 포함: max_hp[1,9999], atk[0,999], def[0,999], spd[10.0,600.0]. 다운스트림에서 `base_*` / `mod_*` 직접 읽기 금지. — source: ADR-0005
- **런타임 CharacterStats 인스턴스는 `duplicate()`로 생성**: `stats = stats_template.duplicate()`. Resource 타입 필드 추가 시 `duplicate(true)` (deep)으로 변경 필요. — source: ADR-0005
- **`stats_changed` 신호**: `signal stats_changed(stat_name: StringName)`. `base_*`/`mod_*` 변경 시 emit. 신호 핸들러 안에서 `base_*`/`mod_*` 쓰기 금지 (신호 루프). — source: ADR-0005
- **GrowthRate는 별도 Resource**: `class_name GrowthRate extends Resource`. CharacterStats와 분리. 레벨업 시스템만 읽음. — source: ADR-0005
- **MVP `mod_*` setter에 `push_warning()` 추가**: 의도치 않은 쓰기 조기 발견. — source: ADR-0005

### Forbidden Approaches

- **Never Autoload를 신호 버스로 사용** — 이벤트 전달은 EventBus 또는 직접 신호 연결 사용. — source: ADR-0001
- **Never Autoload를 통한 교차 시스템 상태 쓰기** — 소유 시스템만 해당 Autoload 상태를 쓴다. — source: ADR-0001
- **Never Autoload 간 순환 의존** — GDScript 로더 제한. 의존 방향은 단방향. — source: ADR-0001
- **Never 4기준 체크 없이 신규 Autoload 추가** — 모든 신규 Autoload는 ADR에 기준 통과 기록 필수. — source: ADR-0001
- **Never PhysicsBody 직접 충돌로 데미지 처리** — 이동 물리와 전투 판정 분리 필수. 전투 판정은 HitboxArea2D/HurtboxArea2D만 사용. — source: ADR-0004
- **Never 캐릭터 종류별 별도 Health 클래스** — PlayerHealth, CompanionHealth, EnemyHealth 분리 금지. 단일 HealthComponent 사용. — source: ADR-0004
- **Never HitboxArea2D `monitoring = true` 상시 활성** — 항상 기본 false, 애니메이션 프레임에서만 활성화. — source: ADR-0004
- **Never 공통 루트 노드 구조 이탈** — CharacterBody2D + HealthComponent + HurtboxArea2D + HitboxArea2D 구조에서 벗어난 캐릭터 씬 금지. — source: ADR-0004
- **Never 다운스트림에서 `base_*` / `mod_*` 직접 읽기** — 반드시 computed 프로퍼티(`max_hp`, `atk`, `def`, `spd`)를 통해 읽는다. 클램핑 우회 방지. — source: ADR-0005
- **Never 런타임에서 `.tres` 원본 수정** — 템플릿 파일은 읽기 전용. 항상 `duplicate()`으로 인스턴스 생성 후 수정. — source: ADR-0005
- **Never `stats_changed` 핸들러 안에서 `base_*` / `mod_*` 쓰기** — 재진입 신호 루프 발생. — source: ADR-0005
- **Never 스탯을 Dictionary로 저장** — 타입 안전성 없음, 오타 런타임 오류. CharacterStats Resource 사용. — source: ADR-0005

### Performance Guardrails

- **프레임 예산**: 16.6ms (60fps). CharacterStats computed 프로퍼티·Autoload O(1) 조회는 무시 가능. HealthComponent Iframes 토글은 `set()` 1회 — 측정 불필요. — source: ADR-0004, ADR-0005

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, dialogue, quest, companion recruitment*

### Required Patterns

- **NavigationAgent2D 공통 사용 패턴**:
  ```gdscript
  if not navigation_agent.is_navigation_finished():
      var next_pos = navigation_agent.get_next_path_position()
      velocity = (next_pos - global_position).normalized() * stats.spd
      move_and_slide()
  ```
  — source: ADR-0006
- **`avoidance_enabled` 기본값 `false`**: 동료 3명 + 적 4명 동시 처리 프로파일링 통과 후에만 활성화. — source: ADR-0006
- **CompanionAI FSM 상태**: `FOLLOWING → CHASING → ATTACKING ↔ (DEAD)`. 상태별 target_position 및 이동/공격 계약은 ADR-0006 표 참조. — source: ADR-0006
- **EnemyAI FSM 상태**: `IDLE → CHASING → ATTACKING ↔ (DEAD)`. 타겟 우선순위: 플레이어 > 가장 가까운 동료. — source: ADR-0006
- **DetectionArea2D 레이어 설정**: 동료 DetectionArea2D: Layer=player_body(2), Mask=enemy_body(3). 적 DetectionArea2D: Layer=enemy_body(3), Mask=player_body(2). — source: ADR-0006
- **CombatEncounter 신호 계약**: 구역 내 모든 적 `health_depleted()` 시 `combat_cleared(encounter_id: StringName)` 정확히 1회 발행. — source: ADR-0006
- **EnemySpawnZone 적 수 공식**: `enemy_count = base_enemy_count(3) + companion_count × ENEMY_SCALE_PER_COMPANION(1)`. `PartyManager.companion_count` 읽기. — source: ADR-0006
- **NavigationRegion2D bake 필수**: 맵 씬 변경 시마다 rebake. TileMapLayer 하위에 배치. — source: ADR-0006
- **대화 시작/종료 시 입력 컨텍스트 전환**:
  ```
  대화 시작: InputMapManager.set_ui_active(true) → grab_focus() → typewriter 시작
  대화 종료: dialogue_completed emit → InputMapManager.set_ui_active(false)
  ```
  — source: ADR-0003
- **DialogueManager CanvasLayer 번호**: `layer = 10` (HUD보다 위). — source: ADR-0003
- **grab_focus() Godot 4.6 검증 완료**: CanvasLayer layer=10의 ChoiceButton에서 `grab_focus()` 정상 동작. `ui_accept` 입력이 ChoiceButton에 전달됨 확인 (spike-grab-focus PASS 2026-05-07). — source: ADR-0003
- **`_input()` 안에서 포커스 즉시 읽기 금지**: `get_viewport().gui_get_focus_owner()`는 Godot이 네비게이션 처리 전 값을 반환. 반드시 `call_deferred()` 사용. — source: spike-grab-focus 2026-05-07

### Forbidden Approaches

- **Never Steering Behavior로 NavigationAgent2D 대체** — 장애물 우회 불가. NavigationAgent2D 없이 직접 방향 계산 금지. — source: ADR-0006
- **Never `avoidance_enabled = true` 기본 설정** — 60fps 수렴 미검증 상태에서 활성화 금지. 프로파일링 후 결정. — source: ADR-0006
- **Never 포탈 진입 조건 미체크** — 포탈 `body_entered` 핸들러에서 반드시 `DialogueManager.is_active` 확인 후 전환 요청. — source: ADR-0003

### Performance Guardrails

- **NavigationAgent2D**: 동료 3명 + 적 6명(최대) 동시 활성 시 60fps(16.6ms) 유지 목표. avoidance 비활성 기본값으로 보수적 운용. — source: ADR-0006
- **AI 경로 갱신**: `target_position` 매 프레임 갱신은 허용. 경로 계산은 NavigationServer2D 자체 캐싱 활용. — source: ADR-0006

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, animations*

### Required Patterns

- **Compatibility Renderer 사용**: 2D 픽셀 아트 최적, 저사양 호환. D3D12/Vulkan 불필요. — source: technical-preferences.md
- **오디오 버스 3개 구조**: Master, Music, SFX. `AudioManager.set_volume(bus_name, linear_value)` 제어. — source: ADR-0002
- **SFX pool 8개**: 동시 재생 지원. 모두 사용 중이면 가장 오래된 것 재사용. — source: ADR-0002
- **AudioManager 인터페이스**: `play_sfx(sfx_id)`, `play_bgm(bgm_id)`, `stop_bgm()`. — source: ADR-0002
- **BGM 페이드 타이밍**: BGM_FADE_OUT(0.3s) / BGM_FADE_IN(0.4s) — SceneTransitionManager 페이드와 동기화. — source: ADR-0003

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController`, `CompanionData` |
| Variables | snake_case | `move_speed`, `current_health` |
| Functions | snake_case | `take_damage()`, `join_party()` |
| Signals/Events | snake_case 과거형 | `health_changed`, `companion_joined`, `quest_completed` |
| Files | snake_case (class명 일치) | `player_controller.gd`, `companion_data.gd` |
| Scenes/Prefabs | PascalCase (루트 노드명 일치) | `PlayerController.tscn`, `CompanionBase.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH`, `BASE_MOVE_SPEED` |

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16.6ms |
| Draw calls | < 200 (2D 픽셀 아트, CanvasItem 배칭 활용) |
| Memory ceiling | 512 MB |

### Approved Libraries / Addons

- **GUT** (Godot Unit Testing) — 테스트 전용, 런타임 제외

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or must not be used in this project:

| Forbidden | Use Instead | Source |
|-----------|-------------|--------|
| `TileMap` node | `TileMapLayer` | deprecated-apis.md (4.3+) |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | deprecated-apis.md (4.0+) |
| `YSort` node | `Node2D.y_sort_enabled` | deprecated-apis.md (4.0+) |
| `Navigation2D` | `NavigationServer2D` | deprecated-apis.md (4.0+) |
| `yield()` | `await signal` | deprecated-apis.md (4.0+) |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | deprecated-apis.md (4.0+) |
| `PackedScene.instance()` | `PackedScene.instantiate()` | deprecated-apis.md (4.0+) |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | deprecated-apis.md (4.0+) |
| `duplicate()` for nested Resources | `duplicate_deep()` | deprecated-apis.md (4.5+) |
| `$NodePath` in `_process()` | `@onready var` cached reference | deprecated-apis.md |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | deprecated-apis.md |
| `Texture2D` in shader params | `Texture` base type | deprecated-apis.md (4.4+) |

### Cross-Cutting Constraints

- **정적 타입 필수**: 모든 변수·함수·신호에 타입 힌트 선언. 타입 없는 코드는 PR 거부 대상.
- **Autoload 의존 방향**: Foundation → Core → Feature → Presentation 단방향. 역방향 의존 금지.
- **테스트 프레임워크**: GUT. 로직 스토리(공식, AI, 상태 머신)는 자동화 단위 테스트 필수 (BLOCKING). 시각/Feel 검증은 수동 플레이테스트 + 스크린샷.
- **신호 연결**: 항상 Callable 기반 타입 연결 사용. String 기반 `connect()` 금지.
- **데이터 주도 설계**: 게임플레이 수치는 외부 설정 파일(`.tres`, `.json`)에서 관리. 코드에 하드코딩 금지.
- **`@onready` 노드 캐시**: `_process()` / `_physics_process()` 내부에서 `$NodePath` 조회 금지. `@onready var` 캐시 사용.
- **Autoload 순서 변경 시**: ADR-0002 Supersede 후 팀 전체에 공유. project.godot 직접 수정 금지.
