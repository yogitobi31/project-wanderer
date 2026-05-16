# Epic: DialogueManager

> **Layer**: Core
> **GDD**: design/gdd/대화-시스템.md
> **Architecture Module**: DialogueManager (Presentation)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories dialogue-manager`

## Overview

DialogueManager는 플레이어와 NPC 간의 텍스트 대화를 표시하고 진행하는 Core 레이어 시스템이다. NPC 현재 상태(`RelationshipState`)에 따라 대화 리소스를 선택하고, 타이핑 애니메이션(0.04초/글자)으로 텍스트를 표시한다. CanvasLayer(layer=10)로 씬 위에 오버레이되며, 대화 중 `InputMapManager.set_ui_active(true)`로 게임플레이 입력을 차단한다. 대화 완료 시 `on_complete` 이벤트를 QuestManager에 전달해 퀘스트 진행을 트리거한다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Foundation Autoload 등록 순서 | InputMapManager(7번) set_ui_active() 계약 | LOW |
| ADR-0003: 씬전환·맵구조·UI오버레이 계약 | CanvasLayer layer=10, grab_focus() dual-focus fallback, is_active 차단 순서 | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-dial-001 | DialogueManager CanvasLayer 오버레이 + grab_focus() 포커스 이동 + is_active로 씬 전환 차단 | ADR-0003 ✅ |

## Engine Risk Note

**HIGH**: `grab_focus()` Godot 4.6 dual-focus — keyboard focus와 gamepad focus가 분리 동작. 검증 완료 전 fallback: `ui_accept` 액션으로 대화 진행 (포커스 의존 없이 구현). 실기기/에디터 검증 후 ADR-0003 업데이트 필요.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/대화-시스템.md` are verified
- `on_complete` 이벤트가 QuestManager에 정확히 전달 — 단위 테스트 통과
- 대화 중 이동/공격 입력 무시 — 수동 플레이테스트 확인
- 타이핑 중 confirm 입력 시 즉시 전체 텍스트 표시 — 수동 플레이테스트 확인
- grab_focus() Steam Deck(gamepad) 동작 확인 — 실기기 또는 에디터 검증 증거

## Next Step

Run `/create-stories dialogue-manager` to break this epic into implementable stories.
