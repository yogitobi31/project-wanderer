extends GutTest

## Unit tests for CharacterStats resource.
##
## Covers all Acceptance Criteria from design/gdd/능력치-시스템.md:
##   Core Rules : AC-STAT-CR-01 through AC-STAT-CR-05
##   Formulas   : AC-STAT-FM-01 through AC-STAT-FM-06
##   Edge Cases : AC-STAT-EC-01 through AC-STAT-EC-03
##   Cross-sys  : AC-STAT-XS-01

var _stats: CharacterStats

func before_each() -> void:
	_stats = CharacterStats.new()
	# Set a neutral baseline for all tests that need it.
	# Use direct property assignment to avoid signal noise from setup.
	_stats.base_max_hp = 80
	_stats.base_atk = 20
	_stats.base_def = 8
	_stats.base_spd = 130.0

func after_each() -> void:
	pass  # CharacterStats is RefCounted — freed automatically

# ---------------------------------------------------------------------------
# AC-1 (story-001) — factory defaults without any before_each override
# ---------------------------------------------------------------------------

func test_new_instance_default_max_hp_is_80() -> void:
	var s := CharacterStats.new()
	assert_eq(s.max_hp, 80, "default max_hp must be 80 per ADR-0005")

func test_new_instance_default_atk_is_20() -> void:
	var s := CharacterStats.new()
	assert_eq(s.atk, 20, "default atk must be 20 per ADR-0005")

func test_new_instance_default_def_is_8() -> void:
	var s := CharacterStats.new()
	assert_eq(s.def, 8, "default def must be 8 per ADR-0005")

func test_new_instance_default_spd_is_130() -> void:
	var s := CharacterStats.new()
	assert_eq(s.spd, 130.0, "default spd must be 130.0 per ADR-0005")

# ---------------------------------------------------------------------------
# AC-STAT-CR-01 — shared CharacterStats type (structural check)
# ---------------------------------------------------------------------------

func test_character_stats_is_resource() -> void:
	# All characters use the same CharacterStats class — no subclasses per role.
	assert_true(_stats is CharacterStats)

func test_character_stats_extends_resource() -> void:
	assert_true(_stats is Resource)

# ---------------------------------------------------------------------------
# AC-STAT-CR-02 — MVP stat properties exist
# ---------------------------------------------------------------------------

func test_base_max_hp_property_exists() -> void:
	assert_true("base_max_hp" in _stats)

func test_base_atk_property_exists() -> void:
	assert_true("base_atk" in _stats)

func test_base_def_property_exists() -> void:
	assert_true("base_def" in _stats)

func test_base_spd_property_exists() -> void:
	assert_true("base_spd" in _stats)

func test_mod_max_hp_property_exists() -> void:
	assert_true("mod_max_hp" in _stats)

func test_mod_atk_property_exists() -> void:
	assert_true("mod_atk" in _stats)

func test_mod_def_property_exists() -> void:
	assert_true("mod_def" in _stats)

func test_mod_spd_property_exists() -> void:
	assert_true("mod_spd" in _stats)

# ---------------------------------------------------------------------------
# AC-STAT-CR-03 — computed property returns base + mod
# ---------------------------------------------------------------------------

func test_atk_computed_returns_base_plus_mod() -> void:
	# Arrange
	_stats.base_atk = 20
	_stats.mod_atk = 5
	# Act / Assert
	assert_eq(_stats.atk, 25)

func test_def_computed_returns_base_plus_positive_mod() -> void:
	_stats.base_def = 10
	_stats.mod_def = 3
	assert_eq(_stats.def, 13)

func test_max_hp_computed_returns_base_plus_mod() -> void:
	_stats.base_max_hp = 80
	_stats.mod_max_hp = 20
	assert_eq(_stats.max_hp, 100)

func test_spd_computed_returns_base_plus_mod() -> void:
	_stats.base_spd = 130.0
	_stats.mod_spd = 20.0
	assert_eq(_stats.spd, 150.0)

# ---------------------------------------------------------------------------
# AC-STAT-CR-04 — stats_changed signal fires on base_* write
# ---------------------------------------------------------------------------

func test_stats_changed_emits_on_base_atk_write() -> void:
	# Arrange / Act
	watch_signals(_stats)
	_stats.base_atk = 25
	# Assert
	assert_signal_emitted_with_parameters(_stats, "stats_changed", [&"atk"])

func test_stats_changed_emits_on_base_max_hp_write() -> void:
	watch_signals(_stats)
	_stats.base_max_hp = 100
	assert_signal_emitted_with_parameters(_stats, "stats_changed", [&"max_hp"])

func test_stats_changed_emits_on_base_def_write() -> void:
	watch_signals(_stats)
	_stats.base_def = 15
	assert_signal_emitted_with_parameters(_stats, "stats_changed", [&"def"])

func test_stats_changed_emits_on_base_spd_write() -> void:
	watch_signals(_stats)
	_stats.base_spd = 200.0
	assert_signal_emitted_with_parameters(_stats, "stats_changed", [&"spd"])

func test_stats_changed_emits_exactly_once_per_base_write() -> void:
	watch_signals(_stats)
	_stats.base_atk = 25
	assert_signal_emit_count(_stats, "stats_changed", 1)

# ---------------------------------------------------------------------------
# AC-STAT-CR-05 — duplicate() produces independent instances
# ---------------------------------------------------------------------------

func test_duplicate_base_atk_change_does_not_affect_original() -> void:
	# Arrange
	var template: CharacterStats = CharacterStats.new()
	template.base_atk = 20
	var instance_a: CharacterStats = template.duplicate()
	var instance_b: CharacterStats = template.duplicate()
	# Act
	instance_a.base_atk = 99
	# Assert
	assert_eq(instance_b.base_atk, 20,
		"instance_b.base_atk should remain at template value")

# ---------------------------------------------------------------------------
# AC-STAT-FM-01 — positive modifier adds correctly
# ---------------------------------------------------------------------------

func test_def_base5_mod3_returns_8() -> void:
	_stats.base_def = 5
	_stats.mod_def = 3
	assert_eq(_stats.def, 8)

# ---------------------------------------------------------------------------
# AC-STAT-FM-02 — negative modifier clamps def to 0
# ---------------------------------------------------------------------------

func test_def_base5_mod_neg8_clamps_to_0() -> void:
	_stats.base_def = 5
	_stats.mod_def = -8
	assert_eq(_stats.def, 0,
		"effective_def must not go below 0 (not return -3)")

# ---------------------------------------------------------------------------
# AC-STAT-FM-03 — spd clamp lower bound; base_spd unchanged
# ---------------------------------------------------------------------------

func test_spd_clamps_to_min_when_modifier_pushes_below() -> void:
	_stats.base_spd = 20.0
	_stats.mod_spd = -15.0
	assert_eq(_stats.spd, CharacterStats.SPD_MIN)

func test_spd_clamp_does_not_mutate_base_spd() -> void:
	_stats.base_spd = 20.0
	_stats.mod_spd = -15.0
	var _ignored: float = _stats.spd  # trigger computed getter
	assert_eq(_stats.base_spd, 20.0,
		"base_spd must remain 20.0 after computed clamping")

# ---------------------------------------------------------------------------
# AC-STAT-FM-04 — max_hp clamps to upper bound (9999)
# ---------------------------------------------------------------------------

func test_max_hp_clamps_to_9999_when_sum_exceeds_upper() -> void:
	_stats.base_max_hp = 9990
	_stats.mod_max_hp = 20
	assert_eq(_stats.max_hp, 9999)

func test_max_hp_base9999_mod1_clamps_to_9999() -> void:
	# Exact spec boundary: 9999 + 1 = 10000, must return 9999
	_stats.base_max_hp = 9999
	_stats.mod_max_hp = 1
	assert_eq(_stats.max_hp, 9999)

# ---------------------------------------------------------------------------
# AC-STAT-FM-05 — max_hp clamps to lower bound (1)
# ---------------------------------------------------------------------------

func test_max_hp_clamps_to_1_when_sum_below_lower() -> void:
	_stats.base_max_hp = 1
	_stats.mod_max_hp = -5
	assert_eq(_stats.max_hp, 1)

# ---------------------------------------------------------------------------
# AC-STAT-FM-06 — player default values (mod_* = 0)
# ---------------------------------------------------------------------------

func test_player_defaults_max_hp_equals_80() -> void:
	# before_each sets base_max_hp=80, all mod_*=0
	assert_eq(_stats.max_hp, 80)

func test_player_defaults_atk_equals_20() -> void:
	assert_eq(_stats.atk, 20)

func test_player_defaults_def_equals_8() -> void:
	assert_eq(_stats.def, 8)

func test_player_defaults_spd_equals_130() -> void:
	assert_eq(_stats.spd, 130.0)

# ---------------------------------------------------------------------------
# AC-STAT-EC-01 — spd debuff: computed clamps, base_spd unchanged
# ---------------------------------------------------------------------------

func test_spd_debuff_result_is_10_when_base15_mod_neg20() -> void:
	_stats.base_spd = 15.0
	_stats.mod_spd = -20.0
	assert_eq(_stats.spd, 10.0)

func test_spd_debuff_base_spd_unchanged_at_15() -> void:
	_stats.base_spd = 15.0
	_stats.mod_spd = -20.0
	var _ignored: float = _stats.spd
	assert_eq(_stats.base_spd, 15.0)

# ---------------------------------------------------------------------------
# AC-STAT-EC-02 — level-up: base_max_hp cannot exceed 9999 via setter clamp
# ---------------------------------------------------------------------------

func test_base_max_hp_setter_clamps_at_9999() -> void:
	# Simulates level-up system writing base_max_hp = 9995 + 10 = 10005
	_stats.base_max_hp = 10005
	assert_eq(_stats.base_max_hp, 9999,
		"base_max_hp must be stored as 9999, not 10005")

func test_base_max_hp_9995_plus_growth10_stored_as_9999() -> void:
	_stats.base_max_hp = 9995
	_stats.base_max_hp = _stats.base_max_hp + 10
	assert_eq(_stats.base_max_hp, 9999)

# ---------------------------------------------------------------------------
# AC-STAT-EC-03 — duplicate() independence for mod values
# ---------------------------------------------------------------------------

func test_duplicate_mod_atk_change_does_not_affect_sibling() -> void:
	# Arrange
	var template: CharacterStats = CharacterStats.new()
	template.base_atk = 20
	var instance_a: CharacterStats = template.duplicate()
	var instance_b: CharacterStats = template.duplicate()
	# Act — mod_atk write will emit push_warning (expected during this test)
	instance_a.mod_atk = 50
	# Assert
	assert_eq(instance_b.mod_atk, 0)
	assert_eq(instance_b.atk, 20,
		"instance_b.atk should equal its base_atk, not be affected by instance_a's mod")

# ---------------------------------------------------------------------------
# AC-STAT-XS-01 — stats_changed receives correct names, correct count
# ---------------------------------------------------------------------------

func test_stats_changed_fires_twice_with_correct_names_in_order() -> void:
	# Arrange
	var received: Array[StringName] = []
	_stats.stats_changed.connect(func(stat_name: StringName) -> void:
		received.append(stat_name)
	)
	# Act
	_stats.base_max_hp = 100
	_stats.base_atk = 25
	# Assert
	assert_eq(received.size(), 2,
		"stats_changed must fire exactly twice")
	assert_eq(received[0], &"max_hp")
	assert_eq(received[1], &"atk")

func test_stats_changed_counter_is_two_after_two_writes() -> void:
	watch_signals(_stats)
	_stats.base_max_hp = 100
	_stats.base_atk = 25
	assert_signal_emit_count(_stats, "stats_changed", 2)

# ---------------------------------------------------------------------------
# Boundary: atk cannot go below 0 via base setter
# ---------------------------------------------------------------------------

func test_base_atk_setter_clamps_to_0_when_negative_assigned() -> void:
	_stats.base_atk = -5
	assert_eq(_stats.base_atk, 0)

# ---------------------------------------------------------------------------
# Boundary: spd upper clamp via base setter
# ---------------------------------------------------------------------------

func test_base_spd_setter_clamps_to_600_when_over_max() -> void:
	_stats.base_spd = 9999.0
	assert_eq(_stats.base_spd, CharacterStats.SPD_MAX)

# AC-4 (story-001) — setter lower clamp: base_spd=5.0 is stored as 10.0
func test_base_spd_setter_clamps_to_10_when_below_min() -> void:
	# Spec scenario: base_spd = 5.0 → spd == 10.0
	# This exercises the setter clamp path, not the getter clamp path.
	_stats.base_spd = 5.0
	assert_eq(_stats.base_spd, 10.0, "setter must store SPD_MIN, not 5.0")
	assert_eq(_stats.spd, 10.0)

# ---------------------------------------------------------------------------
# Boundary: atk upper clamp via computed getter
# ---------------------------------------------------------------------------

func test_atk_computed_clamps_to_999_when_sum_exceeds_max() -> void:
	_stats.base_atk = 999
	_stats.mod_atk = 5
	assert_eq(_stats.atk, 999)
