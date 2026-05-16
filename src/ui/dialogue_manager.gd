extends CanvasLayer

## NPC dialogue overlay, typewriter animation, and ui_accept input handler
## (TR-dial-001, ADR-0003 S.UI 오버레이 계약, story-002).
##
## Registers as an Autoload so Portal and other systems can read is_active via
## get_node_or_null("/root/DialogueManager"). Layer 10 keeps the overlay above
## the HUD and below the SceneTransitionManager fade (layer 128).
##
## Usage:
##   DialogueManager.start_dialogue(&"npc_aria")
##   DialogueManager.show_line("안녕하세요!")
##   await DialogueManager.dialogue_completed

## Emitted when a dialogue session ends.
signal dialogue_completed(npc_id: StringName)

## Typewriter speed - seconds per character (ADR-0003).
const TYPING_SPEED: float = 0.04

## True while a dialogue session is active.
## Read by Portal._can_trigger() to block scene transitions during dialogue.
var is_active: bool = false

var _current_npc_id: StringName = &""
var _full_text: String = ""
var _char_index: int = 0

var _dialogue_text: Label
var _typing_timer: Timer
var _choice_button: Button


func _ready() -> void:
	layer = 10
	hide()
	_setup_children()


func _setup_children() -> void:
	var panel := Panel.new()
	add_child(panel)

	_dialogue_text = Label.new()
	_dialogue_text.name = "DialogueText"
	panel.add_child(_dialogue_text)

	_choice_button = Button.new()
	_choice_button.name = "ChoiceButton"
	panel.add_child(_choice_button)

	_typing_timer = Timer.new()
	_typing_timer.name = "TypingTimer"
	_typing_timer.wait_time = TYPING_SPEED
	_typing_timer.one_shot = false
	_typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(_typing_timer)


## Begins a dialogue session with [param npc_id].
## Call show_line() after this to display text with typewriter animation.
func start_dialogue(npc_id: StringName) -> void:
	_current_npc_id = npc_id
	is_active = true
	InputMapManager.set_ui_active(true)
	show()


## Displays [param text] with typewriter animation.
## No-op if called before start_dialogue() (is_active guard).
func show_line(text: String) -> void:
	if not is_active:
		return
	_display_line(text)


## Ends the current dialogue session.
##
## Resets is_active, deactivates UI input context, hides the overlay, and
## emits dialogue_completed(npc_id). Called by _advance_dialogue() or externally.
func finish_dialogue(npc_id: StringName) -> void:
	is_active = false
	InputMapManager.set_ui_active(false)
	hide()
	dialogue_completed.emit(npc_id)


func _display_line(text: String) -> void:
	_full_text = text
	_char_index = 0
	_dialogue_text.text = ""
	_typing_timer.wait_time = TYPING_SPEED
	_typing_timer.start()


func _on_typing_timer_timeout() -> void:
	_char_index += 1
	_dialogue_text.text = _full_text.left(_char_index)
	if _char_index >= _full_text.length():
		_typing_timer.stop()
		_choice_button.grab_focus()  # safe from Timer.timeout - spike-grab-focus 2026-05-07


## Testable seam for ui_accept logic. Called by _unhandled_input.
## Typing in progress: skip to full text. Typing done: advance or end dialogue.
func _on_ui_accept() -> void:
	if not is_active:
		return
	if _typing_timer.is_stopped():
		_advance_dialogue()
	else:
		_typing_timer.stop()
		_dialogue_text.text = _full_text


func _advance_dialogue() -> void:
	finish_dialogue(_current_npc_id)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_ui_accept()
