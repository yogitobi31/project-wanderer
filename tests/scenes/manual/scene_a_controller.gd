extends Node

# TC-1, TC-3: SceneB_Full with spawn_id "inn"
func _on_btn_to_b_full_pressed() -> void:
	SceneTransitionManager.request_transition(
		"res://tests/scenes/manual/SceneB_Full.tscn", "inn"
	)

# TC-4: SceneB_DefaultOnly — spawn_id "inn" doesn't exist, falls back to default
func _on_btn_to_b_default_pressed() -> void:
	SceneTransitionManager.request_transition(
		"res://tests/scenes/manual/SceneB_DefaultOnly.tscn", "inn"
	)

# TC-5: SceneB_Empty — no spawn points at all
func _on_btn_to_b_empty_pressed() -> void:
	SceneTransitionManager.request_transition(
		"res://tests/scenes/manual/SceneB_Empty.tscn", "inn"
	)

# TC-2: triggers a second request mid-transition (attach to a separate button)
func _on_btn_interrupt_pressed() -> void:
	SceneTransitionManager.request_transition(
		"res://tests/scenes/manual/SceneB_Empty.tscn", ""
	)
