extends GutTest
## Tests for PlayerController story-001: IDLE/MOVING FSM + movement formula.
##
## Test strategy: call _process_movement(vector) directly — bypasses InputMapManager Autoload.
## move_and_slide() is a no-op in headless GUT (no physics world); AC-3's move_and_slide()
## call is verified to exist in the source and will be exercised in Vertical Slice playtest.
##
## Note on DEAD state: _process_movement has no internal DEAD guard — the guard lives in
## _physics_process. story-003 must add an integration test via _physics_process for DEAD.

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

var _stats: CharacterStats
var _player: PlayerController

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_spd = 130.0  # stats.spd computed == 130.0 (mod_spd defaults to 0)
	_player = PlayerController.new()
	_player.stats = _stats   # assign before add_child so _ready() assert passes
	add_child(_player)

func after_each() -> void:
	remove_child(_player)
	_player.free()
	# _stats is RefCounted, freed automatically

# ---------------------------------------------------------------------------
# AC-3: velocity = move_vec * stats.spd when input is non-zero
# ---------------------------------------------------------------------------

func test_process_movement_right_input_sets_velocity_x_to_spd() -> void:
	# Arrange: rightward unit vector
	# Act
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert
	assert_eq(_player.velocity.x, _stats.spd,
		"velocity.x must equal stats.spd (130.0) for rightward unit input")
	assert_eq(_player.velocity.y, 0.0)

func test_process_movement_up_input_sets_velocity_y_to_negative_spd() -> void:
	# Arrange: upward unit vector (Godot Y-down: up == negative Y)
	# Act
	_player._process_movement(Vector2(0.0, -1.0))
	# Assert
	assert_eq(_player.velocity.y, -_stats.spd,
		"velocity.y must equal -stats.spd (-130.0) for upward unit input")
	assert_eq(_player.velocity.x, 0.0)

func test_process_movement_diagonal_input_scales_by_spd() -> void:
	# Arrange: raw diagonal — NOT normalized; magnitude == sqrt(2) ~= 1.414.
	# In real gameplay, InputMapManager.get_move_vector() returns a normalized vector,
	# so diagonal speed = Vector2(1,1).normalized() * 130.0 ~= 91.9 px/s per axis.
	# This test confirms _process_movement does NOT normalize — normalization is
	# InputMapManager's responsibility.
	var diagonal: Vector2 = Vector2(1.0, 1.0)
	# Act
	_player._process_movement(diagonal)
	# Assert: velocity must equal diagonal * stats.spd exactly
	var expected: Vector2 = diagonal * _stats.spd
	assert_eq(_player.velocity, expected,
		"velocity must equal move_vec * stats.spd for diagonal input")

# ---------------------------------------------------------------------------
# AC-4: velocity == Vector2.ZERO when input is zero
# ---------------------------------------------------------------------------

func test_process_movement_zero_input_sets_velocity_to_zero() -> void:
	# Arrange: prime with a non-zero velocity first
	_player._process_movement(Vector2(1.0, 0.0))
	assert_ne(_player.velocity, Vector2.ZERO)  # pre-condition
	# Act
	_player._process_movement(Vector2.ZERO)
	# Assert
	assert_eq(_player.velocity, Vector2.ZERO,
		"velocity must be Vector2.ZERO when move_vec is zero")

# ---------------------------------------------------------------------------
# AC-5: FSM — state transitions on input presence / absence
# ---------------------------------------------------------------------------

func test_process_movement_nonzero_input_sets_state_moving() -> void:
	# Arrange: start in IDLE (default)
	assert_eq(_player._state, PlayerController.State.IDLE)  # pre-condition
	# Act
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert
	assert_eq(_player._state, PlayerController.State.MOVING,
		"non-zero input must transition state to MOVING")

func test_process_movement_zero_input_sets_state_idle() -> void:
	# Arrange: prime into MOVING first
	_player._process_movement(Vector2(1.0, 0.0))
	assert_eq(_player._state, PlayerController.State.MOVING)  # pre-condition
	# Act
	_player._process_movement(Vector2.ZERO)
	# Assert
	assert_eq(_player._state, PlayerController.State.IDLE,
		"zero input must transition state to IDLE")

func test_process_movement_moving_to_idle_transition() -> void:
	# Arrange: MOVING state
	_player._process_movement(Vector2(0.0, 1.0))
	assert_eq(_player._state, PlayerController.State.MOVING)
	# Act
	_player._process_movement(Vector2.ZERO)
	# Assert
	assert_eq(_player._state, PlayerController.State.IDLE,
		"MOVING -> IDLE: zero input after non-zero must transition to IDLE")

func test_process_movement_idle_to_moving_transition() -> void:
	# Arrange: IDLE state (default)
	assert_eq(_player._state, PlayerController.State.IDLE)
	# Act
	_player._process_movement(Vector2(-1.0, 0.0))
	# Assert
	assert_eq(_player._state, PlayerController.State.MOVING,
		"IDLE -> MOVING: non-zero input must transition to MOVING")
