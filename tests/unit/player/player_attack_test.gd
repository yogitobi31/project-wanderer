extends GutTest
## Tests for PlayerController story-002: ATTACKING FSM + HitboxArea2D area_entered handling.
##
## Test strategy: call start_attack() and _on_attack_finished() directly — bypasses
## InputMapManager and AnimationPlayer. AnimationPlayer hitbox.monitoring keyframes
## (AC-2/AC-3) require the editor scene and are deferred to visual playtest.
##
## AC-1: start_attack() transitions to ATTACKING; movement is blocked in ATTACKING state
## AC-4: _on_hitbox_area_entered() calls hit_confirmed on the target HealthComponent
## AC-5: _on_attack_finished() returns state to IDLE

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

var _stats: CharacterStats
var _player: PlayerController

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_spd = 130.0
	_stats.base_atk = 20
	_stats.base_def = 0
	_player = PlayerController.new()
	_player.stats = _stats
	add_child(_player)

func after_each() -> void:
	remove_child(_player)
	_player.free()
	# _stats is RefCounted, freed automatically

# ---------------------------------------------------------------------------
# AC-1: start_attack transitions to ATTACKING
# ---------------------------------------------------------------------------

func test_start_attack_from_idle_sets_state_attacking() -> void:
	# Arrange: default IDLE state
	assert_eq(_player._state, PlayerController.State.IDLE)
	# Act
	_player.start_attack()
	# Assert
	assert_eq(_player._state, PlayerController.State.ATTACKING,
		"start_attack() must transition state from IDLE to ATTACKING")

func test_start_attack_from_moving_sets_state_attacking() -> void:
	# Arrange: prime into MOVING
	_player._process_movement(Vector2(1.0, 0.0))
	assert_eq(_player._state, PlayerController.State.MOVING)
	# Act
	_player.start_attack()
	# Assert
	assert_eq(_player._state, PlayerController.State.ATTACKING,
		"start_attack() must transition state from MOVING to ATTACKING")

func test_start_attack_ignored_when_already_attacking() -> void:
	# Arrange
	_player.start_attack()
	assert_eq(_player._state, PlayerController.State.ATTACKING)
	# Act: second call must be a no-op
	_player.start_attack()
	# Assert
	assert_eq(_player._state, PlayerController.State.ATTACKING,
		"start_attack() must be a no-op when already in ATTACKING state")

func test_start_attack_ignored_when_dead() -> void:
	# Arrange: force into DEAD state
	_player._state = PlayerController.State.DEAD
	# Act
	_player.start_attack()
	# Assert
	assert_eq(_player._state, PlayerController.State.DEAD,
		"start_attack() must be a no-op when in DEAD state")

# ---------------------------------------------------------------------------
# AC-1: movement blocked during ATTACKING
# ---------------------------------------------------------------------------

func test_process_movement_velocity_zero_while_attacking() -> void:
	# Arrange
	_player.start_attack()
	# Act: non-zero input during attack
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert
	assert_eq(_player.velocity, Vector2.ZERO,
		"velocity must remain Vector2.ZERO while in ATTACKING state")

func test_process_movement_state_unchanged_while_attacking() -> void:
	# Arrange
	_player.start_attack()
	# Act
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert: must not flip to MOVING
	assert_eq(_player._state, PlayerController.State.ATTACKING,
		"state must remain ATTACKING when movement input arrives during attack")

# ---------------------------------------------------------------------------
# AC-4: area_entered → hit_confirmed on target HealthComponent
# ---------------------------------------------------------------------------

func test_on_hitbox_area_entered_calls_hit_confirmed_on_target() -> void:
	# Arrange: mock target — parent node with HealthComponent + hurtbox as siblings
	var target_root: Node2D = Node2D.new()
	var target_hurtbox: Area2D = Area2D.new()
	var target_stats: CharacterStats = CharacterStats.new()
	target_stats.base_max_hp = 100
	target_stats.base_def = 0
	var target_health: HealthComponent = HealthComponent.new()
	target_health.name = "HealthComponent"
	target_health.stats = target_stats
	target_root.add_child(target_health)
	target_root.add_child(target_hurtbox)
	add_child(target_root)
	# Act
	_player._on_hitbox_area_entered(target_hurtbox)
	# Assert: final_damage = max(1, atk(20) - def(0)) = 20  →  hp = 100 - 20 = 80
	assert_eq(target_health.current_health, 80,
		"hit_confirmed must be called with stats.atk as damage (final_damage = 20)")
	# Cleanup
	remove_child(target_root)
	target_root.free()
	# target_stats is RefCounted, freed automatically

func test_on_hitbox_area_entered_no_op_when_no_health_component() -> void:
	# Arrange: hurtbox whose parent has no HealthComponent
	var parent_node: Node2D = Node2D.new()
	var lone_hurtbox: Area2D = Area2D.new()
	parent_node.add_child(lone_hurtbox)
	add_child(parent_node)
	var state_before: PlayerController.State = _player._state
	# Act
	_player._on_hitbox_area_entered(lone_hurtbox)
	# Assert: no side effects — state unchanged confirms no-op
	assert_eq(_player._state, state_before,
		"state must be unchanged when target has no HealthComponent")
	# Cleanup
	remove_child(parent_node)
	parent_node.free()

# ---------------------------------------------------------------------------
# AC-5: _on_attack_finished returns to IDLE
# ---------------------------------------------------------------------------

func test_on_attack_finished_sets_state_idle() -> void:
	# Arrange
	_player.start_attack()
	assert_eq(_player._state, PlayerController.State.ATTACKING)
	# Act
	_player._on_attack_finished()
	# Assert
	assert_eq(_player._state, PlayerController.State.IDLE,
		"_on_attack_finished() must transition state from ATTACKING to IDLE")

func test_after_attack_finished_movement_resumes_normally() -> void:
	# Arrange: complete an attack cycle
	_player.start_attack()
	_player._on_attack_finished()
	assert_eq(_player._state, PlayerController.State.IDLE)
	# Act: movement input after attack
	_player._process_movement(Vector2(1.0, 0.0))
	# Assert: normal movement resumes
	assert_eq(_player._state, PlayerController.State.MOVING,
		"state must transition to MOVING after attack cycle completes")
	assert_eq(_player.velocity.x, _stats.spd,
		"velocity must equal stats.spd after attack cycle completes")
