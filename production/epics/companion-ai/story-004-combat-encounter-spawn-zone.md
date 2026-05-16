# Story 004: CombatEncounter + EnemySpawnZone 스케일링

> **Epic**: CompanionAI
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/실시간-파티-전투.md`
**Requirements**: `TR-combat-001`, `TR-combat-002`

**ADR Governing Implementation**: ADR-0006: AI 내비게이션 계약
**ADR Decision Summary**: `CombatEncounter` Node — `@export var enemies: Array[EnemyBase]`. 모든 적 `health_depleted()` 시 `combat_cleared(encounter_id)` 정확히 1회 emit. `EnemySpawnZone`: `enemy_count = base_enemy_count(3) + PartyManager.companion_count × ENEMY_SCALE_PER_COMPANION(1)`.

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1**: 적 3마리 전부 `health_depleted()` 후 `combat_cleared` 정확히 1회 emit
- [ ] **AC-2**: 적 0마리 CombatEncounter는 씬 로드 즉시 `combat_cleared` emit
- [ ] **AC-3**: 동료 0명 → 적 3마리 스폰, 동료 1명 → 4마리, 동료 3명 → 6마리
- [ ] **AC-4**: `combat_cleared` 이후 잔존 적 사망 시 중복 emit 없음

---

## Implementation Notes

1. `src/combat/combat_encounter.gd`:
   ```gdscript
   class_name CombatEncounter
   extends Node

   signal combat_cleared(encounter_id: StringName)

   @export var encounter_id: StringName = &"encounter_default"
   @export var enemies: Array[EnemyAI] = []

   var _alive_count: int = 0
   var _cleared: bool = false

   func _ready() -> void:
       _alive_count = enemies.size()
       if _alive_count == 0:
           combat_cleared.emit(encounter_id)
           _cleared = true
           return
       for enemy in enemies:
           enemy.get_node("HealthComponent").health_depleted.connect(_on_enemy_defeated)

   func _on_enemy_defeated() -> void:
       if _cleared:
           return
       _alive_count -= 1
       if _alive_count <= 0:
           _cleared = true
           combat_cleared.emit(encounter_id)
   ```
2. `src/combat/enemy_spawn_zone.gd`:
   ```gdscript
   const BASE_ENEMY_COUNT: int = 3
   const ENEMY_SCALE_PER_COMPANION: int = 1

   func _calculate_enemy_count() -> int:
       return BASE_ENEMY_COUNT + PartyManager.companion_count * ENEMY_SCALE_PER_COMPANION
   ```

---

## QA Test Cases

- **AC-1**: 적 3 mock, 3회 `health_depleted.emit()` → `combat_cleared` emit count == 1
- **AC-2**: `enemies = []` → `_ready()` 후 `combat_cleared` emit
- **AC-3**: `companion_count = 0,1,3` → `_calculate_enemy_count() == 3,4,6`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/combat_encounter_test.gd` — AC-1~4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2–3 hours

---

## Out of Scope

- EnemyAI.tscn 씬 파일 맵 배치 — MapScene/story-003에서 처리
- 실제 데미지 처리 연결 (HitboxArea2D → HealthComponent) — 이미 story-002/003에서 구현됨
- PartyManager Autoload 구현 — Foundation에서 완료 (`src/core/party_manager.gd`)
- 전투 UI / 전투 종료 연출 — 별도 Visual/Feel 스토리

---

## Dependencies

- Depends on: companion-ai/story-003, party-manager (Foundation, 완료)
- Unlocks: MapScene/story-003 (EnemySpawnZone 맵 배치)

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 4/4 passing
**Deviations**:
- ADVISORY: `@export var enemies: Array[EnemyAI]` + `_ready()` 스펙 대신 `register_enemy(HealthComponent)` + `start()` API 채택. `_ready()` → `start()` 자동 호출로 AC-2 충족. 맵 씬에서 Inspector 대신 코드로 연결 필요.
- ADVISORY: `calculate_enemy_count()`가 `PartyManager` autoload 직접 참조 — ADR-0006 §6 명시 방식 준수, DI 표준과 경미한 불일치.
**Test Evidence**: Logic — `tests/unit/combat/combat_encounter_test.gd` (14개 테스트, AC-1~4 전체 커버)
**Code Review**: Complete (CHANGES REQUIRED → 수정 완료 후 APPROVED)
