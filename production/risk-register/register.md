# Risk Register — 유랑단

**Created**: 2026-05-16  
**Phase**: Production  
**Owner**: Juwon  
**Review Cadence**: 매 스프린트 시작 시 검토 + 신규 위험 추가

---

## 활성 위험 목록

| ID | 위험 | 확률 | 영향 | 심각도 | 완화 | 상태 |
|---|---|---|---|---|---|---|
| R-01 | Solo-dev 번아웃 | 중 | 높음 | 🔴 HIGH | 스프린트 버퍼 20% 유지. 주 1회 이상 쉬는 날 확보. 스코프 과부하 즉시 defer. | Active |
| R-02 | SaveManager 직렬화 계약 범위 초과 | 중 | 높음 | 🔴 HIGH | ADR-0007 SAVE_VERSION=1 엄격 제한. 각 Autoload의 get_save_data() 반환 구조를 MVP 최소로 고정. | Active |
| R-03 | 플레이테스트 케이던스 붕괴 | 높음 | 중 | 🟡 MEDIUM | 스프린트별 최소 1회 플레이테스트 커밋. production/playtests/ 미기록 시 sprint-status 블로킹. | Active |
| R-04 | Scope creep — Foundation 완성 전 Feature 스토리 착수 | 중 | 높음 | 🔴 HIGH | Foundation 레이어 완전 완료 전 Core 이상 착수 금지 원칙. 위반 시 /scope-check 즉시 실행. | Active |
| R-05 | 아트 파이프라인 지연 — 플레이스홀더 기간 연장 | 높음 | 중 | 🟡 MEDIUM | 코드 로직과 아트 에셋을 분리. 플레이스홀더로 모든 Logic/Integration 테스트 완료 가능하도록 설계. 아트는 별도 마일스톤 추적. | Active |
| R-06 | Godot 4.6 post-cutoff API 미검증 구역 발생 | 낮음 | 높음 | 🟡 MEDIUM | 신규 API 사용 전 docs/engine-reference/godot/ 참조 필수. 미검증 영역은 spike prototype 먼저. | Active |
| R-07 | Foundation Autoload 초기화 순서 버그 | 낮음 | 높음 | 🟡 MEDIUM | ADR-0002 순서 엄수. project.godot 변경 시 PR 리뷰 필수. CI에서 초기화 순서 자동화 검증 추가 고려. | Active |
| R-08 | 테스트 커버리지 기준 미정의 → 구멍 누적 | 중 | 중 | 🟡 MEDIUM | Sprint 4 종료 전 qa-lead와 최소 커버리지 기준 정의. Logic 스토리 100%, Integration 스토리 핵심 경로 100% 목표. | Active |
| R-09 | StringName ↔ String JSON 타입 불일치 (SaveManager) | 중 | 중 | 🟡 MEDIUM | ADR-0007: load_save_data() 구현 시 StringName() 명시적 캐스팅 필수. 단위 테스트 엣지케이스에 포함. | Active |
| R-10 | Pillar 3 (Team Unlocks World) 검증 지연 → 비전 드리프트 | 중 | 높음 | 🔴 HIGH | M1 계획에 Sprint 6 첫 팀 게이트 프로토타입 명시. 지연 시 CD에 즉시 에스컬레이션. | Active |

---

## 해소된 위험

| ID | 위험 | 해소일 | 해소 방법 |
|---|---|---|---|
| R-CLOSED-01 | Godot 4.4/4.5/4.6 API 호환성 미검증 | 2026-05-15 | 4개 spike prototype으로 HIGH/MEDIUM 위험 전체 실증 검증 완료 |
| R-CLOSED-02 | CI/CD 미구축 → 회귀 미탐지 | 2026-05-16 | GitHub Actions (yogitobi31/project-wanderer) GUT 516/518 PASS |
| R-CLOSED-03 | 플레이테스트 0세션 → 코어 루프 재미 미검증 | 2026-05-16 | Session 001~003 완료. Earned Fellowship + Visible Snowball 검증됨 |
| R-CLOSED-04 | NavigationAgent2D avoidance 성능 미검증 | 2026-05-16 | 9에이전트 스트레스 테스트 완료. avoidance ON 0fps 차이 확인 |

---

## 위험 추가 방법

새 위험 발견 시:
1. 이 파일에 새 행 추가 (R-NN 순번)
2. 확률 / 영향 / 심각도 / 완화 방법 기입
3. 해당 스프린트의 Risks 섹션에도 반영
4. 해소 시 "활성 위험" → "해소된 위험"으로 이동 후 해소일·방법 기록

**심각도 계산**: 확률(높=3, 중=2, 낮=1) × 영향(높=3, 중=2, 낮=1)  
- 🔴 HIGH: 6~9  
- 🟡 MEDIUM: 3~5  
- 🟢 LOW: 1~2
