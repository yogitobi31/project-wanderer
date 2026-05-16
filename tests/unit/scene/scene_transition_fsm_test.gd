class_name SceneTransitionFsmTest
extends GutTest

## Unit tests for SceneTransitionManager FSM (story-001):
## duplicate request guard (AC-2), process_mode contract (AC-5a/b/c),
## and load-failure recovery (AC-6).
##
## Tests that need to set process_mode on a scene root use mock Node instances
## injected via _set_scene_process_mode() — get_tree().current_scene is not
## injectable in GUT headless context.

var _stm: SceneTransitionManager


func before_each() -> void:
	# load() avoids Autoload-name-shadowing: SceneTransitionManager as a class_name + Autoload
	# means SceneTransitionManager.new() would call .new() on the singleton, which fails.
	_stm = load("res://src/core/scene_transition_manager.gd").new()
	add_child_autoqfree(_stm)


func after_each() -> void:
	pass  # freed by autoqfree; no InputMap cleanup needed


# ---------------------------------------------------------------------------
# AC-2: Duplicate request guard
# ---------------------------------------------------------------------------

func test_ac2_duplicate_request_during_fading_out_is_ignored() -> void:
	# Given: transition already in progress
	_stm._state = SceneTransitionManager.State.FADING_OUT
	_stm._target_path = "res://scenes/original.tscn"
	# When: second request arrives
	_stm.request_transition("res://scenes/other.tscn")
	# Then: _target_path unchanged, state unchanged
	assert_eq(_stm._target_path, "res://scenes/original.tscn",
			"second request must not overwrite the in-flight target path")
	assert_eq(_stm._state, SceneTransitionManager.State.FADING_OUT,
			"state must remain FADING_OUT after dropped request")


func test_ac2_duplicate_request_during_loading_is_ignored() -> void:
	_stm._state = SceneTransitionManager.State.LOADING
	_stm._target_path = "res://scenes/original.tscn"
	_stm.request_transition("res://scenes/other.tscn")
	assert_eq(_stm._target_path, "res://scenes/original.tscn")
	assert_eq(_stm._state, SceneTransitionManager.State.LOADING)


func test_ac2_duplicate_request_during_fading_in_is_ignored() -> void:
	_stm._state = SceneTransitionManager.State.FADING_IN
	_stm._target_path = "res://scenes/original.tscn"
	_stm.request_transition("res://scenes/other.tscn")
	assert_eq(_stm._target_path, "res://scenes/original.tscn")
	assert_eq(_stm._state, SceneTransitionManager.State.FADING_IN)


# ---------------------------------------------------------------------------
# AC-2 supplementary: is_transitioning()
# ---------------------------------------------------------------------------

func test_ac2_is_transitioning_returns_false_in_idle() -> void:
	assert_false(_stm.is_transitioning(),
			"IDLE → is_transitioning() must return false")


func test_ac2_is_transitioning_returns_true_when_fading_out() -> void:
	_stm._state = SceneTransitionManager.State.FADING_OUT
	assert_true(_stm.is_transitioning())


func test_ac2_is_transitioning_returns_true_when_loading() -> void:
	_stm._state = SceneTransitionManager.State.LOADING
	assert_true(_stm.is_transitioning())


func test_ac2_is_transitioning_returns_true_when_fading_in() -> void:
	_stm._state = SceneTransitionManager.State.FADING_IN
	assert_true(_stm.is_transitioning())


# ---------------------------------------------------------------------------
# AC-5a: Scene root set to PROCESS_MODE_DISABLED when transition starts
# ---------------------------------------------------------------------------

func test_ac5a_set_scene_process_mode_disabled_applies_to_mock_scene() -> void:
	# Simulates what _begin_fade_out() does to the active scene root.
	var mock_scene := Node.new()
	add_child_autoqfree(mock_scene)
	_stm._set_scene_process_mode(mock_scene, Node.PROCESS_MODE_DISABLED)
	assert_eq(mock_scene.process_mode, Node.PROCESS_MODE_DISABLED,
			"_set_scene_process_mode(DISABLED) must set process_mode on the target node")


func test_ac5a_set_scene_process_mode_null_safe() -> void:
	# Must not crash when scene is null (e.g., transitioning from title screen)
	_stm._set_scene_process_mode(null, Node.PROCESS_MODE_DISABLED)
	assert_true(true, "null-safe: no crash when scene argument is null")


# ---------------------------------------------------------------------------
# AC-5b: New scene root set to PROCESS_MODE_INHERIT after transition completes
# ---------------------------------------------------------------------------

func test_ac5b_set_scene_process_mode_inherit_restores_node() -> void:
	# Simulates what _begin_fade_in() does to the arriving scene root.
	var mock_scene := Node.new()
	add_child_autoqfree(mock_scene)
	mock_scene.process_mode = Node.PROCESS_MODE_DISABLED
	_stm._set_scene_process_mode(mock_scene, Node.PROCESS_MODE_INHERIT)
	assert_eq(mock_scene.process_mode, Node.PROCESS_MODE_INHERIT,
			"_set_scene_process_mode(INHERIT) must restore process_mode on arrival")


# ---------------------------------------------------------------------------
# AC-5c: SceneTransitionManager itself PROCESS_MODE_ALWAYS
# ---------------------------------------------------------------------------

func test_ac5c_manager_process_mode_is_always_after_ready() -> void:
	# _ready() must set PROCESS_MODE_ALWAYS so polling continues during tree pause.
	assert_eq(_stm.process_mode, Node.PROCESS_MODE_ALWAYS,
			"SceneTransitionManager must run even when game tree is paused")


# ---------------------------------------------------------------------------
# AC-6: Error recovery on THREAD_LOAD_FAILED
# ---------------------------------------------------------------------------

func test_ac6_load_failed_sets_state_to_idle() -> void:
	# Given: mid-load state
	_stm._state = SceneTransitionManager.State.LOADING
	_stm._target_path = "res://scenes/nonexistent.tscn"
	# When: ResourceLoader reports failure
	_stm._handle_load_status(ResourceLoader.THREAD_LOAD_FAILED)
	# push_error("failed to load scene: ...") is the expected logging path — consume it.
	assert_push_error_count(1)
	# Then: state returns to IDLE (no crash, no stuck state)
	assert_eq(_stm._state, SceneTransitionManager.State.IDLE,
			"THREAD_LOAD_FAILED must return FSM to IDLE")


func test_ac6_load_failed_overlay_remains_visible() -> void:
	# Overlay must stay visible (black screen) so the player sees no glitch.
	_stm._state = SceneTransitionManager.State.LOADING
	_stm._overlay.visible = true
	_stm._handle_load_status(ResourceLoader.THREAD_LOAD_FAILED)
	# push_error("failed to load scene: ...") is the expected logging path — consume it.
	assert_push_error_count(1)
	assert_true(_stm._overlay.visible,
			"overlay must remain visible after failure — no premature fade-in")


func test_ac6_handle_load_status_in_progress_does_nothing() -> void:
	# THREAD_LOAD_IN_PROGRESS must be silently ignored (stay LOADING).
	_stm._state = SceneTransitionManager.State.LOADING
	_stm._handle_load_status(ResourceLoader.THREAD_LOAD_IN_PROGRESS)
	assert_eq(_stm._state, SceneTransitionManager.State.LOADING,
			"IN_PROGRESS status must leave FSM in LOADING")


func test_ac6_initial_state_is_idle() -> void:
	# Sanity: fresh instance must start in IDLE before any transition.
	assert_eq(_stm._state, SceneTransitionManager.State.IDLE,
			"SceneTransitionManager must initialise in IDLE state")
