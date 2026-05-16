# Epic: HealthComponent

> **Layer**: Core
> **GDD**: design/gdd/체력-데미지-시스템.md
> **Architecture Module**: HealthComponent (Core)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories health-component`

## Overview

HealthComponent는 플레이어·동료·적 모두의 체력 상태를 관리하는 Core 레이어 컴포넌트다. `hit_confirmed(attack_data)` 신호를 수신해 `final_damage = max(1, damage - defense)` 공식으로 데미지를 계산하고, `current_health`를 갱신한다. 피격 시 0.5초 Iframes을 적용하고, 체력 0 시 `health_depleted()` 신호를 발행해 사망 처리를 각 캐릭터 컨트롤러에 위임한다. 모든 전투 참여 캐릭터의 자식 노드로 단일 구현체를 공유한다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: 전투 시스템 계약 | 데미지 공식, Iframes 0.5초, health_changed/health_depleted 신호, 사망 처리 위임 | LOW |
| ADR-0005: CharacterStats Resource | stats.max_hp(초기화), stats.def(데미지 계산) computed 프로퍼티 읽기 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-health-001 | HealthComponent 컴포넌트 패턴 — 플레이어·동료·적 모두 동일한 HealthComponent 자식 노드 사용 | ADR-0004 ✅ |
| TR-health-002 | 데미지 공식: final_damage = max(1, attack_data["damage"] - target_defense) — 최소 1 보장 | ADR-0004 ✅ |
| TR-health-003 | health_depleted() 발행 후 사망 처리(애니메이션·MVP 리스폰 없음·전투 종료)는 캐릭터 컨트롤러에 위임 | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/체력-데미지-시스템.md` are verified
- `final_damage = max(1, damage - defense)` 경계값 포함 단위 테스트 통과
- `health_depleted()` 이후 `hit_confirmed` 수신 무시 — 단위 테스트 통과
- Iframes 0.5초 타이머 정상 동작 — 단위 테스트 통과
- `heal()` 초과 회복 방지 — 단위 테스트 통과

## Next Step

Run `/create-stories health-component` to break this epic into implementable stories.
