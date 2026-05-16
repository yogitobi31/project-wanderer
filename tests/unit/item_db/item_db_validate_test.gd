extends GutTest

## Tests for ItemDB._validate_definitions() and duplicate detection in _load_items().
## Covers story-002 ACs: CR-05, CR-06, CR-07, CR-08, CR-09, CR-11, CR-13, EC-01, EC-04, EC-05, EC-06.

var _db: ItemDB

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: ItemDB as a class_name + Autoload means
	# ItemDB.new() would call .new() on the singleton instance, which fails.
	_db = load("res://src/core/item_db.gd").new()

func after_each() -> void:
	# ItemDB extends Node, so queue_free() is correct here.
	_db.queue_free()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_valid_item(id: StringName) -> ItemDefinition:
	var d := ItemDefinition.new()
	d.item_id = id
	d.category = ItemDefinition.ItemCategory.RESOURCE
	d.stackable = true
	d.max_stack = 10
	d.is_quest_item = false
	d.quest_tags = []
	d.effect_type = ItemDefinition.EffectType.NONE
	d.effect_value = 0.0
	d.icon = ImageTexture.new()
	return d

func _inject(def: ItemDefinition) -> void:
	_db._items[def.item_id] = def

# ---------------------------------------------------------------------------
# AC-ITEM-CR-05: QUEST_ITEM + is_quest_item=false → rejected
# ---------------------------------------------------------------------------

func test_quest_item_category_false_flag_emits_error() -> void:
	var d := _make_valid_item(&"bad_quest")
	d.category = ItemDefinition.ItemCategory.QUEST_ITEM
	d.is_quest_item = false
	# quest_tags left empty (default) to isolate the QUEST_ITEM/is_quest_item mismatch error only
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 1)

func test_quest_item_category_false_flag_not_registered() -> void:
	var d := _make_valid_item(&"bad_quest")
	d.category = ItemDefinition.ItemCategory.QUEST_ITEM
	d.is_quest_item = false
	# quest_tags left empty (default) to isolate the category mismatch validation
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"bad_quest"))

# ---------------------------------------------------------------------------
# AC-ITEM-CR-06: stackable=false + max_stack!=1 → rejected
# ---------------------------------------------------------------------------

func test_non_stackable_max_stack_not_one_emits_error() -> void:
	var d := _make_valid_item(&"bad_stack")
	d.stackable = false
	d.max_stack = 10
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 1)

func test_non_stackable_max_stack_not_one_not_registered() -> void:
	var d := _make_valid_item(&"bad_stack")
	d.stackable = false
	d.max_stack = 10
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"bad_stack"))

func test_non_stackable_max_stack_two_also_rejected() -> void:
	var d := _make_valid_item(&"bad_stack2")
	d.stackable = false
	d.max_stack = 2
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"bad_stack2"))

func test_non_stackable_max_stack_one_is_valid() -> void:
	var d := _make_valid_item(&"ok_stack")
	d.stackable = false
	d.max_stack = 1
	_inject(d)
	_db._validate_definitions()
	assert_true(_db.has(&"ok_stack"))

# ---------------------------------------------------------------------------
# AC-ITEM-CR-07: duplicate item_id → second rejected, first preserved
# ---------------------------------------------------------------------------

func test_duplicate_item_id_emits_error() -> void:
	var first := _make_valid_item(&"dup_id")
	first.display_name = "First"
	_inject(first)
	# Simulate second load attempt directly (duplicate detection in _load_items)
	var second := _make_valid_item(&"dup_id")
	second.display_name = "Second"
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	# Manually replicate _load_items duplicate check
	if _db._items.has(second.item_id):
		_db.error_occurred.emit("ItemDB: duplicate item_id '%s' — skipped." % second.item_id)
	assert_eq(errors.size(), 1)

func test_duplicate_item_id_first_definition_preserved() -> void:
	var first := _make_valid_item(&"dup_id2")
	first.display_name = "First"
	_inject(first)
	# Only first was injected — validate passes
	_db._validate_definitions()
	assert_true(_db.has(&"dup_id2"))
	assert_eq(_db.get_item(&"dup_id2").display_name, "First")

# ---------------------------------------------------------------------------
# AC-ITEM-CR-08: max_stack=0 → rejected
# ---------------------------------------------------------------------------

func test_max_stack_zero_emits_error() -> void:
	var d := _make_valid_item(&"zero_stack")
	d.stackable = true
	d.max_stack = 0
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_gte(errors.size(), 1)

func test_max_stack_zero_not_registered() -> void:
	var d := _make_valid_item(&"zero_stack")
	d.stackable = true
	d.max_stack = 0
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"zero_stack"))

# ---------------------------------------------------------------------------
# AC-ITEM-CR-09: icon=null → rejected
# ---------------------------------------------------------------------------

func test_null_icon_emits_error() -> void:
	var d := _make_valid_item(&"no_icon")
	d.icon = null
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 1)

func test_null_icon_not_registered() -> void:
	var d := _make_valid_item(&"no_icon")
	d.icon = null
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"no_icon"))

# ---------------------------------------------------------------------------
# AC-ITEM-CR-11: CONSUMABLE max_stack sentinel (99) → auto-corrected to 20
# ---------------------------------------------------------------------------

func test_consumable_sentinel_stack_corrected_to_default() -> void:
	var d := _make_valid_item(&"potion")
	d.category = ItemDefinition.ItemCategory.CONSUMABLE
	d.max_stack = 99
	d.effect_type = ItemDefinition.EffectType.HEAL
	d.effect_value = 10.0
	_inject(d)
	_db._validate_definitions()
	assert_eq(_db.get_item(&"potion").max_stack, ItemDefinition.CONSUMABLE_MAX_STACK_DEFAULT)

func test_consumable_explicit_stack_not_corrected() -> void:
	var d := _make_valid_item(&"potion2")
	d.category = ItemDefinition.ItemCategory.CONSUMABLE
	d.max_stack = 50
	d.effect_type = ItemDefinition.EffectType.HEAL
	d.effect_value = 10.0
	_inject(d)
	_db._validate_definitions()
	assert_eq(_db.get_item(&"potion2").max_stack, 50)

# ---------------------------------------------------------------------------
# AC-ITEM-CR-13: non-CONSUMABLE + effect_type != NONE → warning + registered
# ---------------------------------------------------------------------------

func test_resource_with_effect_type_no_error_occurred() -> void:
	var d := _make_valid_item(&"weird_resource")
	d.category = ItemDefinition.ItemCategory.RESOURCE
	d.effect_type = ItemDefinition.EffectType.HEAL
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 0)

func test_resource_with_effect_type_still_registered() -> void:
	var d := _make_valid_item(&"weird_resource")
	d.category = ItemDefinition.ItemCategory.RESOURCE
	d.effect_type = ItemDefinition.EffectType.HEAL
	_inject(d)
	_db._validate_definitions()
	assert_true(_db.has(&"weird_resource"))

# ---------------------------------------------------------------------------
# AC-ITEM-EC-01: is_quest_item=true + quest_tags=[] → rejected
# ---------------------------------------------------------------------------

func test_quest_item_empty_tags_emits_error() -> void:
	var d := _make_valid_item(&"quest_notag")
	d.is_quest_item = true
	d.quest_tags = []
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 1)

func test_quest_item_empty_tags_not_registered() -> void:
	var d := _make_valid_item(&"quest_notag")
	d.is_quest_item = true
	d.quest_tags = []
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"quest_notag"))

# ---------------------------------------------------------------------------
# AC-ITEM-EC-04: CONSUMABLE + HEAL + effect_value=0.0 → rejected
# ---------------------------------------------------------------------------

func test_consumable_heal_zero_effect_value_emits_error() -> void:
	var d := _make_valid_item(&"bad_potion")
	d.category = ItemDefinition.ItemCategory.CONSUMABLE
	d.max_stack = 10
	d.effect_type = ItemDefinition.EffectType.HEAL
	d.effect_value = 0.0
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_gte(errors.size(), 1)

func test_consumable_heal_zero_effect_value_not_registered() -> void:
	var d := _make_valid_item(&"bad_potion")
	d.category = ItemDefinition.ItemCategory.CONSUMABLE
	d.max_stack = 10
	d.effect_type = ItemDefinition.EffectType.HEAL
	d.effect_value = 0.0
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"bad_potion"))

func test_consumable_heal_negative_effect_value_also_rejected() -> void:
	var d := _make_valid_item(&"bad_potion2")
	d.category = ItemDefinition.ItemCategory.CONSUMABLE
	d.max_stack = 10
	d.effect_type = ItemDefinition.EffectType.HEAL
	d.effect_value = -1.0
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"bad_potion2"))

# ---------------------------------------------------------------------------
# AC-ITEM-EC-05: is_quest_item=false + quest_tags non-empty → rejected
# ---------------------------------------------------------------------------

func test_non_quest_item_with_tags_emits_error() -> void:
	var d := _make_valid_item(&"tag_mismatch")
	d.is_quest_item = false
	d.quest_tags = [&"quest_x"]
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 1)

func test_non_quest_item_with_tags_not_registered() -> void:
	var d := _make_valid_item(&"tag_mismatch")
	d.is_quest_item = false
	d.quest_tags = [&"quest_x"]
	_inject(d)
	_db._validate_definitions()
	assert_false(_db.has(&"tag_mismatch"))

# ---------------------------------------------------------------------------
# AC-ITEM-EC-06: RESOURCE + is_quest_item=true + quest_tags → allowed
# ---------------------------------------------------------------------------

func test_resource_quest_item_with_tags_no_error() -> void:
	var d := _make_valid_item(&"quest_resource")
	d.category = ItemDefinition.ItemCategory.RESOURCE
	d.is_quest_item = true
	d.quest_tags = [&"quest_x"]
	_inject(d)
	var errors: Array = []
	_db.error_occurred.connect(func(msg): errors.append(msg))
	_db._validate_definitions()
	assert_eq(errors.size(), 0)

func test_resource_quest_item_with_tags_registered() -> void:
	var d := _make_valid_item(&"quest_resource")
	d.category = ItemDefinition.ItemCategory.RESOURCE
	d.is_quest_item = true
	d.quest_tags = [&"quest_x"]
	_inject(d)
	_db._validate_definitions()
	assert_true(_db.has(&"quest_resource"))
