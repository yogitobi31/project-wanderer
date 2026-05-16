# NPC 상태 관리 (NPC State Manager)

> **Status**: In Revision → Pending Re-review (2026-04-25)
> **Author**: Juwon + Claude Code agents
> **Last Updated**: 2026-04-19
> **Implements Pillar**: Pillar 1 (Earned Fellowship), Pillar 3 (Team Unlocks World)

## Overview

NPC 상태 관리는 유랑단의 모든 NPC(잠재 동료, 중립 NPC, 퀘스트 NPC)의 상태 데이터를 저장하고 제공하는 데이터 레이어다. 각 NPC의 현재 관계 상태(미만남 / 퀘스트 진행 중 / 합류 완료 / 적대 등), 퀘스트 진행 플래그, 세계 조건 기여값을 단일 진실 출처로 관리한다. 이 시스템 자체를 플레이어가 직접 느끼는 일은 없다 — 대화 시스템이 NPC를 다르게 반응시키고, 퀘스트 시스템이 진행도를 기억하며, 월드 조건 시스템이 팀 구성을 보고 문을 여는 것이 이 레이어의 존재를 증명한다. 세이브/로드 시스템이 게임을 저장할 때 이 데이터 전체를 직렬화하므로, 처음부터 직렬화 친화적 구조로 설계되어야 한다.

## Player Fantasy

플레이어는 이 시스템을 인식하지 않는다. 이 시스템이 제대로 작동할 때 플레이어가 느끼는 것은: 지난 세션에 퀘스트를 절반만 끝내고 껐는데, 오늘 다시 켜도 그 NPC가 "그래, 너 어제 절반까지 했지"라고 기억하는 것. 처음 만난 NPC에게는 처음 만나는 것처럼 반응하고, 퀘스트를 마친 NPC는 다르게 말하는 것. "이 세계가 나를 기억한다"는 감각 — 그것이 이 데이터 레이어의 존재 이유다.

이 시스템이 실패하면 플레이어가 느끼는 것: 퀘스트를 완료했는데 NPC가 아직 모르는 것처럼 반응한다. 합류한 동료가 월드 잠금 해제를 하지 못한다. "저장이 제대로 됐나?" 의심이 드는 순간 — Pillar 1 (Earned Fellowship)과 Pillar 3 (Team Unlocks World) 둘 다 무너진다.

## Detailed Rules

### NPCRecord 필드 정의

모든 `NPCRecord` Resource 인스턴스는 다음 필드를 가진다:

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `npc_id` | `StringName` | — | NPC 고유 식별자. 초기화 후 변경 금지 |
| `schema_version` | `int` | `1` | `@export`. NPCRecord 스키마 버전. 세이브/로드 시스템이 마이그레이션 게이트로 사용. 새 필드 추가 시 증가. |
| `relationship_state` | `int` (RelationshipState) | `UNKNOWN(0)` | 현재 관계 상태 |
| `_quest_flags` | `Dictionary` | `{}` | **`@export`** — ResourceSaver 직렬화를 위해 필수. 키: `String`, 값: `bool \| int \| String`만 허용. **외부 읽기**: `NPCRegistry.get_quest_flags(npc_id) → Dictionary`. **외부 쓰기**: `NPCRegistry.set_quest_flag()` 전용 (`@export`는 직렬화 목적이며, 직접 필드 쓰기는 코드 리뷰에서 거부됨) |
| `active_quest_id` | `StringName` | `&""` | 현재 진행 중인 퀘스트 ID. 없으면 빈 StringName |
| `last_dialogue_node` | `StringName` | `&""` | 마지막으로 재생된 대화 노드 ID. 없으면 빈 StringName. 타입은 대화 시스템 GDD 확정 시 재검토 |
| `party_slot` | `int` | `-1` | 파티 슬롯 번호. 비파티: -1, 파티: 0~2 (MVP 동료 상한 3명) |
| `recruitment_tags` | `Array[StringName]` | `[]` | 합류 즉시 활성화되는 세계 잠금 해제 태그. `@export`, 정의 시 고정 |
| `bond_tags` | `Array[StringName]` | `[]` | post-join `quest_flags` 마일스톤으로 활성화되는 성장 태그 (Vertical Slice 단계 구현) |

**파생 속성 (저장하지 않음):**

```gdscript
var is_in_party: bool:
    get: return relationship_state == RelationshipState.COMPANION
```

`is_in_party`는 `relationship_state`에서 파생된다. 절대 독립 필드로 저장하지 않는다 — 두 값이 탈동기화되면 동료 AI가 잘못된 파티 구성을 읽는다.

### Core Rules

1. **모든 NPC는 하나의 `NPCRecord` Resource 인스턴스를 가진다.** 동료, 퀘스트 NPC, 중립 NPC 구조 차이 없음. 차이는 `relationship_state` 값과 `recruitment_tags`로 표현한다.

2. **관계 상태(RelationshipState)는 7개다:**

| 값 | 상수명 | 의미 |
|----|--------|------|
| 0 | `UNKNOWN` | NPC가 존재하지만 플레이어가 접촉한 적 없음 |
| 1 | `MET` | 대화는 했지만 영입 퀘스트 조건 미충족 |
| 2 | `QUEST_ACTIVE` | 영입 퀘스트 수락 후 진행 중 |
| 3 | `COMPANION` | 파티에 합류한 상태 |
| 4 | `DEPARTED` | 서사적 이유로 파티를 떠난 상태 (VS+ 이후). **진입 전환만 가능 — 탈출 전환 없음.** DEPARTED는 어떤 상태로도 전환될 수 없다. `* → HOSTILE` 예외에서 명시적으로 제외된다. |
| 5 | `HOSTILE` | 전투 대상. `_quest_flags["hostile_cause"]`에 원인 기록. `set_state()` 직접 호출로는 이 상태에서 벗어날 수 없다 — 복구는 `reset_hostile()` API 전용. 퀘스트 시스템이 서사적 화해 완료 시 이 API를 호출하며, `_quest_flags` 전체가 보존된 상태로 `MET`로 전환하고 `_quest_flags["reconciled_after_hostile"] = true`를 설정한다 (MVP 미구현, 자리 예약). **MVP 콘텐츠 제약**: MVP 단계의 어떤 퀘스트 선택지도 이 상태로의 전환을 트리거하지 않는다 — HOSTILE과 `reset_hostile()`은 VS+ 이후 콘텐츠에서만 활성화된다. |
| 6 | `QUEST_ABANDONED` | 영입 퀘스트를 포기한 상태. 관계의 기억을 보존하되 퀘스트는 비활성. `QUEST_ACTIVE → QUEST_ABANDONED` 전환 시 `active_quest_id`를 `&""`로 초기화. 재수락 시 `QUEST_ABANDONED → QUEST_ACTIVE`로 전환하고 `active_quest_id` 재설정. **세이브 파일 호환성**: 값 6은 고정. 기존 값(0-5) 변경 금지. |

3. **`_quest_flags`의 키는 `String`(StringName 아님)을 사용한다.** GDScript 비타입 Dictionary에서 `StringName`과 `String` 키는 서로 다른 해시를 갖는다 — `"key"` 로 쓰고 `&"key"` 로 읽으면 `has()` 가 침묵하여 `false`를 반환한다. 모든 쓰기는 `String` 타입으로 명시적 캐스팅 후 저장한다. 값 타입은 `bool`, `int`, `String`만 허용한다 — `set_quest_flag()`가 쓰기 시 타입을 검증한다. **직렬화 라운드트립 주의**: `@export` 추가로 ResourceSaver를 통해 직렬화되지만, 세이브/로드 시스템은 로드 후 `_quest_flags`의 키 타입을 재검증해야 한다 — 일부 직렬화 경로가 `String`을 `StringName`으로 복원할 수 있다.

4. **`NPCRegistry`는 Autoload 싱글톤이다.** `NPCRegistry.get_npc(id)` 단일 경로로 5개 다운스트림 시스템이 접근한다. 코딩 표준의 "의존성 주입 over 싱글톤" 원칙의 예외 — 5개 시스템 동시 참조 현실 반영. 이 결정은 ADR로 문서화한다.

   **⚠️ Autoload 순서 요구사항:** `NPCRegistry`는 Project Settings Autoload 목록에서 이를 참조하는 모든 다른 Autoload(예: QuestManager, DialogueManager)보다 **먼저** 위치해야 한다. 순서가 잘못되면 다른 Autoload의 `_ready()`에서 `get_npc()`를 호출할 때, Autoload 노드 자체는 존재하지만 `_records` Dictionary가 아직 채워지지 않아 모든 ID 조회가 `null`을 반환하며 런타임 에러 없이 침묵하여 통과한다. **실제 실패 메커니즘은 null Autoload가 아닌 빈 레지스트리다** — Core Rule 13의 `is_initialized` 가드가 이를 방어한다.

5. **상태 변경 시 signal을 발생시킨다:** `npc_state_changed(npc_id: StringName, old_state: int, new_state: int)`. GDScript 파서는 `signal` 파라미터 타입에 `ClassName.EnumName` 중첩 형식(`NPCRecord.RelationshipState`)을 지원하지 않는다 — 파서 레벨 제한이므로 `int`를 사용한다. 이는 미검증 사항이 아닌 **언어 제한**이다. 이 `int`를 "수정"하려는 시도는 파싱 오류를 낸다. 대화/퀘스트/AI 시스템은 매 프레임 polling하지 않고 이 signal에 반응한다. `old_state`를 포함해야 다운스트림이 전환 애니메이션/연출을 구분할 수 있다.

6. **`NPCRecord`를 런타임 중 복사해야 할 경우 반드시 `snapshot()` 메서드를 사용한다.** `NPCRecord.snapshot() → NPCRecord`는 다음 순서로 완전한 독립 복사본을 만든다:
   1. `result = duplicate_deep()` — Resource 기본 복사
   2. `result.recruitment_tags = recruitment_tags.duplicate()` — typed Array 명시적 복사
   3. `result.bond_tags = bond_tags.duplicate()` — typed Array 명시적 복사
   4. `result._quest_flags = _quest_flags.duplicate(true)` — Dictionary 딥 복사 (**필수**: Dictionary의 중첩 값이 공유 참조가 되지 않도록)

   **절대 `record.duplicate()`(얕은 복사)나 `record.duplicate_deep()`을 직접 호출하지 않는다** — `snapshot()`을 통해서만 안전한 복사가 보장된다. 참고: `duplicate_deep()`이 `Array[StringName]`을 독립 복사하는지는 GDScript 언어 파서 수준에서 보장되지 않아 명시적 Array 복사를 유지한다. `_quest_flags`의 `String` 키 캐스팅과 이 복사 보장은 함께 동작한다.

7. **`get_npc()`가 반환한 레코드는 라이브 참조다.** 절대 필드를 직접 쓰지 않는다 — `set_state()`, `set_quest_flag()`, `update_dialogue_node()`, `set_party_slot()` API만 사용한다. 직접 필드 쓰기는 signal 미발생 + 유효성 검사 우회를 일으킨다. **`_quest_flags` 읽기 전용 접근**: `NPCRegistry.get_quest_flags(npc_id) → Dictionary`를 통해 조회한다 — `_quest_flags`는 내부 필드로 직접 접근하지 않는다. GDScript 언어 수준의 접근 제어는 없으나 이 규칙을 위반하면 코드 리뷰에서 거부된다.

8. **에러/경고 리포팅은 인젝터블 훅으로 제공한다.** `push_error()`/`push_warning()` 직접 호출 외에, GUT 단위 테스트에서 캡처 가능한 신호(예: `error_occurred(message: String)`)를 NPCRegistry에 추가한다. 이 신호 없이는 AC-NPC-CR-04, CR-05, EC-01이 검증 불가능하다.

9. **`_companions_cache`는 COMPANION 진입 시 party_slot 자동 할당 후 추가, 탈출 시 제거한다.** `set_state()` 내부에서 두 방향을 모두 처리한다:

   ```gdscript
   # COMPANION 진입 — 슬롯 자동 할당 후 캐시 추가
   if new_state == RelationshipState.COMPANION:
       # 현재 점유된 슬롯 목록 계산 (신규 record 제외)
       var used_slots: Array = _companions_cache.map(func(r): return r.party_slot)
       var assigned := false
       for slot in range(MAX_PARTY_SIZE):
           if slot not in used_slots:
               record.party_slot = slot
               assigned = true
               break
       if not assigned:
           error_occurred.emit("No available party slot — MAX_PARTY_SIZE reached")
           return  # 전환 거부
       _companions_cache.append(record)

   # COMPANION 탈출 — 캐시 제거 및 슬롯 초기화
   if old_state == RelationshipState.COMPANION and new_state != RelationshipState.COMPANION:
       _companions_cache.erase(record)
       record.party_slot = -1
   ```

   탈출 패턴은 `COMPANION → HOSTILE`, `COMPANION → DEPARTED` 등 모든 COMPANION 탈출 전환에 자동 적용된다. 전환별로 개별 처리하지 않는다 — 미래 상태 추가 시 누락 방지. **두 조건은 독립적으로 실행된다** — 동일 상태 no-op(`COMPANION → COMPANION`) 시에는 양쪽 모두 실행되지 않는다 (Core Rule 10의 동일 상태 조기 반환 후).

   **`COMPANION → DEPARTED` 추가 사이드 이펙트**: `active_quest_id`를 `&""`로 초기화한다 (파티 이탈 후 완료 불가 퀘스트 ID 댕글링 참조 방지).

10. **`UNKNOWN`은 오직 "플레이어가 한 번도 접촉하지 않은 NPC"를 의미한다.** 세이브 파일 부패 복구 경로에서 UNKNOWN으로 리셋하지 않는다 — 부패된 레코드는 마지막으로 알려진 유효 상태(`MET`)로 폴백한다. UNKNOWN은 "알 수 없음"이 아니라 "미접촉"이다.

11. **HOSTILE 복구는 `reset_hostile(npc_id: StringName)` API를 통해서만 처리한다.** 퀘스트 시스템이 서사적 화해 퀘스트 완료 시 이 API를 호출한다. `reset_hostile()`은:
    - `relationship_state`를 `MET`로 전환
    - `quest_flags` 전체를 보존 (역사 유지 — "이 세계가 나를 기억한다")
    - `quest_flags["reconciled_after_hostile"] = true` 설정 (화해 흔적)
    - `npc_state_changed` signal 발생 (`old_state = HOSTILE`, `new_state = MET`)
    - 절대 "새 NPC 인스턴스"를 생성하지 않는다 — 동일 `npc_id`와 전체 역사 유지 필수
    - 복구된 NPC의 `party_slot`은 `-1`로 유지된다 — `reset_hostile()` 이후 파티에 자동으로 재합류하지 않는다. 재합류는 별도 영입 퀘스트 흐름이 필요하다.
    - MVP 미구현 — 자리 예약. 퀘스트 시스템 GDD에서 호출 조건 정의.

12. **`MAX_PARTY_SIZE`는 명명된 상수로 관리된다.** 현재 값: `3` (MVP). `party_slot` 범위 (`0 ~ MAX_PARTY_SIZE - 1`)는 이 상수에서 파생된다. `set_party_slot()`은 슬롯 중복 할당을 검증하고, 이미 점유된 슬롯 번호가 요청되면 `error_occurred`를 발생시키고 거부한다. **슬롯은 비위치적(set membership)으로 동작하며, 이탈 시 컴팩션 없음** — 빈 슬롯은 다음 합류 동료가 채운다.

13. **`NPCRegistry`는 `is_initialized: bool`과 `registry_initialized` signal을 제공한다.** `_ready()` 완료 전에 `get_npc()`를 호출하면 `null`을 반환하고 `error_occurred("NPCRegistry not yet initialized")`를 발생시킨다. 씬의 `_ready()`에서 레지스트리를 직접 호출하는 시스템은 `registry_initialized` signal에 연결해 초기화 완료 후 처리해야 한다.

### Tags: Recruitment vs Bond

`recruitment_tags`와 `bond_tags`는 Pillar 1(Earned Fellowship)과 Pillar 3(Team Unlocks World)의 긴장을 해소한다:

| 태그 종류 | 활성화 시점 | 구현 단계 | 예시 |
|-----------|-----------|---------|------|
| `recruitment_tags` | 합류 즉시 | MVP | `"has_healer"`, `"has_lockpick"` — 해당 동료가 있으면 즉시 열리는 지역/이벤트 |
| `bond_tags` | post-join 퀘스트 완료 | Vertical Slice | `"trust_level_2"`, `"shared_secret"` — 함께한 이야기가 쌓인 후 열리는 콘텐츠 |

MVP에서는 `bond_tags`가 항상 빈 배열이다. `party_has_tag()`는 두 배열을 모두 검색한다 — MVP에서는 실질적으로 `recruitment_tags`만 결과에 기여한다.

### States and Transitions

| 현재 상태 | → 다음 상태 | 전환 조건 | 소유 시스템 | 사이드 이펙트 |
|-----------|------------|-----------|------------|-------------|
| `UNKNOWN` | `MET` | 플레이어가 NPC에게 처음 대화 시도 | 대화 시스템 | — |
| `MET` | `QUEST_ACTIVE` | 영입 퀘스트 수락 | 동료 영입 퀘스트 시스템 | — |
| `QUEST_ACTIVE` | `COMPANION` | 퀘스트 완료 조건 달성 + 합류 확정 | 동료 영입 퀘스트 시스템 | `active_quest_id := &""`, `party_slot` 자동 할당 (`set_state()` 내부 — Core Rule 9 패턴) |
| `QUEST_ACTIVE` | `QUEST_ABANDONED` | 플레이어가 퀘스트 포기 (비적대) | 동료 영입 퀘스트 시스템 | `active_quest_id := &""` |
| `QUEST_ABANDONED` | `QUEST_ACTIVE` | 플레이어가 퀘스트 재수락 | 동료 영입 퀘스트 시스템 | `active_quest_id` 재설정 |
| `COMPANION` | `DEPARTED` | 서사 이벤트 트리거 (VS+ 이후) | 동료 영입 퀘스트 시스템 | `party_slot := -1`, `active_quest_id := &""`, `_companions_cache`에서 제거 (Core Rule 9 패턴) |
| `MET` / `QUEST_ACTIVE` / `QUEST_ABANDONED` | `HOSTILE` | 특정 퀘스트 선택 결과 | 동료 영입 퀘스트 시스템 | **VS+ 이후** — MVP 퀘스트에서 이 전환을 트리거하지 않는다 |
| `COMPANION` | `HOSTILE` | 특정 퀘스트 선택 결과 | 동료 영입 퀘스트 시스템 | `party_slot := -1`, `active_quest_id := &""`, `_companions_cache`에서 제거 (Core Rule 9 패턴). **VS+ 이후** |
| `HOSTILE` | `MET` | 서사 화해 퀘스트 완료 (`reset_hostile()` 호출만 허용) | 퀘스트 시스템 | `_quest_flags["reconciled_after_hostile"] = true`, 기존 `_quest_flags` 전체 보존. **VS+ 이후** (MVP 미구현) |
| `DEPARTED` | — | **전환 없음** — DEPARTED는 완전 종료 상태. `* → HOSTILE` 예외에서 명시적으로 제외됨. | — | VS+ 이후 재-영입이 필요한 경우 별도 상태 또는 전환 추가 필요 |
| — | `UNKNOWN` | 전환 없음 — 최초 상태만 가능 | — | — |

**단방향 전환 원칙**: `COMPANION → UNKNOWN`처럼 역방향 전환은 허용하지 않는다. 예외 목록:
- `MET / QUEST_ACTIVE / QUEST_ABANDONED / COMPANION → HOSTILE` — **VS+ 이후**. MVP에서는 이 전환이 발생하지 않는다. **`UNKNOWN → HOSTILE`과 `DEPARTED → HOSTILE`은 명시적으로 차단된다** — 만난 적 없는 NPC나 이미 떠난 동료는 적대 상태가 될 수 없다.
- `COMPANION → DEPARTED` — 서사 이벤트로 허용 (VS+ 이후)
- `HOSTILE → MET` — `reset_hostile()` API 전용. `set_state()` 직접 호출 불가. **VS+ 이후** (MVP 미구현)
- `DEPARTED → *` — 정의된 탈출 전환 없음. DEPARTED는 완전 종료 상태.
- `QUEST_ABANDONED → QUEST_ACTIVE` — 재수락 허용 (유일한 역방향 예외)

**퀘스트 포기(비적대)**: `QUEST_ACTIVE → QUEST_ABANDONED` 전환으로 처리한다. 상태 자체가 포기를 명시하므로 플래그 중복 없이 다운스트림 시스템이 상태만으로 포기 여부를 판단할 수 있다. 재수락 시 `QUEST_ABANDONED → QUEST_ACTIVE`로 전환. "이미 시작한 관계"의 기억은 `_quest_flags`에 보존된다.

### Interactions with Other Systems

| 방향 | 시스템 | 읽는/쓰는 값 | 인터페이스 |
|------|--------|-------------|-----------|
| **→ (출력)** | 대화 시스템 | `relationship_state`, `last_dialogue_node` | `NPCRegistry.get_npc(id)` |
| **→ (출력)** | 퀘스트 상태 머신 | `relationship_state`, `quest_flags`, `active_quest_id` | `NPCRegistry.get_npc(id)` |
| **→ (출력)** | 동료 AI 시스템 | `is_in_party` (파생), `party_slot` | `NPCRegistry.get_companions()` |
| **→ (출력)** | 동료 영입 퀘스트 | `relationship_state`, `quest_flags` | `NPCRegistry.get_npc(id)` |
| **→ (출력)** | 월드 조건 시스템 | `recruitment_tags`, `bond_tags`, `relationship_state` | `NPCRegistry.get_companions()`, `party_has_tag()` |
| **← (입력)** | 대화 시스템 | `last_dialogue_node` 업데이트, `MET` 상태 전환 | `NPCRegistry.set_state()`, `NPCRegistry.update_dialogue_node()` |
| **← (입력)** | 동료 영입 퀘스트 시스템 | `relationship_state` 전환, `quest_flags` 업데이트, `COMPANION` 전환, `party_slot` 설정 | `NPCRegistry.set_state()`, `NPCRegistry.set_quest_flag()`, `NPCRegistry.set_party_slot()` |
| **← (입력)** | 세이브/로드 시스템 | 전체 `NPCRecord` 직렬화/역직렬화 | `NPCRegistry` 전체 Resource 저장/복원 |

## Formulas

이 시스템은 수치 계산 공식을 포함하지 않는다 — 데이터 저장 및 조회 레이어이기 때문이다. 대신 다운스트림 시스템이 사용할 쿼리 패턴을 명확히 정의한다.

**Query 1 — 단일 NPC 레코드 조회**

`record = NPCRegistry.get_npc(npc_id: StringName) → NPCRecord | null`

| Parameter | Type | Description |
|-----------|------|-------------|
| `npc_id` | StringName | NPC 고유 식별자 (예: `&"companion_jin"`) |
| 반환값 | NPCRecord \| null | 존재하면 레코드(라이브 참조), 없으면 null |

**Query 2 — 파티 내 동료 목록**

`companions = NPCRegistry.get_companions() → Array[NPCRecord]`

`relationship_state == COMPANION`인 모든 레코드를 반환. 캐싱: `_companions_cache: Array[NPCRecord]`를 내부적으로 유지하고 `set_state()`에서 COMPANION 전환 시만 갱신 — 매 호출마다 전체 순회를 반복하지 않는다.

**⚠️ 반환값은 `_companions_cache.duplicate()` (얕은 복사)다.** 직접 참조를 반환하지 않는다 — `npc_state_changed` 신호 핸들러가 `get_companions()` 결과를 순회하는 도중 다른 `set_state()` 호출이 발생하면 원본 배열이 변형된다(GDScript 신호는 동기 실행). 레코드 자체는 라이브 참조이므로 레코드 필드 수정은 여전히 NPCRegistry에 반영된다 — 배열 컨테이너만 복사된다.

**Query 3 — 태그 기반 파티 능력 확인**

`has_tag = NPCRegistry.party_has_tag(tag: StringName) → bool`

`get_companions()`의 결과(COMPANION 상태 전용)에서 각 동료의 `recruitment_tags`와 `bond_tags`를 순회해 `tag`가 존재하는 동료가 있으면 `true`. **DEPARTED 상태 동료는 검색 대상에서 제외된다** — 태그는 능동적 파티 멤버십의 혜택이며, 이탈 시 기여가 중단된다 (2026-04-24 결정). 월드 조건 시스템의 "이 문을 열 수 있는가?" 체크에 사용. MVP에서는 `bond_tags`가 항상 비어 있어 실질적으로 `recruitment_tags`만 검색된다.

**Output Range**: 쿼리 결과는 0~N개의 레코드 (N = 전체 NPC 수). MVP 기준 최대 30개. `get_companions()`는 0~3개 (MVP 동료 3명 상한).

## Edge Cases

**상태 전환 케이스:**

- **If `get_npc(id)`가 null을 반환하는 경우** (등록되지 않은 `npc_id` 조회): NPCRegistry는 null을 반환하고 `error_occurred` 신호를 발생시킨다. 잘못된 id로 상태를 설정하려는 시도도 동일하게 무시. 등록되지 않은 NPC 접근은 항상 설계 오류다.

- **If `COMPANION → UNKNOWN`처럼 역방향 전환이 시도되는 경우**: `set_state()`는 허용되지 않는 전환을 거부하고 `error_occurred`를 발생시킨다. 단, `* → HOSTILE`과 `COMPANION → DEPARTED`는 예외로 허용한다.

- **If `set_state()`로 HOSTILE에서 직접 전환이 시도되는 경우**: `set_state()`는 이 전환을 거부하고 `error_occurred`를 발생시킨다. HOSTILE에서의 복구는 반드시 `reset_hostile()` API를 통해서만 가능하다 — `quest_flags` 전체를 보존하며 `MET`로 전환한다. 절대 "새 NPC 인스턴스"를 생성하지 않는다. 동일한 `npc_id`와 전체 역사가 유지된다 — "이 세계가 나를 기억한다"의 구현이다.

- **If `COMPANION → HOSTILE`로 전환이 시도되는 경우**: 허용한다 (`* → HOSTILE` 예외). `party_slot`을 -1로 초기화하고 `_companions_cache`에서 제거한다. `old_state = COMPANION`, `new_state = HOSTILE`로 signal을 발생시킨다.

- **If 동일 NPC에 `set_state()`가 같은 프레임에 두 번 호출되는 경우**: GDScript 싱글스레드이므로 순차 실행. 두 번째 호출이 최종값. signal이 두 번 발생해 UI가 중간 상태를 1프레임 노출할 수 있다. MVP에서는 퀘스트 완료와 합류 확정을 하나의 코드 경로로 통합할 것을 동료 영입 퀘스트 GDD에 권장한다.

- **If `QUEST_ACTIVE` 상태에서 플레이어가 퀘스트를 포기한 경우** (비적대): `set_state(npc_id, QUEST_ABANDONED)`를 호출한다. `active_quest_id`는 `&""`로 초기화되고 상태는 `QUEST_ABANDONED(6)`으로 전환된다. 퀘스트 시스템은 이 상태를 확인해 재수락(`QUEST_ABANDONED → QUEST_ACTIVE`) 흐름을 제공한다. `_quest_flags`에 포기 이력을 기록하고 싶다면 `set_quest_flag(npc_id, "quest_abandoned_count", n)`을 별도로 호출한다 (선택 사항).

**데이터 무결성 케이스:**

- **If `quest_flags`에 허용되지 않는 값 타입(Variant)이 쓰이는 경우**: `set_quest_flag()`는 값 타입을 검증하고 `bool`, `int`, `String` 외의 타입이면 `error_occurred`를 발생시키고 저장하지 않는다.

- **If `quest_flags`에 String이 아닌 키가 쓰이는 경우** (예: StringName으로 실수 입력): GDScript 비타입 Dictionary에서 StringName과 String 키는 다른 해시를 갖는다 — `has()` 조회가 침묵하여 `false`를 반환한다. `set_quest_flag()`는 키를 항상 `String(key)`로 캐스팅해 저장한다.

- **If `recruitment_tags`에 중복 태그가 정의되는 경우**: `party_has_tag()`는 중복 여부와 무관하게 동작하지만, 중복은 의도치 않은 상태다. NPCRecord 초기화 시 태그 배열은 중복 없이 구성한다. `recruitment_tags`는 런타임 중 변경하지 않는다.

**세이브/로드 케이스:**

- **If 세이브 파일이 손상되어 `relationship_state`가 유효 범위(0~5) 밖의 값을 갖는 경우**: 로드 후 `_validate_records()`에서 검증. 범위 이탈 시 `UNKNOWN(0)`이 아닌 **`MET(1)`로 폴백**한다 — UNKNOWN은 "미접촉"의 의미만 가지며, 손상된 레코드의 복구값으로 사용하지 않는다. 어느 NPC 레코드가, 어떤 이전 값에서 `MET`로 복원됐는지 기록(`error_occurred` 발생 + 로그). 세이브/로드 시스템 GDD에서 플레이어 알림 처리를 정의한다.

- **If 게임 업데이트로 새 상태가 추가될 때**: `RelationshipState` 값(0~5)은 세이브 파일 하위 호환성을 위해 한 번 정의 후 기존 값 변경 금지. 값 추가는 가능, 기존 값 재정의 불가.

**Autoload 초기화 케이스:**

- **If NPCRegistry가 다른 Autoload의 `_ready()`에서 호출되는 경우**: Project Settings Autoload 순서에 의존한다. `NPCRegistry`는 목록에서 가장 먼저 위치해야 한다. 순서가 잘못되면 `get_npc()`가 빈 Dictionary를 조회하고 null을 반환 — 호출 시스템이 null 체크를 하므로 런타임 에러 없이 침묵 통과한다. 이는 초기화 순서 버그다.

## Dependencies

**이 시스템이 의존하는 것 (Upstream):**

없음. NPC 상태 관리는 Foundation 레이어다. 초기 NPC 데이터(어떤 NPC가 존재하는지)는 에디터 시간 정의 파일(`.tres`)에서 로드되며, 런타임 시스템 의존성이 아니다.

**이 시스템에 의존하는 것 (Downstream):**

| 시스템 | 의존 유형 | 읽는 값 | 의존 강도 |
|--------|-----------|---------|---------|
| 대화 시스템 | Hard | `relationship_state`, `last_dialogue_node` | 없으면 NPC가 항상 처음 만나는 것처럼 반응 |
| 퀘스트 상태 머신 | Hard | `relationship_state`, `quest_flags`, `active_quest_id` | 없으면 퀘스트 진행 상태 기억 불가 |
| 동료 AI 시스템 | Hard | `is_in_party`(파생), `party_slot` | 없으면 파티 구성 파악 불가 |
| 동료 영입 퀘스트 | Hard | `relationship_state`, `quest_flags` | 없으면 영입 진행 상태 기억 불가 |
| 월드 조건 시스템 | Hard | `recruitment_tags`, `bond_tags`, `relationship_state` | 없으면 팀 구성 기반 월드 잠금 해제 불가 — Pillar 3 실패 |
| 세이브/로드 시스템 | Hard | `NPCRegistry` 전체 직렬화 | 없으면 세션 간 NPC 상태 유지 불가 |

**전이적 의존성 (검증 필요):**

세이브/로드 시스템 GDD 완성 시 — `NPCRecord` 직렬화 포맷(`.tres` vs JSON vs 바이너리)이 이 시스템의 구조 결정과 일치하는지 확인. `last_dialogue_node: StringName` 타입이 직렬화 포맷과 호환되는지 포함.

**⚠️ 대화 시스템 GDD 선행 조건 (Player Fantasy 이행 필수):** `"이 세계가 나를 기억한다"`는 약속은 `_quest_flags`의 값이 대화 분기에 반영될 때만 완성된다. 아래는 대화 시스템 GDD가 **반드시 정의해야 하는** 인터페이스 계약 스텁이다 — 이 계약 없이는 이 데이터 레이어가 플레이어 경험에 기여하지 못한다:

```
# [대화 시스템 GDD가 정의해야 할 인터페이스 계약 — 스텁]
# 대화 노드 평가 시, 대화 시스템은 다음 정보에 접근한다:
#   1. NPCRegistry.get_npc(npc_id).relationship_state  → 분기 조건
#   2. NPCRegistry.get_quest_flags(npc_id)             → 플래그 기반 분기 조건
#
# 예시 사용:
#   if get_quest_flags(npc_id).get("quest_abandoned", false):
#       play_dialogue_node("abandoned_reaction")
#   elif get_quest_flags(npc_id).get("reconciled_after_hostile", false):
#       play_dialogue_node("reconciled_reaction")
#
# 이 호출 경로가 대화 시스템 GDD에 명시되기 전까지,
# _quest_flags에 저장된 모든 플레이어 기억은 플레이어에게 전달되지 않는다.
```

대화 시스템 GDD는 이 스텁을 구체적 구현으로 대체해야 한다. **이 계약이 확정되기 전까지 NPC 상태 관리 시스템은 APPROVED를 받을 수 없다.**

## Tuning Knobs

| 튜닝 놉 | 현재 값 | 안전 범위 | 너무 높으면 | 너무 낮으면 | 상호작용 |
|---------|---------|---------|-----------|-----------|---------|
| `RelationshipState` 상태 수 | 7 | 6~9 | 전환 로직 복잡도 증가, 다운스트림 시스템 수정 필요 | 대화 시스템이 상태 구분 불가 | 각 상태를 소비하는 시스템과 동기화 필요 |
| `quest_flags` 최대 플래그 수 (NPC당) | 미정 | 1~20 | 설계 복잡도 증가 | 퀘스트 분기 표현 불가 | 퀘스트 상태 머신 GDD의 분기 복잡도와 직결 |
| `recruitment_tags` 최대 태그 수 (NPC당) | 미정 | 1~5 | 월드 조건 쿼리 복잡도 증가 | MVP 팀 잠금 해제 다양성 제한 | 월드 조건 시스템 GDD의 조건 수와 직결 |
| `bond_tags` 최대 태그 수 (NPC당) | 미정 (VS 단계) | 1~5 | 관계 성장 경로 복잡도 증가 | Pillar 2 성장 감각 약화 | 동료 성장 시스템 GDD와 직결 |
| `MAX_PARTY_SIZE` 상수 | `3` (MVP) | 2~6 | 동료 AI/UI 시스템 부담 증가 | 파티 전투 규모 감소 | `party_slot` 범위 자동 파생 (`0 ~ MAX_PARTY_SIZE - 1`) |
| `party_slot` 범위 | -1 ~ `MAX_PARTY_SIZE - 1` | `MAX_PARTY_SIZE`와 동기화 | — | — | `MAX_PARTY_SIZE` 상수만 수정하면 자동 반영 |
| MVP 총 NPC 수 | ~30 (추정) | 10~100 | Dictionary 성능 문제 없음 (Godot 기준) | 세계 밀도 부족 | 퀘스트/대화 콘텐츠 양과 직결 |

**조정 불가 항목 (코드 상수):**

- `RelationshipState` 값(0~6) — 세이브 파일 하위 호환성. 기존 값 변경 금지, 추가만 가능. `schema_version` 필드가 마이그레이션 게이트 역할.
- `_quest_flags` 키 타입 (`String`) — 직렬화/런타임 해시 안전성.
- `MAX_PARTY_SIZE` 값 — MVP 동료 수(3)와 연동. 변경 시 ADR 필요. `party_slot` 범위, 동료 AI, UI 시스템 모두 이 상수에 의존.

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### Core Rule 조건

**AC-NPC-CR-01** (공용 NPCRecord 구조)
- **GIVEN** 동료 NPC, 퀘스트 NPC, 중립 NPC가 NPCRegistry에 등록되어 있고 (각각 다른 `relationship_state`로 구성된 픽스처)
- **WHEN** 각 레코드에 대해 `record is NPCRecord` 타입 체크를 수행하면
- **THEN** 세 레코드 모두 `true`를 반환해야 한다

**AC-NPC-CR-02** (RelationshipState 7개 상수 — 세이브 파일 하위 호환 회귀 방지)
- **GIVEN** `NPCRecord.RelationshipState` 열거형이 정의되어 있고
- **WHEN** 각 상수 값을 정수로 읽으면
- **THEN** 다음 7개 assertion이 모두 통과해야 한다:
  - `assert_eq(NPCRecord.RelationshipState.UNKNOWN, 0)`
  - `assert_eq(NPCRecord.RelationshipState.MET, 1)`
  - `assert_eq(NPCRecord.RelationshipState.QUEST_ACTIVE, 2)`
  - `assert_eq(NPCRecord.RelationshipState.COMPANION, 3)`
  - `assert_eq(NPCRecord.RelationshipState.DEPARTED, 4)`
  - `assert_eq(NPCRecord.RelationshipState.HOSTILE, 5)`
  - `assert_eq(NPCRecord.RelationshipState.QUEST_ABANDONED, 6)`
- **왜 이 테스트가 필요한가**: 이 정수값은 세이브 파일에 직렬화된다. 열거형 재정렬 시 기존 세이브가 무음으로 손상된다.

**AC-NPC-CR-03** (상태 변경 시 signal 발생 및 payload 검증)
- **GIVEN** NPCRegistry에 `npc_state_changed` signal 수신자가 연결되고 수신 횟수와 인자 캡처 카운터가 초기화되어 있으며
- **WHEN** `set_state(id, COMPANION)`을 호출하면
- **THEN** signal이 정확히 1회 발생하고, `npc_id` 인자가 대상 NPC ID와 일치하며, `new_state`가 `COMPANION(3)`이고, `old_state`가 직전 상태여야 한다

**AC-NPC-CR-03b** (signal payload — 복수 전환 유형)
- **GIVEN** UNKNOWN 상태 NPC에 signal 수신자가 연결되어 있을 때
- **WHEN** `set_state(id, MET)` → `set_state(id, QUEST_ACTIVE)` 순서로 호출하면
- **THEN** 첫 번째 signal의 `old_state=UNKNOWN`, `new_state=MET`, 두 번째 signal의 `old_state=MET`, `new_state=QUEST_ACTIVE`여야 한다

**AC-NPC-CR-04** (미등록 NPC 조회)
- **GIVEN** NPCRegistry에 등록되지 않은 ID가 있을 때
- **WHEN** `get_npc("invalid_id")`를 호출하면
- **THEN** 반환값이 `null`이어야 하고, `error_occurred` 신호가 1회 발생해야 한다

**AC-NPC-CR-05** (역방향 전환 거부)
- **GIVEN** NPC가 `COMPANION(3)` 상태에 있을 때
- **WHEN** `set_state(id, UNKNOWN(0))`을 호출하면
- **THEN** 상태가 `COMPANION(3)`을 유지해야 하고, `error_occurred` 신호가 발생해야 한다

**AC-NPC-CR-05b** (인접 역방향 전환 거부)
- **GIVEN** NPC가 `MET(1)` 상태에 있고 `error_occurred` 수신자가 연결되어 있을 때
- **WHEN** `set_state(id, UNKNOWN(0))`을 호출하면
- **THEN** 상태가 `MET(1)`을 유지해야 하고, `error_occurred` 신호가 1회 발생해야 한다

**AC-NPC-CR-06** (HOSTILE 허용 예외 — MET에서) **(VS+ 이후 테스트 범위)**
- **GIVEN** NPC가 `MET(1)` 상태에 있을 때
- **WHEN** `set_state(id, HOSTILE(5))`를 호출하면
- **THEN** 상태가 `HOSTILE(5)`로 전환되어야 하고, `npc_state_changed` signal이 1회 발생해야 한다

**AC-NPC-CR-06b** (HOSTILE 허용 예외 — COMPANION에서) **(VS+ 이후 테스트 범위)**
- **GIVEN** NPC가 `COMPANION(3)` 상태이고 `party_slot = 1`일 때
- **WHEN** `set_state(id, HOSTILE(5))`를 호출하면
- **THEN** 상태가 `HOSTILE(5)`로 전환되고, `party_slot`이 `-1`로 초기화되며, `get_companions()`에서 해당 NPC가 제외되어야 한다

**AC-NPC-CR-07** (파티 필터 — 크기 및 내용)
- **GIVEN** NPCRegistry에 3개 NPC가 있고 1개만 `COMPANION` 상태일 때
- **WHEN** `get_companions()`를 호출하면
- **THEN** 반환 배열의 크기가 정확히 `1`이고, 해당 레코드의 `relationship_state == COMPANION`이어야 한다

**AC-NPC-CR-08** (recruitment_tags 쿼리)
- **GIVEN** `COMPANION` 상태 동료의 `recruitment_tags`에 `&"healer"`가 포함되어 있을 때
- **WHEN** `party_has_tag(&"healer")`를 호출하면
- **THEN** `true`를 반환해야 한다

**AC-NPC-CR-08c** (bond_tags 쿼리 — Pillar 3 VS+ 경로)
- **GIVEN** `COMPANION` 상태 동료의 `recruitment_tags`에는 `&"secret_path"`가 없고, `bond_tags`에만 `&"secret_path"`가 포함되어 있을 때
- **WHEN** `party_has_tag(&"secret_path")`를 호출하면
- **THEN** `true`를 반환해야 한다 (`party_has_tag()`가 두 배열 모두 검색함을 검증 — bond_tags를 무시하는 구현은 이 테스트에서 실패)

**AC-NPC-CR-08b** (party_has_tag 거짓 케이스 — 비파티 오염 차단)
- **GIVEN** 파티에 `COMPANION` 상태 동료가 있고, 해당 동료의 `recruitment_tags`와 `bond_tags` 모두 `"lockpick"`을 포함하지 않으며, `QUEST_ACTIVE` 상태 NPC 하나가 `recruitment_tags`에 `"lockpick"`을 가지고 있을 때
- **WHEN** `party_has_tag(&"lockpick")`를 호출하면
- **THEN** `false`를 반환해야 한다. COMPANION이 아닌 NPC의 태그는 결과에 영향 없음.

**AC-NPC-CR-09** (COMPANION 전환 시 active_quest_id 초기화)
- **GIVEN** NPC가 `QUEST_ACTIVE` 상태이고 `active_quest_id = &"quest_jin_01"`일 때
- **WHEN** `set_state(id, COMPANION)`을 호출하면
- **THEN** `active_quest_id`가 `&""`(빈 StringName)으로 초기화되어야 한다

**AC-NPC-CR-10** (no-op set_state — 동일 상태 전환 시 signal 미발생)
- **GIVEN** NPC가 `COMPANION(3)` 상태에 있고 signal 수신자가 연결되어 있을 때
- **WHEN** `set_state(id, COMPANION(3))`을 호출하면 (동일 상태)
- **THEN** 상태가 `COMPANION(3)`을 유지하고, `npc_state_changed` signal이 발생하지 않아야 한다

**AC-NPC-CR-11** (COMPANION→DEPARTED 전환)
- **GIVEN** NPC가 `COMPANION(3)` 상태이고 `party_slot = 0`일 때
- **WHEN** `set_state(id, DEPARTED(4))`를 호출하면
- **THEN** 상태가 `DEPARTED(4)`로 전환되고, `party_slot`이 `-1`로 초기화되며, `get_companions()`에서 해당 NPC가 제외되고, `npc_state_changed` signal이 `old_state=COMPANION(3)`, `new_state=DEPARTED(4)`로 1회 발생해야 한다

**AC-NPC-CR-12** (동일 프레임 이중 set_state — 두 번째 값 최종, signal 2회)
- **GIVEN** NPC가 `MET(1)` 상태일 때
- **WHEN** `set_state(id, QUEST_ACTIVE(2))`를 호출한 직후 같은 코드 경로에서 `set_state(id, COMPANION(3))`을 호출하면
- **THEN** 최종 상태가 `COMPANION(3)`이어야 하고, `npc_state_changed` signal이 정확히 2회 발생해야 한다 (첫 번째: `old=MET, new=QUEST_ACTIVE`, 두 번째: `old=QUEST_ACTIVE, new=COMPANION`)

---

### Edge Case 조건

**AC-NPC-EC-01** (상태 범위 이탈 복구)
- **GIVEN** NPCRecord의 `relationship_state`가 유효 범위(0~5) 밖의 값(예: `99`)으로 저장된 상태에서
- **WHEN** `NPCRegistry._validate_records()`를 호출하면
- **THEN** 해당 레코드의 `relationship_state`가 **`MET(1)`** 으로 초기화되어야 하고, `error_occurred` 신호가 발생해야 한다 (Core Rule 10: UNKNOWN은 "미접촉" 의미이므로 복구값으로 사용하지 않는다)

**AC-NPC-EC-02** (quest_flags 키 타입 일관성)
- **GIVEN** `quest_flags`에 키 `"rescued_prisoner"`(String)로 값을 저장하고
- **WHEN** 동일 키로 `quest_flags.has("rescued_prisoner")`를 호출하면
- **THEN** `true`를 반환해야 한다

**AC-NPC-EC-02b** (quest_flags StringName 키 실수 방지)
- **GIVEN** `set_quest_flag(id, &"step", true)`처럼 StringName 키로 호출할 때
- **WHEN** 이후 `quest_flags.has("step")`으로 조회하면
- **THEN** `true`를 반환해야 한다 (`set_quest_flag()`가 내부적으로 String으로 캐스팅하므로)

**AC-NPC-EC-03** (QUEST_ABANDONED 전환 후 _quest_flags 보존)
- **GIVEN** NPC가 `QUEST_ACTIVE` 상태이고 `set_quest_flag(id, "npc_helped_me", true)`가 설정된 상태에서
- **WHEN** `set_state(id, QUEST_ABANDONED)`를 호출하면
- **THEN** 상태가 `QUEST_ABANDONED`이어야 하고, `get_quest_flags(id).has("npc_helped_me")`가 `true`를 반환해야 한다 (포기 전환이 기존 _quest_flags를 보존함을 검증)

**AC-NPC-EC-04** (HOSTILE 터미널 — 탈출 시도 차단) **(VS+ 이후 테스트 범위)**
- **GIVEN** NPC가 `HOSTILE(5)` 상태일 때
- **WHEN** `set_state(id, MET(1))`을 호출하면
- **THEN** 상태가 `HOSTILE(5)`를 유지하고, `error_occurred` 신호가 발생해야 한다

**AC-NPC-EC-05** (snapshot() _quest_flags 독립성)
- **GIVEN** NPCRegistry에서 `get_npc(id)`로 레코드를 가져오고, `set_quest_flag(id, "orig_key", true)`로 플래그를 설정한 후 `record.snapshot()`으로 복사본을 만들었을 때
- **WHEN** 복사본의 내부 `_quest_flags["test_copy"] = "copy_value"`를 직접 쓰면 (GUT 테스트 내부 접근)
- **THEN** 원본 레코드의 `get_quest_flags().has("test_copy")`가 `false`를 반환해야 한다 (독립 복사 확인 — snapshot()이 _quest_flags를 독립 복사함을 검증)

**AC-NPC-EC-06** (빈 레지스트리 안전 기본값)
- **GIVEN** NPCRegistry에 등록된 NPC가 없을 때
- **WHEN** `get_companions()`와 `party_has_tag("any")`를 호출하면
- **THEN** `get_companions()`는 빈 배열 `[]`을, `party_has_tag()`는 `false`를 반환해야 한다

**AC-NPC-EC-07** (quest_flags 유효하지 않은 값 타입 거부)
- **GIVEN** 등록된 NPC가 있을 때
- **WHEN** `set_quest_flag(id, "bad_flag", Vector2(1, 1))`을 호출하면
- **THEN** `error_occurred` signal이 1회 발생해야 하고, `quest_flags.has("bad_flag")`가 `false`를 반환해야 한다

**AC-NPC-EC-08** (recruitment_tags 스냅샷 독립성)
- **GIVEN** NPCRegistry에서 `get_npc(id)`로 레코드를 가져와 `snapshot()`으로 복사본을 만들었을 때
- **WHEN** 복사본의 `recruitment_tags.append(&"test_tag")`로 직접 추가하면
- **THEN** 원본 레코드의 `recruitment_tags.has(&"test_tag")`가 `false`를 반환해야 한다 (배열 독립 복사 확인)

---

### 추가 조건 (이전 리뷰에서 누락)

**AC-NPC-CR-13** (set_party_slot() 중복 슬롯 거부)
- **GIVEN** NPC-A가 `COMPANION` 상태이고 `party_slot = 0`이며, NPC-B도 `COMPANION` 상태일 때
- **WHEN** `set_party_slot(npc_b_id, 0)`을 호출하면 (이미 점유된 슬롯)
- **THEN** NPC-B의 `party_slot`이 변경되지 않아야 하고, `error_occurred` 신호가 1회 발생해야 하며, NPC-A의 `party_slot`이 `0`을 유지해야 한다

**AC-NPC-CR-14** (is_initialized 가드)
- **GIVEN** `NPCRegistry._ready()`가 완료되기 전 (GUT 테스트 하네스로 초기화 지연 시뮬레이션)
- **WHEN** `get_npc(any_valid_id)`를 호출하면
- **THEN** 반환값이 `null`이어야 하고, `error_occurred("NPCRegistry not yet initialized")` 신호가 1회 발생해야 한다

**AC-NPC-CR-14** (is_initialized 가드 — GUT 테스트 방법 정의)
- **GIVEN** GUT 테스트에서 `NPCRegistry` 인스턴스를 `add_child_autofree()`로 추가하기 **전에** `is_initialized` 속성을 직접 읽으면 (`_ready()` 미실행 상태 시뮬레이션)
- **WHEN** `registry.is_initialized`를 확인하면
- **THEN** `false`여야 한다
- **구현 노트**: GUT에서 `_ready()` 미실행 상태는 `add_child()` 호출 전에 수동으로 인스턴스화(`NPCRegistry.new()`)하여 테스트. 실제 `get_npc()` 가드 테스트는 이 방법으로 수행.

**AC-NPC-CR-15** (registry_initialized 신호)
- **GIVEN** GUT 테스트에서 `NPCRegistry`를 `add_child_autofree()`로 장면 트리에 추가하고, **추가 직후 `await get_tree().process_frame`으로 한 프레임 대기**하여 `_ready()` 완료를 보장한 상태에서 (`registry_initialized` 수신자를 추가 **전에** 연결해야 하므로 `call_deferred`로 연결하거나 신호 발생 후 `is_initialized` 속성으로 완료 확인)
- **WHEN** `registry.is_initialized`를 확인하면
- **THEN** `true`여야 한다
- **구현 노트**: 신호 자체가 발생 후에 연결하면 수신 불가이므로, `registry_initialized` 신호 연결 여부 검증 대신 `is_initialized: bool` 속성으로 완료 상태를 검증하는 것이 권장 패턴.

**AC-NPC-RH-01** (reset_hostile() 4단계 계약) **(VS+ 이후 — 현재 자리 예약)**
- **GIVEN** NPC가 `HOSTILE(5)` 상태이고 `_quest_flags`에 기존 플래그 `{"reason": "betrayal"}`가 있으며, `npc_state_changed` 수신자가 연결된 상태에서
- **WHEN** `reset_hostile(npc_id)`를 호출하면
- **THEN** (1) `relationship_state`가 `MET(1)`이어야 하고, (2) 기존 `_quest_flags["reason"]`이 `"betrayal"`로 보존되어야 하며, (3) `get_quest_flags().has("reconciled_after_hostile")`가 `true`여야 하고, (4) `npc_state_changed` 신호가 `old_state=HOSTILE(5)`, `new_state=MET(1)`으로 정확히 1회 발생해야 한다

**AC-NPC-CR-16** (QUEST_ACTIVE → QUEST_ABANDONED 전환)
- **GIVEN** NPC가 `QUEST_ACTIVE(2)` 상태이고 `active_quest_id = &"quest_jin_01"`일 때
- **WHEN** `set_state(id, QUEST_ABANDONED(6))`을 호출하면
- **THEN** 상태가 `QUEST_ABANDONED(6)`이어야 하고, `active_quest_id`가 `&""`이어야 하며, `npc_state_changed` 신호가 `old_state=QUEST_ACTIVE(2)`, `new_state=QUEST_ABANDONED(6)`으로 1회 발생해야 한다

**AC-NPC-CR-17** (QUEST_ABANDONED → QUEST_ACTIVE 재수락)
- **GIVEN** NPC가 `QUEST_ABANDONED(6)` 상태일 때
- **WHEN** `set_state(id, QUEST_ACTIVE(2))`를 호출하면
- **THEN** 상태가 `QUEST_ACTIVE(2)`로 전환되어야 하고, `npc_state_changed` 신호가 발생해야 한다

**AC-NPC-CR-18** (DEPARTED → HOSTILE 차단)
- **GIVEN** NPC가 `DEPARTED(4)` 상태일 때
- **WHEN** `set_state(id, HOSTILE(5))`를 호출하면
- **THEN** 상태가 `DEPARTED(4)`를 유지해야 하고, `error_occurred` 신호가 1회 발생해야 한다

**AC-NPC-CR-19** (set_state() 범위 이탈 정수 직접 입력)
- **GIVEN** 등록된 NPC가 있을 때
- **WHEN** `set_state(id, 99)` 또는 `set_state(id, -1)`을 호출하면
- **THEN** 상태가 변경되지 않아야 하고, `error_occurred` 신호가 1회 발생해야 한다
- **노트**: EC-01(세이브 파일 부패 복구)과 다른 경로 — 이것은 런타임 코드 호출 경로.

**AC-NPC-CR-20** (update_dialogue_node() 동작)
- **GIVEN** 등록된 NPC의 `last_dialogue_node`가 `&""`일 때
- **WHEN** `update_dialogue_node(id, &"node_intro_01")`을 호출하면
- **THEN** `get_npc(id).last_dialogue_node`가 `&"node_intro_01"`이어야 하고, `npc_state_changed` 신호는 발생하지 않아야 한다 (상태 변경이 아님)

**AC-NPC-CR-20b** (update_dialogue_node() 미등록 NPC)
- **GIVEN** 등록되지 않은 NPC ID로
- **WHEN** `update_dialogue_node("invalid_id", &"some_node")`를 호출하면
- **THEN** `error_occurred` 신호가 1회 발생해야 한다

**AC-NPC-EC-09** (snapshot() 스칼라 필드 독립성)
- **GIVEN** NPC의 `active_quest_id = &"quest_a"`, `last_dialogue_node = &"node_b"`로 설정된 상태에서 `snapshot()`으로 복사본을 만들었을 때
- **WHEN** 복사본의 `active_quest_id`와 `last_dialogue_node`를 변경하면
- **THEN** 원본 레코드의 값이 변경되지 않아야 한다 (StringName은 불변값 타입이므로 실질적으로 항상 독립이지만, 복사 계약의 완전성 검증)

**AC-NPC-CI-01** (Autoload 순서 — CI 수동/스크립트 검증)
- **GIVEN** `project.godot` 파일의 Autoload 항목을 검사할 때
- **WHEN** 순서를 읽으면
- **THEN** `NPCRegistry`가 `QuestManager`, `DialogueManager` 보다 낮은 인덱스(먼저)에 위치해야 한다
- **(CI 스크립트 또는 수동 체크리스트 항목 — GUT 자동화 범위 외)**

## Open Questions

| 질문 | 현재 가정 | 결정 시점 | 담당 |
|------|-----------|---------|------|
| `bond_tags` 활성화 마일스톤 정의 | post-join quest_flags 기반 | 동료 성장 시스템 GDD 작성 시 | 동료 성장 시스템 GDD |
| `quest_flags` 최대 플래그 수 (NPC당) | 미정 | 퀘스트 상태 머신 GDD 작성 시 | 퀘스트 상태 머신 GDD |
| `recruitment_tags` + `bond_tags` 최대 태그 수 및 정의 목록 | 미정 | 팀 구성 기반 월드 잠금 해제 GDD 작성 시 | 월드 조건 시스템 GDD |
| NPCRegistry 직렬화 포맷 (.tres vs JSON vs 바이너리) | .tres 가정 | 세이브/로드 시스템 GDD 작성 시 | 세이브/로드 시스템 GDD |
| `last_dialogue_node` 타입 확정 | StringName 가정 | 대화 시스템 GDD 검토 시 | 대화 시스템 GDD |
| DEPARTED 동료 — `recruitment_tags`/`bond_tags` 기여 유지 여부 | **결정됨 (2026-04-24)**: DEPARTED 상태 동료는 태그 기여 중단 — `party_has_tag()`에서 제외 | — | — |
| COMPANION → DEPARTED 전환 트리거 조건 | 서사 이벤트 (MVP 외) | Vertical Slice 서사 설계 시 | narrative-director |
| NPCRegistry Autoload 예외 ADR 문서화 | 필요함 | 아키텍처 설계 시 | /architecture-decision 실행 |
| 대화 시스템의 `_quest_flags` 읽기 인터페이스 | **스텁 계약 추가됨** (Dependencies 섹션 참조) — 대화 시스템 GDD에서 구체화 필요 | 대화 시스템 GDD 작성 시 | 대화 시스템 GDD (**선행 조건**: 이 계약 확정 전 NPC 상태 관리 APPROVED 불가) |
