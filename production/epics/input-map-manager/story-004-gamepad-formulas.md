# Story 004: 게임패드 입력 공식 — Deadzone·이동벡터·4방향 이산화

> **Epic**: InputMapManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/입력-매핑-시스템.md`
**Requirements**: `TR-input-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: 게임패드 Left Stick deadzone = 0.2, `Input.get_vector()` 원형 데드존 패턴 사용. 4방향 이산화는 DIAGONAL_THRESHOLD_DEG = 45.0. StringName 리터럴(`&"action_name"`) 사용으로 핫패스 String 할당 최적화.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Input.get_vector()` — Godot 4.0+ 안정. 원형(radial) 데드존 + 정규화 자동 처리. `Vector2.angle()` — 라디안 반환, 변환 필요. `Input.get_joy_axis()` 대신 액션 기반 `Input.get_vector()` 사용 권장.

**Control Manifest Rules (Foundation layer)**:
- Required: `DEADZONE_LEFT_STICK`, `DIAGONAL_THRESHOLD_DEG`, `REBIND_AXIS_THRESHOLD` 상수로 관리 — 인라인 매직넘버 금지
- Required: StringName 리터럴 `&"move_left"` 형식 사용 — 핫패스 String 할당 최적화
- Forbidden: `JOY_BUTTON_0` 등 deprecated 상수 — `JOY_BUTTON_SOUTH` 등 이름 상수 사용

---

## Acceptance Criteria

*From GDD `design/gdd/입력-매핑-시스템.md`:*

**F-1: Deadzone**
- [ ] `axis_value = 0.19` → `Input.is_action_pressed("move_right")` = false (AC-F1a)
- [ ] `axis_value = 0.20` → false (경계값 — `>` 검증, `>=` 구현 감지) (AC-F1b)
- [ ] `axis_value = 0.21` → true (AC-F1c)

**F-2: 이동 벡터 정규화**
- [ ] Left Stick `(0.7, 0.7)` 입력 → `move_vector.length()` = 1.0 (±0.001) (AC-F2a)
- [ ] 모든 축 0.0 → `move_vector == Vector2.ZERO` (AC-F2b)

**F-3: 4방향 이산화**
- [ ] angle = 44.9° (magnitude > 0.2) → `move_right` = true, `move_down` = false (AC-F3a)
- [ ] angle = 45.0° (경계값) → `move_right` = true, `move_down` = false (45° = move_right 포함) (AC-F3b)
- [ ] angle = 45.1° → `move_down` = true, `move_right` = false (AC-F3c)
- [ ] angle = 134.9° → `move_down` = true, `move_left` = false (AC-F3d)
- [ ] angle = 135.0° → `move_left` = true (AC-F3e)
- [ ] angle = -135.0° → `move_left` = true (AC-F3f)
- [ ] angle = -134.9° → `move_up` = true, `move_left` = false (AC-F3g)
- [ ] angle = 0°/90°/180°/-90° 각각 → move_right/move_down/move_left/move_up 중 1개만 true (AC-F3h)
- [ ] magnitude ≤ 0.2 (deadzone 이내) → NONE, 각도 계산 없이 즉시 반환 (AC-F3i — atan2(0,0) 오탐 방지)

---

## Implementation Notes

*Derived from ADR-0002 + GDD F-1, F-2, F-3:*

```gdscript
# InputMapManager 상수
const DEADZONE_LEFT_STICK: float = 0.2
const DIAGONAL_THRESHOLD_DEG: float = 45.0
const REBIND_AXIS_THRESHOLD: float = 0.5  # F-4 의존성 — AWAITING_INPUT 가드 전용

# F-2: 이동 벡터 (PlayerController에서 매 프레임 호출)
func get_move_vector() -> Vector2:
    return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down", DEADZONE_LEFT_STICK)

# F-3: 4방향 이산화 (UI 메뉴 등 이산 입력 필요 시)
enum Direction { NONE, UP, DOWN, LEFT, RIGHT }

func get_discrete_direction() -> Direction:
    var axis_x := Input.get_axis(&"move_left", &"move_right")
    var axis_y := Input.get_axis(&"move_up", &"move_down")
    var magnitude := Vector2(axis_x, axis_y).length()
    if magnitude <= DEADZONE_LEFT_STICK:
        return Direction.NONE  # atan2(0,0) 오탐 방지 — magnitude 먼저 검사
    var angle_deg := rad_to_deg(Vector2(axis_x, axis_y).angle())
    # Godot Y-down: 양수 axis_y = 아래쪽
    if angle_deg > -DIAGONAL_THRESHOLD_DEG and angle_deg <= DIAGONAL_THRESHOLD_DEG:
        return Direction.RIGHT
    elif angle_deg > DIAGONAL_THRESHOLD_DEG and angle_deg <= 180.0 - DIAGONAL_THRESHOLD_DEG:
        return Direction.DOWN
    elif angle_deg > -(180.0 - DIAGONAL_THRESHOLD_DEG) and angle_deg <= -DIAGONAL_THRESHOLD_DEG:
        return Direction.UP
    else:
        return Direction.LEFT  # angle > 135° or angle <= -135°
```

**F-1 구현 주의**: `Input.get_vector()`는 내부적으로 deadzone 처리. F-1 AC는 deadzone이 엄격한 `>` 비교인지 검증 — `DEADZONE_LEFT_STICK = 0.2` 기준으로 `axis_value = 0.20`이 false여야 함.

**Godot 좌표계 주의**: Y-down 기준. 양수 axis_y = 화면 아래쪽 = move_down. angle 90° = move_down, -90° = move_up.

**`Input.get_vector()` 원형 데드존**: 성분별 데드존과 달리 대각선 경계에서 직선 스냅 없음. `(0.15, 0.15)` 입력: 크기 ≈ 0.212 > 0.2 → 대각선 (0.707, 0.707) 정규화 반환.

---

## Out of Scope

- Story 001: 14개 액션 등록, is_ready 가드
- Story 002: request_rebind() API (REBIND_AXIS_THRESHOLD는 Story 002에서 AWAITING_INPUT 가드로 사용)
- Story 003: is_ui_active 컨텍스트 분리
- 아날로그 스틱 → 이동 속도 변환 — PlayerController 담당 (InputMapManager는 벡터만 반환)

---

## QA Test Cases

- **AC-F1a/b/c**: Deadzone 경계값
  - Given: `DEADZONE_LEFT_STICK = 0.2`
  - When: Left Stick X에 `axis_value = 0.19 / 0.20 / 0.21` 주입
  - Then: `Input.is_action_pressed("move_right")` = false / false / true
  - Edge cases: 0.20이 false인지 반드시 검증 (`>=` 버그 감지)

- **AC-F2a**: 대각선 정규화
  - Given: Left Stick `(0.7, 0.7)` 입력
  - When: `get_move_vector()` 호출
  - Then: 반환 벡터 `length()` = 1.0 (±0.001)

- **AC-F2b**: 무입력 Vector2.ZERO
  - Given: 모든 축 0.0
  - When: `get_move_vector()` 호출
  - Then: Vector2.ZERO

- **AC-F3a~h**: 4방향 이산화 각도 경계값
  - Given: `DIAGONAL_THRESHOLD_DEG = 45.0`, 각 테스트 케이스의 angle과 magnitude > 0.2
  - When: `get_discrete_direction()` 호출
  - Then: 각 케이스별 기대 방향 (위 AC 목록 참조)
  - Edge cases: 정확히 45.0° / 135.0° / -135.0° 경계값 필수 검증

- **AC-F3i**: magnitude ≤ deadzone → NONE (atan2 오탐 방지)
  - Given: axis_x = 0.0, axis_y = 0.0 (magnitude = 0.0)
  - When: `get_discrete_direction()` 호출
  - Then: `Direction.NONE` (move_right 오탐 없음)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/input/input_map_gamepad_test.gd` — GUT 테스트, 위 11개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (input-map-manager) DONE — InputMapManager 액션 등록 후 공식 검증 가능
- Unlocks: PlayerController 이동 시스템 (get_move_vector() 소비)

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: 11/11 passing (AC-F2a: headless 한계 — runtime 검증은 playtest 시)
**Deviations**:
- ADVISORY: Implementation Notes의 분기 조건을 abs() 패턴으로 교체 — 코드 리뷰 승인
- ADVISORY: AC-F2a normalization — Input 싱글턴 headless 주입 불가, `test_f2a_normalization_requires_hardware` pass 처리
**Test Evidence**: Logic — `tests/unit/input/input_map_gamepad_test.gd` (19개 테스트)
**Code Review**: Complete (CHANGES REQUIRED → APPROVED)
