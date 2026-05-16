# 색맹 팔레트 결정: 유랑단

> **Status**: Resolved
> **Author**: art-director
> **Date**: 2026-05-16
> **Resolves**: design/accessibility-requirements.md Open Question #3

---

## 결론

**충돌 없음.** 14색 마스터 팔레트 제약은 아트 프로덕션 에셋(스프라이트, 타일셋)에만 적용된다.
색맹 모드는 런타임 렌더링 레이어로 구현되며, 팔레트에 새로운 색상을 추가하지 않는다.
팔레트 내 예외 1개(HP 바 색맹 모드 교체)가 명시적으로 문서화된다.

---

## 구현 방식

### 1차 메커니즘 — 화면 공간 달톤화 셰이더

`CanvasLayer` + `ColorRect` 또는 `WorldEnvironment` 후처리 셰이더로
전체 화면 출력에 달톤화 보정 행렬을 적용한다.
이 방식은 스프라이트 팔레트를 변경하지 않으며, 색맹 모드가
꺼져 있을 때는 완전히 비활성화된다.

### 2차 메커니즘 — HP 바 명시적 색상 교체 (예외 1개)

Protanopia/Deuteranopia 모드에서 HP 바 저체력 색상을
코드(HUD/HealthComponent)에서 교체한다.

---

## 색맹 모드별 명세

### Protanopia (제1색맹 — 적색 불인식)

| 구분 | 내용 |
|---|---|
| 주요 문제 | Rust Red `#8C3A2A`(저체력)가 Stone Dust `#2A2520` 배경과 유사한 어두운 갈색으로 수렴 |
| 셰이더 | Viénot 1999 Protanopia 달톤화 보정 행렬 |
| HP 바 교체 | 저체력 Rust Red → **Warm Gold `#E8B840`** (팔레트 내, 색맹 모드 전용) |
| 비색상 백업 | HP 수치 항상 표시, 동료 사망 X 아이콘, 위험 임박 시 깜빡임 |

### Deuteranopia (제2색맹 — 녹색 불인식)

| 구분 | 내용 |
|---|---|
| 주요 문제 | Rust Red `#8C3A2A`와 Worn Sage `#5A6E48`가 모두 탁한 황갈색으로 수렴 |
| 셰이더 | Brettel 1997 Deuteranopia 달톤화 보정 행렬 |
| HP 바 교체 | 저체력 Rust Red → **Warm Gold `#E8B840`** (Protanopia와 동일) |
| 적/아군 구분 | 색상 교체 불필요 — 형태 신호로 해소 (아트 바이블 Section 3.1/3.2: 적 가로 실루엣 vs 아군 세로 실루엣) |
| 비색상 백업 | HP 수치, X 아이콘, 깜빡임 |

### Tritanopia (제3색맹 — 청색 불인식)

| 구분 | 내용 |
|---|---|
| 주요 문제 | Dusk Iron `#3A4A5C`(적 신호)가 보라 방향으로 이동 |
| 셰이더 | Brettel 1997 Tritanopia 달톤화 보정 행렬 |
| HP 바 교체 | **불필요** — Rust Red는 난색 계열로 Tritanopia 영향 미미 |
| 적 신호 | Dusk Iron의 보라 방향 이동이 Ember Amber(아군)와의 구분을 오히려 강화 |
| 비색상 백업 | 동일 |

---

## 팔레트 예외 정의

Protanopia/Deuteranopia 모드에서 HP 바 저체력 채우기 색상을
**코드에서 Warm Gold `#E8B840`으로 교체**한다.

| 항목 | 내용 |
|---|---|
| 교체 전 | Rust Red `#8C3A2A` |
| 교체 후 | Warm Gold `#E8B840` |
| 구현 위치 | `src/ui/hud/health_bar.gd` — 색맹 모드 설정값 읽어 동적 교체 |
| 적용 범위 | 색맹 모드 활성 시 전용. 기본 모드에서 Warm Gold는 "보상" 시맨틱 유지. |
| 팔레트 추가 여부 | 없음 — Warm Gold는 이미 Reserved Signal Band에 포함 |

---

## 확인: 14색 팔레트 제약 준수

| 대상 | 결정 |
|---|---|
| 스프라이트 아트 | 변경 없음 — 14색 제약 그대로 유지 |
| 타일셋 아트 | 변경 없음 |
| 셰이더 달톤화 출력 | 런타임 변환 — 아트 팔레트 제약 범위 외 |
| HP 바 코드 교체 | 팔레트 내 기존 색상(Warm Gold) 사용 — 신규 색상 추가 없음 |

**신규 색상 추가: 0개. 팔레트 제약 위반: 없음.**

---

## Open Question 처리

`design/accessibility-requirements.md` Open Question #3 해소:

> "색맹 팔레트가 아트 바이블 14색 마스터 팔레트와 충돌하는가?"
>
> **→ 충돌 없음.** 달톤화 셰이더는 팔레트 외부 레이어. HP 바 예외는 기존 팔레트 색상 활용.
> 담당 art-director, 해소일: 2026-05-16.
