# Story 003: 컨텍스트 분리 — is_ui_active 및 gameplay 차단

> **Epic**: InputMapManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/입력-매핑-시스템.md`
**Requirements**: `TR-input-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: `InputMapManager`가 `is_ui_active: bool` 플래그를 소유. `set_ui_active(true)` 시 `gameplay` 카테고리 액션을 PlayerController 레이어에서 차단. `game_pause` 액션도 UI 중 비활성화. `PROCESS_MODE_DISABLED`는 `Input` 싱글턴 폴링을 차단하지 않으므로 명시적 가드 필수.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `PROCESS_MODE_DISABLED`는 `_process`/`_physics_process`만 차단 — `Input.is_action_pressed()` 폴링 미차단 (GDD R-7 설계 근거 참조). PlayerController는 `_physics_process()` 진입 시 `InputMapManager.is_ui_active` 가드를 명시적으로 구현해야 함.

**Control Manifest Rules (Foundation layer)**:
- Required: `is_ui_active` 플래그 소유권 = InputMapManager 단독
- Required: PlayerController `_physics_process()` 진입 시 `if InputMapManager.is_ui_active: return` 가드 필수
- Forbidden: `game_pause` 액션을 UI 컨텍스트에서 `game_cancel`과 함께 활성화 — 두 액션은 UI 중 역할 분리

---

## Acceptance Criteria

*From GDD `design/gdd/입력-매핑-시스템.md`:*

**R-7: 컨텍스트 분리**
- [ ] 게임플레이 중 `set_ui_active(true)` 호출 후 게임패드 South 버튼 입력 시: PlayerController `handle_input()` 미실행, `Input.is_action_pressed("game_confirm")` = true (AC-R7a)
- [ ] `set_ui_active(true)` 상태에서 Escape 입력 → `Input.is_action_just_pressed("game_cancel")` = true AND `Input.is_action_just_pressed("game_pause")` = false (AC-R7b)
- [ ] `set_ui_active()` 호출 없이 is_ui_active = false 유지 시 게임패드 South 입력 → PlayerController `handle_input()` 실행됨 (AC-R7c — 회귀 앵커)
- [ ] `src/` 하위 `.gd` 파일(InputMapManager 및 tests 제외)에서 `KEY_[A-Z0-9_]+`, `JOY_BUTTON_[A-Z0-9_]+`, `JOY_AXIS_[A-Z0-9_]+` 패턴이 `Input.is_action`, `InputMap.` 호출 외부에서 0건 (AC-R7d — 정적 분석)

---

## Implementation Notes

*Derived from ADR-0002 + GDD R-7:*

```gdscript
# InputMapManager 추가 멤버
var is_ui_active: bool = false

func set_ui_active(active: bool) -> void:
    is_ui_active = active
```

PlayerController 의무 가드:
```gdscript
func _physics_process(delta: float) -> void:
    if InputMapManager.is_ui_active:
        return
    handle_input()
```

**`game_pause` 비활성화 메커니즘**: `game_pause`는 `ui` 카테고리이지만 R-7에서 UI 중 예외적으로 비활성. 구현 방법:
- 옵션 A: PlayerController/UIController가 `is_ui_active` 체크 후 `game_pause` 입력 무시
- 옵션 B: `set_ui_active(true)` 시 `InputMap.action_erase_events("game_pause")` 임시 제거 → `set_ui_active(false)` 시 복원 (이벤트 목록 보존 필요)
- **권장**: 옵션 A — InputMap 직접 수정 없이 플래그만으로 처리. Pause 처리 노드가 `if InputMapManager.is_ui_active: return` 가드 추가.

**컨텍스트 전환 책임**: GDD R-7 기준으로 씬 전환 시스템(SceneTransitionManager)이 씬 전환 시작 시 `InputMapManager.set_ui_active(true)` 호출, 씬 로드 완료 후 `set_ui_active(false)` 호출.

**정적 분석 (AC-R7d)**: 구현 완료 후 GDScript `Key` enum / `JOY_BUTTON` 상수가 `Input.is_action` 또는 `InputMap.` 호출 외부에서 사용되면 Forbidden Pattern — grep으로 CI에서 검증.

---

## Out of Scope

- Story 001: InputMapManager Autoload 등록, 14개 액션 초기화
- Story 002: request_rebind() 리바인딩 API
- Story 004: 게임패드 Deadzone·이동벡터·4방향 이산화

---

## QA Test Cases

- **AC-R7a**: gameplay 차단 / ui 액션 통과
  - Given: PlayerController + InputMapManager 연결, `is_ui_active = false`
  - When: `InputMapManager.set_ui_active(true)` 후 JOY_BUTTON_SOUTH 입력 시뮬레이션
  - Then: PlayerController `handle_input()` 미실행 (호출 카운터 = 0), `Input.is_action_pressed("game_confirm")` = true

- **AC-R7b**: game_pause 비활성화
  - Given: `set_ui_active(true)` 상태
  - When: Escape 키 입력
  - Then: `Input.is_action_just_pressed("game_cancel")` = true, `Input.is_action_just_pressed("game_pause")` = false

- **AC-R7c**: 회귀 앵커 (is_ui_active = false 시 정상 동작)
  - Given: `is_ui_active = false` (set_ui_active 미호출)
  - When: JOY_BUTTON_SOUTH 입력
  - Then: PlayerController `handle_input()` 실행됨 (호출 카운터 ≥ 1)

- **AC-R7d**: 하드코딩 키코드 정적 분석
  - Given: `src/` 디렉터리 전체 `.gd` 파일 (src/core/input_map_manager.gd, tests/ 제외)
  - When: grep 패턴 `KEY_[A-Z0-9_]+|JOY_BUTTON_[A-Z0-9_]+|JOY_AXIS_[A-Z0-9_]+` 검색 (단, `Input.is_action`, `InputMap.` 컨텍스트 내 사용은 제외)
  - Then: 결과 0건

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/input/input_map_context_test.gd` — GUT 테스트, AC-R7a/b/c 커버, 반드시 존재하고 통과
- AC-R7d: CI grep 스크립트 또는 수동 정적 분석 기록

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (input-map-manager) DONE
- Unlocks: PlayerController 구현 (is_ui_active 가드 패턴 사용)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 4/4 passing (0 deferred)
**Deviations**: None
**Test Evidence**: Logic — tests/unit/input/input_map_context_test.gd (11 test functions, 4 AC COVERED)
**Code Review**: Complete (lean mode — APPROVED)
