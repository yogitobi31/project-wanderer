# Story 002: stats_changed 신호 + GrowthRate + duplicate() 계약

> **Epic**: CharacterStats
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/능력치-시스템.md`
**Requirements**: `TR-stats-003`, `TR-stats-004`, `TR-stats-006`

**ADR Governing Implementation**: ADR-0005: CharacterStats Resource 패턴
**ADR Decision Summary**: `signal stats_changed(stat_name: StringName)` — `base_*`/`mod_*` setter 변경 시 emit. 런타임 인스턴스는 `stats_template.duplicate()`으로 생성. `GrowthRate`는 별도 Resource. 신호 핸들러 안에서 `base_*`/`mod_*` 쓰기 금지 (루프).

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Required: `stats_changed(stat_name: StringName)` 신호, base_*/mod_* setter에서 emit
- Required: 런타임 인스턴스는 `duplicate()` — `.tres` 원본 직접 수정 Forbidden
- Required: `GrowthRate` 는 별도 `class_name GrowthRate extends Resource`

---

## Acceptance Criteria

- [ ] **AC-1**: `base_atk` 변경 시 `stats_changed` 신호가 `stat_name == &"atk"`로 정확히 1회 emit
- [ ] **AC-2**: `duplicate()` 로 생성한 두 인스턴스가 독립적 — 한쪽 `base_atk` 수정이 다른 쪽에 영향 없음
- [ ] **AC-3**: `stats_changed` 핸들러 안에서 `base_*` 써도 신호 루프(무한 emit) 발생하지 않음
- [ ] **AC-4**: `GrowthRate` 인스턴스 생성 가능, `hp_growth`, `atk_growth`, `def_growth`, `spd_growth` 필드 존재

---

## Implementation Notes

1. `character_stats.gd`에 신호 추가:
   ```gdscript
   signal stats_changed(stat_name: StringName)
   ```
2. `base_*` setter 패턴 (mod_* 동일):
   ```gdscript
   var base_atk: int = 20:
       set(value):
           base_atk = value
           stats_changed.emit(&"atk")
   ```
   — `@export` setter는 Inspector 편집에서도 호출됨
3. MVP 보호: `mod_*` setter에 `push_warning()` 추가
4. `src/core/stats/growth_rate.gd` 생성:
   ```gdscript
   class_name GrowthRate
   extends Resource

   @export var hp_growth: int = 0
   @export var atk_growth: int = 0
   @export var def_growth: int = 0
   @export var spd_growth: float = 0.0
   ```
5. `.tres` 템플릿 파일 예시 (`assets/data/stats/player_stats.tres`) — 레벨 디자이너용 참고용 1개 생성

---

## Out of Scope

- 레벨업 계산 로직 — 별도 Feature 에픽
- `mod_*` 실제 사용 (버프/디버프) — Post-MVP

---

## QA Test Cases

- **AC-1**: `var count := 0; s.stats_changed.connect(func(_n): count += 1); s.base_atk = 25` → `assert_eq(count, 1)`; 신호 인자 `&"atk"` 확인
- **AC-2**: `var a := template.duplicate(); var b := template.duplicate(); a.base_atk = 99` → `assert_eq(b.base_atk, 20)`
- **AC-3**: 핸들러 안 `base_atk = 30` 설정 — 무한 루프 없이 정상 반환
- **AC-4**: `GrowthRate.new()` → `hp_growth == 0`, `atk_growth == 0` 확인

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/stats/character_stats_signal_test.gd` — AC-1~4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2 hours
- setter 신호 추가 + GrowthRate 작성: 45분
- GUT 테스트: 1시간
- .tres 템플릿 파일 생성: 15분

---

## Dependencies

- Depends on: character-stats/story-001
- Unlocks: HealthComponent, PlayerController, CompanionAI (stats.atk/def/spd/max_hp 사용)

## Completion Notes
**Completed**: 2026-05-07
**Criteria**: 4/4 passing
**Deviations**: TR-stats-006 미존재 (advisory — 스토리 작성 오타 추정)
**Test Evidence**: Logic — `tests/unit/stats/character_stats_signal_test.gd` (16 test functions)
**Code Review**: Complete — APPROVED WITH SUGGESTIONS (3개 제안 모두 적용)
