class_name HealthComponent
extends Node
## Combat health management component shared by all character types (player, companion, enemy).
##
## Receives hit_confirmed() calls from the HitboxArea2D -> HurtboxArea2D signal chain.
## Applies damage formula: final_damage = max(1, damage - stats.def).
## Emits health_changed and health_depleted - callers are responsible for death response.
##
## Iframes: on each confirmed hit, hurtbox.monitoring is set to false immediately.
## After IFRAMES_DURATION seconds the internal Timer restores it to true.
## On health_depleted the timer is stopped and monitoring stays false permanently.
##
## Usage:
##   # In HitboxArea2D.area_entered handler:
##   var health: HealthComponent = hurtbox.get_parent().get_node("HealthComponent")
##   health.hit_confirmed({"damage": stats.atk, "knockback": 0.0, "source": self})

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Invincibility-frames window in seconds. Character cannot be hit again during this period.
const IFRAMES_DURATION: float = 0.5

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal health_changed(current: int, maximum: int)
signal health_depleted()

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## CharacterStats resource for the owning character. Assign in the Inspector.
@export var stats: CharacterStats

## The HurtboxArea2D that receives incoming hit signals for this character.
## When assigned, monitoring is toggled to implement invincibility frames.
## Leave unassigned for characters that do not require iframe protection.
@export var hurtbox: Area2D

# ---------------------------------------------------------------------------
# Public variables
# ---------------------------------------------------------------------------

var current_health: int

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _iframe_timer: Timer

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	assert(stats != null, "HealthComponent: 'stats' export must be assigned on %s" % get_path())
	current_health = stats.max_hp
	_iframe_timer = Timer.new()
	_iframe_timer.wait_time = IFRAMES_DURATION
	_iframe_timer.one_shot = true
	_iframe_timer.timeout.connect(_on_iframes_expired)
	add_child(_iframe_timer)

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Receive a confirmed hit from the HitboxArea2D signal chain.
## Ignored silently if the character is already dead (current_health <= 0).
## On a live hit: applies damage, disables hurtbox monitoring for IFRAMES_DURATION,
## then emits health_changed. Emits health_depleted if health reaches zero.
func hit_confirmed(attack_data: Dictionary) -> void:
	if current_health <= 0:
		return
	var damage: int = int(attack_data.get("damage", 0))
	var final_damage: int = max(1, damage - stats.def)
	current_health = max(0, current_health - final_damage)
	if hurtbox:
		hurtbox.monitoring = false
		_iframe_timer.start()
	health_changed.emit(current_health, stats.max_hp)
	if current_health == 0:
		_iframe_timer.stop()
		health_depleted.emit()

## Restore health by amount, capped at stats.max_hp.
## Ignored silently if the character is dead (current_health <= 0).
func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(current_health + amount, stats.max_hp)
	health_changed.emit(current_health, stats.max_hp)

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

## Called by _iframe_timer when the invincibility window expires.
## Restores hurtbox.monitoring only if the character is still alive.
func _on_iframes_expired() -> void:
	if current_health > 0 and hurtbox:
		hurtbox.monitoring = true
