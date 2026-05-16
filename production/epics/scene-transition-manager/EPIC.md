# Epic: SceneTransitionManager

> **Layer**: Foundation
> **GDD**: design/gdd/씬전환-시스템.md
> **Architecture Module**: SceneTransitionManager (Autoload)
> **Status**: Ready
> **Stories**: 2 stories created

## Overview

SceneTransitionManager는 씬 로딩 FSM과 페이드 오버레이를 하나의 Autoload로 통합한다.
Foundation FSM(IDLE → FADING_OUT → LOADING → FADING_IN → IDLE)이 로딩 흐름을 제어하고,
Presentation 역할인 ColorRect CanvasLayer 페이드 연출도 같은 Autoload가 소유한다.
씬 전환 중 `PROCESS_MODE_DISABLED`로 AudioManager를 제외한 모든 게임플레이 노드를 일시
정지하며, `ResourceLoader.load_threaded_request()`로 비동기 로딩하여 화면 멈춤 없는
씬 이동을 보장한다. `spawn_id` 불일치 시 `SpawnPoint_Default` 폴백으로 크래시를 방지한다.
Autoload 등록 순서 8번.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: 씬 전환·맵 구조·UI 오버레이 계약 | 4-state FSM, 비동기 로딩, SpawnPoint 명명 규칙, PROCESS_MODE_DISABLED 계약 | LOW (stable API) |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|-------|----------|--------------|
| TR-scene-001 | 씬 전환 중 `PROCESS_MODE_DISABLED` — AudioManager 제외 모든 게임플레이 노드 일시 정지 | ADR-0003 ✅ |
| TR-scene-002 | `ResourceLoader.load_threaded_request()` 비동기 씬 로딩 — `_process` 폴링으로 진행률 확인 | ADR-0003 ✅ |
| TR-scene-003 | 4-state FSM: IDLE → FADING_OUT → LOADING → FADING_IN → IDLE 전환 순서 고정 | ADR-0003 ✅ |
| TR-scene-004 | SpawnPoint 그룹 명명 규칙 — `SpawnPoint_{id}` 노드, spawn_id 없으면 `SpawnPoint_Default` 폴백 | ADR-0003 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/씬전환-시스템.md`의 모든 Acceptance Criteria 검증
- Logic/Integration stories 테스트 파일이 `tests/unit/scene/`에 존재하고 통과
- FSM 상태 전환 순서 단위 테스트 통과
- `transition_to()` 중복 호출 무시(IDLE 상태에서만 수락) 테스트 통과
- `spawn_id` 없을 때 `SpawnPoint_Default` 폴백 테스트 통과
- SceneTransitionManager Autoload가 project.godot에 순서 8번으로 등록됨

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [FSM 상태 전환·process_mode 계약·중복 요청 방어](story-001-fsm-process-mode.md) | Logic | Ready | ADR-0003 |
| 002 | [SpawnPoint 조회·폴백·전환 완료 흐름](story-002-spawnpoint-transition-flow.md) | Integration | Ready | ADR-0003 |

## Next Step

`/story-readiness production/epics/scene-transition-manager/story-001-fsm-process-mode.md`를 실행하여 구현 준비 상태를 확인하세요.
