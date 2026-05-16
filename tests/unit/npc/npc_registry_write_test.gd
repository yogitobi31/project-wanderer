extends GutTest

## Tests for NPCRegistry write API: set_quest_flag, get_quest_flags,
## update_dialogue_node, set_party_slot, reset_hostile, _validate_records.
## Covers story-003 ACs: CR-13, CR-20, CR-20b, EC-01..09.

var _registry: NPCRegistry

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: NPCRegistry as a class_name + Autoload means
	# NPCRegistry.new() would call .new() on the singleton instance, which fails.
	_registry = load("res://src/core/npc_registry.gd").new()
	_registry.is_initialized = true

func after_each() -> void:
	# NPCRegistry extends Node, so queue_free() is correct here.
	_registry.queue_free()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_npc(id: StringName, state: int = NPCRecord.RelationshipState.UNKNOWN) -> NPCRecord:
	var r := NPCRecord.new()
	r.npc_id = id
	r.relationship_state = state
	_registry._records[id] = r
	_registry._rebuild_companions_cache()
	return r

func _make_companion(id: StringName, slot: int) -> NPCRecord:
	var r := _make_npc(id, NPCRecord.RelationshipState.COMPANION)
	r.party_slot = slot
	return r

# ---------------------------------------------------------------------------
# AC-NPC-CR-13: set_party_slot() duplicate slot rejection
# ---------------------------------------------------------------------------

func test_set_party_slot_duplicate_emits_error_occurred() -> void:
	_make_companion(&"npc_a", 0)
	var npc_b := _make_companion(&"npc_b", 1)
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry.set_party_slot(&"npc_b", 0)
	assert_eq(errors.size(), 1, "error_occurred emitted once")

func test_set_party_slot_duplicate_does_not_change_npc_b_slot() -> void:
	_make_companion(&"npc_a", 0)
	var npc_b := _make_companion(&"npc_b", 1)
	_registry.set_party_slot(&"npc_b", 0)
	assert_eq(npc_b.party_slot, 1, "NPC-B slot unchanged")

func test_set_party_slot_duplicate_preserves_npc_a_slot() -> void:
	var npc_a := _make_companion(&"npc_a", 0)
	_make_companion(&"npc_b", 1)
	_registry.set_party_slot(&"npc_b", 0)
	assert_eq(npc_a.party_slot, 0, "NPC-A slot unchanged")

func test_set_party_slot_unique_slot_succeeds() -> void:
	_make_companion(&"npc_a", 0)
	var npc_b := _make_companion(&"npc_b", 1)
	_registry.set_party_slot(&"npc_b", 2)
	assert_eq(npc_b.party_slot, 2)

func test_set_party_slot_non_companion_emits_error_occurred() -> void:
	_make_npc(&"npc_met", NPCRecord.RelationshipState.MET)
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry.set_party_slot(&"npc_met", 0)
	assert_eq(errors.size(), 1, "error_occurred emitted for non-COMPANION")

func test_set_party_slot_non_companion_does_not_change_slot() -> void:
	var r := _make_npc(&"npc_met", NPCRecord.RelationshipState.MET)
	_registry.set_party_slot(&"npc_met", 0)
	assert_eq(r.party_slot, -1, "party_slot unchanged on non-COMPANION")

# ---------------------------------------------------------------------------
# AC-NPC-CR-20: update_dialogue_node() normal
# ---------------------------------------------------------------------------

func test_update_dialogue_node_sets_last_dialogue_node() -> void:
	_make_npc(&"npc_x")
	_registry.update_dialogue_node(&"npc_x", &"node_intro_01")
	var record := _registry.get_npc(&"npc_x")
	assert_eq(record.last_dialogue_node, &"node_intro_01")

func test_update_dialogue_node_does_not_emit_npc_state_changed() -> void:
	_make_npc(&"npc_x")
	watch_signals(_registry)
	_registry.update_dialogue_node(&"npc_x", &"node_intro_01")
	assert_signal_not_emitted(_registry, "npc_state_changed", "npc_state_changed not emitted")

# ---------------------------------------------------------------------------
# AC-NPC-CR-20b: update_dialogue_node() unknown NPC
# ---------------------------------------------------------------------------

func test_update_dialogue_node_unknown_npc_emits_error_occurred() -> void:
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry.update_dialogue_node(&"ghost_id", &"node")
	assert_eq(errors.size(), 1)

# ---------------------------------------------------------------------------
# AC-NPC-EC-02: quest_flags String key round-trip
# ---------------------------------------------------------------------------

func test_set_quest_flag_string_key_stored() -> void:
	_make_npc(&"npc_q")
	_registry.set_quest_flag(&"npc_q", "rescued_prisoner", true)
	var flags := _registry.get_quest_flags(&"npc_q")
	assert_true(flags.has("rescued_prisoner"))

func test_set_quest_flag_string_key_value_correct() -> void:
	_make_npc(&"npc_q")
	_registry.set_quest_flag(&"npc_q", "rescued_prisoner", true)
	var flags := _registry.get_quest_flags(&"npc_q")
	assert_eq(flags["rescued_prisoner"], true)

# ---------------------------------------------------------------------------
# AC-NPC-EC-02b: quest_flags StringName key coerced to String
# ---------------------------------------------------------------------------

func test_set_quest_flag_stringname_key_coerced_to_string() -> void:
	_make_npc(&"npc_q")
	_registry.set_quest_flag(&"npc_q", &"step", true)
	var flags := _registry.get_quest_flags(&"npc_q")
	assert_true(flags.has("step"), "StringName coerced to String key")

func test_set_quest_flag_stringname_key_not_stored_as_stringname() -> void:
	_make_npc(&"npc_q")
	_registry.set_quest_flag(&"npc_q", &"step", true)
	var flags := _registry.get_quest_flags(&"npc_q")
	# The key type should be String, not StringName
	for key in flags.keys():
		assert_eq(typeof(key), TYPE_STRING, "key is String type")

# ---------------------------------------------------------------------------
# AC-NPC-EC-03: QUEST_ABANDONED preserves quest_flags
# ---------------------------------------------------------------------------

func test_set_state_quest_abandoned_preserves_quest_flags() -> void:
	var r := _make_npc(&"npc_q", NPCRecord.RelationshipState.QUEST_ACTIVE)
	_registry.set_quest_flag(&"npc_q", "npc_helped_me", true)
	_registry.set_state(&"npc_q", NPCRecord.RelationshipState.QUEST_ABANDONED)
	var flags := _registry.get_quest_flags(&"npc_q")
	assert_true(flags.has("npc_helped_me"), "quest flag preserved after QUEST_ABANDONED")

func test_set_state_quest_abandoned_state_is_correct() -> void:
	_make_npc(&"npc_q", NPCRecord.RelationshipState.QUEST_ACTIVE)
	_registry.set_quest_flag(&"npc_q", "npc_helped_me", true)
	_registry.set_state(&"npc_q", NPCRecord.RelationshipState.QUEST_ABANDONED)
	var record := _registry.get_npc(&"npc_q")
	assert_eq(record.relationship_state, NPCRecord.RelationshipState.QUEST_ABANDONED)

# ---------------------------------------------------------------------------
# AC-NPC-EC-07: invalid value type rejected
# ---------------------------------------------------------------------------

func test_set_quest_flag_invalid_type_emits_error_occurred() -> void:
	_make_npc(&"npc_q")
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry.set_quest_flag(&"npc_q", "bad_flag", Vector2(1.0, 1.0))
	assert_eq(errors.size(), 1)

func test_set_quest_flag_invalid_type_does_not_store_flag() -> void:
	_make_npc(&"npc_q")
	_registry.set_quest_flag(&"npc_q", "bad_flag", Vector2(1.0, 1.0))
	var flags := _registry.get_quest_flags(&"npc_q")
	assert_false(flags.has("bad_flag"))

# ---------------------------------------------------------------------------
# AC-NPC-EC-05: snapshot() _quest_flags independence
# ---------------------------------------------------------------------------

func test_snapshot_quest_flags_modification_does_not_affect_original() -> void:
	_make_npc(&"npc_s")
	_registry.set_quest_flag(&"npc_s", "orig_key", true)
	var record := _registry.get_npc(&"npc_s")
	var snap := record.snapshot()
	snap._quest_flags["test_copy"] = "value"
	var flags := _registry.get_quest_flags(&"npc_s")
	assert_false(flags.has("test_copy"), "snapshot mutation does not affect original")

func test_snapshot_quest_flags_original_not_affected_by_delete() -> void:
	_make_npc(&"npc_s")
	_registry.set_quest_flag(&"npc_s", "orig_key", true)
	var record := _registry.get_npc(&"npc_s")
	var snap := record.snapshot()
	snap._quest_flags.erase("orig_key")
	var flags := _registry.get_quest_flags(&"npc_s")
	assert_true(flags.has("orig_key"), "original key still present after snapshot erase")

# ---------------------------------------------------------------------------
# AC-NPC-EC-08: snapshot() recruitment_tags independence
# ---------------------------------------------------------------------------

func test_snapshot_recruitment_tags_append_does_not_affect_original() -> void:
	var r := _make_npc(&"npc_s")
	r.recruitment_tags = [&"healer"]
	var snap := r.snapshot()
	snap.recruitment_tags.append(&"test_tag")
	assert_false(r.recruitment_tags.has(&"test_tag"), "original recruitment_tags unchanged")

func test_snapshot_recruitment_tags_original_count_unchanged() -> void:
	var r := _make_npc(&"npc_s")
	r.recruitment_tags = [&"healer"]
	var snap := r.snapshot()
	snap.recruitment_tags.append(&"test_tag")
	assert_eq(r.recruitment_tags.size(), 1)

# ---------------------------------------------------------------------------
# AC-NPC-EC-09: snapshot() scalar field independence
# ---------------------------------------------------------------------------

func test_snapshot_scalar_change_does_not_affect_original() -> void:
	var r := _make_npc(&"npc_s")
	r.active_quest_id = &"quest_a"
	var snap := r.snapshot()
	snap.active_quest_id = &"quest_b"
	assert_eq(r.active_quest_id, &"quest_a", "original active_quest_id unchanged")

# ---------------------------------------------------------------------------
# AC-NPC-EC-01: _validate_records() corruption recovery
# ---------------------------------------------------------------------------

func test_validate_records_corrupted_state_reset_to_met() -> void:
	var r := _make_npc(&"npc_corrupt")
	r.relationship_state = 99
	_registry._validate_records()
	assert_eq(r.relationship_state, NPCRecord.RelationshipState.MET)

func test_validate_records_corrupted_state_emits_error_occurred() -> void:
	var r := _make_npc(&"npc_corrupt")
	r.relationship_state = 99
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry._validate_records()
	assert_eq(errors.size(), 1)

func test_validate_records_valid_state_not_modified() -> void:
	var r := _make_npc(&"npc_ok", NPCRecord.RelationshipState.MET)
	var errors: Array = []
	_registry.error_occurred.connect(func(msg): errors.append(msg))
	_registry._validate_records()
	assert_eq(r.relationship_state, NPCRecord.RelationshipState.MET)
	assert_eq(errors.size(), 0)

func test_validate_records_unknown_state_zero_not_modified() -> void:
	var r := _make_npc(&"npc_ok", NPCRecord.RelationshipState.UNKNOWN)
	_registry._validate_records()
	assert_eq(r.relationship_state, NPCRecord.RelationshipState.UNKNOWN, "UNKNOWN(0) is valid")

func test_validate_records_negative_state_reset_to_met() -> void:
	var r := _make_npc(&"npc_neg")
	r.relationship_state = -1
	_registry._validate_records()
	assert_eq(r.relationship_state, NPCRecord.RelationshipState.MET)
