# Story 003: PlayerController — DEAD FSM + set_spawn_position()

> **Epic**: PlayerController
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/플레이어-캐릭터-컨트롤러.md`
**Requirements**: `TR-player-001`, `TR-health-003`

**ADR Governing Implementation**: ADR-0004: 전투 시스템 계약 + ADR-0003: 씬 전환 계약
**ADR Decision Summary**: `HealthComponent.health_depleted()` 수신 → DEAD 상태. `set_spawn_position(pos)` 로 SceneTransitionManager 씬 전환 후 위치 배치. DEAD 상태에서 이동/공격 입력 무시.

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1**: `health_depleted` 신호 수신 시 DEAD 상태로 전환
- [ ] **AC-2**: DEAD 상태에서 이동 입력 → `velocity == Vector2.ZERO` (이동 없음)
- [ ] **AC-3**: DEAD 상태에서 공격 입력 → 무반응
- [ ] **AC-4**: `set_spawn_position(Vector2(100, 200))` 호출 시 `global_position == Vector2(100, 200)`
- [ ] **AC-5**: MVP: `health_depleted` 후 씬 재시작 또는 타이틀로 이동 (구체적 처리는 GameManager에 위임 — 신호만 발행)

---

## Implementation Notes

1. `_ready()` 에서 HealthComponent 신호 연결:
   ```gdscript
   func _ready() -> void:
       health_component.health_depleted.connect(_on_health_depleted)

   func _on_health_depleted() -> void:
       _state = State.DEAD
       # MVP: EventBus 통해 GameManager에 player_died 알림 또는 직접 씬 전환
   ```
2. `set_spawn_position()`:
   ```gdscript
   func set_spawn_position(pos: Vector2) -> void:
       global_position = pos
   ```
   — SceneTransitionManager가 씬 로드 완료 후 호출
3. DEAD 상태 체크는 `_physics_process` 서두에 이미 존재 (story-001)

---

## Out of Scope

- 사망 애니메이션 — Visual/Feel
- 리스폰 / Game Over UI — Feature 레이어 (MVP 제외)

---

## QA Test Cases

- **AC-1**: `health_component.health_depleted.emit()` → `_state == State.DEAD`
- **AC-2**: DEAD 상태에서 `get_move_vector()` → 1 반환 → `velocity == Vector2.ZERO`
- **AC-3**: DEAD 상태에서 공격 입력 → `hitbox.monitoring` 변화 없음
- **AC-4**: `set_spawn_position(Vector2(100, 200))` → `global_position.x == 100`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player/player_death_test.gd` — AC-1~4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2 hours
- DEAD 상태 + health_depleted 연결: 45분
- set_spawn_position: 15분
- GUT 테스트: 1시간

---

## Dependencies

- Depends on: player-controller/story-002, health-component/story-001
- Unlocks: Vertical Slice 플레이어 루프 완성

## Completion Notes
**Completed**: 2026-05-08
**Criteria**: 5/5 passing
**Deviations**: ADVISORY — `_process_movement` DEAD 가드 추가(defense-in-depth); `push_warning()` for null health_component
**Test Evidence**: Logic: `tests/unit/player/player_death_test.gd` (9개 테스트, AC-1~5 커버)
**Code Review**: Complete (/code-review 수동 실행, APPROVED WITH SUGGESTIONS → 적용 완료)
