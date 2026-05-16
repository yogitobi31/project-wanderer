extends Node
## Perf/stress spawner for C-6 (perf baseline) and C-7 (NavigationAgent2D stress test).
##
## Attached as PerfStressSpawner child in perf_stress_test.tscn.
## Open perf_stress_test.tscn → F6 → Godot Debugger Monitors에서 측정.
## main_map.tscn을 수정하지 않습니다.
##
## Controls:
##   T — NavigationAgent2D avoidance ON/OFF 토글 (OFF → ON 비교가 C-7 목적)
##   Q — Output 패널에 현재 FPS + avoidance 상태 출력

const CompanionScene := preload("res://src/characters/CompanionAI.tscn")
const StatsB := preload("res://assets/data/stats/companion_b_stats.tres")
const StatsC := preload("res://assets/data/stats/companion_c_stats.tres")

var _avoidance_on: bool = false
var _all_agents: Array[NavigationAgent2D] = []


func _ready() -> void:
	# 한 프레임 대기: main_map.gd의 _ready() 및 적 스폰이 완료된 뒤 실행
	await get_tree().process_frame

	var root: Node2D = get_parent() as Node2D
	var player: Node2D = root.get_node_or_null("PlayerController") as Node2D

	_spawn_extra_companions(root, player)

	# 씬 내 모든 NavigationAgent2D 수집 (동료 + 적)
	for agent in root.find_children("*", "NavigationAgent2D", true, false):
		if agent is NavigationAgent2D:
			_all_agents.append(agent as NavigationAgent2D)

	print("[PerfTest] 준비 완료 — agents=%d  T: avoidance 토글  Q: 상태 출력" % _all_agents.size())


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_T:
			_toggle_avoidance()
		KEY_Q:
			_print_stats()


func _spawn_extra_companions(root: Node2D, player: Node2D) -> void:
	var configs := [
		{pos = Vector2(148, 150), slot = 1, stats = StatsB.duplicate()},
		{pos = Vector2(128, 160), slot = 2, stats = StatsC.duplicate()},
	]
	for cfg in configs:
		var companion: Node = CompanionScene.instantiate()
		companion.position = cfg.pos
		companion.stats = cfg.stats
		companion.party_slot = cfg.slot
		if is_instance_valid(player):
			companion.player_target = player

		# HealthComponent stats: add_child 전에 설정해야 _ready() assertion 통과
		var hc: Node = companion.get_node("HealthComponent")
		hc.stats = cfg.stats

		root.add_child(companion)


func _toggle_avoidance() -> void:
	_avoidance_on = not _avoidance_on
	for agent in _all_agents:
		if is_instance_valid(agent):
			agent.avoidance_enabled = _avoidance_on
	print("[PerfTest] avoidance_enabled = %s" % _avoidance_on)


func _print_stats() -> void:
	print("[PerfTest] FPS=%d  avoidance=%s  agents=%d" % [
		Engine.get_frames_per_second(),
		_avoidance_on,
		_all_agents.size(),
	])
