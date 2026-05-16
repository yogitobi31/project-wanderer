# Story 002: Inventory — SaveManager 직렬화 계약

> **Epic**: Inventory
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/인벤토리-시스템.md`
**Requirements**: `TR-save-002`

**ADR Governing Implementation**: ADR-0007: SaveManager 직렬화
**ADR Decision Summary**: `get_save_data()` → `{"items": [{"item_id": String, "quantity": int}]}`. `load_save_data(data)` → `_items` Dictionary 복원. 방어적 로드 (키 없으면 기본값).

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Foundation layer)**:
- Required: `get_save_data() -> Dictionary` / `load_save_data(data: Dictionary) -> void` 계약
- Required: JSON-serializable 타입만 반환 (String, int, float, bool, Array, Dictionary)
- Required: StringName → String 명시적 캐스팅 (`StringName(data["item_id"])`)

---

## Acceptance Criteria

- [ ] **AC-1**: `add_item(&"herb_moonleaf", 5)` 후 `get_save_data()` → `{"items": [{"item_id": "herb_moonleaf", "quantity": 5}]}`
- [ ] **AC-2**: `load_save_data({"items": [{"item_id": "herb_moonleaf", "quantity": 3}]})` → `get_quantity(&"herb_moonleaf") == 3`
- [ ] **AC-3**: 라운드트립: `load_save_data(get_save_data())` → 인벤토리 상태 동일
- [ ] **AC-4**: `load_save_data({})` (빈 딕셔너리) → 오류 없이 빈 인벤토리

---

## Implementation Notes

1. `inventory.gd`에 직렬화 메서드 추가:
   ```gdscript
   func get_save_data() -> Dictionary:
       var items_array: Array = []
       for item_id: StringName in _items:
           items_array.append({"item_id": str(item_id), "quantity": _items[item_id]})
       return {"items": items_array}

   func load_save_data(data: Dictionary) -> void:
       _items.clear()
       var items_array: Array = data.get("items", [])
       for entry: Dictionary in items_array:
           var item_id: StringName = StringName(entry.get("item_id", ""))
           var quantity: int = entry.get("quantity", 0) as int
           if item_id != &"" and quantity > 0:
               _items[item_id] = quantity
   ```

---

## QA Test Cases

AC-1~4 자동화 테스트. JSON stringify → parse_string 라운드트립 포함.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/inventory/inventory_save_test.gd` — AC-1~4 커버, 통과 필수

---

## Size Estimate

**Estimate**: 1.5 hours
- 직렬화 메서드 작성: 30분
- GUT 테스트 (라운드트립): 1시간

---

## Dependencies

- Depends on: inventory/story-001
- Unlocks: SaveManager 구현 시 Inventory 연동

---

## Completion Notes
**Completed**: 2026-05-12
**Criteria**: 4/4 passing
**Deviations**:
- ADVISORY: 코드 리뷰 중 `as int` → `int()` 수정 (JSON float silent data loss 버그)
- ADVISORY: `Array` → `Array[Dictionary]` 타입 강화
- ADVISORY: `load_save_data` ItemDB 검증 없이 신뢰 로드 (설계 의도 — 세이브 파일 신뢰)
**Test Evidence**: Logic — `tests/unit/inventory/inventory_save_test.gd` (13 tests, AC-1~4)
**Code Review**: Complete (CHANGES REQUIRED → 수정 완료)
