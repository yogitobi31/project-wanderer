# 유랑단 (The Wandering Band) — Master Architecture

## Document Status
- Version: 1 (draft)
- Last Updated: 2026-04-27
- Engine: Godot 4.6 (Compatibility Renderer, GDScript)
- GDDs Covered: 20 MVP systems (see systems-index.md)
- ADRs Referenced: ADR-0001 (Data Registry Autoload)
- Technical Director Sign-Off: 2026-04-27 — APPROVED
- Lead Programmer Feasibility: SKIPPED (lean mode)

---

## Engine Knowledge Gap Summary

LLM training covers ~Godot 4.3. Versions 4.4/4.5/4.6 are post-cutoff.
This project uses the Compatibility Renderer (2D), so D3D12 default, Jolt physics,
and glow rework from 4.6 are **not relevant**.

**Relevant post-cutoff items:**

| Risk | API / Change | System Affected | Verified |
|------|-------------|-----------------|---------|
| HIGH | `duplicate_deep()` added 4.5 | NPCRegistry.snapshot() | ✅ |
| HIGH | `TileMap` → `TileMapLayer` (4.3) | MapScene | ✅ |
| HIGH | `grab_focus()` dual-focus split (4.6) | UI/CompanionJoin CanvasLayer | ✅ |
| MEDIUM | Dedicated 2D NavigationServer (4.5) | CompanionAI, EnemyAI | ✅ |
| MEDIUM | `physical_keycode` storage (4.5) | InputMapManager | ✅ |
| MEDIUM | SDL3 gamepad backend (4.5) | InputMapManager | ✅ |
| LOW | Audio API | AudioManager | ✅ (no changes) |
| LOW | CharacterBody2D / move_and_slide() | PlayerController | ✅ (stable) |

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  • DialogueManager (CanvasLayer overlay)                │
│  • AudioManager (BGM/SFX playback)                      │
│  • SceneTransitionManager (fade CanvasLayer)            │
│  • HUD (HP bar, party status) [future GDD]              │
├─────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                          │
│  • QuestManager (quest state, conditions)               │
│  • CompanionAI (FOLLOWING/CHASING/ATTACKING)            │
│  • EnemyAI + CombatEncounter (enemy FSM, scaling)       │
│  • CompanionJoinEvent (join orchestration)              │
│  • RecruitmentQuest (quest→NPC→join orchestration)      │
│  • MapScene (TileMapLayer, portals, spawn zones)        │
│  • Inventory (item storage)                             │
│  • PickupItem (auto-collect node)                       │
├─────────────────────────────────────────────────────────┤
│  CORE LAYER                                             │
│  • PlayerController (input→movement→attack FSM)         │
│  • HealthComponent (HP tracking, damage application)    │
│  • Hitbox / Hurtbox (Area2D collision detection)        │
│  • CharacterStats (base+mod Resource)                   │
├─────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                       │
│  • EventBus (cross-system signal relay)                 │
│  • NPCRegistry (NPC state Autoload)                     │
│  • PartyManager (party membership Autoload)             │
│  • ItemDB (item definition Autoload)                    │
│  • InputMapManager (action context + rebinding)         │
│  • SceneTransitionManager* (async loader logic)         │
├─────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                         │
│  Godot 4.6 + Compatibility Renderer + GDScript          │
│  OS, FileAccess, ResourceLoader, NavigationServer2D     │
└─────────────────────────────────────────────────────────┘
```

*SceneTransitionManager: loading FSM in Foundation; fade CanvasLayer in Presentation.
One Autoload owns both concerns.

---

## Module Ownership

### Foundation Layer

| 모듈 | Owns | Exposes | Consumes | Engine API |
|---|---|---|---|---|
| **EventBus** | companion_join_requested 시그널 정의 | `companion_join_requested(companion_id:StringName)` | — | Godot Signal (stable) |
| **NPCRegistry** | 모든 NPC의 RelationshipState, quest_flags, party_slot | `get_npc(id)`, `set_state(id, state)`, `npc_state_changed` signal | — | `Resource.duplicate_deep()` ⚠️ HIGH (4.5+) |
| **PartyManager** | _companions Array[StringName], MAX_PARTY_SIZE=3 | `register_companion(id)`, `is_recruited(id)`, `get_companions()`, `companion_count` | NPCRegistry (validation 목적) | Array (stable) |
| **ItemDB** | ItemDefinition Resource 딕셔너리 (id→def) | `get(id)→ItemDefinition`, `has(id)→bool`, `error_occurred` signal | FileSystem (DirAccess scan) | `DirAccess`, `load()` (stable) |
| **InputMapManager** | 액션 바인딩, is_ui_active:bool, ConfigFile | `get_move_vector()→Vector2`, `is_action_just_pressed(action)`, `set_ui_active(bool)` | ConfigFile user://input_bindings.cfg | `InputMap`, `physical_keycode` ⚠️ MEDIUM (4.5) |
| **SceneTransitionManager** | 로딩 FSM 상태 (IDLE/FADING_OUT/LOADING/FADING_IN) | `transition_to(scene_path, spawn_id)`, `transition_completed` signal | ResourceLoader (async) | `ResourceLoader.load_threaded_request()`, `PROCESS_MODE_DISABLED` (stable) |

### Core Layer

| 모듈 | Owns | Exposes | Consumes | Engine API |
|---|---|---|---|---|
| **CharacterStats** | base_*/mod_* 값, computed properties | `max_hp`, `atk`, `def`, `spd` (computed), `stats_changed(stat_name)` signal | — | Resource (stable) |
| **HealthComponent** | current_hp:int, is_dead:bool, iframe 타이머 | `heal(amount)`, `initialize(stats)`, `health_changed(cur,max)`, `health_depleted` signals | CharacterStats (max_hp 읽기), Hurtbox (`hit_confirmed` 신호 수신) | Node (stable) |
| **Hitbox** | 활성화 여부, attack_data Dict | `activate(attack_data)`, `deactivate()` | AnimationPlayer (activation 트리거) | Area2D (stable); 7 physics layers |
| **Hurtbox** | — | `hit_received(attack_data)` signal | — | Area2D (stable) |
| **PlayerController** | 플레이어 FSM 상태 (IDLE/MOVING/ATTACKING/DEAD), 위치 | `set_spawn_position(pos:Vector2)` | InputMapManager, HealthComponent, Hitbox | CharacterBody2D, `move_and_slide()` (stable) |

### Feature Layer

| 모듈 | Owns | Exposes | Consumes | Engine API |
|---|---|---|---|---|
| **Inventory** | {item_id→quantity} Dictionary | `add_item(id,qty)`, `remove_item(id,qty)→bool`, `get_quantity(id)`, `has_item(id)`, `item_added/removed` signals | ItemDB (유효성 검사) | Dictionary (stable) |
| **QuestManager** | 퀘스트별 상태 (NOT_STARTED/ACTIVE/COMPLETED), 조건 | `start_quest(id)`, `complete_quest(id)`, `get_state(id)`, `quest_completed(id)` signal | NPCRegistry, Inventory, MapScene (location) | Dictionary (stable) |
| **CompanionAI** | 동료 FSM 상태 (FOLLOWING/CHASING/ATTACKING), nav target | `activate()`, `deactivate()` | PlayerController (위치), NPCRegistry (companion_id), NavigationAgent2D | `NavigationAgent2D` ⚠️ MEDIUM (4.5 2D nav server) |
| **EnemyAI** | 적 FSM 상태 (IDLE/CHASING/ATTACKING) | — | PlayerController (위치), HealthComponent | `NavigationAgent2D` ⚠️ MEDIUM |
| **CombatEncounter** | 활성 적 목록, companion_count 기반 스케일링 | `enemy_count` (computed) | PartyManager (companion_count) | Node (stable) |
| **CompanionJoinEvent** | join 연출 진행 여부 (_is_playing:bool) | `trigger_join(companion_id)` | NPCRegistry, PartyManager, AudioManager, EventBus | AnimationPlayer, `get_tree().get_nodes_in_group()` (stable) |
| **RecruitmentQuest** | — (오케스트레이터, 상태 없음) | — | DialogueManager, QuestManager, EventBus | — |
| **MapScene** | TileMapLayer, 포탈, SpawnPoint, EnemySpawnZone | SpawnPoint 그룹 (`SpawnPoint_{id}`), `portal_activated` signal | DialogueManager (is_active 체크), SceneTransitionManager | `TileMapLayer` ⚠️ HIGH (TileMap 대체), NavigationRegion2D, Area2D |
| **PickupItem** | — (노드, 상태 없음) | — | Inventory (add_item), PlayerController (충돌 감지) | Area2D, `queue_free()` (stable) |

### Presentation Layer

| 모듈 | Owns | Exposes | Consumes | Engine API |
|---|---|---|---|---|
| **DialogueManager** | is_active:bool, 현재 대화 노드 | `start_dialogue(npc_id)`, `is_active→bool`, `dialogue_completed` signal | NPCRegistry (RelationshipState→대화 선택) | CanvasLayer, Label (stable); `grab_focus()` ⚠️ HIGH (4.6 dual-focus) |
| **AudioManager** | SFX 풀(8), BGM 현재 트랙, 버스 볼륨 | `play_sfx(key)`, `play_bgm(key)`, `stop_bgm()`, `set_volume(bus,val)` | audio_config.tres (BGM 매핑) | AudioStreamPlayer, AudioServer (stable) |
| **SceneTransitionManager** (Presentation) | ColorRect fade overlay (CanvasLayer) | — (Foundation FSM이 제어) | SceneTransitionManager Foundation FSM | CanvasLayer, ColorRect, Tween (stable) |

### 의존성 다이어그램

```
PLATFORM
  └── FOUNDATION
        ├── EventBus ◄────────────────────────────────────┐
        ├── NPCRegistry ◄───────────────────────┐         │
        ├── PartyManager ◄──────────┐           │         │
        ├── ItemDB ◄───────┐        │           │         │
        ├── InputMapManager◄──────────────────────────────│──────┐
        └── SceneTransitionMgr                  │         │      │
              │                                 │         │      │
        CORE  │                                 │         │      │
        ├── CharacterStats                       │         │      │
        ├── HealthComponent ──► CharacterStats   │         │      │
        ├── Hitbox/Hurtbox                       │         │      │
        └── PlayerController ──► InputMapMgr    │         │      │
                              ──► HealthComponent│         │      │
              │                                 │         │      │
        FEATURE                                 │         │      │
        ├── Inventory ──────────────────────────┤(ItemDB) │      │
        ├── QuestManager ────────────────────────┤        │      │
        │     └──────────────────────────────────┘(NPCReg)│      │
        ├── CompanionAI ──► PlayerController              │      │
        ├── EnemyAI ──► PlayerController                  │      │
        ├── CombatEncounter ──► PartyManager              │      │
        ├── CompanionJoinEvent ──► NPCRegistry ───────────┘      │
        │                    ──► PartyManager                     │
        │                    ──► EventBus ────────────────────────┘
        ├── RecruitmentQuest ──► QuestManager, EventBus
        ├── MapScene ──► SceneTransitionMgr
        └── PickupItem ──► Inventory

        PRESENTATION
        ├── DialogueManager ──► NPCRegistry
        ├── AudioManager
        └── SceneTransitionMgr (Presentation: fade overlay)
```

---

## Data Flow

### Scenario 1: Frame Update Path (플레이어 이동 + 공격)

```
InputMapManager
  │  get_move_vector() → Vector2          [sync, per frame]
  │  is_action_just_pressed("combat_attack") → bool
  ▼
PlayerController._physics_process()
  │  move_and_slide()                     [sync, CharacterBody2D]
  │  (공격 입력 시) FSM → ATTACKING
  │    └── Hitbox.activate(attack_data)   [sync, direct call]
  │
  │  (DEAD 상태) → 이동/공격 입력 무시
  ▼
CompanionAI._physics_process()
  │  NavigationAgent2D.get_next_path_position() → Vector2  [sync]
  ▼
EnemyAI._physics_process()
  │  NavigationAgent2D.get_next_path_position() → Vector2  [sync]
  │  (ATTACKING) → Hitbox.activate(attack_data)
```

통신 방식: 모두 동기 호출. 크로스-스레드 없음. NavigationServer2D는 메인 스레드와 동기화됨.

### Scenario 2: 피해 처리 경로 (Hitbox → HealthComponent → 사망)

```
Hitbox (Area2D)
  │  area_entered(hurtbox) 시그널           [signal, 동기]
  ▼
Hurtbox
  │  hit_received(attack_data) 시그널 emit  [signal, 동기]
  ▼
HealthComponent
  │  [hit_confirmed(attack_data) 신호 수신 — ADR-0004]
  │  final_damage = max(1, attack_data["damage"] - owner.stats.def)
  │  current_hp -= final_damage
  │  health_changed(current_hp, max_hp) emit
  │
  └── (current_hp ≤ 0)
        health_depleted() emit
        ▼
        PlayerController → FSM DEAD
        또는
        EnemyAI → queue_free()
          └── PickupItem 드롭 → Inventory.add_item()
```

통신 방식: Area2D 시그널 → 직접 호출 체인. 히트박스 활성화는 AnimationPlayer가 animation frame 기반으로 트리거.

### Scenario 3: 동료 영입 흐름 (대화 → 퀘스트 → 합류)

```
DialogueManager.start_dialogue(npc_id)
  │  NPCRegistry.get_npc(npc_id).relationship_state 읽기
  │  dialogue_completed emit
  ▼
RecruitmentQuest
  │  QuestManager.start_quest() / complete_quest()
  │    └── NPCRegistry.set_state(COMPANION)
  │    └── Inventory.remove_item(required_items)
  │    └── quest_completed emit
  ▼
EventBus.companion_join_requested(companion_id) emit   [크로스-시스템 디커플링]
  ▼
CompanionJoinEvent
  │  Phase A (동기): PartyManager.register_companion()
  │  Phase C (await): 씬 인스턴스화 → AudioManager.play_sfx()
  │    → AnimationPlayer.play("join_in") → await finished
  └── CompanionAI.activate()
```

통신 방식: 퀘스트→영입은 EventBus 시그널. 합류 연출은 `await` 코루틴. `_is_playing` 가드로 중복 트리거 방지.

### Scenario 4: 씬 전환 경로 (포탈 → 로딩 → 스폰)

```
MapScene.portal (Area2D)
  │  DialogueManager.is_active() 체크 → false여야 진행
  ▼
SceneTransitionManager.transition_to(target_scene, spawn_id)
  │  IDLE → FADING_OUT: ColorRect Tween (0.3s), tree.paused = true
  │  FADING_OUT → LOADING: ResourceLoader.load_threaded_request() [async]
  │  LOADING → FADING_IN: change_scene_to_packed(), tree.paused = false
  │    PlayerController.set_spawn_position(SpawnPoint_{spawn_id})
  │    AudioManager.play_bgm(new_map_bgm)
  │    ColorRect Tween (0.4s)
  └── FADING_IN → IDLE: transition_completed emit
```

통신 방식: 씬 로딩은 `ResourceLoader` 비동기 (`_process` 폴링). BGM 전환은 동기 호출.

### Scenario 5: 초기화 순서 (게임 시작)

Autoload 등록 순서 (project.godot):
1. EventBus — 시그널 정의만, 의존성 없음
2. ItemDB — DirAccess 스캔, _validate_definitions()
3. NPCRegistry — is_initialized=false 가드
4. PartyManager — NPCRegistry 이후
5. Inventory — ItemDB 이후
6. QuestManager — NPCRegistry, Inventory 이후
7. InputMapManager — ConfigFile 로드
8. SceneTransitionManager
9. AudioManager — 독립적

NPCRegistry._ready() 완료 시 `registry_initialized` emit → 의존 시스템에 준비 완료 알림.

**저장/불러오기 대상**: NPCRegistry, Inventory, QuestManager, PartyManager — 4개 Autoload가 직렬화 책임 보유. SaveManager(미래 GDD)가 이들을 호출.

---

## API Boundaries

### Foundation Layer API

```gdscript
# ── EventBus (Autoload) ──────────────────────────────────────────
signal companion_join_requested(companion_id: StringName)
# 발행자: RecruitmentQuest  수신자: CompanionJoinEvent
# 불변: companion_id는 NPCRegistry에 존재하는 ID여야 함


# ── NPCRegistry (Autoload) ───────────────────────────────────────
signal npc_state_changed(npc_id: StringName, old_state: RelationshipState, new_state: RelationshipState)
signal registry_initialized()

func get_npc(npc_id: StringName) -> NPCRecord          # snapshot() 반환 — 호출자가 수정해도 레지스트리 안전
func set_state(npc_id: StringName, state: RelationshipState) -> void
func is_initialized() -> bool

# 불변:
#   get_npc()는 항상 복사본(duplicate_deep)을 반환 — 원본 직접 수정 금지
#   set_state()는 registry_initialized 이후에만 호출 가능
#   COMPANION 상태로의 전환은 PartyManager.companion_count < MAX_PARTY_SIZE일 때만


# ── PartyManager (Autoload) ──────────────────────────────────────
signal companion_registered(companion_id: StringName)

var companion_count: int  # 읽기 전용 computed property

func register_companion(companion_id: StringName) -> void
func is_recruited(companion_id: StringName) -> bool
func get_companions() -> Array[StringName]  # 복사본 반환

# 불변:
#   register_companion() 호출 전 NPCRegistry 상태가 COMPANION이어야 함
#   companion_count > MAX_PARTY_SIZE(3)이면 register_companion() 실패


# ── ItemDB (Autoload) ────────────────────────────────────────────
signal error_occurred(message: String)

func get(item_id: StringName) -> ItemDefinition   # 없으면 null
func has(item_id: StringName) -> bool

# 불변:
#   _ready() 완료 후 딕셔너리는 불변 — 런타임 추가/삭제 없음
#   ItemDefinition은 읽기 전용 Resource — 복사 불필요


# ── InputMapManager (Autoload) ───────────────────────────────────
signal bindings_changed()

func get_move_vector() -> Vector2          # 정규화된 입력 벡터
func is_action_just_pressed(action: StringName) -> bool
func is_action_pressed(action: StringName) -> bool
func set_ui_active(active: bool) -> void   # gameplay 입력 차단 여부
func remap_action(action: StringName, event: InputEvent) -> void
func save_bindings() -> void
func load_bindings() -> void

# 불변:
#   is_ui_active == true이면 gameplay 카테고리 액션은 항상 false 반환
#   physical_keycode 기반 저장 (Godot 4.5 best practice)
# ⚠️ MEDIUM: physical_keycode — docs/engine-reference/godot/modules/input.md 검증 필요


# ── SceneTransitionManager (Autoload) ────────────────────────────
signal transition_completed(scene_path: String)

func transition_to(scene_path: String, spawn_id: String = "Default") -> void

# 불변:
#   transition_to() 호출 시 이미 전환 중이면 무시 (FSM IDLE 상태에서만 수락)
#   spawn_id에 해당하는 SpawnPoint_{spawn_id} 노드가 없으면 SpawnPoint_Default로 폴백
```

### Core Layer API

```gdscript
# ── CharacterStats (Resource) ────────────────────────────────────
signal stats_changed(stat_name: String)

@export var base_max_hp: int = 80
@export var base_atk: int = 20
@export var base_def: int = 8
@export var base_spd: float = 130.0
@export var mod_max_hp: int = 0
@export var mod_atk: int = 0
@export var mod_def: int = 0
@export var mod_spd: float = 0.0

var max_hp: int:  get: return max(1, base_max_hp + mod_max_hp)
var atk: int:     get: return max(0, base_atk + mod_atk)
var def: int:     get: return max(0, base_def + mod_def)
var spd: float:   get: return max(0.0, base_spd + mod_spd)

func apply_modifier(stat_name: String, delta) -> void  # mod_* 수정 + stats_changed emit

# 불변: computed property는 항상 ≥ 최솟값 (max_hp≥1, atk/def≥0, spd≥0.0)


# ── HealthComponent (Node) ───────────────────────────────────────
signal health_changed(current: int, maximum: int)
signal health_depleted()

var is_dead: bool  # 읽기 전용

func _on_hit_confirmed(attack_data: Dictionary) -> void
    # ADR-0004: take_damage 직접 호출 금지 — Hurtbox hit_confirmed 신호 수신
    # final_damage = max(1, attack_data["damage"] - owner.stats.def)
    # 무적(iframe) 중이면 무시
func heal(amount: int) -> void
func initialize(stats: CharacterStats) -> void  # _ready() 후 반드시 호출

# 불변:
#   initialize() 호출 전 heal 호출 금지
#   is_dead == true이면 hit_confirmed 무시


# ── Hitbox (Area2D) ──────────────────────────────────────────────
func activate(attack_data: Dictionary) -> void
    # attack_data 필수 키: { "damage": int, "knockback": Vector2, "attacker": Node }
func deactivate() -> void

# 불변:
#   activate()는 AnimationPlayer에서만 호출 (R-3: 공격 애니메이션 프레임 중에만)
#   같은 Hurtbox에 중복 히트 방지는 Hurtbox 측 책임


# ── Hurtbox (Area2D) ─────────────────────────────────────────────
signal hit_received(attack_data: Dictionary)
# 수신자: 부모 캐릭터의 HealthComponent


# ── PlayerController (CharacterBody2D) ───────────────────────────
func set_spawn_position(pos: Vector2) -> void

# 불변:
#   set_spawn_position()은 SceneTransitionManager가 씬 로드 직후 호출
#   FSM DEAD 상태에서 입력 처리 없음
```

### Feature Layer API

```gdscript
# ── Inventory (Autoload) ─────────────────────────────────────────
signal item_added(item_id: StringName, quantity: int)
signal item_removed(item_id: StringName, quantity: int)

func add_item(item_id: StringName, quantity: int = 1) -> void
func remove_item(item_id: StringName, quantity: int = 1) -> bool  # 수량 부족 시 false
func get_quantity(item_id: StringName) -> int   # 없으면 0
func has_item(item_id: StringName, quantity: int = 1) -> bool

# 불변: remove_item()은 성공 시에만 item_removed emit


# ── QuestManager (Autoload) ──────────────────────────────────────
signal quest_started(quest_id: StringName)
signal quest_completed(quest_id: StringName)

func start_quest(quest_id: StringName) -> void
func complete_quest(quest_id: StringName) -> void
func get_state(quest_id: StringName) -> QuestState  # NOT_STARTED / ACTIVE / COMPLETED
func notify_enemy_killed(enemy_type: StringName) -> void
func notify_location_visited(location_id: StringName) -> void

# 불변:
#   complete_quest()는 ACTIVE 상태에서만 유효
#   on_complete: NPCRegistry.set_state(COMPANION) + Inventory.remove_item() 내부 수행


# ── CompanionJoinEvent (Node — CompanionLayer에 배치) ─────────────
signal companion_appeared(companion_id: StringName)

func trigger_join(companion_id: StringName) -> void

# 불변:
#   _is_playing == true이면 trigger_join() 무시
#   companion_scenes Dictionary에 companion_id 없으면 push_error + return


# ── MapScene (씬별 루트 노드) ────────────────────────────────────
# 그룹 계약:
#   "spawn_points" 그룹: SpawnPoint_Default, SpawnPoint_{id} 노드 필수
#   "enemy_spawn_zones" 그룹: EnemySpawnZone 노드
# 포탈 진입 조건: !DialogueManager.is_active()


# ── CombatEncounter (Node — 각 MapScene에 배치) ──────────────────
const BASE_ENEMY_COUNT: int = 3
const ENEMY_SCALE_PER_COMPANION: int = 1

var enemy_count: int:
    get: return BASE_ENEMY_COUNT + PartyManager.companion_count * ENEMY_SCALE_PER_COMPANION
```

### Presentation Layer API

```gdscript
# ── DialogueManager (Autoload) ───────────────────────────────────
signal dialogue_completed(npc_id: StringName)

var is_active: bool  # 읽기 전용

func start_dialogue(npc_id: StringName) -> void

# 불변:
#   is_active == true 동안 씬 전환 차단 (MapScene 포탈이 체크)
#   TYPEWRITER_SPEED = 0.04초/글자
# ⚠️ HIGH: CanvasLayer 내 grab_focus() — Godot 4.6 dual-focus 변경
#   keyboard/gamepad focus와 UI focus 분리. 구현 시 재검증 필요.


# ── AudioManager (Autoload) ──────────────────────────────────────
func play_sfx(sfx_key: StringName) -> void
func play_bgm(bgm_key: StringName) -> void
func stop_bgm() -> void
func set_volume(bus_name: StringName, linear_value: float) -> void  # 0.0~1.0

# 불변:
#   SFX 풀(8개) 전부 사용 중이면 가장 오래된 것 재사용
#   BGM_FADE_OUT=0.3s, BGM_FADE_IN=0.4s
#   sfx_key / bgm_key 없으면 push_error + return (crash 없음)
```

### API 경계 엔진 주의 플래그

| 경계 | API | 위험도 | 검증 출처 |
|---|---|---|---|
| NPCRegistry.get_npc() | `duplicate_deep()` | HIGH (4.5+) | breaking-changes.md |
| DialogueManager.start_dialogue() | `grab_focus()` dual-focus | HIGH (4.6) | modules/input.md |
| InputMapManager | `physical_keycode` 저장 | MEDIUM (4.5) | modules/input.md |
| CompanionAI / EnemyAI | `NavigationAgent2D` avoidance | MEDIUM (4.5) | modules/navigation.md |
| MapScene | `TileMapLayer` | HIGH (4.3 대체) | deprecated-apis.md |

---

## ADR Audit

### ADR 품질 감사

| 항목 | ADR-0001 |
|---|---|
| Engine Compatibility 섹션 존재 | ✅ |
| 엔진 버전 기록 | ✅ Godot 4.6 |
| Post-cutoff API 플래그 | ✅ `duplicate_deep()` (4.5+) |
| GDD Requirements Addressed 섹션 | ✅ 3개 요건 |
| 이 아키텍처 결정과 충돌 | ✅ 없음 |
| 핀된 엔진 버전에 유효 | ✅ |
| Status | ⚠️ `Proposed` — 코딩 시작 전 `Accepted`로 승격 필요 |

### 추적성 커버리지

5개 커버 / 42개 GAP (총 47개 요건)

커버됨: TR-npc-001, TR-npc-002, TR-npc-003, TR-item-001, TR-item-002

GAP 목록 및 담당 신규 ADR:

| Req IDs | 담당 ADR |
|---|---|
| TR-npc-004~005, TR-item-003, TR-input-001~004, TR-audio-001~003, TR-inv-001~002, TR-party-001~002, TR-ebus-001, TR-quest-001~002 | ADR-0002 |
| TR-scene-001~004, TR-map-001~003, TR-dial-001 | ADR-0003 |
| TR-health-001~003, TR-hitbox-001~003, TR-player-001~003 | ADR-0004 |
| TR-stats-001~004 | ADR-0005 |
| TR-ai-001~002, TR-combat-001~002 | ADR-0006 |

신규 ADR 완성 후 커버리지: 47/47 (100%)

---

## Required ADRs

### 코딩 시작 전 필수

| ADR | 제목 | 커버 요건 수 | 주요 위험 |
|---|---|---|---|
| ADR-0001 | *(기존)* Data Registry Autoload — **Proposed → Accepted 필요** | 5 | duplicate_deep() HIGH |
| ADR-0002 | Foundation Autoload 등록 순서 및 초기화 계약 | 17 | physical_keycode MEDIUM |
| ADR-0003 | 씬 전환·맵 구조·UI 오버레이 계약 | 8 | grab_focus dual-focus HIGH |
| ADR-0004 | 전투 시스템 계약 (물리 레이어, 데미지, 무적 프레임) | 9 | 없음 |

### 해당 시스템 구현 전 필수

| ADR | 제목 | 커버 요건 수 | 주요 위험 |
|---|---|---|---|
| ADR-0005 | CharacterStats Resource 패턴 | 4 | 없음 |
| ADR-0006 | AI 내비게이션 계약 (NavigationAgent2D, 동료·적 FSM) | 4 | NavigationAgent2D avoidance MEDIUM |

### 생성 순서

```
1. ADR-0001 → Accepted (즉시)
2. ADR-0002: Foundation Autoloads
3. ADR-0003: 씬/맵/UI
4. ADR-0004: 전투 계약
5. ADR-0005: CharacterStats
6. ADR-0006: AI 내비게이션
```

전체 완성 시 커버리지: 47/47 (100%)

---

## Architecture Principles

1. **Autoload는 데이터 레지스트리만 허용한다.**
   게임플레이 로직이나 이벤트 중계는 Autoload에 넣지 않는다. ADR-0001의 4가지 기준을 충족하지 않는 시스템은 의존성 주입 또는 EventBus 시그널 패턴을 사용한다.

2. **크로스-시스템 통신은 EventBus 시그널로 디커플링한다.**
   레이어를 넘는 통신(Feature→Foundation, Presentation→Feature)은 직접 참조 대신 EventBus를 경유한다. 부모-자식 관계의 노드 간 통신만 직접 시그널을 허용한다.

3. **엔진 API 사용 전 엔진 레퍼런스를 먼저 확인한다.**
   LLM 학습 데이터는 Godot ~4.3 기준이다. HIGH/MEDIUM 위험 API(`duplicate_deep`, `grab_focus`, `TileMapLayer`, `NavigationAgent2D` avoidance)는 `docs/engine-reference/godot/` 검증 없이 구현을 시작하지 않는다.

4. **상태는 소유 모듈만 쓴다.**
   NPCRegistry 상태는 NPCRegistry만, 파티 목록은 PartyManager만 수정한다. 외부 시스템은 읽기 전용 API(`get_npc`, `get_companions`)와 시그널을 통해서만 상태 변화를 관찰한다.

5. **Pillar 4 "Small but True" — MVP 범위를 지킨다.**
   동료 3명, 맵 3개, 영입 퀘스트 3개가 MVP 완성 기준이다. 신규 시스템이나 API 추가는 이 범위 내 요건을 먼저 충족한 후에만 고려한다.

---

## Open Questions

| 질문 | 관련 시스템 | 해결 시점 |
|---|---|---|
| `grab_focus()` dual-focus (Godot 4.6): CanvasLayer 내 DialogueManager에서 gamepad 포커스가 올바르게 동작하는지 실기기/에디터 검증 필요 | DialogueManager, Steam Deck 지원 | ADR-0003 작성 시 |
| `NavigationAgent2D` avoidance: `velocity_computed` 시그널 기반 avoidance가 동료 3명 + 적 4명(최대) 동시 처리 시 60fps 예산 내에 수렴하는지 프로파일링 필요 | CompanionAI, EnemyAI | ADR-0006 작성 후 프로토타입 |
| SaveManager: NPCRegistry, Inventory, QuestManager, PartyManager 4개 Autoload의 직렬화 포맷과 파일 경로 미결정 | 저장/불러오기 전체 | MVP 이후 별도 GDD |
| HUD: 체력바, 파티 상태 표시 UI의 GDD 미작성 | Presentation Layer | Feature Layer 구현 시작 전 |
