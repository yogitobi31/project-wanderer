# ADR-0002: Foundation Autoload 등록 순서 및 초기화 계약

## Status
Accepted

## Date
2026-04-27

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting (Autoload 패턴) |
| **Knowledge Risk** | MEDIUM — InputMapManager의 physical_keycode 저장 (4.5+) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `physical_keycode` (Godot 4.5 best practice — InputMapManager 바인딩 저장 시) |
| **Verification Required** | InputMapManager 리바인딩 저장/불러오기 시 physical_keycode 기반 ConfigFile이 Godot 4.6에서 올바르게 직렬화되는지 확인. |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (Accepted) — Autoload 허용 기준 정의. 이 ADR은 ADR-0001의 Data Registry 트랙을 확장하고 Service Singleton 트랙을 신규 정의한다. |
| **Enables** | ADR-0003, ADR-0004, ADR-0005, ADR-0006 — 모든 구현 ADR은 이 ADR의 Autoload 등록 순서에 의존한다. |
| **Blocks** | 모든 Foundation/Core/Feature 구현 시작 — Autoload 순서 미확정 시 초기화 타이밍 버그 발생 가능 |
| **Ordering Note** | project.godot Autoload 등록 순서는 이 ADR Accepted 후 고정. 이후 순서 변경 시 이 ADR을 Supersede해야 한다. |

## Context

### Problem Statement

유랑단은 9개의 Foundation Autoload를 사용한다. Godot은 project.godot에 등록된 순서대로
Autoload의 `_ready()`를 실행한다. 등록 순서가 문서화되지 않으면 의존 Autoload가 준비되기
전에 접근하는 초기화 타이밍 버그가 발생할 수 있다.

또한 ADR-0001은 순수 데이터 레지스트리에 대한 4가지 Autoload 허용 기준을 정의했다.
EventBus, InputMapManager 등 서비스 성격의 Autoload는 이 기준을 충족하지 않으나
Autoload 패턴이 합당하다. 이 예외를 명문화한다.

### Constraints

- Godot Autoload는 등록 순서대로 _ready()가 실행됨
- A가 _ready()에서 B를 호출하려면 B가 A보다 먼저 등록되어야 함
- 순환 Autoload 의존 불가 (GDScript 로더 제한)

### Requirements

- 9개 Autoload의 project.godot 등록 순서 명시
- 각 Autoload가 "언제부터 호출 가능한가" 계약 정의
- 서비스 싱글톤 허용을 위한 2nd track 기준 정의

## Decision

### Autoload 두 트랙 분류

**Track 1 — 데이터 레지스트리 (ADR-0001 4가지 기준 충족)**

| Autoload | GDD |
|---|---|
| ItemDB | 아이템-데이터베이스.md |
| NPCRegistry | NPC-상태-관리.md |
| PartyManager | 파티-매니저.md |
| Inventory | 인벤토리-시스템.md |

**Track 2 — 서비스 싱글톤 (신규 기준)**

아래 **4가지 기준을 모두 충족**할 때 서비스 Autoload를 허용한다:

| # | 기준 | EventBus | QuestManager | InputMapManager | SceneTransitionMgr | AudioManager |
|---|---|---|---|---|---|---|
| S-1 | **전역 생명주기 필요**: 씬 전환에 무관하게 상태/풀/컨텍스트를 유지해야 함 | ✓ | ✓ | ✓ | ✓ | ✓ |
| S-2 | **씬 계층 주입 불가**: 3개 이상 비관련 씬에서 동시 접근 필요 | ✓ | ✓ | ✓ | ✓ | ✓ |
| S-3 | **단일 서비스 책임**: 하나의 명확한 서비스 목적만 가짐 | ✓ | ✓ | ✓ | ✓ | ✓ |
| S-4 | **순환 의존 없음**: 다른 Autoload의 _ready() 완료를 기다리지 않고 초기화 가능 | ✓ | ✓ | ✓ | ✓ | ✓ |

### project.godot 등록 순서 (고정)

```
; Autoloads — 등록 순서대로 _ready() 실행됨. 변경 시 ADR-0002 Supersede 필요.
EventBus               = "*res://src/core/event_bus.gd"
ItemDB                 = "*res://src/core/item_db.gd"
NPCRegistry            = "*res://src/core/npc_registry.gd"
PartyManager           = "*res://src/core/party_manager.gd"
Inventory              = "*res://src/core/inventory.gd"
QuestManager           = "*res://src/core/quest_manager.gd"
InputMapManager        = "*res://src/core/input_map_manager.gd"
SceneTransitionManager = "*res://src/core/scene_transition_manager.gd"
AudioManager           = "*res://src/core/audio_manager.gd"
```

### 초기화 계약

| Autoload | 준비 완료 시점 | 신호 | 런타임 의존 대상 |
|---|---|---|---|
| EventBus | _ready() 즉시 | — | 없음 |
| ItemDB | _ready() 완료 (DirAccess 스캔 후) | `error_occurred` (실패 시) | 없음 |
| NPCRegistry | _ready() 완료 후 `registry_initialized` emit | `registry_initialized` | 없음 |
| PartyManager | _ready() 즉시 | — | NPCRegistry (런타임 검증용) |
| Inventory | _ready() 즉시 | — | ItemDB (런타임 검증용) |
| QuestManager | _ready() 즉시 | — | NPCRegistry, Inventory (런타임 호출) |
| InputMapManager | _ready() 완료 (ConfigFile 로드 후) | `bindings_changed` | 없음 |
| SceneTransitionManager | _ready() 즉시 | `transition_completed` | ResourceLoader (런타임) |
| AudioManager | _ready() 즉시 (풀 초기화) | — | 없음 |

**런타임 안전 규칙**:
- `NPCRegistry.set_state()` / `get_npc()` 호출 전 `NPCRegistry.is_initialized()` 확인
- registry_initialized 이전에 접근하는 시스템은 `await NPCRegistry.registry_initialized` 사용
- `ItemDB.get()` / `has()`는 _ready() 즉시 안전 (DirAccess 스캔이 동기적)

### Autoload 파일 경로 규칙

모든 Autoload는 `src/core/[snake_case_name].gd`에 위치하며 씬 파일 없이 스크립트만으로 등록한다 (`*` 접두사).

### Architecture Diagram

```
project.godot 등록 순서 (↓ 방향 = 먼저 초기화)

[1] EventBus               ← 시그널 정의만, 의존성 없음
[2] ItemDB                 ← res://assets/data/items/ 스캔
[3] NPCRegistry            ← registry_initialized emit → [6] 대기 가능
[4] PartyManager           ← [3] 이후 (런타임 검증용)
[5] Inventory              ← [2] 이후 (런타임 검증용)
[6] QuestManager           ← [3][5] 이후 (런타임 호출)
[7] InputMapManager        ← user://input_bindings.cfg
[8] SceneTransitionManager ← ResourceLoader 준비
[9] AudioManager           ← SFX 풀(8) + audio_config.tres
```

## Alternatives Considered

### Alternative 1: 등록 순서 문서화 없이 신호로만 동기화

- **Description**: 임의 순서로 등록하고 registry_initialized 같은 신호로만 동기화
- **Pros**: 등록 순서 강제 없음
- **Cons**: 모든 Autoload가 초기화 신호를 emit/await해야 하는 보일러플레이트 급증. 신호 미연결 시 무한 대기 버그
- **Rejection Reason**: 오버엔지니어링. Godot의 순서 보장을 활용하는 것이 더 단순

### Alternative 2: Node 기반 서비스 로케이터

- **Description**: /root/Services/ 노드 트리에 서비스 등록, get_node()로 접근
- **Pros**: 씬 단위 교체 가능, 테스트 더블 주입 용이
- **Cons**: 문자열 경로 취약성, 초기화 타이밍 제어 어려움, ADR-0001과 방향성 불일치
- **Rejection Reason**: ADR-0001이 이미 Autoload 패턴을 채택. 전환 비용 대비 이점 없음

## Consequences

### Positive

- 개발자가 project.godot을 보지 않아도 초기화 순서를 알 수 있음
- 초기화 타이밍 버그를 ADR 레벨에서 사전 차단
- Track 2 기준으로 미래 서비스 Autoload 추가를 체크리스트로 판단 가능

### Negative

- 등록 순서가 ADR에 고정 → 변경 시 ADR Supersede 필요

### Risks

- **위험**: 개발자가 project.godot에서 순서를 임의 변경 → **완화**: Control Manifest에 "Autoload 순서는 ADR-0002 참조" 명시
- **위험**: InputMapManager의 physical_keycode 직렬화가 Godot 4.6에서 예상과 다르게 동작 → **완화**: 첫 구현 시 저장/불러오기 통합 테스트 필수

## GDD Requirements Addressed

| GDD 시스템 | 요구사항 | 해결 방식 |
|---|---|---|
| NPC-상태-관리.md | TR-npc-004: is_initialized guard + registry_initialized signal | 초기화 계약 테이블에 명시 |
| NPC-상태-관리.md | TR-npc-005: MAX_PARTY_SIZE=3 | PartyManager Track 1 등재로 단일 권위 확립 |
| 아이템-데이터베이스.md | TR-item-003: _validate_definitions() + error_occurred signal | ItemDB 초기화 계약 명시 |
| 입력-매핑-시스템.md | TR-input-001: InputMapManager Autoload | Track 2 Service Singleton으로 등재, 순서 7번 |
| 입력-매핑-시스템.md | TR-input-002: is_ui_active context separation | InputMapManager 서비스 책임 명시 |
| 입력-매핑-시스템.md | TR-input-003: ConfigFile persistence | 초기화 계약 (ConfigFile 로드) 명시 |
| 입력-매핑-시스템.md | TR-input-004: physical_keycode storage | Engine Compatibility + Verification Required에 명시 |
| 오디오-매니저.md | TR-audio-001~003: AudioManager; 3 buses; SFX pool | Track 2 Service, 순서 9번 |
| 인벤토리-시스템.md | TR-inv-001~002: Inventory Autoload; Dictionary | Track 1 Data Registry, 순서 5번 |
| 파티-매니저.md | TR-party-001~002: PartyManager; MAX_PARTY_SIZE | Track 1 Data Registry, 순서 4번 |
| 이벤트-버스.md | TR-ebus-001: EventBus Autoload; companion_join_requested | Track 2 Service, 순서 1번 |
| 퀘스트-상태-머신.md | TR-quest-001~002: QuestManager; 3-state; conditions | Track 2 Service, 순서 6번 |

## Performance Implications

- **CPU**: Autoload _ready() 합산 초기화 비용 — 수십 ms (게임 시작 1회, 무시 가능)
- **Memory**: 9개 Autoload 합산 — 수십 KB (무시 가능)
- **Load Time**: DirAccess 스캔(ItemDB) + ConfigFile 로드(InputMapManager) — 각 10ms 이내 예상
- **Network**: 해당 없음

## Migration Plan

신규 프로젝트 — 기존 코드 없음. project.godot에 위 순서대로 Autoload를 등록한다.
구현 시작 전 이 ADR이 Accepted 상태여야 한다.

## Validation Criteria

- [ ] 게임 시작 첫 프레임에 `NPCRegistry.is_initialized()` == true
- [ ] InputMapManager 리바인딩 → 재시작 후 바인딩 유지 (physical_keycode 저장 검증)
- [ ] `NPCRegistry.get_npc()` 호출이 registry_initialized 이전이면 경고 로그 출력
- [ ] Track 2 신규 Autoload 추가 시 S-1~S-4 체크리스트 통과 기록 존재

## Related Decisions

- ADR-0001: Data Registry Autoload 허용 기준 (Track 1 정의)
- design/gdd/NPC-상태-관리.md
- design/gdd/입력-매핑-시스템.md
- design/gdd/이벤트-버스.md
