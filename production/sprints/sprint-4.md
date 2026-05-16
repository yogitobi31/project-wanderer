# Sprint 4 — 2026-05-19 to 2026-06-02

## Sprint Goal

Production Phase 첫 스프린트 — 관리 기반 확립(Milestone·Risk Register)과 SaveManager 구현으로
씬 전환 간 파티 지속성을 확보하고, Foundation epic 착수를 시작한다.

## Capacity

- 총 일수: 10일 (솔로 개발자 — Juwon)
- 버퍼 (20%): 2일
- 가용: **8일**

---

## Tasks

### Must Have (Critical Path)

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S4-1 | M1 밀스톤 정의 | Juwon | 0.5일 | — | `production/milestones/M1.md` 작성. scope envelope, 성공 기준, 타겟 날짜, Pillar 3 검증 일정 포함. |
| S4-2 | Risk register 생성 | producer | 0.5일 | — | `production/risk-register/register.md` 생성. 최소 5개 항목. |
| S4-3 | 플레이어 캐릭터 비주얼 프로필 생성 | art-director | 0.5일 | — | `design/art/characters/player.md` 생성. art-bible 섹션 5.1 기반. 실루엣 스펙, 색상 할당, idle 포즈 스펙, prohibition list 포함. |
| S4-4 | SaveManager 구현 (첫 Production Feature) | godot-gdscript-specialist | 1.5일 | ADR-0007 | `src/core/save_manager.gd` 구현. SAVE_VERSION=1 직렬화 계약. GUT 단위 테스트 통과. 씬 전환 후 파티 상태 복원 확인. |

**Must Have 합계: 3.0일 / 가용 8일**

---

### Should Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S4-5 | 문서 상태 정리 (art-bible + 동료 프로필) | art-director | 0.5일 | — | art-bible.md Status "Complete" + dated sign-off. seo-rin/dol-soe/ma-ru Draft → Approved. |
| S4-6 | VIS-2 적 사망 AnimationPlayer 구현 (S3-9 carryover) | godot-gdscript-specialist | 0.5일 | EnemyAI | 적 DEAD 전환 시 애니메이션 재생 후 제거. 즉시 사라짐 현상 없음. GUT 통과. |
| S4-7 | EventBus Foundation epic — story-001 구현 | godot-gdscript-specialist | 1.0일 | — | `production/epics/event-bus/story-001-autoload-signal-contract.md` 기준. autoload 등록, 신호 계약 GUT 단위 테스트 통과. |
| S4-8 | Production 플레이테스트 세션 1회 | Juwon | 0.5일 | S4-4 권장 | `production/playtests/session-004-2026-05-xx.md` 생성. SaveManager 포함 빌드 기준. |

**Should Have 합계: 2.5일**

---

### Nice to Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S4-9 | 대각선 이동 스프라이트 8방향 전환 (S3-10 carryover) | godot-gdscript-specialist | 0.5일 | PlayerController | 대각선 이동 시 8방향 스프라이트 전환. B-001 버그 해소. |
| S4-10 | BUG-0001 push_warning → push_error 수정 (S3-11 carryover) | godot-gdscript-specialist | 0.5일 | — | 해당 호출 전부 push_error로 교체. GUT 전체 통과. |

**Nice to Have 합계: 1.0일**

**스프린트 총 스코프: 3.0 + 2.5 + 1.0 = 6.5일 / 가용 8일** ✅

---

## Carryover from Sprint 3

| 태스크 | Sprint 3 상태 | Sprint 4 처리 |
|---|---|---|
| S3-5 UX review 3종 | 백로그 (실제 완료) | ✅ done — UX 파일 Status: Approved 확인됨 |
| S3-6 색맹 팔레트 | 백로그 (실제 완료) | ✅ done — colorblind-palette.md 존재 확인됨 |
| S3-7 동료 비주얼 프로필 | 백로그 (실제 완료) | ✅ done — 3종 파일 존재. Draft→Approved는 S4-5 |
| S3-8 SaveManager | 백로그 | → S4-4 Must Have 승격 |
| S3-9 AnimationPlayer | 백로그 | → S4-6 Should Have |
| S3-10 대각선 스프라이트 | 백로그 | → S4-9 Nice to Have |
| S3-11 push_warning | 백로그 | → S4-10 Nice to Have |

---

## Risks

| Risk | 확률 | 영향 | 완화 |
|---|---|---|---|
| SaveManager 직렬화 계약이 ADR-0007보다 복잡해질 수 있음 | 중 | 높음 | ADR-0007 계약 범위를 SAVE_VERSION=1으로 엄격히 제한. 씬/파티 상태만 저장. |
| M1 밀스톤 정의가 scope creep 유발 가능 | 중 | 중 | M1 scope는 Foundation+Core 레이어 완성까지로 제한. Feature 레이어는 M2. |
| Solo dev capacity — 킥오프 아이템 + SaveManager 동시 진행 | 중 | 중 | Day 0~1(S4-1~3) 완료 후 S4-4 시작. 병렬 진행 금지. |
| EventBus story-001 구현 시 Godot 4.6 Signal post-cutoff 이슈 | 낮 | 중 | engine-reference 참조 후 착수. |

---

## Dependencies on External Factors

- GitHub Actions (yogitobi31/project-wanderer) — CI 가용성
- Godot 4.6 에디터 — SaveManager 씬 전환 수동 테스트

---

## Definition of Done for Sprint 4

- [ ] S4-1~S4-4 (Must Have) 전체 완료
- [ ] `production/milestones/M1.md` 존재 및 내용 완성
- [ ] `production/risk-register/register.md` 존재 및 5개+ 항목
- [ ] `design/art/characters/player.md` 존재
- [ ] SaveManager GUT 단위 테스트 통과
- [ ] QA plan 존재 (`production/qa/qa-plan-sprint-4.md`)
- [ ] Logic/Integration 스토리 GUT 테스트 통과
- [ ] Smoke check PASS
- [ ] QA sign-off: APPROVED or APPROVED WITH CONDITIONS
- [ ] S1, S2 버그 없음
- [ ] 설계 문서가 편차 반영해 업데이트됨
- [ ] 코드 리뷰 및 머지 완료

---

> ⚠️ **No QA Plan**: QA plan 없이 스프린트를 시작합니다. `/qa-plan sprint`를 마지막 스토리 구현 전에 반드시 실행하세요. Production → Polish 게이트는 QA sign-off 리포트가 필요하며, 이는 QA plan 없이는 생성 불가합니다.

> **PR-SPRINT skipped — Lean mode.**

> **Scope check:** Foundation epic(EventBus)이 Sprint 4에 새로 추가됩니다. 구현 시작 전 `/scope-check event-bus`를 실행하여 scope creep 여부를 확인하세요.
