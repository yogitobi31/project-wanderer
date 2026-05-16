# HUD Design

> **Status**: Approved
> **Author**: Juwon + ux-designer
> **Last Updated**: 2026-05-06
> **Template**: HUD Design

---

## HUD Philosophy

유랑단 HUD는 **최소 상시(Minimal but Present)** 원칙을 따른다. 플레이어의 생존과 파티 상태 판단에 직결되는 정보만 항상 화면에 있고, 나머지는 관련 상황이 발생했을 때만 나타나거나 플레이어가 능동적으로 요청해야 볼 수 있다.

아트 바이블의 "조용한 순간을 위한 공간" 원칙을 HUD가 침범하지 않는다. 대화·영입 장면에서는 Must Show 항목도 최소화되거나 숨겨질 수 있다. 게임 필라 "눈에 보이는 성장(Visible Snowball)"을 위해 파티 구성은 항상 화면에 존재해야 한다 — 동료가 한 명 늘 때마다 HUD에서도 즉시 보여야 한다.

---

## Information Architecture

### Full Information Inventory

GDD UI Requirements 및 게임 시스템에서 수집된 HUD 표시 후보 전체:

1. 플레이어 체력바 (HealthComponent `health_changed` 신호)
2. 동료 체력바 (HealthComponent `health_changed` 신호, 최대 3명)
3. 파티 구성 표시 (PartyManager / CompanionJoinEvent `companion_appeared` 신호)
4. 동료 사망/부상 상태 아이콘 (HealthComponent `health_depleted` 신호)
5. 전투 진입/종료 알림 (CombatEncounter `combat_cleared` 신호)
6. 현재 퀘스트 목표 (QuestManager — On Demand 토글)
7. 수집 자원 수량 (Inventory — On Demand 토글)

### Categorization

| 카테고리 | 항목 | 설명 |
|---|---|---|
| **Must Show** | 플레이어 체력바 | 항상 표시 |
| **Must Show** | 동료 체력바 (×최대 3) | 항상 표시 |
| **Must Show** | 파티 구성 표시 | 항상 표시 — Visible Snowball 필라 |
| **Must Show** | 동료 사망/부상 아이콘 | 항상 표시 |
| **Contextual** | 전투 진입/종료 알림 | 전투 전환 시 잠깐 표시 후 사라짐 |
| **On Demand** | 현재 퀘스트 목표 | 버튼 토글 (접근성: 2번 이하 버튼) |
| **On Demand** | 수집 자원 수량 | 버튼 토글 또는 인벤토리 화면 |
| **Hidden** | 미니맵 / 방향 표시 | 월드 내 랜드마크로 탐색 |
| **Hidden** | 전투 중 적 수 | 전투 상황으로 직관적 파악 |

---

## Layout Zones

**기본 레이아웃: 하단 바 (안 A)**

파티 체력 슬롯이 화면 하단 중앙에 가로로 배열된다. 플레이어 슬롯이 맨 왼쪽, 동료 슬롯이 오른쪽으로 추가된다. 동료가 없는 슬롯은 표시되지 않으며, 동료 합류 시 슬롯이 오른쪽으로 추가된다.

```
┌──────────────────────────────────────────────────┐
│                                                  │
│                  [게임 월드]                      │
│                                                  │
│                                                  │
│      ┌──────────┬──────────┬──────────┐          │
│      │[P] ████░│[1] ███░░│[2] ██░░░│  ...       │
│      │  HP바   │  HP바   │  HP바   │            │
│      └──────────┴──────────┴──────────┘          │
└──────────────────────────────────────────────────┘

P = 플레이어  1~3 = 동료 슬롯 (합류 시 동적 추가)
█ = 현재 HP  ░ = 손실 HP  X = 사망 아이콘 오버레이
```

**커스터마이징 (Vertical Slice 목표)**: Settings > HUD 설정에서 위치를 하단 / 좌하단 / 우하단 중 선택 가능. MVP에서는 하단 고정.

**On Demand 오버레이**: 퀘스트 목표 / 자원 수량 토글 시 화면 상단 또는 좌상단에 일시적으로 표시.

---

## HUD Elements

| 요소 | 카테고리 | 위치 | 구성 | 업데이트 트리거 |
|---|---|---|---|---|
| 플레이어 HP 슬롯 | Must Show | 하단 바 맨 왼쪽 | 아이콘 + HP바 + 수치 | `health_changed(current, maximum)` |
| 동료 HP 슬롯 (×최대 3) | Must Show | 하단 바 플레이어 오른쪽 | 아이콘 + HP바 | `health_changed` |
| 동료 사망 아이콘 | Must Show | 해당 슬롯 오버레이 | X 아이콘 | `health_depleted()` |
| 전투 진입/종료 알림 | Contextual | 화면 상단 중앙 | 텍스트 또는 아이콘, 2초 후 페이드 | `CombatEncounter` 전투 시작/`combat_cleared` |
| 퀘스트 목표 | On Demand | 화면 좌상단 (토글 시) | 목표 텍스트 1줄 | 토글 입력 / `QuestManager` 목표 변경 |
| 자원 수량 | On Demand | 화면 좌상단 퀘스트 아래 (토글 시) | 아이템 아이콘 + 수량 | 토글 입력 / `item_added` / `item_removed` |

**HP바 색상 + 비색상 백업** (접근성 요건):
- 75% 이상: 기본색 (Warm Accent)
- 25~75%: 경고색 (주황)
- 25% 미만: 위험색 (빨강) + 깜빡임 애니메이션
- 사망: X 아이콘 + 슬롯 불투명도 감소 — 색상 단독 표시 금지

---

## Dynamic Behaviors

**동료 합류 시**: 새 슬롯이 하단 바 오른쪽에 추가된다. 슬롯 등장 애니메이션 (슬라이드 인 또는 페이드 인) — `companion_appeared` 신호 수신 시.

**동료 사망 시**: 해당 슬롯에 X 아이콘 오버레이, HP바 소진 상태 유지. 슬롯은 제거되지 않음 (사망 동료도 파티 구성원으로 표시 유지).

**대화/영입 씬 진입 시**: Must Show 요소 불투명도 50% 감소 또는 완전 숨김 — DialogueManager `is_active()` 상태 기반. DialogueManager가 HUD에 직접 신호를 보내는 것이 아닌, HUD가 `is_active` 상태를 폴링하거나 신호 구독.

**On Demand 토글 동작**: 퀘스트 목표 토글 버튼 1회 → 표시, 다시 1회 → 숨김. 자원 수량도 동일. 두 항목은 독립적으로 토글.

**저장 성공**: 자동저장 완료 시 HUD 우하단에 "저장 완료 ✓" 0.8초 표시 후 페이드. 전투/이동 흐름을 차단하지 않음.

**저장 중**: 자동저장 트리거 시 HUD 우하단에 저장 아이콘 + "저장 중..." 최대 1.5초 표시. 1.5초 초과 시 "저장에 시간이 걸리고 있습니다..." 로 텍스트 변경. 입력 차단 없음 — 플레이 흐름을 막지 않는다.

**저장 실패**: 자동저장 IO 오류 시 HUD 우하단에 "저장 실패 ⚠" 3초 표시 후 페이드. 플레이 차단 없음. 이후 메인 메뉴 복귀 시 Continue 비활성 + 툴팁으로 상태 전달 (main-menu.md 에러 상태 참조).

**HUD 커스터마이징 (Vertical Slice)**:
- UI 스케일: 75% ~ 150% (기본값 100%)
- 불투명도: 30% ~ 100% (기본값 100%)
- 위치: 하단 / 좌하단 / 우하단
- 요소 ON/OFF: 퀘스트 목표 표시 여부 개별 설정

---

## Platform & Input Variants

**Steam Deck (게임패드)**:
- On Demand 토글 액션은 게임패드 버튼에 매핑 필요 (InputMapManager 경유)
- HUD 요소 크기는 Steam Deck 화면(1280×800)에서 가독성 확보 — HP바 최소 높이 8px

**PC (Keyboard/Mouse)**:
- On Demand 토글은 키보드 단축키 (기본값 미정 — `/ux-design settings-screen` 시 확정)
- 고해상도(4K) 대응: UI 스케일 설정으로 커버

**모션 감소 모드**:
- 슬롯 등장 애니메이션 비활성화
- HP 위험 깜빡임 → 정적 아이콘으로 대체

---

## Accessibility

**접근성 티어**: Standard (committed — design/accessibility-requirements.md)

**색상 단독 표시자 금지**: HP 상태는 색상 + 수치 텍스트 + 아이콘(위험 시 깜빡임) 3중 신호. 색맹 모드 3종(Protanopia / Deuteranopia / Tritanopia) 대응 필수 — 체력바 팔레트 우선 적용.

**파티 상태 아이콘**: 동료 생존/부상/사망은 원형 아이콘(생존) / 삼각형(부상) / X(사망) 형태로 구분 — 색상 없이도 판독 가능.

**텍스트 크기**: HP 수치 표시 20px 이상 @ 1080p.

**On Demand 토글 접근성**: 퀘스트 목표는 2번 이하 버튼 입력으로 확인 가능 (접근성 요건 준수).

---

## Visual Budget

**최대 동시 표시 요소 수**: 7개
- Must Show: 플레이어 슬롯 1 + 동료 슬롯 최대 3 = 최대 4슬롯
- Contextual: 전투 알림 1 (동시에 1개만 표시, 큐 처리)
- On Demand: 퀘스트 목표 1 + 자원 수량 1 = 최대 2개

**화면 점유율 상한**:
- Must Show (하단 바): 화면 높이의 12% 이내 @ 1080p (약 130px)
- On Demand 오버레이 (좌상단): 화면 너비의 25% × 높이의 10% 이내
- Contextual 알림 (상단 중앙): 화면 너비의 30% × 높이의 6% 이내
- 총 HUD 점유율: 화면 면적의 20% 초과 금지

**알림 큐/우선순위**:
- Contextual 알림이 이미 표시 중일 때 새 알림 발생 시 → 현재 알림 즉시 페이드아웃 후 새 알림 표시
- On Demand 오버레이와 Contextual 알림은 독립 레이어로 겹침 허용 (상단 vs 좌상단)
- Must Show 요소는 어떤 상황에서도 다른 HUD 요소에 의해 가려지지 않음

**Steam Deck 안전 영역**:
- 화면 사방 40px 마진 유지 (1280×800 기준)
- 하단 바 하단 엣지: 화면 하단에서 최소 50px 위

---

## HUD States by Gameplay Context

| 상태 | Must Show | Contextual | On Demand | 비고 |
|---|---|---|---|---|
| **탐색 (Exploration)** | 100% 불투명 표시 | 숨김 | 토글 가능 | 기본 상태 |
| **전투 (Combat)** | 100% 불투명 표시 | 전투 알림 표시 (2초 후 페이드) | 토글 가능 | 알림 종료 후 자동 복귀 |
| **대화/영입 (Dialogue)** | 50% 불투명 또는 숨김 | 숨김 | 숨김 (토글 비활성) | DialogueManager `is_active()` 기반 |
| **일시정지 (Paused)** | 숨김 | 숨김 | 숨김 | 일시정지 메뉴가 전체 화면 점유 |

**상태 전환 규칙**:
- 탐색 → 전투: `CombatEncounter` 시작 신호 수신 시 즉시 전환, 알림 표시
- 전투 → 탐색: `combat_cleared` 수신 후 알림 표시 → 2초 후 탐색 상태로 복귀
- 탐색/전투 → 대화: `DialogueManager.is_active() == true` 감지 시 Must Show 페이드
- 대화 → 탐색/전투: `DialogueManager.is_active() == false` 복귀 시 Must Show 원복
- 모든 상태 → 일시정지: 일시정지 입력 수신 즉시 HUD 전체 숨김, 메뉴 레이어 활성화
- 일시정지 → 이전 상태: 메뉴 닫힘 시 이전 상태 그대로 복귀 (On Demand 토글 상태 유지)

---

## Acceptance Criteria

- **AC-1**: 게임 시작 시 플레이어 HP 슬롯이 하단 바에 표시되고, HP바가 최대치로 채워져 있다.
- **AC-2**: 동료 합류 시(`companion_appeared`) 100ms 이내에 새 슬롯이 하단 바 오른쪽에 추가된다.
- **AC-3**: 플레이어 HP가 25% 미만일 때 HP바가 위험색(빨강)으로 변하고 깜빡임 애니메이션이 재생된다.
- **AC-4**: 동료 사망 시(`health_depleted`) 해당 슬롯에 X 아이콘이 오버레이되고, 슬롯은 제거되지 않는다.
- **AC-5**: 퀘스트 목표 토글 입력 1회 → 좌상단에 목표 텍스트 표시, 재입력 → 숨김. 두 번 이하 입력으로 동작한다.
- **AC-6**: `DialogueManager.is_active() == true`일 때 Must Show 요소 불투명도가 50% 이하로 감소하거나 숨겨진다.
- **AC-7**: 일시정지 시 HUD 전체가 숨겨지고, 일시정지 해제 시 이전 On Demand 토글 상태 그대로 복귀한다.
- **AC-8**: 색맹 모드 Protanopia 활성 시 HP바 팔레트가 대체 팔레트로 교체되어 표시된다.
- **AC-9**: Steam Deck(1280×800)에서 모든 HUD 요소가 화면 사방 40px 안전 영역 내에 배치된다.
- **AC-10**: UI 스케일 150% 설정 시 HUD 요소가 다른 요소와 겹치지 않고 레이아웃을 유지한다.

---

## Open Questions

| 질문 | 담당 | 기한 |
|---|---|---|
| On Demand 토글 기본 키 바인딩 — InputMapManager 액션명 확정 필요 | game-designer + godot-specialist | settings-screen UX 스펙 작성 시 |
| 대화 씬에서 HUD 숨김 구현 — DialogueManager 신호 구독 vs 폴링 결정 | godot-specialist | DialogueManager 에픽 구현 시 |
| HP바 최소 픽셀 크기 — Godot 4.6 TextureProgressBar 최소 크기 확인 필요 | godot-specialist | HealthComponent 에픽 구현 시 |
| HUD 커스터마이징 설정값 저장 — SaveManager 직렬화 계약에 포함 여부 | game-designer | Vertical Slice 스프린트 플랜 시 |
