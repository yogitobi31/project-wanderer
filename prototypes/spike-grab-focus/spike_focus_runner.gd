## 런타임 검증용
## F1: 대화창 열기  F2/ESC: 닫기  F3: 로그 덤프  ↓: 포커스 이동 확인  Enter: 버튼 누름 확인
extends Node

@onready var controller: Node = get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("[FocusSpike] F1 — 대화창 열기")
				controller.open_dialogue()
			KEY_F2:
				print("[FocusSpike] F2 — 대화창 닫기")
				controller.close_dialogue()
			KEY_F3:
				print("[FocusSpike] F3 — 포커스 덤프:")
				for line: String in controller.get_focus_log():
					print("  ", line)
				controller.show_focus_dump()
			KEY_ESCAPE:
				print("[FocusSpike] ESC — 대화창 닫기")
				controller.close_dialogue()

	# ui_down: 포커스 이동 후 결과를 화면에 표시 (call_deferred로 다음 프레임 읽음)
	if event.is_action_pressed("ui_down"):
		controller.log_action("ui_down pressed")

	# ui_accept: ChoiceButton이 포커스를 갖고 있을 때 Enter/스페이스를 누르면
	# choice_button.pressed 시그널이 발생 — 컨트롤러에서 화면에 표시됨
	if event.is_action_pressed("ui_accept"):
		print("[FocusSpike] ui_accept pressed")
