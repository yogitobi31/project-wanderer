class_name PortalTransitionTest
extends GutTest

## Unit tests for Portal._can_trigger() (map-scene/story-002, TR-map-003):
## AC-1 — player-group body enters portal → _can_trigger() returns true.
## AC-2 — DialogueManager.is_active == true → _can_trigger() returns false.
##
## _can_trigger() is a pure-function helper extracted from _on_body_entered()
## so tests can inject mock Node2D instances without a live SceneTree, exactly
## as SceneTransitionManager._resolve_spawn_position() is tested in
## scene_transition_spawn_test.gd.
##
## Tests that require SceneTransitionManager.request_transition() to be called
## (AC-1 end-to-end) are covered by manual playtest — the signal contract and
## transition FSM are verified by scene_transition_fsm_test.gd.

var _portal: Portal


func before_each() -> void:
	_portal = Portal.new()
	# add_child_autoqfree triggers _ready(), which connects body_entered.
	# That connection is harmless headlessly — nothing emits body_entered in these tests.
	add_child_autoqfree(_portal)


func after_each() -> void:
	pass  # freed by autoqfree


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_player_body() -> Node2D:
	var body := Node2D.new()
	body.add_to_group(&"player")
	add_child_autoqfree(body)
	return body


func _make_npc_body() -> Node2D:
	var body := Node2D.new()
	# intentionally NOT added to "player" group
	add_child_autoqfree(body)
	return body


# ---------------------------------------------------------------------------
# AC-1: Player body in "player" group triggers transition
# ---------------------------------------------------------------------------

func test_portal_can_trigger_player_group_body_returns_true() -> void:
	# Arrange
	var player := _make_player_body()
	# Act
	var result: bool = _portal._can_trigger(player)
	# Assert
	assert_true(result,
			"_can_trigger() must return true when body is in the 'player' group")


func test_portal_can_trigger_non_player_body_returns_false() -> void:
	# Arrange — NPC body not in "player" group
	var npc := _make_npc_body()
	# Act
	var result: bool = _portal._can_trigger(npc)
	# Assert
	assert_false(result,
			"_can_trigger() must return false when body is NOT in the 'player' group")


func test_portal_can_trigger_enemy_body_returns_false() -> void:
	# Arrange — enemy body with its own group, not "player"
	var enemy := Node2D.new()
	enemy.add_to_group(&"enemy")
	add_child_autoqfree(enemy)
	# Act
	var result: bool = _portal._can_trigger(enemy)
	# Assert
	assert_false(result,
			"_can_trigger() must return false for a body only in the 'enemy' group")


# ---------------------------------------------------------------------------
# AC-1 supplementary: player body must pass when no DialogueManager present
# ---------------------------------------------------------------------------

func test_portal_can_trigger_missing_dialogue_manager_does_not_block() -> void:
	# Arrange — DialogueManager is not registered (EC-5 null-safe pattern).
	# get_node_or_null("/root/DialogueManager") returns null in GUT headless context.
	var player := _make_player_body()
	# Act
	var result: bool = _portal._can_trigger(player)
	# Assert
	assert_true(result,
			"missing DialogueManager must not block the portal (EC-5 null-safe pattern)")


# ---------------------------------------------------------------------------
# AC-2: DialogueManager.is_active == true blocks transition
# ---------------------------------------------------------------------------

func test_portal_can_trigger_dialogue_active_blocks_player_body() -> void:
	# Arrange — DialogueManager is already registered as Autoload at /root/DialogueManager.
	# Adding a mock with the same name fails silently (Godot renames it to DialogueManager2).
	# Use the singleton directly instead.
	var original_active: bool = DialogueManager.is_active
	DialogueManager.is_active = true

	var player := _make_player_body()

	# Act
	var result: bool = _portal._can_trigger(player)

	# Cleanup
	DialogueManager.is_active = original_active

	# Assert
	assert_false(result,
			"_can_trigger() must return false when DialogueManager.is_active is true")


func test_portal_can_trigger_dialogue_inactive_allows_player_body() -> void:
	# Arrange — use the Autoload singleton directly (is_active = false by default).
	var original_active: bool = DialogueManager.is_active
	DialogueManager.is_active = false

	var player := _make_player_body()

	# Act
	var result: bool = _portal._can_trigger(player)

	# Cleanup
	DialogueManager.is_active = original_active

	# Assert
	assert_true(result,
			"_can_trigger() must return true when DialogueManager.is_active is false")


func test_portal_can_trigger_dialogue_active_does_not_block_non_player() -> void:
	# Arrange — even if dialogue is active the non-player guard fires first.
	var original_active: bool = DialogueManager.is_active
	DialogueManager.is_active = true

	var npc := _make_npc_body()

	# Act
	var result: bool = _portal._can_trigger(npc)

	# Cleanup
	DialogueManager.is_active = original_active

	# Assert
	assert_false(result,
			"_can_trigger() must return false for a non-player body regardless of dialogue state")


# ---------------------------------------------------------------------------
# AC-3: target_scene_path and target_spawn_name are configurable (data-driven)
# ---------------------------------------------------------------------------

func test_portal_default_target_scene_path_is_empty_string() -> void:
	# Arrange — fresh Portal instance, no Inspector values set
	# Assert
	assert_eq(_portal.target_scene_path, "",
			"default target_scene_path must be an empty string")


func test_portal_default_target_spawn_name_is_empty_string() -> void:
	assert_eq(_portal.target_spawn_name, "",
			"default target_spawn_name must be an empty string (resolves to SpawnPoint_Default)")


func test_portal_target_scene_path_is_assignable() -> void:
	# Arrange
	_portal.target_scene_path = "res://src/scenes/town.tscn"
	# Assert
	assert_eq(_portal.target_scene_path, "res://src/scenes/town.tscn",
			"target_scene_path must accept and retain an assigned value")


func test_portal_target_spawn_name_is_assignable() -> void:
	# Arrange
	_portal.target_spawn_name = "north_gate"
	# Assert
	assert_eq(_portal.target_spawn_name, "north_gate",
			"target_spawn_name must accept and retain an assigned value")
