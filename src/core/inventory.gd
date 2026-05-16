extends Node

## Player item quantity registry - Autoload singleton (TR-inv-001, TR-inv-002, ADR-0002).
##
## Stores {item_id -> quantity} for all player-held items. Validates item_id against
## ItemDB before adding. Emits item_added/item_removed on successful mutations.
##
## Usage:
##   Inventory.add_item(&"herb_moonleaf", 3)
##   var qty: int = Inventory.get_quantity(&"herb_moonleaf")
##   if Inventory.has_item(&"herb_moonleaf"):
##       Inventory.remove_item(&"herb_moonleaf", 1)

signal item_added(item_id: StringName, quantity: int)
signal item_removed(item_id: StringName, quantity: int)

## Internal storage: StringName -> int quantity.
var _items: Dictionary[StringName, int] = {}


## Adds [param quantity] of [param item_id] to the inventory.
## Returns false if item_id is not registered in ItemDB.
##
## Example:
##   var ok: bool = Inventory.add_item(&"herb_moonleaf", 3)  # true
##   var bad: bool = Inventory.add_item(&"unknown", 1)       # false
func add_item(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0:
		return false
	if not Engine.get_singleton(&"ItemDB").has(item_id):
		return false
	_items[item_id] = _items.get(item_id, 0) + quantity
	item_added.emit(item_id, quantity)
	return true


## Removes [param quantity] of [param item_id] from the inventory.
## Returns false and leaves inventory unchanged if current quantity < requested.
##
## Example:
##   Inventory.remove_item(&"herb_moonleaf", 2)  # true if qty >= 2
##   Inventory.remove_item(&"herb_moonleaf", 99) # false - qty unchanged
func remove_item(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0:
		return false
	if get_quantity(item_id) < quantity:
		return false
	_items[item_id] -= quantity
	if _items[item_id] == 0:
		_items.erase(item_id)
	item_removed.emit(item_id, quantity)
	return true


## Returns true if item_id is present with quantity >= 1.
func has_item(item_id: StringName) -> bool:
	return _items.get(item_id, 0) > 0


## Returns the current quantity of item_id, or 0 if not present.
func get_quantity(item_id: StringName) -> int:
	return _items.get(item_id, 0)


## Returns a JSON-serializable snapshot of the inventory for SaveManager.
## Format: {"items": [{"item_id": String, "quantity": int}, ...]}
func get_save_data() -> Dictionary:
	var items_array: Array[Dictionary] = []
	for item_id: StringName in _items:
		items_array.append({"item_id": str(item_id), "quantity": _items[item_id]})
	return {"items": items_array}


## Restores inventory state from a SaveManager data block.
## Missing keys are treated as defaults (defensive load).
func load_save_data(data: Dictionary) -> void:
	_items.clear()
	var items_array: Array = data.get("items", [])
	for entry: Dictionary in items_array:
		var item_id: StringName = StringName(entry.get("item_id", ""))
		var quantity: int = int(entry.get("quantity", 0))
		if item_id != &"" and quantity > 0:
			_items[item_id] = quantity
