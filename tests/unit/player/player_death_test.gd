extends GutTest
## Tests for PlayerController story-003: DEAD FSM + set_spawn_position().
##
## Test strategy: call _on_health_depleted() directly — bypasses HealthComponent
## scene node (null-safe @onready). set_spawn_position() is tested directly.
##
## AC-1: _on_health_depleted() transitions state to DEAD
## AC-2: DEAD state blocks movement (velocity == Vector2.ZERO, state stays DEAD)
## AC-3: DEAD state blocks attack (start_attack() is a no-op)
## AC-4: set_spawn_position(pos) sets global_position == pos
## AC-5: _on_health_depleted() emits player_died signal

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

var _stats: CharacterStats
var _player: PlayerController

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_spd = 130.0
	_stats.base_atk = 20
	_player = PlayerController.new()
	_player.stats = _stats
	add_child(_player)

func after_each() -> void:
	remove_child(_player)
	_player.free()
	# _stats is RefCounted, freed automatically

# ---------------------------------------------------------------------------
# AC-1: health_depleted → DEAD state
# ---------------------------------------------------------------------------

func test_on_health_depleted_sets_state_dead() -> void:
	# Arrange: default IDLE state
	assert_eq(_player._state, PlayerController.State.IDLE)
	# Act
	_player._on_health_depleted()
	# Assert
	assert_eq(_player._state, PlayerController.State.DEAD,
		"_on_health_depleted() must transition state to DEAD")

# ---------------------------------------------------------------------------
# AC-2: DEAD state blocks movement
# ---------------------------------------------------------------------------

func test_dead_state_blocks_movement_velocity() -> void:
	# Arrange
	_player._on_health_depleted()
	assert_eq(_player._state, PlayerController.State.DEAD)
	# Act: non-zero movement input while dead
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert
	assert_eq(_player.velocity, Vector2.ZERO,
		"velocity must remain Vector2.ZERO while in DEAD state")

func test_dead_state_cannot_be_overridden_by_movement_input() -> void:
	# Arrange
	_player._on_health_depleted()
	# Act: movement input (normally transitions to MOVING)
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert: DEAD state is sticky
	assert_eq(_player._state, PlayerController.State.DEAD,
		"state must remain DEAD when movement input arrives in DEAD state")

func test_dead_state_cannot_be_overridden_by_zero_input() -> void:
	# Arrange
	_player._on_health_depleted()
	# Act: zero input (normally transitions to IDLE)
	_player._process_movement(Vector2.ZERO)
	# Assert
	assert_eq(_player._state, PlayerController.State.DEAD,
		"state must remain DEAD when zero input arrives in DEAD state")

# ---------------------------------------------------------------------------
# AC-3: DEAD state blocks attack
# ---------------------------------------------------------------------------

func test_dead_state_blocks_start_attack() -> void:
	# Arrange
	_player._on_health_depleted()
	assert_eq(_player._state, PlayerController.State.DEAD)
	# Act
	_player.start_attack()
	# Assert
	assert_eq(_player._state, PlayerController.State.DEAD,
		"start_attack() must be a no-op in DEAD state")

func test_on_health_depleted_from_attacking_state_sets_dead() -> void:
	# Arrange: prime into ATTACKING first
	_player.start_attack()
	assert_eq(_player._state, PlayerController.State.ATTACKING)
	# Act
	_player._on_health_depleted()
	# Assert: DEAD must override ATTACKING unconditionally
	assert_eq(_player._state, PlayerController.State.DEAD,
		"_on_health_depleted() must transition to DEAD even from ATTACKING state")

# ---------------------------------------------------------------------------
# AC-4: set_spawn_position sets global_position
# ---------------------------------------------------------------------------

func test_set_spawn_position_updates_global_position() -> void:
	# Arrange: node is in scene tree (add_child in before_each)
	# Act
	_player.set_spawn_position(Vector2(100.0, 200.0))
	# Assert
	assert_eq(_player.global_position, Vector2(100.0, 200.0),
		"set_spawn_position must set global_position to the given Vector2")

func test_set_spawn_position_can_be_called_while_dead() -> void:
	# Arrange: DEAD state should not block respawn placement
	_player._on_health_depleted()
	# Act
	_player.set_spawn_position(Vector2(50.0, 75.0))
	# Assert
	assert_eq(_player.global_position, Vector2(50.0, 75.0),
		"set_spawn_position must work even in DEAD state")

# ---------------------------------------------------------------------------
# AC-5: player_died signal emitted on health_depleted
# ---------------------------------------------------------------------------

func test_on_health_depleted_emits_player_died_signal() -> void:
	# Arrange
	watch_signals(_player)
	# Act
	_player._on_health_depleted()
	# Assert
	assert_signal_emitted(_player, "player_died",
		"player_died signal must be emitted when health_depleted is received")
