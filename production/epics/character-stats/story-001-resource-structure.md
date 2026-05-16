# Story 001: CharacterStats Resource 구조 + computed 프로퍼티

> **Epic**: CharacterStats
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/능력치-시스템.md`
**Requirements**: `TR-stats-001`, `TR-stats-002`, `TR-stats-005`

**ADR Governing Implementation**: ADR-0005: CharacterStats Resource 패턴
**ADR Decision Summary**: `class_name CharacterStats extends Resource`. `@export base_*` 4개 (base_max_hp, base_atk, base_def, base_spd) + `mod_*` 런타임 전용 4개. 다운스트림은 computed 프로퍼티(`max_hp`, `atk`, `def`, `spd`)만 읽는다. 클램핑: max_hp[1,9999], atk[0,999], def[0,999], spd[10.0,600.0].

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `@export`, `Resource`, computed property(`var name: type: get:`) — 4.6 변경 없음.

**Control Manifest Rules (Core layer)**:
- Required: `class_name CharacterStats extends Resource`, 파일 위치 `src/core/stats/character_stats.gd`
- Required: `@export` 는 `base_*` 만. `mod_*` 는 `@export` 없음
- Required: 다운스트림은 computed 프로퍼티만 읽음 (`base_*` / `mod_*` 직접 읽기 Forbidden)

---

## Acceptance Criteria

- [ ] **AC-1**: `CharacterStats` 인스턴스 기본값 — `max_hp == 80`, `atk == 20`, `def == 8`, `spd == 130.0`
- [ ] **AC-2**: `base_def = 5, mod_def = -8` → `def == 0` (클램핑: 최솟값 0)
- [ ] **AC-3**: `base_max_hp = 9999, mod_max_hp = 1` → `max_hp == 9999` (클램핑: 최댓값 9999)
- [ ] **AC-4**: `base_spd = 5.0` → `spd == 10.0` (클램핑: 최솟값 10.0)
- [ ] **AC-5**: 에디터 Inspector에서 `base_*` 4개 필드가 표시되고 편집 가능 (수동 확인)

---

## Implementation Notes

1. `src/core/stats/character_stats.gd` 생성:
   ```gdscript
   class_name CharacterStats
   extends Resource

   @export var base_max_hp: int = 80
   @export var base_atk: int = 20
   @export var base_def: int = 8
   @export var base_spd: float = 130.0

   var mod_max_hp: int = 0
   var mod_atk: int = 0
   var mod_def: int = 0
   var mod_spd: float = 0.0

   var max_hp: int:
       get: return clampi(base_max_hp + mod_max_hp, 1, 9999)

   var atk: int:
       get: return clampi(base_atk + mod_atk, 0, 999)

   var def: int:
       get: return clampi(base_def + mod_def, 0, 999)

   var spd: float:
       get: return clampf(base_spd + mod_spd, 10.0, 600.0)
   ```
2. `mod_*` 에는 MVP 보호용 `push_warning()` setter 추가 (ADR-0005 §7)
3. `.tres` 템플릿 파일 생성 불필요 — story-002에서 duplicate() 계약과 함께 작성

---

## Out of Scope

- `stats_changed` 신호 — story-002에서 처리
- `GrowthRate` Resource — story-002에서 처리
- `.tres` 템플릿 파일 생성 — story-002

---

## QA Test Cases

- **AC-1**: `var s := CharacterStats.new()` → `assert_eq(s.max_hp, 80)`, `assert_eq(s.atk, 20)`, `assert_eq(s.def, 8)`, `assert_eq(s.spd, 130.0)`
- **AC-2**: `s.base_def = 5; s.mod_def = -8` → `assert_eq(s.def, 0)`
- **AC-3**: `s.base_max_hp = 9999; s.mod_max_hp = 1` → `assert_eq(s.max_hp, 9999)`
- **AC-4**: `s.base_spd = 5.0` → `assert_eq(s.spd, 10.0)`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/stats/character_stats_test.gd` — AC-1~4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2–3 hours
- `src/core/stats/character_stats.gd` 작성: 30분
- GUT 테스트 (경계값 포함): 1.5시간
- AC-5 Inspector 수동 확인: 15분

---

## Dependencies

- Depends on: None
- Unlocks: story-002 (stats_changed), HealthComponent/story-001, PlayerController/story-001, CompanionAI/story-001

## Completion Notes
**Completed**: 2026-05-07
**Criteria**: 4/5 passing (AC-5 Inspector visibility — advisory manual, @export_range confirmed in code)
**Deviations**: TR-stats-005 referenced in story but not in TR registry — likely typo, implementation satisfies TR-stats-001 and TR-stats-002
**Test Evidence**: Logic — `tests/unit/stats/character_stats_test.gd` (34 test functions)
**Code Review**: Complete — CHANGES REQUIRED resolved (3 fixes applied)
