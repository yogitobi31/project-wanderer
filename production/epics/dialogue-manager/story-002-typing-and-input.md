# Story 002: DialogueManager — 타이핑 애니메이션 + ui_accept 진행

> **Epic**: DialogueManager
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic + Visual/Feel
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/대화-시스템.md`

**ADR Governing Implementation**: ADR-0003: 씬전환·맵구조·UI오버레이 계약
**ADR Decision Summary**: 타이핑 속도 0.04초/글자. `ui_accept` 입력으로 진행 (grab_focus() 스파이크 PASS 검증 완료 — ChoiceButton grab_focus 정상). 타이핑 중 `ui_accept` 시 전체 텍스트 즉시 표시.

**Engine**: Godot 4.6 | **Risk**: LOW (grab_focus dual-focus 스파이크 PASS 2026-05-07)

---

## Acceptance Criteria

- [ ] **AC-1**: 대화 텍스트가 0.04초/글자 속도로 타이핑 표시
- [ ] **AC-2**: 타이핑 중 `ui_accept` 입력 시 전체 텍스트 즉시 표시 (skip)
- [ ] **AC-3**: 전체 텍스트 표시 완료 후 `ui_accept` 입력 시 다음 대사로 진행 (또는 대화 종료)
- [ ] **AC-4**: `grab_focus()` 호출로 ChoiceButton이 포커스 획득 — `ui_accept`가 버튼에 전달됨

---

## Implementation Notes

1. 타이핑 효과 (`Timer` 기반):
   ```gdscript
   const TYPING_SPEED: float = 0.04

   var _full_text: String = ""
   var _char_index: int = 0

   func _display_line(text: String) -> void:
       _full_text = text
       _char_index = 0
       $TypingTimer.wait_time = TYPING_SPEED
       $TypingTimer.start()

   func _on_typing_timer_timeout() -> void:
       _char_index += 1
       $DialogueText.text = _full_text.left(_char_index)
       if _char_index >= _full_text.length():
           $TypingTimer.stop()
   ```
2. `ui_accept` 처리:
   ```gdscript
   func _unhandled_input(event: InputEvent) -> void:
       if not is_active:
           return
       if event.is_action_pressed("ui_accept"):
           if $TypingTimer.is_stopped():
               _advance_dialogue()
           else:
               $TypingTimer.stop()
               $DialogueText.text = _full_text
   ```
3. ChoiceButton 표시 시 `$ChoiceButton.grab_focus()` 호출 (스파이크 PASS — CanvasLayer 10 정상)

---

## QA Test Cases

- **AC-1**: Timer 기반 글자 카운트 진행 확인
- **AC-2**: 타이핑 중 `ui_accept` → `text == _full_text`, `TypingTimer.is_stopped()`
- **AC-3**: 완료 후 `ui_accept` → `_advance_dialogue()` 호출

---

## Test Evidence

**Story Type**: Logic + Visual/Feel
**Required evidence**:
- `tests/unit/dialogue/dialogue_typing_test.gd` — AC-1~3 커버
- 타이핑 애니메이션 스크린샷 → `production/qa/evidence/dialogue-typing.png`

---

## Size Estimate

**Estimate**: 3 hours

---

## Dependencies

- Depends on: dialogue-manager/story-001
- Unlocks: Vertical Slice 대화 루프 완성, NPC 영입 이벤트

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 3/4 passing (AC-4 grab_focus UX DEFERRED — manual playtest required)
**Deviations**:
- ADVISORY: TYPING_SPEED = 0.04 hardcoded — post-MVP에서 @export로 이전 권장
- ADVISORY: show_line() public API story notes에 명시 없음 — _display_line 호출용 public seam으로 추가
**Test Evidence**: Logic — tests/unit/dialogue/dialogue_typing_test.gd (13 tests); Visual/Feel — production/qa/evidence/dialogue-typing.png (ADVISORY, 미생성)
**Code Review**: Complete (CHANGES REQUIRED → 수정 완료)
