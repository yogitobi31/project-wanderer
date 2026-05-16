extends Node

## Global read-only registry of all ItemDefinition resources (TR-item-001).
##
## Scans res://assets/data/items/*.tres at startup and caches each ItemDefinition
## by item_id. Provides get_item()/has() access only - no runtime writes (TR-item-002).
##
## Usage:
##   # Fetch with null guard:
##   var def: ItemDefinition = ItemDB.get_item(&"herb_moonleaf")
##   if def:
##       print(def.display_name)
##
##   # Existence check (no error_occurred):
##   if ItemDB.has(&"old_key"):
##       ...

## Emitted when get_item() is called with an unregistered item_id, or when a .tres file
## cannot be loaded as ItemDefinition. Allows tests to assert error conditions.
signal error_occurred(message: String)

const _ITEMS_DIR: String = "res://assets/data/items/"

var _items: Dictionary = {}

func _ready() -> void:
	_load_items()
	_validate_definitions()

## Returns the ItemDefinition for item_id, or null if not registered.
## Emits error_occurred when item_id is not found.
func get_item(item_id: StringName) -> ItemDefinition:
	if _items.has(item_id):
		var def: ItemDefinition = _items[item_id]
		return def
	error_occurred.emit("ItemDB: item_id '%s' not found." % item_id)
	return null

## Returns true if item_id is registered. Never emits error_occurred.
func has(item_id: StringName) -> bool:
	return _items.has(item_id)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _load_items() -> void:
	var dir := DirAccess.open(_ITEMS_DIR)
	if dir == null:
		error_occurred.emit("ItemDB: cannot open items directory '%s' - check assets/data/items/ exists." % _ITEMS_DIR)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = _ITEMS_DIR + file_name
			var res: Resource = load(path)
			if res is ItemDefinition:
				var def: ItemDefinition = res
				if _items.has(def.item_id):
					error_occurred.emit("ItemDB: duplicate item_id '%s' in '%s' - skipped." % [def.item_id, path])
				else:
					_items[def.item_id] = def
			else:
				error_occurred.emit("ItemDB: '%s' is not an ItemDefinition - skipped." % path)
		file_name = dir.get_next()
	dir.list_dir_end()

## Validates all loaded ItemDefinitions and removes those that fail rules.
##
## Rules (TR-item-003):
##   CONSUMABLE max_stack sentinel (99) -> auto-corrected to CONSUMABLE_MAX_STACK_DEFAULT(20).
##   All other invalid definitions are removed and error_occurred is emitted.
## Called during _ready() - startup emissions have no guaranteed listener.
func _validate_definitions() -> void:
	var to_remove: Array[StringName] = []
	for item_id: StringName in _items:
		var def: ItemDefinition = _items[item_id] as ItemDefinition
		var valid: bool = true

		# Auto-correction: CONSUMABLE max_stack sentinel -> default (only allowed auto-fix).
		# Duplicate before mutating to avoid corrupting Godot's shared resource cache.
		if def.category == ItemDefinition.ItemCategory.CONSUMABLE and def.max_stack == 99:
			def = def.duplicate() as ItemDefinition
			def.max_stack = ItemDefinition.CONSUMABLE_MAX_STACK_DEFAULT
			_items[item_id] = def

		# QUEST_ITEM category requires is_quest_item flag.
		if def.category == ItemDefinition.ItemCategory.QUEST_ITEM and not def.is_quest_item:
			error_occurred.emit("ItemDB: '%s' - QUEST_ITEM category requires is_quest_item=true." % item_id)
			valid = false

		# Non-stackable items must have max_stack == 1.
		if not def.stackable and def.max_stack != 1:
			error_occurred.emit("ItemDB: '%s' - stackable=false requires max_stack==1." % item_id)
			valid = false

		# max_stack must be at least 1.
		if def.max_stack < 1:
			error_occurred.emit("ItemDB: '%s' - max_stack must be >= 1, got %d." % [item_id, def.max_stack])
			valid = false

		# Icon is required.
		if def.icon == null:
			error_occurred.emit("ItemDB: '%s' - icon is null." % item_id)
			valid = false

		# quest_item flag and quest_tags must be consistent.
		if def.is_quest_item and def.quest_tags.is_empty():
			error_occurred.emit("ItemDB: '%s' - is_quest_item=true requires non-empty quest_tags." % item_id)
			valid = false
		if not def.is_quest_item and not def.quest_tags.is_empty():
			error_occurred.emit("ItemDB: '%s' - is_quest_item=false but quest_tags is non-empty." % item_id)
			valid = false

		# CONSUMABLE with active effect must have positive effect_value.
		if def.category == ItemDefinition.ItemCategory.CONSUMABLE \
				and def.effect_type != ItemDefinition.EffectType.NONE \
				and def.effect_value <= 0.0:
			error_occurred.emit("ItemDB: '%s' - CONSUMABLE effect_value must be > 0." % item_id)
			valid = false

		# Warning-only: non-CONSUMABLE with an effect type set.
		if def.category != ItemDefinition.ItemCategory.CONSUMABLE \
				and def.effect_type != ItemDefinition.EffectType.NONE:
			push_warning("ItemDB: '%s' - non-CONSUMABLE has effect_type set (ignored at runtime)." % item_id)

		if not valid:
			to_remove.append(item_id)

	for id: StringName in to_remove:
		_items.erase(id)
