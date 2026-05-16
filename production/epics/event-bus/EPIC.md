# Epic: EventBus

> **Layer**: Foundation
> **GDD**: design/gdd/이벤트-버스.md
> **Architecture Module**: EventBus (Autoload)
> **Status**: Ready
> **Stories**: 1 story created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [EventBus Autoload 구현 및 신호 계약](story-001-autoload-signal-contract.md) | Logic | Ready | ADR-0002 |

## Overview

EventBus는 레이어 경계를 넘는 크로스-시스템 이벤트 중계를 담당하는 Foundation Autoload다.
특히 Feature → Foundation 방향의 통신(동료 영입 요청 등)을 직접 참조 없이 디커플링한다.
MVP에서는 `companion_join_requested(companion_id: StringName)` 신호 하나를 정의하며,
RecruitmentQuest가 발행하고 CompanionJoinEvent가 수신한다.
Autoload 등록 순서 1번 — 다른 모든 Autoload가 의존하므로 가장 먼저 초기화된다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| ADR-0002: Foundation Autoload 등록 순서 | EventBus를 Track 2 Service Singleton으로 등재, 등록 순서 1번 | LOW |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|---|---|---|
| TR-ebus-001 | EventBus Autoload — `companion_join_requested(companion_id: StringName)` 크로스-시스템 신호 정의 | ADR-0002 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/이벤트-버스.md`의 모든 Acceptance Criteria 검증
- Logic/Integration stories의 테스트 파일이 `tests/`에 존재하고 통과
- EventBus Autoload가 project.godot에 순서 1번으로 등록됨

## Next Step

`/create-stories event-bus`를 실행하여 구현 가능한 Story로 분해하세요.
