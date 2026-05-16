# Epic: ItemDB

> **Layer**: Foundation
> **GDD**: design/gdd/아이템-데이터베이스.md
> **Architecture Module**: ItemDB (Autoload)
> **Status**: Ready
> **Stories**: 2 stories created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [ItemDefinition Resource 및 ItemDB Autoload 기본 구조](story-001-itemdefinition-and-autoload-structure.md) | Logic | Ready | ADR-0001, ADR-0002 |
| 002 | [_validate_definitions() — 등록 검증 규칙](story-002-validate-definitions.md) | Logic | Ready | ADR-0001, ADR-0002 |

## Overview

ItemDB는 모든 아이템 정의(ItemDefinition Resource)를 저장하는 읽기 전용 Foundation Autoload다.
`DirAccess`로 `res://assets/data/items/` 디렉터리를 스캔하여 `.tres` 파일을 로드하고,
`{item_id → ItemDefinition}` Dictionary를 구성한다.
런타임에서 `get(item_id)`, `has(item_id)` 읽기 전용 인터페이스만 노출하며,
정의 오류 시 `error_occurred` 신호를 발행하여 게임 크래시 없이 경고를 전달한다.
Inventory, RecruitmentQuest, PickupItem 등 3개+ 시스템의 아이템 정의 공급자.
Autoload 등록 순서 2번.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|---|---|---|
| ADR-0001: Data Registry Autoload | ItemDB를 4가지 기준 충족 Autoload로 등재, 읽기 전용 계약 | LOW |
| ADR-0002: Foundation Autoload 등록 순서 | ItemDB Track 1 Data Registry, 등록 순서 2번, `_validate_definitions()` 계약 | LOW |

## GDD Requirements

| TR-ID | 요구사항 | ADR Coverage |
|---|---|---|
| TR-item-001 | ItemDB Autoload — 아이템 정의 전역 읽기 전용 접근 경로 | ADR-0001 ✅ |
| TR-item-002 | `get()`, `has()` 읽기 전용 인터페이스만 노출 — 런타임 수정 금지 | ADR-0001 ✅ |
| TR-item-003 | `_ready()`에서 `_validate_definitions()` 실행, 오류 시 `error_occurred` 신호 발행 | ADR-0002 ✅ |

## Definition of Done

이 Epic은 아래 조건이 모두 충족될 때 완료된다:
- 모든 Stories가 구현·리뷰·`/story-done` 완료
- `design/gdd/아이템-데이터베이스.md`의 모든 Acceptance Criteria 검증
- Logic stories 테스트 파일이 `tests/unit/item/`에 존재하고 통과
- 잘못된 아이템 정의 시 `error_occurred` 발행 단위 테스트 통과
- ItemDB Autoload가 project.godot에 순서 2번으로 등록됨

## Next Step

`/create-stories item-db`를 실행하여 구현 가능한 Story로 분해하세요.
