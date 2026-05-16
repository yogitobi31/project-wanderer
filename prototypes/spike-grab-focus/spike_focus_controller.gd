## Spike: grab_focus() dual-focus 검증
## CanvasLayer(layer=10)의 버튼이 게임패드 포커스를 올바르게 받는지 확인한다.
extends Node

@onready var hud_control: Control = $HUD/HealthBar
@onready var dialogue_panel: Control = $DialogueLayer/DialoguePanel
@onready var choice_button: Button = $DialogueLayer/DialoguePanel/ChoiceButton
@onready var debug_label: Label = $HUD/DebugLabel
@onready var log_label: Label = $HUD/LogLabel

const CHOICE_TEXT_DEFAULT := "네, 함께 가요"
const CHOICE_TEXT_FOCUSED := "▶ 네, 함께 가요"

var _focus_log: Array[String] = []

func _ready() -> void:
	debug_label.add_theme_font_size_override("font_size", 22)
	log_label.add_theme_font_size_override("font_size", 16)

	dialogue_panel.hide()

	hud_control.focus_entered.connect(func() -> void:
		_log("HUD 포커스 획득")
		hud_control.modulate = Color(0.5, 1.5, 0.5)
		_update_debug("HUD HealthBar")
	)
	hud_control.focus_exited.connect(func() -> void:
		_log("HUD 포커스 해제")
		hud_control.modulate = Color.WHITE
	)
	choice_button.focus_entered.connect(func() -> void:
		_log("ChoiceButton 포커스 획득")
		choice_button.text = CHOICE_TEXT_FOCUSED
		choice_button.modulate = Color(1.0, 1.5, 0.3)
		_update_debug("ChoiceButton (DialogueLayer 10)")
	)
	choice_button.focus_exited.connect(func() -> void:
		_log("ChoiceButton 포커스 해제")
		choice_button.text = CHOICE_TEXT_DEFAULT
		choice_button.modulate = Color.WHITE
	)
	# pressed 시그널 = ui_accept(Enter/스페이스/게임패드 A)가 실제로 전달된 증거
	choice_button.pressed.connect(func() -> void:
		_log("✅ ChoiceButton PRESSED — ui_accept가 CanvasLayer 10에 전달됨")
		log_label.text = "✅ ChoiceButton pressed!\n(ui_accept 입력이 CanvasLayer 10에 전달됨)"
	)

	hud_control.grab_focus()
	_log("초기 포커스: HUD")

func open_dialogue() -> void:
	dialogue_panel.show()
	choice_button.grab_focus()
	_log("대화창 열림 — ChoiceButton.grab_focus() 호출")

func close_dialogue() -> void:
	dialogue_panel.hide()
	_log("대화창 닫힘")
	hud_control.grab_focus()
	_log("HUD 포커스 복귀 시도")

func log_action(action: String) -> void:
	# _input() 타이밍 문제: Godot이 ui_down 네비게이션을 처리하기 전에 focus를 읽으면
	# 이전 노드가 나옴. call_deferred로 한 프레임 후에 읽는다.
	_log(action)
	log_label.text = action
	_read_focus_after_input.call_deferred(action)

func _read_focus_after_input(action: String) -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	var focus_name: String = focus_owner.name if focus_owner else "none"
	var msg: String = "[" + action + "]\ncurrent focus: " + focus_name
	_log("→ 이동 후 포커스: " + focus_name)
	log_label.text = msg

func show_focus_dump() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	var current_name: String = focus_owner.name if focus_owner else "none"
	var dump: String = (
		"Focus dump:\n"
		+ "- HUD HealthBar: focusable\n"
		+ "- ChoiceButton: focusable\n"
		+ "- Current focus: " + current_name
	)
	log_label.text = dump
	_log("F3 dump — current focus: " + current_name)

func get_focus_log() -> Array[String]:
	return _focus_log.duplicate()

func _update_debug(who: String) -> void:
	debug_label.text = "Focus: " + who

func _log(msg: String) -> void:
	_focus_log.append(msg)
	print("[FocusSpike] ", msg)
