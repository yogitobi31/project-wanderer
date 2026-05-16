class_name CompanionAI
extends CharacterBody2D
## Companion character AI controller: FOLLOWING, CHASING, ATTACKING, and DEAD states.
##
## Follows the player via NavigationAgent2D with per-slot formation offsets.
## Transitions to CHASING when DetectionArea2D detects an enemy body.
## Transitions to ATTACKING when within ATTACK_RANGE of the current target.
## Transitions to DEAD when HealthComponent emits health_depleted.
## avoidance_enabled is always false until a performance profile confirms safety.
##
## Required node structure:
##   CompanionAI (CharacterBody2D, Layer=player_body(2), Mask=world(1))
##   +-- CollisionShape2D
##   +-- HealthComponent
##   +-- HurtboxArea2D (Layer=player_hurtbox(6), Mask=enemy_hitbox(5))
##   |   +-- CollisionShape2D
##   +-- HitboxArea2D  (Layer=player_hitbox(4), Mask=enemy_hurtbox(7), monitoring=false)
##   |   +-- CollisionShape2D
##   +-- NavigationAgent2D
##   +-- AttackCooldownTimer (wait_time=1.0, one_shot=false)
##   +-- AttackActiveTimer   (wait_time=0.2, one_shot=true)
##   +-- DetectionArea2D (Layer=player_body(2), Mask=enemy_body(3))
##       +-- CollisionShape2D
##
## Usage:
##   companion.stats = preload("res://assets/data/stats/companion_a.tres").duplicate()
##   companion.player_target = player_node
##   companion.party_slot = 0   # 0, 1, or 2

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { FOLLOWING, CHASING, ATTACKING, DEAD }

# ---------------------------------------------------------------------------
# Constants - ADR-0006 S.2
# ---------------------------------------------------------------------------

## Companion stops moving when it reaches within this distance of its offset destination.
const FOLLOW_STOP_DISTANCE: float = 40.0

## Companion teleports to the player when farther than this distance (out-of-screen catch-up).
const TELEPORT_THRESHOLD: float = 600.0

## World-space offsets from player position per party slot. Prevents companion overlap.
const COMPANION_OFFSETS: Array[Vector2] = [
	Vector2(-60.0, 20.0),
	Vector2(60.0, 20.0),
	Vector2(0.0, 50.0),
]

## Distance at which the companion stops chasing and begins attacking.
const ATTACK_RANGE: float = 60.0

## Seconds between each attack activation pulse.
const ATTACK_COOLDOWN: float = 1.0

## Seconds the HitboxArea2D stays monitoring=true per attack pulse.
const ATTACK_ACTIVE_DURATION: float = 0.2

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## CharacterStats resource for this companion. Assign in Inspector or at spawn time.
@export var stats: CharacterStats

## Party slot index (0-2). Determines which COMPANION_OFFSETS entry to use.
@export_range(0, 2, 1) var party_slot: int = 0

## Player node to follow. Assign after the companion joins the party.
@export var player_target: CharacterBody2D

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var hitbox_area: Area2D = $HitboxArea2D
@onready var health_component: Node = $HealthComponent
@onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var _attack_active_timer: Timer = $AttackActiveTimer

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _state: State = State.FOLLOWING
var _current_target: Node2D = null
var _enemies_in_range: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-12, -16, 24, 32), Color(0.2, 0.8, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(-10, -20), "ALLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

func _ready() -> void:
	queue_redraw()
	assert(is_instance_valid(navigation_agent),
		"CompanionAI: NavigationAgent2D child missing on %s" % get_path())
	assert(is_instance_valid(hitbox_area),
		"CompanionAI: HitboxArea2D child missing on %s" % get_path())
	assert(is_instance_valid(_attack_cooldown_timer),
		"CompanionAI: AttackCooldownTimer child missing on %s" % get_path())
	assert(is_instance_valid(_attack_active_timer),
		"CompanionAI: AttackActiveTimer child missing on %s" % get_path())
	navigation_agent.avoidance_enabled = false
	if is_instance_valid(detection_area):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	if is_instance_valid(health_component):
		health_component.health_depleted.connect(_on_health_depleted)
	_attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	_attack_active_timer.timeout.connect(_on_attack_active_timeout)


func _physics_process(_delta: float) -> void:
	match _state:
		State.FOLLOWING:  _process_following()
		State.CHASING:    _process_chasing()
		State.ATTACKING:  _process_attacking()
		State.DEAD:       pass

# ---------------------------------------------------------------------------
# Public helpers - pure logic, testable without NavigationAgent2D
# ---------------------------------------------------------------------------

## Returns the world-space follow destination for the current party slot.
## Falls back to own position when player_target is invalid.
func get_follow_destination() -> Vector2:
	if not is_instance_valid(player_target):
		return global_position
	return player_target.global_position + COMPANION_OFFSETS[party_slot]


## Returns true when dist_to_player exceeds TELEPORT_THRESHOLD.
func should_teleport(dist_to_player: float) -> bool:
	return dist_to_player > TELEPORT_THRESHOLD


## Returns true when the companion is within FOLLOW_STOP_DISTANCE of dest.
func should_stop_at(dest: Vector2) -> bool:
	return global_position.distance_to(dest) <= FOLLOW_STOP_DISTANCE

# ---------------------------------------------------------------------------
# Private - state handlers
# ---------------------------------------------------------------------------

func _process_following() -> void:
	if not is_instance_valid(player_target) or not is_instance_valid(stats):
		return
	var dist_to_player: float = global_position.distance_to(player_target.global_position)
	if should_teleport(dist_to_player):
		global_position = get_follow_destination()
		return
	var dest: Vector2 = get_follow_destination()
	navigation_agent.target_position = dest
	if should_stop_at(dest):
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		var next: Vector2
		if not navigation_agent.is_navigation_finished():
			next = navigation_agent.get_next_path_position()
		else:
			next = dest
		velocity = (next - global_position).normalized() * stats.spd
		move_and_slide()


func _process_chasing() -> void:
	if not is_instance_valid(_current_target):
		_state = State.FOLLOWING
		return
	if not is_instance_valid(stats):
		return
	var dist_to_target: float = global_position.distance_to(_current_target.global_position)
	if dist_to_target <= ATTACK_RANGE:
		_state = State.ATTACKING
		velocity = Vector2.ZERO
		_attack_cooldown_timer.start(ATTACK_COOLDOWN)
		return
	navigation_agent.target_position = _current_target.global_position
	var next: Vector2
	if not navigation_agent.is_navigation_finished():
		next = navigation_agent.get_next_path_position()
	else:
		next = _current_target.global_position
	velocity = (next - global_position).normalized() * stats.spd
	move_and_slide()


func _process_attacking() -> void:
	if not is_instance_valid(_current_target):
		_stop_attack()
		_state = State.FOLLOWING
		return
	velocity = Vector2.ZERO


## Stops all attack timers and disables the hitbox. Safe to call from any state.
func _stop_attack() -> void:
	_attack_cooldown_timer.stop()
	_attack_active_timer.stop()
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = false

# ---------------------------------------------------------------------------
# Private - signal handlers
# ---------------------------------------------------------------------------

func _on_attack_cooldown_timeout() -> void:
	if _state != State.ATTACKING:
		return
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = true
	_attack_active_timer.start(ATTACK_ACTIVE_DURATION)


func _on_attack_active_timeout() -> void:
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = false


func _on_health_depleted() -> void:
	_state = State.DEAD
	_stop_attack()
	if is_instance_valid(detection_area):
		detection_area.monitoring = false
	set_physics_process(false)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _state == State.DEAD or not body.is_in_group("enemies"):
		return
	if not _enemies_in_range.has(body):
		_enemies_in_range.append(body)
	_current_target = body
	_state = State.CHASING


func _on_detection_area_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)
	if _enemies_in_range.is_empty():
		if _state == State.ATTACKING:
			_stop_attack()
		_current_target = null
		_state = State.FOLLOWING
	elif body == _current_target:
		while not _enemies_in_range.is_empty() and not is_instance_valid(_enemies_in_range.back()):
			_enemies_in_range.pop_back()
		if _enemies_in_range.is_empty():
			if _state == State.ATTACKING:
				_stop_attack()
			_current_target = null
			_state = State.FOLLOWING
		else:
			_current_target = _enemies_in_range.back()
			if _state == State.ATTACKING:
				_stop_attack()
				_state = State.CHASING
