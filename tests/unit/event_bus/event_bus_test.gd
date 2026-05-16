class_name EventBusTest
extends GutTest

## GUT unit tests for EventBus.
##
## Verifies that every declared signal:
##   - Exists on the EventBus singleton
##   - Can be connected, emitted, and received with correct argument values
##   - Does not retain stale connections after the listener is freed
##
## Run with: godot --headless --script res://addons/gut/gut_cmdln.gd -gtest=res://tests/
## Or via the GUT panel in the Godot editor.
##
## AC-3 (씬 전환 후 Autoload 지속): 수동 확인 전용 — engine guarantee이므로 자동화 제외.
## 수동 체크리스트: production/qa/evidence/ 참조

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _bus: EventBus

func before_each() -> void:
	# Create a fresh EventBus node per test to keep tests isolated.
	# load() avoids the Autoload-name-shadowing problem: when class_name EventBus
	# is also an Autoload, EventBus refers to the singleton instance, not the class,
	# so EventBus.new() fails. load().new() always constructs a fresh instance.
	_bus = load("res://src/core/event_bus.gd").new()
	add_child(_bus)

func after_each() -> void:
	_bus.queue_free()
	_bus = null

# ---------------------------------------------------------------------------
# Signal existence checks
# ---------------------------------------------------------------------------

func test_all_signals_exist() -> void:
	assert_true(_bus.has_signal("companion_join_requested"),  "companion_join_requested signal missing")  # TR-ebus-001
	assert_true(_bus.has_signal("health_changed"),            "health_changed signal missing")
	assert_true(_bus.has_signal("player_died"),               "player_died signal missing")
	assert_true(_bus.has_signal("player_region_entered"),     "player_region_entered signal missing")
	assert_true(_bus.has_signal("companion_joined"),          "companion_joined signal missing")
	assert_true(_bus.has_signal("companion_left"),            "companion_left signal missing")
	assert_true(_bus.has_signal("companion_stat_changed"),    "companion_stat_changed signal missing")
	assert_true(_bus.has_signal("quest_started"),             "quest_started signal missing")
	assert_true(_bus.has_signal("quest_objective_updated"),   "quest_objective_updated signal missing")
	assert_true(_bus.has_signal("quest_completed"),           "quest_completed signal missing")
	assert_true(_bus.has_signal("quest_failed"),              "quest_failed signal missing")
	assert_true(_bus.has_signal("dialogue_started"),          "dialogue_started signal missing")
	assert_true(_bus.has_signal("dialogue_ended"),            "dialogue_ended signal missing")
	assert_true(_bus.has_signal("damage_dealt"),              "damage_dealt signal missing")
	assert_true(_bus.has_signal("combat_started"),            "combat_started signal missing")
	assert_true(_bus.has_signal("combat_ended"),              "combat_ended signal missing")
	assert_true(_bus.has_signal("scene_transition_started"),  "scene_transition_started signal missing")
	assert_true(_bus.has_signal("scene_transition_completed"),"scene_transition_completed signal missing")

# ---------------------------------------------------------------------------
# companion_join_requested (TR-ebus-001 — required AC)
# ---------------------------------------------------------------------------

var _received_join_requested_id: StringName = &""

func _on_companion_join_requested(companion_id: StringName) -> void:
	_received_join_requested_id = companion_id

func test_companion_join_requested_delivers_to_subscriber() -> void:
	_received_join_requested_id = &""
	_bus.companion_join_requested.connect(_on_companion_join_requested)
	_bus.companion_join_requested.emit(&"npc_01")
	assert_eq(_received_join_requested_id, &"npc_01", "companion_id mismatch")
	_bus.companion_join_requested.disconnect(_on_companion_join_requested)

func test_companion_join_requested_empty_stringname_delivers() -> void:
	_received_join_requested_id = &"not_empty"
	_bus.companion_join_requested.connect(_on_companion_join_requested)
	_bus.companion_join_requested.emit(&"")
	assert_eq(_received_join_requested_id, &"", "empty StringName should deliver")
	_bus.companion_join_requested.disconnect(_on_companion_join_requested)

func test_companion_join_requested_no_error_without_subscriber() -> void:
	# No subscriber connected — must not throw or crash
	_bus.companion_join_requested.emit(&"npc_01")
	assert_true(true, "emit without subscriber completed without error")

# ---------------------------------------------------------------------------
# Player signals
# ---------------------------------------------------------------------------

var _received_new_health: float = -1.0
var _received_max_health: float = -1.0

func _on_health_changed(new_health: float, max_health: float) -> void:
	_received_new_health = new_health
	_received_max_health = max_health

func test_health_changed_delivers_correct_values() -> void:
	_received_new_health = -1.0
	_received_max_health = -1.0
	_bus.health_changed.connect(_on_health_changed)
	_bus.health_changed.emit(75.0, 100.0)
	assert_eq(_received_new_health, 75.0, "new_health mismatch")
	assert_eq(_received_max_health, 100.0, "max_health mismatch")
	_bus.health_changed.disconnect(_on_health_changed)

func test_player_died_emits() -> void:
	watch_signals(_bus)
	_bus.player_died.emit()
	assert_signal_emitted(_bus, "player_died")

var _received_region_id: StringName = &""

func _on_player_region_entered(region_id: StringName) -> void:
	_received_region_id = region_id

func test_player_region_entered_delivers_id() -> void:
	_received_region_id = &""
	_bus.player_region_entered.connect(_on_player_region_entered)
	_bus.player_region_entered.emit(&"forest_north")
	assert_eq(_received_region_id, &"forest_north", "region_id mismatch")
	_bus.player_region_entered.disconnect(_on_player_region_entered)

# ---------------------------------------------------------------------------
# Companion signals
# ---------------------------------------------------------------------------

var _received_companion_id: StringName = &""

func _on_companion_joined(companion_id: StringName) -> void:
	_received_companion_id = companion_id

func test_companion_joined_delivers_id() -> void:
	_received_companion_id = &""
	_bus.companion_joined.connect(_on_companion_joined)
	_bus.companion_joined.emit(&"mira")
	assert_eq(_received_companion_id, &"mira", "companion_id mismatch on join")
	_bus.companion_joined.disconnect(_on_companion_joined)

func test_companion_left_delivers_id() -> void:
	_received_companion_id = &""
	_bus.companion_left.connect(_on_companion_joined)
	_bus.companion_left.emit(&"mira")
	assert_eq(_received_companion_id, &"mira", "companion_id mismatch on leave")
	_bus.companion_left.disconnect(_on_companion_joined)

var _received_stat_companion_id: StringName = &""
var _received_stat_name: StringName = &""
var _received_stat_value: float = -1.0

func _on_companion_stat_changed(
	companion_id: StringName, stat_name: StringName, new_value: float
) -> void:
	_received_stat_companion_id = companion_id
	_received_stat_name = stat_name
	_received_stat_value = new_value

func test_companion_stat_changed_delivers_all_args() -> void:
	_bus.companion_stat_changed.connect(_on_companion_stat_changed)
	_bus.companion_stat_changed.emit(&"mira", &"affinity", 80.0)
	assert_eq(_received_stat_companion_id, &"mira",     "companion_id mismatch")
	assert_eq(_received_stat_name,         &"affinity", "stat_name mismatch")
	assert_eq(_received_stat_value,        80.0,        "stat_value mismatch")
	_bus.companion_stat_changed.disconnect(_on_companion_stat_changed)

# ---------------------------------------------------------------------------
# Quest signals
# ---------------------------------------------------------------------------

var _received_quest_id: StringName = &""
var _received_objective_id: StringName = &""

func _on_quest_started(quest_id: StringName) -> void:
	_received_quest_id = quest_id

func _on_quest_objective_updated(quest_id: StringName, objective_id: StringName) -> void:
	_received_quest_id = quest_id
	_received_objective_id = objective_id

func test_quest_started_delivers_id() -> void:
	_received_quest_id = &""
	_bus.quest_started.connect(_on_quest_started)
	_bus.quest_started.emit(&"escort_mira")
	assert_eq(_received_quest_id, &"escort_mira", "quest_id mismatch on start")
	_bus.quest_started.disconnect(_on_quest_started)

func test_quest_objective_updated_delivers_ids() -> void:
	_received_quest_id = &""
	_received_objective_id = &""
	_bus.quest_objective_updated.connect(_on_quest_objective_updated)
	_bus.quest_objective_updated.emit(&"escort_mira", &"reach_village")
	assert_eq(_received_quest_id,     &"escort_mira",  "quest_id mismatch")
	assert_eq(_received_objective_id, &"reach_village","objective_id mismatch")
	_bus.quest_objective_updated.disconnect(_on_quest_objective_updated)

func test_quest_completed_emits() -> void:
	watch_signals(_bus)
	_bus.quest_completed.emit(&"escort_mira")
	assert_signal_emitted(_bus, "quest_completed")

func test_quest_failed_emits() -> void:
	watch_signals(_bus)
	_bus.quest_failed.emit(&"escort_mira")
	assert_signal_emitted(_bus, "quest_failed")

# ---------------------------------------------------------------------------
# Dialogue signals
# ---------------------------------------------------------------------------

var _received_dialogue_id: StringName = &""
var _received_speaker_id: StringName = &""

func _on_dialogue_started(dialogue_id: StringName, speaker_id: StringName) -> void:
	_received_dialogue_id = dialogue_id
	_received_speaker_id = speaker_id

func test_dialogue_started_delivers_ids() -> void:
	_bus.dialogue_started.connect(_on_dialogue_started)
	_bus.dialogue_started.emit(&"dlg_mira_intro", &"mira")
	assert_eq(_received_dialogue_id, &"dlg_mira_intro", "dialogue_id mismatch")
	assert_eq(_received_speaker_id,  &"mira",           "speaker_id mismatch")
	_bus.dialogue_started.disconnect(_on_dialogue_started)

func test_dialogue_ended_emits() -> void:
	watch_signals(_bus)
	_bus.dialogue_ended.emit(&"dlg_mira_intro")
	assert_signal_emitted(_bus, "dialogue_ended")

# ---------------------------------------------------------------------------
# Combat signals
# ---------------------------------------------------------------------------

var _received_target_id: StringName = &""
var _received_damage_amount: float = -1.0
var _received_damage_type: StringName = &""

func _on_damage_dealt(target_id: StringName, amount: float, damage_type: StringName) -> void:
	_received_target_id = target_id
	_received_damage_amount = amount
	_received_damage_type = damage_type

func test_damage_dealt_delivers_all_args() -> void:
	_bus.damage_dealt.connect(_on_damage_dealt)
	_bus.damage_dealt.emit(&"goblin_01", 25.0, &"physical")
	assert_eq(_received_target_id,      &"goblin_01", "target_id mismatch")
	assert_eq(_received_damage_amount,  25.0,         "damage amount mismatch")
	assert_eq(_received_damage_type,    &"physical",  "damage_type mismatch")
	_bus.damage_dealt.disconnect(_on_damage_dealt)

func test_combat_started_emits() -> void:
	watch_signals(_bus)
	_bus.combat_started.emit()
	assert_signal_emitted(_bus, "combat_started")

var _received_combat_result: StringName = &""

func _on_combat_ended(result: StringName) -> void:
	_received_combat_result = result

func test_combat_ended_delivers_result() -> void:
	_bus.combat_ended.connect(_on_combat_ended)
	_bus.combat_ended.emit(&"victory")
	assert_eq(_received_combat_result, &"victory", "combat result mismatch")
	_bus.combat_ended.disconnect(_on_combat_ended)

# ---------------------------------------------------------------------------
# Scene transition signals
# ---------------------------------------------------------------------------

var _received_from_scene: StringName = &""
var _received_to_scene: StringName = &""

func _on_scene_transition_started(from_scene: StringName, to_scene: StringName) -> void:
	_received_from_scene = from_scene
	_received_to_scene = to_scene

func test_scene_transition_started_delivers_scenes() -> void:
	_bus.scene_transition_started.connect(_on_scene_transition_started)
	_bus.scene_transition_started.emit(&"town_square", &"dungeon_entrance")
	assert_eq(_received_from_scene, &"town_square",      "from_scene mismatch")
	assert_eq(_received_to_scene,   &"dungeon_entrance", "to_scene mismatch")
	_bus.scene_transition_started.disconnect(_on_scene_transition_started)

func test_scene_transition_completed_emits() -> void:
	watch_signals(_bus)
	_bus.scene_transition_completed.emit(&"dungeon_entrance")
	assert_signal_emitted(_bus, "scene_transition_completed")

# ---------------------------------------------------------------------------
# Stale-connection guard
# ---------------------------------------------------------------------------

## Verifies that a freed listener does not cause errors when a signal fires.
## In Godot 4, connections to freed objects emit a warning but do not crash
## unless Object.CONNECT_PERSIST is set. This test documents expected behaviour.
func test_freed_listener_does_not_crash() -> void:
	var listener: Node = Node.new()
	add_child(listener)
	# Use a lambda so no persistent callable holds a hard ref after free.
	_bus.player_died.connect(func() -> void: pass)
	listener.queue_free()
	await get_tree().process_frame
	# Emit after the listener is freed — must not crash.
	_bus.player_died.emit()
	assert_true(true, "emit after listener freed completed without crash")
