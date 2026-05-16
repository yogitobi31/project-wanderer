class_name EnemySpawnZone
extends Node2D
## Spawns EnemyAI instances at scene load based on party size, then registers
## each with a CombatEncounter (실시간-파티-전투.md R-5, F-1; TR-combat-002).
##
## Place this node in a map scene. Assign enemy_scene and combat_encounter in
## the Inspector. On _ready(), enemies are instantiated as siblings of this
## node and their HealthComponents are registered with the CombatEncounter.
##
## Tuning knobs (실시간-파티-전투.md S.Tuning Knobs):
##   base_enemy_count           default 3   safe range 1-8
##   ENEMY_SCALE_PER_COMPANION  default 1   safe range 0-2
##   spawn_radius               default 80  pixels, controls spread

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Additional enemies spawned per companion in the party (ADR-0006 S.6).
const ENEMY_SCALE_PER_COMPANION: int = 1

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Enemy scene to instantiate. Must have a HealthComponent child node.
@export var enemy_scene: PackedScene

## CombatEncounter to register spawned enemies with.
## If null, enemies are spawned but not tracked for combat clear.
@export var combat_encounter: CombatEncounter

## Base number of enemies when the player has no companions.
@export var base_enemy_count: int = 3

## Radius in pixels used to distribute spawn positions around this node.
@export var spawn_radius: float = 80.0

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	if enemy_scene == null:
		push_error("EnemySpawnZone: enemy_scene not assigned on %s" % get_path())
		return
	call_deferred("_spawn_enemies")

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Returns total enemies to spawn: base_enemy_count + (companion_count x ENEMY_SCALE_PER_COMPANION).
##
## Formula (F-1 - 실시간-파티-전투.md S.Tuning Knobs). Example: 3 companions -> 3 + 3 = 6.
##
## Example:
##   var count := zone.calculate_enemy_count()
func calculate_enemy_count() -> int:
	return base_enemy_count + (PartyManager.companion_count * ENEMY_SCALE_PER_COMPANION)

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _spawn_enemies() -> void:
	var count: int = calculate_enemy_count()
	var parent: Node = get_parent()
	for i: int in count:
		var enemy: EnemyAI = enemy_scene.instantiate() as EnemyAI
		if enemy == null:
			push_error("EnemySpawnZone: enemy_scene did not instantiate as EnemyAI")
			continue
		var angle: float = TAU * i / count
		var offset: Vector2 = Vector2.from_angle(angle) * spawn_radius
		parent.add_child(enemy)
		enemy.global_position = global_position + offset
		if is_instance_valid(combat_encounter):
			var hc: HealthComponent = enemy.get_node("HealthComponent") as HealthComponent
			if hc != null:
				combat_encounter.register_enemy(hc)
			else:
				push_error("EnemySpawnZone: spawned enemy has no HealthComponent child")
