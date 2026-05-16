class_name EnemyAI
extends CharacterBody2D
## Enemy AI controller: IDLE, CHASING, ATTACKING, and DEAD states.
##
## Detects bodies in "player" and "companions" groups via DetectionArea2D.
## Chases and attacks using the same NavigationAgent2D pattern as CompanionAI (ADR-0006).
## Target priority: player group > nearest companions group body.
## avoidance_enabled is always false until a performance profile confirms safety.
##
## Required node structure:
##   EnemyAI (CharacterBody2D, Layer=enemy_body(3), Mask=world(1))
##   |-- CollisionShape2D
##   |-- HealthComponent
##   |-- HurtboxArea2D (Layer=enemy_hurtbox(7), Mask=player_hitbox(4))
##   |   +-- CollisionShape2D
##   |-- HitboxArea2D  (Layer=enemy_hitbox(5), Mask=player_hurtbox(6), monitoring=false)
##   |   +-- CollisionShape2D
##   |-- NavigationAgent2D
##   |-- AttackCooldownTimer (wait_time=1.0, one_shot=false)
##   |-- AttackActiveTimer   (wait_time=0.2, one_shot=true)
##   +-- DetectionArea2D (Layer=enemy_body(3), Mask=player_body(2))
##       +-- CollisionShape2D
##
## Usage:
##   enemy.stats = preload("res://assets/data/stats/enemy_basic.tres").duplicate()

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { IDLE, CHASING, ATTACKING, DEAD }

# ---------------------------------------------------------------------------
# Constants - ADR-0006 S.3
# ---------------------------------------------------------------------------

## Distance at which the enemy stops chasing and begins attacking.
const ENEMY_ATTACK_RANGE: float = 60.0

## Seconds between each attack activation pulse.
const ENEMY_ATTACK_COOLDOWN: float = 1.0

## Seconds the HitboxArea2D stays monitoring=true per attack pulse.
const ENEMY_ATTACK_ACTIVE_DURATION: float = 0.2

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## CharacterStats resource for this enemy. Assign in Inspector or at spawn time.
@export var stats: CharacterStats

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea2D
@onready var hitbox_area: Area2D = $HitboxArea2D
@onready var health_component: Node = $HealthComponent
@onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var _attack_active_timer: Timer = $AttackActiveTimer
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _state: State = State.IDLE
var _current_target: Node2D = null
## All valid player/companion bodies currently inside DetectionArea2D.
var _bodies_in_range: Array[Node2D] = []

# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-10, -14, 20, 28), Color(1.0, 0.3, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(-10, -18), "ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

func _ready() -> void:
	queue_redraw()
	assert(is_instance_valid(navigation_agent),
		"EnemyAI: NavigationAgent2D child missing on %s" % get_path())
	assert(is_instance_valid(hitbox_area),
		"EnemyAI: HitboxArea2D child missing on %s" % get_path())
	assert(is_instance_valid(_attack_cooldown_timer),
		"EnemyAI: AttackCooldownTimer child missing on %s" % get_path())
	assert(is_instance_valid(_attack_active_timer),
		"EnemyAI: AttackActiveTimer child missing on %s" % get_path())
	assert(is_instance_valid(_animation_player),
		"EnemyAI: AnimationPlayer child missing on %s" % get_path())
	navigation_agent.avoidance_enabled = false
	if is_instance_valid(detection_area):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	if is_instance_valid(health_component):
		health_component.health_depleted.connect(_on_health_depleted)
	if is_instance_valid(hitbox_area):
		hitbox_area.area_entered.connect(_on_hitbox_area_entered)
	_attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	_attack_active_timer.timeout.connect(_on_attack_active_timeout)
	_animation_player.animation_finished.connect(_on_death_animation_finished)
	_setup_death_animation()


func _physics_process(_delta: float) -> void:
	match _state:
		State.IDLE:      pass
		State.CHASING:   _process_chasing()
		State.ATTACKING: _process_attacking()
		State.DEAD:      pass

# ---------------------------------------------------------------------------
# Public helpers - testable without NavigationAgent2D
# ---------------------------------------------------------------------------

## Returns the highest-priority valid target from _bodies_in_range.
## Purges freed references before scanning.
## Priority: any body in "player" group first, then nearest "companions" body.
## Returns null when _bodies_in_range is empty or contains no valid targets.
func select_target() -> Node2D:
	var i: int = _bodies_in_range.size() - 1
	while i >= 0:
		if not is_instance_valid(_bodies_in_range[i]):
			_bodies_in_range.remove_at(i)
		else:
			i -= 1

	for body: Node2D in _bodies_in_range:
		if body.is_in_group("player"):
			return body

	var nearest: Node2D = null
	var min_dist: float = INF
	for body: Node2D in _bodies_in_range:
		if body.is_in_group("companions"):
			var d: float = global_position.distance_to(body.global_position)
			if d < min_dist:
				min_dist = d
				nearest = body
	return nearest

# ---------------------------------------------------------------------------
# Private - state handlers
# ---------------------------------------------------------------------------

func _process_chasing() -> void:
	if not is_instance_valid(_current_target):
		_state = State.IDLE
		return
	if not is_instance_valid(stats):
		return
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist <= ENEMY_ATTACK_RANGE:
		_state = State.ATTACKING
		velocity = Vector2.ZERO
		move_and_slide()
		_attack_cooldown_timer.start(ENEMY_ATTACK_COOLDOWN)
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
		_state = State.IDLE
		return
	velocity = Vector2.ZERO
	move_and_slide()


## Stops all attack timers and disables the hitbox. Safe to call from any state.
func _stop_attack() -> void:
	_attack_cooldown_timer.stop()
	_attack_active_timer.stop()
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = false

# ---------------------------------------------------------------------------
# Private - helpers
# ---------------------------------------------------------------------------

## Builds a 0.5-second fade-out animation for the placeholder visuals.
## Animates modulate alpha 1→0 then calls queue_free() via animation_finished.
func _setup_death_animation() -> void:
	var anim: Animation = Animation.new()
	anim.length = 0.5
	var track_idx: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath(".:modulate"))
	anim.track_insert_key(track_idx, 0.0, Color.WHITE)
	anim.track_insert_key(track_idx, 0.5, Color(1.0, 1.0, 1.0, 0.0))
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(&"death", anim)
	_animation_player.add_animation_library(&"", lib)

# ---------------------------------------------------------------------------
# Private - signal handlers
# ---------------------------------------------------------------------------

func _on_hitbox_area_entered(area: Area2D) -> void:
	var health_comp: HealthComponent = area.get_parent().get_node_or_null("HealthComponent")
	if health_comp and is_instance_valid(stats):
		health_comp.hit_confirmed({"damage": stats.atk, "knockback": 0.0, "source": self})

func _on_attack_cooldown_timeout() -> void:
	if _state != State.ATTACKING:
		return
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = true
	_attack_active_timer.start(ENEMY_ATTACK_ACTIVE_DURATION)


func _on_attack_active_timeout() -> void:
	if is_instance_valid(hitbox_area):
		hitbox_area.monitoring = false


func _on_health_depleted() -> void:
	_state = State.DEAD
	_stop_attack()
	if is_instance_valid(detection_area):
		detection_area.monitoring = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_animation_player.play(&"death")


func _on_death_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"death":
		queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _state == State.DEAD:
		return
	if not body.is_in_group("player") and not body.is_in_group("companions"):
		return
	if not _bodies_in_range.has(body):
		_bodies_in_range.append(body)
	_current_target = select_target()
	if is_instance_valid(_current_target):
		_state = State.CHASING


func _on_detection_area_body_exited(body: Node2D) -> void:
	_bodies_in_range.erase(body)
	if _bodies_in_range.is_empty():
		if _state == State.ATTACKING:
			_stop_attack()
		_current_target = null
		_state = State.IDLE
		return
	var new_target: Node2D = select_target()
	if not is_instance_valid(new_target):
		if _state == State.ATTACKING:
			_stop_attack()
		_current_target = null
		_state = State.IDLE
		return
	if new_target != _current_target:
		if _state == State.ATTACKING:
			_stop_attack()
			_state = State.CHASING
		_current_target = new_target
