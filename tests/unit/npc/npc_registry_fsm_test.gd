class_name NpcRegistryFsmTest
extends GutTest

## GUT unit tests for NPCRegistry.set_state() FSM.
##
## Covers:
##   AC-NPC-CR-03   — npc_state_changed payload (npc_id, old, new)
##   AC-NPC-CR-03b  — consecutive transitions emit correct signals each time
##   AC-NPC-CR-05   — backward transition from COMPANION rejected
##   AC-NPC-CR-05b  — backward transition from MET rejected
##   AC-NPC-CR-06   — MET → HOSTILE allowed (VS+ — FSM logic tested at MVP)
##   AC-NPC-CR-06b  — COMPANION → HOSTILE: party_slot=-1, cache removed
##   AC-NPC-CR-09   — COMPANION entry clears active_quest_id
##   AC-NPC-CR-10   — same-state call is no-op, no signal
##   AC-NPC-CR-11   — COMPANION → DEPARTED: party_slot=-1, removed from companions
##   AC-NPC-CR-12   — double set_state reaches final COMPANION, 2 signals total
##   AC-NPC-CR-16   — QUEST_ACTIVE → QUEST_ABANDONED: active_quest_id cleared
##   AC-NPC-CR-17   — QUEST_ABANDONED → QUEST_ACTIVE allowed
##   AC-NPC-CR-18   — DEPARTED → HOSTILE rejected
##   AC-NPC-CR-19   — invalid state value (99, -1) rejected
##
## Run with: godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://tests/

var _registry: NPCRegistry

# Signal capture
var _signal_count: int = 0
var _last_npc_id: StringName = &""
var _last_old_state: int = -1
var _last_new_state: int = -1
var _error_count: int = 0
var _captured_signals: Array = []  # Array of {npc_id, old, new} dicts

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: NPCRegistry as a class_name + Autoload means
	# NPCRegistry.new() would call .new() on the singleton instance, which fails.
	_registry = load("res://src/core/npc_registry.gd").new()
	_registry.is_initialized = true  # Bypass _ready() — testing FSM, not file loading.
	_signal_count = 0
	_last_npc_id = &""
	_last_old_state = -1
	_last_new_state = -1
	_error_count = 0
	_captured_signals = []

func after_each() -> void:
	if is_instance_valid(_registry):
		_registry.queue_free()
	_registry = null

# ---------------------------------------------------------------------------
# Signal receivers
# ---------------------------------------------------------------------------

func _on_state_changed(npc_id: StringName, old_state: int, new_state: int) -> void:
	_signal_count += 1
	_last_npc_id = npc_id
	_last_old_state = old_state
	_last_new_state = new_state
	_captured_signals.append({"npc_id": npc_id, "old": old_state, "new_state": new_state})

func _on_error_occurred(_message: String) -> void:
	_error_count += 1

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_npc(npc_id: StringName, state: int) -> NPCRecord:
	var r := NPCRecord.new()
	r.npc_id = npc_id
	r.relationship_state = state
	_registry._records[npc_id] = r
	_registry._rebuild_companions_cache()
	return r

func _connect_signals() -> void:
	_registry.npc_state_changed.connect(_on_state_changed)
	_registry.error_occurred.connect(_on_error_occurred)

func _disconnect_signals() -> void:
	if _registry.npc_state_changed.is_connected(_on_state_changed):
		_registry.npc_state_changed.disconnect(_on_state_changed)
	if _registry.error_occurred.is_connected(_on_error_occurred):
		_registry.error_occurred.disconnect(_on_error_occurred)

# ---------------------------------------------------------------------------
# AC-NPC-CR-03 — npc_state_changed signal payload
# ---------------------------------------------------------------------------

func test_set_state_emits_npc_state_changed_once() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_signal_count, 1, "npc_state_changed must fire exactly once")
	_disconnect_signals()

func test_set_state_signal_carries_correct_npc_id() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_last_npc_id, &"mira", "signal npc_id must match")
	_disconnect_signals()

func test_set_state_signal_carries_correct_old_state() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_last_old_state, NPCRecord.RelationshipState.UNKNOWN, "old_state must be UNKNOWN")
	_disconnect_signals()

func test_set_state_signal_carries_correct_new_state() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_last_new_state, NPCRecord.RelationshipState.COMPANION, "new_state must be COMPANION")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-03b — consecutive transitions
# ---------------------------------------------------------------------------

func test_consecutive_transitions_emit_two_signals() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"jin", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	assert_eq(_signal_count, 2, "two transitions must emit two signals")
	_disconnect_signals()

func test_consecutive_first_signal_old_unknown_new_met() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"jin", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	var first: Dictionary = _captured_signals[0]
	assert_eq(first.old, NPCRecord.RelationshipState.UNKNOWN, "first signal old must be UNKNOWN")
	assert_eq(first.new_state, NPCRecord.RelationshipState.MET, "first signal new must be MET")
	_disconnect_signals()

func test_consecutive_second_signal_old_met_new_quest_active() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.UNKNOWN)
	_connect_signals()
	_registry.set_state(&"jin", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	var second: Dictionary = _captured_signals[1]
	assert_eq(second.old, NPCRecord.RelationshipState.MET, "second signal old must be MET")
	assert_eq(second.new_state, NPCRecord.RelationshipState.QUEST_ACTIVE, "second signal new must be QUEST_ACTIVE")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-05 — backward transition from COMPANION rejected
# ---------------------------------------------------------------------------

func test_companion_to_unknown_keeps_companion_state() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	var record: NPCRecord = _registry._records[&"mira"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.COMPANION,
		"state must remain COMPANION after illegal transition")

func test_companion_to_unknown_emits_error_occurred() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.COMPANION)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	assert_eq(_error_count, 1, "error_occurred must fire once for illegal transition")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-05b — backward transition from MET rejected
# ---------------------------------------------------------------------------

func test_met_to_unknown_keeps_met_state() -> void:
	_make_npc(&"merchant", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"merchant", NPCRecord.RelationshipState.UNKNOWN)
	var record: NPCRecord = _registry._records[&"merchant"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.MET,
		"state must remain MET after illegal transition")

func test_met_to_unknown_emits_error_occurred() -> void:
	_make_npc(&"merchant", NPCRecord.RelationshipState.MET)
	_connect_signals()
	_registry.set_state(&"merchant", NPCRecord.RelationshipState.UNKNOWN)
	assert_eq(_error_count, 1, "error_occurred must fire once")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-06 — MET → HOSTILE allowed (VS+ content, FSM logic at MVP)
# ---------------------------------------------------------------------------

func test_met_to_hostile_is_allowed() -> void:
	_make_npc(&"bandit", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"bandit", NPCRecord.RelationshipState.HOSTILE)
	var record: NPCRecord = _registry._records[&"bandit"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.HOSTILE,
		"MET → HOSTILE must be allowed")

# ---------------------------------------------------------------------------
# AC-NPC-CR-06b — COMPANION → HOSTILE: party_slot cleared, removed from cache
# ---------------------------------------------------------------------------

func test_companion_to_hostile_clears_party_slot() -> void:
	var r: NPCRecord = _make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.HOSTILE)
	assert_eq(r.party_slot, -1, "party_slot must be -1 after COMPANION → HOSTILE")

func test_companion_to_hostile_removes_from_companions_cache() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.HOSTILE)
	assert_eq(_registry.get_companions().size(), 0,
		"companions cache must be empty after COMPANION → HOSTILE")

# ---------------------------------------------------------------------------
# AC-NPC-CR-09 — COMPANION entry clears active_quest_id
# ---------------------------------------------------------------------------

func test_quest_active_to_companion_clears_active_quest_id() -> void:
	var r: NPCRecord = _make_npc(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	r.active_quest_id = &"quest_jin_01"
	_registry.set_state(&"jin", NPCRecord.RelationshipState.COMPANION)
	assert_eq(r.active_quest_id, &"", "active_quest_id must be cleared on COMPANION entry")

# ---------------------------------------------------------------------------
# AC-NPC-CR-10 — same-state call is no-op, no signal
# ---------------------------------------------------------------------------

func test_same_state_emits_no_signal() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_signal_count, 0, "same-state set_state must not emit npc_state_changed")
	_disconnect_signals()

func test_same_state_keeps_state_unchanged() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	var record: NPCRecord = _registry._records[&"mira"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.COMPANION,
		"state must remain COMPANION after same-state call")

# ---------------------------------------------------------------------------
# AC-NPC-CR-11 — COMPANION → DEPARTED side-effects
# ---------------------------------------------------------------------------

func test_companion_to_departed_sets_state_departed() -> void:
	var r: NPCRecord = _make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.DEPARTED)
	assert_eq(r.relationship_state, NPCRecord.RelationshipState.DEPARTED,
		"state must be DEPARTED")

func test_companion_to_departed_clears_party_slot() -> void:
	var r: NPCRecord = _make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.DEPARTED)
	assert_eq(r.party_slot, -1, "party_slot must be -1 after departure")

func test_companion_to_departed_removes_from_companions() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.DEPARTED)
	assert_eq(_registry.get_companions().size(), 0,
		"get_companions() must return empty after departure")

func test_companion_to_departed_emits_correct_signal() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.UNKNOWN)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.DEPARTED)
	assert_eq(_last_old_state, NPCRecord.RelationshipState.COMPANION, "old_state must be COMPANION")
	assert_eq(_last_new_state, NPCRecord.RelationshipState.DEPARTED, "new_state must be DEPARTED")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-12 — double set_state reaches COMPANION, 2 signals
# ---------------------------------------------------------------------------

func test_double_set_state_final_state_is_companion() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.QUEST_ACTIVE)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	var record: NPCRecord = _registry._records[&"mira"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.COMPANION,
		"final state must be COMPANION")

func test_double_set_state_emits_two_signals() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_connect_signals()
	_registry.set_state(&"mira", NPCRecord.RelationshipState.QUEST_ACTIVE)
	_registry.set_state(&"mira", NPCRecord.RelationshipState.COMPANION)
	assert_eq(_signal_count, 2, "two transitions must emit exactly two signals")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-16 — QUEST_ACTIVE → QUEST_ABANDONED
# ---------------------------------------------------------------------------

func test_quest_abandoned_clears_active_quest_id() -> void:
	var r: NPCRecord = _make_npc(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	r.active_quest_id = &"quest_01"
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ABANDONED)
	assert_eq(r.active_quest_id, &"", "active_quest_id must be cleared on QUEST_ABANDONED")

func test_quest_abandoned_emits_correct_signal() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	_connect_signals()
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ABANDONED)
	assert_eq(_last_old_state, NPCRecord.RelationshipState.QUEST_ACTIVE, "old must be QUEST_ACTIVE")
	assert_eq(_last_new_state, NPCRecord.RelationshipState.QUEST_ABANDONED, "new must be QUEST_ABANDONED")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-17 — QUEST_ABANDONED → QUEST_ACTIVE (re-accept)
# ---------------------------------------------------------------------------

func test_quest_abandoned_to_quest_active_is_allowed() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.QUEST_ABANDONED)
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	var record: NPCRecord = _registry._records[&"jin"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.QUEST_ACTIVE,
		"QUEST_ABANDONED → QUEST_ACTIVE must be allowed")

func test_quest_abandoned_to_quest_active_emits_signal() -> void:
	_make_npc(&"jin", NPCRecord.RelationshipState.QUEST_ABANDONED)
	_connect_signals()
	_registry.set_state(&"jin", NPCRecord.RelationshipState.QUEST_ACTIVE)
	assert_eq(_signal_count, 1, "re-accept must emit npc_state_changed")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-18 — DEPARTED → HOSTILE rejected
# ---------------------------------------------------------------------------

func test_departed_to_hostile_keeps_departed_state() -> void:
	_make_npc(&"ghost", NPCRecord.RelationshipState.DEPARTED)
	_registry.set_state(&"ghost", NPCRecord.RelationshipState.HOSTILE)
	var record: NPCRecord = _registry._records[&"ghost"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.DEPARTED,
		"DEPARTED state must be terminal — no exit")

func test_departed_to_hostile_emits_error_occurred() -> void:
	_make_npc(&"ghost", NPCRecord.RelationshipState.DEPARTED)
	_connect_signals()
	_registry.set_state(&"ghost", NPCRecord.RelationshipState.HOSTILE)
	assert_eq(_error_count, 1, "error_occurred must fire for DEPARTED → HOSTILE")
	_disconnect_signals()

# ---------------------------------------------------------------------------
# AC-NPC-CR-19 — invalid state value rejected
# ---------------------------------------------------------------------------

func test_invalid_state_99_keeps_original_state() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"mira", 99)
	var record: NPCRecord = _registry._records[&"mira"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.MET,
		"state must be unchanged after invalid value 99")

func test_invalid_state_99_emits_error_occurred() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_connect_signals()
	_registry.set_state(&"mira", 99)
	assert_eq(_error_count, 1, "error_occurred must fire for invalid state 99")
	_disconnect_signals()

func test_invalid_state_negative_one_keeps_original_state() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_registry.set_state(&"mira", -1)
	var record: NPCRecord = _registry._records[&"mira"]
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.MET,
		"state must be unchanged after invalid value -1")

func test_invalid_state_negative_one_emits_error_occurred() -> void:
	_make_npc(&"mira", NPCRecord.RelationshipState.MET)
	_connect_signals()
	_registry.set_state(&"mira", -1)
	assert_eq(_error_count, 1, "error_occurred must fire for invalid state -1")
	_disconnect_signals()
