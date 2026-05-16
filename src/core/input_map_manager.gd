extends Node

## Global input action registry and runtime rebind manager for 유랑단.
##
## Registers all 14 gameplay and UI actions in Godot's InputMap at startup,
## restores any user-saved keyboard remappings from disk, and provides a
## safe interactive rebind API (story-002).
##
## Usage - reading input:
##   if InputMapManager.is_ready:
##       var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
##
## Usage - listening for readiness:
##   InputMapManager.input_map_ready.connect(_on_input_ready)
##
## Usage - rebinding a key:
##   var ev := InputEventKey.new()
##   ev.physical_keycode = KEY_H
##   var result := InputMapManager.request_rebind(&"combat_attack", ev)
##   if result == InputMapManager.RebindResult.SUCCESS:
##       pass  # binding applied and saved
##
## Usage - interactive rebind flow:
##   InputMapManager.begin_rebind(&"combat_attack")
##   # ... user presses a key, _input() detects InputEventKey and calls
##   #     request_rebind() then cancel_rebind() internally ...
##   InputMapManager.bindings_changed.connect(_on_bindings_changed)
##
## Gamepad formulas (story-004): get_move_vector() and get_discrete_direction()
## live here alongside the action registry they depend on.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted once, immediately after is_ready is set true.
## Connect early listeners before InputMapManager enters the scene tree,
## or check is_ready directly if late-connecting.
signal input_map_ready()

## Emitted whenever the active InputMap bindings change - either because
## request_rebind(), force_swap(), remove_binding(), or reset_to_defaults()
## succeeded, or because the file was re-saved.
## Listeners (e.g. rebind UI screens) should refresh their display on this signal.
signal bindings_changed()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Config-file schema version. Increment when the serialization format changes.
## Saved files with a lower version are discarded (defaults used, warning emitted).
const CURRENT_SCHEMA_VERSION: int = 1

## Keycodes that may never be rebound to a gameplay action.
## Includes OS-level keys that must remain unconditionally available.
const RESERVED_KEYCODES: Array[int] = [
	KEY_PRINT,
	KEY_META,
	KEY_F1,  KEY_F2,  KEY_F3,  KEY_F4,
	KEY_F5,  KEY_F6,  KEY_F7,  KEY_F8,
	KEY_F9,  KEY_F10, KEY_F11, KEY_F12,
]

## Minimum axis_value magnitude for a JoypadMotion event to be accepted as a
## rebind target. Prevents accidental binding to near-zero drift.
const REBIND_AXIS_THRESHOLD: float = 0.5

## Left stick deadzone radius (radial). Passed to Input.get_vector() and used
## as the magnitude threshold in _direction_from_axes().
## GDD F-1: magnitude at exactly 0.2 must NOT register (? is treated as dead).
const DEADZONE_LEFT_STICK: float = 0.2

## Half-width of each cardinal direction quadrant in degrees.
## Angles within ?DIAGONAL_THRESHOLD_DEG of a cardinal axis map to that axis.
const DIAGONAL_THRESHOLD_DEG: float = 45.0

## Return codes for all rebind operations (story-002).
##
## Example:
##   var r := InputMapManager.request_rebind(&"interact", ev)
##   match r:
##       InputMapManager.RebindResult.SUCCESS:           _refresh_ui()
##       InputMapManager.RebindResult.DUPLICATE_BINDING: _show_swap_dialog()
##       InputMapManager.RebindResult.RESERVED_KEY:      _show_reserved_warning()
##       _:                                              push_warning("rebind failed: %d" % r)
enum RebindResult {
	SUCCESS,               ## Binding applied and saved successfully.
	UNKNOWN_ACTION,        ## action is not in ACTION_DEFS.
	INVALID_EVENT_TYPE,    ## Event type is not rebindable (e.g. MIDI, touch).
	RESERVED_KEY,          ## Key is in RESERVED_KEYCODES (F1-F12, Super, Print).
	DUPLICATE_BINDING,     ## Same event already bound in the same category.
	LAST_BINDING_BLOCKED,  ## Removal would leave the action with zero keyboard events.
	SAVE_FAILED,           ## InputMap updated in memory; disk write failed.
	NOT_IN_REBIND,         ## cancel_rebind() called while already in ACTIVE state.
}

## Discrete 4-way direction returned by get_discrete_direction().
## NONE is returned when stick magnitude is within DEADZONE_LEFT_STICK.
enum Direction { NONE, UP, DOWN, LEFT, RIGHT }

## Internal rebind-flow state machine (story-002).
enum _State {
	ACTIVE,          ## Normal operation - no interactive rebind pending.
	AWAITING_INPUT,  ## begin_rebind() was called; next valid key press completes the bind.
}

## Master table of all 14 actions. Each Dictionary has keys:
##   &"name"     : StringName  - the InputMap action name
##   &"category" : StringName  - &"gameplay" or &"ui"
##   &"keys"     : Array       - keyboard KEY_* constants (physical)
##   &"mouse"    : Array       - MOUSE_BUTTON_* constants (may be empty)
##   &"joy_btns" : Array       - JOY_BUTTON_* constants (may be empty)
##   &"joy_axes" : Array       - [{axis, value}] pairs (may be empty)
##
## Design note: game_confirm uses KEY_ENTER + JOY_BUTTON_SOUTH, which
## overlaps with Godot's built-in ui_accept keybindings. game_confirm is
## registered as an independent action; callers that need to distinguish
## game_confirm from ui_accept must handle both signals separately.
## This is intentional per GDD R-2 - do not remove the bindings.
const ACTION_DEFS: Array[Dictionary] = [
	{
		&"name": &"move_up",      &"category": &"gameplay",
		&"keys": [KEY_W, KEY_UP], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_UP],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_Y, &"value": -1.0}]
	},
	{
		&"name": &"move_down",    &"category": &"gameplay",
		&"keys": [KEY_S, KEY_DOWN], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_DOWN],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_Y, &"value": 1.0}]
	},
	{
		&"name": &"move_left",    &"category": &"gameplay",
		&"keys": [KEY_A, KEY_LEFT], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_LEFT],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_X, &"value": -1.0}]
	},
	{
		&"name": &"move_right",   &"category": &"gameplay",
		&"keys": [KEY_D, KEY_RIGHT], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_RIGHT],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_X, &"value": 1.0}]
	},
	{
		&"name": &"combat_attack", &"category": &"gameplay",
		&"keys": [KEY_J], &"mouse": [MOUSE_BUTTON_LEFT],
		&"joy_btns": [JOY_BUTTON_A],
		&"joy_axes": []
	},
	{
		&"name": &"combat_dodge",  &"category": &"gameplay",
		&"keys": [KEY_K, KEY_SPACE], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_B],
		&"joy_axes": []
	},
	{
		&"name": &"interact",      &"category": &"gameplay",
		&"keys": [KEY_F], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_Y],
		&"joy_axes": []
	},
	{
		&"name": &"game_pause",    &"category": &"ui",
		&"keys": [KEY_ESCAPE], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_START],
		&"joy_axes": []
	},
	{
		&"name": &"game_confirm",  &"category": &"ui",
		&"keys": [KEY_ENTER], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_A],
		&"joy_axes": []
	},
	{
		&"name": &"game_cancel",   &"category": &"ui",
		&"keys": [KEY_ESCAPE, KEY_BACKSPACE], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_B],
		&"joy_axes": []
	},
	{
		&"name": &"game_nav_up",   &"category": &"ui",
		&"keys": [KEY_UP, KEY_W], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_UP],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_Y, &"value": -1.0}]
	},
	{
		&"name": &"game_nav_down", &"category": &"ui",
		&"keys": [KEY_DOWN, KEY_S], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_DOWN],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_Y, &"value": 1.0}]
	},
	{
		&"name": &"game_nav_left", &"category": &"ui",
		&"keys": [KEY_LEFT, KEY_A], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_LEFT],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_X, &"value": -1.0}]
	},
	{
		&"name": &"game_nav_right", &"category": &"ui",
		&"keys": [KEY_RIGHT, KEY_D], &"mouse": [],
		&"joy_btns": [JOY_BUTTON_DPAD_RIGHT],
		&"joy_axes": [{&"axis": JOY_AXIS_LEFT_X, &"value": 1.0}]
	},
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## True once _ready() has completed its initialization sequence.
## Callers that consume input should guard with: if not InputMapManager.is_ready: return
var is_ready: bool = false

## Path to the user bindings config file.
## Overridable in tests by setting this before calling _load_user_bindings().
var _bindings_path: String = "user://input_bindings.cfg"

## Current interactive-rebind state.  ACTIVE means no rebind is pending.
var _rebind_state: _State = _State.ACTIVE

## The action waiting for a new key during an interactive rebind flow, or &""
## when _rebind_state == ACTIVE.
var _pending_rebind_action: StringName = &""

## True while a UI overlay (dialogue, menu, inventory) is active.
## PlayerController and any gameplay input consumers must guard their
## _physics_process() entry with: if InputMapManager.is_ui_active: return
## game_pause handlers must also check this flag before acting.
var is_ui_active: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_register_default_actions()
	_load_user_bindings()
	is_ready = true
	input_map_ready.emit()
	get_viewport().focus_exited.connect(cancel_rebind)

# ---------------------------------------------------------------------------
# Internal - default registration
# ---------------------------------------------------------------------------

## Registers all 14 actions in InputMap with their default keyboard,
## mouse, and gamepad events. Idempotent: safe to call multiple times
## (existing events are erased before re-adding).
##
## Also clears Godot built-in ui_accept / ui_cancel events so that
## game_confirm / game_cancel are the sole handlers for those inputs.
## This satisfies AC-R2c (zero event overlap with Godot built-ins).
func _register_default_actions() -> void:
	# Remove Godot built-in event bindings that would overlap with game_ actions.
	for builtin: StringName in [&"ui_accept", &"ui_cancel"]:
		if InputMap.has_action(builtin):
			InputMap.action_erase_events(builtin)

	for def: Dictionary in ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		else:
			InputMap.action_erase_events(action_name)

		for keycode: int in def[&"keys"]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action_name, ev)

		for btn_idx: int in def[&"mouse"]:
			var ev := InputEventMouseButton.new()
			ev.button_index = btn_idx
			InputMap.action_add_event(action_name, ev)

		for btn_idx: int in def[&"joy_btns"]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = btn_idx
			InputMap.action_add_event(action_name, ev)

		for axis_pair: Dictionary in def[&"joy_axes"]:
			var ev := InputEventJoypadMotion.new()
			ev.axis = axis_pair[&"axis"]
			ev.axis_value = axis_pair[&"value"]
			InputMap.action_add_event(action_name, ev)

# ---------------------------------------------------------------------------
# Internal - user binding restore
# ---------------------------------------------------------------------------

## Loads user bindings from _bindings_path and restores keyboard events.
##
## Failure modes (all non-fatal):
##   - File missing       : silently skipped, defaults remain
##   - Parse error        : push_warning emitted, defaults remain
##   - schema_version < 1 : push_warning("schema...") emitted, defaults remain
##   - Unknown action     : entry skipped silently (whitelist enforced)
##
## Only keyboard events are restored. Mouse and gamepad bindings always
## use defaults and are not persisted (rebind API is story-002 scope).
func _load_user_bindings() -> void:
	if not FileAccess.file_exists(_bindings_path):
		return

	var cfg := ConfigFile.new()
	var err: Error = cfg.load(_bindings_path)
	if err != OK:
		push_warning("InputMapManager: failed to parse bindings file (error %d) - using defaults" % err)
		return

	var schema_version: int = cfg.get_value("meta", "schema_version", 0)
	if schema_version < CURRENT_SCHEMA_VERSION:
		push_warning(
			"InputMapManager: bindings schema version %d < current %d - using defaults" \
			% [schema_version, CURRENT_SCHEMA_VERSION]
		)
		return

	var known_actions: Array[StringName] = []
	for def: Dictionary in ACTION_DEFS:
		known_actions.append(def[&"name"])

	for section: String in cfg.get_sections():
		if section == "meta":
			continue
		var action_name: StringName = StringName(section)
		if not known_actions.has(action_name):
			continue
		if not InputMap.has_action(action_name):
			continue

		var keycode: int = cfg.get_value(section, "physical_keycode", -1)
		if keycode <= 0:
			continue

		var existing: Array[InputEvent] = InputMap.action_get_events(action_name)
		for ev: InputEvent in existing:
			if ev is InputEventKey:
				InputMap.action_erase_event(action_name, ev)

		var new_ev := InputEventKey.new()
		new_ev.physical_keycode = keycode
		InputMap.action_add_event(action_name, new_ev)

# ---------------------------------------------------------------------------
# Public - context (story-003)
# ---------------------------------------------------------------------------

## Sets or clears the UI-active context flag.
##
## When [param active] is true, gameplay-category action polling is expected
## to be suppressed by each consumer (PlayerController, CombatController, etc.)
## via an explicit guard at the start of their _physics_process().
## This Autoload only owns the flag - enforcement is the caller's responsibility.
##
## Called by SceneTransitionManager at transition start (true) and completion (false),
## and by any UI overlay that captures exclusive input focus.
##
## Example:
##   InputMapManager.set_ui_active(true)   # UI opened
##   InputMapManager.set_ui_active(false)  # UI closed
func set_ui_active(active: bool) -> void:
	is_ui_active = active

# ---------------------------------------------------------------------------
# Public - gamepad formulas (story-004)
# ---------------------------------------------------------------------------

## Returns the left-stick movement vector with radial deadzone applied.
##
## Delegates to Input.get_vector(), which normalises the output to length ? 1.0
## once the stick magnitude exceeds DEADZONE_LEFT_STICK.
##
## Example (PlayerController._physics_process):
##   if InputMapManager.is_ui_active: return
##   velocity = InputMapManager.get_move_vector() * speed
func get_move_vector() -> Vector2:
	return Input.get_vector(
			&"move_left", &"move_right", &"move_up", &"move_down",
			DEADZONE_LEFT_STICK)

## Returns a discrete 4-way Direction for UI navigation or tile-grid movement.
##
## Reads the current left-stick axes and delegates to _direction_from_axes().
## Returns Direction.NONE when the stick is within the deadzone.
##
## Example:
##   var d := InputMapManager.get_discrete_direction()
##   if d == InputMapManager.Direction.UP: _move_cursor_up()
func get_discrete_direction() -> Direction:
	var axis_x := Input.get_axis(&"move_left", &"move_right")
	var axis_y := Input.get_axis(&"move_up", &"move_down")
	return _direction_from_axes(axis_x, axis_y)

# ---------------------------------------------------------------------------
# Public - rebind API (story-002)
# ---------------------------------------------------------------------------

## Atomically rebinds [param action] to [param new_event], enforcing all
## guard rules (unknown action, invalid event type, reserved key,
## conflict detection within the same category).
##
## Returns [enum RebindResult].SUCCESS on success. On success the change is
## persisted to disk via [method _save_to_cfg] and [signal bindings_changed]
## is emitted. On failure the InputMap is unchanged.
##
## Example:
##   var ev := InputEventKey.new()
##   ev.physical_keycode = KEY_H
##   var r := InputMapManager.request_rebind(&"combat_attack", ev)
##   if r == InputMapManager.RebindResult.SUCCESS:
##       _refresh_rebind_ui()
func request_rebind(action: StringName, new_event: InputEvent) -> RebindResult:
	if not _is_registered_action(action):
		return RebindResult.UNKNOWN_ACTION

	if not _is_allowed_event_type(new_event):
		return RebindResult.INVALID_EVENT_TYPE

	if new_event is InputEventKey:
		var key_ev := new_event as InputEventKey
		if RESERVED_KEYCODES.has(key_ev.physical_keycode):
			return RebindResult.RESERVED_KEY

	if new_event is InputEventJoypadMotion:
		var joy_ev := new_event as InputEventJoypadMotion
		if absf(joy_ev.axis_value) < REBIND_AXIS_THRESHOLD:
			return RebindResult.INVALID_EVENT_TYPE

	var category: StringName = _get_action_category(action)
	var conflict: StringName = _find_duplicate(action, new_event, category)
	if conflict != &"":
		return RebindResult.DUPLICATE_BINDING

	# Remove all existing events of the same type, then add the new event.
	var existing: Array[InputEvent] = InputMap.action_get_events(action)
	for ev: InputEvent in existing:
		if ev.get_class() == new_event.get_class():
			InputMap.action_erase_event(action, ev)

	InputMap.action_add_event(action, new_event)

	var save_result: RebindResult = _save_to_cfg()
	bindings_changed.emit()
	return save_result

## Moves [param event] from [param conflict_action] to [param target_action].
## Used when the player chooses a key already in use - the UI can offer a
## swap rather than a conflict error.
##
## Removes the matching event from conflict_action, replaces any same-type
## event on target_action, then adds the event to target_action.
##
## Returns [enum RebindResult].SUCCESS on success, or the first failing
## [enum RebindResult] code encountered.
##
## Example:
##   var ev := InputEventKey.new()
##   ev.physical_keycode = KEY_J
##   var r := InputMapManager.force_swap(&"interact", &"combat_attack", ev)
func force_swap(target_action: StringName, conflict_action: StringName, event: InputEvent) -> RebindResult:
	if not _is_registered_action(target_action):
		return RebindResult.UNKNOWN_ACTION
	if not _is_registered_action(conflict_action):
		return RebindResult.UNKNOWN_ACTION

	# Remove the event from conflict_action.
	var conflict_events: Array[InputEvent] = InputMap.action_get_events(conflict_action)
	for ev: InputEvent in conflict_events:
		if _events_match(ev, event):
			InputMap.action_erase_event(conflict_action, ev)
			break

	# Remove same-type events from target_action, then add the new event.
	var target_events: Array[InputEvent] = InputMap.action_get_events(target_action)
	for ev: InputEvent in target_events:
		if ev.get_class() == event.get_class():
			InputMap.action_erase_event(target_action, ev)

	InputMap.action_add_event(target_action, event)

	var save_result: RebindResult = _save_to_cfg()
	bindings_changed.emit()
	return save_result

## Removes the first keyboard binding from [param action_name], subject to
## the LAST_BINDING_BLOCKED guard: if only one keyboard event remains, the
## removal is refused.
##
## Returns [enum RebindResult].SUCCESS on success,
## [enum RebindResult].LAST_BINDING_BLOCKED if removal would leave zero
## keyboard events, or [enum RebindResult].UNKNOWN_ACTION if the action is
## not registered.
##
## Example:
##   InputMapManager.remove_binding(&"combat_dodge")
func remove_binding(action_name: StringName) -> RebindResult:
	if not _is_registered_action(action_name):
		return RebindResult.UNKNOWN_ACTION

	# Count keyboard events; refuse if only one remains (AC-R5b).
	var key_events: Array[InputEvent] = []
	for ev: InputEvent in InputMap.action_get_events(action_name):
		if ev is InputEventKey:
			key_events.append(ev)

	if key_events.size() <= 1:
		return RebindResult.LAST_BINDING_BLOCKED

	InputMap.action_erase_event(action_name, key_events[0])

	var save_result: RebindResult = _save_to_cfg()
	bindings_changed.emit()
	return save_result

## Enters AWAITING_INPUT state for [param action_name].
## The next call to [method request_rebind] (or a UI layer that intercepts
## raw input) should use [param action_name] as the target.
##
## Does nothing and returns [enum RebindResult].UNKNOWN_ACTION if the action
## is not registered. Sets _rebind_state to AWAITING_INPUT on success.
##
## Example:
##   InputMapManager.begin_rebind(&"combat_attack")
##   # ... show "press a key" prompt in UI ...
func begin_rebind(action_name: StringName) -> RebindResult:
	if not _is_registered_action(action_name):
		return RebindResult.UNKNOWN_ACTION
	_rebind_state = _State.AWAITING_INPUT
	_pending_rebind_action = action_name
	return RebindResult.SUCCESS

## Cancels an in-progress interactive rebind, returning to ACTIVE state.
## Safe to call at any time (no-ops when not in AWAITING_INPUT).
##
## Connected to Viewport.focus_exited so that tabbing away from the window
## automatically cancels a pending rebind. The return value is ignored when
## called via that signal connection.
##
## Returns [enum RebindResult].NOT_IN_REBIND if called while already ACTIVE,
## [enum RebindResult].SUCCESS otherwise.
##
## Example:
##   InputMapManager.cancel_rebind()  # user pressed Escape
func cancel_rebind() -> RebindResult:
	if _rebind_state == _State.ACTIVE:
		return RebindResult.NOT_IN_REBIND
	_rebind_state = _State.ACTIVE
	_pending_rebind_action = &""
	return RebindResult.SUCCESS

## Resets all 14 actions to their default bindings from ACTION_DEFS and
## deletes the user bindings config file so defaults load clean on next
## launch (AC-R6b). Emits [signal bindings_changed].
##
## Example:
##   InputMapManager.reset_to_defaults()
func reset_to_defaults() -> void:
	_register_default_actions()
	if FileAccess.file_exists(_bindings_path):
		DirAccess.remove_absolute(_bindings_path)
	bindings_changed.emit()

# ---------------------------------------------------------------------------
# Private - rebind helpers
# ---------------------------------------------------------------------------

## Returns true if [param action_name] is present in ACTION_DEFS.
func _is_registered_action(action_name: StringName) -> bool:
	for def: Dictionary in ACTION_DEFS:
		if def[&"name"] == action_name:
			return true
	return false

## Returns the &"category" StringName (&"gameplay" or &"ui") for a registered
## action, or &"" if the action is not found.
func _get_action_category(action_name: StringName) -> StringName:
	for def: Dictionary in ACTION_DEFS:
		if def[&"name"] == action_name:
			return def[&"category"]
	return &""

## Searches all registered actions in the same [param category] (excluding
## [param skip_action]) for an existing binding that matches [param event].
## Returns the conflicting action name, or &"" if no conflict is found.
##
## Only actions in the same category are checked - keyboard vs. gamepad
## bindings in different categories are permitted to overlap (AC-F4c).
func _find_duplicate(skip_action: StringName, event: InputEvent, category: StringName) -> StringName:
	for def: Dictionary in ACTION_DEFS:
		var name: StringName = def[&"name"]
		if name == skip_action:
			continue
		if def[&"category"] != category:
			continue
		for ev: InputEvent in InputMap.action_get_events(name):
			if _events_match(event, ev):
				return name
	return &""

## Returns true if [param a] and [param b] represent the same input event.
##
## Type mismatches always return false (AC-F4c: keyboard vs gamepad ? duplicate).
## For keyboard events, all modifier flags must also match (AC-F4a, AC-F4b).
func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class():
		return false

	if a is InputEventKey:
		var ak := a as InputEventKey
		var bk := b as InputEventKey
		return (ak.physical_keycode == bk.physical_keycode
			and ak.ctrl_pressed  == bk.ctrl_pressed
			and ak.shift_pressed == bk.shift_pressed
			and ak.alt_pressed   == bk.alt_pressed
			and ak.meta_pressed  == bk.meta_pressed)

	if a is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index

	if a is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index

	if a is InputEventJoypadMotion:
		var am := a as InputEventJoypadMotion
		var bm := b as InputEventJoypadMotion
		return am.axis == bm.axis and sign(am.axis_value) == sign(bm.axis_value)

	return false

## Returns true if [param event] is a rebindable event type.
## Accepts keyboard, mouse button, joypad button, and joypad motion events.
func _is_allowed_event_type(event: InputEvent) -> bool:
	return (event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventJoypadButton
		or event is InputEventJoypadMotion)

## Serialises the current keyboard bindings for all 14 actions to
## [member _bindings_path].
##
## Stores physical_keycode only (not logical keycode) to support non-QWERTY
## layouts correctly (AC-R6c).
##
## Returns [enum RebindResult].SUCCESS on success,
## [enum RebindResult].SAVE_FAILED if ConfigFile.save() fails (InputMap is
## still updated in memory).
func _save_to_cfg() -> RebindResult:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "schema_version", CURRENT_SCHEMA_VERSION)

	for def: Dictionary in ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		for ev: InputEvent in InputMap.action_get_events(action_name):
			if ev is InputEventKey:
				cfg.set_value(action_name, "physical_keycode",
						(ev as InputEventKey).physical_keycode)
				break  # Only persist the first keyboard event per action.

	var err: Error = cfg.save(_bindings_path)
	if err != OK:
		push_warning("InputMapManager: could not save bindings (error %d)" % err)
		return RebindResult.SAVE_FAILED
	return RebindResult.SUCCESS

## Pure direction mapping - testable without the Input singleton.
##
## Quadrant boundaries (Godot Y-down, angle from Vector2.angle()):
##   RIGHT : abs(angle) ? 45?              - symmetric, includes ?45?
##   LEFT  : abs(angle) ? 135?             - symmetric, includes ?135?
##   DOWN  : angle ? (45?, 135?) exclusive - positive-Y half
##   UP    : angle ? (-135?, -45?) excl.   - negative-Y half
##   NONE  : magnitude ? DEADZONE_LEFT_STICK
##
## Callers: get_discrete_direction(), and unit tests directly.
func _direction_from_axes(axis_x: float, axis_y: float) -> Direction:
	var vec: Vector2 = Vector2(axis_x, axis_y)
	if vec.length_squared() <= DEADZONE_LEFT_STICK * DEADZONE_LEFT_STICK:
		return Direction.NONE
	const _EPSILON: float = 0.0001
	var angle_deg: float = rad_to_deg(vec.angle())
	if abs(angle_deg) <= DIAGONAL_THRESHOLD_DEG + _EPSILON:
		return Direction.RIGHT
	elif abs(angle_deg) >= 180.0 - DIAGONAL_THRESHOLD_DEG - _EPSILON:
		return Direction.LEFT
	elif angle_deg > 0.0:
		return Direction.DOWN
	else:
		return Direction.UP
