# ADR-0005: CharacterStats Resource 패턴

## Status
Accepted

## Date
2026-04-28

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource / Data) |
| **Knowledge Risk** | LOW — Resource, @export, duplicate()는 4.4~4.6 변경 없음 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | 없음 |
| **Verification Required** | 없음 |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (Accepted) — Autoload 허용 기준 확립 (CharacterStats는 Autoload가 아닌 Resource임을 확인) |
| **Enables** | HealthComponent 구현(ADR-0004), 동료 AI 구현(ADR-0006), 플레이어 컨트롤러 구현 |
| **Blocks** | `stats.atk`, `stats.def`, `stats.spd`, `stats.max_hp`를 참조하는 모든 시스템 구현 |
| **Ordering Note** | ADR-0004와 ADR-0006 구현 전 이 ADR이 Accepted여야 한다. CharacterStats 없이는 데미지 계산과 AI 이동 속도를 정의할 수 없다. |

## Context

### Problem Statement

`능력치-시스템.md` GDD는 모든 캐릭터(플레이어·동료·적)가 동일한 `CharacterStats` Resource를 사용하도록 정의한다. 그러나 구체적인 GDScript 구현 계약(클래스 선언 방식, 필드명, computed 프로퍼티 패턴, 신호 설계, 인스턴스 생성 방법)이 ADR로 고정되지 않으면 구현자마다 다른 패턴을 선택할 수 있다. 특히 `base_*` 직접 노출 vs computed getter 패턴, `duplicate()` vs 직접 할당, `stats_changed` 신호 설계는 다운스트림 시스템 7개에 영향을 미치는 계약이므로 사전 명문화가 필요하다.

### Constraints

- GDScript는 Union 타입과 속성 데코레이터(@property)를 지원하지 않는다. computed 프로퍼티는 getter 함수 또는 `_get()` 가상 메서드로 구현해야 한다.
- CharacterStats는 에디터에서 편집 가능해야 한다 — Godot 에디터 Inspector에서 base_* 값을 직접 설정.
- 템플릿 `.tres` 파일을 여러 캐릭터가 공유하므로 런타임에서 원본을 수정하면 안 된다.

### Requirements

- TR-stats-001: 플레이어·동료·적이 동일한 CharacterStats 클래스를 사용
- TR-stats-002: base_* + mod_* 두 층 구조로 영구값과 임시값을 분리
- TR-stats-003: 스탯 변경 시 stats_changed 신호를 발행하여 다운스트림이 polling 없이 반응
- TR-stats-004: 런타임 인스턴스는 duplicate()로 생성하여 템플릿 원본을 보호

## Decision

### 1. 클래스 선언

```gdscript
# res://src/core/stats/character_stats.gd
class_name CharacterStats
extends Resource
```

`class_name`을 등록하여 Inspector에서 타입 힌트를 제공하고, 다운스트림 코드에서 `CharacterStats` 타입으로 정적 타입 선언 가능.

### 2. 필드 구조

```gdscript
# Base values — 영구값. 레벨업 시스템만 쓴다.
@export var base_max_hp: int = 80
@export var base_atk: int = 20
@export var base_def: int = 8
@export var base_spd: float = 130.0

# Modifier values — 임시값. 버프/디버프가 쓴다. MVP에서 항상 0.
var mod_max_hp: int = 0
var mod_atk: int = 0
var mod_def: int = 0
var mod_spd: float = 0.0
```

`base_*`는 `@export` — 에디터 Inspector에서 편집 가능, `.tres` 파일에 직렬화됨.
`mod_*`는 `@export` 없음 — 런타임 전용, 세이브 파일에 포함되지 않음.

### 3. Computed 프로퍼티 (클램핑 포함)

다운스트림 시스템은 `base_*`나 `mod_*`를 직접 읽지 않는다. 반드시 computed 프로퍼티를 통해 읽는다.

```gdscript
var max_hp: int:
    get: return clampi(base_max_hp + mod_max_hp, 1, 9999)

var atk: int:
    get: return clampi(base_atk + mod_atk, 0, 999)

var def: int:
    get: return clampi(base_def + mod_def, 0, 999)

var spd: float:
    get: return clampf(base_spd + mod_spd, 10.0, 600.0)
```

**클램핑 규칙:**

| 스탯 | 최솟값 | 최댓값 | 이유 |
|---|---|---|---|
| `max_hp` | 1 | 9999 | 0이면 즉사; 9999 초과는 UI 오버플로 |
| `atk` | 0 | 999 | atk=0 허용 (무장 해제 여지) |
| `def` | 0 | 999 | 음수 방어력 방지 |
| `spd` | 10.0 | 600.0 | 10 미만: AI pathfinding 타임아웃 위험; 600 초과: 소형 맵에서 프레임당 충돌 스킵 가능 |

### 4. stats_changed 신호

```gdscript
signal stats_changed(stat_name: StringName)
```

`base_*` 또는 `mod_*` setter에서 값이 변경될 때 emit. 인자는 변경된 computed 프로퍼티 이름(`&"max_hp"`, `&"atk"`, `&"def"`, `&"spd"`).

**신호 핸들러 규칙**: `stats_changed` 핸들러 안에서 `base_*`나 `mod_*`를 쓰지 않는다. 재진입으로 인한 신호 루프 방지.

### 5. 인스턴스 생성 계약

```gdscript
# 캐릭터 노드 _ready()에서:
stats = stats_template.duplicate()   # shallow copy — int/float 프리미티브이므로 충분
```

- `.tres` 템플릿은 `@export` 필드로 씬에 연결
- 런타임에서 `.tres` 원본을 직접 수정하는 것은 Forbidden Pattern
- 미래에 CharacterStats 내부에 Array 또는 Resource 타입 필드가 추가되면 `duplicate(true)` (deep copy)로 변경해야 한다 — 이 ADR을 업데이트할 것

### 6. GrowthRate 분리

경험치/레벨업 시스템이 사용하는 성장률 데이터는 CharacterStats와 별도 Resource로 분리한다:

```gdscript
# res://src/core/stats/growth_rate.gd
class_name GrowthRate
extends Resource

@export var hp_growth: int = 0
@export var atk_growth: int = 0
@export var def_growth: int = 0
@export var spd_growth: float = 0.0
```

CharacterStats는 GrowthRate를 참조하지 않는다. GrowthRate는 레벨업 시스템만 읽는다.

### 7. MVP 보호장치

MVP 빌드에서 `mod_*` setter에 `push_warning()` 추가 — 의도치 않은 쓰기를 경고로 조기 발견:

```gdscript
var mod_atk: int = 0:
    set(value):
        push_warning("CharacterStats: mod_atk written — intended? value=%d" % value)
        mod_atk = value
        stats_changed.emit(&"atk")
```

### Architecture Diagram

```
         ┌──────────────────────────────────────┐
         │        CharacterStats (Resource)      │
         │                                      │
         │  @export base_max_hp, base_atk,      │
         │          base_def, base_spd          │
         │                                      │
         │  var     mod_max_hp, mod_atk,        │
         │          mod_def, mod_spd            │
         │                                      │
         │  computed: max_hp, atk, def, spd     │  ← 다운스트림은 여기만 읽음
         │  signal:  stats_changed(stat_name)   │
         └──────────────────────────────────────┘
                         │
         ┌───────────────┼──────────────────────┐
         ▼               ▼                      ▼
  HealthComponent   CompanionAI          PlayerController
  (max_hp, def)     (atk, spd)           (max_hp, spd)
```

## Alternatives Considered

### Alternative 1: 딕셔너리로 스탯 저장

- **Description**: `stats = {"max_hp": 80, "atk": 20, ...}` 딕셔너리 사용
- **Pros**: 유연함 — 새 스탯 추가가 쉬움
- **Cons**: 타입 안전성 없음. 오타로 인한 null 접근이 런타임에서야 발견됨. 에디터 Inspector 미지원.
- **Rejection Reason**: GDScript 정적 타입 원칙 위반

### Alternative 2: Node 기반 StatsComponent

- **Description**: Node를 상속하여 씬 트리에 자식 노드로 추가
- **Pros**: 씬에서 시각적으로 확인 가능
- **Cons**: Resource는 `.tres` 파일로 에디터에서 직접 편집 가능 — Node보다 데이터 정의에 적합. `duplicate()`로 인스턴스 생성도 Resource 패턴이 자연스러움.
- **Rejection Reason**: GDD에서 "CharacterStats Resource" 명시

## Consequences

### Positive

- 7개 다운스트림 시스템이 동일한 타입 안전 인터페이스로 스탯에 접근
- `.tres` 파일로 에디터에서 직접 편집 — 밸런스 튜닝이 코드 수정 없이 가능
- `stats_changed` 신호로 UI와 AI가 매 프레임 polling 없이 스탯 변화에 반응

### Negative

- computed 프로퍼티가 GDScript 4.x의 `var name: type: get:` 문법에 의존 — 이 문법에 익숙하지 않은 구현자가 실수할 수 있음
- shallow `duplicate()` 의존성 — 미래에 Resource 타입 필드 추가 시 deep copy로 변경 필요

### Risks

- **위험**: 다운스트림에서 `base_atk`를 직접 읽어 클램핑 우회 → **완화**: Forbidden Pattern 등록 (다운스트림은 computed 프로퍼티만 읽는다)
- **위험**: 템플릿 `.tres`를 직접 수정 → **완화**: Forbidden Pattern 등록 (런타임에서 `.tres` 원본 쓰기 금지)
- **위험**: Array/Resource 필드 추가 후 shallow copy 유지 → **완화**: 이 ADR 5번 항목에 변경 조건 명시

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 이 ADR의 해결 방식 |
|---|---|---|
| 능력치-시스템.md | Core Rule 1: 모든 캐릭터가 동일한 CharacterStats 사용 | class_name CharacterStats extends Resource로 단일 클래스 고정 |
| 능력치-시스템.md | Core Rule 2: MVP 스탯 4개 (max_hp, atk, def, spd) | @export 필드 4쌍(base_*/mod_*) + computed 프로퍼티 4개로 구현 |
| 능력치-시스템.md | Core Rule 3: base + modifier 두 층 구조 | base_*(영구) / mod_*(임시) 분리 및 computed getter 패턴 |
| 능력치-시스템.md | Core Rule 4: stats_changed 신호 | `signal stats_changed(stat_name: StringName)` 계약 명문화 |
| 능력치-시스템.md | Core Rule 5: duplicate()로 런타임 인스턴스 생성 | shallow copy 사용 조건 및 future deep copy 변경 조건 명시 |
| 능력치-시스템.md | Core Rule 6: GrowthRate 별도 Resource | GrowthRate class_name 분리 선언 |

## Performance Implications

- **CPU**: computed 프로퍼티는 getter 1회 호출 — 프레임 영향 무시 가능
- **Memory**: int/float 프리미티브 8개 필드 / 인스턴스 — 수십 바이트
- **Load Time**: `.tres` preload — 게임 시작 1회, 수 ms 이내

## Validation Criteria

- `CharacterStats.new().duplicate()`로 생성한 두 인스턴스가 서로 독립적으로 동작 (한쪽 base_atk 수정이 다른쪽에 영향 없음)
- `base_def = 5, mod_def = -8` → `def` computed 프로퍼티가 `0` 반환 (클램프 확인)
- `base_max_hp` 변경 시 `stats_changed` 신호가 정확히 1회, `stat_name = &"max_hp"`로 발행
- 플레이어·동료·적 씬에서 `stats` 필드의 타입이 모두 `CharacterStats`

## Related Decisions

- design/gdd/능력치-시스템.md
- ADR-0004 (전투 시스템 계약 — stats.atk, stats.def 소비자)
- ADR-0006 (AI 내비게이션 계약 — stats.spd 소비자)
