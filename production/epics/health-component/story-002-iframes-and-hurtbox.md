# Story 002: Iframes 타이머 + HurtboxArea2D 연동

> **Epic**: HealthComponent
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/체력-데미지-시스템.md`
**Requirements**: `TR-hitbox-003`

**ADR Governing Implementation**: ADR-0004: 전투 시스템 계약
**ADR Decision Summary**: 피격 시 `HurtboxArea2D.monitoring = false` 즉시. `IFRAMES_DURATION = 0.5초` 후 `monitoring = true` 복원. 타이머는 HealthComponent 내부 Timer 노드로 관리.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Required: Iframes = 0.5초, 내부 Timer 노드로 관리
- Required: 피격 즉시 `HurtboxArea2D.monitoring = false` — 복원은 타이머 후

---

## Acceptance Criteria

- [ ] **AC-1**: 피격 직후 `hurtbox.monitoring == false`
- [ ] **AC-2**: 피격 후 0.5초 경과 시 `hurtbox.monitoring == true` 복원
- [ ] **AC-3**: Iframes 중 `hit_confirmed` 재호출 시 무시 (monitoring=false이므로 area_entered 미발생 — 구조적 보장)
- [ ] **AC-4**: `health_depleted()` 이후 `hurtbox.monitoring` 이 영구 false 유지 (Iframes 타이머 중단)

---

## Implementation Notes

1. HealthComponent에 `@export var hurtbox: Area2D` 추가 (씬에서 연결)
2. 내부 Timer 노드 추가:
   ```gdscript
   const IFRAMES_DURATION: float = 0.5

   @onready var _iframe_timer: Timer = $IframesTimer

   func _ready() -> void:
       current_health = stats.max_hp
       _iframe_timer.wait_time = IFRAMES_DURATION
       _iframe_timer.one_shot = true
       _iframe_timer.timeout.connect(_on_iframes_expired)

   func hit_confirmed(attack_data: Dictionary) -> void:
       if current_health <= 0:
           return
       # ... 데미지 계산 (story-001)
       if hurtbox:
           hurtbox.monitoring = false
           _iframe_timer.start()

   func _on_iframes_expired() -> void:
       if current_health > 0 and hurtbox:
           hurtbox.monitoring = true
   ```
3. `health_depleted()` emit 시 `_iframe_timer.stop()` — 복원 차단

---

## Out of Scope

- HitboxArea2D monitoring 토글 (애니메이션 트랙) — PlayerController/story-002

---

## QA Test Cases

- **AC-1**: `hit_confirmed(attack_data)` 호출 직후 `hurtbox.monitoring == false`
- **AC-2**: 타이머 `advance(0.5)` 후 `hurtbox.monitoring == true`
- **AC-4**: `current_health → 0` 피격 후 타이머 만료 시 `hurtbox.monitoring` 변화 없음 (false 유지)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/health_iframes_test.gd` — AC-1, AC-2, AC-4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2 hours
- Timer 연동 + hurtbox 참조 추가: 45분
- GUT 테스트 (타이머 시뮬레이션): 1시간
- health_depleted 후 타이머 중단 처리: 15분

---

## Dependencies

- Depends on: health-component/story-001
- Unlocks: PlayerController (전체 전투 루프), CompanionAI/story-002

## Completion Notes
**Completed**: 2026-05-07
**Criteria**: 4/4 passing (AC-3 구조적 보장)
**Deviations**: ADVISORY — programmatic Timer 생성 (testability); IFRAMES_DURATION const (MVP 허용)
**Test Evidence**: Logic: `tests/unit/combat/health_iframes_test.gd` (7개 테스트)
**Code Review**: Complete (/code-review 수동 실행, CHANGES REQUIRED → 수정 완료)
