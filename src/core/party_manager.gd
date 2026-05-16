extends Node

## Global registry for party membership (TR-party-001, TR-party-002).
##
## Tracks recruited companion IDs. Registration order is preserved.
## Enforces MAX_PARTY_SIZE=3 as a second line of defence - the join-event
## system must check companion_count < MAX_PARTY_SIZE before emitting
## companion_join_requested.
##
## Usage:
##   PartyManager.register_companion(&"aria")
##   if PartyManager.is_recruited(&"aria"):
##       print(PartyManager.get_companions())

## Maximum active party companions (TR-party-002). Single source of truth
## for all downstream systems that need to check party capacity.
const MAX_PARTY_SIZE: int = 3

var _companions: Array[StringName] = []

## Computed - number of currently registered companions.
var companion_count: int:
	get: return _companions.size()

## Registers companion_id as a party member.
##
## Silent no-op if companion_id is already registered (push_warning emitted).
## Silent no-op if MAX_PARTY_SIZE is already reached (push_warning emitted).
func register_companion(companion_id: StringName) -> void:
	if _companions.has(companion_id):
		push_warning("PartyManager: companion already registered - %s" % companion_id)
		return
	if _companions.size() >= MAX_PARTY_SIZE:
		push_warning("PartyManager: MAX_PARTY_SIZE reached, cannot register - %s" % companion_id)
		return
	_companions.append(companion_id)

## Returns true if companion_id is currently in the party.
func is_recruited(companion_id: StringName) -> bool:
	return _companions.has(companion_id)

## Returns a copy of the companions list in registration order.
## Modifying the returned array does not affect internal state.
func get_companions() -> Array[StringName]:
	var copy: Array[StringName] = []
	copy.assign(_companions)
	return copy


## Returns a JSON-serializable snapshot of party state for SaveManager (ADR-0007).
## Format: {"party": [String, ...]} — companion IDs in registration order.
func get_save_data() -> Dictionary:
	var party_array: Array[String] = []
	for id: StringName in _companions:
		party_array.append(str(id))
	return {"party": party_array}


## Restores party state from a SaveManager data block (ADR-0007).
## StringName casts all IDs explicitly to guard against String/StringName
## JSON round-trip mismatch (R-09). Silently skips empty or excess entries.
func load_save_data(data: Dictionary) -> void:
	_companions.clear()
	var party_array: Array = data.get("party", [])
	for entry: Variant in party_array:
		var companion_id: StringName = StringName(str(entry))
		if companion_id != &"" and _companions.size() < MAX_PARTY_SIZE:
			_companions.append(companion_id)
