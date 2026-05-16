extends GutTest

## Unit tests for Inventory save/load contract — AC-1 through AC-4 (story-002-save-load-contract).
##
## ItemDB is mocked via Engine.register_singleton so Inventory.add_item() can call
## ItemDB.has() without requiring the real assets/data/items/ directory.

# ---------------------------------------------------------------------------
# Mock
# ---------------------------------------------------------------------------

class MockItemDB extends Node:
	func has(item_id: StringName) -> bool:
		return item_id in [&"herb_moonleaf", &"old_key"]


# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

var _inventory: Inventory
var _mock_db: MockItemDB
var _prev_singleton: Object = null


func before_each() -> void:
	_mock_db = MockItemDB.new()
	add_child(_mock_db)

	if Engine.has_singleton(&"ItemDB"):
		_prev_singleton = Engine.get_singleton(&"ItemDB")
		Engine.unregister_singleton(&"ItemDB")
	Engine.register_singleton(&"ItemDB", _mock_db)

	_inventory = load("res://src/core/inventory.gd").new()
	add_child(_inventory)


func after_each() -> void:
	_inventory.queue_free()
	Engine.unregister_singleton(&"ItemDB")
	if _prev_singleton != null:
		Engine.register_singleton(&"ItemDB", _prev_singleton)
		_prev_singleton = null
	_mock_db.queue_free()


# ---------------------------------------------------------------------------
# AC-1: get_save_data returns correct structure
# ---------------------------------------------------------------------------

func test_get_save_data_returns_items_array_with_correct_entry() -> void:
	_inventory.add_item(&"herb_moonleaf", 5)
	var data: Dictionary = _inventory.get_save_data()
	assert_true(data.has("items"), "get_save_data should return a dict with 'items' key")
	var items: Array = data["items"]
	assert_eq(items.size(), 1, "items array should have exactly one entry")
	assert_eq(items[0]["item_id"], "herb_moonleaf",
			"item_id should be serialized as String (not StringName)")
	assert_eq(items[0]["quantity"], 5, "quantity should match what was added")


func test_get_save_data_empty_inventory_returns_empty_items_array() -> void:
	var data: Dictionary = _inventory.get_save_data()
	assert_true(data.has("items"), "get_save_data should always include 'items' key")
	assert_eq(data["items"].size(), 0, "empty inventory should produce empty items array")


func test_get_save_data_multiple_items_all_included() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	_inventory.add_item(&"old_key", 1)
	var data: Dictionary = _inventory.get_save_data()
	var items: Array = data["items"]
	assert_eq(items.size(), 2, "both items should appear in save data")


# ---------------------------------------------------------------------------
# AC-2: load_save_data restores inventory state
# ---------------------------------------------------------------------------

func test_load_save_data_restores_quantity() -> void:
	_inventory.load_save_data({"items": [{"item_id": "herb_moonleaf", "quantity": 3}]})
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 3,
			"get_quantity should reflect the loaded value")


func test_load_save_data_sets_has_item_true() -> void:
	_inventory.load_save_data({"items": [{"item_id": "herb_moonleaf", "quantity": 2}]})
	assert_true(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return true after load_save_data")


func test_load_save_data_clears_previous_state() -> void:
	_inventory.add_item(&"old_key", 10)
	_inventory.load_save_data({"items": [{"item_id": "herb_moonleaf", "quantity": 1}]})
	assert_eq(_inventory.get_quantity(&"old_key"), 0,
			"items not in save data should be cleared on load")


# ---------------------------------------------------------------------------
# AC-3: roundtrip — load_save_data(get_save_data()) preserves state
# ---------------------------------------------------------------------------

func test_roundtrip_preserves_quantity() -> void:
	_inventory.add_item(&"herb_moonleaf", 7)
	var snapshot: Dictionary = _inventory.get_save_data()
	_inventory.load_save_data(snapshot)
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 7,
			"quantity should be identical after a save/load roundtrip")


func test_roundtrip_through_json_stringify_parse() -> void:
	_inventory.add_item(&"herb_moonleaf", 4)
	_inventory.add_item(&"old_key", 2)
	var json_string: String = JSON.stringify(_inventory.get_save_data())
	var parsed: Variant = JSON.parse_string(json_string)
	assert_true(parsed is Dictionary, "JSON.parse_string should return a Dictionary")
	_inventory.load_save_data(parsed as Dictionary)
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 4,
			"herb_moonleaf quantity should survive JSON roundtrip")
	assert_eq(_inventory.get_quantity(&"old_key"), 2,
			"old_key quantity should survive JSON roundtrip")


func test_roundtrip_empty_inventory() -> void:
	var snapshot: Dictionary = _inventory.get_save_data()
	_inventory.load_save_data(snapshot)
	assert_eq(_inventory.get_save_data()["items"].size(), 0,
			"empty inventory roundtrip should remain empty")


# ---------------------------------------------------------------------------
# AC-4: load_save_data({}) — empty dict, no error, empty inventory
# ---------------------------------------------------------------------------

func test_load_save_data_empty_dict_produces_empty_inventory() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	_inventory.load_save_data({})
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"inventory should be empty after loading empty dict")
	assert_false(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return false after loading empty dict")


func test_load_save_data_empty_dict_does_not_crash() -> void:
	# If this test runs without error, the empty-dict case is handled defensively.
	_inventory.load_save_data({})
	assert_true(true, "load_save_data({}) should not throw any errors")


func test_load_save_data_skips_zero_quantity_entries() -> void:
	_inventory.load_save_data({"items": [{"item_id": "herb_moonleaf", "quantity": 0}]})
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"zero-quantity entries in save data should be ignored")
	assert_false(_inventory.has_item(&"herb_moonleaf"),
			"has_item should be false for zero-quantity save entries")


func test_load_save_data_skips_empty_item_id_entries() -> void:
	_inventory.load_save_data({"items": [{"item_id": "", "quantity": 5}]})
	assert_eq(_inventory.get_save_data()["items"].size(), 0,
			"entries with empty item_id should be ignored on load")
