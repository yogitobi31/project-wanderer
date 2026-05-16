extends GutTest
## Tests for EnemyAI story-003: IDLE/CHASING/ATTACKING/DEAD FSM.
##
## Test strategy: signal handlers and state-process methods called directly to
## verify FSM transitions without live Area2D/Timer firing. select_target() tested
## as a pure helper by populating _bodies_in_range directly.
## Group-based mocks (plain CharacterBody2D with "player"/"companions" group) avoid
## instantiating PlayerController/CompanionAI and their _ready() assert requirements.

var _stats: CharacterStats
var _enemy: EnemyAI

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_spd = 100.0
	_enemy = EnemyAI.new()
	_enemy.stats = _stats
	_add_required_stubs(_enemy)
	add_child(_enemy)

func after_each() -> void:
	remove_child(_enemy)
	_enemy.free()
	# _stats is RefCounted, freed automatically

## Adds named child nodes required by _ready() asserts for .new()-based tests.
## Children are added before add_child(enemy) so @onready resolves at _ready() time.
func _add_required_stubs(enemy: EnemyAI) -> void:
	var nav := NavigationAgent2D.new()
	nav.name = "NavigationAgent2D"
	enemy.add_child(nav)
	var detection := Area2D.new()
	detection.name = "DetectionArea2D"
	enemy.add_child(detection)
	var hitbox := Area2D.new()
	hitbox.name = "HitboxArea2D"
	enemy.add_child(hitbox)
	var cooldown_t := Timer.new()
	cooldown_t.name = "AttackCooldownTimer"
	enemy.add_child(cooldown_t)
	var active_t := Timer.new()
	active_t.name = "AttackActiveTimer"
	enemy.add_child(active_t)

# ---------------------------------------------------------------------------
# AC-1: IDLE → CHASING when player enters DetectionArea2D
# ---------------------------------------------------------------------------

func test_enemy_ai_player_body_enters_detection_area_transitions_to_chasing() -> void:
	# Arrange
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	assert_eq(_enemy._state, EnemyAI.State.IDLE)
	# Act
	_enemy._on_detection_area_body_entered(player)
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.CHASING,
		"player body entering detection area must transition state from IDLE to CHASING")
	assert_eq(_enemy._current_target, player,
		"_current_target must be assigned to the entered player body")
	remove_child(player)
	player.free()

func test_enemy_ai_non_target_body_does_not_transition() -> void:
	# Arrange: body not in "player" or "companions" group
	var neutral: CharacterBody2D = CharacterBody2D.new()
	add_child(neutral)
	assert_eq(_enemy._state, EnemyAI.State.IDLE)
	# Act
	_enemy._on_detection_area_body_entered(neutral)
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.IDLE,
		"non-player, non-companion body entering detection area must not change state")
	remove_child(neutral)
	neutral.free()

func test_enemy_ai_detection_body_entered_dead_state_does_not_transition() -> void:
	# Arrange
	_enemy._state = EnemyAI.State.DEAD
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	# Act
	_enemy._on_detection_area_body_entered(player)
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.DEAD,
		"DEAD state must block transitions from DetectionArea2D")
	remove_child(player)
	player.free()

# ---------------------------------------------------------------------------
# AC-2: player priority over nearest companion
# ---------------------------------------------------------------------------

func test_enemy_ai_select_target_prefers_player_over_closer_companion() -> void:
	# Arrange: player at 200px (far), companion at 30px (near)
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	var companion: CharacterBody2D = CharacterBody2D.new()
	companion.add_to_group("companions")
	add_child(companion)
	_enemy.global_position = Vector2.ZERO
	player.global_position = Vector2(200.0, 0.0)
	companion.global_position = Vector2(30.0, 0.0)
	_enemy._bodies_in_range.append(companion)
	_enemy._bodies_in_range.append(player)
	# Act
	var result: Node2D = _enemy.select_target()
	# Assert
	assert_eq(result, player,
		"select_target must return the player body regardless of companion proximity")
	remove_child(player)
	remove_child(companion)
	player.free()
	companion.free()

func test_enemy_ai_select_target_returns_nearest_companion_when_no_player() -> void:
	# Arrange: two companions, companion_b is nearer
	var companion_a: CharacterBody2D = CharacterBody2D.new()
	companion_a.add_to_group("companions")
	add_child(companion_a)
	var companion_b: CharacterBody2D = CharacterBody2D.new()
	companion_b.add_to_group("companions")
	add_child(companion_b)
	_enemy.global_position = Vector2.ZERO
	companion_a.global_position = Vector2(300.0, 0.0)
	companion_b.global_position = Vector2(100.0, 0.0)
	_enemy._bodies_in_range.append(companion_a)
	_enemy._bodies_in_range.append(companion_b)
	# Act
	var result: Node2D = _enemy.select_target()
	# Assert
	assert_eq(result, companion_b,
		"select_target must return the nearest companion when no player is present")
	remove_child(companion_a)
	remove_child(companion_b)
	companion_a.free()
	companion_b.free()

# ---------------------------------------------------------------------------
# AC-3: CHASING → ATTACKING when distance ≤ ENEMY_ATTACK_RANGE (60 px)
# ---------------------------------------------------------------------------

func test_enemy_ai_chasing_within_attack_range_transitions_to_attacking() -> void:
	# Arrange: CHASING with a nearby player target
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_enemy._on_detection_area_body_entered(player)
	assert_eq(_enemy._state, EnemyAI.State.CHASING)
	_enemy.global_position = Vector2.ZERO
	player.global_position = Vector2(30.0, 0.0)  # 30 px < ENEMY_ATTACK_RANGE 60 px
	# Act: _process_chasing returns before NavigationAgent2D access when within range
	_enemy._process_chasing()
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.ATTACKING,
		"distance 30 < ENEMY_ATTACK_RANGE 60 must transition state to ATTACKING")
	assert_false(_enemy._attack_cooldown_timer.is_stopped(),
		"transition to ATTACKING must start AttackCooldownTimer")
	remove_child(player)
	player.free()

func test_enemy_ai_chasing_beyond_attack_range_remains_chasing() -> void:
	# Arrange: CHASING with a distant player target
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_enemy._on_detection_area_body_entered(player)
	assert_eq(_enemy._state, EnemyAI.State.CHASING)
	_enemy.global_position = Vector2.ZERO
	player.global_position = Vector2(200.0, 0.0)  # 200 px > ENEMY_ATTACK_RANGE 60 px
	# Act
	_enemy._process_chasing()
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.CHASING,
		"distance 200 > ENEMY_ATTACK_RANGE 60 must keep state as CHASING")
	remove_child(player)
	player.free()

# ---------------------------------------------------------------------------
# AC-4: health_depleted → DEAD
# ---------------------------------------------------------------------------

func test_enemy_ai_health_depleted_transitions_to_dead() -> void:
	# Arrange
	assert_eq(_enemy._state, EnemyAI.State.IDLE)
	# Act
	_enemy._on_health_depleted()
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.DEAD,
		"health_depleted must transition state to DEAD")

func test_enemy_ai_health_depleted_disables_physics_processing() -> void:
	# Act
	_enemy._on_health_depleted()
	# Assert
	assert_false(_enemy.is_physics_processing(),
		"DEAD state must disable physics processing via set_physics_process(false)")

func test_enemy_ai_health_depleted_disables_hitbox_monitoring() -> void:
	# Arrange
	_enemy.hitbox_area.monitoring = true
	# Act
	_enemy._on_health_depleted()
	# Assert
	assert_false(_enemy.hitbox_area.monitoring,
		"health_depleted must disable HitboxArea2D monitoring via _stop_attack()")

func test_enemy_ai_health_depleted_disables_detection_area_monitoring() -> void:
	# Arrange
	_enemy.detection_area.monitoring = true
	# Act
	_enemy._on_health_depleted()
	# Assert
	assert_false(_enemy.detection_area.monitoring,
		"health_depleted must set DetectionArea2D monitoring=false")

# ---------------------------------------------------------------------------
# AC-5: target exits detection radius → IDLE
# ---------------------------------------------------------------------------

func test_enemy_ai_last_target_exits_detection_area_transitions_to_idle() -> void:
	# Arrange: CHASING state
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_enemy._on_detection_area_body_entered(player)
	assert_eq(_enemy._state, EnemyAI.State.CHASING)
	# Act
	_enemy._on_detection_area_body_exited(player)
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.IDLE,
		"last target exiting detection area must transition state to IDLE")
	assert_null(_enemy._current_target,
		"_current_target must be cleared when all targets exit")
	remove_child(player)
	player.free()

func test_enemy_ai_attacking_invalid_target_transitions_to_idle() -> void:
	# Arrange: ATTACKING state with active hitbox
	var player: CharacterBody2D = CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	_enemy._on_detection_area_body_entered(player)
	_enemy._state = EnemyAI.State.ATTACKING
	_enemy.hitbox_area.monitoring = true
	# Act: free the target (makes _current_target invalid)
	remove_child(player)
	player.free()
	_enemy._process_attacking()
	# Assert
	assert_eq(_enemy._state, EnemyAI.State.IDLE,
		"ATTACKING with invalid target must transition to IDLE")
	assert_false(_enemy.hitbox_area.monitoring,
		"ATTACKING→IDLE must disable hitbox via _stop_attack()")
