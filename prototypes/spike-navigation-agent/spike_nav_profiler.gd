## NavigationAgent2D avoidance 프로파일러
##
## 측정 방식: Time.get_ticks_usec() 기반 물리 프레임 간 벽시계 시간 간격
##   - delta * 1000.0은 항상 16.67ms (물리 타임스텝 상수) → 부하 측정 불가
##   - 실제 부하가 있으면 프레임 처리 시간이 늘어나 간격이 16.67ms를 초과함
##   - 목표: 최대 간격 < 33ms (2배 초과 = 실질적 프레임 드롭)
##
## 합격 기준:
##   - 평균 간격 < 20ms (16.67ms ± 20% 허용)
##   - 33ms 초과 프레임 < 5% (심각한 스파이크 없음)
extends Node

const MEASURE_DURATION_SEC: float = 30.0
const WARMUP_SEC: float = 2.0   # 초기 로딩 안정화 제외
const AGENT_COUNT: int = 7
const TARGET_MS: float = 16.67
const SPIKE_THRESHOLD_MS: float = 33.0  # 2× 타임스텝

var _samples: Array[float] = []
var _elapsed: float = 0.0
var _done: bool = false
var _last_tick_us: int = 0

@onready var _status_label: Label = get_parent().get_node("HUD/StatusLabel")

func _ready() -> void:
	_setup_navigation_polygon()
	_setup_collision_shapes()
	_setup_enemy_targets()
	_status_label.text = "워밍업 중... (%.0f초)" % WARMUP_SEC
	print("[NavSpike] 씬 셋업 완료 — 측정 시작 (워밍업 %.0f초 포함)" % WARMUP_SEC)

func _setup_navigation_polygon() -> void:
	var nav_polygon := NavigationPolygon.new()
	nav_polygon.vertices = PackedVector2Array([
		Vector2(0, 0), Vector2(800, 0),
		Vector2(800, 600), Vector2(0, 600)
	])
	nav_polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	get_parent().get_node("NavigationRegion2D").navigation_polygon = nav_polygon
	print("[NavSpike] NavigationPolygon 설정 완료")

func _setup_collision_shapes() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	for child in get_parent().get_children():
		var col := child.get_node_or_null("CollisionShape2D")
		if col:
			col.shape = shape
	print("[NavSpike] CollisionShape2D 설정 완료")

func _setup_enemy_targets() -> void:
	var player: Node2D = get_parent().get_node("Player")
	for i in range(1, 5):
		var enemy: Node = get_parent().get_node_or_null("Enemy%d" % i)
		if enemy:
			enemy.chase_target = player
	print("[NavSpike] Enemy chase_target → Player 설정 완료")

func _physics_process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	var now_us := Time.get_ticks_usec()

	# 워밍업 이후부터 측정
	if _elapsed > WARMUP_SEC and _last_tick_us > 0:
		var interval_ms: float = (now_us - _last_tick_us) / 1000.0
		_samples.append(interval_ms)

	_last_tick_us = now_us

	# 화면 표시 (1초마다 갱신)
	if _elapsed > WARMUP_SEC and int(_elapsed) != int(_elapsed - delta):
		var remaining: float = MEASURE_DURATION_SEC - _elapsed
		var cur_avg: float = _current_avg()
		_status_label.text = (
			"측정 중: %.0f초 남음\n" % maxf(remaining, 0.0)
			+ "샘플 수: %d\n" % _samples.size()
			+ "현재 평균 간격: %.2f ms (목표 ≤20ms)" % cur_avg
		)

	if _elapsed >= MEASURE_DURATION_SEC:
		_done = true
		_print_report()

func _current_avg() -> float:
	if _samples.is_empty():
		return 0.0
	var total: float = 0.0
	for s: float in _samples:
		total += s
	return total / _samples.size()

func _print_report() -> void:
	var avg_ms: float = _current_avg()
	var max_ms: float = 0.0
	var spike_count: int = 0
	for s: float in _samples:
		if s > max_ms:
			max_ms = s
		if s > SPIKE_THRESHOLD_MS:
			spike_count += 1

	var spike_pct: float = float(spike_count) / _samples.size() * 100.0
	var pass_avg: bool = avg_ms < 20.0
	var pass_spike: bool = spike_pct < 5.0
	var verdict: String = "PASS" if (pass_avg and pass_spike) else "FAIL"

	print("=== NavigationAgent2D Spike 결과 ===")
	print("에이전트 수: %d (동료 3 + 적 4)" % AGENT_COUNT)
	print("측정 방식: 물리 프레임 간 벽시계 간격 (워밍업 %.0f초 제외)" % WARMUP_SEC)
	print("샘플 수: %d" % _samples.size())
	print("평균 간격: %.2f ms (목표 < 20ms) → %s" % [avg_ms, "OK" if pass_avg else "OVER"])
	print("최대 간격: %.2f ms" % max_ms)
	print("33ms 초과 프레임: %d / %d (%.1f%%) → %s" % [
		spike_count, _samples.size(), spike_pct,
		"OK" if pass_spike else "OVER (5%% 초과)"
	])
	print("판정: %s" % verdict)
	print("=====================================")
	print("※ Godot Profiler → Physics 2D 항목 값도 별도 기록 필요")

	_status_label.text = (
		"=== 측정 완료 ===\n"
		+ "평균 간격: %.2f ms\n" % avg_ms
		+ "최대 간격: %.2f ms\n" % max_ms
		+ "33ms 초과: %d 프레임 (%.1f%%)\n" % [spike_count, spike_pct]
		+ "판정: " + verdict + "\n"
		+ "(Godot Profiler→Physics 2D 값도 기록)"
	)
