# ADR-0006: AI 내비게이션 계약 (NavigationAgent2D·동료·적 FSM)

## Status
Accepted

## Date
2026-04-28

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (AI / Navigation) |
| **Knowledge Risk** | MEDIUM — NavigationAgent2D avoidance의 velocity_computed 신호 기반 동작이 4.4~4.6에서 변경되었을 수 있음. 동료 3명 + 적 4명 동시 처리 시 60fps 수렴 여부 미검증. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | `NavigationAgent2D.velocity_computed` 신호 (4.x avoidance 패턴) |
| **Verification Required** | 동료 3명 + 적 4명(최대) 동시 활성 시 avoidance 처리가 16.6ms 프레임 예산 내에 수렴하는지 프로토타입에서 프로파일링. 수렴하지 않으면 avoidance 비활성화 후 오프셋 기반 대형으로 대체. |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0004 (Accepted) — 동료·적 AI가 CharacterBody2D + move_and_slide() 구조 위에서 동작 |
| **Depends On** | ADR-0005 (Accepted) — AI가 stats.spd, stats.atk를 CharacterStats computed 프로퍼티로 읽음 |
| **Enables** | 동료 AI 구현, 적 AI 구현, CombatEncounter 구현, 실시간 파티 전투 구현 |
| **Blocks** | 동료·적이 등장하는 모든 맵 씬 구현 |
| **Ordering Note** | ADR-0004, ADR-0005가 Accepted된 이후 이 ADR을 구현한다. NavigationRegion2D bake는 ADR-0003의 TileMapLayer 계약 위에서 수행된다. |

## Context

### Problem Statement

`동료-AI-시스템.md`와 `실시간-파티-전투.md` GDD는 각각 CompanionAI와 EnemyAI의 상태 머신을 정의하지만, 두 시스템이 공유하는 NavigationAgent2D 사용 패턴, DetectionArea2D 레이어 설정, CombatEncounter 노드 인터페이스가 하나의 ADR로 고정되지 않으면 구현자마다 다른 navigation 패턴을 선택할 수 있다. 또한 NavigationAgent2D avoidance는 MEDIUM 위험 항목으로, 프로토타입 전에 설계 계약을 먼저 고정해야 프로토타입 결과가 계약 위반인지 성능 한계인지 판별할 수 있다.

### Constraints

- NavigationAgent2D는 NavigationRegion2D가 bake된 맵 씬에서만 동작한다.
- GDScript는 싱글스레드 — AI 처리가 메인 스레드에서 실행되므로 캐릭터 수 증가 시 프레임 예산 압박이 있다.
- 동료와 적이 같은 Physics body 레이어를 피해 이동해야 한다 — avoidance 또는 오프셋으로 겹침 방지.

### Requirements

- TR-ai-001: CompanionAI가 NavigationAgent2D로 플레이어를 따라다니며 적을 자동 공격
- TR-ai-002: EnemyAI가 NavigationAgent2D로 플레이어/동료를 추격하며 공격
- TR-combat-001: CombatEncounter 노드가 구역 내 모든 적 사망 시 combat_cleared 신호 발행
- TR-combat-002: EnemySpawnZone이 PartyManager.companion_count를 읽어 적 수를 동적 결정

## Decision

### 1. NavigationAgent2D 공통 사용 패턴

동료·적 모두 동일한 패턴으로 NavigationAgent2D를 사용한다:

```gdscript
# _physics_process(delta) 내부
if not navigation_agent.is_navigation_finished():
    var next_pos: Vector2 = navigation_agent.get_next_path_position()
    var direction: Vector2 = (next_pos - global_position).normalized()
    velocity = direction * stats.spd
    move_and_slide()
```

- `target_position` 갱신: 매 프레임 또는 타겟 위치 변화 감지 시
- `avoidance_enabled`: 기본값 `false`. 프로토타입 프로파일링 통과 시에만 활성화.
- 경로 없음(`is_navigation_finished()` = true이나 목적지 미도달): 이동 정지, 현재 상태 유지.

### 2. CompanionAI 상태 머신

```
FOLLOWING ──DetectionArea2D 내 적 진입──► CHASING ──거리 ≤ ATTACK_RANGE──► ATTACKING
    ▲                                                                             │
    └──────── 적 없음 + 플레이어 근처 ◄── 적 사망 or DETECTION_RADIUS 이탈 ────────┘
                                                        ↓
                                                     DEAD (health_depleted 수신)
```

**상태별 계약:**

| 상태 | target_position | 이동 | 공격 |
|---|---|---|---|
| FOLLOWING | `player.global_position + companion_offset` | stats.spd로 이동. 거리 ≤ FOLLOW_STOP_DISTANCE면 정지 | 없음 |
| CHASING | `current_target.global_position` | stats.spd로 이동 | 없음 |
| ATTACKING | 변경 없음 | 정지 | ATTACK_COOLDOWN마다 HitboxArea2D 활성화 |
| DEAD | — | 정지 | 없음. DetectionArea2D.monitoring = false |

**동료 오프셋 (companion_offset):**

동료끼리 겹치지 않도록 파티 슬롯마다 고정 오프셋 설정. 기본값:

| 슬롯 | offset |
|---|---|
| 0 | Vector2(-60, 20) |
| 1 | Vector2(60, 20) |
| 2 | Vector2(0, 50) |

**텔레포트 임계값:**
플레이어와 거리가 `TELEPORT_THRESHOLD(600px)` 초과 시 플레이어 위치 근처로 순간이동. 화면 내에서는 텔레포트 없음.

### 3. EnemyAI 상태 머신

```
IDLE ──DetectionArea2D 내 플레이어/동료 진입──► CHASING ──거리 ≤ ENEMY_ATTACK_RANGE──► ATTACKING
  ▲                                                                                          │
  └─────────── 플레이어 사망 / 감지 범위 이탈 ◄─────────────────────────────────────────────┘
                                                       ↓
                                                    DEAD (health_depleted 수신)
```

**상태별 계약:**

| 상태 | target_position | 이동 | 공격 |
|---|---|---|---|
| IDLE | — | 정지 | 없음 |
| CHASING | `current_target.global_position` | stats.spd로 이동 | 없음 |
| ATTACKING | 변경 없음 | 정지 | ENEMY_ATTACK_COOLDOWN마다 HitboxArea2D 활성화 |
| DEAD | — | 정지 | 없음 |

**타겟 우선순위**: 플레이어 > 가장 가까운 동료.

### 4. DetectionArea2D 레이어 설정

| 노드 | Area2D Layer | Area2D Mask | 용도 |
|---|---|---|---|
| 동료 DetectionArea2D | `player_body` (2) | `enemy_body` (3) | 동료가 적 body 진입 감지 |
| 적 DetectionArea2D | `enemy_body` (3) | `player_body` (2) | 적이 플레이어/동료 body 진입 감지 |

DetectionArea2D는 ADR-0004의 Physics 레이어 번호를 그대로 사용한다.

### 5. CombatEncounter 노드 계약

맵 씬의 전투 구역마다 `CombatEncounter` Node를 배치한다.

```gdscript
# CombatEncounter.gd
signal combat_cleared(encounter_id: StringName)

# 관리하는 적 목록 — 씬에서 @export로 연결
@export var enemies: Array[EnemyBase] = []
```

모든 적의 `health_depleted()` 신호를 수신. 목록 내 생존 적이 0이 되면 `combat_cleared(encounter_id)` 발행.

**EC-base_enemy_count = 0**: 적 없는 CombatEncounter는 씬 로드 시 즉시 `combat_cleared` 발행.

### 6. EnemySpawnZone — 적 수 스케일링

```gdscript
# EnemySpawnZone.gd — _ready()에서 호출
func _calculate_enemy_count() -> int:
    var companion_count: int = PartyManager.companion_count
    return base_enemy_count + companion_count * ENEMY_SCALE_PER_COMPANION
```

| 변수 | 기본값 | 설명 |
|---|---|---|
| `base_enemy_count` | 3 | 동료 없을 때 기본 적 수 |
| `ENEMY_SCALE_PER_COMPANION` | 1 | 동료 1명당 추가 적 수 |

예시: 동료 3명 → `3 + (3 × 1) = 6`마리

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     MapScene                            │
│                                                         │
│  ┌──────────────┐    ┌────────────────────────────────┐ │
│  │ NavigationRe-│    │       CombatEncounter          │ │
│  │ gion2D (baked│    │  enemies: [Enemy0, Enemy1, ...]│ │
│  │  TileMapLayer│    │  signal combat_cleared(id)     │ │
│  │  bake 필요)  │    └──────────────┬─────────────────┘ │
│  └──────────────┘                  │ health_depleted    │
│                                    ▼                    │
│  ┌──────────────┐    ┌────────────────────────────────┐ │
│  │ CompanionAI  │    │          EnemyAI               │ │
│  │ FOLLOWING    │    │  IDLE → CHASING → ATTACKING    │ │
│  │ CHASING      │    │  NavigationAgent2D             │ │
│  │ ATTACKING    │    │  DetectionArea2D               │ │
│  │ NavigationAge│    └────────────────────────────────┘ │
│  │ DetectionArea│                                       │
│  └──────────────┘                                       │
└─────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Steering Behavior (직접 방향 계산)

- **Description**: NavigationAgent2D 없이 플레이어 방향으로 직접 velocity 계산
- **Pros**: NavigationAgent2D 의존성 없음. 장애물 없는 오픈 필드에서 단순
- **Cons**: 장애물 우회 불가. 픽셀 아트 맵에는 벽과 장애물이 있어 캐릭터가 막히는 문제 발생
- **Rejection Reason**: GDD에서 NavigationAgent2D 명시. 장애물 우회는 MVP 필수 요건

### Alternative 2: avoidance 기본 활성화

- **Description**: NavigationAgent2D avoidance_enabled = true를 기본으로 설정
- **Pros**: 동료·적 겹침 자동 방지
- **Cons**: velocity_computed 신호 기반 avoidance는 추가 CPU 비용. 동료 3명 + 적 4명 동시 처리 시 60fps 수렴 미검증
- **Rejection Reason**: 프로파일링 통과 전에는 비활성화가 안전한 기본값. 오프셋 기반 대형(CompanionAI)과 타겟 분산(EnemyAI 자연 분산)으로 MVP 수준 겹침 완화 가능

## Consequences

### Positive

- 동료·적 AI가 동일한 NavigationAgent2D 패턴을 공유 — 코드 리뷰와 디버그 비용 절감
- CombatEncounter 계약이 고정되어 퀘스트·이벤트 시스템이 `combat_cleared` 신호에 일관되게 반응
- 적 수 스케일링 공식이 한 곳(EnemySpawnZone)에 집중 — 밸런스 조정이 코드 수정 없이 가능

### Negative

- avoidance 비활성화 기본값 — 동료·적 겹침이 MVP에서 발생할 수 있음. 오프셋과 자연 분산으로 완화하지만 완전 해결은 아님
- NavigationRegion2D bake 의존성 — 맵 씬 변경 시 rebake 필요

### Risks

- **위험**: avoidance 활성화 시 60fps 미달 → **완화**: Verification Required 명시. 프로토타입에서 프로파일링 후 이 ADR 업데이트
- **위험**: NavigationRegion2D bake 없이 맵 씬 배포 → **완화**: `/smoke-check` 체크리스트에 Navigation bake 확인 포함
- **위험**: companion_count가 PartyManager 초기화 전에 읽힘 → **완화**: ADR-0002의 Autoload 초기화 순서 계약 준수 (PartyManager는 EventBus 다음 등록)

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 이 ADR의 해결 방식 |
|---|---|---|
| 동료-AI-시스템.md | R-1~R-6: FOLLOWING/CHASING/ATTACKING/DEAD 상태, NavigationAgent2D, DetectionArea2D, 오프셋, 텔레포트 | CompanionAI FSM 계약 및 상태별 target_position 규칙 명문화 |
| 실시간-파티-전투.md | R-1~R-3: 적 AI IDLE/CHASING/ATTACKING, 타겟 우선순위 | EnemyAI FSM 계약 명문화 |
| 실시간-파티-전투.md | R-4: CombatEncounter 노드, combat_cleared 신호 | CombatEncounter 노드 인터페이스 고정 |
| 실시간-파티-전투.md | R-5: 파티 규모 연동 적 수 스케일링 | EnemySpawnZone 공식 및 변수 고정 |

## Performance Implications

- **CPU**: NavigationAgent2D 경로 계산 — 동료 3명 + 적 4명 = 최대 7개 agent 동시 처리. avoidance 비활성화 상태에서 2D 픽셀 아트 맵 스케일이면 16.6ms 예산 내 처리 예상. 검증 필요.
- **Memory**: NavigationAgent2D 인스턴스 7개 — 수 KB 수준
- **Profiling Gate**: 동료 3명 + 적 6명(최대 — 동료 3명 × ENEMY_SCALE_PER_COMPANION 1 + base 3) 동시 활성 시 60fps 유지를 프로토타입에서 확인 후 이 ADR에 결과 기록

## Migration Plan

신규 프로젝트. NavigationRegion2D를 맵 씬 루트에 배치하고 TileMapLayer를 NavigationRegion2D 하위로 구성한 뒤 bake한다. 에디터에서 Navigation > Bake NavigationPolygon 실행 또는 씬 로드 시 `NavigationServer2D.bake_from_source_geometry_data()` 호출.

## Validation Criteria

- 동료가 장애물 있는 맵에서 플레이어를 따라 경로를 우회하여 이동
- 적이 플레이어 감지 후 NavigationAgent2D 경로로 추격
- 맵 내 모든 적 처치 시 `combat_cleared` 신호 정확히 1회 발행 (단위 테스트)
- 동료 0/1/3명 시 스폰 적 수가 각각 3/4/6 (단위 테스트)
- 동료 3명 + 적 6명 동시 활성 시 60fps 유지 (프로토타입 프로파일링)

## Related Decisions

- design/gdd/동료-AI-시스템.md
- design/gdd/실시간-파티-전투.md
- ADR-0003 (씬·맵 계약 — TileMapLayer + NavigationRegion2D bake 계약)
- ADR-0004 (전투 시스템 계약 — CharacterBody2D 구조, Physics 레이어)
- ADR-0005 (CharacterStats Resource — stats.spd, stats.atk 공급자)
