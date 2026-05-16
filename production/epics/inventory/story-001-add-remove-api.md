# Story 001: Inventory Autoload — add/remove/has/get + 신호

> **Epic**: Inventory
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/인벤토리-시스템.md`
**Requirements**: `TR-inv-001`, `TR-inv-002`

**ADR Governing Implementation**: ADR-0001: Data Registry Autoload + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: `Inventory` Autoload, 등록 순서 5번. `{item_id: StringName → quantity: int}` Dictionary. `add_item()`, `remove_item()`, `has_item()`, `get_quantity()`. 아이템 변경 시 `item_added`/`item_removed` 신호.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload 등록 순서 5번 (Inventory), `src/core/inventory.gd`
- Required: `ItemDB` 로 유효성 검사 — 등록되지 않은 item_id 추가 거부

---

## Acceptance Criteria

- [ ] **AC-1**: `add_item(&"herb_moonleaf", 3)` → `get_quantity(&"herb_moonleaf") == 3`
- [ ] **AC-2**: `add_item` 중복 호출 → 수량 누적 (`3 + 2 == 5`)
- [ ] **AC-3**: `remove_item(&"herb_moonleaf", 2)` → `get_quantity == 1`
- [ ] **AC-4**: `remove_item` 수량 초과 시 실패 반환 (item 유지) — `false` 반환
- [ ] **AC-5**: `has_item(&"herb_moonleaf") == true`, 없는 아이템 `false`
- [ ] **AC-6**: `add_item` 시 `item_added(item_id, quantity)` 신호 emit
- [ ] **AC-7**: `remove_item` 성공 시 `item_removed(item_id, quantity)` 신호 emit
- [ ] **AC-8**: 등록되지 않은 item_id (`ItemDB.has_item()` false) → `add_item` 거부

---

## Implementation Notes

1. `src/core/inventory.gd` 생성 (`Node` 상속):
   ```gdscript
   class_name Inventory
   extends Node

   signal item_added(item_id: StringName, quantity: int)
   signal item_removed(item_id: StringName, quantity: int)

   var _items: Dictionary = {}  # StringName → int

   func add_item(item_id: StringName, quantity: int) -> bool:
       if not ItemDB.has_item(item_id):
           return false
       _items[item_id] = _items.get(item_id, 0) + quantity
       item_added.emit(item_id, quantity)
       return true

   func remove_item(item_id: StringName, quantity: int) -> bool:
       if get_quantity(item_id) < quantity:
           return false
       _items[item_id] -= quantity
       if _items[item_id] == 0:
           _items.erase(item_id)
       item_removed.emit(item_id, quantity)
       return true

   func has_item(item_id: StringName) -> bool:
       return _items.get(item_id, 0) > 0

   func get_quantity(item_id: StringName) -> int:
       return _items.get(item_id, 0)
   ```
2. `project.godot` Autoload 5번에 등록

---

## Out of Scope

- get_save_data() / load_save_data() — story-002

---

## QA Test Cases

AC-1~8 모두 자동화 테스트. ItemDB mock (herb_moonleaf 등록된 것으로 처리).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/inventory/inventory_api_test.gd` — AC-1~8 커버, 통과 필수

---

## Size Estimate

**Estimate**: 2–3 hours
- `inventory.gd` 작성: 45분
- project.godot 등록: 15분
- GUT 테스트: 1.5시간

---

## Dependencies

- Depends on: item-db (Foundation, 완료)
- Unlocks: inventory/story-002 (직렬화), QuestManager (has_item 조건)

---

## Completion Notes
**Completed**: 2026-05-12
**Criteria**: 8/8 passing
**Deviations**:
- ADVISORY: 스토리 의사코드 `ItemDB.has_item()` → 실제 API `ItemDB.has()`. 구현 정상.
- ADVISORY: `quantity <= 0` 가드 코드 리뷰 중 추가 (음수 재고 오염 방지). 테스트 4개 추가.
**Test Evidence**: Logic — `tests/unit/inventory/inventory_api_test.gd` (19 tests, AC-1~8 + quantity guard)
**Code Review**: Complete (CHANGES REQUIRED → 수정 완료)
