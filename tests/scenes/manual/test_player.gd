extends Node2D

var _pos_label: Label

func _ready() -> void:
	add_to_group("player")
	_pos_label = Label.new()
	_pos_label.name = "PosLabel"
	add_child(_pos_label)
	_update_label()

func set_spawn_position(pos: Vector2) -> void:
	global_position = pos
	_update_label()

func _update_label() -> void:
	if _pos_label:
		_pos_label.text = "Player pos: %s" % str(global_position)
