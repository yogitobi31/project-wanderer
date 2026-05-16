# Story 001: NPCRecord 데이터 구조 및 NPCRegistry 읽기 인터페이스

> **Epic**: NPCRegistry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/NPC-상태-관리.md`
**Requirements**: `TR-npc-001`, `TR-npc-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: 데이터 레지스트리 Autoload 패턴 + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: NPCRegistry는 4가지 기준 충족 Autoload로, `get_npc()` 단일 경로로 5개+ 다운스트림 시스템이 접근한다. `_ready()` 완료 후 `registry_initialized` 신호를 emit하며, 초기화 전 호출 시 `error_occurred`를 발행한다. project.godot 등록 순서 3번 (ItemDB 다음).

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: `duplicate_deep()` — Godot 4.5+ API. NPCRecord 내 `Array[StringName]`, `Dictionary` 필드가 올바르게 딥 복사되는지 Godot 4.6에서 확인 필요. `docs/engine-reference/godot/` 검증 후 구현 시작.

> ⚠️ **설계 불일치 — 구현 전 해소 필요**
> TR-npc-002 / ADR-0001 / architecture.md: `get_npc()`가 `snapshot()` 반환
> GDD Core Rule 7: `get_npc()`가 **라이브 참조** 반환 (직접 쓰기 금지 규칙 적용)
> 어느 패턴을 따를지 결정 후 Story 001과 Story 003을 구현할 것.
> 권장: GDD Core Rule 7 (라이브 참조) — ADR-0001 코멘트를 GDD 기준으로 정정.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload는 `src/core/npc_registry.gd`, `*` 접두사로 등록
- Required: 공개 읽기 인터페이스 — `get_npc()`, `get_companions()`, `party_has_tag()`
- Forbidden: 다운스트림 시스템의 NPCRecord 필드 직접 쓰기 — 쓰기는 set_state() 등 전용 API만

---

## Acceptance Criteria

*From GDD `design/gdd/NPC-상태-관리.md`:*

- [ ] 동료·퀘스트·중립 NPC 레코드 모두 `record is NPCRecord` 타입 체크가 `true` (AC-NPC-CR-01)
- [ ] `RelationshipState` enum 7개 값이 정수 고정 — UNKNOWN=0, MET=1, QUEST_ACTIVE=2, COMPANION=3, DEPARTED=4, HOSTILE=5, QUEST_ABANDONED=6 (AC-NPC-CR-02)
- [ ] `get_npc("invalid_id")` → `null` 반환 + `error_occurred` 1회 발행 (AC-NPC-CR-04)
- [ ] COMPANION 상태 1개만 있을 때 `get_companions()` → 크기 1, `relationship_state==COMPANION` (AC-NPC-CR-07)
- [ ] `recruitment_tags`에 `&"healer"` 포함 COMPANION 존재 시 `party_has_tag(&"healer")` → `true` (AC-NPC-CR-08)
- [ ] COMPANION의 tags에 없는 태그 + QUEST_ACTIVE NPC가 보유해도 `party_has_tag()` → `false` (AC-NPC-CR-08b)
- [ ] `bond_tags`에만 `&"secret_path"` 있을 때 `party_has_tag(&"secret_path")` → `true` (AC-NPC-CR-08c)
- [ ] `_ready()` 미실행 상태 인스턴스의 `is_initialized` → `false` (AC-NPC-CR-14)
- [ ] `add_child()` + 1 프레임 대기 후 `is_initialized` → `true` (AC-NPC-CR-15)
- [ ] 등록된 NPC 없을 때 `get_companions()` → `[]`, `party_has_tag("any")` → `false` (AC-NPC-EC-06)

---

## Implementation Notes

*Derived from ADR-0001 + ADR-0002:*

1. `src/core/npc_record.gd` 생성 — `Resource` 상속
   - 모든 필드 `@export` 선언 (직렬화 보장)
   - `RelationshipState` enum: UNKNOWN=0 ~ QUEST_ABANDONED=6 (정수 고정 — 세이브 파일 하위 호환)
   - `is_in_party: bool` — `relationship_state == COMPANION`에서 파생, 독립 저장 금지
   - `snapshot() -> NPCRecord` 메서드 구현 (Story 003에서 독립성 검증)

2. `src/core/npc_registry.gd` 생성 — `Node` 상속
   - `_records: Dictionary` (npc_id → NPCRecord)
   - `_companions_cache: Array[NPCRecord]` — COMPANION 상태 레코드 캐시
   - `is_initialized: bool` — `_ready()` 완료 후 true
   - `signal registry_initialized()`, `signal error_occurred(message: String)`
   - `_ready()`: `.tres` 로드 → `_validate_records()` → `is_initialized = true` → emit `registry_initialized`
   - `get_npc(npc_id)`: `is_initialized` 가드 → null + `error_occurred` 미초기화 시
   - `get_companions()`: `_companions_cache.duplicate()` 반환 (배열 컨테이너만 복사, 레코드는 라이브)
   - `party_has_tag(tag)`: `_companions_cache` 순회 → `recruitment_tags` + `bond_tags` 검색

3. `project.godot` 등록 순서 3번:
   ```
   NPCRegistry = "*res://src/core/npc_registry.gd"
   ```

---

## Out of Scope

- Story 002: `set_state()` FSM 및 상태 전환 로직
- Story 003: 쓰기 API (`set_quest_flag`, `update_dialogue_node`), `snapshot()` 독립성 검증

---

## QA Test Cases

- **AC-NPC-CR-01**: 공용 NPCRecord 구조
  - Given: 동료·퀘스트·중립 NPC 픽스처 3개 생성
  - When: 각각 `record is NPCRecord` 타입 체크
  - Then: 모두 `true`

- **AC-NPC-CR-02**: RelationshipState 정수값 고정 (세이브 파일 하위 호환 회귀 방지)
  - When: 각 상수 값을 정수로 assert
  - Then: UNKNOWN=0, MET=1, QUEST_ACTIVE=2, COMPANION=3, DEPARTED=4, HOSTILE=5, QUEST_ABANDONED=6 (모두 통과)
  - Edge cases: 값 재정렬 시 즉시 실패 → 의도된 회귀 감지

- **AC-NPC-CR-04**: 미등록 NPC null 반환 + error_occurred
  - Given: error_occurred 수신자 연결, &"ghost_id" 미등록
  - When: `get_npc(&"ghost_id")` 호출
  - Then: null 반환, error_occurred 정확히 1회

- **AC-NPC-CR-07**: get_companions() 파티 필터
  - Given: NPC 3개 — 1개 COMPANION, 2개 다른 상태
  - When: `get_companions()` 호출
  - Then: 배열 크기 1, 해당 레코드 `relationship_state == COMPANION`

- **AC-NPC-CR-08/08b/08c**: party_has_tag() 쿼리
  - Given(08): COMPANION 동료 `recruitment_tags = [&"healer"]`
  - Then: `party_has_tag(&"healer")` → true
  - Given(08b): COMPANION에 `&"lockpick"` 없음, QUEST_ACTIVE NPC가 보유
  - Then: `party_has_tag(&"lockpick")` → false
  - Given(08c): COMPANION `recruitment_tags`에 없고 `bond_tags = [&"secret_path"]`
  - Then: `party_has_tag(&"secret_path")` → true

- **AC-NPC-CR-14/15**: is_initialized 가드
  - Given(14): `NPCRegistry.new()` 호출만 (add_child 없음)
  - Then: `is_initialized == false`
  - Given(15): `add_child_autofree(registry)` + `await process_frame`
  - Then: `is_initialized == true`

- **AC-NPC-EC-06**: 빈 레지스트리 안전 기본값
  - Given: 등록된 NPC 없음
  - When: `get_companions()`, `party_has_tag(&"any")` 호출
  - Then: `[]`, `false`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc/npc_registry_read_test.gd` — GUT 테스트, 위 10개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: item-db/001 DONE (project.godot Autoload 등록 패턴 확립, ItemDB #2 등록 후 NPCRegistry #3)
- Unlocks: Story 002 (npc-registry), Story 003 (npc-registry)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 10/10 passing
**Deviations**: ADVISORY — `get_npc()` 라이브 참조 반환 (ADR-0001 의사코드는 snapshot — GDD Core Rule 7 우선 적용, 스토리에 기록됨)
**Test Evidence**: Logic — `tests/unit/npc/npc_registry_read_test.gd` (24 test functions, 10 AC + pre-init guard 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (item_id 오타 수정, pre-init 가드 테스트 추가, Array 명시적 캐스트)
