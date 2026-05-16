# Sprint 2 — 2026-05-07 to 2026-05-20

## Sprint Goal

B2 API 스파이크 4개 결과 기록 + Foundation 레이어 스토리 생성 + 첫 3개 Foundation 시스템 구현 착수

## Capacity

- 총 일수: 10일 (솔로 개발자 — Juwon)
- 버퍼 (20%): 2일
- 가용: **8일**

---

## Tasks

### Must Have (Critical Path)

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S2-1 | API 스파이크 4개 Godot 실행 + 결과 기록 | Juwon (직접 실행) | 1일 | Godot 4.6 환경 | `production/spikes/` 4개 README에 결과 기록 완료 |
| S2-2 | Foundation 에픽 스토리 생성 (`/create-stories` × 6) | godot-gdscript-specialist | 1일 | Foundation 에픽 6개 ✅ | 6개 에픽 각 stories 파일 생성 완료 |
| S2-3 | EventBus 구현 | godot-gdscript-specialist | 0.5일 | S2-2 | GUT 단위 테스트 통과 |
| S2-4 | NPCRegistry 구현 | godot-gdscript-specialist | 1일 | S2-2 | GUT 단위 테스트 통과 |
| S2-5 | PartyManager 구현 | godot-gdscript-specialist | 1일 | S2-4 | GUT 단위 테스트 통과 |

**Must Have 합계: 4.5일 / 가용 8일**

---

### Should Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S2-6 | ItemDB 구현 | godot-gdscript-specialist | 0.5일 | S2-2 | GUT 단위 테스트 통과 |
| S2-7 | InputMapManager 구현 | godot-gdscript-specialist | 1일 | S2-2 | GUT 단위 테스트 통과, 리바인딩 ConfigFile 저장 |
| S2-8 | CI/CD 워크플로우 완성 (`.github/workflows/`) | devops-engineer | 0.5일 | — | PR 시 GUT 자동 실행 확인 |

**Should Have 합계: 2일**

---

### Nice to Have

| ID | 태스크 | 담당 | 예상 | 의존성 | 완료 기준 |
|---|---|---|---|---|---|
| S2-9 | SceneTransitionManager 구현 | godot-gdscript-specialist | 1일 | S2-2, S2-3 | 씬 전환 FSM GUT 테스트 통과 |
| S2-10 | Core 에픽 스토리 생성 (`/create-stories` × 7) | godot-gdscript-specialist | 0.5일 | Core 에픽 7개 ✅ | 7개 에픽 stories 파일 생성 완료 |

---

## 이전 스프린트 캐리오버

없음 (Sprint 2가 첫 구현 스프린트).

---

## Risks

| 리스크 | 확률 | 영향 | 완화 |
|---|---|---|---|
| B2 스파이크 — TileMapLayer + NavigationAgent2D가 HIGH RISK로 판명 | MEDIUM | HIGH | ADR 업데이트 후 MapScene/CompanionAI 에픽 스코프 조정 |
| B2 스파이크 — grab_focus() dual-focus 문제 Godot 4.6에서 확인 | MEDIUM | MEDIUM | ADR-0003 폴백(ui_accept) 이미 명시 — 추가 대응 불필요 |
| Foundation 구현 중 Godot 4.6 API 호환성 문제 | LOW | MEDIUM | `docs/engine-reference/godot/deprecated-apis.md` + control-manifest 참조 |

---

## Dependencies on External Factors

- **S2-1**: Juwon이 Godot 4.6 에디터에서 직접 실행 필요 — Claude Code에서 자동화 불가
- **S2-8**: `.github/workflows/` 파일 이미 존재 (git status 확인) — 완성 여부 검증 필요

---

## Definition of Done for this Sprint

- [ ] All Must Have tasks (S2-1 ~ S2-5) completed
- [ ] All Logic/Integration stories have passing GUT tests in `tests/`
- [ ] API 스파이크 4개 결과 `production/spikes/` README에 기록
- [ ] QA plan exists or `/qa-plan sprint` run before last story implemented
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations from ADRs
- [ ] Code reviewed and merged to main

---

> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.
