class_name SpikeEnemyAgent
extends CharacterBody2D

@export var move_speed: float = 80.0
@export var chase_target: Node2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 16.0
	nav_agent.max_speed = move_speed
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 32.0
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(_delta: float) -> void:
	if chase_target:
		nav_agent.target_position = chase_target.global_position

	if nav_agent.is_navigation_finished():
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = (next_pos - global_position).normalized()
	nav_agent.set_velocity(direction * move_speed)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
