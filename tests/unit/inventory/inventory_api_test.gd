extends GutTest

## Unit tests for Inventory Autoload — AC-1 through AC-8 (story-001-add-remove-api).
##
## ItemDB is mocked via Engine.register_singleton so Inventory.add_item() can call
## ItemDB.has() without requiring the real assets/data/items/ directory.

# ---------------------------------------------------------------------------
# Mock
# ---------------------------------------------------------------------------

class MockItemDB extends Node:
	## Recognises only the two item IDs used in these tests.
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
# AC-1: add_item stores quantity
# ---------------------------------------------------------------------------

func test_add_item_stores_correct_quantity() -> void:
	var ok: bool = _inventory.add_item(&"herb_moonleaf", 3)
	assert_true(ok, "add_item should return true for a registered item")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 3,
			"get_quantity should equal 3 after adding 3")


# ---------------------------------------------------------------------------
# AC-2: add_item accumulates (3 + 2 = 5)
# ---------------------------------------------------------------------------

func test_add_item_accumulates_quantity() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	_inventory.add_item(&"herb_moonleaf", 2)
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 5,
			"get_quantity should equal 5 after two adds (3 + 2)")


# ---------------------------------------------------------------------------
# AC-3: remove_item decrements quantity
# ---------------------------------------------------------------------------

func test_remove_item_decrements_quantity() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	var ok: bool = _inventory.remove_item(&"herb_moonleaf", 2)
	assert_true(ok, "remove_item should return true when sufficient quantity exists")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 1,
			"get_quantity should equal 1 after removing 2 from 3")


# ---------------------------------------------------------------------------
# AC-4: remove_item returns false when quantity insufficient; item unchanged
# ---------------------------------------------------------------------------

func test_remove_item_returns_false_when_quantity_insufficient() -> void:
	_inventory.add_item(&"herb_moonleaf", 1)
	var ok: bool = _inventory.remove_item(&"herb_moonleaf", 5)
	assert_false(ok, "remove_item should return false when requested quantity exceeds held quantity")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 1,
			"inventory should be unchanged after a failed remove")


func test_remove_item_returns_false_when_item_not_present() -> void:
	var ok: bool = _inventory.remove_item(&"herb_moonleaf", 1)
	assert_false(ok, "remove_item should return false when item is not present at all")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"get_quantity should remain 0 after a failed remove on absent item")


# ---------------------------------------------------------------------------
# AC-5: has_item returns true/false based on presence
# ---------------------------------------------------------------------------

func test_has_item_returns_true_when_item_present() -> void:
	_inventory.add_item(&"herb_moonleaf", 1)
	assert_true(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return true when quantity >= 1")


func test_has_item_returns_false_when_item_absent() -> void:
	assert_false(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return false when item was never added")


func test_has_item_returns_false_after_quantity_reaches_zero() -> void:
	_inventory.add_item(&"herb_moonleaf", 1)
	_inventory.remove_item(&"herb_moonleaf", 1)
	assert_false(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return false after removing all quantity")


# ---------------------------------------------------------------------------
# AC-6: add_item emits item_added signal
# ---------------------------------------------------------------------------

func test_add_item_emits_item_added_signal() -> void:
	watch_signals(_inventory)
	_inventory.add_item(&"herb_moonleaf", 3)
	assert_signal_emitted(_inventory, "item_added",
			"item_added signal should be emitted on successful add_item")


func test_add_item_emits_item_added_with_correct_args() -> void:
	watch_signals(_inventory)
	_inventory.add_item(&"herb_moonleaf", 3)
	assert_signal_emitted_with_parameters(_inventory, "item_added",
			[&"herb_moonleaf", 3])


# ---------------------------------------------------------------------------
# AC-7: remove_item emits item_removed signal on success
# ---------------------------------------------------------------------------

func test_remove_item_emits_item_removed_signal_on_success() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	watch_signals(_inventory)
	_inventory.remove_item(&"herb_moonleaf", 2)
	assert_signal_emitted(_inventory, "item_removed",
			"item_removed signal should be emitted on successful remove_item")


func test_remove_item_emits_item_removed_with_correct_args() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	watch_signals(_inventory)
	_inventory.remove_item(&"herb_moonleaf", 2)
	assert_signal_emitted_with_parameters(_inventory, "item_removed",
			[&"herb_moonleaf", 2])


func test_remove_item_does_not_emit_item_removed_on_failure() -> void:
	_inventory.add_item(&"herb_moonleaf", 1)
	watch_signals(_inventory)
	_inventory.remove_item(&"herb_moonleaf", 99)
	assert_signal_not_emitted(_inventory, "item_removed",
			"item_removed should NOT be emitted when remove fails due to insufficient quantity")


# ---------------------------------------------------------------------------
# AC-8: add_item returns false for unregistered item_id
# ---------------------------------------------------------------------------

func test_add_item_returns_false_for_unregistered_item_id() -> void:
	var ok: bool = _inventory.add_item(&"unknown_id", 1)
	assert_false(ok, "add_item should return false for an item_id not in ItemDB")
	assert_eq(_inventory.get_quantity(&"unknown_id"), 0,
			"unregistered item should not be stored in inventory")


func test_add_item_does_not_emit_signal_for_unregistered_item_id() -> void:
	watch_signals(_inventory)
	_inventory.add_item(&"unknown_id", 1)
	assert_signal_not_emitted(_inventory, "item_added",
			"item_added should NOT be emitted when item_id is not registered in ItemDB")


# ---------------------------------------------------------------------------
# quantity guard: add_item / remove_item with quantity <= 0
# ---------------------------------------------------------------------------

func test_add_item_returns_false_for_zero_quantity() -> void:
	var ok: bool = _inventory.add_item(&"herb_moonleaf", 0)
	assert_false(ok, "add_item should return false when quantity is 0")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"inventory should remain empty after add_item with quantity 0")


func test_add_item_returns_false_for_negative_quantity() -> void:
	var ok: bool = _inventory.add_item(&"herb_moonleaf", -1)
	assert_false(ok, "add_item should return false when quantity is negative")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"inventory should remain empty after add_item with negative quantity")


func test_remove_item_returns_false_for_zero_quantity() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	watch_signals(_inventory)
	var ok: bool = _inventory.remove_item(&"herb_moonleaf", 0)
	assert_false(ok, "remove_item should return false when quantity is 0")
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 3,
			"inventory should be unchanged after remove_item with quantity 0")
	assert_signal_not_emitted(_inventory, "item_removed",
			"item_removed should NOT be emitted when remove_item quantity is 0")


func test_remove_item_depletes_item_removes_from_inventory() -> void:
	_inventory.add_item(&"herb_moonleaf", 3)
	_inventory.remove_item(&"herb_moonleaf", 3)
	assert_eq(_inventory.get_quantity(&"herb_moonleaf"), 0,
			"get_quantity should return 0 after removing all held quantity")
	assert_false(_inventory.has_item(&"herb_moonleaf"),
			"has_item should return false after full depletion")
