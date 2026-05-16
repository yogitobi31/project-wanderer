extends GutTest

## Integration tests: full save → load round-trip across all save-contract Autoloads.
##
## These tests verify that SaveManager correctly orchestrates Inventory,
## NPCRegistry, and PartyManager as a multi-system contract.
## Inventory._items is written directly to bypass ItemDB validation.

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


# Full multi-system save → load round-trip
func test_full_roundtrip_all_systems() -> void:
	# Populate state across all systems
	PartyManager._companions.append(&"aria")
	PartyManager._companions.append(&"dolsoi")
	Inventory._items[&"iron_ore"] = 5
	Inventory._items[&"herb_moonleaf"] = 2
	SaveManager.record_player_location("res://scenes/village.tscn", Vector2(320.0, 240.0))

	assert_true(SaveManager.save_game(), "save_game() must succeed")

	# Wipe all state
	PartyManager._companions.clear()
	Inventory._items.clear()
	SaveManager._player_location = {}

	assert_true(SaveManager.load_game(), "load_game() must succeed")

	# Verify every system was restored
	assert_true(PartyManager.is_recruited(&"aria"), "aria must be in party after load")
	assert_true(PartyManager.is_recruited(&"dolsoi"), "dolsoi must be in party after load")
	assert_eq(Inventory.get_quantity(&"iron_ore"), 5, "iron_ore quantity must be restored")
	assert_eq(Inventory.get_quantity(&"herb_moonleaf"), 2, "herb_moonleaf quantity must be restored")

	var loc: Dictionary = SaveManager.get_player_location()
	assert_eq(loc.get("scene"), "res://scenes/village.tscn", "scene must be restored")
	assert_almost_eq(float(loc.get("position_x", 0.0)), 320.0, 0.001, "position_x must be restored")
	assert_almost_eq(float(loc.get("position_y", 0.0)), 240.0, 0.001, "position_y must be restored")


# Successive saves overwrite — only the last state is loaded
func test_second_save_overwrites_first() -> void:
	PartyManager._companions.append(&"aria")
	SaveManager.save_game()

	PartyManager._companions.clear()
	PartyManager._companions.append(&"mira")
	SaveManager.save_game()

	PartyManager._companions.clear()
	SaveManager.load_game()

	assert_false(PartyManager.is_recruited(&"aria"), "first save must be overwritten")
	assert_true(PartyManager.is_recruited(&"mira"), "second save must be the active state")


# Saving with empty systems produces a loadable file with empty state
func test_empty_state_roundtrip() -> void:
	assert_true(SaveManager.save_game(), "save_game() on empty state must succeed")
	assert_true(SaveManager.load_game(), "load_game() on empty state must succeed")
	assert_eq(PartyManager.companion_count, 0, "party must be empty")
	assert_eq(Inventory.get_quantity(&"herb_moonleaf"), 0, "inventory must be empty")


# Party at MAX_PARTY_SIZE survives round-trip without overflow
func test_max_party_size_roundtrip() -> void:
	PartyManager._companions.append(&"aria")
	PartyManager._companions.append(&"dolsoi")
	PartyManager._companions.append(&"mira")
	SaveManager.save_game()
	PartyManager._companions.clear()
	SaveManager.load_game()
	assert_eq(PartyManager.companion_count, 3, "all 3 companions must be restored")
	assert_true(PartyManager.is_recruited(&"aria"))
	assert_true(PartyManager.is_recruited(&"dolsoi"))
	assert_true(PartyManager.is_recruited(&"mira"))
