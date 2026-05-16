extends GutTest
## Tests for CompanionAI story-002: ATTACKING/DEAD FSM.
##
## Test strategy: call _process_chasing() directly for AC-1 (returns before
## NavigationAgent2D access when within ATTACK_RANGE). Timer callbacks
## (_on_attack_cooldown_timeout, _on_attack_active_timeout) called directly
## to verify HitboxArea2D monitoring cycle without live Timer firing.
## _on_health_depleted() called directly to verify DEAD state transitions.

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

func after_each() -> void:
	remove_child(_companion)
	remove_child(_player)
	_companion.queue_free()
	_player.queue_free()
	# _stats is RefCounted (Resource) — freed automatically

## Adds child nodes required by _ready() asserts for .new()-based tests.
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

# ---------------------------------------------------------------------------
# AC-1: CHASING → ATTACKING when distance ≤ ATTACK_RANGE (60 px)
# ---------------------------------------------------------------------------

func test_companion_ai_chasing_within_attack_range_transitions_to_attacking() -> void:
	# Arrange: set up CHASING state with a nearby enemy
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.add_to_group("enemies")
	add_child(enemy)
	_companion._on_detection_area_body_entered(enemy)
	assert_eq(_companion._state, CompanionAI.State.CHASING)
	_companion.global_position = Vector2.ZERO
	enemy.global_position = Vector2(30.0, 0.0)  # 30 px < ATTACK_RANGE 60 px
	# Act: _process_chasing returns before NavigationAgent2D access when within range
	_companion._process_chasing()
	# Assert
	assert_eq(_companion._state, CompanionAI.State.ATTACKING,
		"distance 30 < ATTACK_RANGE 60 must transition state to ATTACKING")
	assert_false(_companion._attack_cooldown_timer.is_stopped(),
		"transition to ATTACKING must start AttackCooldownTimer")
	remove_child(enemy)
	enemy.free()

func test_companion_ai_chasing_beyond_attack_range_remains_chasing() -> void:
	# Arrange: enemy far outside ATTACK_RANGE
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.add_to_group("enemies")
	add_child(enemy)
	_companion._on_detection_area_body_entered(enemy)
	assert_eq(_companion._state, CompanionAI.State.CHASING)
	_companion.global_position = Vector2.ZERO
	enemy.global_position = Vector2(200.0, 0.0)  # 200 px > ATTACK_RANGE 60 px
	# Act
	_companion._process_chasing()
	# Assert: state must remain CHASING
	assert_eq(_companion._state, CompanionAI.State.CHASING,
		"distance 200 > ATTACK_RANGE 60 must keep state as CHASING")
	remove_child(enemy)
	enemy.free()

# ---------------------------------------------------------------------------
# AC-2: HitboxArea2D monitoring cycle (timer callbacks called directly)
# ---------------------------------------------------------------------------

func test_companion_ai_attack_cooldown_timeout_enables_hitbox_monitoring() -> void:
	# Arrange: companion is ATTACKING
	_companion._state = CompanionAI.State.ATTACKING
	assert_false(_companion.hitbox_area.monitoring)  # pre-condition: default false
	# Act: simulate timer timeout
	_companion._on_attack_cooldown_timeout()
	# Assert
	assert_true(_companion.hitbox_area.monitoring,
		"attack cooldown timeout must set HitboxArea2D monitoring=true")

func test_companion_ai_attack_active_timeout_disables_hitbox_monitoring() -> void:
	# Arrange: hitbox is active (monitoring=true)
	_companion.hitbox_area.monitoring = true
	# Act: simulate active window expiring
	_companion._on_attack_active_timeout()
	# Assert
	assert_false(_companion.hitbox_area.monitoring,
		"attack active timeout must set HitboxArea2D monitoring=false")

func test_companion_ai_attack_cooldown_timeout_ignored_when_not_attacking() -> void:
	# Arrange: companion is FOLLOWING (not ATTACKING)
	_companion._state = CompanionAI.State.FOLLOWING
	# Act
	_companion._on_attack_cooldown_timeout()
	# Assert: guard must prevent hitbox activation outside ATTACKING
	assert_false(_companion.hitbox_area.monitoring,
		"cooldown timeout must be a no-op when state is not ATTACKING")

# ---------------------------------------------------------------------------
# AC-3: ATTACKING → FOLLOWING when current target becomes invalid
# ---------------------------------------------------------------------------

func test_companion_ai_attacking_invalid_target_transitions_to_following() -> void:
	# Arrange: set up ATTACKING state with an active hitbox
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.add_to_group("enemies")
	add_child(enemy)
	_companion._on_detection_area_body_entered(enemy)
	_companion._state = CompanionAI.State.ATTACKING
	_companion.hitbox_area.monitoring = true
	# Act: free the enemy (makes _current_target invalid)
	remove_child(enemy)
	enemy.free()
	_companion._process_attacking()
	# Assert
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING,
		"ATTACKING with invalid target must transition to FOLLOWING")
	assert_false(_companion.hitbox_area.monitoring,
		"ATTACKING→FOLLOWING must disable hitbox via _stop_attack()")

# ---------------------------------------------------------------------------
# AC-4: health_depleted → DEAD + DetectionArea2D.monitoring = false
# ---------------------------------------------------------------------------

func test_companion_ai_health_depleted_transitions_to_dead() -> void:
	# Arrange: companion is alive
	assert_eq(_companion._state, CompanionAI.State.FOLLOWING)
	# Act: call handler directly (mirrors HealthComponent.health_depleted signal)
	_companion._on_health_depleted()
	# Assert
	assert_eq(_companion._state, CompanionAI.State.DEAD,
		"health_depleted must transition state to DEAD")

func test_companion_ai_health_depleted_disables_detection_area_monitoring() -> void:
	# Arrange: detection_area monitoring is enabled by default
	_companion.detection_area.monitoring = true
	# Act
	_companion._on_health_depleted()
	# Assert
	assert_false(_companion.detection_area.monitoring,
		"health_depleted must set DetectionArea2D monitoring=false")

func test_companion_ai_health_depleted_disables_hitbox_monitoring() -> void:
	# Arrange: hitbox was activated during an attack pulse
	_companion.hitbox_area.monitoring = true
	# Act
	_companion._on_health_depleted()
	# Assert: _stop_attack() must clear the hitbox
	assert_false(_companion.hitbox_area.monitoring,
		"health_depleted must set HitboxArea2D monitoring=false via _stop_attack()")

# ---------------------------------------------------------------------------
# AC-5: DEAD state — physics processing disabled
# ---------------------------------------------------------------------------

func test_companion_ai_health_depleted_disables_physics_processing() -> void:
	# Act
	_companion._on_health_depleted()
	# Assert
	assert_false(_companion.is_physics_processing(),
		"DEAD state must disable physics processing via set_physics_process(false)")
