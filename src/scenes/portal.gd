class_name Portal
extends Area2D

## Scene transition trigger for map portals.
##
## Implements TR-map-003 (design/gdd/맵-지역-시스템.md, ADR-0003):
##   - A physics body in the "player" group entering the Area2D requests a scene
##     transition via SceneTransitionManager.request_transition().
##   - Transition is blocked when DialogueManager.is_active is true.
##   - change_scene_to_file() / change_scene_to_packed() direct calls are FORBIDDEN
##     (control-manifest S.Foundation Forbidden) - all transitions go through
##     SceneTransitionManager.
##
## Required scene structure (configure in editor):
##   Portal_{target} (Area2D - this script, Layer=player_body(2), Mask=player_body(2))
##   +-- CollisionShape2D
##
## Place under the Portals (Node2D) container in any map scene per ADR-0003 S.맵 구조 계약.
##
## Usage:
##   1. Add Portal.tscn as a child of Portals in your map scene.
##   2. Set target_scene_path and target_spawn_name in the Inspector.
##   3. body_entered is auto-connected in _ready() - no manual wiring needed.
##
## Example:
##   portal.target_scene_path = "res://src/scenes/town.tscn"
##   portal.target_spawn_name = "south_entrance"   # -> SpawnPoint_south_entrance

# ---------------------------------------------------------------------------
# Exports - data-driven per coding-standards (no hardcoded scene paths)
# ---------------------------------------------------------------------------

## Full resource path to the destination scene.
## Example: "res://src/scenes/dungeon.tscn"
## An empty string is logged as an error at trigger time and aborts the transition.
@export var target_scene_path: String = ""

## Spawn point id suffix for the destination scene.
## Example: "north_gate" resolves to SpawnPoint_north_gate in the new scene.
## Pass "" to use SpawnPoint_Default (ADR-0003 S.SpawnPoint 계약).
@export var target_spawn_name: String = ""

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-16, -24, 32, 48), Color(1.0, 0.9, 0.1, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(-18, -28), "PORTAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)

func _ready() -> void:
	queue_redraw()
	body_entered.connect(_on_body_entered)

# ---------------------------------------------------------------------------
# Signal handler
# ---------------------------------------------------------------------------

## Fires when a physics body enters the portal collision shape.
##
## Delegates to [method _can_trigger] for guard conditions, then calls
## [method SceneTransitionManager.request_transition] to begin the transition.
## Does NOT call change_scene_to_file() or change_scene_to_packed() directly
## (forbidden per ADR-0003 and control-manifest).
func _on_body_entered(body: Node2D) -> void:
	if not _can_trigger(body):
		return
	if target_scene_path.is_empty():
		push_error("[Portal] target_scene_path is empty - transition aborted. " +
				"Set target_scene_path in the Inspector.")
		return
	SceneTransitionManager.request_transition(target_scene_path, target_spawn_name)

# ---------------------------------------------------------------------------
# Internal - extracted for unit testability (ADR-0003, story-002 S.QA Test Cases)
# ---------------------------------------------------------------------------

## Returns true when all preconditions for a scene transition are met.
##
## Preconditions (both must pass):
##   1. [param body] is in the "player" group - avoids hard coupling to
##      PlayerController class (ADR-0003 S.포탈 진입 조건 uses is_in_group pattern).
##   2. DialogueManager.is_active is false - blocks portal during active dialogue
##      (ADR-0003 S.포탈 진입 조건, control-manifest S.Feature Forbidden).
##      Null-safe: if DialogueManager is not yet initialised the check is skipped
##      and the portal is allowed to trigger (EC-5 pattern from 씬전환-시스템.md).
##
## Extracted from [method _on_body_entered] so unit tests can inject mock Node2D
## instances without requiring a live SceneTree - same pattern as
## SceneTransitionManager._resolve_spawn_position().
##
## Example:
##   var mock_player := Node2D.new()
##   mock_player.add_to_group(&"player")
##   assert_true(portal._can_trigger(mock_player))
func _can_trigger(body: Node2D) -> bool:
	# Guard 1: only the player triggers scene transitions (ADR-0003 S.TR-map-003).
	if not body.is_in_group(&"player"):
		return false

	# Guard 2: block transition during active dialogue (ADR-0003 S.TR-map-003).
	# Null-safe: DialogueManager may not be initialised in early development.
	# Treat missing DialogueManager as is_active = false (permissive - EC-5 pattern).
	var dm: Node = get_node_or_null("/root/DialogueManager")
	if dm != null and dm.get("is_active"):
		return false

	return true
