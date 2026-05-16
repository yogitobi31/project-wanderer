extends GutTest

## Unit tests for InputMapManager rebind API (story-002).
##
## Coverage:
##   AC-R4a  request_rebind: unknown action → UNKNOWN_ACTION
##   AC-R4b  request_rebind: invalid event type → INVALID_EVENT_TYPE
##   AC-R4c  request_rebind: reserved key → RESERVED_KEY
##   AC-R4d  request_rebind: duplicate binding → DUPLICATE_BINDING
##   AC-R4e  request_rebind: success → SUCCESS + InputMap updated + cfg saved + signal
##   AC-R5a  force_swap: moves event from conflict_action to target_action
##   AC-R5b  remove_binding: last keyboard binding → LAST_BINDING_BLOCKED
##   AC-R6a  cfg stores physical_keycode immediately after rebind
##   AC-R6b  reset_to_defaults: deletes cfg file, restores defaults, emits signal
##   AC-R6c  cfg stores physical_keycode, NOT logical keycode (AZERTY simulation)
##   AC-F4a  _find_duplicate detects modifier combos as duplicates
##   AC-F4b  _find_duplicate: different modifier → not a duplicate
##   AC-F4c  _find_duplicate: different event type → not a duplicate
##   AC-E-focus-loss  cancel_rebind during AWAITING_INPUT returns to ACTIVE
##   AC-E-save-fail   SAVE_FAILED still applies binding to InputMap in memory

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _mgr: InputMapManager

## Creates an InputEventKey with the given physical_keycode and optional modifiers.
func _make_key(keycode: int, ctrl: bool = false, shift: bool = false, alt: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.alt_pressed = alt
	return ev

## Creates an InputEventJoypadButton with the given button_index.
func _make_joy_btn(button: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev

## Returns physical_keycode of first InputEventKey on action, or -1.
func _first_key(action: StringName) -> int:
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return (ev as InputEventKey).physical_keycode
	return -1

## Returns true if the action has any InputEventKey with the given physical_keycode.
func _has_key(action: StringName, keycode: int) -> bool:
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			return true
	return false

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: InputMapManager as a class_name + Autoload means
	# InputMapManager.new() would call .new() on the singleton instance, which fails.
	_mgr = load("res://src/core/input_map_manager.gd").new()
	# Redirect file I/O so tests never touch the real user:// directory.
	_mgr._bindings_path = "user://test_rebind_tmp.cfg"
	add_child(_mgr)
	# _ready() runs synchronously when added to tree; wait one frame for
	# focus_exited to wire up.
	await get_tree().process_frame

func after_each() -> void:
	# Erase all 14 actions from the global InputMap before freeing the manager.
	# This mirrors input_map_init_test.gd and prevents state leaking between runs.
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
	_mgr.queue_free()
	# Remove temp file if it was created.
	if FileAccess.file_exists("user://test_rebind_tmp.cfg"):
		DirAccess.remove_absolute("user://test_rebind_tmp.cfg")

# ---------------------------------------------------------------------------
# AC-R4a — request_rebind: unknown action
# ---------------------------------------------------------------------------

func test_request_rebind_unknown_action_returns_unknown_action() -> void:
	var ev := _make_key(KEY_G)
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"fly_up", ev)
	assert_eq(result, InputMapManager.RebindResult.UNKNOWN_ACTION)

func test_request_rebind_unknown_action_does_not_emit_signal() -> void:
	watch_signals(_mgr)
	_mgr.request_rebind(&"not_a_real_action", _make_key(KEY_G))
	assert_signal_not_emitted(_mgr, "bindings_changed")

# ---------------------------------------------------------------------------
# AC-R4b — request_rebind: invalid event type
# ---------------------------------------------------------------------------

func test_request_rebind_invalid_event_type_returns_invalid() -> void:
	var ev := InputEventMIDI.new()
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"move_up", ev)
	assert_eq(result, InputMapManager.RebindResult.INVALID_EVENT_TYPE)

func test_request_rebind_invalid_event_type_does_not_change_binding() -> void:
	var before: int = _first_key(&"move_up")
	_mgr.request_rebind(&"move_up", InputEventMIDI.new())
	assert_eq(_first_key(&"move_up"), before)

# ---------------------------------------------------------------------------
# AC-R4c — request_rebind: reserved key
# ---------------------------------------------------------------------------

func test_request_rebind_reserved_key_returns_reserved_key() -> void:
	var ev := _make_key(KEY_F1)
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"move_up", ev)
	assert_eq(result, InputMapManager.RebindResult.RESERVED_KEY)

func test_request_rebind_reserved_key_does_not_change_binding() -> void:
	var before: int = _first_key(&"move_up")
	_mgr.request_rebind(&"move_up", _make_key(KEY_F5))
	assert_eq(_first_key(&"move_up"), before)

# ---------------------------------------------------------------------------
# AC-R4d — request_rebind: duplicate binding
# ---------------------------------------------------------------------------

# combat_attack has KEY_J by default; trying to bind interact to KEY_J → DUPLICATE
func test_request_rebind_duplicate_returns_duplicate_binding() -> void:
	var ev := _make_key(KEY_J)
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"interact", ev)
	assert_eq(result, InputMapManager.RebindResult.DUPLICATE_BINDING)

func test_request_rebind_duplicate_does_not_change_binding() -> void:
	var before: int = _first_key(&"interact")
	_mgr.request_rebind(&"interact", _make_key(KEY_J))
	assert_eq(_first_key(&"interact"), before)

func test_request_rebind_same_action_same_key_is_not_conflict() -> void:
	# Re-binding an action to its own current key is not a duplicate.
	var current: int = _first_key(&"move_up")  # KEY_W
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"move_up", _make_key(current))
	assert_eq(result, InputMapManager.RebindResult.SUCCESS,
			"Re-binding to own key should return SUCCESS (no self-conflict)")

# ---------------------------------------------------------------------------
# AC-R4e — request_rebind: success
# ---------------------------------------------------------------------------

func test_request_rebind_success_returns_success() -> void:
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"interact", _make_key(KEY_E))
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

func test_request_rebind_success_updates_inputmap() -> void:
	_mgr.request_rebind(&"interact", _make_key(KEY_E))
	assert_true(_has_key(&"interact", KEY_E))

func test_request_rebind_success_writes_cfg() -> void:
	_mgr.request_rebind(&"interact", _make_key(KEY_E))
	assert_true(FileAccess.file_exists(_mgr._bindings_path))

func test_request_rebind_success_emits_bindings_changed() -> void:
	watch_signals(_mgr)
	_mgr.request_rebind(&"interact", _make_key(KEY_E))
	assert_signal_emitted(_mgr, "bindings_changed")

# ---------------------------------------------------------------------------
# AC-R5a — force_swap
# ---------------------------------------------------------------------------

# combat_attack has KEY_J by default.
func test_force_swap_removes_event_from_conflict_action() -> void:
	var ev := _make_key(KEY_J)
	_mgr.force_swap(&"interact", &"combat_attack", ev)
	assert_false(_has_key(&"combat_attack", KEY_J))

func test_force_swap_adds_event_to_target_action() -> void:
	var ev := _make_key(KEY_J)
	_mgr.force_swap(&"interact", &"combat_attack", ev)
	assert_true(_has_key(&"interact", KEY_J))

func test_force_swap_returns_success() -> void:
	var result: InputMapManager.RebindResult = _mgr.force_swap(&"interact", &"combat_attack", _make_key(KEY_J))
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

func test_force_swap_emits_bindings_changed() -> void:
	watch_signals(_mgr)
	_mgr.force_swap(&"interact", &"combat_attack", _make_key(KEY_J))
	assert_signal_emitted(_mgr, "bindings_changed")

func test_force_swap_unknown_target_returns_unknown_action() -> void:
	var result: InputMapManager.RebindResult = _mgr.force_swap(&"ghost_action", &"combat_attack", _make_key(KEY_J))
	assert_eq(result, InputMapManager.RebindResult.UNKNOWN_ACTION)

func test_force_swap_unknown_conflict_returns_unknown_action() -> void:
	var result: InputMapManager.RebindResult = _mgr.force_swap(&"interact", &"ghost_action", _make_key(KEY_J))
	assert_eq(result, InputMapManager.RebindResult.UNKNOWN_ACTION)

# ---------------------------------------------------------------------------
# AC-R5b — remove_binding: last binding protection
# ---------------------------------------------------------------------------

# interact has only KEY_F by default (1 keyboard binding).
func test_remove_binding_last_binding_returns_last_binding_blocked() -> void:
	var result: InputMapManager.RebindResult = _mgr.remove_binding(&"interact")
	assert_eq(result, InputMapManager.RebindResult.LAST_BINDING_BLOCKED)

func test_remove_binding_last_binding_does_not_change_binding() -> void:
	var before: int = _first_key(&"interact")
	_mgr.remove_binding(&"interact")
	assert_eq(_first_key(&"interact"), before)

# combat_dodge has KEY_K and KEY_SPACE — removing one is allowed.
func test_remove_binding_multiple_bindings_removes_one() -> void:
	var result: InputMapManager.RebindResult = _mgr.remove_binding(&"combat_dodge")
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

func test_remove_binding_unknown_action_returns_unknown_action() -> void:
	var result: InputMapManager.RebindResult = _mgr.remove_binding(&"ghost_action")
	assert_eq(result, InputMapManager.RebindResult.UNKNOWN_ACTION)

func test_remove_binding_ok_emits_bindings_changed() -> void:
	watch_signals(_mgr)
	_mgr.remove_binding(&"combat_dodge")
	assert_signal_emitted(_mgr, "bindings_changed")

# ---------------------------------------------------------------------------
# AC-R6a — cfg saves physical_keycode immediately after rebind
# ---------------------------------------------------------------------------

func test_rebind_saves_physical_keycode_to_cfg() -> void:
	_mgr.request_rebind(&"combat_dodge", _make_key(KEY_L))
	var cfg := ConfigFile.new()
	cfg.load(_mgr._bindings_path)
	assert_eq(cfg.get_value("combat_dodge", "physical_keycode", -1), KEY_L)

# ---------------------------------------------------------------------------
# AC-R6b — reset_to_defaults
# ---------------------------------------------------------------------------

func test_reset_to_defaults_deletes_cfg_file() -> void:
	# First create a cfg by rebinding.
	_mgr.request_rebind(&"interact", _make_key(KEY_E))
	assert_true(FileAccess.file_exists(_mgr._bindings_path))
	_mgr.reset_to_defaults()
	assert_false(FileAccess.file_exists(_mgr._bindings_path))

func test_reset_to_defaults_restores_original_keys() -> void:
	_mgr.request_rebind(&"move_up", _make_key(KEY_T))
	_mgr.reset_to_defaults()
	assert_true(_has_key(&"move_up", KEY_W))

func test_reset_to_defaults_emits_bindings_changed() -> void:
	watch_signals(_mgr)
	_mgr.reset_to_defaults()
	assert_signal_emitted(_mgr, "bindings_changed")

# ---------------------------------------------------------------------------
# AC-R6c — physical_keycode stored, not logical keycode (AZERTY simulation)
# ---------------------------------------------------------------------------

func test_rebind_stores_physical_keycode_not_logical() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E  # physical position on AZERTY "e" key
	ev.keycode = KEY_Q           # logical output on AZERTY layout
	_mgr.request_rebind(&"interact", ev)
	var cfg := ConfigFile.new()
	cfg.load(_mgr._bindings_path)
	assert_eq(cfg.get_value("interact", "physical_keycode", -1), KEY_E)
	# logical keycode must NOT be stored
	assert_eq(cfg.get_value("interact", "keycode", 0), 0)

# ---------------------------------------------------------------------------
# AC-F4a — modifier combo detected as duplicate
# ---------------------------------------------------------------------------

func test_find_duplicate_detects_modifier_combo() -> void:
	# Bind combat_attack to Ctrl+J.
	var ctrl_j := _make_key(KEY_J, true, false, false)
	_mgr.request_rebind(&"combat_attack", ctrl_j)
	# Try to bind interact to Ctrl+J — must be DUPLICATE.
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"interact", _make_key(KEY_J, true, false, false))
	assert_eq(result, InputMapManager.RebindResult.DUPLICATE_BINDING)

# ---------------------------------------------------------------------------
# AC-F4b — different modifier → not a duplicate
# ---------------------------------------------------------------------------

func test_find_duplicate_different_modifier_not_duplicate() -> void:
	# combat_attack has plain KEY_J (no modifier).
	# Binding interact to Ctrl+J must succeed because J ≠ Ctrl+J.
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"interact", _make_key(KEY_J, true, false, false))
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

# ---------------------------------------------------------------------------
# AC-F4c — different event type → not a duplicate
# ---------------------------------------------------------------------------

func test_find_duplicate_different_event_type_not_duplicate() -> void:
	# combat_attack has KEY_J (keyboard). JOY_BUTTON_X is not bound to any
	# gameplay action by default, so this confirms that a keyboard event and a
	# joypad event with different indices are never treated as duplicates.
	# JOY_BUTTON_X was renamed to JOY_BUTTON_X in Godot 4.x.
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"interact", _make_joy_btn(JOY_BUTTON_X))
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

# ---------------------------------------------------------------------------
# begin_rebind / cancel_rebind — state machine
# ---------------------------------------------------------------------------

func test_begin_rebind_sets_awaiting_state() -> void:
	_mgr.begin_rebind(&"interact")
	assert_eq(_mgr._rebind_state, InputMapManager._State.AWAITING_INPUT,
			"begin_rebind should switch state to AWAITING_INPUT")

func test_begin_rebind_stores_pending_action() -> void:
	_mgr.begin_rebind(&"interact")
	assert_eq(_mgr._pending_rebind_action, &"interact")

func test_begin_rebind_returns_success() -> void:
	var result: InputMapManager.RebindResult = _mgr.begin_rebind(&"interact")
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

func test_begin_rebind_unknown_action_returns_unknown_action() -> void:
	var result: InputMapManager.RebindResult = _mgr.begin_rebind(&"ghost_action")
	assert_eq(result, InputMapManager.RebindResult.UNKNOWN_ACTION)

func test_begin_rebind_unknown_action_does_not_change_state() -> void:
	_mgr.begin_rebind(&"ghost_action")
	assert_eq(_mgr._rebind_state, InputMapManager._State.ACTIVE,
			"State must stay ACTIVE after a failed begin_rebind")

func test_cancel_rebind_returns_success_when_awaiting() -> void:
	_mgr.begin_rebind(&"interact")
	var result: InputMapManager.RebindResult = _mgr.cancel_rebind()
	assert_eq(result, InputMapManager.RebindResult.SUCCESS)

func test_cancel_rebind_restores_active_state() -> void:
	_mgr.begin_rebind(&"interact")
	_mgr.cancel_rebind()
	assert_eq(_mgr._rebind_state, InputMapManager._State.ACTIVE,
			"cancel_rebind should return state to ACTIVE")

func test_cancel_rebind_clears_pending_action() -> void:
	_mgr.begin_rebind(&"interact")
	_mgr.cancel_rebind()
	assert_eq(_mgr._pending_rebind_action, &"",
			"_pending_rebind_action must be cleared after cancel")

func test_cancel_rebind_not_in_rebind_returns_not_in_rebind() -> void:
	# No begin_rebind call — already in ACTIVE state.
	var result: InputMapManager.RebindResult = _mgr.cancel_rebind()
	assert_eq(result, InputMapManager.RebindResult.NOT_IN_REBIND,
			"Calling cancel_rebind while ACTIVE should return NOT_IN_REBIND")

# ---------------------------------------------------------------------------
# AC-E-focus-loss — focus loss during AWAITING_INPUT returns to ACTIVE
# ---------------------------------------------------------------------------

func test_focus_loss_during_awaiting_returns_to_active() -> void:
	_mgr.begin_rebind(&"interact")
	assert_eq(_mgr._rebind_state, InputMapManager._State.AWAITING_INPUT)
	# Simulate focus loss — cancel_rebind() is connected to focus_exited.
	_mgr.cancel_rebind()
	assert_eq(_mgr._rebind_state, InputMapManager._State.ACTIVE)

func test_focus_loss_does_not_change_inputmap() -> void:
	var before: int = _first_key(&"interact")
	_mgr.begin_rebind(&"interact")
	_mgr.cancel_rebind()
	assert_eq(_first_key(&"interact"), before)

# ---------------------------------------------------------------------------
# AC-E-save-fail — SAVE_FAILED still applies binding to InputMap in memory
# ---------------------------------------------------------------------------

func test_save_fail_still_applies_to_inputmap() -> void:
	# Point to an invalid path to simulate write failure.
	_mgr._bindings_path = "user://nonexistent_dir/cannot_write.cfg"
	var result: InputMapManager.RebindResult = _mgr.request_rebind(&"move_up", _make_key(KEY_T))
	# Memory must be updated even if save failed.
	assert_true(_has_key(&"move_up", KEY_T))
	assert_eq(result, InputMapManager.RebindResult.SAVE_FAILED)
