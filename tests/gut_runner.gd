extends SceneTree

func _init() -> void:
	var gut_cli := load("res://addons/gut/cli/gut_cli.gd")
	if gut_cli == null:
		push_error("GUT not found. Install via AssetLib or addons/.")
		quit(1)
		return
	var cli = gut_cli.new()
	cli.run()
