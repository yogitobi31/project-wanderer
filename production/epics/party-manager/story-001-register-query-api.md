# Story 001: PartyManager Autoload — 등록·조회 API 및 파티 제한

> **Epic**: PartyManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/파티-매니저.md`
**Requirements**: `TR-party-001`, `TR-party-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: PartyManager는 Track 1 Data Registry, Autoload 등록 순서 4번 (NPCRegistry 다음). `MAX_PARTY_SIZE = 3` 계약은 PartyManager 내부에서 이중 방어로 강제된다.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Array[StringName]` typed array는 Godot 4.0+에서 안정. `@export var companion_count: int` 대신 computed property 패턴(`get: return _companions.size()`) 사용 — Godot 4.x setter/getter 문법 확인 필요.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload는 `src/core/party_manager.gd`, `*` 접두사로 등록, 순서 4번
- Required: `get_companions()` — 복사본(`duplicate()`) 반환, 원본 배열 직접 노출 금지
- Forbidden: `remove_companion()` 구현 — MVP 범위 외 (Vertical Slice에서 추가)

---

## Acceptance Criteria

*From GDD `design/gdd/파티-매니저.md`:*

- [ ] `register_companion(id)` 호출 후 `is_recruited(id)` → `true` (AC-1)
- [ ] `companion_count`는 등록된 동료 수와 일치한다 (AC-2)
- [ ] 같은 id를 두 번 등록해도 `companion_count == 1` — 중복 무시 (AC-3)
- [ ] `MAX_PARTY_SIZE(3)` 초과 등록 시도 시 4번째 동료는 등록되지 않는다 (AC-4)
- [ ] `get_companions()` 반환값 수정이 내부 `_companions` 배열에 영향 없음 (AC-5)
- [ ] 씬 전환 후에도 파티 목록이 유지된다 — Autoload 속성 보장, 수동 플레이테스트 확인 (AC-6)

---

## Implementation Notes

*Derived from ADR-0002 + GDD Detailed Rules:*

```gdscript
# src/core/party_manager.gd
extends Node

const MAX_PARTY_SIZE: int = 3

var _companions: Array[StringName] = []

var companion_count: int:
    get: return _companions.size()

func register_companion(companion_id: StringName) -> void:
    if _companions.has(companion_id):
        push_warning("PartyManager: companion already registered — " + companion_id)
        return
    if _companions.size() >= MAX_PARTY_SIZE:
        push_warning("PartyManager: MAX_PARTY_SIZE reached, cannot register — " + companion_id)
        return
    _companions.append(companion_id)

func is_recruited(companion_id: StringName) -> bool:
    return _companions.has(companion_id)

func get_companions() -> Array[StringName]:
    return _companions.duplicate()
```

`project.godot` 등록:
```
PartyManager = "*res://src/core/party_manager.gd"
```
등록 순서: EventBus(1) → ItemDB(2) → NPCRegistry(3) → **PartyManager(4)**

**이중 방어 설계**: 동료-합류-이벤트 시스템이 `companion_count < MAX_PARTY_SIZE` 사전 확인 후 합류 이벤트를 발행해야 함. PartyManager의 `register_companion()` 내 상한 검사는 이중 방어선이다.

---

## Out of Scope

- `remove_companion()` — VS+ 자리 예약, MVP에서 구현하지 않음
- NPCRegistry COMPANION 상태 교차 검증 — 동료-합류-이벤트 시스템 책임 (party-manager는 ID 저장만 담당)
- 세이브/로드 연동 — 별도 VS 에픽

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: register_companion() 후 is_recruited() 확인
  - Given: 빈 PartyManager, companion_id = &"aria"
  - When: `register_companion(&"aria")` 호출
  - Then: `is_recruited(&"aria")` → true

- **AC-2**: companion_count 정확성
  - Given: 빈 PartyManager
  - When: `register_companion(&"aria")`, `register_companion(&"bran")` 순서로 등록
  - Then: `companion_count == 2`

- **AC-3**: 중복 등록 무시
  - Given: 빈 PartyManager
  - When: `register_companion(&"aria")` 두 번 호출
  - Then: `companion_count == 1`, `is_recruited(&"aria")` → true

- **AC-4**: MAX_PARTY_SIZE 초과 거부
  - Given: &"aria", &"bran", &"ceri" 3명 등록된 PartyManager
  - When: `register_companion(&"deon")` 호출
  - Then: `companion_count == 3`, `is_recruited(&"deon")` → false

- **AC-5**: get_companions() 복사본 독립성
  - Given: &"aria" 등록된 PartyManager
  - When: `var list = get_companions()` 후 `list.append(&"fake")`
  - Then: `companion_count == 1`, `is_recruited(&"fake")` → false

- **AC-6**: 씬 전환 후 파티 유지 (수동 플레이테스트)
  - Setup: 동료 등록 후 SceneTransitionManager로 씬 전환
  - Verify: 전환 후 `companion_count` 및 `is_recruited()` 결과가 전환 전과 동일
  - Pass condition: Autoload 특성상 씬 전환에 무관하게 유지됨 확인

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/party/party_manager_test.gd` — GUT 테스트, 위 AC-1~AC-5 커버, 반드시 존재하고 통과
- AC-6: 수동 플레이테스트 메모 (ADVISORY)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: npc-registry/001 DONE (project.godot Autoload 등록 패턴 확립, NPCRegistry #3 등록 후 PartyManager #4)
- Unlocks: 동료-합류-이벤트 epic (PartyManager 완성 후 합류 이벤트 구현 가능)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 5/5 passing (AC-6 DEFERRED — Autoload 씬 전환 유지, 수동 플레이테스트)
**Deviations**: None
**Test Evidence**: Logic — tests/unit/party/party_manager_test.gd (17 test functions, AC-1~AC-5 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (get_companions() Array.assign() 패턴으로 타입 안전하게 수정)
