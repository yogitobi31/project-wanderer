class_name CombatEncounter
extends Node
## Manages a single combat encounter: tracks live enemies and emits combat_cleared
## when all enemies are defeated (실시간-파티-전투.md R-4, AC-3).
##
## Each enemy must be registered via register_enemy() after spawning.
## CombatEncounter connects to each enemy's HealthComponent.health_depleted signal.
## When every registered enemy has been defeated, combat_cleared is emitted once.
##
## EC-5: If no enemies are registered before combat_started() is called,
## combat_cleared is emitted immediately.
##
## Usage:
##   # In the map scene _ready():
##   $CombatEncounter.encounter_id = &"zone_forest_01"
##   $CombatEncounter.register_enemy($EnemyA/HealthComponent)
##   $CombatEncounter.register_enemy($EnemyB/HealthComponent)

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted once when all registered enemies have been defeated.
## encounter_id matches the value assigned before registering enemies.
signal combat_cleared(encounter_id: StringName)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Unique identifier for this encounter zone. Assign in the Inspector or at spawn time.
@export var encounter_id: StringName = &""

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _total_enemies: int = 0
var _defeated_enemies: int = 0
var _cleared: bool = false

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	start()

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Register one enemy HealthComponent to be tracked by this encounter.
##
## Must be called before the encounter begins. Each call connects
## health_depleted to the internal defeat counter.
##
## Example:
##   encounter.register_enemy(get_node("Enemy/HealthComponent"))
func register_enemy(health_component: HealthComponent) -> void:
	_total_enemies += 1
	health_component.health_depleted.connect(_on_enemy_health_depleted)


## Begin the encounter. Immediately emits combat_cleared if no enemies were registered (EC-5).
## Safe to call multiple times - subsequent calls after the first are silently ignored.
func start() -> void:
	if _cleared:
		return
	if _total_enemies == 0:
		_cleared = true
		combat_cleared.emit(encounter_id)

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

func _on_enemy_health_depleted() -> void:
	if _cleared:
		return
	_defeated_enemies += 1
	if _defeated_enemies >= _total_enemies:
		_cleared = true
		combat_cleared.emit(encounter_id)
