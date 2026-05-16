# Epic: Inventory

> **Layer**: Core
> **GDD**: design/gdd/인벤토리-시스템.md
> **Architecture Module**: Inventory (Feature — Autoload)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories inventory`

## Overview

Inventory는 플레이어의 아이템 수량을 `{item_id→quantity}` Dictionary로 전역 관리하는 Autoload 싱글톤이다. `add_item()`, `remove_item()`, `has_item()`, `get_quantity()` 인터페이스를 제공하며, 아이템 추가/제거 시 `item_added`/`item_removed` 신호를 발행한다. ItemDB와 연동해 유효성을 검사하고, QuestManager의 `has_item` 조건 판정과 퀘스트 아이템 제거 계약을 이행한다. SaveManager와의 직렬화 계약(get_save_data / load_save_data)도 이 에픽 범위에 포함된다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Data Registry Autoload | Track 1 Data Registry 기준 충족 (4가지 기준) | LOW |
| ADR-0002: Foundation Autoload 등록 순서 | Autoload 등록 순서 5번 (Inventory), src/core/inventory.gd | LOW |
| ADR-0007: SaveManager 직렬화 | get_save_data() — items 배열, load_save_data() 복원 계약 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-inv-001 | Inventory Autoload — 플레이어 아이템 수량 전역 관리 | ADR-0002 ✅ |
| TR-inv-002 | Dictionary 기반 {item_id→quantity} 저장, add_item()/remove_item()/has_item()/get_quantity() 인터페이스 | ADR-0002 ✅ |
| TR-save-002 | Inventory 아이템 목록(item_id, quantity) 저장 및 복원 | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/인벤토리-시스템.md` are verified
- `add_item()` / `remove_item()` / `has_item()` / `get_quantity()` 단위 테스트 통과
- `get_save_data()` / `load_save_data()` 직렬화 라운드트립 단위 테스트 통과
- `item_added` / `item_removed` 신호 발행 — 단위 테스트 통과

## Next Step

Run `/create-stories inventory` to break this epic into implementable stories.
