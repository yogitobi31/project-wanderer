# Story 002: _validate_definitions() — 등록 검증 규칙

> **Epic**: ItemDB
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/아이템-데이터베이스.md`
**Requirement**: `TR-item-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: 데이터 레지스트리 Autoload 패턴 + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: ItemDB._ready()에서 `_validate_definitions()`를 실행한다. 규칙 위반 아이템은 등록 거부 + `error_occurred` 신호 발행. CONSUMABLE max_stack 센티넬 보정(99→20)만 자동 수정 허용 — 그 외 자동 수정 금지.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Dictionary, Array[StringName], assert() — 4.6에서 변경 없음 (stable). `assert(false)`는 디버그 빌드에서만 중단; 릴리즈 빌드에서는 push_error + 등록 거부로 처리.

**Control Manifest Rules (Foundation layer)**:
- Required: `_validate_definitions()`는 `_ready()` 내에서 모든 `.tres` 로드 완료 후 실행
- Required: 검증 실패 시 반드시 `error_occurred.emit(message)` 호출 후 등록 거부
- Forbidden: 검증 실패 아이템 자동 수정 금지 (CONSUMABLE max_stack 센티넬 보정 예외 제외)

---

## Acceptance Criteria

*From GDD `design/gdd/아이템-데이터베이스.md`:*

**등록 거부 규칙:**
- [ ] `category=QUEST_ITEM, is_quest_item=false` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-CR-05)
- [ ] `stackable=false, max_stack=10` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-CR-06)
- [ ] 중복 `item_id` → `error_occurred` 발행 + 두 번째 등록 거부, 첫 번째 유지 (AC-ITEM-CR-07)
- [ ] `max_stack=0` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-CR-08)
- [ ] `icon=null` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-CR-09)
- [ ] `is_quest_item=true, quest_tags=[]` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-EC-01)
- [ ] `category=CONSUMABLE, effect_type=HEAL, effect_value=0.0` → `error_occurred` 발행 + 등록 거부 (AC-ITEM-EC-04)
- [ ] `is_quest_item=false, quest_tags=[&"quest_x"]` (비어 있지 않음) → `error_occurred` 발행 + 등록 거부 (AC-ITEM-EC-05)

**경고 허용 규칙:**
- [ ] `category=RESOURCE, effect_type=HEAL` → push_warning 발생 + **등록 허용** (`has()==true`) (AC-ITEM-CR-13)
- [ ] `category=RESOURCE, is_quest_item=true, quest_tags=[&"quest_x"]` → error_occurred 없음 + 등록 허용 (AC-ITEM-EC-06)

**자동 보정 규칙:**
- [ ] `category=CONSUMABLE, max_stack=99(기본값 센티넬)` → `_validate_definitions()` 후 `max_stack == CONSUMABLE_MAX_STACK_DEFAULT(20)` (AC-ITEM-CR-11)

---

## Implementation Notes

*Derived from ADR-0001 + ADR-0002 Implementation Guidelines:*

`_validate_definitions()` 함수를 ItemDB._ready()에서 로드 완료 후 호출:

```gdscript
func _validate_definitions() -> void:
    var to_remove: Array[StringName] = []
    for item_id in _items:
        var def: ItemDefinition = _items[item_id]
        var valid := true

        # CONSUMABLE max_stack 센티넬 보정 (자동 수정 허용 — 기본값 채우기)
        if def.category == ItemCategory.CONSUMABLE and def.max_stack == 99:
            def.max_stack = CONSUMABLE_MAX_STACK_DEFAULT  # 20

        # 거부 규칙
        if def.category == ItemCategory.QUEST_ITEM and not def.is_quest_item:
            error_occurred.emit("..."); valid = false
        if not def.stackable and def.max_stack != 1:
            error_occurred.emit("..."); valid = false
        if def.max_stack < 1:
            error_occurred.emit("..."); valid = false
        if def.icon == null:
            error_occurred.emit("..."); valid = false
        if def.is_quest_item and def.quest_tags.is_empty():
            error_occurred.emit("..."); valid = false
        if not def.is_quest_item and not def.quest_tags.is_empty():
            error_occurred.emit("..."); valid = false
        if def.category == ItemCategory.CONSUMABLE and def.effect_type != EffectType.NONE and def.effect_value <= 0.0:
            error_occurred.emit("..."); valid = false

        # 경고만 (등록 허용)
        if def.category != ItemCategory.CONSUMABLE and def.effect_type != EffectType.NONE:
            push_warning("...")

        if not valid:
            to_remove.append(item_id)

    for id in to_remove:
        _items.erase(id)
```

중복 item_id는 DirAccess 스캔 단계에서 처리:
```gdscript
if _items.has(def.item_id):
    push_error("Duplicate item_id: " + def.item_id)
    error_occurred.emit("...")
    continue  # 두 번째 등록 거부, 첫 번째 유지
```

---

## Out of Scope

- Story 001: ItemDefinition 구조 및 get/has 인터페이스 — 이 스토리의 전제조건
- 퀘스트 fast-path (AC-ITEM-EC-02) — 퀘스트 상태 머신 GDD 완성 후 Integration 스토리로 분리

---

## QA Test Cases

*Logic 스토리 — 자동화 테스트 스펙 (GUT):*

**거부 규칙 테스트:**

- **AC-ITEM-CR-05**: QUEST_ITEM + is_quest_item=false 거부
  - Given: `category=QUEST_ITEM, is_quest_item=false` ItemDefinition
  - When: ItemDB._validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`

- **AC-ITEM-CR-06**: stackable=false + max_stack!=1 거부
  - Given: `stackable=false, max_stack=10`
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`
  - Edge cases: max_stack=2, max_stack=0 모두 거부

- **AC-ITEM-CR-07**: 중복 item_id 거부
  - Given: 동일 item_id를 가진 두 .tres 파일
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, 첫 번째 정의 유지(`has()==true`), 두 번째 거부

- **AC-ITEM-CR-08**: max_stack=0 거부
  - Given: `stackable=true, max_stack=0`
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`

- **AC-ITEM-CR-09**: icon=null 거부
  - Given: `icon=null` (Texture2D 미할당)
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`

- **AC-ITEM-EC-01**: is_quest_item=true + quest_tags 비어 있음 거부
  - Given: `is_quest_item=true, quest_tags=[]`
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`

- **AC-ITEM-EC-04**: CONSUMABLE + HEAL + effect_value=0.0 거부
  - Given: `category=CONSUMABLE, effect_type=HEAL, effect_value=0.0`
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`
  - Edge cases: effect_value=-1.0도 거부

- **AC-ITEM-EC-05**: quest_tags 비어 있지 않음 + is_quest_item=false 거부
  - Given: `is_quest_item=false, quest_tags=[&"quest_x"]`
  - When: _validate_definitions() 실행
  - Then: error_occurred 발행, `has(item_id)==false`

**경고 허용 테스트:**

- **AC-ITEM-CR-13**: non-CONSUMABLE + effect_type!=NONE — 경고 발행 + 등록 허용
  - Given: `category=RESOURCE, effect_type=HEAL(1)`
  - When: _validate_definitions() 실행
  - Then: error_occurred 미발행, `has(item_id)==true`

- **AC-ITEM-EC-06**: RESOURCE + is_quest_item=true — 등록 허용
  - Given: `category=RESOURCE, is_quest_item=true, quest_tags=[&"quest_x"]`
  - When: _validate_definitions() 실행
  - Then: error_occurred 미발행, `has(item_id)==true`

**보정 규칙 테스트:**

- **AC-ITEM-CR-11**: CONSUMABLE max_stack 센티넬 보정
  - Given: `category=CONSUMABLE, max_stack=99` (GDScript 필드 기본값)
  - When: _validate_definitions() 완료 후 ItemDB.get(item_id).max_stack 조회
  - Then: `max_stack == ItemDB.CONSUMABLE_MAX_STACK_DEFAULT` (20)
  - Edge cases: max_stack=50 (명시적 설정값)은 보정 없이 50 유지

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/item_db/item_db_validate_test.gd` — GUT 테스트, 위 11개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (item-db) DONE — ItemDefinition 구조 및 ItemDB 기본 프레임 필요
- Unlocks: npc-registry/001 (ItemDB 완성 후 NPCRegistry 구현 가능)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 11/11 passing
**Deviations**:
- ADVISORY: CR-07 단위 테스트가 `_load_items()` production 코드가 아닌 하네스 시뮬레이션임 — DirAccess 구조적 한계, Integration 테스트 tech debt
- ADVISORY: sentinel `99` magic number — `ItemDefinition.MAX_STACK_SENTINEL` 추출 권장
**Test Evidence**: Logic — `tests/unit/item_db/item_db_validate_test.gd` (35 test functions, 11 AC 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (Resource duplicate-before-mutate, DirAccess failure signal 추가)
