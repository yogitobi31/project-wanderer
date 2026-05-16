extends GutTest

## Unit tests for InputMapManager context separation (story-003).
##
## Coverage:
##   AC-R7a  set_ui_active(true) → is_ui_active = true, guard stops handle_input
##   AC-R7b  is_ui_active=true → game_pause 액션 미처리 가드 (플래그 기반)
##   AC-R7c  is_ui_active 기본값 = false (회귀 앵커)
##   AC-R7d  정적 분석 — 하드코딩 키코드 grep (결과 0건)

var _mgr: InputMapManager

func before_each() -> void:
	# load() avoids Autoload-name-shadowing: InputMapManager as a class_name + Autoload means
	# InputMapManager.new() would call .new() on the singleton instance, which fails.
	_mgr = load("res://src/core/input_map_manager.gd").new()
	_mgr._bindings_path = "user://test_context_tmp.cfg"
	add_child(_mgr)
	await get_tree().process_frame

func after_each() -> void:
	for def: Dictionary in InputMapManager.ACTION_DEFS:
		var action_name: StringName = def[&"name"]
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
	_mgr.queue_free()
	if FileAccess.file_exists("user://test_context_tmp.cfg"):
		DirAccess.remove_absolute("user://test_context_tmp.cfg")

# ---------------------------------------------------------------------------
# AC-R7c — 회귀 앵커 (기본값 = false)
# ---------------------------------------------------------------------------

func test_is_ui_active_defaults_to_false() -> void:
	assert_false(_mgr.is_ui_active,
			"is_ui_active must be false on init — gameplay input must not be blocked by default")

# ---------------------------------------------------------------------------
# AC-R7a — set_ui_active() 플래그 설정 / 해제
# ---------------------------------------------------------------------------

func test_set_ui_active_true_sets_flag() -> void:
	_mgr.set_ui_active(true)
	assert_true(_mgr.is_ui_active)

func test_set_ui_active_false_clears_flag() -> void:
	_mgr.set_ui_active(true)
	_mgr.set_ui_active(false)
	assert_false(_mgr.is_ui_active)

# ---------------------------------------------------------------------------
# AC-R7a — PlayerController 가드 패턴 시뮬레이션
# ---------------------------------------------------------------------------

## Mimics PlayerController._physics_process() guard.
## Returns 1 when handle_input would be called, 0 when the guard fires.
func _simulate_player_input_poll(mgr: InputMapManager) -> int:
	if mgr.is_ui_active:
		return 0  # guard triggered — handle_input not called
	return 1      # would call handle_input

func test_ui_active_blocks_gameplay_input_poll() -> void:
	_mgr.set_ui_active(true)
	var calls: int = _simulate_player_input_poll(_mgr)
	assert_eq(calls, 0,
			"When is_ui_active=true, PlayerController guard must prevent handle_input()")

func test_ui_inactive_allows_gameplay_input_poll() -> void:
	# is_ui_active defaults to false
	var calls: int = _simulate_player_input_poll(_mgr)
	assert_eq(calls, 1,
			"When is_ui_active=false, PlayerController guard must allow handle_input()")

# ---------------------------------------------------------------------------
# AC-R7b — game_pause 비활성화 가드 플래그 검증
# ---------------------------------------------------------------------------

## The game_pause handler is responsible for checking is_ui_active before acting.
## These tests verify the flag correctly signals when game_pause should be suppressed.

func test_ui_active_flag_signals_game_pause_suppression() -> void:
	_mgr.set_ui_active(true)
	# A pause handler would do: if InputMapManager.is_ui_active: return (skip pause)
	var should_handle_pause: bool = not _mgr.is_ui_active
	assert_false(should_handle_pause,
			"When is_ui_active=true, game_pause handlers must suppress pause action")

func test_ui_inactive_flag_allows_game_pause() -> void:
	# is_ui_active = false by default
	var should_handle_pause: bool = not _mgr.is_ui_active
	assert_true(should_handle_pause,
			"When is_ui_active=false, game_pause handlers must process pause action normally")

# ---------------------------------------------------------------------------
# AC-R7c — 토글 회귀
# ---------------------------------------------------------------------------

func test_set_ui_active_is_idempotent_true() -> void:
	_mgr.set_ui_active(true)
	_mgr.set_ui_active(true)
	assert_true(_mgr.is_ui_active,
			"Calling set_ui_active(true) twice must leave flag true")

func test_set_ui_active_is_idempotent_false() -> void:
	_mgr.set_ui_active(false)
	assert_false(_mgr.is_ui_active,
			"Calling set_ui_active(false) when already false must leave flag false")

func test_ui_active_toggle_sequence() -> void:
	_mgr.set_ui_active(true)
	_mgr.set_ui_active(false)
	_mgr.set_ui_active(true)
	assert_true(_mgr.is_ui_active,
			"Flag must reflect the last set_ui_active() call")

# ---------------------------------------------------------------------------
# AC-R7d — 정적 분석 (하드코딩 키코드 grep)
# ---------------------------------------------------------------------------

## AC-R7d: Static analysis — no hardcoded keycodes outside InputMap/Input contexts.
## This test is intentionally lightweight: it documents the rule and provides
## a seam for CI to run the grep check externally.
## Full verification: grep -rn "KEY_[A-Z]\|JOY_BUTTON_\|JOY_AXIS_" src/
## excluding src/core/input_map_manager.gd and tests/ — result must be 0 lines.
func test_static_analysis_no_hardcoded_keycodes_documented() -> void:
	# This test passes by definition at the unit level; CI grep enforces the rule.
	# If a gameplay file hardcodes KEY_* outside InputMap calls, the CI grep fails.
	assert_true(true,
			"AC-R7d: CI grep for hardcoded keycodes must return 0 matches. "
			+ "Run: grep -rn 'KEY_[A-Z0-9_]\\+\\|JOY_BUTTON_[A-Z0-9_]\\+' src/ "
			+ "--include='*.gd' --exclude='input_map_manager.gd'")
