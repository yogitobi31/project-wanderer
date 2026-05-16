extends GutTest

## Unit tests for DialogueManager state management (story-001, TR-dial-001).
##
## AC-1 — start_dialogue() sets is_active = true
## AC-2 — start_dialogue() sets InputMapManager.is_ui_active = true
## AC-3 — finish_dialogue() resets is_active and InputMapManager.is_ui_active to false
## AC-4 — CanvasLayer layer == 10

var _dm: DialogueManager


func before_each() -> void:
	_dm = load("res://src/ui/dialogue_manager.gd").new()
	add_child_autoqfree(_dm)
	InputMapManager.set_ui_active(false)


func after_each() -> void:
	InputMapManager.set_ui_active(false)


# ---------------------------------------------------------------------------
# AC-1: start_dialogue sets is_active
# ---------------------------------------------------------------------------

func test_dialogue_manager_is_active_false_by_default() -> void:
	assert_false(_dm.is_active,
			"AC-1: is_active must be false before any dialogue starts")


func test_dialogue_manager_start_dialogue_sets_is_active_true() -> void:
	# Arrange
	assert_false(_dm.is_active, "precondition: is_active must be false before start")
	# Act
	_dm.start_dialogue(&"npc_01")
	# Assert
	assert_true(_dm.is_active,
			"AC-1: start_dialogue() must set is_active = true")


# ---------------------------------------------------------------------------
# AC-2: start_dialogue activates UI input context
# ---------------------------------------------------------------------------

func test_dialogue_manager_start_dialogue_activates_ui_input() -> void:
	# Arrange
	assert_false(InputMapManager.is_ui_active,
			"precondition: InputMapManager.is_ui_active must be false before start")
	# Act
	_dm.start_dialogue(&"npc_01")
	# Assert
	assert_true(InputMapManager.is_ui_active,
			"AC-2: start_dialogue() must call InputMapManager.set_ui_active(true)")


# ---------------------------------------------------------------------------
# AC-3: finish_dialogue resets both flags and emits signal
# ---------------------------------------------------------------------------

func test_dialogue_manager_finish_dialogue_sets_is_active_false() -> void:
	# Arrange
	_dm.start_dialogue(&"npc_01")
	assert_true(_dm.is_active, "precondition: is_active must be true after start")
	# Act
	_dm.finish_dialogue(&"npc_01")
	# Assert
	assert_false(_dm.is_active,
			"AC-3: finish_dialogue() must set is_active = false")


func test_dialogue_manager_finish_dialogue_deactivates_ui_input() -> void:
	# Arrange
	_dm.start_dialogue(&"npc_01")
	assert_true(InputMapManager.is_ui_active,
			"precondition: UI input must be active after start")
	# Act
	_dm.finish_dialogue(&"npc_01")
	# Assert
	assert_false(InputMapManager.is_ui_active,
			"AC-3: finish_dialogue() must call InputMapManager.set_ui_active(false)")


func test_dialogue_manager_finish_dialogue_emits_dialogue_completed_with_npc_id() -> void:
	# Arrange
	_dm.start_dialogue(&"npc_aria")
	watch_signals(_dm)
	# Act
	_dm.finish_dialogue(&"npc_aria")
	# Assert
	assert_signal_emitted_with_parameters(_dm, "dialogue_completed", [&"npc_aria"])


func test_dialogue_manager_finish_dialogue_different_npc_id_emits_correctly() -> void:
	_dm.start_dialogue(&"npc_bran")
	watch_signals(_dm)
	_dm.finish_dialogue(&"npc_bran")
	assert_signal_emitted_with_parameters(_dm, "dialogue_completed", [&"npc_bran"])


func test_dialogue_manager_finish_without_start_is_safe() -> void:
	# finish_dialogue on an already-idle manager must not crash and must leave state clean
	_dm.finish_dialogue(&"npc_01")
	assert_false(_dm.is_active,
			"finish_dialogue() on an inactive manager must leave is_active = false")
	assert_false(InputMapManager.is_ui_active,
			"finish_dialogue() on an inactive manager must leave InputMapManager inactive")


# ---------------------------------------------------------------------------
# AC-4: CanvasLayer layer = 10
# ---------------------------------------------------------------------------

func test_dialogue_manager_layer_is_ten() -> void:
	assert_eq(_dm.layer, 10,
			"AC-4: DialogueManager CanvasLayer must have layer = 10 (ADR-0003)")
