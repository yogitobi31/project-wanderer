class_name PlayerController
extends CharacterBody2D

## Root controller for the player character.
##
## Owns the FSM (IDLE / MOVING / ATTACKING / DEAD) and delegates
## physics movement to [method _process_movement].
##
## Scene structure (set in editor):
##   PlayerController (CharacterBody2D, Layer=player_body(2), Mask=world(1))
##   |-- CollisionShape2D
##   |-- HealthComponent
##   |-- HurtboxArea2D
##   +-- HitboxArea2D  (monitoring=false by default per ADR-0004)
##
## Usage:
##   Assign a [CharacterStats] resource to [member stats] in the Inspector.
##   The node handles movement and attack input automatically via [method _physics_process].

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when [member health_component] fires [signal HealthComponent.health_depleted].
## GameManager or a scene-level handler listens to this to trigger Game Over / respawn.
signal player_died()

# ---------------------------------------------------------------------------
# Constants and Enums
# ---------------------------------------------------------------------------

## Player FSM states.
enum State { IDLE, MOVING, ATTACKING, DEAD }

## Eight compass directions for sprite selection (E=0 clockwise to NE=7).
## Indexed so that _vec_to_direction() sector math maps directly: E=0, SE=1, … NE=7.
enum Direction { E = 0, SE = 1, S = 2, SW = 3, W = 4, NW = 5, N = 6, NE = 7 }

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Character stat resource. Must be assigned in the Inspector.
## All reads use computed properties (e.g. [member CharacterStats.spd]) - ADR-0005.
@export var stats: CharacterStats

# ---------------------------------------------------------------------------
# Private variables
# ---------------------------------------------------------------------------

var _state: State = State.IDLE
var _facing: Direction = Direction.S

# ---------------------------------------------------------------------------
# @onready variables
# ---------------------------------------------------------------------------

## HealthComponent child node.
## Null-safe: will be null when instantiated without a full scene (unit tests).
@onready var health_component: HealthComponent = (
	$HealthComponent if has_node("HealthComponent") else null
)

## HitboxArea2D child node.
## Null-safe: will be null in unit tests (no scene).
## monitoring is toggled by AnimationPlayer keyframes in-scene.
@onready var _hitbox: Area2D = (
	$HitboxArea2D if has_node("HitboxArea2D") else null
)

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	assert(stats != null,
		"PlayerController: 'stats' export must be assigned before entering the scene tree.")
	if _hitbox:
		_hitbox.area_entered.connect(_on_hitbox_area_entered)
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed_draw)
	else:
		push_warning("PlayerController: HealthComponent not found - health_depleted will not trigger death.")
	queue_redraw()

func _on_health_changed_draw(_cur: int, _max: int) -> void:
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(-12, -16, 24, 32), Color(0.3, 0.5, 1.0))
	draw_string(font, Vector2(-14, -22), "PLAYER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	if health_component:
		var hp_text: String = "HP:%d/%d" % [health_component.current_health, health_component.stats.max_hp]
		draw_string(font, Vector2(-20, 30), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.YELLOW)
	var dir_angle: float = _facing * (PI / 4.0)
	var dir_vec: Vector2 = Vector2(cos(dir_angle), sin(dir_angle)) * 14.0
	draw_line(Vector2.ZERO, dir_vec, Color.YELLOW, 2.0)

func _physics_process(_delta: float) -> void:
	if _state == State.DEAD:
		return
	if InputMapManager.is_ui_active:
		return
	if _get_attack_input():
		start_attack()
	_process_movement(_get_move_input())

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

## Initiates the ATTACKING state.
##
## No-op if the player is already ATTACKING or DEAD.
## In-scene, the AnimationPlayer plays the attack animation and controls
## [member _hitbox].monitoring via keyframes. On animation finish,
## [method _on_attack_finished] is called (connected in-scene) to return to IDLE.
##
## Tests call this directly to inject an attack without InputMapManager.
func start_attack() -> void:
	if _state == State.ATTACKING or _state == State.DEAD:
		return
	_state = State.ATTACKING

## Sets the player's world position for respawn placement.
##
## Called by [SceneTransitionManager] after a scene load completes to position
## the player at the correct spawn point.
func set_spawn_position(pos: Vector2) -> void:
	global_position = pos

# ---------------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------------

## Maps a movement vector to the nearest of eight compass directions.
##
## Uses atan2 sector math: the circle is divided into 8 equal 45° sectors,
## with each sector centred on its cardinal/diagonal direction.
## Returns [enum Direction] matching the enum integer layout (E=0 clockwise to NE=7).
##
## Pure function — safe to call from unit tests without a scene.
static func _vec_to_direction(v: Vector2) -> Direction:
	var a: float = fmod(v.angle() + TAU, TAU)
	return (int((a + PI / 8.0) / (PI / 4.0)) % 8) as Direction

## Returns the current movement input vector from [InputMapManager].
## Extracted as a seam so tests can call [method _process_movement] directly.
func _get_move_input() -> Vector2:
	return InputMapManager.get_move_vector()

## Returns whether the attack action was just pressed.
## Tests call [method start_attack] directly - this method is not unit-tested.
func _get_attack_input() -> bool:
	return Input.is_action_just_pressed("combat_attack")

## Applies movement and FSM transitions from a given input vector.
##
## Blocked in ATTACKING and DEAD states - velocity is zeroed and no state
## transition occurs. [method move_and_slide] is called unconditionally.
func _process_movement(move_vec: Vector2) -> void:
	if _state == State.ATTACKING or _state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if move_vec != Vector2.ZERO:
		velocity = move_vec * stats.spd
		_state = State.MOVING
		var new_facing: Direction = _vec_to_direction(move_vec)
		if new_facing != _facing:
			_facing = new_facing
			queue_redraw()
	else:
		velocity = Vector2.ZERO
		_state = State.IDLE
	move_and_slide()

## Called by [HitboxArea2D] `area_entered` signal when the hitbox overlaps a hurtbox.
##
## Looks up the [HealthComponent] on the hurtbox's parent and calls
## [method HealthComponent.hit_confirmed] with [member stats.atk] as damage.
## No-op if no [HealthComponent] is found.
##
## Tests call this directly with an injected hurtbox [Area2D].
func _on_hitbox_area_entered(area: Area2D) -> void:
	var health_comp: HealthComponent = area.get_parent().get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.hit_confirmed({"damage": stats.atk, "knockback": 0.0, "source": self})

## Called by AnimationPlayer `animation_finished` signal at the end of the attack animation.
##
## Resets state to IDLE and ensures [member _hitbox].monitoring is false as a safety net.
## Tests call this directly to simulate animation completion.
func _on_attack_finished() -> void:
	_state = State.IDLE
	if _hitbox:
		_hitbox.monitoring = false

## Called when [member health_component] emits [signal HealthComponent.health_depleted].
##
## Transitions FSM to DEAD and emits [signal player_died] for GameManager / scene handler.
## Tests call this directly to simulate death without a HealthComponent scene node.
func _on_health_depleted() -> void:
	_state = State.DEAD
	player_died.emit()
