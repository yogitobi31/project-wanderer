extends GutTest

## Unit tests for SaveManager (ADR-0007, TR-save-001~006).
##
## Tests are isolated: each test cleans up the save file before and after.
## Inventory state is set directly on _items to bypass ItemDB validation.

const SAVE_PATH: String = "user://saves/save_001.json"


func before_each() -> void:
	_cleanup()
	PartyManager._companions.clear()
	Inventory._items.clear()
	SaveManager._player_location = {}


func after_each() -> void:
	_cleanup()
	PartyManager._companions.clear()
	Inventory._items.clear()
	SaveManager._player_location = {}


func _cleanup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# TR-save-005: has_save() returns false before any save
func test_has_save_false_before_first_save() -> void:
	assert_false(SaveManager.has_save(), "has_save() must return false before any save")


# TR-save-001: save_game() creates file at SAVE_PATH
func test_save_game_creates_file() -> void:
	var result: bool = SaveManager.save_game()
	assert_true(result, "save_game() must return true on success")
	assert_true(FileAccess.file_exists(SAVE_PATH), "save file must exist after save_game()")


# TR-save-005: has_save() returns true after save
func test_has_save_true_after_save() -> void:
	SaveManager.save_game()
	assert_true(SaveManager.has_save(), "has_save() must return true after save_game()")


# TR-save-002: saved JSON contains save_version == SAVE_VERSION (1)
func test_save_game_embeds_correct_version() -> void:
	SaveManager.save_game()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_text: String = file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(json_text)
	assert_true(data is Dictionary, "saved content must be a Dictionary")
	assert_eq(int(data.get("save_version", -1)), 1, "save_version must equal SAVE_VERSION=1")


# TR-save-006: delete_save() removes the file
func test_delete_save_removes_file() -> void:
	SaveManager.save_game()
	var result: bool = SaveManager.delete_save()
	assert_true(result, "delete_save() must return true")
	assert_false(FileAccess.file_exists(SAVE_PATH), "file must not exist after delete_save()")


# delete_save() on missing file returns true without error
func test_delete_save_noop_when_no_file() -> void:
	var result: bool = SaveManager.delete_save()
	assert_true(result, "delete_save() on missing file must return true")


# load_game() returns false when no save file exists
func test_load_game_returns_false_when_no_file() -> void:
	var result: bool = SaveManager.load_game()
	assert_false(result, "load_game() must return false when save file is absent")


# load_game() returns false on invalid JSON
func test_load_game_returns_false_on_invalid_json() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("not{{{valid json")
	file.close()
	assert_false(SaveManager.load_game(), "load_game() must return false on invalid JSON")


# load_game() returns false on mismatched version
func test_load_game_returns_false_on_wrong_version() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 99}))
	file.close()
	assert_false(SaveManager.load_game(), "load_game() must return false on wrong save_version")


# TR-save-004: PartyManager companion list survives save → load round-trip
func test_save_load_roundtrip_party_manager() -> void:
	PartyManager._companions.append(&"aria")
	SaveManager.save_game()
	PartyManager._companions.clear()
	var result: bool = SaveManager.load_game()
	assert_true(result, "load_game() must return true")
	assert_true(PartyManager.is_recruited(&"aria"), "companion must be restored after load")


# TR-save-003: Inventory items survive save → load round-trip
func test_save_load_roundtrip_inventory() -> void:
	Inventory._items[&"herb_moonleaf"] = 3
	SaveManager.save_game()
	Inventory._items.clear()
	var result: bool = SaveManager.load_game()
	assert_true(result, "load_game() must return true")
	assert_eq(Inventory.get_quantity(&"herb_moonleaf"), 3, "item quantity must be restored after load")


# R-09: StringName companion IDs survive JSON String round-trip
func test_party_manager_stringname_json_roundtrip() -> void:
	PartyManager._companions.append(&"mira")
	SaveManager.save_game()
	PartyManager._companions.clear()
	SaveManager.load_game()
	assert_true(
		PartyManager.is_recruited(&"mira"),
		"StringName must survive JSON String round-trip via explicit StringName() cast"
	)


# record_player_location() data survives save → load
func test_record_player_location_roundtrip() -> void:
	SaveManager.record_player_location("res://scenes/village.tscn", Vector2(128.0, 64.0))
	SaveManager.save_game()
	SaveManager._player_location = {}
	SaveManager.load_game()
	var loc: Dictionary = SaveManager.get_player_location()
	assert_eq(loc.get("scene"), "res://scenes/village.tscn", "scene path must be restored")
	assert_almost_eq(float(loc.get("position_x", 0.0)), 128.0, 0.001, "position_x must be restored")
	assert_almost_eq(float(loc.get("position_y", 0.0)), 64.0, 0.001, "position_y must be restored")


# Empty party saves and loads without error
func test_empty_party_roundtrip() -> void:
	SaveManager.save_game()
	SaveManager.load_game()
	assert_eq(PartyManager.companion_count, 0, "empty party must remain empty after load")
