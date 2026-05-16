class_name NpcRegistryReadTest
extends GutTest

## GUT unit tests for NPCRegistry read-only interface.
##
## Covers:
##   AC-NPC-CR-01  — NPCRecord type check passes for all NPC archetypes
##   AC-NPC-CR-02  — RelationshipState integer values are fixed (save compat regression guard)
##   AC-NPC-CR-04  — get_npc() returns null + error_occurred for unregistered id
##   AC-NPC-CR-07  — get_companions() returns only COMPANION-state records
##   AC-NPC-CR-08  — party_has_tag() finds tag in recruitment_tags
##   AC-NPC-CR-08b — party_has_tag() ignores tags on non-COMPANION records
##   AC-NPC-CR-08c — party_has_tag() finds tag in bond_tags
##   AC-NPC-CR-14  — is_initialized == false before add_child
##   AC-NPC-CR-15  — is_initialized == true after _ready()
##   AC-NPC-EC-06  — empty registry returns [] and false safely
##
## Run with: godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://tests/

var _registry: NPCRegistry

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: NPCRegistry as a class_name + Autoload means
	# NPCRegistry.new() would call .new() on the singleton instance, which fails.
	_registry = load("res://src/core/npc_registry.gd").new()
	_error_count = 0
	_last_error_msg = ""

func after_each() -> void:
	if is_instance_valid(_registry):
		_registry.queue_free()
	_registry = null

# ---------------------------------------------------------------------------
# Helpers — inject fixtures directly to isolate from .tres loading
# ---------------------------------------------------------------------------

func _make_companion_record(npc_id: StringName, rtags: Array[StringName] = [], btags: Array[StringName] = []) -> NPCRecord:
	var r := NPCRecord.new()
	r.npc_id = npc_id
	r.relationship_state = NPCRecord.RelationshipState.COMPANION
	r.recruitment_tags = rtags
	r.bond_tags = btags
	return r

func _make_quest_record(npc_id: StringName) -> NPCRecord:
	var r := NPCRecord.new()
	r.npc_id = npc_id
	r.relationship_state = NPCRecord.RelationshipState.QUEST_ACTIVE
	return r

func _make_neutral_record(npc_id: StringName) -> NPCRecord:
	var r := NPCRecord.new()
	r.npc_id = npc_id
	r.relationship_state = NPCRecord.RelationshipState.MET
	return r

func _inject(record: NPCRecord) -> void:
	_registry._records[record.npc_id] = record
	_registry._rebuild_companions_cache()

# ---------------------------------------------------------------------------
# Error signal helpers
# ---------------------------------------------------------------------------

var _error_count: int = 0
var _last_error_msg: String = ""

func _on_error_occurred(message: String) -> void:
	_error_count += 1
	_last_error_msg = message

# ---------------------------------------------------------------------------
# AC-NPC-CR-01 — NPCRecord type check for all archetypes
# ---------------------------------------------------------------------------

func test_companion_record_is_npcrecord() -> void:
	var r: NPCRecord = _make_companion_record(&"mira")
	assert_true(r is NPCRecord, "companion record must be NPCRecord")

func test_quest_record_is_npcrecord() -> void:
	var r: NPCRecord = _make_quest_record(&"jin")
	assert_true(r is NPCRecord, "quest NPC record must be NPCRecord")

func test_neutral_record_is_npcrecord() -> void:
	var r: NPCRecord = _make_neutral_record(&"merchant")
	assert_true(r is NPCRecord, "neutral NPC record must be NPCRecord")

# ---------------------------------------------------------------------------
# AC-NPC-CR-02 — RelationshipState integer values fixed
# ---------------------------------------------------------------------------

func test_relationship_state_unknown_equals_zero() -> void:
	assert_eq(int(NPCRecord.RelationshipState.UNKNOWN), 0, "UNKNOWN must be 0")

func test_relationship_state_met_equals_one() -> void:
	assert_eq(int(NPCRecord.RelationshipState.MET), 1, "MET must be 1")

func test_relationship_state_quest_active_equals_two() -> void:
	assert_eq(int(NPCRecord.RelationshipState.QUEST_ACTIVE), 2, "QUEST_ACTIVE must be 2")

func test_relationship_state_companion_equals_three() -> void:
	assert_eq(int(NPCRecord.RelationshipState.COMPANION), 3, "COMPANION must be 3")

func test_relationship_state_departed_equals_four() -> void:
	assert_eq(int(NPCRecord.RelationshipState.DEPARTED), 4, "DEPARTED must be 4")

func test_relationship_state_hostile_equals_five() -> void:
	assert_eq(int(NPCRecord.RelationshipState.HOSTILE), 5, "HOSTILE must be 5")

func test_relationship_state_quest_abandoned_equals_six() -> void:
	assert_eq(int(NPCRecord.RelationshipState.QUEST_ABANDONED), 6, "QUEST_ABANDONED must be 6")

# ---------------------------------------------------------------------------
# Pre-init guard — get_npc() before _ready() returns null + error_occurred
# ---------------------------------------------------------------------------

func test_get_npc_before_ready_returns_null() -> void:
	# _registry created in before_each but NOT added to scene tree — _ready() never runs
	var result: NPCRecord = _registry.get_npc(&"any_id")
	assert_null(result, "get_npc() before _ready() must return null")

func test_get_npc_before_ready_emits_error_occurred_once() -> void:
	_registry.error_occurred.connect(_on_error_occurred)
	_registry.get_npc(&"any_id")
	assert_eq(_error_count, 1, "error_occurred must fire once when called before _ready()")
	_registry.error_occurred.disconnect(_on_error_occurred)

# ---------------------------------------------------------------------------
# AC-NPC-CR-04 — get_npc() returns null + error_occurred for unknown id
# ---------------------------------------------------------------------------

func test_get_npc_missing_id_returns_null() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	var result: NPCRecord = _registry.get_npc(&"ghost_id")
	assert_null(result, "get_npc() must return null for unregistered id")

func test_get_npc_missing_id_emits_error_occurred_once() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	_error_count = 0
	_registry.error_occurred.connect(_on_error_occurred)
	_registry.get_npc(&"ghost_id")
	assert_eq(_error_count, 1, "error_occurred must fire exactly once for missing id")
	_registry.error_occurred.disconnect(_on_error_occurred)

# ---------------------------------------------------------------------------
# AC-NPC-CR-07 — get_companions() returns only COMPANION records
# ---------------------------------------------------------------------------

func test_get_companions_returns_only_companion_state_records() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	_inject(_make_companion_record(&"mira"))
	_inject(_make_quest_record(&"jin"))
	_inject(_make_neutral_record(&"merchant"))
	var companions: Array[NPCRecord] = _registry.get_companions()
	assert_eq(companions.size(), 1, "get_companions() must return exactly 1 companion")
	assert_eq(companions[0].relationship_state, NPCRecord.RelationshipState.COMPANION,
		"returned record must have COMPANION state")

func test_get_companions_returns_companion_with_correct_id() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	_inject(_make_companion_record(&"mira"))
	_inject(_make_quest_record(&"jin"))
	var companions: Array[NPCRecord] = _registry.get_companions()
	assert_eq(companions[0].npc_id, &"mira", "companion npc_id must be mira")

# ---------------------------------------------------------------------------
# AC-NPC-CR-08 — party_has_tag() finds tag in recruitment_tags
# ---------------------------------------------------------------------------

func test_party_has_tag_returns_true_for_recruitment_tag() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	_inject(_make_companion_record(&"healer_npc", [&"healer"], []))
	assert_true(_registry.party_has_tag(&"healer"),
		"party_has_tag must return true when tag is in recruitment_tags")

# ---------------------------------------------------------------------------
# AC-NPC-CR-08b — party_has_tag() ignores tags on non-COMPANION records
# ---------------------------------------------------------------------------

func test_party_has_tag_ignores_non_companion_records() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	var quest_npc := NPCRecord.new()
	quest_npc.npc_id = &"jin"
	quest_npc.relationship_state = NPCRecord.RelationshipState.QUEST_ACTIVE
	quest_npc.recruitment_tags = [&"lockpick"]
	_inject(quest_npc)
	_inject(_make_companion_record(&"mira"))
	assert_false(_registry.party_has_tag(&"lockpick"),
		"party_has_tag must return false for tags on non-COMPANION NPC")

# ---------------------------------------------------------------------------
# AC-NPC-CR-08c — party_has_tag() finds tag in bond_tags
# ---------------------------------------------------------------------------

func test_party_has_tag_returns_true_for_bond_tag() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	_inject(_make_companion_record(&"mira", [], [&"secret_path"]))
	assert_true(_registry.party_has_tag(&"secret_path"),
		"party_has_tag must return true when tag is in bond_tags")

# ---------------------------------------------------------------------------
# AC-NPC-CR-14 — is_initialized == false before add_child
# ---------------------------------------------------------------------------

func test_is_initialized_false_before_ready() -> void:
	assert_false(_registry.is_initialized,
		"is_initialized must be false before add_child / _ready()")

# ---------------------------------------------------------------------------
# AC-NPC-CR-15 — is_initialized == true after _ready()
# ---------------------------------------------------------------------------

func test_is_initialized_true_after_ready() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	assert_true(_registry.is_initialized,
		"is_initialized must be true after _ready() completes")

# ---------------------------------------------------------------------------
# AC-NPC-EC-06 — empty registry safe defaults
# ---------------------------------------------------------------------------

func test_empty_registry_get_companions_returns_empty_array() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	var companions: Array[NPCRecord] = _registry.get_companions()
	assert_eq(companions.size(), 0, "empty registry get_companions() must return []")

func test_empty_registry_party_has_tag_returns_false() -> void:
	add_child_autofree(_registry)
	await get_tree().process_frame
	assert_false(_registry.party_has_tag(&"any"),
		"empty registry party_has_tag() must return false")
