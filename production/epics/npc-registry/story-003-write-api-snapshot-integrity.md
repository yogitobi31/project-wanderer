# Story 003: 쓰기 API, snapshot() 독립성 및 데이터 무결성

> **Epic**: NPCRegistry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/NPC-상태-관리.md`
**Requirements**: `TR-npc-002`, `TR-npc-004` (partial)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: 데이터 레지스트리 Autoload 패턴 + ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: NPCRecord 복사 시 `snapshot()`만 사용. `duplicate_deep()` 직접 호출 금지. `_quest_flags` 키는 String 타입 강제. 세이브 파일 부패 복구 시 MET(1) 폴백.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: `duplicate_deep()`이 `Array[StringName]`, `Dictionary` 내 중첩 값을 올바르게 딥 복사하는지 Godot 4.6에서 검증 필요. `snapshot()`에서 각 배열을 명시적으로 `.duplicate()`하는 이유가 여기에 있음. `docs/engine-reference/godot/` 확인 필수.

> ⚠️ **설계 불일치 — 구현 전 해소 필요**
> TR-npc-002 / ADR-0001: `get_npc()`가 snapshot() 반환
> GDD Core Rule 7: `get_npc()`가 **라이브 참조** 반환
> 결정에 따라 `snapshot()` 사용 시점이 달라짐:
> - 라이브 참조(GDD): 호출자가 필요 시 `record.snapshot()` 명시 호출
> - 스냅샷(ADR): `get_npc()` 내부에서 자동 snapshot()
> 이 스토리의 AC-NPC-EC-05는 snapshot() 독립성을 검증하므로 어느 결정에도 유효.

**Control Manifest Rules (Foundation layer)**:
- Required: `_quest_flags` 키는 항상 `String(key)` 캐스팅 후 저장
- Required: `set_quest_flag()` 값 타입 검증 — bool, int, String만 허용
- Forbidden: `duplicate()` (얕은 복사) 직접 사용 — `snapshot()` 경유만 허용

---

## Acceptance Criteria

*From GDD `design/gdd/NPC-상태-관리.md`:*

**쓰기 API:**
- [ ] 중복 슬롯 `set_party_slot(npc_b, 0)` — 슬롯 불변, `error_occurred` 1회, NPC-A slot 유지 (AC-NPC-CR-13)
- [ ] `update_dialogue_node(id, &"node_intro_01")` → `last_dialogue_node == &"node_intro_01"`, `npc_state_changed` 미발행 (AC-NPC-CR-20)
- [ ] 미등록 ID로 `update_dialogue_node()` → `error_occurred` 1회 (AC-NPC-CR-20b)

**quest_flags 키 타입:**
- [ ] `"rescued_prisoner"` (String) 키로 저장 후 `has("rescued_prisoner")` → `true` (AC-NPC-EC-02)
- [ ] `set_quest_flag(id, &"step", true)` (StringName 입력) 후 `quest_flags.has("step")` → `true` (AC-NPC-EC-02b)
- [ ] QUEST_ABANDONED 전환 후 기존 `_quest_flags` 보존 (AC-NPC-EC-03)
- [ ] `set_quest_flag(id, "bad_flag", Vector2(1,1))` → `error_occurred` 1회, `has("bad_flag")==false` (AC-NPC-EC-07)

**snapshot() 독립성:**
- [ ] `snapshot()`의 `_quest_flags` 수정이 원본에 영향 없음 (AC-NPC-EC-05)
- [ ] `snapshot()`의 `recruitment_tags.append()` 가 원본에 영향 없음 (AC-NPC-EC-08)
- [ ] `snapshot()`의 스칼라 필드 변경이 원본에 영향 없음 (AC-NPC-EC-09)

**데이터 무결성:**
- [ ] `relationship_state=99` 부패 레코드 → `_validate_records()` 후 MET(1), `error_occurred` 발행 (AC-NPC-EC-01)
- [ ] HOSTILE 상태에서 `set_state(id, MET)` 직접 호출 → 상태 유지, `error_occurred` 발행 (AC-NPC-EC-04) *(VS+ 이후 테스트)*

---

## Implementation Notes

*Derived from ADR-0001 Core Rule 6 (snapshot 패턴):*

```gdscript
# NPCRecord.snapshot() — GDD Core Rule 6
func snapshot() -> NPCRecord:
    var result: NPCRecord = duplicate_deep()
    result.recruitment_tags = recruitment_tags.duplicate()   # typed Array 명시적 복사
    result.bond_tags = bond_tags.duplicate()
    result._quest_flags = _quest_flags.duplicate(true)       # Dictionary 딥 복사
    return result

# NPCRegistry.set_quest_flag()
func set_quest_flag(npc_id: StringName, key: Variant, value: Variant) -> void:
    var record := _records.get(npc_id, null)
    if record == null:
        error_occurred.emit("NPC not found: " + str(npc_id)); return
    # 키 타입 강제 (StringName → String)
    var str_key: String = String(key)
    # 값 타입 검증
    if not (value is bool or value is int or value is String):
        error_occurred.emit("Invalid quest_flag value type: " + str(typeof(value))); return
    record._quest_flags[str_key] = value

# NPCRegistry._validate_records() — 세이브 파일 부패 복구
func _validate_records() -> void:
    for npc_id in _records:
        var record: NPCRecord = _records[npc_id]
        if record.relationship_state < 0 or record.relationship_state > 6:
            error_occurred.emit("Corrupted state for " + npc_id + ": " + str(record.relationship_state))
            record.relationship_state = RelationshipState.MET  # UNKNOWN이 아닌 MET로 폴백
```

reset_hostile() — VS+ 자리 예약 stub:
```gdscript
func reset_hostile(npc_id: StringName) -> void:
    push_warning("reset_hostile() is reserved for VS+ — not implemented in MVP")
    # VS+ 구현 시: MET 전환, _quest_flags 보존, reconciled_after_hostile=true 설정
```

---

## Out of Scope

- Story 001: NPCRecord 구조 및 읽기 인터페이스
- Story 002: set_state() FSM
- 세이브/로드 시스템 통합 — 별도 VS 에픽

---

## QA Test Cases

- **AC-NPC-CR-13**: set_party_slot() 중복 슬롯 거부
  - Given: NPC-A COMPANION, party_slot=0; NPC-B COMPANION
  - When: `set_party_slot(npc_b_id, 0)` 호출
  - Then: NPC-B slot 불변, error_occurred 1회, NPC-A slot=0 유지

- **AC-NPC-CR-20**: update_dialogue_node() 정상
  - Given: NPC last_dialogue_node=&"", npc_state_changed 수신자 연결
  - When: `update_dialogue_node(id, &"node_intro_01")`
  - Then: last_dialogue_node==&"node_intro_01", npc_state_changed 미발행

- **AC-NPC-CR-20b**: update_dialogue_node() 미등록 NPC
  - When: `update_dialogue_node(&"ghost_id", &"node")` 호출
  - Then: error_occurred 1회

- **AC-NPC-EC-02/02b**: quest_flags 키 타입 일관성
  - Given(02): `set_quest_flag(id, "rescued_prisoner", true)` 저장
  - Then: `get_quest_flags(id).has("rescued_prisoner")` → true
  - Given(02b): `set_quest_flag(id, &"step", true)` (StringName 입력)
  - Then: `get_quest_flags(id).has("step")` → true (String으로 캐스팅됨)

- **AC-NPC-EC-03**: QUEST_ABANDONED 전환 후 flags 보존
  - Given: QUEST_ACTIVE, `set_quest_flag(id, "npc_helped_me", true)` 설정
  - When: `set_state(id, QUEST_ABANDONED)`
  - Then: 상태=QUEST_ABANDONED, `get_quest_flags(id).has("npc_helped_me")` → true

- **AC-NPC-EC-05**: snapshot() _quest_flags 독립성
  - Given: 원본 레코드에 `set_quest_flag(id, "orig_key", true)` 설정 후 `snapshot()` 생성
  - When: 복사본의 `_quest_flags["test_copy"] = "value"` (GUT 내부 접근)
  - Then: 원본 `get_quest_flags().has("test_copy")` → false

- **AC-NPC-EC-07**: 유효하지 않은 값 타입 거부
  - When: `set_quest_flag(id, "bad", Vector2(1, 1))`
  - Then: error_occurred 1회, `get_quest_flags().has("bad")` → false

- **AC-NPC-EC-08**: snapshot() recruitment_tags 독립성
  - Given: 원본 `recruitment_tags = [&"healer"]`, `snapshot()` 생성
  - When: 복사본 `recruitment_tags.append(&"test_tag")`
  - Then: 원본 `recruitment_tags.has(&"test_tag")` → false

- **AC-NPC-EC-09**: snapshot() 스칼라 독립성
  - Given: active_quest_id=&"quest_a", snapshot() 생성
  - When: 복사본 active_quest_id를 &"quest_b"로 변경
  - Then: 원본 active_quest_id == &"quest_a"

- **AC-NPC-EC-01**: 세이브 파일 부패 복구
  - Given: relationship_state=99인 NPCRecord
  - When: `_validate_records()` 호출
  - Then: relationship_state==MET(1), error_occurred 1회
  - Edge cases: relationship_state=0(UNKNOWN) — 유효값이므로 보정 없음

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc/npc_registry_write_test.gd` — GUT 테스트, 위 12개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (npc-registry) DONE, Story 002 (npc-registry) DONE
- Unlocks: party-manager/001 (NPCRegistry 완성 후 PartyManager 구현 가능)

---

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 11/11 passing (AC-NPC-EC-04 DEFERRED — VS+ 이후 테스트로 스토리에 명시)
**Deviations**: ADVISORY — get_npc() 라이브 참조 반환 (story-001에서 승인된 deviation, snapshot() 독립성 이 스토리에서 검증 완료); ADVISORY — _validate_records() startup error_occurred 리스너 보장 없음 (문서화 완료)
**Test Evidence**: Logic — tests/unit/npc/npc_registry_write_test.gd (49 test functions, 11 AC 커버)
**Code Review**: Complete — CHANGES REQUIRED → APPROVED (set_party_slot non-COMPANION 가드 추가, reset_hostile _npc_id rename, _validate_records StringName 루프, 문서화 개선)
