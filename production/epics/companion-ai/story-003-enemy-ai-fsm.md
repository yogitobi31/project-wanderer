# Story 003: EnemyAI — IDLE/CHASING/ATTACKING/DEAD FSM

> **Epic**: CompanionAI
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/동료-AI-시스템.md`, `design/gdd/실시간-파티-전투.md`
**Requirements**: `TR-ai-002`

**ADR Governing Implementation**: ADR-0006: AI 내비게이션 계약
**ADR Decision Summary**: `EnemyAI` IDLE/CHASING/ATTACKING/DEAD. 타겟 우선순위: 플레이어 > 가장 가까운 동료. DetectionArea2D Layer=`enemy_body(3)`, Mask=`player_body(2)`. CompanionAI와 동일한 NavigationAgent2D 패턴.

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1**: IDLE 상태에서 DetectionArea2D 내 플레이어 진입 시 CHASING 전환
- [ ] **AC-2**: 플레이어보다 가까운 동료가 있어도 플레이어를 우선 추격
- [ ] **AC-3**: 거리 ≤ `ENEMY_ATTACK_RANGE`(기본 60px) 시 ATTACKING 전환
- [ ] **AC-4**: `health_depleted()` 수신 시 DEAD 전환 (이동/공격 중단)
- [ ] **AC-5**: 타겟 사망 / 감지 범위 이탈 시 IDLE 복귀

---

## Implementation Notes

1. `src/characters/enemy_ai.gd` 생성 (CompanionAI와 유사 구조, CharacterBody2D)
   - Layer=`enemy_body(3)`, Mask=`world(1)`
   - DetectionArea2D: Layer=`enemy_body(3)`, Mask=`player_body(2)`
   - HitboxArea2D: Layer=`enemy_hitbox(5)`, Mask=`player_hurtbox(6)`
   - HurtboxArea2D: Layer=`enemy_hurtbox(7)`, Mask=`player_hitbox(4)`
2. 타겟 우선순위 (DetectionArea2D는 `body_entered` 신호 사용 — CompanionAI 패턴과 동일):
   ```gdscript
   func _select_target(bodies: Array[Node2D]) -> Node2D:
       for body in bodies:
           if body is PlayerController:
               return body
       # 가장 가까운 동료
       var nearest: Node2D = null
       var min_dist: float = INF
       for body in bodies:
           if not is_instance_valid(body):
               continue
           var d: float = global_position.distance_to(body.global_position)
           if d < min_dist:
               min_dist = d
               nearest = body
       return nearest
   ```

---

## QA Test Cases

- **AC-2**: 플레이어 + 동료 동시 감지 범위 내 → 타겟 == PlayerController
- **AC-4**: `health_depleted.emit()` → `_state == State.DEAD`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/enemy_ai_test.gd` — AC-2, AC-4 커버

---

## Size Estimate

**Estimate**: 3–4 hours

---

## Out of Scope

- `EnemyAI.tscn` 씬 파일 — story-004에서 CombatEncounter/SpawnZone과 함께 통합
- 실제 데미지 처리 — HitboxArea2D → HealthComponent 연결은 전투 통합 스토리에서
- 애니메이션 연동 — 별도 Visual/Feel 스토리
- EnemySpawnZone 스폰 로직

---

## Dependencies

- Depends on: companion-ai/story-001 (NavigationAgent2D 패턴 확립)
- Unlocks: companion-ai/story-004 (CombatEncounter)

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 5/5 passing
**Deviations**: ADVISORY — gameplay constants as class-level `const` (same accepted pattern as story-002); `_process_attacking()` calls `move_and_slide()` every tick (zero-velocity, functionally harmless, accepted at code review); 3 QA edge cases lack dedicated tests (exact 60px boundary, empty-array, companion-only exit) — recommend follow-up in story-004
**Test Evidence**: Logic — `tests/unit/ai/enemy_ai_test.gd` (13 test functions, all 5 ACs covered)
**Code Review**: Complete — B-1 purge loop off-by-one fixed, B-2 `select_target()` doc comment added before closure
