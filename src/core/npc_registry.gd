extends Node

## Global registry for all NPC state (TR-npc-001, TR-npc-003).
##
## Scans res://assets/data/npcs/*.tres at startup and caches each NPCRecord
## by npc_id. Read interface: get_npc()/get_companions()/party_has_tag().
## Write interface: set_state() - the only path for RelationshipState changes.
##
## Usage:
##   var record: NPCRecord = NPCRegistry.get_npc(&"mira")
##   if record and record.is_in_party:
##       print(record.recruitment_tags)
##
##   NPCRegistry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
##   if NPCRegistry.party_has_tag(&"healer"):
##       ...

## Emitted once when _ready() finishes loading and validating all records.
signal registry_initialized()

## Emitted on state change: npc_id, previous state int, new state int (TR-npc-003).
signal npc_state_changed(npc_id: StringName, old_state: int, new_state: int)

## Emitted on API misuse: unregistered id, invalid transition, pre-init call.
signal error_occurred(message: String)

## Maximum number of active party companions (TR-npc-005).
## PartyManager owns this value - referenced here for COMPANION entry enforcement.
const MAX_PARTY_SIZE: int = 3

const _NPCS_DIR: String = "res://assets/data/npcs/"

var _records: Dictionary = {}
var _companions_cache: Array[NPCRecord] = []

## True after _ready() completes. Guards against pre-init API calls.
var is_initialized: bool = false

func _ready() -> void:
	_load_records()
	_validate_records()
	_rebuild_companions_cache()
	is_initialized = true
	registry_initialized.emit()

## Returns the live NPCRecord for npc_id, or null if not found or not initialized.
## Emits error_occurred on failure.
func get_npc(npc_id: StringName) -> NPCRecord:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: get_npc() called before initialization.")
		return null
	if _records.has(npc_id):
		return _records[npc_id] as NPCRecord
	error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
	return null

## Returns a shallow copy of the companions cache array.
## Records inside are live references - do not write to them directly.
func get_companions() -> Array[NPCRecord]:
	return _companions_cache.duplicate() as Array[NPCRecord]

## Returns true if any COMPANION record holds tag in recruitment_tags or bond_tags.
func party_has_tag(tag: StringName) -> bool:
	for record: NPCRecord in _companions_cache:
		if tag in record.recruitment_tags or tag in record.bond_tags:
			return true
	return false

## Sets a quest flag on npc_id's record.
##
## key is coerced to String (StringName inputs are accepted).
## value must be bool, int, or String - other types emit error_occurred.
## Does not emit npc_state_changed. Quest flags survive QUEST_ABANDONED transitions.
func set_quest_flag(npc_id: StringName, key: Variant, value: Variant) -> void:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: set_quest_flag() called before initialization.")
		return
	if not _records.has(npc_id):
		error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
		return
	if not (value is bool or value is int or value is String):
		error_occurred.emit("NPCRegistry: invalid quest_flag value type %d for '%s'." % [typeof(value), npc_id])
		return
	var record: NPCRecord = _records[npc_id] as NPCRecord
	record._quest_flags[String(key)] = value

## Returns a shallow copy of npc_id's quest flags dictionary.
## Keys are always String; values are bool, int, or String - shallow copy is safe.
## Returns empty dict if npc_id not found.
func get_quest_flags(npc_id: StringName) -> Dictionary:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: get_quest_flags() called before initialization.")
		return {}
	if not _records.has(npc_id):
		error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
		return {}
	var record: NPCRecord = _records[npc_id] as NPCRecord
	return record._quest_flags.duplicate()

## Updates npc_id's last_dialogue_node without triggering a state change.
## Does not emit npc_state_changed.
func update_dialogue_node(npc_id: StringName, node_id: StringName) -> void:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: update_dialogue_node() called before initialization.")
		return
	if not _records.has(npc_id):
		error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
		return
	var record: NPCRecord = _records[npc_id] as NPCRecord
	record.last_dialogue_node = node_id

## Assigns slot to npc_id's party_slot.
##
## Emits error_occurred if npc_id is not COMPANION, or if slot is already occupied.
## Does not emit npc_state_changed.
func set_party_slot(npc_id: StringName, slot: int) -> void:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: set_party_slot() called before initialization.")
		return
	if not _records.has(npc_id):
		error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
		return
	var record: NPCRecord = _records[npc_id] as NPCRecord
	if record.relationship_state != NPCRecord.RelationshipState.COMPANION:
		error_occurred.emit("NPCRegistry: set_party_slot() called on non-COMPANION '%s'." % npc_id)
		return
	for companion: NPCRecord in _companions_cache:
		if companion.npc_id != npc_id and companion.party_slot == slot:
			error_occurred.emit("NPCRegistry: party slot %d already occupied." % slot)
			return
	record.party_slot = slot

## Stub reserved for VS+ - resets a HOSTILE NPC back to MET.
## Not implemented in MVP.
func reset_hostile(_npc_id: StringName) -> void:
	push_warning("NPCRegistry: reset_hostile() is reserved for VS+ - not implemented in MVP.")

## Changes npc_id's RelationshipState to new_state and emits npc_state_changed.
##
## Enforces the FSM transition matrix - illegal transitions emit error_occurred
## and leave state unchanged. Same-state calls are silent no-ops.
## COMPANION entry assigns the first free party slot (MAX_PARTY_SIZE enforced).
func set_state(npc_id: StringName, new_state: int) -> void:
	if not is_initialized:
		error_occurred.emit("NPCRegistry: set_state() called before initialization.")
		return
	if not _records.has(npc_id):
		error_occurred.emit("NPCRegistry: npc_id '%s' not found." % npc_id)
		return

	var record: NPCRecord = _records[npc_id] as NPCRecord
	var old_state: int = record.relationship_state

	if old_state == new_state:
		return  # No-op - same state, no signal.

	if new_state < 0 or new_state > 6:
		error_occurred.emit("NPCRegistry: invalid state value %d for '%s'." % [new_state, npc_id])
		return

	if not _is_transition_allowed(old_state, new_state):
		error_occurred.emit(
			"NPCRegistry: illegal transition %d -> %d for '%s'." % [old_state, new_state, npc_id]
		)
		return

	# COMPANION entry - assign first free slot, enforce MAX_PARTY_SIZE.
	if new_state == NPCRecord.RelationshipState.COMPANION:
		var used_slots: Array[int] = []
		for companion: NPCRecord in _companions_cache:
			used_slots.append(companion.party_slot)
		var assigned: bool = false
		for slot: int in range(MAX_PARTY_SIZE):
			if slot not in used_slots:
				record.party_slot = slot
				assigned = true
				break
		if not assigned:
			error_occurred.emit("NPCRegistry: no available party slot for '%s'." % npc_id)
			return
		_companions_cache.append(record)
		record.active_quest_id = &""

	# COMPANION exit - remove from cache, clear slot, clear active quest.
	if old_state == NPCRecord.RelationshipState.COMPANION:
		_companions_cache.erase(record)
		record.party_slot = -1
		record.active_quest_id = &""

	# QUEST_ABANDONED exit side-effects.
	if new_state == NPCRecord.RelationshipState.QUEST_ABANDONED:
		record.active_quest_id = &""

	record.relationship_state = new_state
	npc_state_changed.emit(npc_id, old_state, new_state)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _load_records() -> void:
	var dir := DirAccess.open(_NPCS_DIR)
	if dir == null:
		return  # Valid empty state - directory does not exist yet.

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = _NPCS_DIR + file_name
			var res: Resource = load(path)
			if res is NPCRecord:
				var record: NPCRecord = res
				_records[record.npc_id] = record
			else:
				error_occurred.emit("NPCRegistry: '%s' is not an NPCRecord - skipped." % path)
		file_name = dir.get_next()
	dir.list_dir_end()

## Called during _ready() - error_occurred emissions here fire before external nodes connect.
## Startup errors are fire-and-forget until a buffer-and-flush pattern is added.
func _validate_records() -> void:
	for npc_id: StringName in _records:
		var record: NPCRecord = _records[npc_id] as NPCRecord
		if record.relationship_state < 0 or record.relationship_state > 6:
			error_occurred.emit(
				"NPCRegistry: corrupted state %d for '%s' - reset to MET." % [record.relationship_state, npc_id]
			)
			record.relationship_state = NPCRecord.RelationshipState.MET

## Returns true when the old_state -> new_state transition is permitted by the FSM.
##
## Rules (GDD Core Rule 9):
##   DEPARTED and HOSTILE are terminal - no exit via set_state().
##   UNKNOWN -> HOSTILE is forbidden (NPC must be met before turning hostile).
##   Any -> HOSTILE is otherwise allowed (VS+ content - logic enforced at MVP).
##   QUEST_ABANDONED -> QUEST_ACTIVE is the only permitted reverse transition.
##   All other allowed transitions move strictly forward (new_state > old_state).
func _is_transition_allowed(old_state: int, new_state: int) -> bool:
	if old_state == NPCRecord.RelationshipState.DEPARTED:
		return false
	if old_state == NPCRecord.RelationshipState.HOSTILE:
		return false
	if old_state == NPCRecord.RelationshipState.UNKNOWN and new_state == NPCRecord.RelationshipState.HOSTILE:
		return false
	if new_state == NPCRecord.RelationshipState.HOSTILE:
		return true  # All non-UNKNOWN, non-DEPARTED states may turn hostile.
	if old_state == NPCRecord.RelationshipState.QUEST_ABANDONED and new_state == NPCRecord.RelationshipState.QUEST_ACTIVE:
		return true
	return new_state > old_state

func _rebuild_companions_cache() -> void:
	_companions_cache.clear()
	for record: NPCRecord in _records.values():
		if record.relationship_state == NPCRecord.RelationshipState.COMPANION:
			_companions_cache.append(record)


# ---------------------------------------------------------------------------
# Save contract (ADR-0007)
# ---------------------------------------------------------------------------

## Returns a JSON-serializable snapshot of all NPC relationship states for SaveManager.
## Format: {"npc_states": {String: int, ...}} — npc_id key, RelationshipState value.
func get_save_data() -> Dictionary:
	var npc_states: Dictionary = {}
	for npc_id: StringName in _records:
		var record: NPCRecord = _records[npc_id] as NPCRecord
		npc_states[str(npc_id)] = record.relationship_state
	return {"npc_states": npc_states}


## Restores NPC relationship states from a SaveManager data block (ADR-0007).
##
## Bypasses the FSM transition guard — load is an authoritative restore, not a
## gameplay transition. StringName() casts all keys explicitly (R-09).
## Rebuilds the companions cache after all states are applied.
func load_save_data(data: Dictionary) -> void:
	var npc_states: Dictionary = data.get("npc_states", {})
	for npc_id_str: String in npc_states:
		var npc_id: StringName = StringName(npc_id_str)
		if not _records.has(npc_id):
			continue
		var state_value: int = int(npc_states[npc_id_str])
		if state_value < 0 or state_value > 6:
			continue
		var record: NPCRecord = _records[npc_id] as NPCRecord
		record.relationship_state = state_value
	_rebuild_companions_cache()
