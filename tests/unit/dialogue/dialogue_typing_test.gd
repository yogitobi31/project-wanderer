extends GutTest

## Unit tests for DialogueManager typewriter animation and ui_accept input
## (story-002, TR-dial-001).
##
## AC-1 — show_line() starts typing animation at TYPING_SPEED (0.04s/char)
## AC-2 — ui_accept during typing shows full text immediately and stops timer
## AC-3 — ui_accept after typing complete ends dialogue, emits dialogue_completed
## AC-4 — ChoiceButton node exists for grab_focus() (UX verification deferred to playtest)

var _dm: DialogueManager


func before_each() -> void:
	_dm = load("res://src/ui/dialogue_manager.gd").new()
	add_child_autoqfree(_dm)
	InputMapManager.set_ui_active(false)
	_dm.start_dialogue(&"npc_test")


func after_each() -> void:
	InputMapManager.set_ui_active(false)


# ---------------------------------------------------------------------------
# AC-1: Typewriter animation via Timer
# ---------------------------------------------------------------------------

func test_dialogue_typing_speed_constant_is_0_04() -> void:
	assert_eq(DialogueManager.TYPING_SPEED, 0.04,
			"AC-1: TYPING_SPEED must be 0.04 seconds per character (ADR-0003)")


func test_dialogue_typing_show_line_starts_timer() -> void:
	_dm.show_line("hello")
	assert_false(_dm._typing_timer.is_stopped(),
			"AC-1: show_line() must start the typing timer")


func test_dialogue_typing_timer_timeout_reveals_one_char_per_tick() -> void:
	_dm.show_line("abc")
	_dm._on_typing_timer_timeout()
	_dm._on_typing_timer_timeout()
	assert_eq(_dm._dialogue_text.text, "ab",
			"AC-1: each timer timeout must reveal exactly one more character")


func test_dialogue_typing_timer_stops_when_all_chars_revealed() -> void:
	_dm.show_line("hi")
	_dm._on_typing_timer_timeout()  # "h"
	_dm._on_typing_timer_timeout()  # "hi" — completes
	assert_true(_dm._typing_timer.is_stopped(),
			"AC-1: timer must stop automatically when all characters are displayed")
	assert_eq(_dm._dialogue_text.text, "hi",
			"AC-1: full text must be visible after typing completes")


func test_dialogue_typing_show_line_without_start_is_noop() -> void:
	var dm2: DialogueManager = load("res://src/ui/dialogue_manager.gd").new()
	add_child_autoqfree(dm2)
	# is_active is false — show_line must be a no-op
	dm2.show_line("ignored")
	assert_true(dm2._typing_timer.is_stopped(),
			"show_line() must not start the timer when dialogue is inactive")


# ---------------------------------------------------------------------------
# AC-2: ui_accept during typing skips to full text
# ---------------------------------------------------------------------------

func test_dialogue_typing_ui_accept_during_typing_shows_full_text() -> void:
	_dm.show_line("hello world")
	_dm._on_typing_timer_timeout()  # "h"
	_dm._on_typing_timer_timeout()  # "he"
	assert_false(_dm._typing_timer.is_stopped(),
			"precondition: timer must still be running mid-text")
	_dm._on_ui_accept()
	assert_eq(_dm._dialogue_text.text, "hello world",
			"AC-2: ui_accept during typing must show the full text immediately")


func test_dialogue_typing_ui_accept_during_typing_stops_timer() -> void:
	_dm.show_line("hello world")
	_dm._on_typing_timer_timeout()
	_dm._on_ui_accept()
	assert_true(_dm._typing_timer.is_stopped(),
			"AC-2: ui_accept during typing must stop the timer")


# ---------------------------------------------------------------------------
# AC-3: ui_accept after typing complete advances/ends dialogue
# ---------------------------------------------------------------------------

func test_dialogue_typing_ui_accept_after_completion_ends_dialogue() -> void:
	_dm.show_line("hi")
	_dm._on_typing_timer_timeout()  # "h"
	_dm._on_typing_timer_timeout()  # "hi" — complete
	assert_true(_dm._typing_timer.is_stopped(),
			"precondition: typing must be complete before advance")
	_dm._on_ui_accept()
	assert_false(_dm.is_active,
			"AC-3: ui_accept after typing completes must end the dialogue session")


func test_dialogue_typing_advance_dialogue_emits_completed_with_npc_id() -> void:
	_dm.finish_dialogue(&"npc_test")  # reset from before_each start
	_dm.start_dialogue(&"npc_aria")
	watch_signals(_dm)
	_dm.show_line("hello")
	for _i: int in 5:  # reveal all 5 chars of "hello"
		_dm._on_typing_timer_timeout()
	# Typing complete; now ui_accept advances dialogue (AC-3)
	_dm._on_ui_accept()
	assert_signal_emitted_with_parameters(_dm, "dialogue_completed", [&"npc_aria"])


# ---------------------------------------------------------------------------
# AC-4: ChoiceButton exists for grab_focus (structural check)
# Full UX verification — DEFERRED to manual playtest
# ---------------------------------------------------------------------------

func test_dialogue_typing_choice_button_node_exists() -> void:
	assert_not_null(_dm._choice_button,
			"AC-4: ChoiceButton node must exist so grab_focus() can be called on completion")


# ---------------------------------------------------------------------------
# Edge cases (TC-DT-011, TC-DT-012, TC-DT-013)
# ---------------------------------------------------------------------------

func test_dialogue_typing_show_line_empty_string_completes_on_first_tick() -> void:
	# TC-DT-011: empty string completes in one tick without error
	_dm.show_line("")
	_dm._on_typing_timer_timeout()
	assert_true(_dm._typing_timer.is_stopped(),
			"edge: empty string must complete typing on the first timer tick")
	assert_eq(_dm._dialogue_text.text, "",
			"edge: empty string must leave dialogue text empty")


func test_dialogue_typing_show_line_called_twice_replaces_text() -> void:
	# TC-DT-012: second show_line mid-session replaces the first line cleanly
	_dm.show_line("first")
	_dm._on_typing_timer_timeout()  # partial reveal of "first"
	_dm.show_line("second")
	for _i: int in 6:  # len("second") == 6
		_dm._on_typing_timer_timeout()
	assert_eq(_dm._dialogue_text.text, "second",
			"edge: second show_line call must fully replace the first line")
	assert_true(_dm._typing_timer.is_stopped(),
			"edge: timer must stop when the replacement line finishes typing")


func test_dialogue_typing_ui_accept_when_inactive_is_noop() -> void:
	# TC-DT-013: _on_ui_accept() must be a no-op when is_active == false
	var dm2: DialogueManager = load("res://src/ui/dialogue_manager.gd").new()
	add_child_autoqfree(dm2)
	# is_active is false — no start_dialogue call
	watch_signals(dm2)
	dm2._on_ui_accept()
	assert_false(dm2.is_active,
			"TC-DT-013: _on_ui_accept on inactive manager must not change is_active")
	assert_signal_not_emitted(dm2, "dialogue_completed",
			"TC-DT-013: _on_ui_accept on inactive manager must not emit dialogue_completed")
