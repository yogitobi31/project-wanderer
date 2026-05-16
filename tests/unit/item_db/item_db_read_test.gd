class_name ItemDbReadTest
extends GutTest

## GUT unit tests for ItemDB read-only interface.
##
## Covers:
##   AC-ITEM-CR-01  — get() returns correct ItemDefinition for registered item
##   AC-ITEM-CR-02  — get() returns null for unregistered item
##   AC-ITEM-CR-02b — get() on missing item emits error_occurred exactly once
##   AC-ITEM-CR-03  — has() returns correct bool, never emits error_occurred
##   AC-ITEM-CR-04  — ItemCategory enum values (QUEST_ITEM=0, RESOURCE=1, CONSUMABLE=2, no EQUIPMENT)
##   AC-ITEM-CR-10  — CONSUMABLE item returns correct effect_type and effect_value
##   AC-ITEM-CR-12  — source_companion_id and source_quest_id returned correctly
##   AC-ITEM-EC-03  — RESOURCE + is_quest_item=true + quest_tags all correct
##
## AC-3 (scene persistence across transitions): manual verification — engine guarantee.
## See production/qa/evidence/ for manual checklist.
##
## Run with: godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://tests/

var _db: ItemDB

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: ItemDB as a class_name + Autoload means
	# ItemDB.new() would call .new() on the singleton instance, which fails.
	_db = load("res://src/core/item_db.gd").new()
	add_child(_db)
	_error_count = 0
	_last_error_msg = ""

func after_each() -> void:
	_db.queue_free()
	_db = null

# ---------------------------------------------------------------------------
# Helpers — inject fixtures directly to isolate tests from .tres loading
# ---------------------------------------------------------------------------

func _make_resource_item() -> ItemDefinition:
	var def := ItemDefinition.new()
	def.item_id = &"herb_moonleaf"
	def.display_name = "달빛 약초"
	def.category = ItemDefinition.ItemCategory.RESOURCE
	def.is_quest_item = true
	def.stackable = true
	def.max_stack = 99
	def.quest_tags = [&"quest_jin_herb"]
	def.source_companion_id = &"companion_jin"
	def.source_quest_id = &"quest_jin_herb"
	def.effect_type = ItemDefinition.EffectType.NONE
	def.effect_value = 0.0
	return def

func _make_consumable_item() -> ItemDefinition:
	var def := ItemDefinition.new()
	def.item_id = &"healing_herb"
	def.display_name = "치유 약초"
	def.category = ItemDefinition.ItemCategory.CONSUMABLE
	def.is_quest_item = false
	def.stackable = true
	def.max_stack = 20
	def.quest_tags = []
	def.source_companion_id = &""
	def.source_quest_id = &""
	def.effect_type = ItemDefinition.EffectType.HEAL
	def.effect_value = 50.0
	return def

func _make_quest_item() -> ItemDefinition:
	var def := ItemDefinition.new()
	def.item_id = &"old_key"
	def.display_name = "낡은 열쇠"
	def.category = ItemDefinition.ItemCategory.QUEST_ITEM
	def.is_quest_item = true
	def.stackable = false
	def.max_stack = 1
	def.quest_tags = [&"quest_old_door"]
	def.source_companion_id = &""
	def.source_quest_id = &""
	def.effect_type = ItemDefinition.EffectType.NONE
	def.effect_value = 0.0
	return def

# ---------------------------------------------------------------------------
# AC-ITEM-CR-04 — ItemCategory enum values (pure code, no .tres loading)
# ---------------------------------------------------------------------------

func test_item_category_quest_item_equals_zero() -> void:
	assert_eq(int(ItemDefinition.ItemCategory.QUEST_ITEM), 0, "QUEST_ITEM must be 0")

func test_item_category_resource_equals_one() -> void:
	assert_eq(int(ItemDefinition.ItemCategory.RESOURCE), 1, "RESOURCE must be 1")

func test_item_category_consumable_equals_two() -> void:
	assert_eq(int(ItemDefinition.ItemCategory.CONSUMABLE), 2, "CONSUMABLE must be 2")

func test_item_category_has_no_equipment_value() -> void:
	# AC-ITEM-CR-04: EQUIPMENT must not exist — regression guard for accidental addition
	assert_false(
		"EQUIPMENT" in ItemDefinition.ItemCategory.keys(),
		"ItemCategory must NOT have an EQUIPMENT value"
	)

# ---------------------------------------------------------------------------
# AC-ITEM-CR-01 — get() returns correct ItemDefinition for registered item
# ---------------------------------------------------------------------------

func test_get_registered_item_returns_non_null_definition() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_not_null(result, "get() must return non-null for registered item")

func test_get_registered_item_has_correct_item_id() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_eq(result.item_id, &"herb_moonleaf", "item_id must match")

# ---------------------------------------------------------------------------
# AC-ITEM-CR-02 — get() returns null for unregistered item
# ---------------------------------------------------------------------------

func test_get_missing_item_returns_null() -> void:
	var result: ItemDefinition = _db.get_item(&"nonexistent")
	assert_null(result, "get() must return null for unregistered item")

# ---------------------------------------------------------------------------
# AC-ITEM-CR-02b — get() on missing item emits error_occurred exactly once
# ---------------------------------------------------------------------------

var _error_count: int = 0
var _last_error_msg: String = ""

func _on_error_occurred(message: String) -> void:
	_error_count += 1
	_last_error_msg = message

func test_get_missing_item_emits_error_occurred_once() -> void:
	_error_count = 0
	_last_error_msg = ""
	_db.error_occurred.connect(_on_error_occurred)
	_db.get_item(&"nonexistent")
	assert_eq(_error_count, 1, "error_occurred must fire exactly once on missing item")
	_db.error_occurred.disconnect(_on_error_occurred)

# ---------------------------------------------------------------------------
# AC-ITEM-CR-03 — has() returns correct bool, never emits error_occurred
# ---------------------------------------------------------------------------

func test_has_registered_item_returns_true() -> void:
	_db._items[&"old_key"] = _make_quest_item()
	assert_true(_db.has(&"old_key"), "has() must return true for registered item")

func test_has_missing_item_returns_false() -> void:
	assert_false(_db.has(&"missing"), "has() must return false for unregistered item")

func test_has_missing_item_does_not_emit_error_occurred() -> void:
	_error_count = 0
	_db.error_occurred.connect(_on_error_occurred)
	_db.has(&"missing")
	assert_eq(_error_count, 0, "has() must NOT emit error_occurred")
	_db.error_occurred.disconnect(_on_error_occurred)

# ---------------------------------------------------------------------------
# AC-ITEM-CR-10 — CONSUMABLE returns correct effect_type and effect_value
# ---------------------------------------------------------------------------

func test_consumable_item_effect_type_is_heal() -> void:
	_db._items[&"healing_herb"] = _make_consumable_item()
	var result: ItemDefinition = _db.get_item(&"healing_herb")
	assert_eq(result.effect_type, ItemDefinition.EffectType.HEAL, "effect_type must be HEAL")

func test_consumable_item_effect_value_is_fifty() -> void:
	_db._items[&"healing_herb"] = _make_consumable_item()
	var result: ItemDefinition = _db.get_item(&"healing_herb")
	assert_eq(result.effect_value, 50.0, "effect_value must be 50.0")

# ---------------------------------------------------------------------------
# AC-ITEM-CR-12 — source_companion_id and source_quest_id returned correctly
# ---------------------------------------------------------------------------

func test_source_companion_id_is_returned_correctly() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_eq(result.source_companion_id, &"companion_jin", "source_companion_id mismatch")

func test_source_quest_id_is_returned_correctly() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_eq(result.source_quest_id, &"quest_jin_herb", "source_quest_id mismatch")

# ---------------------------------------------------------------------------
# AC-ITEM-EC-03 — RESOURCE + is_quest_item=true + quest_tags all correct
# ---------------------------------------------------------------------------

func test_resource_quest_item_category_is_resource() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_eq(result.category, ItemDefinition.ItemCategory.RESOURCE, "category must be RESOURCE")

func test_resource_quest_item_is_quest_item_is_true() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_true(result.is_quest_item, "is_quest_item must be true")

func test_resource_quest_item_quest_tags_contains_correct_tag() -> void:
	_db._items[&"herb_moonleaf"] = _make_resource_item()
	var result: ItemDefinition = _db.get_item(&"herb_moonleaf")
	assert_eq(result.quest_tags.size(), 1, "quest_tags must have exactly 1 entry")
	assert_eq(result.quest_tags[0], &"quest_jin_herb", "quest_tags[0] must be &\"quest_jin_herb\"")
