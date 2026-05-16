# ADR-0001: 데이터 레지스트리 Autoload 패턴 (ItemDB + NPCRegistry)

## Status
Accepted

## Date
2026-04-19

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Scripting — Autoload 패턴) |
| **Knowledge Risk** | LOW — Autoload API는 4.4/4.5/4.6에서 변경 없음 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `duplicate_deep()` (Godot 4.5+) — NPCRegistry에서 NPCRecord 스냅샷 복사 시 사용 |
| **Verification Required** | `duplicate_deep()`이 중첩 Resource 타입(NPCRecord 내 Dictionary/Array)에 올바르게 작동하는지 Godot 4.6에서 확인. NPCRecord의 모든 Resource 타입 필드가 `_init()`에서 초기화되어 있는지 확인 필수. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ItemDB/NPCRegistry를 사용하는 모든 시스템의 구현 (플레이어 컨트롤러, 동료 AI, 대화, 퀘스트 등) |
| **Blocks** | None |
| **Ordering Note** | MVP 구현 시작 전 Accepted 상태 권장 |

## Context

### Problem Statement

`아이템-데이터베이스.md`와 `NPC-상태-관리.md` GDD는 각각 `ItemDB`와 `NPCRegistry`를 Autoload
싱글톤으로 정의한다. 프로젝트 코딩 표준은 "의존성 주입 over 싱글톤"을 원칙으로 하지만, 두 시스템은
5개 이상의 다운스트림 시스템이 동시에 접근하는 순수 데이터 레지스트리라는 특수한 성격을 가진다.
이 예외를 명문화하지 않으면 (a) 부적절한 시스템에 같은 패턴이 전파되거나, (b) 이 적법한 예외를
코딩 표준 위반으로 오해해 불필요하게 리팩터링할 위험이 있다.

### Constraints

- Godot 씬 트리에서 5개+ 씬 계층을 통해 레지스트리를 주입하는 것은 비현실적
- 두 레지스트리는 게임 시작 시점에 완전히 초기화되어야 하는 전역 데이터
- 세이브/로드 시스템이 NPCRegistry 전체를 직렬화해야 하므로 단일 접근 경로 필수

### Requirements

- 5개+ 다운스트림 시스템의 동시 접근 지원
- O(1) 조회 성능 (프레임 내 다중 호출 허용)
- 미래의 유사 시스템을 위한 적용 기준 제공

## Decision

순수 데이터 레지스트리 시스템이 아래 **4가지 기준을 모두 충족**할 때만 Autoload 싱글톤 패턴을
허용한다. 이 기준을 충족하지 않는 시스템은 의존성 주입 또는 EventBus 신호 패턴을 사용해야 한다.

### Autoload 허용 기준

| # | 기준 | ItemDB | NPCRegistry |
|---|------|--------|-------------|
| 1 | **순수 데이터 레지스트리**: 소비자에게 읽기 전용 인터페이스. 쓰기는 소유 시스템만 가능 | ✓ (get/has만 노출) | ✓ (set_state는 소유 시스템만) |
| 2 | **광범위 팬아웃**: 3개 이상 비관련 다운스트림 시스템이 동시 접근 | ✓ (인벤토리, 수집, 퀘스트) | ✓ (대화, 퀘스트, AI, 합류이벤트, 월드조건) |
| 3 | **안정적·좁은 API**: 공개 메서드 10개 이하, 변경 빈도 낮음 | ✓ | ✓ |
| 4 | **단순 초기화**: 다른 런타임 시스템 의존 없이 에디터 리소스/cfg에서 초기화 | ✓ (.tres preload) | ✓ (기본값 또는 세이브 파일 복원) |

### 허용된 Autoload 목록

| Autoload 이름 | GDD | 역할 | 쓰기 권한 |
|--------------|-----|------|----------|
| `ItemDB` | design/gdd/아이템-데이터베이스.md | 아이템 정의 조회 | 에디터 전용 (런타임 쓰기 금지) |
| `NPCRegistry` | design/gdd/NPC-상태-관리.md | NPC 상태 저장 및 조회 | NPCRegistry 자체만 (`set_state`) |

### Autoload 사용 제약

1. **신호 버스 금지**: Autoload는 시스템 간 이벤트 중계에 사용 불가. 이벤트 전달은 EventBus 또는 직접 신호 연결을 사용한다.
2. **교차 시스템 상태 쓰기 금지**: Autoload를 통해 소유 시스템 외부가 상태를 쓰는 것은 금지.
3. **스냅샷 복사 시 `duplicate_deep()` 필수**: Autoload에 저장된 Resource 복사본이 필요할 경우 `resource.duplicate_deep()` 사용 (Godot 4.5+ API). 얕은 복사는 레지스트리 데이터 오염 위험. **NPCRecord의 모든 Resource 타입 필드는 `_init()`에서 초기화되어 있어야 `duplicate_deep()`이 안전하게 동작한다.**
4. **Autoload 간 순환 의존 금지**.
5. **초기화 순서 문서화**: 향후 Autoload A가 `_ready()`에서 Autoload B를 참조하는 의존 방향이 생기면, Project Settings 등록 순서를 해당 ADR 또는 이 ADR에 명시적으로 기록한다.

### Architecture Diagram

```
         ┌─────────────────────────────────┐
         │         Autoload Layer           │
         │  ┌──────────┐  ┌─────────────┐  │
         │  │  ItemDB  │  │ NPCRegistry │  │
         │  │(read-only│  │(+set_state) │  │
         │  └────┬─────┘  └──────┬──────┘  │
         └───────┼───────────────┼──────────┘
                 │ get/has       │ get_npc / signal
        ┌────────┴──┐    ┌───────┴──────────────┐
        │ 인벤토리   │    │ 대화 · 퀘스트 · AI    │
        │ 수집/자원  │    │ 합류이벤트 · 월드조건  │
        │ 퀘스트     │    └──────────────────────┘
        └────────────┘
```

### Key Interfaces

> **주의**: 아래 `-> Type | null` 표기는 의사코드다. GDScript는 Union 타입을 지원하지 않으므로
> 실제 구현 시 `-> Type` 반환 타입을 선언하고 미존재 시 `null`을 반환한다.

```gdscript
# ItemDB (Autoload, 읽기 전용)
func get(item_id: StringName) -> ItemDefinition:     # null 반환 가능
    pass
func has(item_id: StringName) -> bool:
    pass

# NPCRegistry (Autoload)
func get_npc(npc_id: StringName) -> NPCRecord:       # null 반환 가능
    pass
func set_state(npc_id: StringName, state: RelationshipState) -> void:  # 소유자만
    pass
signal npc_state_changed(npc_id: StringName, new_state: int)
```

## Alternatives Considered

### Alternative 1: 의존성 주입 (Dependency Injection)

- **Description**: `_ready()`에서 ItemDB/NPCRegistry 인스턴스를 파라미터로 전달
- **Pros**: 시스템 독립 단위 테스트 가능, 전역 상태 없음
- **Cons**: Godot 씬 인스턴스화는 생성자 주입 미지원. 5개+ 씬에 동일 참조를 전파하면 Autoload보다 복잡한 씬 계층 의존성 발생
- **Rejection Reason**: 이득보다 비용이 큰 실용성 문제

### Alternative 2: SceneTree 서비스 로케이터

- **Description**: `/root/Services/ItemDB` 노드 경로로 등록, `get_node()`로 접근
- **Pros**: 경로 모킹으로 테스트 가능
- **Cons**: 문자열 경로는 리팩터링에 취약. Autoload와 동일한 전역 상태 문제에 추가 복잡도만 발생
- **Rejection Reason**: 복잡도 대비 이점 없음

## Consequences

### Positive

- 5개+ 다운스트림 시스템의 일관된 단일 접근 경로
- GDD의 기존 설계 결정과 일치 — 구현 마찰 없음
- 미래 Autoload 사용에 대한 명확한 4가지 체크리스트 제공

### Negative

- 전역 상태 도입 — Autoload 초기화 순서를 Project Settings에서 명시적 관리 필요
- 단위 테스트 시 테스트 더블 주입 번거로움 (MVP 이후 해결 권장)

### Risks

- **위험**: 4가지 기준 체크 없이 새 Autoload 추가 → **완화**: Forbidden Pattern으로 등록, `/dev-story` 체크리스트에 포함
- **위험**: `duplicate_deep()` 미사용으로 레지스트리 데이터 오염 → **완화**: Forbidden Pattern 등록

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 이 ADR의 해결 방식 |
|------------|---------|------------------|
| NPC-상태-관리.md | Core Rule 4: NPCRegistry Autoload 예외를 ADR로 문서화 | 4가지 기준 충족 확인 및 허용 목록 등재 |
| NPC-상태-관리.md | Core Rule 6: 스냅샷 복사 시 `duplicate_deep()` 사용 | 제약 조항 3번 명시 및 `_init()` 초기화 요건 추가 |
| 아이템-데이터베이스.md | Core Rule 4: ItemDB Autoload 예외를 NPCRegistry와 통합 ADR로 문서화 | 4가지 기준 충족 확인 및 허용 목록 등재 |

## Performance Implications

- **CPU**: O(1) Dictionary 조회 — 프레임 영향 무시 가능
- **Memory**: ItemDB (7~14개 .tres) + NPCRegistry (NPC 수십 개) — 수 KB 수준
- **Load Time**: 게임 시작 1회 초기화 — 수십 ms 이내 예상
- **Network**: 해당 없음 (싱글플레이어)

## Migration Plan

신규 프로젝트 — 기존 코드 없음. Project Settings → Autoload에 `ItemDB`, `NPCRegistry` 순으로
등록한다. 두 시스템은 서로를 참조하지 않으므로 순서는 관례적이며, 향후 의존성이 생기면 제약 5번에
따라 이 섹션을 업데이트한다.

## Validation Criteria

- `ItemDB.get()` / `NPCRegistry.get_npc()`가 첫 프레임부터 유효한 데이터 반환
- `duplicate_deep()` 복사본 수정이 레지스트리 원본에 영향 없음 (NPCRecord 필드 초기화 포함)
- 이 ADR 이후 추가된 Autoload가 있다면, 해당 ADR에 4가지 기준 체크리스트 통과 기록 존재

## Related Decisions

- design/gdd/NPC-상태-관리.md — Core Rule 4, 6
- design/gdd/아이템-데이터베이스.md — Core Rule 4
