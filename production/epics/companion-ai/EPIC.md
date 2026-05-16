# Epic: CompanionAI

> **Layer**: Core
> **GDD**: design/gdd/동료-AI-시스템.md
> **Architecture Module**: CompanionAI + EnemyAI (Feature)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories companion-ai`

## Overview

CompanionAI는 파티 동료들이 플레이어를 따라다니며 적을 자동 공격하는 AI를 구현한다. `NavigationAgent2D` 기반 경로 탐색으로 장애물을 우회하고, FOLLOWING/CHASING/ATTACKING/DEAD 4-state FSM으로 행동을 전환한다. EnemyAI(IDLE/CHASING/ATTACKING/DEAD)와 CombatEncounter(전투 구역 관리, `combat_cleared` 신호)도 이 에픽에 포함된다. `avoidance_enabled` 기본 false — 동료 3명 + 적 6명 60fps 프로파일링 통과 후에만 활성화.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: 전투 시스템 계약 | CharacterBody2D 루트 구조, HitboxArea2D 패턴, attack_data 스펙 | LOW |
| ADR-0005: CharacterStats Resource | stats.spd, stats.atk computed 프로퍼티만 읽기 | LOW |
| ADR-0006: AI 내비게이션 계약 | NavigationAgent2D 패턴, CompanionAI/EnemyAI FSM, DetectionArea2D 레이어, CombatEncounter, EnemySpawnZone | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ai-001 | CompanionAI — NavigationAgent2D 기반 4-state FSM (FOLLOWING/CHASING/ATTACKING/DEAD), 동료 오프셋 대형 | ADR-0006 ✅ |
| TR-ai-002 | EnemyAI — NavigationAgent2D 기반 4-state FSM (IDLE/CHASING/ATTACKING/DEAD), 타겟 우선순위: 플레이어 > 가장 가까운 동료 | ADR-0006 ✅ |
| TR-combat-001 | CombatEncounter — 구역 내 모든 적 health_depleted() 수신 시 combat_cleared(encounter_id) 신호 발행 | ADR-0006 ✅ |
| TR-combat-002 | EnemySpawnZone — enemy_count = base_enemy_count(3) + companion_count × ENEMY_SCALE_PER_COMPANION(1) | ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/동료-AI-시스템.md` are verified
- 동료 0/1/3명 시 스폰 적 수가 각각 3/4/6 — 단위 테스트 통과
- `combat_cleared` 신호가 모든 적 사망 시 정확히 1회 발행 — 단위 테스트 통과
- DEAD 상태 동료 DetectionArea2D 비활성 — 단위 테스트 통과
- 동료 3명 + 적 6명 동시 활성 시 60fps 유지 — 프로토타입 프로파일링 통과
- All Visual/Feel stories have screenshot/video evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories companion-ai` to break this epic into implementable stories.
