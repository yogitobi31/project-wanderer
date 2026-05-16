extends Node

## Scene transition manager with a 4-state FSM, async loading, and fade overlay.
##
## ADR-0003: IDLE -> FADING_OUT -> LOADING -> FADING_IN -> IDLE.
## Uses PROCESS_MODE_ALWAYS so it continues running while the active scene root
## is set to PROCESS_MODE_DISABLED during the transition.
##
## Usage:
##   SceneTransitionManager.request_transition("res://scenes/map_town.tscn")
##   await SceneTransitionManager.transition_completed
##
##   # With spawn point and metadata:
##   SceneTransitionManager.request_transition(
##       "res://scenes/map_town.tscn", "north_gate",
##       TransitionType.DEFAULT, {"from_scene": "map_dungeon"})
##
## Guarding actions during a transition:
##   if SceneTransitionManager.is_transitioning(): return

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the new scene is live and the fade-in is complete.
signal transition_completed(scene_path: String)

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

## FSM states - ADR-0003 S.씬 전환 계약.
enum State { IDLE, FADING_OUT, LOADING, FADING_IN }

## Visual style of the transition (reserved - story-002+ scope).
enum TransitionType { DEFAULT, INSTANT, CUT }

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Fade-out duration in seconds - synced with AudioManager BGM_FADE_OUT.
const FADE_OUT_DURATION: float = 0.3

## Fade-in duration in seconds - synced with AudioManager BGM_FADE_IN.
const FADE_IN_DURATION: float = 0.4

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _state: State = State.IDLE
var _target_path: String = ""
var _overlay: ColorRect
var _load_progress: Array[float] = []

## Persists the requested spawn point id across coroutine steps.
## Set in request_transition(); consumed in _swap_scene() -> _apply_spawn().
var _spawn_point_id: String = ""

## Persists caller-supplied metadata across coroutine steps.
## Set in request_transition(); consumed in _swap_scene() -> _deliver_metadata().
var _metadata: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_overlay()

func _process(_delta: float) -> void:
	if _state != State.LOADING:
		return
	var status: int = ResourceLoader.load_threaded_get_status(_target_path, _load_progress)
	_handle_load_status(status)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Begins a scene transition to [param scene_path].
##
## Drops the request with [method push_warning] if a transition is already
## in progress (AC-2 duplicate request guard). The in-flight transition is
## never interrupted - only the first caller wins.
##
## [param spawn_point_id]: destination SpawnPoint_{id} node name suffix.
##   Resolved against the "spawn_points" group after the scene loads.
##   Falls back to SpawnPoint_Default when the named point is absent.
##   Pass "" to go directly to SpawnPoint_Default.
## [param transition_type]: visual style (DEFAULT, INSTANT, CUT).
## [param metadata]: arbitrary data forwarded to the arriving scene via
##   [method _on_scene_ready] if that method exists on the scene root.
##
## Example:
##   SceneTransitionManager.request_transition(
##       "res://scenes/map_cave.tscn", "cave_entrance")
func request_transition(scene_path: String, spawn_point_id: String = "",
		transition_type: TransitionType = TransitionType.DEFAULT,
		metadata: Dictionary = {}) -> void:
	if _state != State.IDLE:
		push_warning(
				"SceneTransitionManager: transition already in progress, " +
				"dropping request for: " + scene_path)
		return
	_target_path = scene_path
	_spawn_point_id = spawn_point_id
	_metadata = metadata
	_begin_fade_out(transition_type)

## Returns true while the FSM is in any non-IDLE state.
##
## Example:
##   if SceneTransitionManager.is_transitioning(): return
func is_transitioning() -> bool:
	return _state != State.IDLE

# ---------------------------------------------------------------------------
# Internal - FSM transitions (coroutines)
# ---------------------------------------------------------------------------

func _begin_fade_out(_type: TransitionType) -> void:
	if _type != TransitionType.DEFAULT:
		push_warning("SceneTransitionManager: TransitionType.%s not yet implemented - using DEFAULT" % TransitionType.keys()[_type])
	_state = State.FADING_OUT
	call_deferred("_set_scene_process_mode", get_tree().current_scene, PROCESS_MODE_DISABLED)
	_overlay.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_OUT_DURATION)
	await tween.finished
	_begin_loading()

func _begin_loading() -> void:
	_state = State.LOADING
	# TODO(ADR-0003): AudioManager null guard - AudioManager.request_music_fade_out(FADE_OUT_DURATION)
	# Remove null guard once AudioManager epic is complete.
	ResourceLoader.load_threaded_request(_target_path)
	# Polled each frame via _process() -> _handle_load_status().

func _swap_scene() -> void:
	_state = State.FADING_IN  # Guard: exit LOADING before first await so _process won't re-enter
	var packed: PackedScene = ResourceLoader.load_threaded_get(_target_path) as PackedScene
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	var new_scene: Node = get_tree().current_scene
	_set_scene_process_mode(new_scene, PROCESS_MODE_DISABLED)
	_apply_spawn(_spawn_point_id)
	_deliver_metadata(_metadata)
	_begin_fade_in()

func _begin_fade_in() -> void:
	_state = State.FADING_IN
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_IN_DURATION)
	await tween.finished
	_overlay.visible = false
	_set_scene_process_mode(get_tree().current_scene, PROCESS_MODE_INHERIT)
	_state = State.IDLE
	transition_completed.emit(_target_path)

# ---------------------------------------------------------------------------
# Internal - SpawnPoint resolution
# ---------------------------------------------------------------------------

## Resolves a world-space spawn position from a flat array of nodes.
##
## Pure function - performs no scene tree queries. Pass the result of
## [method SceneTree.get_nodes_in_group] as [param spawn_nodes] so this
## function can be unit-tested without a live scene.
##
## Resolution order (ADR-0003 TR-scene-004):
##   1. Marker2D named "SpawnPoint_{spawn_point_id}" if [param spawn_point_id] != "".
##   2. Marker2D named "SpawnPoint_Default" (fallback).
##   3. push_error + Vector2.ZERO if neither exists.
##
## Example:
##   var pos: Vector2 = _resolve_spawn_position(
##       get_tree().get_nodes_in_group(&"spawn_points"), "north_gate")
func _resolve_spawn_position(spawn_nodes: Array, spawn_point_id: String) -> Vector2:
	# 1. Named spawn point lookup
	if spawn_point_id != "":
		var target_name: String = "SpawnPoint_" + spawn_point_id
		for node in spawn_nodes:
			if node is Marker2D and node.name == target_name:
				return node.global_position

	# 2. Default fallback
	for node in spawn_nodes:
		if node is Marker2D and node.name == "SpawnPoint_Default":
			return node.global_position

	# 3. Neither found — ADR-0003 requires push_error here (SpawnPoint_Default is mandatory)
	push_error(
			"SceneTransitionManager: no SpawnPoint_Default found in " +
			"'spawn_points' group - placing player at Vector2.ZERO")
	return Vector2.ZERO

## Queries the spawn_points group, resolves the target position, and
## moves the player node to it via [method set_spawn_position].
##
## Silently skips if no node is in the "player" group or if the player
## node does not implement [method set_spawn_position] - avoids hard
## coupling to PlayerController (ADR-0003 S.no direct reference).
func _apply_spawn(spawn_point_id: String) -> void:
	var spawn_nodes: Array = get_tree().get_nodes_in_group(&"spawn_points")
	var spawn_pos: Vector2 = _resolve_spawn_position(spawn_nodes, spawn_point_id)
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	if player.has_method(&"set_spawn_position"):
		player.set_spawn_position(spawn_pos)

## Delivers transition metadata to the arriving scene root.
##
## Calls [method _on_scene_ready] on the current scene root if that method
## exists, forwarding [param meta] as its argument. Does nothing when the
## scene root has no such method, keeping non-metadata scenes unaffected.
##
## Example scene root implementation:
##   func _on_scene_ready(meta: Dictionary) -> void:
##       if meta.has("from_scene"): _show_arrival_cutscene()
func _deliver_metadata(meta: Dictionary) -> void:
	var new_scene: Node = get_tree().current_scene
	if new_scene == null:
		return
	if new_scene.has_method(&"_on_scene_ready"):
		new_scene._on_scene_ready(meta)

# ---------------------------------------------------------------------------
# Internal - helpers (also called directly by unit tests)
# ---------------------------------------------------------------------------

## Applies the ResourceLoader status from _process() or a unit test simulation.
##
## LOADED  -> _swap_scene() (starts the scene swap coroutine).
## FAILED  -> push_error, state returns to IDLE, overlay stays visible
##            (black screen - caller must decide recovery).
## Other statuses (IN_PROGRESS, INVALID_RESOURCE) are silently ignored.
func _handle_load_status(status: int) -> void:
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_swap_scene()
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error(
					"SceneTransitionManager: failed to load scene: " +
					_target_path)
			_state = State.IDLE

## Sets [param mode] on [param scene] if it is not null.
##
## Extracted from _begin_fade_out/_begin_fade_in for unit testability:
## tests inject mock Node instances instead of relying on
## get_tree().current_scene, which is not injectable in GUT headless context.
func _set_scene_process_mode(scene: Node, mode: Node.ProcessMode) -> void:
	if scene == null:
		return
	scene.process_mode = mode

func _setup_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	layer.add_child(_overlay)
