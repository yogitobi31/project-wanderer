# Epic: InputMapManager

> **Layer**: Foundation
> **GDD**: design/gdd/입력-매핑-시스템.md
> **Architecture Module**: InputMapManager (Autoload)
> **Status**: Ready
> **Stories**: 4 stories created

## Overview

InputMapManager는 키보드·마우스·게임패드 바인딩을 통합 관리하는 Foundation Autoload다.
`gameplay` / `ui` 두 컨텍스트를 분리하여, `set_ui_active(true)` 호출 시 게임플레이 입력을
자동 차단한다. 바인딩은 `physical_keycode` 기반으로 `user://input_bindings.cfg`에 저장하여
키보드 레이아웃 독립성을 보장한다. PlayerController가 매 프레임 `get_move_vector()`와
`is_action_just_pressed()`를 통해 입력을 소비하며, Steam Deck 호환을 위해 모든 핵심
액션은 gamepad에도 매핑되어야 한다.
Autoload 등록 순서 7번.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Foundation Autoload 등록 순서 | InputMapManager Track 2 Service Singleton, 등록 순서 7번, physical_keycode 저장 계약 | MEDIUM (`physical_keycode` 4.5+, SDL3 gamepad 4.5+) |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|-------|----------|--------------|
| TR-input-001 | InputMapManager Autoload — 액션 바인딩·컨텍스트 전환·리바인딩 전역 관리 | ADR-0002 ✅ |
| TR-input-002 | `is_ui_active` 컨텍스트 분리 — `set_ui_active(true)` 시 gameplay 카테고리 액션 입력 차단 | ADR-0002 ✅ |
| TR-input-003 | ConfigFile 기반 키 바인딩 영속성 — `user://input_bindings.cfg` 저장/로드 | ADR-0002 ✅ |
| TR-input-004 | `physical_keycode` 기반 바인딩 저장 (Godot 4.5 best practice — 키보드 레이아웃 독립) | ADR-0002 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/입력-매핑-시스템.md`의 모든 Acceptance Criteria 검증
- Logic stories 테스트 파일이 `tests/unit/input/`에 존재하고 통과
- `is_ui_active == true`일 때 gameplay 액션 차단 단위 테스트 통과
- `physical_keycode` 저장/로드 왕복 단위 테스트 통과
- `docs/engine-reference/godot/modules/input.md` 검증 후 구현 시작 (MEDIUM risk)
- InputMapManager Autoload가 project.godot에 순서 7번으로 등록됨

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [액션 마스터 테이블 초기화 및 is_ready 가드](story-001-action-table-init.md) | Logic | Ready | ADR-0002 |
| 002 | [리바인딩 API — 유효성 검사·중복 처리·저장](story-002-rebind-api.md) | Logic | Ready | ADR-0002 |
| 003 | [컨텍스트 분리 — is_ui_active 및 gameplay 차단](story-003-context-separation.md) | Logic | Ready | ADR-0002 |
| 004 | [게임패드 입력 공식 — Deadzone·이동벡터·4방향 이산화](story-004-gamepad-formulas.md) | Logic | Ready | ADR-0002 |

## Next Step

`/story-readiness production/epics/input-map-manager/story-001-action-table-init.md`를 실행하여 구현 준비 상태를 확인하세요.
