# Cross-GDD Review Report — 유랑단
**Date:** 2026-04-26
**Scope:** 18 MVP System GDDs + game-concept.md + systems-index.md
**Mode:** Full (Consistency + Design Theory)
**Reviewer:** /review-all-gdds skill (claude-sonnet-4-6)

---

## Verdict: FAIL

6개의 블로킹 이슈가 발견되었습니다. 현재 GDD 상태에서 아키텍처를 구축하면 코드에 버그를 내재하게 됩니다. 블로커 해소 후 재검토 필요.

---

## Phase 2: Cross-GDD Consistency

### 🔴 B-1: NPC 상태명 불일치 (3개 GDD 영향)

**권위 소스:** `NPC-상태-관리.md`
```
RelationshipState enum:
  UNKNOWN(0), MET(1), QUEST_ACTIVE(2), COMPANION(3),
  DEPARTED(4), HOSTILE(5), QUEST_ABANDONED(6)
```

**모순된 참조:**

| GDD | 사용된 상태명 | 실제 enum 값 |
|-----|------------|------------|
| `대화-시스템.md` | `"IDLE"` | 존재하지 않음 |
| `대화-시스템.md` | `"QUEST_GIVEN"` | 존재하지 않음 |
| `대화-시스템.md` | `"RECRUITED"` | 존재하지 않음 → `COMPANION` |
| `퀘스트-상태-머신.md` | `"RECRUITED"` | 존재하지 않음 → `COMPANION` |
| `동료-영입-퀘스트.md` | `"QUEST_DONE"` | 존재하지 않음 → `QUEST_ACTIVE`? `COMPANION`? |

→ 세 GDD가 모두 다른 상태명을 사용. 구현 시 런타임 에러 확정.

**수정 대상:** `대화-시스템.md`, `퀘스트-상태-머신.md`, `동료-영입-퀘스트.md`

---

### 🔴 B-2: Autoload 이름 불일치

**권위 소스:** 각 GDD의 선언부

| 권위 Autoload명 | 잘못 참조한 GDD | 사용된 잘못된 이름 |
|---------------|--------------|----------------|
| `NPCRegistry` | `퀘스트-상태-머신.md` | `NpcManager` |
| `InputMapManager` | `플레이어-캐릭터-컨트롤러.md` | `InputManager` |

→ `NpcManager.set_state()`, `InputManager.get_move_vector()`는 존재하지 않는 API 호출.

**수정 대상:** `퀘스트-상태-머신.md`, `플레이어-캐릭터-컨트롤러.md`

---

### 🔴 B-3: CharacterStats 필드명 불일치

**권위 소스:** `능력치-시스템.md`
```
CharacterStats 필드: max_hp, atk, def, spd
```

| GDD | 잘못된 필드명 | 올바른 필드명 |
|-----|------------|------------|
| `체력-데미지-시스템.md` | `stats.max_health` | `stats.max_hp` |
| `체력-데미지-시스템.md` | `stats.defense` | `stats.def` |
| `동료-AI-시스템.md` | `stats.move_speed` | `stats.spd` |
| `동료-AI-시스템.md` | `stats.attack_damage` | `stats.atk` |

→ 두 시스템 GDD가 실제 존재하지 않는 필드를 참조.

**수정 대상:** `체력-데미지-시스템.md`, `동료-AI-시스템.md`

---

### 🔴 B-4: 동료 합류 트리거 메커니즘 충돌

**`동료-합류-이벤트.md`** (권위 소스):
```
트리거: EventBus.companion_join_requested(companion_id) 신호 발행
```

**`동료-영입-퀘스트.md`** (충돌):
```
R-2: CompanionJoinEvent.trigger(companion_id)  # 직접 메서드 호출
```

→ 동일한 이벤트를 위한 두 가지 다른 호출 패턴. 어느 쪽이 구현 기준인지 결정되지 않음.

**수정 대상:** `동료-영입-퀘스트.md` (EventBus 신호 패턴으로 통일)

---

### 🔴 B-5: 퀘스트 완료 시 아이템 제거 미정의

**`아이템-데이터베이스.md`** Cross-system Contract [계약 1]:
> "퀘스트 완료 시 아이템 제거 책임은 퀘스트 상태 머신"

**`퀘스트-상태-머신.md`** `on_complete` 단계:
```
1. QuestDef.rewards 처리
2. NPCRegistry.set_state(npc_id, RelationshipState.COMPANION)
3. (아이템 제거 단계 없음)
```

→ 계약을 이행하는 코드가 어느 GDD에도 명시되어 있지 않음. 퀘스트 아이템이 영구적으로 인벤토리에 잔류.

**수정 대상:** `퀘스트-상태-머신.md` (on_complete에 Inventory.remove_item 단계 추가)

---

### 🔴 B-6: PartyManager — 참조는 있지만 GDD 없음

**참조하는 GDD:**
- `실시간-파티-전투.md`: `PartyManager.companion_count` 읽기
- `동료-합류-이벤트.md`: `PartyManager` 파티 등록

**실제 상태:** `design/gdd/`에 `PartyManager` GDD 없음. `동료-합류-이벤트.md`에 인라인 스텁 존재하지만 정식 명세 없음.

→ API 계약 불명확. MAX_PARTY_SIZE=3 적용 위치 미정의. 두 시스템이 파티 상태를 읽는 방법이 정해지지 않음.

**필요 조치:** `파티-매니저.md` 신규 작성

---

## ⚠️ 경고 이슈 (WARNING)

### W-1: 플레이어 HP 값 불일치

| GDD | 값 | 필드 |
|-----|-----|------|
| `능력치-시스템.md` | `80` | `base_max_hp` |
| `체력-데미지-시스템.md` | `100` | Tuning Knobs `player_max_health` |

→ `능력치-시스템.md`를 권위 소스로 지정하고 `체력-데미지-시스템.md` 수치 통일 권장.

---

### W-2: 부활(Respawn) 소유권 순환

- `체력-데미지-시스템.md`: "플레이어 사망 → 체력 시스템이 이벤트 발행, 리스폰은 다른 시스템 담당"
- `플레이어-캐릭터-컨트롤러.md`: 리스폰 처리 로직 없음
- 두 GDD 중 어느 쪽도 리스폰 메커니즘을 소유하지 않음

→ 플레이어 사망 후 게임 상태 불명확. MVP 스코프에서 리스폰 소유자 명확화 필요.

---

### W-3: EventBus — 참조는 있지만 정의 없음

`동료-합류-이벤트.md`가 `EventBus`를 Autoload로 사용하지만 `design/gdd/`에 EventBus GDD 없음. Autoload 등록 여부, 제공 신호 목록, 소유 시스템 모두 미정의.

**권장 조치:** `이벤트-버스.md` 신규 작성 (또는 PartyManager GDD에 통합 정의)

---

### W-4: item_id 타입 불일치

| GDD | 타입 | 컨텍스트 |
|-----|------|--------|
| `아이템-데이터베이스.md` | `StringName` | `ItemDefinition.item_id` 필드 |
| `인벤토리-시스템.md` | `String` | `add_item(item_id: String, ...)` |

→ GDScript에서 `StringName != String` 비교는 예상치 못한 결과를 낼 수 있음. `인벤토리-시스템.md` 시그니처를 `StringName`으로 통일 권장.

---

## Phase 3: Game Design Holism

### ✅ 3a: 진행 루프 경쟁 — 이상 없음
하나의 주요 루프(동료 영입 → 파티 강화 → 지역 해금)가 명확하게 정의되어 있으며 모든 서브시스템이 이를 지원. 경쟁 루프 없음.

### ⚠️ 3b: 동시 활성 시스템 수 — 경계선
핵심 전투 중 동시 Active 시스템 4개 (전투, HP, 히트박스, 수집). 권장 한계 상한선이지만 허용 범위 내. 수집이 전투 중 충돌을 일으킬 가능성 주의.

### ✅ 3c: 지배 전략 감지 — 이상 없음
현재 MVP는 단일 근거리 전투 기반. 추후 원거리 시스템 추가 시 재검토 필요.

### ✅ 3d: 경제 루프 분석 — 구조적으로 건전함
자원: 수집 → 인벤토리 → 퀘스트 제출(소비). 무한 축적 없음. 단 B-5(아이템 제거 누락)가 경제 루프를 깨뜨릴 수 있음.

### ✅ 3e: 난이도 곡선 — 의도적 스케일링
`enemy_count = base + (companion_count × ENEMY_SCALE_PER_COMPANION)` — 선형 스케일, 파티 성장과 동기화됨.

### ✅ 3f: 필라 정렬 — 전 시스템 통과
모든 18개 시스템이 4개 필라 중 최소 1개에 기여. Anti-pillar 위반 없음.

### ✅ 3g: 플레이어 판타지 일관성 — 강함
"동료와 함께 성장하는 여정" 단일 정체성으로 모든 시스템 수렴.

---

## Phase 4: 크로스-시스템 시나리오 워크스루

### 시나리오 1: 퀘스트 완료 → 동료 합류 전체 체인 — BLOCKER

```
트리거: 플레이어가 퀘스트 아이템 습득 후 NPC에 대화
→ 대화-시스템: 상태 확인 ("QUEST_GIVEN" 조회)  ← B-1: 존재하지 않는 상태명
→ 퀘스트-상태-머신: on_complete 실행
   → NpcManager.set_state("RECRUITED")  ← B-2: 잘못된 Autoload, B-1: 잘못된 상태명
   → 아이템 제거 없음  ← B-5: 계약 불이행
→ 동료-영입-퀘스트: CompanionJoinEvent.trigger()  ← B-4: 트리거 방식 충돌
→ 동료-합류-이벤트: EventBus 신호 수신 시도  ← W-3: EventBus 미정의

결과: 이 체인의 5개 단계 중 4개에서 에러 발생 가능
```

### 시나리오 2: 전투 중 동료 HP 관리 — BLOCKER

```
트리거: 적이 동료 공격
→ 히트박스-충돌-감지: hit_confirmed(attack_data) 신호
→ 체력-데미지-시스템: final_damage = max(1, attack - stats.defense)  ← B-3: stats.def가 올바름
→ HealthComponent: stats.max_health으로 HP 비율 계산  ← B-3: stats.max_hp가 올바름

결과: 방어력 계산 및 HP 비율 표시 모두 잘못된 필드 참조
```

---

## 수정 액션 플랜

### 즉시 수정 필요 (BLOCKER 해소)

| 우선순위 | GDD | 수정 내용 |
|---------|-----|---------|
| 1 | `대화-시스템.md` | 상태명 → RelationshipState enum 값으로 교체 |
| 2 | `퀘스트-상태-머신.md` | NpcManager→NPCRegistry, "RECRUITED"→COMPANION, 아이템 제거 단계 추가 |
| 3 | `동료-영입-퀘스트.md` | "QUEST_DONE" 상태 수정, 트리거를 EventBus 신호 패턴으로 통일 |
| 4 | `체력-데미지-시스템.md` | 필드명 수정 (max_health→max_hp, defense→def), HP 값 80으로 통일 |
| 5 | `동료-AI-시스템.md` | 필드명 수정 (move_speed→spd, attack_damage→atk) |
| 6 | `플레이어-캐릭터-컨트롤러.md` | InputManager→InputMapManager |

### 신규 작성 필요

| GDD | 이유 | 우선순위 |
|-----|------|--------|
| `파티-매니저.md` | B-6: 2개 GDD에서 참조 | 🔴 HIGH — 아키텍처 전 필수 |
| `이벤트-버스.md` | W-3: 합류 이벤트에서 참조 | ⚠️ MEDIUM — 아키텍처 전 권장 |

---

## 종합 판정 매트릭스

| 카테고리 | 결과 |
|---------|------|
| 의존성 양방향성 | ⚠️ 부분 통과 (PartyManager, EventBus 누락) |
| 규칙 모순 | 🔴 실패 (상태명, Autoload명, 필드명) |
| 스테일 참조 | 🔴 실패 (다수) |
| 튜닝 소유권 충돌 | ⚠️ 경고 (HP값) |
| 수식 호환성 | 🔴 실패 (필드명 불일치) |
| 진행 루프 경쟁 | ✅ 통과 |
| 인지 부하 | ✅ 통과 (경계선) |
| 경제 루프 | ⚠️ 경고 (아이템 제거 누락) |
| 난이도 곡선 | ✅ 통과 |
| 필라 정렬 | ✅ 통과 |

**최종 판정: FAIL → 해소 완료 (2026-04-26)**

## Blockers Resolved

모든 블로커가 동일 세션(2026-04-26)에 해소되었습니다.

| 블로커 | 해소 방법 | 수정 파일 |
|--------|---------|---------|
| B-1 NPC 상태명 불일치 | RelationshipState enum으로 통일 | 대화-시스템, 퀘스트-상태-머신, 동료-영입-퀘스트 |
| B-2 Autoload 이름 불일치 | NPCRegistry, InputMapManager로 수정 | 퀘스트-상태-머신, 플레이어-캐릭터-컨트롤러 |
| B-3 CharacterStats 필드명 불일치 | max_hp, def, atk, spd로 수정 | 체력-데미지-시스템, 동료-AI-시스템 |
| B-4 합류 트리거 충돌 | EventBus.emit_signal 패턴으로 통일 | 동료-영입-퀘스트 |
| B-5 퀘스트 아이템 제거 누락 | on_complete에 remove_items 단계 추가 | 퀘스트-상태-머신 |
| B-6 PartyManager GDD 없음 | 파티-매니저.md 신규 작성 | (신규) |
| W-3 EventBus GDD 없음 | 이벤트-버스.md 신규 작성 | (신규) |

**Gate check 결과**: CONCERNS (Technical Setup 진입 승인)
**게이트 레포트**: `production/gate-checks/gate-systems-design-to-technical-setup-2026-04-26.md`
