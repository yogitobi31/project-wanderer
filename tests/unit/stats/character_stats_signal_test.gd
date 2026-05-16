extends GutTest

# ---------------------------------------------------------------------------
# AC-1: stats_changed emits exactly once with correct stat_name
# ---------------------------------------------------------------------------

func test_stats_changed_emits_once_with_atk_name_on_base_atk_write() -> void:
	var s := CharacterStats.new()
	watch_signals(s)
	s.base_atk = 25
	assert_signal_emit_count(s, "stats_changed", 1, "stats_changed must fire exactly once")
	assert_signal_emitted_with_parameters(s, "stats_changed", [&"atk"])

func test_stats_changed_emits_once_with_max_hp_name_on_base_max_hp_write() -> void:
	var s := CharacterStats.new()
	watch_signals(s)
	s.base_max_hp = 100
	assert_signal_emitted_with_parameters(s, "stats_changed", [&"max_hp"])

func test_stats_changed_emits_once_with_def_name_on_base_def_write() -> void:
	var s := CharacterStats.new()
	watch_signals(s)
	s.base_def = 15
	assert_signal_emitted_with_parameters(s, "stats_changed", [&"def"])

func test_stats_changed_emits_once_with_spd_name_on_base_spd_write() -> void:
	var s := CharacterStats.new()
	watch_signals(s)
	s.base_spd = 200.0
	assert_signal_emitted_with_parameters(s, "stats_changed", [&"spd"])

func test_stats_changed_does_not_emit_when_same_value_written() -> void:
	# Value-changed guard: no-op writes must not fire the signal.
	var s := CharacterStats.new()
	s.base_atk = 20  # already the default
	watch_signals(s)
	s.base_atk = 20
	assert_signal_not_emitted(s, "stats_changed", "no emission expected for same-value write")

# ---------------------------------------------------------------------------
# AC-2: duplicate() produces independent instances
# ---------------------------------------------------------------------------

func test_duplicate_instances_are_independent_for_base_atk() -> void:
	var template := CharacterStats.new()
	template.base_atk = 20
	var a: CharacterStats = template.duplicate()
	var b: CharacterStats = template.duplicate()
	a.base_atk = 99
	assert_eq(b.base_atk, 20, "b.base_atk must not be affected by a.base_atk change")
	assert_eq(template.base_atk, 20, "template source must be unaffected")

func test_duplicate_instances_are_independent_for_base_max_hp() -> void:
	var template := CharacterStats.new()
	template.base_max_hp = 80
	var a: CharacterStats = template.duplicate()
	var b: CharacterStats = template.duplicate()
	a.base_max_hp = 500
	assert_eq(b.base_max_hp, 80)

func test_duplicate_computed_values_are_independent() -> void:
	var template := CharacterStats.new()
	var a: CharacterStats = template.duplicate()
	var b: CharacterStats = template.duplicate()
	a.base_atk = 50
	assert_eq(a.atk, 50)
	assert_eq(b.atk, 20, "b.atk must remain at template default")

# ---------------------------------------------------------------------------
# AC-3: stats_changed handler writing base_* does not cause infinite loop
# ---------------------------------------------------------------------------

func test_handler_writing_base_atk_does_not_loop() -> void:
	# Handler always writes base_atk = 30. Value-changed guard stops re-emission
	# after the first handler execution (base_atk is already 30 on re-entry).
	var s := CharacterStats.new()
	var call_count: Array[int] = [0]
	s.stats_changed.connect(func(stat_name: StringName) -> void:
		call_count[0] += 1
		if stat_name == &"atk":
			s.base_atk = 30  # same value on second call → no re-emission
	)
	s.base_atk = 25  # triggers handler: call_count=1, handler sets base_atk=30
	# Handler fires again: call_count=2, handler sets base_atk=30 (same) → guard stops it
	assert_eq(call_count[0], 2, "expected exactly 2 emissions: initial write + handler write; guard stops chain")
	assert_eq(s.base_atk, 30, "final value must be 30 as set by handler")

func test_handler_writing_same_value_does_not_emit_again() -> void:
	var s := CharacterStats.new()
	s.base_atk = 20
	var count: Array[int] = [0]
	s.stats_changed.connect(func(stat_name: StringName) -> void:
		count[0] += 1
		s.base_atk = 25  # same as the just-set value → value-changed guard stops re-emission
	)
	s.base_atk = 25  # first real change: 20→25 → handler fires once, writes 25 (same) → stops
	assert_eq(count[0], 1, "handler sets same value — no second emission")

# ---------------------------------------------------------------------------
# AC-4: GrowthRate resource has correct fields with zero defaults
# ---------------------------------------------------------------------------

func test_growth_rate_can_be_instantiated() -> void:
	var gr := GrowthRate.new()
	assert_not_null(gr)

func test_growth_rate_hp_growth_default_is_zero() -> void:
	var gr := GrowthRate.new()
	assert_eq(gr.hp_growth, 0)

func test_growth_rate_atk_growth_default_is_zero() -> void:
	var gr := GrowthRate.new()
	assert_eq(gr.atk_growth, 0)

func test_growth_rate_def_growth_default_is_zero() -> void:
	var gr := GrowthRate.new()
	assert_eq(gr.def_growth, 0)

func test_growth_rate_spd_growth_default_is_zero() -> void:
	var gr := GrowthRate.new()
	assert_eq(gr.spd_growth, 0.0)
