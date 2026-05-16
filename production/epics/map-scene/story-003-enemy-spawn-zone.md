# Story 003: MapScene — EnemySpawnZone 배치 + 적 수 스케일링

> **Epic**: MapScene
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/실시간-파티-전투.md`, `design/gdd/맵-지역-시스템.md`
**Requirements**: `TR-combat-002`, `TR-map-002`

**ADR Governing Implementation**: ADR-0006: AI 내비게이션 계약
**ADR Decision Summary**: `EnemySpawnZone._ready()` 에서 `base_enemy_count + PartyManager.companion_count × ENEMY_SCALE_PER_COMPANION` 계산 후 EnemyAI 인스턴스 스폰. CombatEncounter와 연동.

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1**: 동료 0명 → 적 3마리 스폰, 동료 3명 → 6마리 스폰
- [ ] **AC-2**: 스폰된 적이 CombatEncounter.enemies 배열에 등록
- [ ] **AC-3**: 스폰 위치가 EnemySpawnZone 영역 내 분산 (겹침 최소화)

---

## Implementation Notes

1. `src/scenes/enemy_spawn_zone.gd`:
   ```gdscript
   class_name EnemySpawnZone
   extends Node2D

   const BASE_ENEMY_COUNT: int = 3
   const ENEMY_SCALE_PER_COMPANION: int = 1

   @export var enemy_scene: PackedScene
   @export var combat_encounter: CombatEncounter
   @export var spawn_radius: float = 80.0

   func _ready() -> void:
       var count: int = BASE_ENEMY_COUNT + PartyManager.companion_count * ENEMY_SCALE_PER_COMPANION
       for i in count:
           var enemy: EnemyAI = enemy_scene.instantiate() as EnemyAI
           var offset: Vector2 = Vector2.from_angle(TAU * i / count) * spawn_radius
           enemy.global_position = global_position + offset
           get_parent().add_child(enemy)
           if combat_encounter:
               combat_encounter.enemies.append(enemy)
   ```

---

## QA Test Cases

- **AC-1**: `PartyManager.companion_count = 0` → spawn count == 3; `= 3` → count == 6
- **AC-2**: CombatEncounter.enemies.size() == spawn count

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/enemy_spawn_zone_test.gd` — AC-1, AC-2 커버

---

## Size Estimate

**Estimate**: 2 hours

---

## Dependencies

- Depends on: companion-ai/story-004, map-scene/story-001
- Unlocks: Vertical Slice 전투 구역 완성

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 2/3 passing (AC-3 위치 분산 DEFERRED — playtest)
**Deviations**:
- ADVISORY: src/scenes/ 신규 파일 대신 src/combat/enemy_spawn_zone.gd 확장 (class_name 충돌 방지)
- ADVISORY: enemies.append() 대신 register_enemy(hc) 사용 (story-004 API 반영)
- ADVISORY: AC-2 테스트가 _spawn_enemies() 직접 호출 없이 register_enemy() 계약 검증 (get_node 경로 미검증 — integration test 권장)
**Test Evidence**: Logic — tests/unit/combat/enemy_spawn_zone_test.gd (6개 테스트, AC-1~2 커버)
**Code Review**: Complete (CHANGES REQUIRED → 수정 완료 후 APPROVED)
