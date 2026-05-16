# Spike: grab_focus() dual-focus — DialogueManager 게임패드 포커스

**위험도**: HIGH  
**관련 ADR**: ADR-0003 (씬 전환·맵·UI 오버레이 계약)  
**Godot 버전**: 4.6  
**스파이크 목적**: CanvasLayer 위의 UI와 게임 씬 UI 사이에서 gamepad 포커스 충돌 검증

---

## 배경

ADR-0003의 DialogueManager는 `CanvasLayer(layer=10)`에 올라간다.
대화창이 열렸을 때 `DialoguePanel` 안의 버튼이 grab_focus()를 받아야 한다.
동시에 게임 씬(HUD)에도 포커스를 받을 수 있는 Control 노드가 존재할 수 있다.

Steam Deck 대응 요건(`technical-preferences.md`): "UI는 마우스 hover 없이도 동작해야 함"
→ 게임패드로 대화창 선택지를 내비게이션할 수 있어야 함.

Godot 4.5에서 AccessKit 통합으로 포커스 동작이 변경되었을 수 있다.

## 검증 대상

1. `CanvasLayer` 위의 버튼이 `grab_focus()` 호출 시 게임패드 포커스를 받는가?
2. 게임 씬 HUD의 Control이 포커스를 갖고 있을 때, 대화창이 열리며 grab_focus() 하면 포커스가 이전되는가?
3. 대화창 닫힐 때 포커스가 HUD로 정상 복귀하는가?
4. `ui_accept` / `ui_up` / `ui_down` 입력이 CanvasLayer 위 버튼에 전달되는가?

## 테스트 시나리오

```
# 씬 구조:
# Root
#   ├─ HUD (CanvasLayer layer=0)
#   │    └─ HealthBar (Control — HUD 포커스 대상)
#   └─ DialogueLayer (CanvasLayer layer=10)
#        └─ DialoguePanel (Control, visible=false)
#             ├─ Label ("대화 텍스트")
#             └─ ChoiceButton (Button — 대화 선택지)

# 시나리오:
# 1. HUD HealthBar가 포커스를 가짐
# 2. DialoguePanel.show() + ChoiceButton.grab_focus() 호출
# 3. gamepad ui_down → ChoiceButton에 전달되는지 확인
# 4. DialoguePanel.hide() → 포커스 상태 확인
```

## 합격 기준

- [ ] CanvasLayer(layer=10)의 버튼이 grab_focus() 후 게임패드 입력 수신
- [ ] 하위 CanvasLayer의 Control이 포커스를 잃음 (dual-focus 없음)
- [ ] 대화창 닫힌 후 포커스 상태가 예측 가능
- [ ] Steam Deck에서 ui_accept로 선택지 선택 가능 (시뮬레이션)

## 결과

**날짜**: 2026-05-07  
**결과**: BLOCKED — 씬 구성 오류 수정 후 재실행 필요

**발견된 씬 구성 오류 (2026-05-07)**:
- `spike_focus_runner.gd`가 `.tscn`에 연결되지 않음 → 입력 처리 전혀 불가
- 실행 안내서의 키 설명 오류: "Space" → 실제 키는 **F1**(대화창 열기) / **F2**(닫기) / **F3**(로그 출력)

**수정 완료 (2026-05-07)**:
- `spike_focus.tscn`에 `Runner` 노드 추가 + `spike_focus_runner.gd` 연결
- `Runner`의 parent = `SpikeGrabFocus` → `get_parent()`가 컨트롤러를 정상 참조

---

## Spike Result: spike-grab-focus

**Status**: BLOCKED / NOT PASSED

**Reason**:  
정확한 씬(`spike_focus.tscn`)은 실행되었으나 `spike_focus_runner.gd`가 씬에 미연결 상태여서  
어떤 키 입력도 처리되지 않았음. 대화창 열림 동작 검증 불가.

**Observed Issues**:
- F6 실행 후 "HP: 100" 텍스트만 표시, 키 입력에 반응 없음
- `[FocusSpike]` 로그 미출력 (Runner 노드 없어서 `_input()` 미호출)
- Space는 매핑된 키가 아님 — F1/F2/F3이 올바른 조작 키

**Next Action**:
씬을 F6으로 재실행한 후 아래 순서로 검증:
1. `[FocusSpike] 초기 포커스: HUD` 출력 확인
2. **F1** 키 → 대화창 열림 + `ChoiceButton.grab_focus()` 확인
3. **ui_down** (방향키 ↓ 또는 게임패드 스틱) → 포커스 이동 확인
4. **F2** 키 → 대화창 닫힘 + HUD 포커스 복귀 확인
5. **F3** 키 → 포커스 로그 전체 출력 확인

---

## 1차 실행 결과 (2026-05-07) — PARTIAL

**F1 대화창 열기**: ✅ PASS — DialoguePanel 표시, ChoiceButton 보임  
**F2 대화창 닫기 / HUD 포커스 복귀**: ❓ 시각적 확인 불가  
**F3 포커스 로그 출력**: ❓ Output 패널 미확인  
**ui_down ChoiceButton 포커스 이동**: ❓ 포커스 시각 피드백 없어 확인 불가  
**ESC 대화창 닫기**: ❌ 미구현 (F2만 존재)

**추가 수정 완료 (2026-05-07)**:
- `spike_focus_controller.gd`: 포커스 시각 피드백 추가 (HealthBar 초록, ChoiceButton 노랑 modulate)
- `spike_focus_controller.gd`: 화면 내 `DebugLabel`로 `Focus: [노드명]` 실시간 표시
- `spike_focus_runner.gd`: ESC 키 → `close_dialogue()` 연결
- `spike_focus.tscn`: `HUD/DebugLabel` 노드 추가

---

## 2차 실행 결과 (2026-05-07) — PARTIAL

**F1 대화창 열기**: ✅ PASS  
**F2/ESC 닫기 + HUD 복귀**: ✅ PASS  
**ui_down 포커스 이동 확인**: ❓ NOT VERIFIABLE — 시각 피드백 부족  
**F3 로그 출력 확인**: ❓ NOT VERIFIABLE — 화면 표시 없이 Output 패널만 출력됨

**추가 수정 완료 (2026-05-07)**:
- `spike_focus_controller.gd`: `show_focus_dump()` 추가 (F3 화면 표시), `log_action()` 추가 (ui_down 화면 표시), ChoiceButton 텍스트 `▶` 프리픽스 포커스 시 변경
- `spike_focus_runner.gd`: `ui_down` 액션 감지 → `log_action()` 호출
- `spike_focus.tscn`: `LogLabel` 추가 (멀티라인 이벤트 표시), `KeyHints` 레이블 추가, DebugLabel 폰트 22pt

---

## 3차 실행 결과 (2026-05-07) — PARTIAL

**F6 실행**: ✅ PASS  
**F1 대화창 열기**: ✅ PASS  
**F2/ESC 닫기**: ✅ PASS  
**F3 로그 덤프 화면 표시**: ✅ PASS  
**ui_down 포커스 이동 확인**: ❓ NOT VERIFIED  
- LogLabel의 포커스 읽기 타이밍 문제 발견: `_input()` 내에서 즉시 읽으면 Godot의 네비게이션 처리 전 값이 나옴  
- 수정 완료: `call_deferred`로 한 프레임 후 읽도록 변경  
- `choice_button.pressed` 시그널 추가: ui_accept(Enter) 입력 전달 여부를 화면에 표시

**추가 수정 완료 (2026-05-07)**:
- `spike_focus_controller.gd`: `log_action()` → `call_deferred(_read_focus_after_input)` 패턴으로 타이밍 수정
- `spike_focus_controller.gd`: `choice_button.pressed` 시그널 연결 → ui_accept 전달 확인
- `spike_focus_runner.gd`: `ui_accept` 감지 추가

---

## 재실행 체크리스트 (4차 — 최종)

**검증 순서** (DialoguePanel이 닫힌 상태에서 ↓는 의미 없음 — 반드시 F1 먼저):

| # | 동작 | 기대 화면 표시 | 판정 |
|---|---|---|---|
| 1 | F6 실행 직후 | `Focus: HUD HealthBar` + HealthBar 초록 | |
| 2 | **F1** | `Focus: ChoiceButton (DialogueLayer 10)` + `▶ 네, 함께 가요` 노랑 | |
| 3 | **↓ 방향키** | LogLabel: `[ui_down pressed] / current focus: ChoiceButton` | |
| 4 | **Enter** (ui_accept) | LogLabel: `✅ ChoiceButton pressed! (ui_accept가 CanvasLayer 10에 전달됨)` | |
| 5 | **F3** | LogLabel: `Focus dump: ... Current focus: ChoiceButton` | |
| 6 | **F2** or **ESC** | `Focus: HUD HealthBar` 복귀 + HealthBar 초록 | |

항목 3과 4가 모두 확인되면 → **PASS**

---

## 최종 결과 (4차 실행 — 2026-05-07) ✅ PASS

**날짜**: 2026-05-07  
**결과**: ✅ PASS — 전체 합격 기준 충족

| 합격 기준 | 결과 |
|---|---|
| CanvasLayer(layer=10) 버튼이 `grab_focus()` 후 포커스 수신 | ✅ |
| `ui_down` 입력 시 ChoiceButton 포커스 유지 (dual-focus 없음) | ✅ |
| `ui_accept`(Enter) 입력이 CanvasLayer 10 버튼에 전달됨 | ✅ (`pressed` 시그널 발생 확인) |
| 대화창 닫힌 후 HUD 포커스 정상 복귀 | ✅ |
| AccessKit(Godot 4.5+) 통합으로 인한 포커스 동작 변경 | 없음 |

**발견 사항**:
- `grab_focus()` — CanvasLayer layer 값에 무관하게 정상 동작. layer=10 버튼이 layer=0 버튼보다 포커스 우선권을 갖는 것은 별도 처리가 아닌 `grab_focus()` 호출로 결정됨
- `ui_down` — ChoiceButton 아래에 포커스 이동 대상이 없을 경우 포커스 그대로 유지. CanvasLayer 간 포커스 누출(dual-focus) 없음 확인
- `ui_accept` — ChoiceButton이 포커스를 보유한 상태에서 Enter 시 `pressed` 시그널 정상 발생. Steam Deck gamepad 대응 가능
- GDScript `_input()` 내에서 즉시 `get_focus_owner()` 호출 시 타이밍 문제 있음 → `call_deferred` 필수

**ADR-0003 영향**: 없음 — 설계 확정  
DialogueManager가 `CanvasLayer(layer=10)`에서 `grab_focus()` 호출하는 방식 그대로 사용 가능.  
폴백(`ui_accept`) 포커스 처리도 별도 대응 불필요.

**AccessKit 관련 동작 변경**: 없음 (Godot 4.6.2 기준)

## 구현 파일

- `spike_focus.tscn` — HUD + DialogueLayer 테스트 씬
- `spike_focus_controller.gd` — 포커스 전환 로직
- `spike_grab_focus_test.gd` — GUT 테스트
