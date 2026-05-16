extends GutTest
## Tests for HealthComponent story-002: Iframes timer + HurtboxArea2D integration.
##
## AC-1: hurtbox.monitoring == false immediately after hit_confirmed
## AC-2: hurtbox.monitoring == true after IFRAMES_DURATION expires
## AC-4: hurtbox.monitoring stays false permanently after health_depleted
##
## Timer strategy: _iframe_timer will not fire in a headless test environment without
## running process frames. Tests that verify timer expiry call _health._on_iframes_expired()
## directly to simulate the callback synchronously and deterministically.

var _stats: CharacterStats
var _health: HealthComponent
var _hurtbox: Area2D

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_max_hp = 80
	_stats.base_def = 0
	_stats.base_atk = 20
	_hurtbox = Area2D.new()
	_health = HealthComponent.new()
	_health.stats = _stats
	_health.hurtbox = _hurtbox
	add_child(_health)
	add_child(_hurtbox)

func after_each() -> void:
	remove_child(_health)
	remove_child(_hurtbox)
	_health.free()
	_hurtbox.free()
	# _stats is RefCounted, freed automatically

# ---------------------------------------------------------------------------
# AC-1: hurtbox.monitoring is true before any hit (baseline)
# ---------------------------------------------------------------------------

func test_hurtbox_monitoring_is_true_before_first_hit() -> void:
	# Arrange: fresh component, hurtbox assigned but no hits taken
	# Act: (none)
	# Assert
	assert_true(_hurtbox.monitoring,
		"hurtbox.monitoring must be true before any hit is received")

# ---------------------------------------------------------------------------
# AC-1: hit_confirmed disables hurtbox.monitoring immediately
# ---------------------------------------------------------------------------

func test_hit_confirmed_sets_hurtbox_monitoring_false_immediately() -> void:
	# Arrange
	assert_true(_hurtbox.monitoring)
	# Act
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	# Assert
	assert_false(_hurtbox.monitoring,
		"hurtbox.monitoring must be false immediately after hit_confirmed")

# ---------------------------------------------------------------------------
# AC-2: hurtbox.monitoring stays false before iframes expire
# ---------------------------------------------------------------------------

func test_hurtbox_monitoring_stays_false_before_iframes_expire() -> void:
	# Arrange
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	# Act: timer has NOT fired — do not call _on_iframes_expired
	# Assert
	assert_false(_hurtbox.monitoring,
		"hurtbox.monitoring must remain false until the iframes timer expires")

# ---------------------------------------------------------------------------
# AC-2: hurtbox.monitoring is restored to true after iframes expire
# ---------------------------------------------------------------------------

func test_hurtbox_monitoring_restored_true_after_iframes_expire() -> void:
	# Arrange
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	assert_false(_hurtbox.monitoring)
	# Act: simulate timer expiry synchronously
	_health._on_iframes_expired()
	# Assert
	assert_true(_hurtbox.monitoring,
		"hurtbox.monitoring must be restored to true after the iframes window expires")

# ---------------------------------------------------------------------------
# AC-4: lethal hit stops the iframes timer
# ---------------------------------------------------------------------------

func test_lethal_hit_stops_iframe_timer() -> void:
	# Arrange: lethal damage (80 hp, 0 def, 80 damage)
	# Act
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	# Assert: timer stopped AND monitoring stays false
	assert_true(_health._iframe_timer.is_stopped(),
		"iframes timer must be stopped when health_depleted is emitted")
	assert_false(_hurtbox.monitoring,
		"hurtbox.monitoring must remain false after a lethal hit")

# ---------------------------------------------------------------------------
# AC-4: iframes expiry does NOT restore monitoring after lethal hit
# ---------------------------------------------------------------------------

func test_iframes_expiry_does_not_restore_monitoring_after_death() -> void:
	# Arrange
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 0)
	assert_false(_hurtbox.monitoring)
	# Act: simulate the timer callback firing after death
	_health._on_iframes_expired()
	# Assert: guard inside _on_iframes_expired checks current_health > 0, so no restore
	assert_false(_hurtbox.monitoring,
		"hurtbox.monitoring must not be restored when the character is dead")

# ---------------------------------------------------------------------------
# AC-4: hurtbox.monitoring stays false permanently after death
# ---------------------------------------------------------------------------

func test_hurtbox_monitoring_stays_false_permanently_after_death() -> void:
	# Arrange: kill the character
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 0)
	# Act: subsequent hit_confirmed calls are silently ignored (dead guard),
	# and further simulated timer expirations must not flip monitoring back
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	_health._on_iframes_expired()
	# Assert
	assert_false(_hurtbox.monitoring,
		"hurtbox.monitoring must remain false permanently after health_depleted")
