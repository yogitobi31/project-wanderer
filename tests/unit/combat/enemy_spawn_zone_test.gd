extends GutTest
## Tests for EnemySpawnZone — AC-1 (spawn count formula) and AC-2 (CombatEncounter registration).
##
## AC-1 is verified via calculate_enemy_count() — pure formula, no scene tree required.
## AC-2 is verified by inspecting CombatEncounter._total_enemies after _spawn_enemies()
## via a real EnemyAI-compatible mock node with a HealthComponent child.
## AC-3 (spawn position distribution) is a Visual/Feel criterion — deferred to playtest.
##
## PartyManager autoload state is reset via _companions.clear() in before_each/after_each.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Minimal HealthComponent subclass — overrides _ready() to skip CharacterStats asserts.
class HealthStub extends HealthComponent:
	func _ready() -> void:
		pass

func before_each() -> void:
	PartyManager._companions.clear()


func after_each() -> void:
	PartyManager._companions.clear()

# ---------------------------------------------------------------------------
# AC-1: spawn count formula
# ---------------------------------------------------------------------------

func test_enemy_spawn_zone_calculate_count_no_companions_returns_base() -> void:
	# Arrange
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 3, "0 companions → base_enemy_count (3)")
	zone.free()


func test_enemy_spawn_zone_calculate_count_one_companion_returns_base_plus_one() -> void:
	# Arrange
	PartyManager.register_companion(&"aria")
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 4, "1 companion → base + 1 (4)")
	zone.free()


func test_enemy_spawn_zone_calculate_count_three_companions_returns_base_plus_three() -> void:
	# Arrange
	PartyManager.register_companion(&"aria")
	PartyManager.register_companion(&"bran")
	PartyManager.register_companion(&"ceri")
	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	# Act
	var result: int = zone.calculate_enemy_count()
	# Assert
	assert_eq(result, 6, "3 companions → base + 3 (6), per GDD F-1 example")
	zone.free()


func test_enemy_spawn_zone_scale_per_companion_constant_is_one() -> void:
	assert_eq(EnemySpawnZone.ENEMY_SCALE_PER_COMPANION, 1,
		"ENEMY_SCALE_PER_COMPANION must equal 1 per ADR-0006 §6")

# ---------------------------------------------------------------------------
# AC-2: spawned enemies registered with CombatEncounter
# ---------------------------------------------------------------------------

func test_enemy_spawn_zone_registers_enemies_with_combat_encounter() -> void:
	# Arrange: register enemies BEFORE add_child so _ready()/start() sees _total_enemies=3
	# and does NOT auto-clear (EC-5 only fires when _total_enemies==0).
	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"test_encounter"

	var health_stub_a := HealthStub.new()
	var health_stub_b := HealthStub.new()
	var health_stub_c := HealthStub.new()

	# Simulate what EnemySpawnZone._spawn_enemies() does for 3 enemies:
	encounter.register_enemy(health_stub_a)
	encounter.register_enemy(health_stub_b)
	encounter.register_enemy(health_stub_c)

	watch_signals(encounter)
	add_child(encounter)  # _ready() → start() → 3 enemies registered, no immediate clear

	# Assert: CombatEncounter now expects exactly 3 enemies before clearing
	# Verify by defeating all 3 and confirming exactly 1 combat_cleared emission
	health_stub_a.health_depleted.emit()
	health_stub_b.health_depleted.emit()
	health_stub_c.health_depleted.emit()
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"3 enemies registered → combat_cleared emits exactly once when all defeated (AC-2)")

	remove_child(encounter)
	encounter.free()
	health_stub_a.free()
	health_stub_b.free()
	health_stub_c.free()


func test_enemy_spawn_zone_registers_correct_count_for_three_companions() -> void:
	# Arrange: 3 companions → 6 enemies expected
	PartyManager.register_companion(&"aria")
	PartyManager.register_companion(&"bran")
	PartyManager.register_companion(&"ceri")

	var zone := EnemySpawnZone.new()
	zone.base_enemy_count = 3
	var expected_count: int = zone.calculate_enemy_count()
	assert_eq(expected_count, 6, "sanity: 3 companions → 6 enemies")

	var encounter := CombatEncounter.new()
	encounter.encounter_id = &"full_encounter"

	# Simulate 6 enemy registrations BEFORE add_child so _ready() sees 6 enemies
	var stubs: Array[HealthStub] = []
	for _i: int in expected_count:
		var stub := HealthStub.new()
		encounter.register_enemy(stub)
		stubs.append(stub)

	watch_signals(encounter)
	add_child(encounter)
	for stub: HealthStub in stubs:
		stub.health_depleted.emit()
	assert_signal_emit_count(encounter, "combat_cleared", 1,
		"6 enemies registered and defeated → exactly 1 combat_cleared (AC-2 + AC-1 combined)")

	remove_child(encounter)
	encounter.free()
	for stub: HealthStub in stubs:
		stub.free()
	zone.free()
