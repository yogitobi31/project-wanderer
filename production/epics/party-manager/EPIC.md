# Epic: PartyManager

> **Layer**: Foundation
> **GDD**: design/gdd/파티-매니저.md
> **Architecture Module**: PartyManager (Autoload)
> **Status**: Ready
> **Stories**: 1 story created

## Overview

PartyManager는 플레이어 파티의 멤버십을 관리하는 Foundation Autoload다.
`_companions Array[StringName]`에 합류한 동료 ID를 저장하고,
`MAX_PARTY_SIZE = 3` 제한을 강제하며, `companion_count` computed property를
Feature 레이어(CombatEncounter 적 스케일링 등)에 제공한다.
NPCRegistry가 COMPANION 상태임을 검증한 후에만 `register_companion()`이 성공한다.
NPCRegistry 다음 등록되어야 하므로 Autoload 등록 순서 4번.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| ADR-0002: Foundation Autoload 등록 순서 | PartyManager Track 1 Data Registry, 등록 순서 4번, MAX_PARTY_SIZE 계약 | LOW |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|---|---|---|
| TR-party-001 | PartyManager Autoload — `register_companion()`, `is_recruited()`, `get_companions()`, `companion_count` | ADR-0002 ✅ |
| TR-party-002 | `register_companion()` — `companion_count >= MAX_PARTY_SIZE(3)`이면 실패, COMPANION 상태 검증 | ADR-0002 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/파티-매니저.md`의 모든 Acceptance Criteria 검증
- Logic stories 테스트 파일이 `tests/unit/party/`에 존재하고 통과
- 파티 최대 인원(3명) 초과 시 `register_companion()` 실패 단위 테스트 통과
- PartyManager Autoload가 project.godot에 순서 4번으로 등록됨

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [PartyManager Autoload — 등록·조회 API 및 파티 제한](story-001-register-query-api.md) | Logic | Ready | ADR-0002 |

## Next Step

`/story-readiness production/epics/party-manager/story-001-register-query-api.md`를 실행하여 구현 준비 상태를 확인하세요.
