# Story 002: set_state() FSM + npc_state_changed 신호

> **Epic**: NPCRegistry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/NPC-상태-관리.md`
**Requirements**: `TR-npc-003`, `TR-npc-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: 데이터 레지스트리 Autoload 패턴 + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: `set_state()`는 NPCRegistry만 호출 가능한 쓰기 API. 상태 변경 시 `npc_state_changed(npc_id, old_state, new_state)` 신호를 발행한다. MAX_PARTY_SIZE=3 제한은 COMPANION 진입 시 강제된다.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: GDScript 신호는 동기 실행 — 신호 핸들러 내에서 set_state() 재호출 시 재진입(reentrance) 주의. GDScript 단일 스레드이므로 레이스 컨디션 없음.

**Control Manifest Rules (Foundation layer)**:
- Required: 상태 전환 시 반드시 `npc_state_changed` 신호 발행
- Required: 동일 상태 전환 시 no-op + 신호 미발행
- Forbidden: `set_state()` 우회한 필드 직접 쓰기

---

## Acceptance Criteria

*From GDD `design/gdd/NPC-상태-관리.md`:*

**신호 페이로드:**
- [ ] `set_state(id, COMPANION)` → `npc_state_changed` 1회, old_state=직전상태, new_state=COMPANION(3) (AC-NPC-CR-03)
- [ ] 연속 두 번 전환 → 첫 번째 signal(old=UNKNOWN, new=MET), 두 번째(old=MET, new=QUEST_ACTIVE) (AC-NPC-CR-03b)

**전환 거부:**
- [ ] `COMPANION(3)` 상태에서 `set_state(id, UNKNOWN(0))` → 상태 유지, `error_occurred` 발행 (AC-NPC-CR-05)
- [ ] `MET(1)` 상태에서 `set_state(id, UNKNOWN(0))` → 상태 유지, `error_occurred` 1회 (AC-NPC-CR-05b)
- [ ] `DEPARTED(4)` 상태에서 `set_state(id, HOSTILE(5))` → 상태 유지, `error_occurred` 1회 (AC-NPC-CR-18)
- [ ] `set_state(id, 99)` 또는 `set_state(id, -1)` → 상태 유지, `error_occurred` 1회 (AC-NPC-CR-19)

**사이드 이펙트:**
- [ ] `QUEST_ACTIVE → COMPANION` 전환 시 `active_quest_id == &""` (AC-NPC-CR-09)
- [ ] `COMPANION → COMPANION` (동일 상태) → 상태 유지, 신호 미발행 (AC-NPC-CR-10)
- [ ] `COMPANION → DEPARTED` → 상태=DEPARTED, `party_slot=-1`, `get_companions()`에서 제외, 신호(old=COMPANION, new=DEPARTED) (AC-NPC-CR-11)
- [ ] `MET → QUEST_ACTIVE → COMPANION` 연속 호출 → 최종 COMPANION, 신호 2회 (AC-NPC-CR-12)
- [ ] `QUEST_ACTIVE → QUEST_ABANDONED` → 상태=QUEST_ABANDONED, `active_quest_id=&""`, 신호 발행 (AC-NPC-CR-16)
- [ ] `QUEST_ABANDONED → QUEST_ACTIVE` → 상태=QUEST_ACTIVE, 신호 발행 (AC-NPC-CR-17)

**HOSTILE 예외 (FSM 로직 포함 — VS+ 이후 테스트):**
- [ ] `MET → HOSTILE` 허용 — VS+ 이후 테스트 활성화 (AC-NPC-CR-06)
- [ ] `COMPANION → HOSTILE` → party_slot=-1, _companions_cache에서 제거 — VS+ 이후 테스트 활성화 (AC-NPC-CR-06b)

---

## Implementation Notes

*Derived from ADR-0001 + ADR-0002:*

`set_state(npc_id, new_state)` 구현 패턴 (GDD Core Rule 9):

```gdscript
func set_state(npc_id: StringName, new_state: int) -> void:
    if not is_initialized:
        error_occurred.emit("NPCRegistry not yet initialized")
        return
    var record := _records.get(npc_id, null)
    if record == null:
        error_occurred.emit("NPC not found: " + npc_id)
        return

    var old_state: int = record.relationship_state

    # 동일 상태 no-op
    if old_state == new_state:
        return

    # 범위 검사
    if new_state < 0 or new_state > 6:
        error_occurred.emit("Invalid state: " + str(new_state))
        return

    # 전환 허용 매트릭스 검증
    if not _is_transition_allowed(old_state, new_state):
        error_occurred.emit("Illegal transition: " + str(old_state) + " → " + str(new_state))
        return

    # COMPANION 진입 — 슬롯 자동 할당 (MAX_PARTY_SIZE=3 강제)
    if new_state == RelationshipState.COMPANION:
        var used_slots = _companions_cache.map(func(r): return r.party_slot)
        var assigned := false
        for slot in range(MAX_PARTY_SIZE):
            if slot not in used_slots:
                record.party_slot = slot
                assigned = true
                break
        if not assigned:
            error_occurred.emit("No available party slot")
            return
        _companions_cache.append(record)

    # COMPANION 탈출
    if old_state == RelationshipState.COMPANION and new_state != RelationshipState.COMPANION:
        _companions_cache.erase(record)
        record.party_slot = -1
        if new_state == RelationshipState.DEPARTED:
            record.active_quest_id = &""

    # QUEST_ACTIVE/QUEST_ABANDONED → COMPANION 전환 시 active_quest_id 초기화
    if new_state == RelationshipState.COMPANION:
        record.active_quest_id = &""

    # QUEST_ACTIVE → QUEST_ABANDONED 전환 시 active_quest_id 초기화
    if new_state == RelationshipState.QUEST_ABANDONED:
        record.active_quest_id = &""

    record.relationship_state = new_state
    npc_state_changed.emit(npc_id, old_state, new_state)
```

허용 전환 매트릭스 (`_is_transition_allowed`):
- DEPARTED → * : 모두 거부 (단방향 종료 상태)
- HOSTILE → * : set_state()로 탈출 불가 (reset_hostile() 전용)
- UNKNOWN → HOSTILE : 거부 (만난 적 없는 NPC 적대 불가)
- * → HOSTILE : UNKNOWN, DEPARTED 제외 허용 (VS+ 이후 콘텐츠 — MVP에서도 FSM 로직은 구현)
- QUEST_ABANDONED → QUEST_ACTIVE : 유일한 역방향 예외

---

## Out of Scope

- Story 001: NPCRecord 구조 및 읽기 인터페이스 — 이 스토리의 전제조건
- Story 003: `set_quest_flag()`, `update_dialogue_node()` 쓰기 API
- reset_hostile() — VS+ 자리 예약 (Story 003에 stub 선언)

---

## QA Test Cases

- **AC-NPC-CR-03**: 신호 페이로드 검증
  - Given: UNKNOWN 상태 NPC, npc_state_changed 수신자 연결
  - When: `set_state(id, COMPANION)` 호출
  - Then: 신호 1회, old_state=UNKNOWN(0), new_state=COMPANION(3), npc_id 일치

- **AC-NPC-CR-03b**: 연속 전환 신호
  - Given: UNKNOWN 상태 NPC
  - When: `set_state(id, MET)` → `set_state(id, QUEST_ACTIVE)` 순서
  - Then: 첫 신호 old=0/new=1, 두 번째 신호 old=1/new=2

- **AC-NPC-CR-05/05b**: 역방향 전환 거부
  - Given: COMPANION(3) 상태 NPC + error_occurred 수신자
  - When: `set_state(id, UNKNOWN(0))` 호출
  - Then: 상태 COMPANION(3) 유지, error_occurred 1회

- **AC-NPC-CR-09**: COMPANION 진입 시 active_quest_id 초기화
  - Given: QUEST_ACTIVE 상태, active_quest_id=&"quest_jin_01"
  - When: `set_state(id, COMPANION)` 호출
  - Then: active_quest_id == &""

- **AC-NPC-CR-10**: 동일 상태 no-op
  - Given: COMPANION(3) 상태 + 신호 수신자
  - When: `set_state(id, COMPANION(3))` 호출
  - Then: 상태 유지, npc_state_changed 미발행

- **AC-NPC-CR-11**: COMPANION → DEPARTED 사이드이펙트
  - Given: COMPANION 상태, party_slot=0
  - When: `set_state(id, DEPARTED)`
  - Then: 상태=DEPARTED, party_slot=-1, get_companions()에서 제외, 신호(old=3, new=4)

- **AC-NPC-CR-12**: 이중 set_state 최종값
  - Given: MET(1) 상태
  - When: `set_state(id, QUEST_ACTIVE)` 직후 `set_state(id, COMPANION)` 호출
  - Then: 최종 COMPANION(3), 신호 2회

- **AC-NPC-CR-16/17**: QUEST_ABANDONED 전환
  - Given: QUEST_ACTIVE(2), active_quest_id=&"quest_01"
  - When: `set_state(id, QUEST_ABANDONED)`
  - Then: 상태=6, active_quest_id=&"", 신호(old=2, new=6)
  - Then(재수락): `set_state(id, QUEST_ACTIVE)` → 상태=2, 신호 발행

- **AC-NPC-CR-18/19**: 차단 케이스
  - DEPARTED→HOSTILE: 상태 유지 + error_occurred
  - set_state(id, 99): 상태 유지 + error_occurred

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc/npc_registry_fsm_test.gd` — GUT 테스트, 위 12개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (npc-registry) DONE — NPCRecord 구조 및 NPCRegistry 프레임 필요
- Unlocks: Story 003 (npc-registry)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 14/14 passing
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/npc/npc_registry_fsm_test.gd` (46 test functions, 14 AC 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (active_quest_id COMPANION exit 누락 수정, Array[int] 타입 루프 교체, "new" 키워드 dict key 충돌 수정)
