extends GutTest
## Tests for CompanionAI story-001: FOLLOWING/CHASING FSM — pure helper functions.
##
## Test strategy: call pure helper functions (get_follow_destination, should_teleport,
## should_stop_at) directly — bypasses NavigationAgent2D which is a no-op headlessly.
## Signal handlers are called directly to verify state transitions without a live Area2D.
## _process_chasing() target_position assignment is exercised in Vertical Slice playtest.

class _HealthStub extends Node:
	signal health_depleted()

var _stats: CharacterStats
var _companion: CompanionAI
var _player: CharacterBody2D

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_spd = 100.0
	_companion = CompanionAI.new()
	_companion.stats = _stats
	_add_required_stubs(_companion)
	_player = CharacterBody2D.new()
	add_child(_player)
	add_child(_companion)
	_companion.player_target = _player

## Adds minimal child nodes required by _ready() asserts so .new()-based tests work.
func _add_required_stubs(companion: CompanionAI) -> void:
	var nav := NavigationAgent2D.new()
	nav.name = "NavigationAgent2D"
	companion.add_child(nav)
	var detection := Area2D.new()
	detection.name = "DetectionArea2D"
	companion.add_child(detection)
	var hitbox := Area2D.new()
	hitbox.name = "HitboxArea2D"
	hitbox.monitoring = false
	companion.add_child(hitbox)
	var hc := _HealthStub.new()
	hc.name = "HealthComponent"
	companion.add_child(hc)
	var cooldown_t := Timer.new()
	cooldown_t.name = "AttackCooldownTimer"
	companion.add_child(cooldown_t)
	var active_t := Timer.new()
	active_t.name = "AttackActiveTimer"
	companion.add_child(active_t)

func after_each() -> void:
	remove_child(_companion)
	remove_child(_player)
	_companion.queue_free()
	_player.queue_free()
	# _stats is RefCounted (Resource) — freed automatically

# ---------------------------------------------------------------------------
# AC-1: formation offsets per party slot
# ---------------------------------------------------------------------------

func test_get_follow_destination_slot0_returns_player_position_plus_offset() -> void:
	# Arrange
	_player.global_position = Vector2(100.0, 200.0)
	_companion.party_slot = 0
	# Act
	var dest: Vector2 = _companion.get_follow_destination()
	# Assert
	assert_eq(dest, Vector2(40.0, 220.0),
		"slot 0: destination must equal player.pos + (-60, 20)")

func test_get_follow_destination_slot1_returns_player_position_plus_offset() -> void:
	# Arrange
	_player.global_position = Vector2(100.0, 200.0)
	_companion.party_slot = 1
	# Act
	var dest: Vector2 = _companion.get_follow_destination()
	# Assert
	assert_eq(dest, Vector2(160.0, 220.0),
		"slot 1: destination must equal player.pos + (60, 20)")

func test_get_follow_destination_slot2_returns_player_position_plus_offset() -> void:
	# Arrange
	_player.global_position = Vector2(100.0, 200.0)
	_companion.party_slot = 2
	# Act
	var dest: Vector2 = _companion.get_follow_destination()
	# Assert
	assert_eq(dest, Vector2(100.0, 250.0),
		"slot 2: destination must equal player.pos + (0, 50)")

func test_get_follow_destination_no_player_target_returns_own_position() -> void:
	# Arrange: null player_target
	_companion.player_target = null
	_companion.global_position = Vector2(55.0, 80.0)
	# Act
	var dest: Vector2 = _companion.get_follow_destination()
	# Assert
	assert_eq(dest, Vector2(55.0, 80.0),
		"null player_target: must fall back to own global_position")

# ---------------------------------------------------------------------------
# AC-2: stop within FOLLOW_STOP_DISTANCE (40 px)
# ---------------------------------------------------------------------------

func test_should_stop_at_distance_inside_threshold_returns_true() -> void:
	# Arrange: 30 px < 40 px
	_companion.global_position = Vector2.ZERO
	# Act / Assert
	assert_true(_companion.should_stop_at(Vector2(30.0, 0.0)),
		"distance 30 < FOLLOW_STOP_DISTANCE 40 must return true")

func test_should_stop_at_distance_outside_threshold_returns_false() -> void:
	# Arrange: 50 px > 40 px
	_companion.global_position = Vector2.ZERO
	# Act / Assert
	assert_false(_companion.should_stop_at(Vector2(50.0, 0.0)),
		"distance 50 > FOLLOW_STOP_DISTANCE 40 must return false")

func test_should_stop_at_exact_threshold_returns_true() -> void:
	# Arrange: exactly 40 px — boundary is inclusive (<=)
	_companion.global_position = Vector2.ZERO
	# Act / Assert
	assert_true(_companion.should_stop_at(Vector2(40.0, 0.0)),
		"distance == FOLLOW_STOP_DISTANCE 40 must return true (boundary inclusive)")

# ---------------------------------------------------------------------------
# AC-3: teleport when distance > TELEPORT_THRESHOLD (600 px)
# ---------------------------------------------------------------------------

func test_should_teleport_distance_beyond_threshold_returns_true() -> void:
	# Act / Assert
	assert_true(_companion.should_teleport(700.0),
		"distance 700 > TELEPORT_THRESHOLD 600 must return true")

func test_should_teleport_distance_within_threshold_returns_false() -> void:
	# Act / Assert
	assert_false(_companion.should_teleport(500.0),
		"distance 500 < TELEPORT_THRESHOLD 600 must return false")

func test_companion_ai_teleport_moves_global_position_to_follow_destination() -> void:
	# Arrange: place companion >600px from player
	_player.global_position = Vector2.ZERO
	_companion.global_position = Vector2(700.0, 0.0)
	_companion.party_slot = 0
	# Act: teleport branch returns early before navigation_agent access — safe headlessly
	_companion._process_following()
	# Assert: position must equal player.pos + slot-0 offset
	assert_eq(_companion.global_position, Vector2(-60.0, 20.0),
		"companion must teleport to player.pos + slot-0 offset when distance > TELEPORT_THRESHOLD")

# ---------------------------------------------------------------------------
# AC-4: enemy enters DetectionArea2D → CHASING state
# ---------------------------------------------------------------------------

func test_on_detection_body_entered_enemy_group_transitions_to_chasing() -> void:
	# Arrange
	var mock_enemy: Node2D = Node2D.new()
	mock_enemy.add_to_group("enemies")
	add_child(mock_enemy)
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING)
	# Act: call handler directly — mirrors what DetectionArea2D.body_entered emits
	_companion._on_detection_area_body_entered(mock_enemy)
	# Assert
	assert_eq(_companion._state, CompanionAI.State.CHASING,
		"enemy body entering detection area must transition state to CHASING")
	assert_eq(_companion._current_target, mock_enemy,
		"_current_target must be assigned to the entered enemy")
	remove_child(mock_enemy)
	mock_enemy.free()

func test_on_detection_body_exited_current_target_transitions_to_following() -> void:
	# Arrange: establish CHASING state first
	var mock_enemy: Node2D = Node2D.new()
	mock_enemy.add_to_group("enemies")
	add_child(mock_enemy)
	_companion._on_detection_area_body_entered(mock_enemy)
	assert_eq(_companion._state, CompanionAI.State.CHASING)
	# Act
	_companion._on_detection_area_body_exited(mock_enemy)
	# Assert
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING,
		"current target exiting detection area must transition back to FOLLOWING")
	assert_null(_companion._current_target,
		"_current_target must be cleared when current target exits")
	remove_child(mock_enemy)
	mock_enemy.free()

func test_on_detection_body_entered_dead_state_does_not_transition() -> void:
	# Arrange: companion is dead
	_companion._state = CompanionAI.State.DEAD
	var mock_enemy: Node2D = Node2D.new()
	mock_enemy.add_to_group("enemies")
	add_child(mock_enemy)
	# Act
	_companion._on_detection_area_body_entered(mock_enemy)
	# Assert: DEAD guard must prevent any transition
	assert_eq(_companion._state, CompanionAI.State.DEAD,
		"DEAD state must block state transitions from DetectionArea2D")
	remove_child(mock_enemy)
	mock_enemy.free()

func test_on_detection_body_entered_non_enemy_does_not_transition() -> void:
	# Arrange: body NOT in "enemies" group
	var friendly: CharacterBody2D = CharacterBody2D.new()
	add_child(friendly)
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING)
	# Act
	_companion._on_detection_area_body_entered(friendly)
	# Assert: non-enemy must not trigger CHASING
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING,
		"non-enemy body entering detection area must not change state")
	assert_null(_companion._current_target,
		"_current_target must remain null for non-enemy body")
	remove_child(friendly)
	friendly.free()

func test_on_detection_body_exited_second_enemy_retargets_remaining() -> void:
	# Arrange: two enemies enter, first exits
	var enemy_a: Node2D = Node2D.new()
	var enemy_b: Node2D = Node2D.new()
	enemy_a.add_to_group("enemies")
	enemy_b.add_to_group("enemies")
	add_child(enemy_a)
	add_child(enemy_b)
	_companion._on_detection_area_body_entered(enemy_a)
	_companion._on_detection_area_body_entered(enemy_b)
	assert_eq(_companion._state, CompanionAI.State.CHASING)
	# Act: first enemy exits
	_companion._on_detection_area_body_exited(enemy_a)
	# Assert: must stay CHASING and retarget enemy_b
	assert_eq(_companion._state, CompanionAI.State.CHASING,
		"state must remain CHASING when a second enemy is still in range")
	assert_eq(_companion._current_target, enemy_b,
		"_current_target must switch to remaining enemy")
	remove_child(enemy_a)
	remove_child(enemy_b)
	enemy_a.free()
	enemy_b.free()
