extends Node

## Orchestrates game persistence (ADR-0007, TR-save-001~006).
##
## Collects save data from all Autoloads implementing the save contract
## (get_save_data() -> Dictionary, load_save_data(data: Dictionary) -> void)
## and writes a single JSON file to disk. SAVE_VERSION=1 is the only supported
## schema — version mismatches are rejected on load.
##
## Usage:
##   SaveManager.record_player_location("res://scenes/map.tscn", position)
##   SaveManager.save_game()
##   if SaveManager.has_save():
##       SaveManager.load_game()

const SAVE_PATH: String = "user://saves/save_001.json"
const SAVE_VERSION: int = 1

var _player_location: Dictionary = {}


## Returns true if a save file exists at SAVE_PATH.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Stores the player's current scene and pixel position for inclusion in the next save.
## Call this before save_game() when the player reaches a saveable point.
func record_player_location(scene_path: String, position: Vector2) -> void:
	_player_location = {
		"scene": scene_path,
		"position_x": position.x,
		"position_y": position.y,
	}


## Returns the player location recorded by the last record_player_location() call.
## Returns an empty Dictionary if no location has been recorded yet.
func get_player_location() -> Dictionary:
	return _player_location.duplicate()


## Collects state from all save-contract Autoloads and writes to SAVE_PATH.
##
## Returns true on success. Returns false and emits push_error if the directory
## cannot be created or the file cannot be opened for writing.
func save_game() -> bool:
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"player_location": _player_location,
		"inventory": Inventory.get_save_data(),
		"npc_registry": NPCRegistry.get_save_data(),
		"party_manager": PartyManager.get_save_data(),
	}

	var dir_path: String = SAVE_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error(
			"SaveManager: cannot open '%s' for writing (error %d)." % [
				SAVE_PATH, FileAccess.get_open_error()
			]
		)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return true


## Reads SAVE_PATH and restores all Autoload states.
##
## Returns false without modifying any Autoload if the file is missing,
## unreadable, contains invalid JSON, or has a mismatched save_version.
func load_game() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error(
			"SaveManager: cannot open '%s' for reading (error %d)." % [
				SAVE_PATH, FileAccess.get_open_error()
			]
		)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var save_data: Variant = JSON.parse_string(json_text)
	if not save_data is Dictionary:
		push_error("SaveManager: save file contains invalid JSON.")
		return false

	var version: int = int(save_data.get("save_version", 0))
	if version != SAVE_VERSION:
		push_error(
			"SaveManager: unsupported save version %d (expected %d)." % [version, SAVE_VERSION]
		)
		return false

	_player_location = save_data.get("player_location", {})
	Inventory.load_save_data(save_data.get("inventory", {}))
	NPCRegistry.load_save_data(save_data.get("npc_registry", {}))
	PartyManager.load_save_data(save_data.get("party_manager", {}))
	return true


## Removes the save file. Returns true if deleted or file did not exist.
## Returns false and emits push_error if deletion fails.
func delete_save() -> bool:
	if not has_save():
		return true
	var err: int = DirAccess.remove_absolute(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: failed to delete save file (error %d)." % err)
		return false
	return true
