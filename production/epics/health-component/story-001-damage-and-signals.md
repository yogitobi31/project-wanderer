# Story 001: HealthComponent — 데미지 계산 + 신호 계약

> **Epic**: HealthComponent
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/체력-데미지-시스템.md`
**Requirements**: `TR-health-001`, `TR-health-002`, `TR-health-003`

**ADR Governing Implementation**: ADR-0004: 전투 시스템 계약
**ADR Decision Summary**: `hit_confirmed(attack_data: Dictionary)` 수신 → `final_damage = max(1, attack_data["damage"] - stats.def)` 계산 → `current_health` 갱신 → `health_changed(current, maximum)` emit. `current_health == 0` 시 `health_depleted()` emit. 사망 처리는 위임.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Required: 데미지 계산은 HealthComponent만 수행 (Hitbox 계산 Forbidden)
- Required: `health_changed(current: int, maximum: int)`, `health_depleted()` 신호
- Required: `heal(amount: int)` — max_hp 초과 금지

---

## Acceptance Criteria

- [ ] **AC-1**: `attack_data = {"damage": 25, "knockback": 0.0, "source": null}`, `stats.def = 8` → `final_damage = 17`, `current_health` 감소
- [ ] **AC-2**: `attack_data["damage"] = 5`, `stats.def = 10` → `final_damage = 1` (최솟값 보장)
- [ ] **AC-3**: 데미지로 `current_health == 0` 시 `health_depleted()` 신호 1회 emit
- [ ] **AC-4**: `health_changed(current, maximum)` 이 데미지/회복 시마다 emit
- [ ] **AC-5**: `heal(amount)` — `current_health`가 `stats.max_hp`를 초과하지 않음
- [ ] **AC-6**: `health_depleted()` 이후 추가 `hit_confirmed` 수신 시 무시 (무반응)

---

## Implementation Notes

1. `src/core/health_component.gd` 생성 (`Node` 상속):
   ```gdscript
   class_name HealthComponent
   extends Node

   signal health_changed(current: int, maximum: int)
   signal health_depleted()

   @export var stats: CharacterStats

   var current_health: int

   func _ready() -> void:
       current_health = stats.max_hp

   func hit_confirmed(attack_data: Dictionary) -> void:
       if current_health <= 0:
           return
       var damage: int = attack_data.get("damage", 0) as int
       var final_damage: int = max(1, damage - stats.def)
       current_health = max(0, current_health - final_damage)
       health_changed.emit(current_health, stats.max_hp)
       if current_health == 0:
           health_depleted.emit()

   func heal(amount: int) -> void:
       if current_health <= 0:
           return
       current_health = min(current_health + amount, stats.max_hp)
       health_changed.emit(current_health, stats.max_hp)
   ```
2. `stats` 필드는 `@export` — 씬에서 CharacterStats 리소스 연결
3. `hit_confirmed` 를 신호로 선언하지 않음 — HitboxArea2D가 직접 호출 (ADR-0004 신호 체인)

---

## Out of Scope

- Iframes 타이머 — story-002
- HurtboxArea2D monitoring 토글 — story-002

---

## QA Test Cases

- **AC-1**: stats.def=8, attack_data.damage=25 → current_health == initial - 17
- **AC-2**: stats.def=10, attack_data.damage=5 → current_health == initial - 1
- **AC-3**: current_health를 0으로 만드는 피격 → health_depleted emit count == 1
- **AC-4**: 피격마다 health_changed emit 확인 (current, maximum 값 검증)
- **AC-5**: current_health=5, max_hp=80, heal(100) → current_health == 80
- **AC-6**: health_depleted 이후 hit_confirmed 재호출 → current_health 변화 없음

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/health_component_test.gd` — AC-1~6 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2–3 hours
- `health_component.gd` 작성: 45분
- GUT 테스트: 1.5시간
- 경계값 케이스 (최솟값 1, heal 초과): 30분

---

## Dependencies

- Depends on: character-stats/story-001 (stats.def, stats.max_hp)
- Unlocks: health-component/story-002, PlayerController/story-003, CompanionAI

## Completion Notes
**Completed**: 2026-05-07
**Criteria**: 6/6 passing
**Deviations**: ADVISORY — `_ready()` null guard 추가 (ADR-0004 미명시, 런타임 안전성 개선); 중복 테스트 제거 및 heal 단언 강화
**Test Evidence**: Logic: `tests/unit/combat/health_component_test.gd` (15개 테스트)
**Code Review**: Complete (/code-review 수동 실행, CHANGES REQUIRED → 수정 완료)
