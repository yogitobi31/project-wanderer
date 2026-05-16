# Sprint 5 — 2026-06-03 to 2026-06-16

## Sprint Goal

모든 Foundation + Core 레이어가 구현 완료된 상태에서, 전체 플레이어블 루프
(이동→전투→대화→포탈→저장→로드)를 엔드-투-엔드로 검증하고, Pillar 3 팀 게이트
설계 문서를 작성하여 M1 Exit Criteria 달성 기반을 마련한다.

## Capacity

- 총 일수: 10일 (솔로 개발자 — Juwon)
- 버퍼 (20%): 2일
- 가용: **8일**

---

## Tasks

### Must Have (Critical Path)

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|----|--------|------|------|--------|-----------|
| S5-1 | 플레이어블 루프 통합 검증 | godot-gdscript-specialist | 1.5일 | 모든 Core 에픽 완료 | `tests/integration/full_loop/` 에 end-to-end 통합 테스트 작성. 이동→전투→포탈 전환→저장→로드→파티 복원 전 사이클이 코드 상 검증됨 |
| S5-2 | S4-8 플레이테스트 세션 완료 | Juwon | 0.5일 | — | `production/qa/playtests/session-004-2026-05-16-juwon.md` 작성 완료. Top 3 Priorities 기록 |
| S5-3 | 플레이테스트 세션 2 (M1 ≥2회 요건) | Juwon | 0.5일 | S5-2 완료 후 | `production/qa/playtests/session-005-2026-06-*.md` 작성. 새 게임 시작 → 동료 영입 → 저장 → 재시작 → 복원 루프 집중 검증 |
| S5-4 | Pillar 3 팀 게이트 설계 문서 | game-designer | 1.0일 | — | `design/gdd/팀-게이트-조건.md` 작성. 팀 구성 조건 → 패스/잠금 해제 매커니즘 1종 이상 설계. MapScene 적용 규칙 포함 |

**Must Have 합계: 3.5일 / 가용 8일**

---

### Should Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|----|--------|------|------|--------|-----------|
| S5-5 | GDD-구현 일치 검증 | qa-lead | 1.0일 | — | 모든 구현된 시스템 GDD 대비 편차 목록 작성. `production/qa/gdd-alignment-sprint-5.md` 생성. 편차는 GDD 업데이트 또는 Known Deviation으로 기록 |
| S5-6 | MapScene 2 (두 번째 맵) 기초 설계 | level-designer | 1.0일 | S5-4 | `design/levels/map-02-forest.md` 작성. 팀 게이트 1개 포함한 레이아웃 초안. SpawnPoint·Portal·EnemySpawnZone 배치 계획 |
| S5-7 | M1 Exit Criteria 중간 점검 | Juwon | 0.5일 | S5-2, S5-3 | `production/milestones/M1.md` Exit Criteria 체크리스트 현황 업데이트. 미달 항목은 Sprint 6~7 배정 계획 기록 |

**Should Have 합계: 2.5일**

---

### Nice to Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|----|--------|------|------|--------|-----------|
| S5-8 | 동료 대화 콘텐츠 초안 (서린 · 돌쇠) | writer | 1.0일 | — | `design/narrative/dialogue/seo-rin-intro.md`, `dol-soe-intro.md` 작성. 영입 대화 3~5 교환 초안. DialogueManager 포맷 기준 |
| S5-9 | Risk Register 업데이트 | producer | 0.5일 | S5-5 완료 | R-08 (테스트 커버리지 기준) 해소 여부 확인. GDD 정렬 결과 기반 신규 위험 항목 추가 |

**Nice to Have 합계: 1.5일**

**전체 합계: 7.5일 / 가용 8일**

---

## Carryover from Sprint 4

| 태스크 | 이유 | 새 예상 |
|--------|------|---------|
| S4-8 플레이테스트 세션 (in-progress) | Juwon 직접 플레이 + 기록 미완료 | S5-2로 흡수 (0.5일) |

---

## Risks

| 위험 | 확률 | 영향 | 완화 |
|------|------|------|------|
| 통합 테스트에서 Autoload 초기화 순서 버그 발견 | Medium | High | ADR-0002 순서 확인 후 GUT mock 주입으로 격리 테스트 |
| Pillar 3 팀 게이트 설계가 Core 루프와 충돌 | Low | High | 설계 전 GDD 의존성 섹션 교차 확인; CD 리뷰 요청 |
| 솔로 개발자 플레이테스트 2회 스케줄 확보 실패 | Medium | Medium | M1 exit criteria 블로킹 — Sprint 6 앞으로 당기는 것으로 완화 |

---

## Dependencies on External Factors

- Godot 4.6 에디터에서 NavigationRegion2D bake + TileMapLayer 호환성 수동 확인 필요
  (ADR-0003 Verification Required 미해소 항목)

---

## Definition of Done for this Sprint

- [ ] 모든 Must Have 태스크 완료
- [ ] `tests/integration/full_loop/` 통합 테스트 CI green
- [ ] 플레이테스트 ≥2회 기록 (`production/qa/playtests/`)
- [ ] Pillar 3 팀 게이트 설계 문서 작성 완료
- [ ] QA plan 존재 (`production/qa/qa-plan-sprint-5-*.md`)
- [ ] Smoke check 통과 (`/smoke-check sprint`)
- [ ] S1·S2 버그 없음
- [ ] M1.md Exit Criteria 체크리스트 업데이트

---

## 참고

- 이전 스프린트: `production/sprints/sprint-4.md`
- 마일스톤: `production/milestones/M1.md` (Target: 2026-07-11)
- Risk Register: `production/risk-register/register.md`
- Sprint 5 대상 에픽: Foundation + Core 전체 Complete 확인 (2026-05-16 기준)
  → Sprint 5는 통합 검증 + 플레이테스트 + Pillar 3 설계로 피벗
