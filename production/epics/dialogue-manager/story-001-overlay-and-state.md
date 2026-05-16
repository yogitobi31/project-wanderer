# Story 001: DialogueManager — CanvasLayer 오버레이 + is_active 상태

> **Epic**: DialogueManager
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/대화-시스템.md`
**Requirements**: `TR-dial-001`

**ADR Governing Implementation**: ADR-0003: 씬전환·맵구조·UI오버레이 계약
**ADR Decision Summary**: DialogueManager CanvasLayer `layer=10`. `is_active` 플래그로 씬 전환·포탈 진입 차단. 대화 시작 시 `InputMapManager.set_ui_active(true)`, 종료 시 `false`.

**Engine**: Godot 4.6 | **Risk**: HIGH (grab_focus() dual-focus — 스파이크 PASS로 검증 완료)

**Control Manifest Rules (Presentation layer)**:
- Required: CanvasLayer `layer = 10`
- Required: 대화 시작 시 `InputMapManager.set_ui_active(true)`
- Forbidden: CanvasLayer 번호를 10 이외로 설정

---

## Acceptance Criteria

- [ ] **AC-1**: `DialogueManager.start_dialogue(npc_id)` 호출 시 `is_active == true`
- [ ] **AC-2**: 대화 진행 중 `InputMapManager.is_ui_active == true`
- [ ] **AC-3**: 대화 완료 후 `is_active == false`, `InputMapManager.is_ui_active == false`
- [ ] **AC-4**: CanvasLayer `layer == 10` 확인 (수동)
- [ ] **AC-5**: `is_active == true` 상태에서 씬 전환 요청 시 SceneTransitionManager가 차단 (포탈 진입 핸들러가 `is_active` 체크)

---

## Implementation Notes

1. `src/ui/dialogue_manager.gd` (CanvasLayer 상속):
   ```gdscript
   class_name DialogueManager
   extends CanvasLayer

   signal dialogue_completed(npc_id: StringName)

   var is_active: bool = false

   func _ready() -> void:
       layer = 10
       hide()

   func start_dialogue(npc_id: StringName) -> void:
       is_active = true
       InputMapManager.set_ui_active(true)
       show()
       # story-002에서 타이핑 애니메이션 구현

   func _finish_dialogue(npc_id: StringName) -> void:
       is_active = false
       InputMapManager.set_ui_active(false)
       hide()
       dialogue_completed.emit(npc_id)
   ```
2. `DialogueManager.tscn`: CanvasLayer (layer=10) + Panel + Label (DialogueText) + ChoiceButton
3. Autoload 또는 씬 루트 자식으로 배치 (GDD 기준 — 씬 간 지속성 필요시 Autoload)

---

## Out of Scope

- 타이핑 애니메이션, ui_accept 진행 — story-002
- NPC RelationshipState 기반 대화 분기 — Feature 에픽

---

## QA Test Cases

- **AC-1**: `start_dialogue(&"npc_01")` → `is_active == true`
- **AC-2**: 대화 중 `InputMapManager.is_ui_active == true`
- **AC-3**: `_finish_dialogue` 호출 후 양쪽 false 확인

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/dialogue/dialogue_manager_state_test.gd` — AC-1~3 커버

---

## Size Estimate

**Estimate**: 3 hours

---

## Dependencies

- Depends on: input-map-manager (Foundation, 완료)
- Unlocks: dialogue-manager/story-002, map-scene/story-002 (포탈 is_active 체크)

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 5/5 passing
**Deviations**:
- ADVISORY: `finish_dialogue` (public) vs `_finish_dialogue` (story spec) — 외부 호출자 요구로 rename, doc comment에 명시
- ADVISORY: `grab_focus()` story-002로 연기 — ADR-0003 명시적 fallback 허용
- OUT OF SCOPE: `project.godot` Autoload 등록 — Portal `get_node_or_null` 패턴에 필수, 범위 확장 인정
**Test Evidence**: Logic — tests/unit/dialogue/dialogue_manager_state_test.gd (9 tests, AC-1~4 covered)
**Code Review**: Complete (APPROVED WITH SUGGESTIONS → suggestions deferred to story-002)
