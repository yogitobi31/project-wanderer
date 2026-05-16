extends GutTest
## Integration tests: Core gameplay loop cross-system boundary checks.
##
## Verifies signal chains and state synchronisation across system boundaries
## that unit tests cannot cover in isolation.
##
## Coverage (7 tests):
##   1-3. CombatEncounter signal chain — register→defeat→combat_cleared
##   4.   PlayerController hitbox → HealthComponent damage propagation
##   5-7. DialogueManager.is_active ↔ InputMapManager.is_ui_active sync
##
## Save / load round-trip coverage lives in:
##   tests/integration/save_manager/save_load_roundtrip_test.gd

# ---------------------------------------------------------------------------
# Teardown — reset Autoload state touched by dialogue tests
# ---------------------------------------------------------------------------

func after_each() -> void:
	if DialogueManager.is_active:
		DialogueManager.end_dialogue()
	InputMapManager.set_ui_active(false)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_stats(max_hp: int = 80, atk: int = 20, def_val: int = 0) -> CharacterStats:
	var s := CharacterStats.new()
	s.base_max_hp = max_hp
	s.base_atk = atk
	s.base_def = def_val
	return s

# ---------------------------------------------------------------------------
# 1. CombatEncounter: single enemy defeat → combat_cleared
# ---------------------------------------------------------------------------

func test_combat_encounter_emits_cleared_when_single_enemy_defeated() -> void:
	# Arrange: HealthComponent added to tree so _ready() initialises current_health
	var health_comp := HealthComponent.new()
	health_comp.stats = _make_stats(10, 0, 0)
	add_child(health_comp)

	# CombatEncounter NOT in tree — register + start manually to skip EC-5 auto-fire
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_single_enemy"
	encounter.register_enemy(health_comp)
	watch_signals(encounter)
	encounter.start()

	# Act: lethal hit
	health_comp.hit_confirmed({"damage": 999, "knockback": 0.0, "source": null})

	# Assert
	assert_signal_emitted(encounter, "combat_cleared",
		"combat_cleared must emit when the only registered enemy is defeated")

	remove_child(health_comp)
	health_comp.free()
	encounter.free()

# ---------------------------------------------------------------------------
# 2. CombatEncounter EC-5: no enemies registered → immediate clear
# ---------------------------------------------------------------------------

func test_combat_encounter_clears_immediately_with_no_enemies() -> void:
	# Adding to tree triggers _ready() → start() → _total_enemies == 0 → clear
	var encounter := CombatEncounter.new()
	watch_signals(encounter)
	add_child(encounter)

	assert_signal_emitted(encounter, "combat_cleared",
		"combat_cleared must emit immediately when no enemies are registered (EC-5)")

	remove_child(encounter)
	encounter.free()

# ---------------------------------------------------------------------------
# 3. CombatEncounter: 3 enemies — does NOT clear until the last one falls
# ---------------------------------------------------------------------------

func test_combat_encounter_does_not_clear_until_last_enemy_defeated() -> void:
	# Arrange: 3 independent HealthComponents
	var hc1 := HealthComponent.new()
	var hc2 := HealthComponent.new()
	var hc3 := HealthComponent.new()
	hc1.stats = _make_stats(10, 0, 0)
	hc2.stats = _make_stats(10, 0, 0)
	hc3.stats = _make_stats(10, 0, 0)
	add_child(hc1)
	add_child(hc2)
	add_child(hc3)

	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_three_enemies"
	encounter.register_enemy(hc1)
	encounter.register_enemy(hc2)
	encounter.register_enemy(hc3)
	watch_signals(encounter)
	encounter.start()

	# Kill first two — must NOT clear yet
	hc1.hit_confirmed({"damage": 999, "knockback": 0.0, "source": null})
	hc2.hit_confirmed({"damage": 999, "knockback": 0.0, "source": null})
	assert_eq(get_signal_emit_count(encounter, "combat_cleared"), 0,
		"combat_cleared must NOT emit while one enemy remains")

	# Kill third — must clear now
	hc3.hit_confirmed({"damage": 999, "knockback": 0.0, "source": null})
	assert_signal_emitted(encounter, "combat_cleared",
		"combat_cleared must emit after all 3 enemies are defeated")

	for hc: HealthComponent in [hc1, hc2, hc3]:
		remove_child(hc)
		hc.free()
	encounter.free()

# ---------------------------------------------------------------------------
# 4. PlayerController._on_hitbox_area_entered → HealthComponent damage
# ---------------------------------------------------------------------------

func test_player_hitbox_propagates_stats_atk_as_damage() -> void:
	# Target: Node2D parent with HealthComponent child (def=0) + Area2D sibling (hurtbox).
	# _on_hitbox_area_entered does: area.get_parent().get_node_or_null("HealthComponent")
	var health_comp := HealthComponent.new()
	health_comp.stats = _make_stats(100, 0, 0)  # max_hp=100, def=0

	var target_parent := Node2D.new()
	target_parent.add_child(health_comp)  # class_name → node name "HealthComponent"

	var hurtbox := Area2D.new()
	target_parent.add_child(hurtbox)

	add_child(target_parent)  # HealthComponent._ready() → current_health = 100

	# Player with atk=30; target def=0 → final_damage = max(1, 30-0) = 30
	var player := PlayerController.new()
	player.stats = _make_stats(80, 30, 0)
	add_child(player)

	# Act: simulate hitbox area_entered with the hurtbox Area2D
	player._on_hitbox_area_entered(hurtbox)

	# Assert: 100 - 30 = 70
	assert_eq(health_comp.current_health, 70,
		"_on_hitbox_area_entered must deal stats.atk damage to the target HealthComponent")

	remove_child(target_parent)
	target_parent.free()
	remove_child(player)
	player.free()

# ---------------------------------------------------------------------------
# 5. DialogueManager.is_active true after start_dialogue
# ---------------------------------------------------------------------------

func test_dialogue_is_active_true_after_start_dialogue() -> void:
	assert_false(DialogueManager.is_active,
		"is_active must be false before any dialogue session")

	DialogueManager.start_dialogue(&"npc_test_aria")

	assert_true(DialogueManager.is_active,
		"is_active must be true immediately after start_dialogue()")

# after_each() calls end_dialogue()

# ---------------------------------------------------------------------------
# 6. start_dialogue syncs InputMapManager.is_ui_active
# ---------------------------------------------------------------------------

func test_dialogue_sets_ui_active_on_input_manager() -> void:
	assert_false(InputMapManager.is_ui_active,
		"is_ui_active must be false before dialogue starts")

	DialogueManager.start_dialogue(&"npc_test_aria")

	assert_true(InputMapManager.is_ui_active,
		"InputMapManager.is_ui_active must be true while dialogue is active — ADR-0003 is_active 차단 계약")

# after_each() calls end_dialogue()

# ---------------------------------------------------------------------------
# 7. end_dialogue resets both is_active and is_ui_active
# ---------------------------------------------------------------------------

func test_dialogue_is_active_and_ui_active_reset_after_end_dialogue() -> void:
	DialogueManager.start_dialogue(&"npc_test_aria")
	assert_true(DialogueManager.is_active)        # pre-condition
	assert_true(InputMapManager.is_ui_active)     # pre-condition

	DialogueManager.end_dialogue()

	assert_false(DialogueManager.is_active,
		"is_active must be false after end_dialogue()")
	assert_false(InputMapManager.is_ui_active,
		"InputMapManager.is_ui_active must be false after end_dialogue()")
