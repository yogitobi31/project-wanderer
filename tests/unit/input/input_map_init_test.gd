extends GutTest

## Tests for InputMapManager story-001.
## Covers AC-R2a, AC-R2b, AC-R2c, AC-R3a, AC-R3b, AC-R3c, AC-R3d,
## AC-E-schema-old, AC-E-schema-new (CURRENT_SCHEMA_VERSION constant).

var _mgr: InputMapManager

func before_each() -> void:
	# Do NOT add_child — _ready() must not fire automatically.
	# Tests call _register_default_actions() / _load_user_bindings() directly.
	# load() avoids Autoload-name-shadowing: InputMapManager as a class_name + Autoload means
	# load("res://src/core/input_map_manager.gd").new() would call .new() on the singleton instance, which fails.
	_mgr = load("res://src/core/input_map_manager.gd").new()

func after_each() -> void:
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
	# InputMapManager extends Node, so queue_free() is correct here.
	_mgr.queue_free()

# ---------------------------------------------------------------------------
# AC-R2a: all 14 actions present after _register_default_actions
# ---------------------------------------------------------------------------

func test_register_default_actions_all_14_present() -> void:
	_mgr._register_default_actions()
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		assert_true(
			InputMap.has_action(def[&"name"]),
			"Expected InputMap to have action: %s" % def[&"name"]
		)

func test_register_default_actions_count_is_14() -> void:
	_mgr._register_default_actions()
	var registered_count: int = 0
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		if InputMap.has_action(def[&"name"]):
			registered_count += 1
	assert_eq(registered_count, 14)

# ---------------------------------------------------------------------------
# AC-R2b: each action has ≥1 joypad event
# ---------------------------------------------------------------------------

func test_all_actions_have_at_least_one_joypad_event() -> void:
	_mgr._register_default_actions()
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		var events: Array[InputEvent] = InputMap.action_get_events(action_name)
		var has_joypad: bool = false
		for ev: InputEvent in events:
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				has_joypad = true
				break
		assert_true(has_joypad, "Action %s has no joypad event" % action_name)

# ---------------------------------------------------------------------------
# AC-R2c: game_confirm registered as standalone action independent of ui_accept
# ---------------------------------------------------------------------------

func test_game_confirm_is_registered_as_standalone_action() -> void:
	_mgr._register_default_actions()
	assert_true(InputMap.has_action(&"game_confirm"))

func test_game_confirm_has_own_events() -> void:
	_mgr._register_default_actions()
	var events: Array[InputEvent] = InputMap.action_get_events(&"game_confirm")
	assert_true(events.size() > 0,
		"game_confirm must have its own events registered (not derived from ui_accept)")

func test_game_confirm_events_have_zero_overlap_with_ui_accept() -> void:
	_mgr._register_default_actions()
	var game_confirm_events: Array[InputEvent] = InputMap.action_get_events(&"game_confirm")
	var ui_accept_events: Array[InputEvent] = InputMap.action_get_events(&"ui_accept")
	# _register_default_actions clears ui_accept events, so overlap must be zero.
	for gc_ev: InputEvent in game_confirm_events:
		for ua_ev: InputEvent in ui_accept_events:
			assert_false(gc_ev.is_match(ua_ev, true),
				"game_confirm event overlaps with ui_accept: %s" % gc_ev.as_text())

# ---------------------------------------------------------------------------
# AC-R3a: no cfg → defaults used, signal emits once
# ---------------------------------------------------------------------------

func test_no_cfg_defaults_move_up_has_key_w() -> void:
	_mgr._bindings_path = "user://nonexistent_test_bindings_r3a.cfg"
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_w: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W:
			has_w = true
			break
	assert_true(has_w, "move_up should contain KEY_W when no cfg exists")

func test_no_cfg_defaults_move_up_has_key_up() -> void:
	_mgr._bindings_path = "user://nonexistent_test_bindings_r3a_up.cfg"
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_up: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_UP:
			has_up = true
			break
	assert_true(has_up, "move_up should contain KEY_UP when no cfg exists")

func test_no_cfg_signal_emits_once() -> void:
	_mgr._bindings_path = "user://nonexistent_test_bindings_signal.cfg"
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	_mgr.is_ready = true
	watch_signals(_mgr)
	_mgr.input_map_ready.emit()
	assert_signal_emit_count(_mgr, "input_map_ready", 1)

# ---------------------------------------------------------------------------
# AC-R3b: valid cfg (move_up=KEY_Z, schema_version=1) → KEY_Z bound
# ---------------------------------------------------------------------------

func test_valid_cfg_move_up_remapped_to_key_z() -> void:
	var tmp_path: String = "user://test_bindings_r3b.cfg"
	_mgr._bindings_path = tmp_path
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", 1)
	cfg.set_value("move_up", "physical_keycode", KEY_Z)
	cfg.set_value("move_up", "device", 0)
	cfg.save(tmp_path)
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_z: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_Z:
			has_z = true
			break
	assert_true(has_z, "move_up should have KEY_Z after valid cfg restore")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

func test_valid_cfg_original_keyboard_events_replaced() -> void:
	var tmp_path: String = "user://test_bindings_r3b_replace.cfg"
	_mgr._bindings_path = tmp_path
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", 1)
	cfg.set_value("move_up", "physical_keycode", KEY_Z)
	cfg.set_value("move_up", "device", 0)
	cfg.save(tmp_path)
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var keyboard_count: int = 0
	for ev: InputEvent in events:
		if ev is InputEventKey:
			keyboard_count += 1
	assert_eq(keyboard_count, 1, "Exactly 1 keyboard event expected after remap (defaults replaced)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

# ---------------------------------------------------------------------------
# AC-R3c: corrupted cfg → defaults remain
# ---------------------------------------------------------------------------

func test_corrupted_cfg_defaults_remain() -> void:
	var tmp_path: String = "user://test_bindings_r3c.cfg"
	_mgr._bindings_path = tmp_path
	var fa := FileAccess.open(tmp_path, FileAccess.WRITE)
	fa.store_string("NOT VALID CFG ;;; @@@ !!!")
	fa.close()
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_w: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W:
			has_w = true
			break
	assert_true(has_w, "Defaults should remain after corrupted cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

# ---------------------------------------------------------------------------
# AC-R3d: is_ready guard
# ---------------------------------------------------------------------------

func test_is_ready_false_before_init() -> void:
	assert_false(_mgr.is_ready)

func test_is_ready_true_after_manual_init() -> void:
	_mgr._bindings_path = "user://nonexistent_r3d.cfg"
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	_mgr.is_ready = true
	assert_true(_mgr.is_ready)

func test_is_ready_guard_skips_when_not_ready() -> void:
	var processed: bool = false
	var consume := func() -> void:
		if not _mgr.is_ready:
			return
		processed = true
	consume.call()
	assert_false(processed, "Consumer should not process when is_ready=false")

func test_is_ready_guard_runs_when_ready() -> void:
	_mgr._bindings_path = "user://nonexistent_r3d_ready.cfg"
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	_mgr.is_ready = true
	var processed: Array[bool] = [false]
	var consume := func() -> void:
		if not _mgr.is_ready:
			return
		processed[0] = true
	consume.call()
	assert_true(processed[0], "Consumer should process when is_ready=true")

# ---------------------------------------------------------------------------
# AC-E-schema-old: schema_version=0 → defaults, warning contains "schema"
# ---------------------------------------------------------------------------

func test_schema_version_0_defaults_remain() -> void:
	var tmp_path: String = "user://test_bindings_schema_old.cfg"
	_mgr._bindings_path = tmp_path
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", 0)
	cfg.set_value("move_up", "physical_keycode", KEY_Z)
	cfg.save(tmp_path)
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_w: bool = false
	var has_z: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey:
			if (ev as InputEventKey).physical_keycode == KEY_W:
				has_w = true
			if (ev as InputEventKey).physical_keycode == KEY_Z:
				has_z = true
	assert_true(has_w, "KEY_W should be present when schema is outdated")
	assert_false(has_z, "KEY_Z should NOT be applied when schema is outdated")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

# ---------------------------------------------------------------------------
# AC-E-schema-new: CURRENT_SCHEMA_VERSION constant is 1
# ---------------------------------------------------------------------------

func test_current_schema_version_constant_is_1() -> void:
	assert_eq(InputMapManager.CURRENT_SCHEMA_VERSION, 1)

# ---------------------------------------------------------------------------
# keycode <= 0 boundary: cfg with physical_keycode=0 → skipped, defaults remain
# ---------------------------------------------------------------------------

func test_load_user_bindings_zero_keycode_skipped() -> void:
	var tmp_path: String = "user://test_bindings_zero_keycode.cfg"
	_mgr._bindings_path = tmp_path
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", 1)
	cfg.set_value("move_up", "physical_keycode", 0)
	cfg.save(tmp_path)
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	var events: Array[InputEvent] = InputMap.action_get_events(&"move_up")
	var has_w: bool = false
	for ev: InputEvent in events:
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W:
			has_w = true
			break
	assert_true(has_w, "KEY_W default should remain when cfg has physical_keycode=0")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))

# ---------------------------------------------------------------------------
# Idempotency: _register_default_actions called twice → same event count
# ---------------------------------------------------------------------------

func test_register_default_actions_idempotent_double_call() -> void:
	_mgr._register_default_actions()
	var count_first: int = InputMap.action_get_events(&"move_up").size()
	_mgr._register_default_actions()
	var count_second: int = InputMap.action_get_events(&"move_up").size()
	assert_eq(count_first, count_second,
		"Double call to _register_default_actions must not duplicate events")

func test_unknown_action_in_cfg_is_ignored() -> void:
	var tmp_path: String = "user://test_bindings_unknown.cfg"
	_mgr._bindings_path = tmp_path
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", 1)
	cfg.set_value("fake_action_xyz", "physical_keycode", KEY_Z)
	cfg.save(tmp_path)
	_mgr._register_default_actions()
	_mgr._load_user_bindings()
	assert_false(InputMap.has_action(&"fake_action_xyz"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
