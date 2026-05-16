# Story 002: PlayerController — ATTACKING FSM + HitboxArea2D monitoring

> **Epic**: PlayerController
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/플레이어-캐릭터-컨트롤러.md`
**Requirements**: `TR-player-003`

**ADR Governing Implementation**: ADR-0004: 전투 시스템 계약
**ADR Decision Summary**: HitboxArea2D `monitoring = false` 기본. 공격 애니메이션 특정 프레임에서만 `true`. `attack_data = {"damage": stats.atk, "knockback": 0.0, "source": self}` 생성 후 hurtbox에 `hit_confirmed` 호출.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Required: HitboxArea2D 기본 `monitoring = false` — 애니메이션 프레임에서만 `true`
- Required: `attack_data` 스펙: `{"damage": int, "knockback": float, "source": Node}`
- Forbidden: HitboxArea2D 상시 활성 (Forbidden Pattern)
- Forbidden: Hitbox에서 데미지 계산 (HealthComponent만)

---

## Acceptance Criteria

- [ ] **AC-1**: 공격 입력 시 ATTACKING 상태로 전환, 이동 불가
- [ ] **AC-2**: 공격 애니메이션 활성 프레임에서 `hitbox.monitoring == true`
- [ ] **AC-3**: 공격 애니메이션 종료 후 `hitbox.monitoring == false` 복원
- [ ] **AC-4**: `area_entered` 수신 시 `hit_confirmed({"damage": stats.atk, "knockback": 0.0, "source": self})` 를 hurtbox 소유 HealthComponent에 호출
- [ ] **AC-5**: ATTACKING 상태 완료 후 IDLE로 복귀

---

## Implementation Notes

1. ATTACKING 상태 추가:
   ```gdscript
   @onready var hitbox: Area2D = $HitboxArea2D

   func _on_attack_input() -> void:
       if _state in [State.DEAD, State.ATTACKING]:
           return
       _state = State.ATTACKING
       # AnimationPlayer로 attack 애니메이션 재생
       # 애니메이션 트랙에서 hitbox.monitoring true/false 제어
   ```
2. AnimationPlayer 트랙에 `HitboxArea2D.monitoring` bool 키프레임 추가
   - 공격 프레임 시작: `true`
   - 공격 프레임 종료: `false`
3. `HitboxArea2D.area_entered` 연결:
   ```gdscript
   func _on_hitbox_area_entered(hurtbox: Area2D) -> void:
       var health_comp: HealthComponent = hurtbox.get_owner().get_node_or_null("HealthComponent")
       if health_comp:
           health_comp.hit_confirmed({"damage": stats.atk, "knockback": 0.0, "source": self})
   ```
4. 애니메이션 완료 시 `_state = State.IDLE`

---

## Out of Scope

- 공격 애니메이션 실제 아트 — Visual/Feel story로 분리 가능
- 넉백 처리 — MVP knockback=0.0

---

## QA Test Cases

- **AC-2/3**: `hitbox.monitoring` 타이밍 — AnimationPlayer 트랙 수동 확인 (Visual story)
- **AC-4**: `area_entered` emit 시 target HealthComponent의 `hit_confirmed` 호출 확인 (mock hurtbox)

---

## Test Evidence

**Story Type**: Logic + Visual/Feel
**Required evidence**:
- `tests/unit/player/player_attack_test.gd` — AC-4, AC-5 커버
- 공격 애니메이션 스크린샷 → `production/qa/evidence/player-attack-animation.png`

---

## Size Estimate

**Estimate**: 3–4 hours
- ATTACKING FSM + HitboxArea2D 연결: 1.5시간
- AnimationPlayer 트랙 설정: 1시간
- GUT 테스트: 1시간

---

## Dependencies

- Depends on: player-controller/story-001, health-component/story-001
- Unlocks: player-controller/story-003 (DEAD), CompanionAI (전투 루프)

## Completion Notes
**Completed**: 2026-05-08
**Criteria**: 3/5 passing (AC-2, AC-3 DEFERRED — AnimationPlayer 키프레임 + PlayerController.tscn 에디터 씬 작업)
**Deviations**: ADVISORY — `get_parent()` 사용(get_owner() 대신, 헤드리스 테스트 호환); `Input.is_action_just_pressed()` 직접 사용(InputMapManager 래퍼 미구현); PlayerController.tscn 미생성
**Test Evidence**: Logic: `tests/unit/player/player_attack_test.gd` (10개 테스트, AC-1/4/5 커버)
**Code Review**: Complete (/code-review 수동 실행, CHANGES REQUIRED → 수정 완료 → APPROVED)
