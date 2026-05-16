extends GutTest

var _stats: CharacterStats
var _health: HealthComponent

func before_each() -> void:
	_stats = CharacterStats.new()
	_stats.base_max_hp = 80
	_stats.base_def = 8
	_stats.base_atk = 20
	_health = HealthComponent.new()
	_health.stats = _stats
	add_child(_health)  # triggers _ready() → current_health = stats.max_hp

func after_each() -> void:
	remove_child(_health)
	_health.free()
	# _stats is RefCounted, freed automatically

# ---------------------------------------------------------------------------
# AC-1: damage formula — attack 25, def 8 → final_damage 17
# ---------------------------------------------------------------------------

func test_damage_formula_attack25_def8_reduces_health_by_17() -> void:
	var initial: int = _health.current_health  # 80
	_health.hit_confirmed({"damage": 25, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, initial - 17,
		"final_damage = max(1, 25 - 8) = 17; health must drop by 17")

# ---------------------------------------------------------------------------
# AC-2: damage formula min 1 — defense exceeds attack
# ---------------------------------------------------------------------------

func test_damage_formula_min1_when_defense_exceeds_attack() -> void:
	_stats.base_def = 10
	var initial: int = _health.current_health
	_health.hit_confirmed({"damage": 5, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, initial - 1,
		"final_damage = max(1, 5 - 10) = 1; minimum 1 damage always guaranteed")

func test_damage_formula_min1_when_defense_equals_attack() -> void:
	_stats.base_def = 20
	var initial: int = _health.current_health
	_health.hit_confirmed({"damage": 20, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, initial - 1)

func test_damage_formula_min1_when_attack_is_zero() -> void:
	var initial: int = _health.current_health
	_health.hit_confirmed({"damage": 0, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, initial - 1)

# ---------------------------------------------------------------------------
# AC-3: health_depleted emits exactly once when health reaches zero
# ---------------------------------------------------------------------------

func test_health_depleted_emits_once_on_lethal_hit() -> void:
	_stats.base_def = 0
	watch_signals(_health)
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	assert_signal_emit_count(_health, "health_depleted", 1, "health_depleted must fire exactly once")
	assert_eq(_health.current_health, 0)

func test_health_depleted_not_emitted_on_non_lethal_hit() -> void:
	watch_signals(_health)
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	assert_signal_not_emitted(_health, "health_depleted")

func test_current_health_does_not_go_below_zero() -> void:
	_stats.base_def = 0
	_health.hit_confirmed({"damage": 9999, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 0)

# ---------------------------------------------------------------------------
# AC-4: health_changed emits with correct (current, maximum) on every hit/heal
# ---------------------------------------------------------------------------

func test_health_changed_emits_correct_current_and_max_on_damage() -> void:
	watch_signals(_health)
	_health.hit_confirmed({"damage": 25, "knockback": 0.0, "source": null})
	assert_signal_emitted_with_parameters(_health, "health_changed", [63, 80])

func test_health_changed_emits_on_every_hit() -> void:
	watch_signals(_health)
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	assert_signal_emit_count(_health, "health_changed", 2)

func test_health_changed_emits_on_heal() -> void:
	_health.hit_confirmed({"damage": 20, "knockback": 0.0, "source": null})
	# hit 20 dmg, def 8 → final 12 → hp 68; heal 10 → 78
	watch_signals(_health)
	_health.heal(10)
	assert_signal_emitted_with_parameters(_health, "health_changed", [78, 80])

# ---------------------------------------------------------------------------
# AC-5: heal does not exceed stats.max_hp
# ---------------------------------------------------------------------------

func test_heal_caps_at_max_hp() -> void:
	_stats.base_def = 0
	_health.hit_confirmed({"damage": 75, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 5)
	_health.heal(100)
	assert_eq(_health.current_health, 80, "heal must not exceed stats.max_hp")

func test_heal_partial_amount_works_correctly() -> void:
	_health.hit_confirmed({"damage": 20, "knockback": 0.0, "source": null})
	# After 20 dmg with def 8: final = max(1, 20-8) = 12; current = 80-12 = 68
	assert_eq(_health.current_health, 68)
	_health.heal(5)
	assert_eq(_health.current_health, 73)

# ---------------------------------------------------------------------------
# AC-6: hit_confirmed ignored after health_depleted
# ---------------------------------------------------------------------------

func test_hit_confirmed_ignored_after_death() -> void:
	_stats.base_def = 0
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 0)
	_health.hit_confirmed({"damage": 10, "knockback": 0.0, "source": null})
	assert_eq(_health.current_health, 0, "dead character must not take further damage")

func test_health_depleted_does_not_emit_twice_on_second_hit() -> void:
	_stats.base_def = 0
	watch_signals(_health)
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	assert_signal_emit_count(_health, "health_depleted", 1, "health_depleted must not fire again after death")

func test_heal_ignored_after_death() -> void:
	_stats.base_def = 0
	_health.hit_confirmed({"damage": 80, "knockback": 0.0, "source": null})
	_health.heal(50)
	assert_eq(_health.current_health, 0, "heal must be ignored when dead")
