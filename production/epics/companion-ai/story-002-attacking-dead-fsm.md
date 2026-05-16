# Story 002: CompanionAI — ATTACKING/DEAD FSM + DetectionArea2D

> **Epic**: CompanionAI
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/동료-AI-시스템.md`
**Requirements**: `TR-ai-001`

**ADR Governing Implementation**: ADR-0006: AI 내비게이션 계약 + ADR-0004: 전투 시스템 계약
**ADR Decision Summary**: ATTACKING: 거리 ≤ `ATTACK_RANGE` 시 `ATTACK_COOLDOWN`마다 HitboxArea2D 활성화. DEAD: `health_depleted()` 수신. DetectionArea2D Layer=`player_body(2)`, Mask=`enemy_body(3)`.

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1**: 적과 거리 ≤ `ATTACK_RANGE`(기본 60px) 시 ATTACKING 전환
- [ ] **AC-2**: ATTACKING 중 `ATTACK_COOLDOWN`(기본 1.0초)마다 HitboxArea2D `monitoring = true` → 0.2초 후 `false`
- [ ] **AC-3**: 적 사망 또는 `DETECTION_RADIUS` 이탈 시 FOLLOWING 복귀
- [ ] **AC-4**: `health_depleted()` 수신 시 DEAD 전환, `DetectionArea2D.monitoring = false`
- [ ] **AC-5**: DEAD 상태에서 이동/공격 없음

---

## Implementation Notes

1. DetectionArea2D `area_entered` → CHASING 전환:
   ```gdscript
   func _on_detection_area_entered(area: Area2D) -> void:
       _current_target = area.get_parent()
       _state = State.CHASING

   func _on_detection_area_exited(area: Area2D) -> void:
       if area.get_parent() == _current_target:
           _current_target = null
           _state = State.FOLLOWING
   ```
2. ATTACKING 쿨다운 Timer 노드 (`AttackCooldownTimer`)
3. `health_depleted` 연결:
   ```gdscript
   func _ready() -> void:
       $HealthComponent.health_depleted.connect(_on_health_depleted)

   func _on_health_depleted() -> void:
       _state = State.DEAD
       $DetectionArea2D.monitoring = false
       set_physics_process(false)
   ```

---

## QA Test Cases

- **AC-4**: `health_depleted.emit()` → `_state == State.DEAD`, `DetectionArea2D.monitoring == false`
- **AC-5**: DEAD 상태에서 `_physics_process` 호출 → velocity 변화 없음

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/companion_combat_test.gd` — AC-4, AC-5 커버

---

## Size Estimate

**Estimate**: 3 hours

---

## Dependencies

- Depends on: companion-ai/story-001, health-component/story-002
- Unlocks: companion-ai/story-003 (EnemyAI)

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 5/5 passing
**Deviations**: ADVISORY — TR-ai-001 text says "3-state FSM" (stale wording, 4 states correct); gameplay constants as class-level `const` not external config (same pattern as story-001)
**Test Evidence**: Logic — `tests/unit/ai/companion_combat_test.gd` (9 test functions, all ACs covered)
**Code Review**: Complete — B-1 duplicate append guard, B-2 freed-node validity sweep, AC-3 hitbox assertion, AC-1 timer assertion all applied before closure
