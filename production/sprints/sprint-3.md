# Sprint 3 — 2026-05-20 to 2026-06-03

## Sprint Goal

Gate CONCERNS 해소 + Production 기반 확립 — 성능 기준선 수립, 인프라 검증,
디자인 갭 정리 완료, 첫 Production Feature 착수.

## Capacity

- 총 일수: 10일 (솔로 개발자 — Juwon)
- 버퍼 (20%): 2일
- 가용: **8일**

---

## Tasks

### Must Have (Critical Path)

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S3-1 | systems-index 6개 GDD 상태 동기화 | Juwon | 0.5일 | — | index "Needs Revision" 6개 항목이 개별 파일 실제 상태와 일치. Last Updated 갱신. |
| S3-2 | CI/CD 실제 PR 검증 (arch.md doc-fix PR 오픈) | devops-engineer | 0.5일 | — | GitHub Actions 워크플로우가 PR 트리거로 실행 → green check 확인됨 |
| S3-3 | Vertical Slice 성능 기준선 수립 (`/perf-profile`) | Juwon (직접 실행) | 1일 | Godot 실행 환경 | `production/qa/baselines/perf-baseline-2026-05.md` 생성. frame time p50/p95, draw call 최대값, 메모리 스냅샷 수치 기록. |
| S3-4 | NavigationAgent2D 9-agent 스트레스 테스트 + ADR-0006 avoidance 결정 | ai-programmer | 1일 | S3-3 | 9-agent 테스트 결과 기록. ADR-0006 업데이트 (avoidance on/off 결정 + 근거 데이터). FOLLOW_STOP_DISTANCE 60~80px 조정 적용. |

**Must Have 합계: 3일 / 가용 8일**

---

### Should Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S3-5 | `/ux-review` 재실행 (hud, main-menu, pause) → APPROVED 공식 기록 | ux-designer | 0.5일 | — | 3개 spec APPROVED verdict 파일 기록. spec Status "Reviewed" → "Approved" 업데이트. |
| S3-6 | 색맹 대체 팔레트 ↔ 14색 마스터 팔레트 충돌 해결 | art-director | 0.5일 | — | Protanopia/Deuteranopia/Tritanopia 대체색 명시. 팔레트 예외 여부 결정 문서화 (`design/art/colorblind-palette.md`). |
| S3-7 | MVP 동료 3명 개별 비주얼 프로필 작성 | art-director | 1일 | S3-6 | `design/art/characters/[companion-name].md` 3개 생성. 각각 실루엣 축, 14색 팔레트 내 주 색상, 역할 신호 요소, idle 포즈 설명 포함. |
| S3-8 | SaveManager 구현 (첫 Production Feature) | godot-gdscript-specialist | 1일 | Foundation ADRs | GUT 테스트 통과. SAVE_VERSION=1 직렬화 계약 검증. 씬 전환 + 파티 상태 저장/로드 동작. |
| S3-9 | VIS-2 적 사망 AnimationPlayer 구현 | godot-gdscript-specialist | 0.5일 | EnemyAI | 적 DEAD 전환 시 애니메이션 재생 후 제거. 즉시 사라짐 현상 없음. GUT 테스트 통과. |

**Should Have 합계: 3.5일**

---

### Nice to Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S3-10 | B-001 대각선 이동 스프라이트 8방향 전환 | godot-gdscript-specialist | 0.5일 | PlayerController | 대각선 이동 시 8방향 스프라이트 전환. 기존 4방향 고정 현상 해소. |
| S3-11 | BUG-0001 push_warning → push_error 수정 | godot-gdscript-specialist | 0.5일 | — | 해당 호출 전부 push_error로 교체. GUT 전체 통과. |

**Nice to Have 합계: 1일**

**스프린트 총 스코프: 3 + 3.5 + 1 = 7.5일 / 가용 8일** ✅

---

## 이전 스프린트 캐리오버

| 태스크 | 이유 | 처리 |
|---|---|---|
| B-003 CompanionAI 통로 겹침 | Sprint 2 Medium 버그 | S3-4에 통합 (avoidance 결정으로 해소) |
| B-001 대각선 스프라이트 | Sprint 2 Low 버그 | S3-10 (Nice to Have) |

---

## Risks

| 리스크 | 확률 | 영향 | 완화 |
|---|---|---|---|
| S3-3 perf-profile — Godot 에디터 직접 실행 필요 (Claude Code 자동화 불가) | HIGH | MEDIUM | Juwon이 직접 실행 + 수치만 기록 파일로 넘김 |
| S3-4 avoidance 활성화 시 성능 초과 | LOW-MEDIUM | HIGH | S3-3 기준선 먼저 확보 후 결정 |
| S3-7 동료 비주얼 프로필 — 미확정 동료 이름/컨셉 | MEDIUM | MEDIUM | art-director와 game-concept.md 기반으로 가칭+원형 확정 |
| 솔로 개발자 피로 — 44스토리 이후 첫 스프린트 | MEDIUM | MEDIUM | 8일 가용 중 7.5일 스코프 — 0.5일 여유 유지 |

---

## Dependencies on External Factors

- **S3-3**: Juwon이 Godot 4.6 에디터에서 직접 실행 필요
- **S3-2**: GitHub repository에 실제 PR 오픈 필요 (`gh pr create` 명령 사용)

---

## Definition of Done for this Sprint

- [ ] Must Have (S3-1~S3-4) 전부 완료
- [ ] 모든 Logic/Integration 스토리 GUT 테스트 통과
- [ ] `production/qa/baselines/perf-baseline-2026-05.md` 존재
- [ ] ADR-0006 avoidance 결정 업데이트
- [ ] systems-index Last Updated 갱신 및 상태 동기화
- [ ] CI/CD green check 확인 완료
- [ ] S1/S2 버그 없음
- [ ] Design documents updated for any deviations

---

> ⚠️ **No QA Plan**: Sprint 3는 QA 플랜 없이 시작됩니다. Must Have 태스크 완료 후
> `/qa-plan sprint` 실행을 권장합니다. Production → Polish 게이트는 QA 사인오프가 필요합니다.
