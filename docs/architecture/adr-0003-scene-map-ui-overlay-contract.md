# ADR-0003: 씬 전환·맵 구조·UI 오버레이 계약

## Status
Accepted

## Date
2026-04-27

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI / Tilemap |
| **Knowledge Risk** | HIGH — TileMapLayer (4.3 변경), grab_focus() dual-focus (4.6 변경) |
| **References Consulted** | `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | `TileMapLayer` (TileMap 대체, 4.3+); `grab_focus()` dual-focus 분리 동작 (4.6) |
| **Verification Required** | (1) CanvasLayer 내 Control 노드에서 grab_focus() 호출 시 gamepad 포커스가 올바르게 이동하는지 Godot 4.6 에디터에서 확인. (2) TileMapLayer 기반 맵에서 NavigationRegion2D bake가 정상 동작하는지 확인. |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (Accepted), ADR-0002 (Accepted) — SceneTransitionManager Autoload 등록 순서 |
| **Enables** | 맵 씬 구현, DialogueManager 구현, 씬 전환 구현 |
| **Blocks** | 맵 씬(.tscn) 작업 및 UI 오버레이 구현 |
| **Ordering Note** | 맵 씬에 TileMapLayer를 사용하기 전 이 ADR이 Accepted여야 한다. |

## Context

### Problem Statement

씬 전환, 맵 구조, UI 오버레이(DialogueManager)는 서로 연동되며 아래 세 가지 미결 사항이 있다:

1. **TileMap vs TileMapLayer**: Godot 4.3에서 TileMap이 TileMapLayer로 대체됨. 명문화하지 않으면 구현자가 TileMap을 사용할 수 있다.
2. **SceneTransitionManager 계약**: PROCESS_MODE_DISABLED 적용 범위, 폴백 SpawnPoint 규칙 미확정.
3. **grab_focus() dual-focus (4.6)**: CanvasLayer 내 Control 노드에서 grab_focus() 호출 시 keyboard/gamepad focus가 분리되어 동작한다. DialogueManager가 Steam Deck에서 정상 동작하려면 이 동작을 명시해야 한다.

### Constraints

- TileMap 노드는 Godot 4.3 이후 deprecated — 사용 금지
- grab_focus()는 4.6에서 keyboard focus와 gamepad focus를 독립적으로 관리
- 씬 전환 중 물리/입력 처리는 완전히 차단되어야 함

### Requirements

- TR-scene-001~004: SceneTransitionManager 4-state FSM + 비동기 로딩 + SpawnPoint 계약
- TR-map-001~003: TileMapLayer, NavigationRegion2D, 포탈 조건
- TR-dial-001: DialogueManager CanvasLayer + grab_focus() + is_active 차단

## Decision

### 씬 전환 계약 (SceneTransitionManager)

**FSM 상태 전환**:
```
IDLE → FADING_OUT → LOADING → FADING_IN → IDLE
```

**PROCESS_MODE_DISABLED 적용**: 전환 중 씬 루트에 `PROCESS_MODE_DISABLED` 설정 (`set_process_mode(PROCESS_MODE_DISABLED)`)
- 적용: PlayerController, CompanionAI, EnemyAI, CombatEncounter
- 제외: SceneTransitionManager (PROCESS_MODE_ALWAYS), AudioManager (BGM fade 계속 실행)
- 주의: `get_tree().paused`는 사용하지 않음 — 씬 전체가 아닌 개별 노드 제어가 목적

**비동기 로딩**: `ResourceLoader.load_threaded_request()` → `_process()`에서 `load_threaded_get_status()` 폴링 → 완료 시 `change_scene_to_packed()`.

**SpawnPoint 계약**:
- 모든 맵 씬은 `"spawn_points"` 그룹에 `SpawnPoint_Default` 노드를 반드시 포함
- 추가 포인트: `SpawnPoint_{id}` (id = 포탈 출구 식별자)
- 폴백 규칙: `spawn_id`에 해당하는 노드가 없으면 `SpawnPoint_Default`로 이동. `SpawnPoint_Default`도 없으면 `push_error` 후 Vector2.ZERO

**타이밍 상수**:
- `FADE_OUT_DURATION = 0.3s`
- `FADE_IN_DURATION = 0.4s`
- BGM_FADE_OUT(0.3s) / BGM_FADE_IN(0.4s) — AudioManager와 동기화

### 맵 구조 계약

**TileMapLayer 강제**: 모든 맵 씬에서 `TileMap` 노드 사용 금지. `TileMapLayer`를 사용한다.

**필수 노드 구성 (모든 맵 씬)**:
```
MapScene (Node2D)
├── TileMapLayer              ← 타일 렌더링 + 충돌
├── NavigationRegion2D        ← AI 내비게이션 메시
├── SpawnPoints (Node2D)      ← 그룹: "spawn_points"
│   ├── SpawnPoint_Default (Marker2D)
│   └── SpawnPoint_{id} (Marker2D)   [포탈 출구마다]
├── Portals (Node2D)
│   └── Portal_{target} (Area2D)     [씬 전환 트리거]
└── EnemySpawnZones (Node2D)
    └── EnemySpawnZone (Area2D)      [그룹: "enemy_spawn_zones"]
```

**포탈 진입 조건**:
```gdscript
func _on_portal_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"): return
    if DialogueManager.is_active: return
    SceneTransitionManager.transition_to(target_scene, spawn_id)
```

### UI 오버레이 계약 (DialogueManager + grab_focus)

**CanvasLayer 레이어 번호**: `layer = 10` (HUD보다 위, 전환 overlay보다 아래)

**grab_focus() 처리 (Godot 4.6 dual-focus)**:
- Godot 4.6에서 `grab_focus()`는 keyboard focus만 이동하며 gamepad focus는 독립적으로 동작할 수 있음
- 검증 완료 전 fallback: `ui_accept` 액션으로 대화 진행하며 포커스 의존 없이 구현
- 검증 후 동작이 확인되면 이 ADR을 업데이트한다

**is_active 차단 계약** (순서 고정):
```
대화 시작: InputMapManager.set_ui_active(true) → grab_focus() → typewriter 시작
대화 종료: dialogue_completed emit → InputMapManager.set_ui_active(false)
```

### Architecture Diagram

```
[포탈 Area2D]
  body_entered → DialogueManager.is_active 체크
                 └─ false → SceneTransitionManager.transition_to(scene, spawn_id)
                              FADING_OUT (0.3s) → tree.paused = true
                              LOADING (ResourceLoader async poll)
                              FADING_IN (0.4s) → tree.paused = false
                              PlayerController.set_spawn_position(SpawnPoint_{id})
                              AudioManager.play_bgm(map_bgm)

[NPC 상호작용]
  → DialogueManager.start_dialogue(npc_id)
    InputMapManager.set_ui_active(true)
    grab_focus() [⚠️ 4.6 dual-focus 검증 필요 — fallback: ui_accept]
    typewriter 출력 (0.04s/글자)
    dialogue_completed(npc_id) emit
    InputMapManager.set_ui_active(false)
```

## Alternatives Considered

### Alternative 1: TileMap 유지 (deprecated)

- **Description**: 기존 TileMap 노드 사용 계속
- **Pros**: 없음
- **Cons**: Godot 4.3에서 deprecated, 미래 제거 예정
- **Rejection Reason**: deprecated API 사용 금지 원칙

### Alternative 2: 동기 씬 로딩 (change_scene_to_file)

- **Description**: ResourceLoader 없이 change_scene_to_file() 즉시 전환
- **Pros**: 구현 단순
- **Cons**: 대형 씬에서 프레임 스킵 발생, 페이드 연출 불가
- **Rejection Reason**: 60fps 유지 요건 위반 위험

### Alternative 3: grab_focus 없이 gamepad 처리 (영구)

- **Description**: 포커스 없이 ui_accept 액션만으로 대화 진행 (영구 방식)
- **Pros**: dual-focus 위험 회피
- **Cons**: Steam Deck UX 열화, gamepad 접근성 저하
- **Rejection Reason**: gamepad 지원 요건 위반. 검증 전 임시 fallback으로만 채택

## Consequences

### Positive

- TileMap 금지 명문화로 deprecated API 사용 사전 차단
- SpawnPoint 폴백 규칙으로 씬 전환 버그 방지
- grab_focus dual-focus 위험을 fallback과 함께 명시, 검증 후 확정

### Negative

- grab_focus 검증 완료 전까지 gamepad 대화 UX가 최적이 아닐 수 있음

### Risks

- **위험**: grab_focus() dual-focus가 DialogueManager에서 예상대로 동작하지 않음 → **완화**: ui_accept 액션 fallback 명시, 검증 후 ADR 업데이트
- **위험**: NavigationRegion2D bake가 TileMapLayer와 호환되지 않음 → **완화**: Verification Required에 명시, 첫 맵 구현 시 즉시 확인

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 해결 방식 |
|---|---|---|
| 씬전환-시스템.md | TR-scene-001: PROCESS_MODE_DISABLED | 적용 범위와 예외(AudioManager) 명시 |
| 씬전환-시스템.md | TR-scene-002: load_threaded_request | 비동기 로딩 + _process 폴링 계약 |
| 씬전환-시스템.md | TR-scene-003: 4-state FSM | FSM 전환 순서 확정 |
| 씬전환-시스템.md | TR-scene-004: SpawnPoint 그룹 명명 | SpawnPoint_{id} + Default 폴백 계약 |
| 맵-지역-시스템.md | TR-map-001: TileMapLayer + NavigationRegion2D | TileMap 금지, 필수 노드 구성 명시 |
| 맵-지역-시스템.md | TR-map-002: Area2D 포탈 + EnemySpawnZone | 필수 노드 구성에 포함 |
| 맵-지역-시스템.md | TR-map-003: 포탈 → DialogueManager.is_active 체크 | 포탈 진입 조건 코드 계약 |
| 대화-시스템.md | TR-dial-001: CanvasLayer + grab_focus + is_active 차단 | 레이어 번호, dual-focus fallback, is_active 차단 순서 확정 |

## Performance Implications

- **CPU**: load_threaded_request 폴링 — _process에서 상태 조회만, 무시 가능
- **Memory**: 씬 전환 시 이전 씬 해제 + 새 씬 로드 — 피크는 두 씬의 합. 512MB 예산 내 수용
- **Load Time**: 페이드 아웃(0.3s)이 로딩을 가림 — 체감 로딩 시간 감소
- **Network**: 해당 없음

## Migration Plan

신규 프로젝트 — 기존 코드 없음. 첫 맵 씬 생성 전 이 ADR이 Accepted여야 한다.

## Validation Criteria

- [ ] TileMap 노드가 프로젝트 어디에도 없음 (Grep으로 확인)
- [ ] 모든 맵 씬에 SpawnPoint_Default 노드 존재 ("spawn_points" 그룹)
- [ ] 대화 중 포탈 진입 시도 → 씬 전환 발생하지 않음
- [ ] grab_focus() 호출 후 gamepad ui_accept로 대화 진행 가능 (실기기/에디터 검증)
- [ ] 씬 전환 중 PlayerController._physics_process()가 실행되지 않음

## Related Decisions

- ADR-0002: SceneTransitionManager Autoload 등록 순서
- design/gdd/씬전환-시스템.md
- design/gdd/맵-지역-시스템.md
- design/gdd/대화-시스템.md
