# ADR-0004: 전투 시스템 계약 (물리 레이어·데미지·HealthComponent)

## Status
Accepted

## Date
2026-04-28

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Physics / Combat) |
| **Knowledge Risk** | LOW — CharacterBody2D, Area2D, move_and_slide()는 4.4~4.6 변경 없음 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | 없음 |
| **Verification Required** | 없음 |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0002 (Accepted) — HealthComponent가 Autoload 계층 위에서 동작하는 Core 컴포넌트임을 확인 |
| **Enables** | 플레이어 컨트롤러 구현, 동료 AI 구현, 적 AI 구현, 체력 UI 구현 |
| **Blocks** | 전투 판정이 필요한 모든 씬 구현 |
| **Ordering Note** | 플레이어·동료·적 씬(.tscn) 작업 전 이 ADR이 Accepted여야 한다. |

## Context

### Problem Statement

`체력-데미지-시스템.md`, `히트박스-충돌-감지.md`, `플레이어-캐릭터-컨트롤러.md` GDD 세 개가 공통으로 참조하는 물리 레이어 번호, 신호 체인, 데미지 공식을 단일 ADR로 고정하지 않으면 씬마다 레이어 번호 불일치, hit_confirmed 연결 방식 불일치, 데미지 계산 중복 구현이 발생한다. 이 ADR은 전투 Core 레이어의 "물리적 계약"을 명문화하여 세 GDD 구현체의 구조적 일치를 보장한다.

### Constraints

- 이동 물리와 전투 판정을 분리해야 한다 — 피격 판정과 이동이 같은 콜라이더를 공유하면 튜닝이 불가능해진다.
- 플레이어·동료·적이 동일한 컴포넌트를 사용해야 한다 — 종류마다 별도 HealthComponent를 만들면 버그 발산 위험이 있다.
- Physics 레이어 번호는 한 번 정하면 바꾸기 어렵다 (프로젝트 설정 + 모든 씬에 영향).

### Requirements

- TR-hitbox-001: 모든 전투 판정은 Area2D 기반 Hitbox/Hurtbox로 처리 (PhysicsBody 직접 충돌 금지)
- TR-hitbox-002: Physics 레이어 번호가 프로젝트 전체에서 일관되게 사용됨
- TR-hitbox-003: 동일 공격에 다단 피격 방지 (Iframes 메커니즘)
- TR-health-001: HealthComponent가 플레이어·동료·적에서 동일한 구조로 동작함
- TR-health-002: `final_damage = max(1, damage - defense)` 공식이 모든 피격에 적용됨
- TR-health-003: 사망 처리가 HealthComponent에서 위임(delegation)으로 분리됨
- TR-player-001: 플레이어 이동이 CharacterBody2D + move_and_slide()로 구현됨
- TR-player-002: 플레이어 루트 노드 구조가 동료·적 구조와 일치함
- TR-player-003: 공격 Hitbox가 애니메이션 프레임에만 활성화됨

## Decision

### 1. Physics 레이어 번호 (프로젝트 고정값)

| Layer | 이름 | 사용처 |
|---|---|---|
| 1 | `world` | 지형, 벽, 장애물 |
| 2 | `player_body` | 플레이어·동료 이동 충돌체 |
| 3 | `enemy_body` | 적 이동 충돌체 |
| 4 | `player_hitbox` | 플레이어·동료 공격 판정 |
| 5 | `enemy_hitbox` | 적 공격 판정 |
| 6 | `player_hurtbox` | 플레이어·동료 피격 판정 |
| 7 | `enemy_hurtbox` | 적 피격 판정 |

레이어 번호를 변경하려면 이 ADR을 Supersede하고 모든 씬을 일괄 수정해야 한다.

### 2. 캐릭터 루트 노드 구조 (공통 계약)

모든 전투 참여 캐릭터(플레이어·동료·적)는 동일한 씬 구조를 따른다:

```
CharacterBody2D              ← 캐릭터 루트. Layer: player_body 또는 enemy_body. Mask: world.
├── CollisionShape2D         ← 이동 충돌체 (월드/body 레이어)
├── HealthComponent          ← 체력·데미지 처리 노드 (Core 컴포넌트)
├── HurtboxArea2D            ← 피격 판정. Layer: *_hurtbox. Mask: *_hitbox (상대 진영).
│   └── CollisionShape2D
└── HitboxArea2D             ← 공격 판정. Layer: *_hitbox. Mask: *_hurtbox (상대 진영).
    └── CollisionShape2D     ← 평소 monitoring = false. 공격 애니메이션 프레임에서만 true.
```

이 구조에서 벗어난 캐릭터 씬은 Forbidden Pattern이다.

### 3. 충돌 마스크 규칙

| 노드 | Layer | Mask |
|---|---|---|
| 플레이어·동료 CharacterBody2D | `player_body` (2) | `world` (1) |
| 적 CharacterBody2D | `enemy_body` (3) | `world` (1) |
| 플레이어·동료 HitboxArea2D | `player_hitbox` (4) | `enemy_hurtbox` (7) |
| 적 HitboxArea2D | `enemy_hitbox` (5) | `player_hurtbox` (6) |
| 플레이어·동료 HurtboxArea2D | `player_hurtbox` (6) | `enemy_hitbox` (5) |
| 적 HurtboxArea2D | `enemy_hurtbox` (7) | `player_hitbox` (4) |

### 4. 신호 체인 (hit_confirmed 계약)

```
HitboxArea2D.area_entered(hurtbox: Area2D)
  → Hitbox 소유자가 hurtbox.owner (HealthComponent)에게
    hit_confirmed(attack_data: Dictionary) 신호 전달
  → HealthComponent가 수신
      → 데미지 계산 (F-1)
      → health_changed(current: int, maximum: int) 발행
      → current_health == 0이면 health_depleted() 발행
```

Hitbox는 데미지를 직접 계산하지 않는다. 데미지 계산은 HealthComponent만 수행한다.

**attack_data Dictionary 스펙:**

```gdscript
attack_data = {
    "damage": int,        # 공격자의 stats.atk
    "knockback": float,   # 넉백 강도 (px/s). MVP에서 0.0
    "source": Node        # 공격자 노드 참조
}
```

### 5. 데미지 공식

```
final_damage = max(1, attack_data["damage"] - target_defense)
```

| 변수 | 출처 | 설명 |
|---|---|---|
| `attack_data["damage"]` | 공격자 `stats.atk` | Hitbox 소유자가 attack_data에 주입 |
| `target_defense` | 피격자 `stats.def` | HealthComponent가 피격자 CharacterStats에서 읽음 |
| `final_damage` | — | 최솟값 1 보장. 방어력 ≥ 공격력이어도 최소 1 데미지. |

### 6. Invincibility Frame (Iframes)

```
IFRAMES_DURATION = 0.5초
```

피격 시 HealthComponent가 즉시 `HurtboxArea2D.monitoring = false`로 설정. `IFRAMES_DURATION` 후 `monitoring = true` 복원. 이 타이머는 HealthComponent 내부 Timer 노드로 관리한다.

### 7. HealthComponent 공개 인터페이스

```gdscript
# HealthComponent.gd
signal health_changed(current: int, maximum: int)
signal health_depleted()

func heal(amount: int) -> void
```

사망 처리(애니메이션, 리스폰, 전투 종료)는 HealthComponent가 직접 수행하지 않는다. `health_depleted()` 수신자(플레이어 컨트롤러, 동료 AI, 적 AI)가 각자 처리한다.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│ CharacterBody2D (Player / Companion / Enemy)        │
│                                                     │
│  ┌──────────────┐   ┌─────────────────────────────┐ │
│  │ CollisionShape│   │      HealthComponent        │ │
│  │ (move/world) │   │  hit_confirmed(attack_data) │ │
│  └──────────────┘   │  → final_damage = max(1,    │ │
│                     │    damage - defense)         │ │
│  ┌───────────────┐  │  health_changed(cur, max)   │ │
│  │ HurtboxArea2D │  │  health_depleted()           │ │
│  │ monitoring=T  │──┤  iframes: monitoring=F→T    │ │
│  └───────────────┘  └─────────────────────────────┘ │
│                                                     │
│  ┌───────────────┐                                  │
│  │ HitboxArea2D  │ ← animation frame: monitoring=T │
│  │ monitoring=F  │   area_entered → hit_confirmed   │
│  └───────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: PhysicsBody 직접 충돌로 데미지 계산

- **Description**: CharacterBody2D 간 충돌 시 데미지 처리
- **Pros**: 구조 단순
- **Cons**: 이동 물리와 전투 판정이 결합 — 독립 튜닝 불가. 다단 피격 방지 메커니즘 구현이 복잡해짐.
- **Rejection Reason**: Hitbox/Hurtbox 분리가 Godot 2D 게임의 표준 패턴이며 GDD에서 이미 결정됨

### Alternative 2: 캐릭터 종류마다 별도 Health 클래스

- **Description**: PlayerHealth, CompanionHealth, EnemyHealth 분리
- **Pros**: 종류별 특수 동작 구현 편의
- **Cons**: 데미지 공식·Iframes 로직 중복. 버그 수정 시 세 곳 수정 필요.
- **Rejection Reason**: GDD에서 "동일한 HealthComponent 컴포넌트" 원칙 명시

## Consequences

### Positive

- Physics 레이어 번호가 프로젝트 전체에서 단일 진실 출처로 고정됨
- 플레이어·동료·적 씬이 동일 구조를 공유 — 리뷰와 디버그 비용 절감
- 데미지 공식이 한 곳(HealthComponent)에 집중 — 밸런스 수정이 즉각 전파됨

### Negative

- 레이어 번호 변경 시 모든 씬을 일괄 수정해야 함 — 초기에 올바르게 설정해야 함
- HitboxArea2D monitoring 토글을 애니메이션 트랙에서 관리해야 함 — 애니메이터와의 협업 필요

### Risks

- **위험**: 새 캐릭터 씬에서 레이어 번호 오기입 → **완화**: Forbidden Pattern 등록, `/dev-story` 체크리스트에 레이어 번호 검증 포함
- **위험**: HitboxArea2D monitoring을 해제하지 않고 상시 활성 → **완화**: Forbidden Pattern 등록 (상시 활성 Hitbox 금지)

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 이 ADR의 해결 방식 |
|---|---|---|
| 히트박스-충돌-감지.md | R-1~R-6: Physics 레이어 번호, Hitbox/Hurtbox 구조, 충돌 마스크, 신호 흐름, Iframes | Physics 레이어 고정, 노드 구조 계약, 신호 체인 명문화 |
| 체력-데미지-시스템.md | R-1~R-5, F-1~F-3: HealthComponent 구조, 데미지 공식, Iframes, 회복 | 공식 고정, HealthComponent 계약, Iframes 상수 고정 |
| 플레이어-캐릭터-컨트롤러.md | CharacterBody2D 루트 구조, move_and_slide() 사용 | 공통 루트 노드 구조 명문화 |

## Performance Implications

- **CPU**: Area2D 충돌 감지는 Godot Physics가 처리. 7레이어 × 캐릭터 수 — 2D 픽셀 아트 스케일에서 무시 가능.
- **Memory**: HealthComponent 노드 1개 / 캐릭터 — 수십 바이트 수준.
- **Frame Budget**: HurtboxArea2D monitoring 토글은 `set()` 1회 — 측정 불필요.

## Validation Criteria

- 플레이어·동료·적 씬의 Physics 레이어 번호가 이 ADR의 표와 일치
- `final_damage = max(1, damage - defense)` 단위 테스트 통과 (defense ≥ damage 케이스 포함)
- 동일 공격에 2회 피격 없음 — Iframes 0.5초 단위 테스트 통과
- `health_depleted()` 이후 `hit_confirmed` 수신이 무시됨 — 단위 테스트 통과

## Related Decisions

- design/gdd/히트박스-충돌-감지.md
- design/gdd/체력-데미지-시스템.md
- design/gdd/플레이어-캐릭터-컨트롤러.md
- ADR-0005 (CharacterStats Resource — stats.atk, stats.def 공급자)
- ADR-0006 (AI 내비게이션 — 동료·적이 이 구조 위에서 동작)
