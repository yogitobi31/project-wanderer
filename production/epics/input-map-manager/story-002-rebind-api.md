# Story 002: 리바인딩 API — 유효성 검사·중복 처리·저장

> **Epic**: InputMapManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/입력-매핑-시스템.md`
**Requirements**: `TR-input-003`, `TR-input-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: `physical_keycode` 기반 바인딩 저장 (키보드 레이아웃 독립). ConfigFile 형식, `user://input_bindings.cfg` 경로. 리바인딩은 `request_rebind()` 단일 경로만 허용.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `InputEventKey.physical_keycode` — Godot 4.5+ best practice, 4.6 안정. `ConfigFile.save()` / `get_value()` — 4.x 안정. `InputEventJoypadMotion.axis_value sign()` — 0.0 입력 방지를 위해 E-2의 `REBIND_AXIS_THRESHOLD(0.5)` 가드 필수 (F-4 의존성). `docs/engine-reference/godot/` 확인.

**Control Manifest Rules (Foundation layer)**:
- Required: `physical_keycode` 우선 저장 — `keycode`(논리) 저장 금지
- Required: 같은 카테고리 내 중복만 검사 — 카테고리 간 중복은 컨텍스트 분리(R-7)로 처리
- Forbidden: `InputMap` 직접 수정 — `request_rebind()` 경유만 허용
- Forbidden: `duplicate()` 없는 원본 이벤트 배열 직접 반환

---

## Acceptance Criteria

*From GDD `design/gdd/입력-매핑-시스템.md`:*

**R-4: 리바인딩 유효성 검사**
- [ ] `request_rebind("fly_up", event)` (마스터 테이블 없는 이름) → `RebindResult.UNKNOWN_ACTION`, InputMap 불변 (AC-R4a)
- [ ] `request_rebind("move_up", InputEventMIDI.new())` → `RebindResult.INVALID_EVENT_TYPE`, InputMap 불변 (AC-R4b)
- [ ] F1~F12, Win/Cmd, PrintScreen 중 하나로 리바인딩 → `RebindResult.RESERVED_KEY`, InputMap 불변 (AC-R4c)
- [ ] `combat_attack`이 J 바인딩인 상태에서 `request_rebind("interact", KEY_J)` → `RebindResult.DUPLICATE_BINDING`, InputMap 미변경 (AC-R4d)
- [ ] `request_rebind("interact", KEY_E)` → `RebindResult.SUCCESS`, `action_get_events("interact")`에 KEY_E 포함, cfg에 KEY_E physical_keycode 저장 (AC-R4e)

**R-5: 중복 처리**
- [ ] `combat_attack`이 J 단독 바인딩, `interact`에 J 강제 스왑 확인 → `combat_attack`에서 KEY_J 제거, `interact`에 KEY_J 추가 (AC-R5a)
- [ ] `move_up` 바인딩 1개만 존재 시 삭제 시도 → `RebindResult.LAST_BINDING_BLOCKED`, W 키 유지 (AC-R5b)

**R-6: 저장/복원**
- [ ] `request_rebind("combat_dodge", KEY_L)` SUCCESS 직후 cfg 파일에 `combat_dodge` 섹션에 KEY_L physical_keycode 존재 (AC-R6a)
- [ ] `reset_to_defaults()` 호출 후 `FileAccess.file_exists("user://input_bindings.cfg")` = false (AC-R6b)
- [ ] AZERTY 시뮬레이션: `event.physical_keycode=KEY_E(69)`, `event.keycode=KEY_Q(81)` → cfg에 `physical_keycode=69`, `keycode` 필드 없음(또는 0) (AC-R6c)

**F-4: 중복 감지 판정**
- [ ] `combat_attack`이 Ctrl+J 바인딩, `request_rebind("interact", Ctrl+J)` → `DUPLICATE_BINDING` (AC-F4a)
- [ ] `combat_attack`이 J 바인딩(modifier 없음), `request_rebind("interact", Ctrl+J)` → `SUCCESS` (J ≠ Ctrl+J) (AC-F4b)
- [ ] `combat_attack`이 K 키 바인딩, `request_rebind("interact", JOY_BUTTON_SOUTH)` → `SUCCESS` (타입 달라 중복 아님) (AC-F4c)

**Edge Cases:**
- [ ] AWAITING_INPUT 중 OS 포커스 손실 → 상태 ACTIVE 복귀, InputMap 불변, cfg 불변 (AC-E-focus-loss)
- [ ] `user://` 쓰기 권한 없음, `request_rebind("move_up", KEY_T)` → (1) T키 반응(메모리 적용), (2) `RebindResult.SAVE_FAILED` (AC-E-save-fail)

---

## Implementation Notes

*Derived from ADR-0002 + GDD R-4, R-5, R-6, F-4:*

```gdscript
enum RebindResult {
    SUCCESS,
    UNKNOWN_ACTION,
    INVALID_EVENT_TYPE,
    RESERVED_KEY,
    DUPLICATE_BINDING,
    LAST_BINDING_BLOCKED,
    SAVE_FAILED,
}

const RESERVED_KEYCODES: Array[int] = [KEY_F1, KEY_F2, ..., KEY_F12, KEY_SUPER_L, KEY_SUPER_R, KEY_PRINT]
const ALLOWED_EVENT_TYPES: Array = [InputEventKey, InputEventMouseButton, InputEventJoypadButton, InputEventJoypadMotion]

func request_rebind(action: StringName, new_event: InputEvent) -> RebindResult:
    # 1. 마스터 테이블 존재 확인
    if not _is_registered_action(action):
        return RebindResult.UNKNOWN_ACTION
    # 2. 이벤트 타입 검증
    if not _is_allowed_event_type(new_event):
        return RebindResult.INVALID_EVENT_TYPE
    # 3. 예약 키 확인
    if new_event is InputEventKey and new_event.physical_keycode in RESERVED_KEYCODES:
        return RebindResult.RESERVED_KEY
    # 4. 같은 카테고리 내 중복 검사
    var category := _get_action_category(action)
    var conflict := _find_duplicate(action, new_event, category)
    if conflict != &"":
        return RebindResult.DUPLICATE_BINDING  # 호출자가 스왑 확인 후 force_rebind() 호출
    # 5. InputMap 업데이트 + 저장
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, new_event)
    var save_ok := _save_to_cfg()
    return RebindResult.SUCCESS if save_ok else RebindResult.SAVE_FAILED

func _save_to_cfg() -> bool:
    var cfg := ConfigFile.new()
    for def in ACTION_DEFS:
        for event in InputMap.action_get_events(def.name):
            # InputEvent → primitive 분해 저장 (physical_keycode 우선)
            if event is InputEventKey:
                cfg.set_value(def.name, "physical_keycode", event.physical_keycode)
    cfg.set_value("meta", "schema_version", CURRENT_SCHEMA_VERSION)
    return cfg.save(BINDINGS_PATH) == OK

func reset_to_defaults() -> void:
    _register_default_actions()
    if FileAccess.file_exists(BINDINGS_PATH):
        DirAccess.remove_absolute(BINDINGS_PATH)
```

**강제 스왑 흐름**: `request_rebind()` → `DUPLICATE_BINDING` → UI가 사용자 확인 후 → `force_swap(action, conflict_action, new_event)` 호출 → 기존 액션에서 이벤트 제거 후 새 액션에 추가.

**REBIND_AXIS_THRESHOLD 가드**: AWAITING_INPUT 상태에서 `InputEventJoypadMotion.axis_value` 절댓값 < 0.5이면 이벤트 무시 (`sign(0.0) = 0` 오탐 방지).

---

## Out of Scope

- Story 001: 액션 마스터 테이블 초기화, is_ready 가드
- Story 003: is_ui_active 컨텍스트 분리
- Story 004: 게임패드 Deadzone·이동벡터·4방향 이산화 공식
- UI 리바인딩 화면 (중복 하이라이트, 삭제 버튼 비활성화) — 메인 메뉴/설정 UI 시스템 담당

---

## QA Test Cases

- **AC-R4a**: 미등록 액션 거부
  - Given: ACTIVE 상태
  - When: `request_rebind("fly_up", InputEventKey.new())`
  - Then: `RebindResult.UNKNOWN_ACTION`, InputMap 불변

- **AC-R4b**: 잘못된 이벤트 타입 거부
  - Given: ACTIVE 상태
  - When: `request_rebind("move_up", InputEventMIDI.new())`
  - Then: `RebindResult.INVALID_EVENT_TYPE`, InputMap 불변

- **AC-R4c**: 예약 키 거부
  - Given: ACTIVE 상태
  - When: `request_rebind("move_up", InputEventKey(physical_keycode=KEY_F1))`
  - Then: `RebindResult.RESERVED_KEY`, InputMap 불변

- **AC-R4d**: 중복 바인딩 감지
  - Given: `combat_attack`에 KEY_J 바인딩
  - When: `request_rebind("interact", InputEventKey(physical_keycode=KEY_J))`
  - Then: `RebindResult.DUPLICATE_BINDING`, `action_get_events("interact")`에 KEY_J 없음

- **AC-R4e**: 성공적 리바인딩 + 즉시 저장
  - Given: ACTIVE 상태, cfg 없음
  - When: `request_rebind("interact", InputEventKey(physical_keycode=KEY_E))`
  - Then: `RebindResult.SUCCESS`, `action_get_events("interact")`에 KEY_E, cfg `interact.physical_keycode = KEY_E`

- **AC-R5a**: 강제 스왑
  - Given: `combat_attack`에 KEY_J 단독 바인딩
  - When: 사용자가 스왑 확인 후 `force_swap` 실행
  - Then: `action_get_events("combat_attack")`에 KEY_J 없음, `action_get_events("interact")`에 KEY_J 있음

- **AC-R5b**: 마지막 바인딩 삭제 거부
  - Given: `move_up`에 바인딩 1개만 존재
  - When: 해당 바인딩 삭제 시도
  - Then: `RebindResult.LAST_BINDING_BLOCKED`, `action_get_events("move_up")` 불변

- **AC-R6a**: 리바인딩 직후 cfg 저장
  - Given: ACTIVE 상태
  - When: `request_rebind("combat_dodge", KEY_L)` SUCCESS 반환
  - Then: `ConfigFile.load()` 후 `combat_dodge` 섹션에 `physical_keycode = KEY_L` 존재

- **AC-R6b**: 기본값 초기화 시 cfg 삭제
  - Given: 커스텀 cfg 존재
  - When: `reset_to_defaults()` 호출
  - Then: `FileAccess.file_exists("user://input_bindings.cfg")` = false

- **AC-R6c**: physical_keycode 우선 저장 (AZERTY 시뮬레이션)
  - Given: `event.physical_keycode=69(KEY_E)`, `event.keycode=81(KEY_Q)`
  - When: `request_rebind("interact", event)` SUCCESS 후 cfg 파일 확인
  - Then: `cfg.get_value("interact", "physical_keycode") = 69`, `keycode` 필드 없음(또는 0)

- **AC-F4a**: modifier 조합 중복 감지
  - Given: `combat_attack`에 Ctrl+J 바인딩
  - When: `request_rebind("interact", Ctrl+J)`
  - Then: `RebindResult.DUPLICATE_BINDING`

- **AC-F4b**: modifier 차이 → 중복 아님
  - Given: `combat_attack`에 J (modifier 없음) 바인딩
  - When: `request_rebind("interact", Ctrl+J)`
  - Then: `RebindResult.SUCCESS`

- **AC-F4c**: 이벤트 타입 다름 → 중복 아님
  - Given: `combat_attack`에 KEY_K 바인딩
  - When: `request_rebind("interact", InputEventJoypadButton(JOY_BUTTON_SOUTH))`
  - Then: `RebindResult.SUCCESS`

- **AC-E-focus-loss**: AWAITING_INPUT 포커스 손실
  - Given: AWAITING_INPUT 상태 (`interact` 리바인딩 대기)
  - When: `NOTIFICATION_WM_WINDOW_FOCUS_OUT` 시뮬레이션
  - Then: 상태 = ACTIVE, `action_get_events("interact")` 불변, cfg 불변

- **AC-E-save-fail**: 저장 실패 시 메모리 적용
  - Given: `user://` 쓰기 불가 시뮬레이션
  - When: `request_rebind("move_up", KEY_T)`
  - Then: `Input.is_action_pressed("move_up")` T키 반응, `RebindResult.SAVE_FAILED`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/input/input_map_rebind_test.gd` — GUT 테스트, 위 14개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (npc-registry) DONE — InputMapManager 기본 구조 필요
- Unlocks: 메인 메뉴/설정 UI 시스템 (리바인딩 화면 구현 가능)

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 14/14 passing (0 deferred)
**Deviations**:
- ADVISORY: focus_exited.connect(cancel_rebind) 람다 래핑 권장 — 기능 정상, 스타일 이슈
- ADVISORY: _save_to_cfg()가 keyboard만 직렬화 — gamepad/mouse 영속성은 후속 스토리 처리
- ADVISORY: AC-E-save-fail 테스트 경로 Linux 신뢰성 낮음 — 하드닝 권장
**Test Evidence**: Logic — tests/unit/input/input_map_rebind_test.gd (44 test functions, 14 AC COVERED)
**Code Review**: Complete (CHANGES REQUIRED → APPROVED: after_each InputMap cleanup + AC-F4c JOY_BUTTON_WEST 수정)
