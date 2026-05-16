# 동료 AI 시스템 (Companion AI System)

> **Status**: Reviewed
> **Author**: Juwon + agents
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 2 (눈에 보이는 성장) — 동료 합류마다 전투가 눈에 띄게 달라지는 핵심
> **Risk Level**: HIGH — 10명 동시 실시간 AI, Godot NavigationAgent2D 미검증

## Overview

동료 AI 시스템은 파티에 합류한 동료들이 플레이어를 따라다니며 적을 자동으로 공격하는 행동을 제어한다. 플레이어 컨트롤러와 동일한 `CharacterBody2D` + Hitbox/Hurtbox 구조를 사용하지만, 입력 대신 상태 머신 기반 AI로 제어된다.

MVP 핵심 가설: **동료가 "오브젝트처럼 따라다니는 것"이 아니라 "함께 싸우는 동료"처럼 느껴지는가.** 이것이 Pillar 2의 실현이다.

**AI 상태 머신:**
```
FOLLOWING ──적 감지 범위 진입──► CHASING ──공격 범위 도달──► ATTACKING
    ▲                                                              │
    │                                                 적 사망/범위 이탈
    └──────────────── 적 없음 + 플레이어 근처 ◄────────────────────┘
```

이동은 Godot 4의 `NavigationAgent2D`로 처리 — 장애물을 돌아가는 경로를 자동 계산한다. `move_and_slide()`는 플레이어 컨트롤러와 동일하게 사용.

## Player Fantasy

내가 이동하면 동료들이 따라온다. 적이 나타나면 동료들이 알아서 달려들어 싸운다. 나는 전략적으로 움직이고, 동료들은 내 의도를 읽어 행동한다. 3명이 함께 싸우는 화면은 혼자 싸울 때와 완전히 다른 활기를 가진다.

## Detailed Rules

**R-1: FOLLOWING 상태**
`NavigationAgent2D.target_position = player.global_position`. 매 프레임 갱신. 플레이어와의 거리가 `FOLLOW_STOP_DISTANCE` 이하면 이동 정지 (플레이어에 밀착하지 않음).

**R-2: 적 감지**
`DetectionArea2D` (반경 `DETECTION_RADIUS`의 `Area2D`) 내 `enemy_body` 레이어 진입 시 → `CHASING`. 가장 가까운 적을 `current_target`으로 설정.

**R-3: CHASING 상태**
`NavigationAgent2D.target_position = current_target.global_position`. 매 프레임 갱신. `current_target`과의 거리 ≤ `ATTACK_RANGE`이면 → `ATTACKING`.

**R-4: ATTACKING 상태**
이동 정지. `ATTACK_COOLDOWN`마다 공격 애니메이션 재생 + Hitbox 활성화. `current_target`이 사망하거나 `DETECTION_RADIUS` 밖으로 이탈하면:
- 감지 범위 내 다른 적 있으면 → 새 `current_target` 설정, `CHASING` 유지
- 없으면 → `FOLLOWING`

**R-5: 동료 간 분산 (오프셋)**
동료마다 플레이어 기준 고정 오프셋(`companion_offset`) 설정 — 동료들이 서로 겹치지 않고 퍼져서 따라옴. FOLLOWING 목표는 `player.global_position + companion_offset`.

**R-6: 사망**
체력/데미지 시스템 `health_depleted()` 수신 → `DEAD` 상태. 이동/공격 중단, Hurtbox 비활성. MVP에서 동료 사망 후 부활 없음 — 해당 전투 종료까지 이탈.

## Formulas

**F-1: FOLLOWING 이동**
```
direction = NavigationAgent2D.get_next_path_position() - global_position
velocity = direction.normalized() * move_speed
```

| 변수 | 출처 | 설명 |
|------|------|------|
| `move_speed` | 능력치 시스템 `stats.spd` | 동료마다 다를 수 있음 |

**F-2: 적 거리 판정**
```
distance_to_target = global_position.distance_to(current_target.global_position)
can_attack = distance_to_target <= ATTACK_RANGE
```

**F-3: 가장 가까운 적 선택**
```
nearest_enemy = enemies_in_range.min_by(e => global_position.distance_to(e.global_position))
```
`DetectionArea2D` 내 적 목록에서 매 탐지 이벤트마다 재계산.

**F-4: 공격 쿨다운**
플레이어 컨트롤러 F-2와 동일:
```
can_attack = (current_time - last_attack_time) >= ATTACK_COOLDOWN
```

## Edge Cases

**EC-1: `current_target` 사망 중 ATTACKING**
R-4에 정의됨 — `health_depleted()` 신호로 사망 감지. 신호 수신 즉시 `current_target = null`, 다음 타겟 탐색.

**EC-2: 플레이어가 빠르게 이동해 동료가 너무 멀어짐**
`NavigationAgent2D`가 새 경로 계산. 거리가 `TELEPORT_THRESHOLD` 초과 시 플레이어 위치 근처로 순간이동 (화면 밖에서 멀어진 경우). 화면 내에서는 순간이동 없음.

**EC-3: 동료 여럿이 같은 적을 타겟**
허용. 동료들이 같은 적에게 몰릴 수 있음. MVP에서 타겟 분산 로직 없음 — 가장 가까운 적을 각자 선택하면 자연스럽게 분산됨.

**EC-4: NavigationAgent2D 경로 없음 (막힌 공간)**
`NavigationAgent2D.is_navigation_finished()` 확인. 경로 없으면 이동 정지 + `FOLLOWING` 유지. 순간이동 없음.

**EC-5: 동료가 ATTACKING 중 플레이어가 멀리 이동**
MVP에서 동료는 전투 중 플레이어를 따라가지 않음. 전투 완료 후 FOLLOWING으로 복귀.

**EC-6: DEAD 상태 동료의 DetectionArea2D**
`DEAD` 진입 시 `DetectionArea2D.monitoring = false`. 사망한 동료는 새 적을 감지하지 않음.

## Dependencies

**이 시스템이 의존하는 것 (Upstream)**

| 시스템 | 의존 내용 |
|--------|-----------|
| **능력치 시스템** | `stats.spd`, `stats.atk` 참조 (능력치-시스템.md 권위 필드명) |
| **히트박스/충돌 감지** | `CharacterBody2D` 구조, `HitboxArea2D.monitoring` 제어, `DetectionArea2D` Layer/Mask |
| **NPC 상태 관리** | 동료의 합류 여부(`is_recruited`) 확인. 미합류 동료는 AI 비활성. |
| **체력/데미지 시스템** | `health_depleted()` 수신 → `DEAD` 상태 진입 |

**이 시스템에 의존하는 것 (Downstream)**

| 시스템 | 의존 내용 |
|--------|-----------|
| **실시간 파티 전투** | 동료 AI가 전투의 절반을 구성. 이 시스템 없이는 파티 전투 불가. |
| **플레이어 캐릭터 컨트롤러** | `player.global_position` 참조 (FOLLOWING 목표) |
| **동료 합류 이벤트** | 합류 시 AI 활성화 트리거 |

**프로토타입 필수**
이 시스템은 High-Risk — 설계 완료 후 즉시 `/prototype companion-ai` 실행 권장. "함께 싸우는 느낌"은 수치로 설계할 수 없고 플레이테스트로만 검증 가능.

## Tuning Knobs

| 변수 | 기본값 | 안전 범위 | 영향 |
|------|--------|-----------|------|
| `DETECTION_RADIUS` | 200 px | 100–400 px | 클수록 동료가 먼 적도 달려듦. 너무 크면 동료가 항상 산개해 "팀" 느낌 약화 |
| `ATTACK_RANGE` | 50 px | 30–150 px | 근접 공격 기준. 원거리 동료는 이 값을 크게 설정 |
| `FOLLOW_STOP_DISTANCE` | 60 px | 30–120 px | 플레이어 주변 얼마나 붙어서 멈추는지. 너무 작으면 동료가 플레이어에 겹침 |
| `ATTACK_COOLDOWN` | 0.8초 | 0.3–2.0초 | 플레이어보다 약간 느리게 — 동료가 주연이 아닌 서포터 느낌 |
| `TELEPORT_THRESHOLD` | 600 px | 400–1000 px | 이 거리 초과 시 순간이동. 화면 크기 기준으로 설정 |
| `companion_offset` | 동료마다 수동 설정 | — | 3명 기준: `(-60, 20)`, `(60, 20)`, `(0, 50)` 등 삼각 대형 |

> **조정 지침**: `DETECTION_RADIUS`와 `FOLLOW_STOP_DISTANCE`의 관계가 핵심. 감지 범위 >> 정지 거리여야 동료가 적을 향해 앞으로 나가는 느낌이 남.

## Acceptance Criteria

| # | 조건 | 검증 방법 |
|---|------|-----------|
| AC-1 | 플레이어 이동 시 동료가 `FOLLOW_STOP_DISTANCE` 유지하며 따라온다 | 수동 플레이테스트 |
| AC-2 | `DETECTION_RADIUS` 내 적 등장 시 동료가 해당 적을 향해 이동한다 | 수동 플레이테스트 |
| AC-3 | `ATTACK_RANGE` 도달 시 동료가 `ATTACK_COOLDOWN` 간격으로 공격한다 | 수동 플레이테스트 |
| AC-4 | 적 사망 후 다른 적이 없으면 동료가 플레이어에게 복귀한다 | 수동 플레이테스트 |
| AC-5 | 동료 3명이 동시에 활성화되어도 60fps를 유지한다 | 성능 테스트 |
| AC-6 | 동료끼리 겹치지 않고 플레이어 주변에 퍼져서 따라온다 | 수동 플레이테스트 |
| AC-7 | `DEAD` 상태 동료는 이동/공격을 멈추고 새 적을 감지하지 않는다 | 단위 테스트 |
