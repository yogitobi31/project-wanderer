# Epic: PlayerController

> **Layer**: Core
> **GDD**: design/gdd/플레이어-캐릭터-컨트롤러.md
> **Architecture Module**: PlayerController (Core)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories player-controller`

## Overview

PlayerController는 플레이어가 직접 조종하는 캐릭터의 이동·공격·상태를 관리하는 Core 레이어 시스템이다. `InputMapManager.get_move_vector()`로 입력을 받아 `CharacterBody2D.move_and_slide()`로 이동하고, 공격 입력 시 `HitboxArea2D.monitoring`을 활성화한다. IDLE/MOVING/ATTACKING/DEAD 4-state FSM을 구현하며, `HealthComponent`의 `health_depleted` 신호를 수신해 DEAD 상태로 전환한다. `set_spawn_position(pos)` 메서드로 SceneTransitionManager와의 씬 전환 계약을 이행한다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: 전투 시스템 계약 | CharacterBody2D 루트 구조, HitboxArea2D 기본 monitoring=false, attack_data Dictionary 스펙 | LOW |
| ADR-0005: CharacterStats Resource | stats.max_hp, stats.spd computed 프로퍼티만 읽기 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-player-001 | PlayerController — CharacterBody2D 루트 + move_and_slide() 이동 | ADR-0004 ✅ |
| TR-player-002 | 플레이어 씬 루트 구조가 동료·적과 동일 — CharacterBody2D + HealthComponent + HurtboxArea2D + HitboxArea2D | ADR-0004 ✅ |
| TR-player-003 | HitboxArea2D는 공격 애니메이션 특정 프레임에서만 monitoring=true — 상시 활성 금지 | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/플레이어-캐릭터-컨트롤러.md` are verified
- 이동·공격·사망 FSM 단위 테스트 통과
- `set_spawn_position()` 호출 시 즉시 위치 이동 — 단위 테스트 통과
- DEAD 상태에서 이동/공격 입력 무시 — 단위 테스트 통과
- 씬 구조가 ADR-0004 계약 준수 — `/architecture-review` 통과
- All Visual/Feel stories have screenshot evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories player-controller` to break this epic into implementable stories.
