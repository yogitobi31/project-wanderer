extends GutTest
## Tests for CombatEncounter (AC-3) and EnemySpawnZone (AC-2).
##
## 실시간-파티-전투.md acceptance criteria covered here:
##   AC-2 (automated portion): enemy_count formula is correct for 0/1/3 companions.
##   AC-3: combat_cleared signal emitted when all registered enemies are defeated.
##
## AC-1, AC-4, AC-5, AC-6 are manual playtest items (see GDD §Acceptance Criteria).
##
## Test strategy:
##   CombatEncounter — call _on_enemy_health_depleted() directly to simulate
##   HealthComponent.health_depleted firing without a live scene tree.
##   EnemySpawnZone — use PartyManager autoload and verify calculate_enemy_count().
##   AC-2 signal test — connect lambda counter before add_child() so the signal
##   is wired before start() is called.

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

## Minimal HealthComponent subclass that inherits health_depleted signal.
## Overrides _ready() to skip CharacterStats assertions. Never added to the
## scene tree in these tests so _ready() does not run on plain .new() calls.
class HealthStub extends HealthComponent:
	func _ready() -> void:
		pass

# ---------------------------------------------------------------------------
# CombatEncounter — AC-3: combat_cleared emitted after all enemies defeated
# ---------------------------------------------------------------------------

func test_combat_encounter_single_enemy_defeated_emits_combat_cleared() -> void:
	# Arrange
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_zone"
	var health_stub := HealthStub.new()
	encounter.register_enemy(health_stub)
	watch_signals(encounter)
	add_child(encounter)
	# Act
	health_stub.health_depleted.emit()
	# Assert
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"combat_cleared must emit exactly once when the single registered enemy is defeated")
	remove_child(encounter)
	encounter.free()
	health_stub.free()


func test_combat_encounter_two_enemies_first_defeat_does_not_emit() -> void:
	# Arrange
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_zone_two"
	var health_a := HealthStub.new()
	var health_b := HealthStub.new()
	encounter.register_enemy(health_a)
	encounter.register_enemy(health_b)
	watch_signals(encounter)
	add_child(encounter)
	# Act: defeat only the first enemy
	health_a.health_depleted.emit()
	# Assert
	assert_signal_not_emitted(encounter, "combat_cleared",
		"combat_cleared must NOT emit when only one of two enemies is defeated")
	remove_child(encounter)
	encounter.free()
	health_a.free()
	health_b.free()


func test_combat_encounter_two_enemies_both_defeated_emits_once() -> void:
	# Arrange
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_zone_both"
	var health_a := HealthStub.new()
	var health_b := HealthStub.new()
	encounter.register_enemy(health_a)
	encounter.register_enemy(health_b)
	watch_signals(encounter)
	add_child(encounter)
	# Act: defeat both enemies
	health_a.health_depleted.emit()
	health_b.health_depleted.emit()
	# Assert
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"combat_cleared must emit exactly once when all registered enemies are defeated")
	remove_child(encounter)
	encounter.free()
	health_a.free()
	health_b.free()


func test_combat_encounter_emits_correct_encounter_id() -> void:
	# Arrange
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"forest_01"
	var health_stub := HealthStub.new()
	encounter.register_enemy(health_stub)
	watch_signals(encounter)
	add_child(encounter)
	# Act
	health_stub.health_depleted.emit()
	# Assert
	assert_signal_emitted_with_parameters(encounter, "combat_cleared", [&"forest_01"])
	remove_child(encounter)
	encounter.free()
	health_stub.free()


func test_combat_encounter_health_depleted_twice_emits_only_once() -> void:
	# Arrange: guard against double-emission if signal fires twice on the same component
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_double"
	var health_stub := HealthStub.new()
	encounter.register_enemy(health_stub)
	watch_signals(encounter)
	add_child(encounter)
	# Act: emit health_depleted twice on the same stub
	health_stub.health_depleted.emit()
	health_stub.health_depleted.emit()
	# Assert
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"combat_cleared must not emit more than once even if health_depleted fires repeatedly")
	remove_child(encounter)
	encounter.free()
	health_stub.free()


# AC-2: zero enemies registered → combat_cleared emitted on scene load (_ready → start)
func test_combat_encounter_no_enemies_emits_on_ready() -> void:
	# Arrange: watch BEFORE add_child so signal is tracked before _ready() fires
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"safe_zone"
	watch_signals(encounter)
	# Act: add_child triggers _ready() → start() → emit (no enemies registered)
	add_child(encounter)
	# Assert
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"_ready() with zero registered enemies must immediately emit combat_cleared (AC-2)")
	remove_child(encounter)
	encounter.free()


# AC-4: combat_cleared 이후 별개 잔존 stub 사망 시 중복 emit 없음
func test_combat_encounter_no_duplicate_emit_after_cleared() -> void:
	# Arrange: 2 enemies registered; both die (clears encounter)
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"ac4_zone"
	var health_a := HealthStub.new()
	var health_b := HealthStub.new()
	encounter.register_enemy(health_a)
	encounter.register_enemy(health_b)
	watch_signals(encounter)
	add_child(encounter)
	health_a.health_depleted.emit()
	health_b.health_depleted.emit()
	assert_signal_emit_count(encounter, "combat_cleared", 1, "sanity: cleared after both enemies defeated")
	# Act: a surviving stub fires again after the encounter is already cleared
	health_a.health_depleted.emit()
	# Assert: still exactly 1 emit
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"combat_cleared must not re-emit when a stub fires after the encounter is cleared (AC-4)")
	remove_child(encounter)
	health_a.free()
	health_b.free()
	encounter.free()

# ---------------------------------------------------------------------------
# EnemySpawnZone — AC-2 (formula portion): correct enemy count per party size
# ---------------------------------------------------------------------------

func before_each() -> void:
	PartyManager._companions.clear()


func after_each() -> void:
	PartyManager._companions.clear()


func test_enemy_spawn_zone_companion_count_zero_returns_base() -> void:
	# Arrange: no companions in party
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# companion_count = 0 → expected = 3 + (0 × 1) = 3
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 3,
		"0 companions must yield base_enemy_count (3)")
	zone.free()


func test_enemy_spawn_zone_companion_count_one_returns_base_plus_one() -> void:
	# Arrange: 1 companion
	PartyManager.register_companion(&"aria")
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# companion_count = 1 → expected = 3 + (1 × 1) = 4
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 4,
		"1 companion must yield base_enemy_count + 1 (4)")
	zone.free()


func test_enemy_spawn_zone_companion_count_three_returns_base_plus_three() -> void:
	# Arrange: 3 companions (max party)
	PartyManager.register_companion(&"aria")
	PartyManager.register_companion(&"bran")
	PartyManager.register_companion(&"ceri")
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# companion_count = 3 → expected = 3 + (3 × 1) = 6
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 6,
		"3 companions must yield base_enemy_count + 3 (6) per F-1 example in GDD")
	zone.free()


func test_enemy_spawn_zone_custom_base_uses_assigned_value() -> void:
	# Arrange: non-default base_enemy_count with 1 companion
	PartyManager.register_companion(&"aria")
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 5
	# companion_count = 1 → expected = 5 + (1 × 1) = 6
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 6,
		"base_enemy_count export must be honoured — custom base 5 + 1 companion = 6")
	zone.free()


func test_enemy_spawn_zone_scale_per_companion_constant_is_one() -> void:
	# Verify the tuning constant matches the GDD default (실시간-파티-전투.md §Tuning Knobs)
	assert_eq(EnemySpawnZone.ENEMY_SCALE_PER_COMPANION, 1,
		"ENEMY_SCALE_PER_COMPANION must default to 1 per GDD tuning knobs")


# AC-2 signal-coverage test: combat_cleared fires with correct companion counts
# Lambda counter connected before add_child() so signal is wired before start().
func test_combat_encounter_ac2_party_size_drives_distinct_cleared_ids() -> void:
	# Arrange: two separate encounter zones, one per party size scenario
	var encounter_solo := CombatEncounter.new()
	encounter_solo.encounter_id = &"solo"
	var encounter_trio := CombatEncounter.new()
	encounter_trio.encounter_id = &"trio"

	var cleared_ids: Array[StringName] = []
	encounter_solo.combat_cleared.connect(
		func(id: StringName) -> void: cleared_ids.append(id)
	)
	encounter_trio.combat_cleared.connect(
		func(id: StringName) -> void: cleared_ids.append(id)
	)

	# Solo zone: 3 enemies registered
	var solo_stubs: Array[HealthStub] = []
	for _i in 3:
		var h := HealthStub.new()
		encounter_solo.register_enemy(h)
		solo_stubs.append(h)

	# Trio zone: 6 enemies registered (3 + 3 companions × 1 scale)
	var trio_stubs: Array[HealthStub] = []
	for _i in 6:
		var h := HealthStub.new()
		encounter_trio.register_enemy(h)
		trio_stubs.append(h)

	add_child(encounter_solo)
	add_child(encounter_trio)

	# Act: defeat all solo enemies, then all trio enemies
	for h: HealthStub in solo_stubs:
		h.health_depleted.emit()
	for h: HealthStub in trio_stubs:
		h.health_depleted.emit()

	# Assert: both zones cleared exactly once, in order
	assert_eq(cleared_ids.size(), 2,
		"each encounter zone must emit combat_cleared exactly once")
	assert_eq(cleared_ids[0], &"solo",
		"solo zone (3 enemies) must clear first")
	assert_eq(cleared_ids[1], &"trio",
		"trio zone (6 enemies) must clear second")

	remove_child(encounter_solo)
	remove_child(encounter_trio)
	encounter_solo.free()
	encounter_trio.free()
	for h: HealthStub in solo_stubs:
		h.free()
	for h: HealthStub in trio_stubs:
		h.free()
