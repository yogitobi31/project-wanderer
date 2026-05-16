# Epic: NPCRegistry

> **Layer**: Foundation
> **GDD**: design/gdd/NPC-상태-관리.md
> **Architecture Module**: NPCRegistry (Autoload)
> **Status**: Ready
> **Stories**: 3 stories created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [NPCRecord 데이터 구조 및 NPCRegistry 읽기 인터페이스](story-001-npcrecord-and-read-interface.md) | Logic | Ready | ADR-0001, ADR-0002 |
| 002 | [set_state() FSM + npc_state_changed 신호](story-002-set-state-fsm.md) | Logic | Ready | ADR-0001, ADR-0002 |
| 003 | [쓰기 API, snapshot() 독립성 및 데이터 무결성](story-003-write-api-snapshot-integrity.md) | Logic | Ready | ADR-0001, ADR-0002 |

## Overview

NPCRegistry는 게임 내 모든 NPC의 RelationshipState, quest_flags, party_slot을 저장하고
조회하는 Foundation Autoload다. 5개 이상의 다운스트림 시스템(대화, 퀘스트, AI, 합류이벤트,
월드조건)이 동시 접근하는 전역 NPC 상태 저장소로, ADR-0001의 4가지 Autoload 허용 기준을
충족하는 유일한 NPC 시스템이다.
`get_npc()`는 항상 `duplicate_deep()`으로 스냅샷을 반환하여 원본 보호를 보장하며,
`registry_initialized` 신호로 의존 시스템에 초기화 완료를 알린다.
Autoload 등록 순서 3번 (EventBus, ItemDB 이후).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| ADR-0001: Data Registry Autoload | NPCRegistry를 4가지 기준 충족 Autoload로 등재, `duplicate_deep()` 사용 계약 | HIGH (`duplicate_deep` 4.5+) |
| ADR-0002: Foundation Autoload 등록 순서 | NPCRegistry Track 1 Data Registry, 등록 순서 3번, is_initialized guard 계약 | LOW |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|---|---|---|
| TR-npc-001 | NPCRegistry Autoload — NPC 상태 전역 단일 접근 경로 | ADR-0001 ✅ |
| TR-npc-002 | `get_npc()` 호출 시 `duplicate_deep()`으로 스냅샷 반환 | ADR-0001 ✅ |
| TR-npc-003 | `set_state()`로 RelationshipState 변경, `npc_state_changed` 신호 발행 | ADR-0001 ✅ |
| TR-npc-004 | `is_initialized` guard + `registry_initialized` 신호 | ADR-0002 ✅ |
| TR-npc-005 | MAX_PARTY_SIZE = 3, COMPANION 전환 시 `companion_count < MAX_PARTY_SIZE` 검사 | ADR-0002 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/NPC-상태-관리.md`의 모든 Acceptance Criteria 검증
- Logic stories 테스트 파일이 `tests/unit/npc/`에 존재하고 통과
- `duplicate_deep()` 스냅샷 독립성 단위 테스트 통과
- `registry_initialized` 이전 `set_state()` 호출 시 경고 로그 출력 확인
- NPCRegistry Autoload가 project.godot에 순서 3번으로 등록됨

## Next Step

`/create-stories npc-registry`를 실행하여 구현 가능한 Story로 분해하세요.
