# Story 001: ItemDefinition Resource 및 ItemDB Autoload 기본 구조

> **Epic**: ItemDB
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/아이템-데이터베이스.md`
**Requirements**: `TR-item-001`, `TR-item-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: 데이터 레지스트리 Autoload 패턴 + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: ItemDB는 4가지 기준을 충족하는 순수 데이터 레지스트리 Autoload다. `get()`/`has()` 읽기 전용 인터페이스만 노출하며, `res://assets/data/items/`를 DirAccess로 스캔해 `.tres` 파일을 로드한다. project.godot 등록 순서 2번 (`EventBus` 다음, `NPCRegistry` 전).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: DirAccess, load(), Dictionary — 4.6에서 변경 없음 (stable). `@export var category: ItemCategory` enum 타입 직접 선언 지원됨 (Godot 4.6). `Array[StringName]` @export 직렬화 시 StringName 리터럴(`&"id"`) 사용 필수.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload는 `src/core/item_db.gd` 경로, `*` 접두사로 등록
- Required: 공개 인터페이스는 `get()`, `has()` 2개만 — 런타임 쓰기 메서드 금지
- Forbidden: 다운스트림 시스템의 `.tres` 직접 `load()`/`preload()` 금지 — 모든 접근은 `ItemDB.get()` 경유

---

## Acceptance Criteria

*From GDD `design/gdd/아이템-데이터베이스.md`:*

- [ ] `ItemDB.get(&"herb_moonleaf")` 호출 시 null이 아닌 `item_id == &"herb_moonleaf"`인 ItemDefinition을 반환한다 (AC-ITEM-CR-01)
- [ ] `ItemDB.get(&"nonexistent")` 호출 시 `null`을 반환한다 (AC-ITEM-CR-02)
- [ ] `ItemDB.get()` 미등록 아이템 조회 시 `error_occurred` 신호가 1회 발행된다 (AC-ITEM-CR-02b)
- [ ] `ItemDB.has(&"old_key")`는 `true`, `ItemDB.has(&"missing")`는 `false` 반환 — `error_occurred` 신호 없음 (AC-ITEM-CR-03)
- [ ] `ItemCategory` enum에 `QUEST_ITEM(0)`, `RESOURCE(1)`, `CONSUMABLE(2)` 3개가 존재하고 `EQUIPMENT`는 없다 (AC-ITEM-CR-04)
- [ ] CONSUMABLE 아이템 `get()` 시 `effect_type`과 `effect_value`가 정확히 반환된다 (AC-ITEM-CR-10)
- [ ] `source_companion_id`, `source_quest_id` 필드가 정확히 반환된다 (AC-ITEM-CR-12)
- [ ] `RESOURCE + is_quest_item=true + quest_tags=[&"quest_jin_herb"]` 아이템 `get()` 시 세 필드 모두 정확히 반환된다 (AC-ITEM-EC-03)

---

## Implementation Notes

*Derived from ADR-0001 + ADR-0002 Implementation Guidelines:*

1. `src/core/item_definition.gd` 생성 — `Resource`를 상속하는 GDScript
   - 모든 필드를 `@export`로 선언 (`.tres` 직렬화 보장)
   - `category: ItemCategory`, `effect_type: EffectType` — enum 타입 직접 선언
   - `quest_tags: Array[StringName]` — StringName 리터럴 입력 주의사항 주석 추가
2. `src/core/item_db.gd` 생성 — `Node`를 상속하는 GDScript
   - `_init()`: 빈 Dictionary 초기화 (`_items: Dictionary = {}`)
   - `_ready()`: `DirAccess.open("res://assets/data/items/")` 스캔 → `.tres` 로드 → `_items[def.item_id] = def`
   - `get(item_id: StringName) -> ItemDefinition`: 없으면 `error_occurred.emit()` + `null` 반환
   - `has(item_id: StringName) -> bool`: `error_occurred` 미발행
   - `signal error_occurred(message: String)` 선언
3. `project.godot` Autoload 등록 순서 2번:
   ```
   ItemDB = "*res://src/core/item_db.gd"
   ```
   (EventBus 다음, NPCRegistry 전)
4. `res://assets/data/items/` 디렉토리 생성 (빈 디렉토리, 테스트용 `.tres` 포함)

---

## Out of Scope

- Story 002: `_validate_definitions()` 검증 규칙 — 이 스토리에서 구현하지 않음
- 인벤토리, 퀘스트 시스템과의 통합 — Feature 레이어 에픽에서 처리

---

## QA Test Cases

*Logic 스토리 — 자동화 테스트 스펙 (GUT):*

- **AC-ITEM-CR-01**: 등록된 아이템 조회
  - Given: `herb_moonleaf.tres` (item_id=&"herb_moonleaf")가 `res://assets/data/items/`에 존재
  - When: `ItemDB.get(&"herb_moonleaf")` 호출
  - Then: 반환값이 null이 아니고 `item_id == &"herb_moonleaf"`
  - Edge cases: item_id가 String이 아닌 StringName으로 조회

- **AC-ITEM-CR-02**: 미등록 아이템 null 반환
  - Given: &"nonexistent"가 ItemDB에 없음
  - When: `ItemDB.get(&"nonexistent")` 호출
  - Then: `null` 반환

- **AC-ITEM-CR-02b**: 미등록 아이템 error_occurred 발행
  - Given: `ItemDB.error_occurred.connect(_on_error)` 완료
  - When: `ItemDB.get(&"nonexistent")` 호출
  - Then: `_on_error` 콜백 정확히 1회 호출

- **AC-ITEM-CR-03**: has() — 에러 없이 bool 반환
  - Given: &"old_key" 등록됨, &"missing_item" 미등록, error_occurred 수신자 연결
  - When: 각각 `has()` 호출
  - Then: `true` / `false`, error_occurred 미발행

- **AC-ITEM-CR-04**: ItemCategory enum 구조 확인
  - When: `ItemDB.ItemCategory.QUEST_ITEM`, `RESOURCE`, `CONSUMABLE` 상수 접근
  - Then: 값 0, 1, 2 / `ItemDB.ItemCategory.EQUIPMENT` 존재 시 테스트 실패

- **AC-ITEM-CR-10**: CONSUMABLE effect 필드 보존
  - Given: `effect_type=HEAL(1), effect_value=50.0`인 CONSUMABLE 등록
  - When: `ItemDB.get(item_id)` 호출
  - Then: `effect_type == 1`, `effect_value == 50.0`

- **AC-ITEM-CR-12**: source 필드 보존
  - Given: `source_companion_id=&"companion_jin", source_quest_id=&"quest_jin_herb"` 등록
  - When: `ItemDB.get(item_id)` 호출
  - Then: 두 필드 모두 일치

- **AC-ITEM-EC-03**: RESOURCE + quest_tags 양방향 조회
  - Given: `category=RESOURCE, is_quest_item=true, quest_tags=[&"quest_jin_herb"]` 등록
  - When: `ItemDB.get(item_id)` 호출
  - Then: `category==RESOURCE`, `is_quest_item==true`, `quest_tags.has(&"quest_jin_herb")==true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/item_db/item_db_read_test.gd` — GUT 테스트, 위 8개 AC 커버, 반드시 존재하고 통과

**Status**: [x] `tests/unit/item_db/item_db_read_test.gd` — 19개 테스트 함수, 8개 AC 커버 완료

---

## Dependencies

- Depends on: Story event-bus/001 DONE (project.godot Autoload 등록 패턴 확립)
- Unlocks: Story 002 (item-db) — `_validate_definitions()` 검증 규칙

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 8/8 passing
**Deviations**: ADVISORY — `get_item()` (ADR-0001 명세는 `get()`이나 Object.get() 충돌로 변경, 기능 동일)
**Test Evidence**: Logic — `tests/unit/item_db/item_db_read_test.gd` (19 tests, 8 AC 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (get_item() 변경, _init() 제거, before_each 초기화 이동)
