class_name SpikeCompanionAgent
extends CharacterBody2D

@export var move_speed: float = 100.0
@export var target_position: Vector2 = Vector2.ZERO

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 16.0
	nav_agent.max_speed = move_speed
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.velocity_computed.connect(_on_velocity_computed)

	nav_agent.target_position = target_position

func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		# 목적지 도달 시 반대편으로 재설정 (계속 이동)
		target_position = -target_position
		nav_agent.target_position = target_position
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = (next_pos - global_position).normalized()
	nav_agent.set_velocity(direction * move_speed)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
