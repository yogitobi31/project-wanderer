# Interaction Pattern Library

> **Status**: Draft Complete
> **Author**: Juwon + ux-designer
> **Last Updated**: 2026-05-06
> **Template**: Interaction Pattern Library

---

## Overview

유랑단 인터랙션 패턴 라이브러리. UX 스펙 작성 시 이 패턴을 참조하여 일관된 UI 동작을 보장한다. 새 스펙에서 새로운 패턴이 등장하면 이 파일에 추가한다.

입력 기준: Keyboard/Mouse 주 + Gamepad (Steam Deck 필수).
접근성 기준: Standard 티어 (design/accessibility-requirements.md).

---

## Pattern Catalog

| 패턴명 | 카테고리 | 사용 화면 |
|---|---|---|
| [Primary Button](#primary-button) | Input | main-menu, pause |
| [Disabled Button](#disabled-button) | Input | main-menu, pause |
| [Confirmation Dialog](#confirmation-dialog) | Modal | main-menu, pause |
| [Loading Button State](#loading-button-state) | Feedback | main-menu |
| [Modal Overlay](#modal-overlay) | Modal | pause |
| [Inline Expandable Section](#inline-expandable-section) | Navigation | pause |
| [Volume Slider](#volume-slider) | Input | pause |
| [HP Bar](#hp-bar) | Data Display | hud |
| [Dynamic Party Slot](#dynamic-party-slot) | Data Display | hud |

---

## Patterns

---

### Primary Button

**Category**: Input
**Used In**: main-menu, pause

**Description**: 게임의 기본 액션 버튼. 씬 전환, 확정, 재개 등 플레이어의 주요 의도를 실행한다. 모든 화면에서 일관된 시각 언어를 유지한다.

**Specification**:
- 크기: 최소 너비 120px, 최소 높이 36px @ 1080p
- 폰트 크기: 24px 이상 @ 1080p
- 포커스 상태: 명확한 테두리 하이라이트 (마우스 호버 없이도 표시)
- 활성 상태: 클릭/A버튼 시 눌림 시각 피드백 (색상 변화 또는 스케일 축소 0.95×)
- 입력: 마우스 클릭 / Enter 키 / 게임패드 A버튼
- 탐색: Tab / ↑↓ / D-pad ↑↓

**When to Use**: 플레이어가 결과를 실행하는 모든 액션 (씬 전환, 저장, 확정 등).

**When NOT to Use**: 토글 동작 (on/off 전환)에는 Inline Expandable Section 또는 별도 토글 컴포넌트 사용.

---

### Disabled Button

**Category**: Input
**Used In**: main-menu (Continue — 세이브 없음), pause (Save — 전투 중)

**Description**: 현재 조건에서 선택 불가능한 버튼. 이유를 비색상 수단으로 전달한다.

**Specification**:
- 시각: 불투명도 40% 감소 + 색상 채도 감소 (색상 단독 표시 금지)
- 선택 불가: 클릭/Enter/A버튼 입력 무시
- 포커스: Tab/D-pad 탐색 순서에 포함 (포커스는 받되 실행되지 않음)
- 스크린 리더: "(사용 불가)" 또는 사유 텍스트를 레이블에 포함 — 예: "저장 (전투 중 불가)"
- 툴팁: 포커스 시 비활성 이유를 1줄 텍스트로 표시

**When to Use**: 조건 충족 전까지 일시적으로 불가한 액션.

**When NOT to Use**: 영구적으로 존재하지 않는 기능 — 그 경우 버튼 자체를 숨김.

---

### Confirmation Dialog

**Category**: Modal
**Used In**: main-menu (덮어쓰기 확인), pause (메인 메뉴 / 종료 손실 경고)

**Description**: 되돌릴 수 없는 액션 실행 전 플레이어의 의도를 재확인하는 2버튼 팝업.

**Specification**:
- 구성: 본문 텍스트 (1~2줄) + 취소 버튼 + 확정 버튼
- 버튼 배치: 취소 왼쪽, 확정 오른쪽 (PC 표준)
- 첫 포커스: 취소 버튼 (안전한 기본값)
- 배경: 모달 뒤 딤 패널 (불투명도 60%)
- Esc / B버튼: 취소와 동일
- 확정 버튼 라벨: "확인" 금지 — 액션을 명시 ("새로 시작", "계속하기" 등)
- 본문 텍스트: 2줄 이내. 독일어 40% 확장 대비 레이아웃 여유 필요 (MEDIUM 위험)

**When to Use**: 영구적 데이터 삭제, 미저장 진행 손실, 비가역적 상태 전환.

**When NOT to Use**: 가역적 액션 (설정 변경, 일반 탐색).

---

### Loading Button State

**Category**: Feedback
**Used In**: main-menu (씬 전환 중)

**Description**: 버튼 선택 후 결과가 즉시 나타나지 않을 때 처리 중임을 알리는 버튼 상태.

**Specification**:
- 버튼 텍스트 → "..." 로 교체 (스피너 이미지 대신 텍스트 — MVP 단순화)
- 모든 버튼 비활성화 (중복 입력 방지)
- 지속 시간: 씬 전환 완료까지 유지
- 스크린 리더: "로딩 중" 상태 알림 (Godot AccessKit aria-busy 동등)

**When to Use**: 버튼 선택 후 0.3초 이상 결과가 지연될 때.

**When NOT to Use**: 즉각 반응하는 액션 (Pause 열기, 탭 전환 등).

---

### Modal Overlay

**Category**: Modal
**Used In**: pause

**Description**: 게임 월드 위에 반투명 딤 패널과 함께 표시되는 센터 패널. 게임 상태는 유지되며 배경에서 보인다.

**Specification**:
- 구현: CanvasLayer (layer=10, ADR-0003 기준)
- 배경 딤: 불투명 패널 불투명도 60% (블러 효과는 성능 고려 — 선택적)
- 진입 애니메이션: 페이드 인 0.15초. 모션 감소 모드 시 즉시.
- 퇴장 애니메이션: 페이드 아웃 0.15초. 모션 감소 모드 시 즉시.
- 포커스 트랩: 모달 열린 동안 포커스가 모달 내부에 고정 (배경 버튼 탐색 불가)
- 닫기: Esc / B버튼으로 닫힘 (닫기 가능한 모달에 한함)

**When to Use**: 게임 상태를 유지하면서 추가 UI 레이어가 필요할 때 (Pause, 대화, 알림).

**When NOT to Use**: 씬 전환이 필요한 전체 화면 전환.

---

### Inline Expandable Section

**Category**: Navigation
**Used In**: pause (볼륨 설정)

**Description**: 버튼 선택 시 같은 패널 내에서 추가 콘텐츠가 펼쳐지는 패턴. 별도 화면 전환 없음.

**Specification**:
- 트리거: 버튼에 ▶ 아이콘 (닫힘) / ▼ 아이콘 (열림) 표시
- 확장 애니메이션: 패널 높이 증가 0.1초. 모션 감소 모드 시 즉시.
- 탐색: 확장 시 내부 컴포넌트가 Tab/D-pad 탐색 순서에 포함
- 축소: 같은 버튼 재선택 또는 다른 섹션 선택 시
- 동시 확장: MVP에서는 단일 섹션만 열림 (다른 섹션 선택 시 현재 섹션 자동 닫힘)

**When to Use**: 자주 쓰지 않는 세부 설정을 메인 흐름 방해 없이 접근할 때.

**When NOT to Use**: 자주 쓰는 콘텐츠 — 그 경우 항상 표시하거나 별도 화면으로 분리.

---

### Volume Slider

**Category**: Input
**Used In**: pause (음악/SFX/UI 볼륨)

**Description**: 연속 값을 조절하는 가로 슬라이더. 볼륨 조절에 특화된 구현.

**Specification**:
- 범위: 0.0 ~ 1.0 (UI 표시: 0~100%)
- 기본값: 1.0 (100%)
- 입력 (Mouse): 클릭+드래그
- 입력 (Keyboard): 포커스 후 ←→ 키 (스텝: 0.05 = 5%)
- 입력 (Gamepad): D-pad ←→ (스텝: 0.05 = 5%)
- 실시간 반영: `AudioServer.set_bus_volume_db()` 직접 호출 (AudioManager 경유 불필요)
- 저장: 슬라이더 조작 완료(포커스 이탈) 시 설정 저장 (MVP: SaveManager 또는 별도 config)
- 레이블: 슬라이더 왼쪽에 카테고리명, 오른쪽에 현재 값(%) 표시

**When to Use**: 연속적인 수치 조절이 필요한 모든 설정.

**When NOT to Use**: ON/OFF 이진 설정 — 그 경우 체크박스 또는 토글 버튼 사용.

---

### HP Bar

**Category**: Data Display
**Used In**: hud (플레이어 + 동료 체력)

**Description**: 현재/최대 수치를 시각적 바로 표시하는 리소스 게이지. 체력 시스템에 특화.

**Specification**:
- 구현: Godot TextureProgressBar 또는 ProgressBar
- 업데이트: `health_changed(current, maximum)` 신호 수신 시 즉시 반영
- 최소 높이: 8px @ 1080p (Steam Deck 가독성 기준)
- 수치 텍스트: HP바 위 또는 옆에 current/maximum 숫자 표시 (플레이어 슬롯 필수, 동료 슬롯 선택)
- 색상 상태 + 비색상 백업 (색상 단독 표시 금지):
  - 75% 이상: 기본색 (Warm Accent)
  - 25~75%: 경고색 (주황) — 수치로 병행 표시
  - 25% 미만: 위험색 (빨강) + 깜빡임 애니메이션 — 수치로 병행 표시
  - 0% (사망): X 아이콘 오버레이 + 슬롯 불투명도 감소
- 색맹 모드 3종 대응 필수 (Protanopia / Deuteranopia / Tritanopia)

**When to Use**: 플레이어 또는 동료의 생존 자원 표시.

**When NOT to Use**: 비전투 진행도(퀘스트 진행, 경험치) — 별도 Progress Bar 패턴 사용.

---

### Dynamic Party Slot

**Category**: Data Display
**Used In**: hud (파티 구성 표시)

**Description**: 동료 합류 시 HUD에 동적으로 추가되는 파티 멤버 슬롯. 게임 필라 "눈에 보이는 성장(Visible Snowball)"을 HUD에서 구현.

**Specification**:
- 초기 상태: 플레이어 슬롯만 표시
- 동료 합류: `companion_appeared` 신호 수신 시 새 슬롯 오른쪽에 추가
  - 등장 애니메이션: 슬라이드 인 또는 페이드 인. 모션 감소 모드 시 즉시.
- 슬롯 구성: 캐릭터 아이콘 + HP Bar 패턴
- 동료 사망: 슬롯 제거 없음 — X 아이콘 오버레이 + HP Bar 소진 상태 유지
- 최대 슬롯: 플레이어 1 + 동료 3 = 4슬롯
- 비색상 상태 표시: 원형(생존) / 삼각형(부상, 25% 미만) / X(사망) 아이콘 병행

**When to Use**: 실시간으로 파티 구성이 변하는 HUD 표시.

**When NOT to Use**: 정적 파티 구성 화면 (메뉴 내 파티 관리).

---

## Gaps & Patterns Needed

향후 UX 스펙 작성 시 추가 예정 패턴:

| 패턴 | 필요 화면 | 우선순위 |
|---|---|---|
| Settings Screen Layout | settings-screen | Vertical Slice |
| Key Rebind Row | settings-screen | Vertical Slice |
| Dialogue Box | gameplay (DialogueManager) | Core Sprint |
| Quest Objective Display | hud (On Demand) | Core Sprint |
| Inventory Grid | inventory-screen | Feature Sprint |
| Tooltip | inventory-screen, hud | Feature Sprint |

---

## Open Questions

| 질문 | 담당 | 기한 |
|---|---|---|
| HP Bar 깜빡임 애니메이션 — Godot 4.6 CanvasItem modulate tween vs AnimationPlayer 결정 | godot-specialist | HealthComponent 에픽 구현 시 |
| 색맹 팔레트가 아트 바이블 14색 마스터 팔레트와 충돌하는가 | art-director | interaction-patterns 확정 후 |
| Volume Slider 설정값 저장 방식 — SaveManager 포함 여부 또는 별도 settings.cfg | game-designer | SaveManager 스토리 작성 시 |
