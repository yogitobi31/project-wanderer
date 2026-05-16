class_name ItemDefinition
extends Resource

## Static data record for a single item type.
##
## Authored as .tres files under assets/data/items/ and loaded at startup by ItemDB.
## All fields are read-only after load - never mutate a live instance from ItemDB.get().
##
## Usage:
##   var def: ItemDefinition = ItemDB.get(&"herb_moonleaf")
##   if def:
##       print(def.display_name)

enum ItemCategory { QUEST_ITEM = 0, RESOURCE = 1, CONSUMABLE = 2 }
enum EffectType { NONE = 0, HEAL = 1 }

## Default max_stack for CONSUMABLE items when max_stack is at sentinel value (99).
const CONSUMABLE_MAX_STACK_DEFAULT: int = 20

## Unique item key. Must match the .tres filename stem and the ItemDB Dictionary key.
@export var item_id: StringName = &""

## UI display name (localizable).
@export var display_name: String = ""

## Inventory tooltip description (localizable).
@export var description: String = ""

## Optional icon shown in inventory and HUD slots.
@export var icon: Texture2D = null

## Broad classification controlling stacking, quest logic, and effect fields.
@export var category: ItemCategory = ItemCategory.RESOURCE

## Fast-path flag for quest condition checks. Auto-true when category == QUEST_ITEM.
@export var is_quest_item: bool = false

## Whether multiple copies can share one inventory slot.
@export var stackable: bool = true

## Maximum copies per inventory slot when stackable is true.
@export var max_stack: int = 99

## Quest IDs this item satisfies as a condition.
## NOTE: use StringName literals (&"quest_id") in .tres files, NOT plain strings ("quest_id").
@export var quest_tags: Array[StringName] = []

## Companion whose story provides or requires this item. &"" = general item.
@export var source_companion_id: StringName = &""

## Quest whose logic provides or requires this item. &"" = general item.
@export var source_quest_id: StringName = &""

## For CONSUMABLE items: what effect triggers on use. Non-CONSUMABLE must be NONE.
@export var effect_type: EffectType = EffectType.NONE

## For CONSUMABLE HEAL items: amount of health restored. Non-CONSUMABLE must be 0.0.
@export var effect_value: float = 0.0
