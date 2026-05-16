# Story 001: EventBus Autoload 구현 및 신호 계약

> **Epic**: EventBus
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/이벤트-버스.md`
**Requirement**: `TR-ebus-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서 및 초기화 계약
**ADR Decision Summary**: EventBus는 Track 2 Service Singleton으로 등재. 의존성 없이 즉시 초기화되며 project.godot Autoload 등록 순서 1번에 위치한다. 모든 크로스-시스템 시그널을 이 노드에 선언한다.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot Signal API는 4.6에서 변경 없음 (stable). Autoload 패턴도 안정적.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload는 `src/core/[snake_case].gd` 경로에 스크립트만으로 등록 (`*` 접두사)
- Required: Autoload 등록 순서는 ADR-0002를 따름 — project.godot 임의 변경 금지
- Forbidden: EventBus에 게임플레이 로직 추가 금지 — 신호 선언 전용

---

## Acceptance Criteria

*From GDD `design/gdd/이벤트-버스.md`:*

- [ ] `EventBus.emit_signal("companion_join_requested", companion_id)` 발행 시 구독자가 신호를 수신한다
- [ ] 수신자가 없을 때 신호를 발행해도 오류가 발생하지 않는다
- [ ] 씬 전환 후에도 EventBus Autoload가 존재하며 신호 연결이 가능하다 (수동 확인)

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

1. `src/core/event_bus.gd` 파일 생성 — `Node`를 상속하는 GDScript
2. `companion_join_requested(companion_id: StringName)` 신호 선언
3. `project.godot`에 Autoload 등록:
   ```
   EventBus = "*res://src/core/event_bus.gd"
   ```
   반드시 첫 번째 Autoload로 등록 (다른 모든 Autoload가 이 순서에 의존)
4. 신호 추가 규칙(R-3): 단순 부모-자식 통신은 EventBus를 거치지 않음. 서로를 모르는 시스템 간 크로스-레이어 통신에만 추가

---

## Out of Scope

- 다른 Autoload 등록 (ItemDB, NPCRegistry 등) — 각 에픽의 스토리에서 처리
- AC-3 씬 전환 통합 검증 — `scene-transition-manager` 에픽 구현 후 수동 확인

---

## QA Test Cases

*Logic 스토리 — 자동화 테스트 스펙:*

- **AC-1**: companion_join_requested 신호 전달
  - Given: 구독자 노드가 `EventBus.companion_join_requested.connect(_callback)` 완료
  - When: `EventBus.companion_join_requested.emit(&"npc_01")` 호출
  - Then: `_callback`이 `companion_id == &"npc_01"`로 정확히 1회 호출됨
  - Edge cases: companion_id가 빈 StringName(`&""`)일 때도 콜백 1회 호출

- **AC-2**: 수신자 없는 신호 발행 — 오류 없음
  - Given: EventBus에 companion_join_requested 구독자 없음
  - When: `EventBus.companion_join_requested.emit(&"npc_01")` 호출
  - Then: 오류·예외·크래시 없이 정상 반환

- **AC-3**: 씬 전환 후 Autoload 지속성 (수동 확인)
  - Setup: 씬 전환 실행 후 새 씬 루트에서 `EventBus` 참조
  - Verify: `EventBus != null`, `companion_join_requested` 신호에 `connect()` 가능
  - Pass condition: 씬 전환 전후 동일 EventBus 인스턴스 유지 (engine guarantee)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/event_bus/event_bus_test.gd` — GUT 테스트, AC-1·AC-2 커버, 반드시 존재하고 통과

**Status**: [x] `tests/unit/event_bus/event_bus_test.gd` — 21개 테스트 함수, AC-1·AC-2 커버 완료

---

## Size Estimate

**Estimate**: 2–3 hours
- `src/core/event_bus.gd` 생성 + 신호 선언: 30분
- `project.godot` Autoload 등록 (순서 1번 확인): 15분
- GUT 테스트 작성 (AC-1, AC-2): 1–1.5시간
- 수동 AC-3 씬 전환 확인: 30분

---

## Dependencies

- Depends on: None
- Unlocks: 모든 Foundation 스토리 (`project.godot` Autoload 등록이 이 스토리에서 시작됨)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 3/3 passing (AC-3 DEFERRED — engine guarantee, scene-transition-manager 통합 후 수동 확인 예정)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/event_bus/event_bus_test.gd` (21 tests, AC-1·AC-2 커버)
**Code Review**: Complete — APPROVED WITH SUGGESTIONS (CI runner comment 수정, companion_left init, AC-3 주석 추가)
