# Accessibility Requirements: 유랑단

> **Status**: Committed
> **Author**: ux-designer / producer
> **Last Updated**: 2026-05-05
> **Accessibility Tier Target**: Standard
> **Platform(s)**: PC (Windows / Linux / macOS via Steam), Steam Deck
> **External Standards Targeted**:
> - WCAG 2.1 Level AA (text contrast, text sizing)
> - Game Accessibility Guidelines — Standard feature set
> - Xbox Accessibility Guidelines: N/A (PC/Steam only)
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`

---

## Accessibility Tier Definition

### This Project's Commitment

**Target Tier**: Standard

**Rationale**: 유랑단은 동료 영입과 파티 기반 전투가 핵심인 2D 픽셀 아트 RPG다. 실시간 전투가 있지만 핵심 루프는 대화·탐색·파티 관리로 구성되어 있어 모터 장벽이 순수 액션 게임보다 낮다. 그러나 한국어/다국어 대화 텍스트가 많고 색상 기반 UI(파티 상태 표시, 적 경보 등)가 핵심 정보 전달에 사용되기 때문에 시각 접근성이 중요하다. Steam Deck 대응이 `technical-preferences.md`에 명시되어 있어 전체 게임패드 리바인딩과 마우스 호버 없이도 동작하는 UI가 필수다. Basic 티어는 색맹 모드와 UI 스케일링을 포함하지 않아 약 8%의 색각이상 플레이어와 고해상도 디스플레이 사용자를 배제한다. Comprehensive 티어는 현재 2인 팀 규모에서 구현 비용이 과도하다. Standard 티어는 핵심 장벽을 모두 해소하면서 실현 가능한 수준이다.

**Features explicitly in scope (Standard 기준 추가):**
- 전체 게임패드 리바인딩 — Steam Deck 필수 (ADR-0005 입력 매핑 시스템과 연계)
- 색맹 모드 3종 (Protanopia, Deuteranopia, Tritanopia) — 파티·전투 UI 색상 의존도 높음
- 자막 화자 식별 — 다수 동료 NPC 대화 시 필수

**Features explicitly out of scope (Standard 제외):**
- 인게임 월드 스크린 리더 (메뉴 전용으로 제한 — Godot 4.6 AccessKit 커버 범위)
- 자막 폰트·색상 커스터마이즈 (Comprehensive) — v1.0 이후 검토
- 단일 손 모드 (Comprehensive) — 실시간 전투 복잡도 고려, 포스트런치 평가

---

## Visual Accessibility

| Feature | Tier | Status | Notes |
|---------|------|--------|-------|
| 최소 텍스트 크기 — 메뉴 UI | Standard | Not Started | 24px 이상 @ 1080p. UI 스케일 100% 기준. |
| 최소 텍스트 크기 — 자막 | Standard | Not Started | 32px 이상 @ 1080p. TV 거리 시청 고려. |
| 최소 텍스트 크기 — HUD | Standard | Not Started | 체력바·파티 상태 등 핵심 정보 20px 이상. |
| 텍스트 대비 — UI | Standard | Not Started | 본문 4.5:1 이상 (WCAG AA), 대형 텍스트 3:1 이상. |
| 텍스트 대비 — 자막 | Standard | Not Started | 7:1 이상. 불투명 배경 박스 기본값. |
| 색맹 모드 — Protanopia | Standard | Not Started | 빨강→주황/노랑, 초록→청록. 체력바·적 표시자 우선 적용. |
| 색맹 모드 — Deuteranopia | Standard | Not Started | Protanopia와 팔레트 조정 방향 유사. Coblis로 검증. |
| 색맹 모드 — Tritanopia | Standard | Not Started | 파랑→보라, 노랑→주황. |
| 색상 단독 표시자 감사 | Basic | Not Started | 색상만으로 정보 전달하는 모든 UI 요소 목록화 → 비색상 백업 추가. |
| UI 스케일링 | Standard | Not Started | 75%~150%, 기본값 100%. HUD·메뉴 독립 조절. |
| 밝기/감마 조절 | Basic | Not Started | 그래픽 설정에 노출. 캘리브레이션 참조 이미지 포함. |
| 화면 플래시 경고 | Basic | Not Started | 실행 전 광과민성 경고. VFX 플래시 Harding FPA 기준 준수. |
| 모션 감소 모드 | Standard | Not Started | 화면 쉐이크·카메라 흔들림·메뉴 트랜지션 애니메이션 감소/제거 토글. |
| 자막 — on/off | Basic | Not Started | 기본값 OFF. 첫 실행 시 선택 제공. |
| 자막 — 화자 식별 | Standard | Not Started | 동료 NPC 다수 → 화자 이름 표시 필수. 색상 코드는 색맹 모드와 함께 테스트. |

### 색상 단독 표시자 감사 (Pre-Production 중 작성)

| 위치 | 색상 신호 | 전달 정보 | 비색상 백업 | 상태 |
|------|----------|---------|-----------|------|
| 체력바 | 빨강 = 위험 | 플레이어/동료 사망 임박 | 수치 표시 + 깜빡임 | Not Started |
| 파티 상태 표시 | 색상 점 | 동료 생존/부상/사망 | 아이콘 형태(원/삼각/X) | Not Started |
| 적 경보 표시 | 빨강 = 적대 | 전투 진입 여부 | 느낌표 아이콘 + 애니메이션 | Not Started |
| 아이템 등급 | 색상 테두리 | 아이템 품질 | 등급 텍스트 + 별 아이콘 | Not Started |

---

## Motor Accessibility

| Feature | Tier | Status | Notes |
|---------|------|--------|-------|
| 전체 입력 리바인딩 | Standard | **Implemented** | InputMapManager (ADR-0005) — 키보드/마우스/게임패드 독립 리바인딩. 충돌 방지 포함. ConfigFile 저장. |
| 입력 방식 전환 | Standard | Not Started | 키보드↔게임패드 실시간 전환. UI 프롬프트 아이콘 동적 업데이트. |
| 홀드→토글 전환 | Standard | Not Started | 모든 "홀드 [버튼]" 입력에 토글 대안 제공. 달리기·방어 등 목록화 필요. |
| 연타 입력 대안 | Standard | Not Started | 초당 3회 초과 연타 필요 입력 → 단일 프레스 토글 대안. |
| 입력 타이밍 조절 | Standard | Not Started | 타이밍 창 배수: 0.5x~3.0x. 기본값 1.0x. |

---

## Cognitive Accessibility

| Feature | Tier | Status | Notes |
|---------|------|--------|-------|
| 난이도 옵션 | Standard | Not Started | 단일 Easy/Normal/Hard 대신 피해 수치·적 공격성 개별 슬라이더 권장. |
| 언제든지 일시정지 | Basic | Not Started | 대화·컷씬·튜토리얼 중 포함 모든 상태에서 일시정지 가능. |
| 튜토리얼 영속성 | Standard | Not Started | 튜토리얼 팝업 닫은 후 메뉴 내 도움말 섹션에서 재열람 가능. |
| 퀘스트·목표 명확성 | Standard | Not Started | 현재 목표를 2번 이하 버튼으로 확인 가능. 전체 목표 텍스트 표시. |
| 오디오 전용 정보 시각 표시 | Standard | Not Started | 전투 경보·방향 오디오 등 화면 가장자리 인디케이터. |

---

## Auditory Accessibility

| Feature | Tier | Status | Notes |
|---------|------|--------|-------|
| 모든 대화 자막 | Basic | Not Started | 동료 NPC 전 대화 100% 자막. 타이밍 싱크 테스트 필수. |
| 독립 볼륨 조절 | Basic | Not Started | 음악·SFX·음성·UI 4개 버스 독립 슬라이더. 일시정지 메뉴에서도 접근 가능. |
| 보청기 호환 모드 | Standard | Not Started | 4kHz 초과 고주파 단독 정보 전달 큐 식별 및 저주파/시각 대안 제공. |

---

## Platform Accessibility

| Platform | 상태 | Notes |
|---------|------|-------|
| Steam (PC) | Not Started | Steam Input 게임패드 리바인딩 + 인게임 리바인딩 병행. |
| Steam Deck | Not Started | 마우스 호버 없이 모든 UI 동작 (technical-preferences.md). 전체 게임패드 지원 필수. |
| PC Screen Reader | Not Started | Godot 4.5+ AccessKit — 메뉴 내비게이션 스크린 리더 지원 검증 필요. |

---

## Per-Feature Accessibility Matrix

| 시스템 | 시각 우려 | 모터 우려 | 인지 우려 | 청각 우려 | 상태 |
|--------|----------|---------|---------|---------|------|
| 전투 시스템 | 체력바·적 표시 색상 의존 | 실시간 입력·회피 타이밍 | 동료 상태·쿨다운·적 패턴 동시 추적 | 공격 경보 오디오 | Not Started |
| 파티 매니저 | 파티 상태 색상 점 | 해당 없음 | 최대 4명 동료 상태 추적 | 해당 없음 | Not Started |
| 대화 시스템 | 자막 대비·가독성 | 해당 없음 | 분기 선택지·시간 제한 | 모든 대화 자막 필수 | Not Started |
| 인벤토리 | 아이템 등급 색상 테두리 | 해당 없음 (턴 기반) | 아이템 비교 다중 수치 | 해당 없음 | Not Started |
| 맵·탐색 | 맵 마커 색상 | 해당 없음 | 퀘스트 목표 명확성 | 목표 알림음 시각 대안 | Not Started |
| 입력 매핑 | 해당 없음 | **구현 완료** (ADR-0005) | 해당 없음 | 해당 없음 | ✅ |

---

## Known Intentional Limitations

| Feature | 미포함 이유 | 영향 | 완화 방안 |
|---------|-----------|------|---------|
| 인게임 월드 스크린 리더 | Godot 4.6 AccessKit이 메뉴만 커버. 월드 공간 설명 시스템은 별도 구현 필요. | 시각 장애 플레이어가 게임 월드를 독립적으로 탐색하기 어려움 | 모든 핵심 세계 정보를 퀘스트 로그·맵에 중복 제공. 포스트런치 DLC 검토. |
| 자막 폰트·색상 커스터마이즈 | Standard 티어 범위 외. Godot 커스텀 폰트 렌더링 추가 파이프라인 필요. | 난독증·시각 장애 플레이어의 자막 가독성 제한 | 기본·고가독성 2종 프리셋 제공 (포스트런치 업데이트 검토). |
| 단일 손 모드 | 실시간 전투 복잡도. 포스트런치 평가 예정. | 편마비 플레이어에게 실시간 전투 접근성 제한 | 턴 기반 전투 보조 모드 검토. |

---

## Open Questions

| 질문 | 담당 | 기한 |
|------|------|------|
| Godot 4.6 AccessKit이 HUD 요소 동적 업데이트를 지원하는가? | ux-designer | Pre-Production API 스파이크 시 |
| 대화 시스템에 시간 제한 선택지가 있는가? 있다면 타이밍 확장 지원 필요. | game-designer | Feature Sprint 1 대화 시스템 스토리 작성 시 |
| ~~색맹 팔레트가 아트 바이블 14색 마스터 팔레트와 충돌하는가?~~ | art-director | **해소됨 2026-05-16** — 충돌 없음. 달톤화 셰이더는 팔레트 외부 런타임 레이어. HP 바 예외(Rust Red→Warm Gold)는 기존 팔레트 색상 활용. 상세: `design/art/colorblind-palette.md` |
