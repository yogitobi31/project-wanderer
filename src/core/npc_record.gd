class_name NPCRecord
extends Resource

## Data record for a single NPC's runtime state.
##
## All fields are @export for .tres serialization and save/load compatibility.
## RelationshipState integer values are FIXED - never reorder (TR-npc-002).
##
## Usage:
##   var record: NPCRecord = NPCRegistry.get_npc(&"mira")
##   if record and record.is_in_party:
##       print(record.recruitment_tags)

## Integer values are fixed for save file compatibility.
## Adding new states: append only. Never change existing values.
enum RelationshipState {
	UNKNOWN         = 0,  ## NPC exists but player has not made contact
	MET             = 1,  ## Dialogue occurred, recruitment conditions not met
	QUEST_ACTIVE    = 2,  ## Recruitment quest accepted and in progress
	COMPANION       = 3,  ## Joined the party
	DEPARTED        = 4,  ## Left the party for narrative reasons - terminal state
	HOSTILE         = 5,  ## Combat target - exit only via reset_hostile() API
	QUEST_ABANDONED = 6,  ## Recruitment quest abandoned; re-accept allowed
}

## NPC unique identifier. Immutable after first assignment.
@export var npc_id: StringName = &""

## Schema version for save file migration. Increment when adding fields.
@export var schema_version: int = 1

## Current relationship state. Change only via NPCRegistry.set_state().
@export var relationship_state: int = RelationshipState.UNKNOWN

## Quest progression flags. Keys MUST be String (not StringName) - see GDD Core Rule 3.
## Read via NPCRegistry.get_quest_flags(). Write via NPCRegistry.set_quest_flag().
## @export here is for ResourceSaver serialization only - direct field writes are forbidden.
@export var _quest_flags: Dictionary = {}

## Active recruitment/story quest ID. &"" if none.
@export var active_quest_id: StringName = &""

## Last played dialogue node ID for conversation resumption. &"" if none.
@export var last_dialogue_node: StringName = &""

## Party slot index. -1 = not in party. 0-2 = active party slot.
@export var party_slot: int = -1

## World-unlock tags activated immediately on joining the party.
@export var recruitment_tags: Array[StringName] = []

## Growth tags activated by post-join quest milestones (Vertical Slice+).
@export var bond_tags: Array[StringName] = []

## Derived: true when relationship_state == COMPANION. Never store independently.
var is_in_party: bool:
	get: return relationship_state == RelationshipState.COMPANION

## Returns a fully independent deep copy of this record.
##
## Uses explicit Array duplication because duplicate_deep() does not guarantee
## independent copies of typed Array[StringName] fields in Godot 4.6.
## _quest_flags uses deep duplicate to prevent nested value sharing.
func snapshot() -> NPCRecord:
	var result: NPCRecord = duplicate_deep()
	result.recruitment_tags = recruitment_tags.duplicate()
	result.bond_tags = bond_tags.duplicate()
	result._quest_flags = _quest_flags.duplicate(true)
	return result
