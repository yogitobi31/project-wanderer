extends Node

func _on_btn_back_pressed() -> void:
	SceneTransitionManager.request_transition(
		"res://tests/scenes/manual/SceneA.tscn", ""
	)
