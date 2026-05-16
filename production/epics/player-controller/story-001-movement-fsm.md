# Story 001: PlayerController — 씬 구조 + IDLE/MOVING FSM + 이동

> **Epic**: PlayerController
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/플레이어-캐릭터-컨트롤러.md`
**Requirements**: `TR-player-001`, `TR-player-002`

**ADR Governing Implementation**: ADR-0004: 전투 시스템 계약 + ADR-0005: CharacterStats Resource
**ADR Decision Summary**: `CharacterBody2D` 루트. 자식: `CollisionShape2D`, `HealthComponent`, `HurtboxArea2D`, `HitboxArea2D`. 이동: `InputMapManager.get_move_vector()` → `velocity = direction * stats.spd` → `move_and_slide()`.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Required: CharacterBody2D 루트 + HealthComponent + HurtboxArea2D + HitboxArea2D 구조 (ADR-0004)
- Required: `stats.spd` computed 프로퍼티만 읽기
- Forbidden: 이동 속도 하드코딩

---

## Acceptance Criteria

- [ ] **AC-1**: 씬 구조: `PlayerController (CharacterBody2D) → CollisionShape2D, HealthComponent, HurtboxArea2D, HitboxArea2D`
- [ ] **AC-2**: Physics 레이어: CharacterBody2D Layer=`player_body(2)`, Mask=`world(1)`
- [ ] **AC-3**: 이동 입력 시 `velocity` 가 `direction * stats.spd` 로 설정되고 `move_and_slide()` 호출
- [ ] **AC-4**: 이동 입력 없을 때 `velocity == Vector2.ZERO`
- [ ] **AC-5**: FSM: 입력 있으면 MOVING, 없으면 IDLE 전환

---

## Implementation Notes

1. `src/characters/player_controller.gd` 생성 (`CharacterBody2D` 상속):
   ```gdscript
   class_name PlayerController
   extends CharacterBody2D

   enum State { IDLE, MOVING, ATTACKING, DEAD }

   @export var stats: CharacterStats
   @onready var health_component: HealthComponent = $HealthComponent

   var _state: State = State.IDLE

   func _physics_process(_delta: float) -> void:
       if _state == State.DEAD:
           return
       var move_vec: Vector2 = InputMapManager.get_move_vector()
       if move_vec != Vector2.ZERO:
           velocity = move_vec * stats.spd
           _state = State.MOVING
       else:
           velocity = Vector2.ZERO
           _state = State.IDLE
       move_and_slide()
   ```
2. `PlayerController.tscn` 생성: 루트 CharacterBody2D (Layer=2, Mask=1) + 자식 4개
3. HitboxArea2D: Layer=`player_hitbox(4)`, Mask=`enemy_hurtbox(7)`, 기본 `monitoring = false`
4. HurtboxArea2D: Layer=`player_hurtbox(6)`, Mask=`enemy_hitbox(5)`

---

## Out of Scope

- ATTACKING FSM — story-002
- DEAD FSM, set_spawn_position() — story-003

---

## QA Test Cases

- **AC-3**: `InputMapManager` stub에서 `get_move_vector()` 반환 `Vector2(1, 0)` → `velocity.x == stats.spd`
- **AC-4**: `get_move_vector()` 반환 `Vector2.ZERO` → `velocity == Vector2.ZERO`
- **AC-5**: FSM 상태 전환 확인 (MOVING ↔ IDLE)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/player_movement_test.gd` — AC-3~5 커버
**Visual/Feel evidence**: 에디터 씬 구조 스크린샷 → `production/qa/evidence/player-controller-scene-structure.png`

---

## Size Estimate

**Estimate**: 3–4 hours
- 씬 파일 + 노드 구성: 1시간
- GDScript 이동 로직: 1시간
- GUT 테스트 (InputMapManager mock): 1.5시간

---

## Dependencies

- Depends on: character-stats/story-001, character-stats/story-002
- Unlocks: player-controller/story-002 (ATTACKING)

## Completion Notes
**Completed**: 2026-05-08
**Criteria**: 3/5 passing (AC-1, AC-2 DEFERRED — requires PlayerController.tscn editor scene)
**Deviations**: ADVISORY — `_process_movement(move_vec)` seam 추출 (테스트 주입 목적); `is_ui_active` 가드 추가; `PlayerController.tscn` 미생성
**Test Evidence**: Logic: `tests/unit/player/player_movement_test.gd` (8개 테스트, AC-3/4/5 커버)
**Code Review**: Complete (/code-review 수동 실행, APPROVED WITH SUGGESTIONS → 수정 완료)
