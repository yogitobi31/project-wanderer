## Unit tests for SceneTransitionManager SpawnPoint resolution (story-002):
## _resolve_spawn_position() pure-function contract covering AC-4 and edge cases.
##
## AC-1 (fade sequence order) and AC-3 (named spawn placement) require a live
## scene and are validated via manual playtest — see:
##   production/qa/evidence/scene-transition-spawn-evidence.md

class_name SceneTransitionSpawnTest
extends GutTest

var _stm: SceneTransitionManager


func before_each() -> void:
	# load() avoids Autoload-name-shadowing: SceneTransitionManager as a class_name + Autoload
	# means SceneTransitionManager.new() would call .new() on the singleton, which fails.
	_stm = load("res://src/core/scene_transition_manager.gd").new()
	add_child_autoqfree(_stm)


func after_each() -> void:
	pass  # freed by autoqfree


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_spawn_marker(node_name: String, pos: Vector2) -> Marker2D:
	var m := Marker2D.new()
	m.name = node_name
	add_child_autoqfree(m)  # must enter tree before setting global_position
	m.global_position = pos
	return m


func _make_non_marker(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	add_child_autoqfree(n)
	return n


# ---------------------------------------------------------------------------
# Named id lookup
# ---------------------------------------------------------------------------

func test_resolve_spawn_named_id_found_returns_marker_position() -> void:
	# Arrange
	var m := _make_spawn_marker("SpawnPoint_inn", Vector2(200.0, 300.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([m], "inn")
	# Assert
	assert_eq(result, Vector2(200.0, 300.0),
			"named id 'inn' must return the matching Marker2D position")


func test_resolve_spawn_named_id_found_among_multiple_nodes_returns_correct_position() -> void:
	# Arrange
	var default_m := _make_spawn_marker("SpawnPoint_Default", Vector2(0.0, 0.0))
	var entrance_m := _make_spawn_marker("SpawnPoint_entrance", Vector2(100.0, 50.0))
	var exit_m := _make_spawn_marker("SpawnPoint_exit", Vector2(400.0, 200.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position(
			[default_m, entrance_m, exit_m], "entrance")
	# Assert
	assert_eq(result, Vector2(100.0, 50.0),
			"must return the position of SpawnPoint_entrance, not another node")


# ---------------------------------------------------------------------------
# Default fallback
# ---------------------------------------------------------------------------

func test_resolve_spawn_named_id_missing_falls_back_to_default() -> void:
	# Arrange
	var default_m := _make_spawn_marker("SpawnPoint_Default", Vector2(10.0, 20.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([default_m], "nonexistent_id")
	# Assert
	assert_eq(result, Vector2(10.0, 20.0),
			"missing named id must fall back to SpawnPoint_Default")


func test_resolve_spawn_empty_id_uses_spawn_point_default() -> void:
	# Arrange: empty id skips named lookup entirely — resolves Default directly
	var default_m := _make_spawn_marker("SpawnPoint_Default", Vector2(75.0, 125.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([default_m], "")
	# Assert
	assert_eq(result, Vector2(75.0, 125.0),
			"empty id must resolve SpawnPoint_Default without named lookup")


# ---------------------------------------------------------------------------
# Vector2.ZERO fallback — push_warning expected in each case below
# ---------------------------------------------------------------------------

func test_resolve_spawn_empty_array_nonexistent_id_returns_zero() -> void:
	var result: Vector2 = _stm._resolve_spawn_position([], "nonexistent_id")
	assert_eq(result, Vector2.ZERO,
			"empty array with unknown id must return Vector2.ZERO")


func test_resolve_spawn_empty_array_empty_id_returns_zero() -> void:
	var result: Vector2 = _stm._resolve_spawn_position([], "")
	assert_eq(result, Vector2.ZERO,
			"empty array with empty id must return Vector2.ZERO")


func test_resolve_spawn_named_id_missing_no_default_returns_zero() -> void:
	# Arrange: only an unrelated spawn point — push_warning will fire
	var other_m := _make_spawn_marker("SpawnPoint_other", Vector2(50.0, 50.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([other_m], "nonexistent_id")
	# Assert
	assert_eq(result, Vector2.ZERO,
			"no named match and no Default must return Vector2.ZERO")


func test_resolve_spawn_empty_id_no_default_returns_zero() -> void:
	# Arrange: only a named spawn exists, no Default — push_warning will fire
	var inn_m := _make_spawn_marker("SpawnPoint_inn", Vector2(200.0, 300.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([inn_m], "")
	# Assert
	assert_eq(result, Vector2.ZERO,
			"empty id with no SpawnPoint_Default must return Vector2.ZERO")


# ---------------------------------------------------------------------------
# Node type guard — non-Marker2D nodes are ignored
# ---------------------------------------------------------------------------

func test_resolve_spawn_non_marker2d_named_node_is_ignored_returns_zero() -> void:
	# Arrange: Node2D has the right name but wrong type — push_warning will fire
	var bad_node := _make_non_marker("SpawnPoint_inn")
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([bad_node], "inn")
	# Assert
	assert_eq(result, Vector2.ZERO,
			"non-Marker2D node with matching name must not be treated as a spawn point")


func test_resolve_spawn_non_marker2d_default_node_is_ignored_returns_zero() -> void:
	# Arrange: Node2D named SpawnPoint_Default — push_warning will fire
	var bad_default := _make_non_marker("SpawnPoint_Default")
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([bad_default], "")
	# Assert
	assert_eq(result, Vector2.ZERO,
			"non-Marker2D SpawnPoint_Default must not be used as fallback")


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_resolve_spawn_marker_at_origin_is_valid_not_confused_with_no_match() -> void:
	# Arrange: SpawnPoint_origin is AT (0,0) — must not be confused with ZERO fallback
	var origin_m := _make_spawn_marker("SpawnPoint_origin", Vector2(0.0, 0.0))
	var default_m := _make_spawn_marker("SpawnPoint_Default", Vector2(99.0, 99.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([origin_m, default_m], "origin")
	# Assert
	assert_eq(result, Vector2(0.0, 0.0),
			"Marker2D at (0,0) is a valid result — must not fall through to Default")


func test_resolve_spawn_partial_name_does_not_match_requires_exact() -> void:
	# Arrange: "SpawnPoint_inner_gate" must not match id="inn" — push_warning will fire
	var inner_gate_m := _make_spawn_marker("SpawnPoint_inner_gate", Vector2(300.0, 400.0))
	# Act
	var result: Vector2 = _stm._resolve_spawn_position([inner_gate_m], "inn")
	# Assert
	assert_eq(result, Vector2.ZERO,
			"'SpawnPoint_inner_gate' must not match id='inn' — exact name match required")
