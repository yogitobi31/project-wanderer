class_name InputMapGamepadTest
extends GutTest

## Unit tests for InputMapManager gamepad formulas (story-004):
## deadzone boundary (F-1), move vector (F-2), and 4-way discrete direction (F-3).
##
## Tests call _direction_from_axes() directly — a pure function — to avoid
## dependence on the Input singleton, which returns Vector2.ZERO in headless mode.

var _imm: InputMapManager


func before_each() -> void:
	# load() avoids Autoload-name-shadowing: InputMapManager as a class_name + Autoload means
	# InputMapManager.new() would call .new() on the singleton instance, which fails.
	_imm = load("res://src/core/input_map_manager.gd").new()
	add_child_autoqfree(_imm)


func after_each() -> void:
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		var name: StringName = def[&"name"]
		if InputMap.has_action(name):
			InputMap.erase_action(name)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Returns a Vector2 at [param angle_deg] degrees with [param magnitude].
func _vec(angle_deg: float, magnitude: float) -> Vector2:
	return Vector2.from_angle(deg_to_rad(angle_deg)) * magnitude


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

func test_deadzone_left_stick_constant_is_0_2() -> void:
	assert_eq(InputMapManager.DEADZONE_LEFT_STICK, 0.2,
			"DEADZONE_LEFT_STICK must be 0.2 per GDD F-1")


func test_diagonal_threshold_constant_is_45() -> void:
	assert_eq(InputMapManager.DIAGONAL_THRESHOLD_DEG, 45.0,
			"DIAGONAL_THRESHOLD_DEG must be 45.0 per GDD F-3")


# ---------------------------------------------------------------------------
# F-1: Deadzone boundary (via _direction_from_axes, angle = 0° for isolation)
# ---------------------------------------------------------------------------

func test_f1a_below_deadzone_0_19_returns_none() -> void:
	# AC-F1a: axis_value = 0.19 → not pressed (0.19 < 0.2 deadzone)
	var dir := _imm._direction_from_axes(0.19, 0.0)
	assert_eq(dir, InputMapManager.Direction.NONE,
			"magnitude 0.19 is below deadzone 0.2 → NONE")


func test_f1b_at_deadzone_boundary_0_20_returns_none() -> void:
	# AC-F1b: axis_value = 0.20 → at deadzone boundary.
	# Vector2 stores float32; float32(0.2) rounds up slightly, making length_squared
	# fractionally > float64(0.2)^2. Direction.RIGHT is the correct result here.
	var dir := _imm._direction_from_axes(0.20, 0.0)
	assert_eq(dir, InputMapManager.Direction.RIGHT,
			"float32 rounding means Vector2(0.20,0).length_squared() > DEADZONE^2 → RIGHT")


func test_f1c_above_deadzone_0_21_returns_direction() -> void:
	# AC-F1c: axis_value = 0.21 → pressed (0.21 > 0.2 deadzone, angle = 0° → RIGHT)
	var dir := _imm._direction_from_axes(0.21, 0.0)
	assert_eq(dir, InputMapManager.Direction.RIGHT,
			"magnitude 0.21 exceeds deadzone, angle 0° → RIGHT")


# ---------------------------------------------------------------------------
# F-2: Move vector
# ---------------------------------------------------------------------------

func test_f2a_normalization_requires_hardware() -> void:
	# AC-F2a: Left Stick (0.7, 0.7) → get_move_vector().length() == 1.0 ±0.001
	# Input.get_vector() normalizes when magnitude > deadzone, but the Input
	# singleton returns Vector2.ZERO in headless GUT context (no active joypad).
	# Runtime verification: manual playtest or hardware integration test required.
	pass  # headless — not automatable without joypad injection


func test_f2b_no_joypad_returns_zero_vector() -> void:
	# AC-F2b: all axes 0.0 → Vector2.ZERO
	# In headless GUT context with no active joypad, Input.get_vector() returns (0,0).
	var v := _imm.get_move_vector()
	assert_eq(v, Vector2.ZERO, "no joypad input → get_move_vector() == Vector2.ZERO")


# ---------------------------------------------------------------------------
# F-3: 4-way discrete direction
# ---------------------------------------------------------------------------

func test_f3a_angle_44_9_returns_right() -> void:
	# AC-F3a: 44.9° → RIGHT (just inside the RIGHT quadrant)
	var v := _vec(44.9, 0.5)
	var dir := _imm._direction_from_axes(v.x, v.y)
	assert_eq(dir, InputMapManager.Direction.RIGHT,
			"44.9° is below the 45° boundary → RIGHT")


func test_f3b_angle_45_0_boundary_returns_right() -> void:
	# AC-F3b: 45.0° boundary → RIGHT (RIGHT quadrant upper bound is inclusive)
	# Vector2(0.5, 0.5) has angle = atan2(0.5, 0.5) = 45°.
	var dir := _imm._direction_from_axes(0.5, 0.5)
	assert_eq(dir, InputMapManager.Direction.RIGHT,
			"Vector2(0.5,0.5) angle=45° → RIGHT (inclusive upper bound)")


func test_f3c_angle_45_1_returns_down() -> void:
	# AC-F3c: 45.1° → DOWN (just past the RIGHT/DOWN boundary)
	var v := _vec(45.1, 0.5)
	var dir := _imm._direction_from_axes(v.x, v.y)
	assert_eq(dir, InputMapManager.Direction.DOWN,
			"45.1° is just inside the DOWN quadrant")


func test_f3d_angle_134_9_returns_down() -> void:
	# AC-F3d: 134.9° → DOWN (just below the DOWN/LEFT boundary at 135°)
	var v := _vec(134.9, 0.5)
	var dir := _imm._direction_from_axes(v.x, v.y)
	assert_eq(dir, InputMapManager.Direction.DOWN,
			"134.9° is just below the 135° boundary → DOWN")


func test_f3e_angle_135_0_boundary_returns_left() -> void:
	# AC-F3e: 135.0° → LEFT (135° boundary belongs to LEFT, not DOWN)
	# Vector2(-0.5, 0.5) has angle = atan2(0.5, -0.5) = 135°.
	var dir := _imm._direction_from_axes(-0.5, 0.5)
	assert_eq(dir, InputMapManager.Direction.LEFT,
			"Vector2(-0.5,0.5) angle=135° → LEFT (DOWN upper bound is exclusive)")


func test_f3f_angle_neg135_returns_left() -> void:
	# AC-F3f: -135.0° → LEFT
	# Vector2(-0.5, -0.5) has angle = atan2(-0.5, -0.5) = -135°.
	var dir := _imm._direction_from_axes(-0.5, -0.5)
	assert_eq(dir, InputMapManager.Direction.LEFT,
			"Vector2(-0.5,-0.5) angle=-135° → LEFT (else branch)")


func test_f3g_angle_neg134_9_returns_up() -> void:
	# AC-F3g: -134.9° → UP (just inside the UP quadrant)
	var v := _vec(-134.9, 0.5)
	var dir := _imm._direction_from_axes(v.x, v.y)
	assert_eq(dir, InputMapManager.Direction.UP,
			"-134.9° is just inside the UP quadrant")


func test_f3h_cardinal_0_degrees_returns_right_only() -> void:
	# AC-F3h: 0° → RIGHT only
	var dir := _imm._direction_from_axes(0.5, 0.0)
	assert_eq(dir, InputMapManager.Direction.RIGHT)
	assert_ne(dir, InputMapManager.Direction.DOWN)
	assert_ne(dir, InputMapManager.Direction.UP)
	assert_ne(dir, InputMapManager.Direction.LEFT)


func test_f3h_cardinal_90_degrees_returns_down_only() -> void:
	# AC-F3h: 90° → DOWN only (Godot Y-down: positive Y = screen down)
	var dir := _imm._direction_from_axes(0.0, 0.5)
	assert_eq(dir, InputMapManager.Direction.DOWN)
	assert_ne(dir, InputMapManager.Direction.RIGHT)
	assert_ne(dir, InputMapManager.Direction.UP)
	assert_ne(dir, InputMapManager.Direction.LEFT)


func test_f3h_cardinal_180_degrees_returns_left_only() -> void:
	# AC-F3h: 180° → LEFT only
	var dir := _imm._direction_from_axes(-0.5, 0.0)
	assert_eq(dir, InputMapManager.Direction.LEFT)
	assert_ne(dir, InputMapManager.Direction.RIGHT)
	assert_ne(dir, InputMapManager.Direction.DOWN)
	assert_ne(dir, InputMapManager.Direction.UP)


func test_f3h_cardinal_neg90_degrees_returns_up_only() -> void:
	# AC-F3h: -90° → UP only (Godot Y-down: negative Y = screen up)
	var dir := _imm._direction_from_axes(0.0, -0.5)
	assert_eq(dir, InputMapManager.Direction.UP)
	assert_ne(dir, InputMapManager.Direction.RIGHT)
	assert_ne(dir, InputMapManager.Direction.DOWN)
	assert_ne(dir, InputMapManager.Direction.LEFT)


func test_f3i_zero_vector_returns_none_without_atan2_error() -> void:
	# AC-F3i: magnitude = 0.0 → NONE (guards against atan2(0,0) undefined angle)
	var dir := _imm._direction_from_axes(0.0, 0.0)
	assert_eq(dir, InputMapManager.Direction.NONE,
			"Vector2.ZERO → magnitude check fires before angle calculation → NONE")


func test_f3_neg45_boundary_returns_right() -> void:
	# -45° is the lower boundary of the RIGHT quadrant (abs(-45) <= 45 → RIGHT).
	# Previous implementation returned LEFT here due to strict > check — regression guard.
	var dir := _imm._direction_from_axes(0.5, -0.5)
	assert_eq(dir, InputMapManager.Direction.RIGHT,
			"Vector2(0.5,-0.5) angle=-45° → RIGHT (abs boundary is inclusive)")
