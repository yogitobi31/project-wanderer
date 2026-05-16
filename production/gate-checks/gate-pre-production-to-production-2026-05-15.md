# Gate Check: Pre-Production → Production

**Date**: 2026-05-15
**Checked by**: gate-check skill (claude-sonnet-4-6)
**Review mode**: lean
**Stage file**: `production/stage.txt` → Pre-Production
**Previous gate attempt**: 2026-05-06 — FAIL

---

## Required Artifacts: 9/15 PASS · 3 PARTIAL · 3 FAIL

| # | Artifact | Status | Notes |
|---|---------|--------|-------|
| 1 | Prototype in `prototypes/` with README | ✅ PASS | 4 spikes: spike-duplicate-deep, spike-navigation-agent, spike-grab-focus, spike-tilemaplayer — all with READMEs |
| 2 | Sprint plan in `production/sprints/` | ✅ PASS | `production/sprints/sprint-2.md` |
| 3 | Art bible complete (all 9 sections) | ✅ PASS | 10 sections present. AD-ART-BIBLE: "Skipped — Lean mode (2026-04-16)" — acceptable in lean mode |
| 4 | Character visual profiles for key characters | ⚠️ PARTIAL | Art bible Section 5.1 has Player Character Visual Archetype + companion silhouette rules. No separate per-character profile files. ADVISORY. |
| 5 | All MVP-tier GDDs complete | ⚠️ PARTIAL | `systems-index.md` lists 6 as "Needs Revision" (플레이어-컨트롤러, 체력/데미지, 동료-AI, 대화, 퀘스트, 동료-영입-퀘스트). However, individual GDD files show `Status: Reviewed` — systems-index is stale. Reconciliation required. |
| 6 | Master architecture document | ✅ PASS | `docs/architecture/architecture.md` |
| 7 | At least 3 Foundation-layer ADRs | ✅ PASS | 7 ADRs (ADR-0001~0007), all Accepted, all with Engine Compatibility + ADR Dependencies sections |
| 8 | Control manifest | ✅ PASS | `docs/architecture/control-manifest.md` |
| 9 | Epics: Foundation + Core layers present | ✅ PASS | 14 epics across Foundation + Core + Feature. 44+ stories, all completed. |
| 10 | Vertical Slice build exists and is playable | ⚠️ PARTIAL | Code structurally implemented (CI 516/518 PASS). Smoke check: PASS WITH WARNINGS. No documented player-facing playtest evidence. |
| 11 | Vertical Slice playtested ≥ 3 sessions | ❌ FAIL | User confirmed: 1-2 informal developer tests only. Gate requires 3 documented sessions. |
| 12 | Vertical Slice playtest report | ❌ FAIL | `production/playtests/` directory does NOT EXIST. No playtest report of any kind. |
| 13 | UX specs: main menu, core HUD, pause menu | ✅ PASS | `design/ux/main-menu.md`, `design/ux/hud.md`, `design/ux/pause.md` — all exist with substantive content |
| 14 | HUD design document | ✅ PASS | `design/ux/hud.md` — Status: Draft Complete |
| 15 | All key UX specs passed /ux-review | ❌ FAIL | Status: "Draft Complete" on all three. User confirmed: only some reviewed, none with APPROVED verdict. |

---

## Quality Checks: 3/7 PASS · 2 MANUAL · 2 FAIL

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Tests passing | ✅ PASS | CI run 2026-05-15: 516/518 PASS, 0 failures, 2 risky (hardware-dependent, non-blocking) |
| 2 | Core loop fun validated | ❌ FAIL | User confirmed: "아직 검증 안 됨" |
| 3 | UX specs cover all UI Requirements from GDDs | ❓ MANUAL | Not verified |
| 4 | Interaction pattern library documented | ✅ PASS | `design/ux/interaction-patterns.md` exists |
| 5 | Accessibility tier addressed in UX specs | ❓ MANUAL | `design/accessibility-requirements.md` exists — UX spec alignment not verified |
| 6 | Vertical Slice COMPLETE (start→challenge→resolution) | ❌ FAIL | No documented play session. Only 1-2 informal developer tests (user confirmed). |
| 7 | Architecture no unresolved Foundation open questions | ✅ PASS | All 7 ADRs Accepted. API spikes resolved. |

---

## Vertical Slice Validation (Auto-FAIL triggers)

> Per gate definition: if any item is FAIL, verdict is automatically FAIL regardless of other checks.

| Item | Status | Notes |
|------|--------|-------|
| Human played core loop without developer guidance | ⚠️ PARTIAL | 1-2 informal plays — short of 3 sessions, and not documented |
| Game communicates what to do within 2 minutes | ❓ MANUAL | Not tested |
| No critical "fun blocker" bugs | ✅ PASS | QA sign-off: 0 S1/S2 bugs. Smoke check: PASS WITH WARNINGS. |
| Core mechanic feels good (fun validated) | ❌ **FAIL** | User: "아직 검증 안 됨" — **Auto-FAIL trigger** |

**→ Auto-FAIL condition met.** Core mechanic fun is unvalidated. Per gate definition, verdict is FAIL regardless of other checks.

---

## Director Panel Assessment

> Review mode: lean — all four directors run at phase gates.

**Creative Director: CONCERNS**
> Pillars are coherently represented across artifacts. Core loop fun unvalidated is the top creative risk — for a pillar-driven RPG, entering Production without playtest creates risk that mechanical investment outpaces emotional validation. Systems-index inconsistency (6 stale "Needs Revision") and UX specs at Draft Complete are early-Production items, not blockers.

**Technical Director: CONCERNS**
> Architecture is sound. 7 ADRs cover all critical domains. HIGH-risk APIs spiked and passing. Concerns: (1) performance budgets aspirational not measured — baseline profiling pass needed in sprint 1; (2) NavigationAgent2D not stress-tested at game load (3+ companions + 4 enemies); (3) CI/CD workflow exists but not verified end-to-end.

**Producer: CONCERNS**
> Solo dev velocity is proven (all sprint 2 stories landed, CI green). Primary risks: 6 GDDs in revision state are upstream of Production sprint stories; Sprint 3 not planned; playtest gap inflates production risk. Two conditions before Production work begins: reconcile 6 GDD revisions; run ≥1 external playtest.

**Art Director: CONCERNS**
> Visual identity is established and functional for production start. Top risk: no per-character visual profiles — first companion sprite produced becomes an undocumented precedent, causing palette drift. Asset spec sheets absent. UX specs need AD review before UI assets are commissioned.

**Panel result: CONCERNS × 4 (no NOT READY)**

---

## Blockers

### [BLOCKER-1] Vertical Slice playtested < 3 documented sessions
Only 1-2 informal developer tests. Gate requires ≥3 documented sessions with a human player operating without guidance. This is the #1 predictor of production failure per GDC postmortem data — systems polished before fun-validation frequently require full rework.

**Action**: Create `production/playtests/` directory. Document 2+ additional sessions (developer self-play counts if structured — date, scenario, observations, fun hypothesis result). Minimum 3 entries total.

### [BLOCKER-2] Playtest report missing
`production/playtests/` directory does not exist. No formal playtest report at any path.

**Action**: Run `/playtest-report` after playtest sessions. File at `production/playtests/playtest-sprint2-[date].md`.

### [BLOCKER-3] Core loop fun unvalidated (Vertical Slice auto-FAIL)
User confirmed: "아직 검증 안 됨." Gate definition requires at least one playtester to independently describe an experience matching the Player Fantasy. This triggers the automatic FAIL condition.

**Action**: After playtesting, document whether any tester (or developer) spontaneously described Pillar 1 ("작지만 진짜인 이야기") or Pillar 2 ("팀이 곧 열쇠다") level experiences — without prompting. Record this in the playtest report.

### [BLOCKER-4] UX specs not APPROVED via /ux-review
All three UX specs (main-menu, hud, pause) are "Draft Complete" — none have passed `/ux-review`. Gate requires all key screen UX specs to have passed with APPROVED or NEEDS REVISION ACCEPTED verdict.

**Action**: Run `/ux-review design/ux/hud.md` (highest priority — this is where Pillar 3 lives). Then main-menu and pause. All three must reach APPROVED or user-accepted NEEDS REVISION before gate re-check.

---

## Recommendations (Not Blocking)

| Priority | Item | Action |
|----------|------|--------|
| HIGH | Systems-index stale (6 GDDs show "Needs Revision" in index, "Reviewed" in files) | Update `design/gdd/systems-index.md` status column to match individual GDD files before Sprint 3 planning |
| HIGH | Sprint 3 not planned | Run `/sprint-plan` after blocker resolution — use sprint 3 to schedule performance baseline + NavAgent stress test (TD requests) |
| MEDIUM | Per-character visual profiles missing | Create profile docs for first 3-5 recruitable companions before character art begins |
| MEDIUM | Performance budgets unvalidated | Add profiling story to sprint 3: capture baseline frame time / draw calls / memory on representative scene |
| MEDIUM | NavigationAgent2D avoidance not stress-tested | Add stress-test story before any combat-heavy feature sprints: 3 companions + 4 enemies, avoidance enabled, measure fps convergence |
| LOW | CI/CD workflow unverified | Confirm `.github/workflows/` runs end-to-end on a PR |
| LOW | Asset spec sheets absent | Run `/asset-spec` before first art production sprint |
| LOW | VIS-2: AnimationPlayer 미추가 | Schedule in Sprint 3 — PlayerController.tscn AnimationPlayer 추가 |
| LOW | VIS-3: DialogueManager typing screenshot | 20-minute task — `production/qa/evidence/dialogue-typing.png` |
| LOW | BUG-0001: push_warning vs push_error | Sprint 3 backlog |

---

## Chain-of-Verification

5 challenge questions checked for FAIL draft:
1. **Hard blockers vs. strong recommendations separated?** Yes — 4 blockers are artifact/quality gate misses confirmed by direct file checks + user confirmation. Recommendations are separately listed.
2. **PASS items too lenient?** CI: verified by actual test run. ADRs: verified by grep. Art bible sections: counted. Prototypes: globbed. All solid.
3. **Missing blockers?** Systems-index stale is ADVISORY (individual files pass). CI/CD workflow: LOW priority recommendation, not a blocker.
4. **Minimal path to PASS?** Yes — 4 items. All resolvable in 1-2 days: 2 structured playtests + playtest report + /ux-review × 3 = clear path.
5. **Resolvable or deeper design problem?** Resolvable procedural gaps only. Architecture and implementation quality is production-ready. The gap is exclusively documentation/validation — not design failure.

**Verdict unchanged: FAIL → path to PASS is clear and short.**

---

## Verdict: FAIL

**Reason**: Vertical Slice Validation auto-FAIL condition triggered (core loop fun unvalidated). Additionally: 0/3 required playtest sessions documented; playtest report directory missing; UX specs not APPROVED.

**Director panel**: CONCERNS × 4 (no NOT READY) — directors are willing to proceed conditionally, which is noted, but the artifact gate hard requirements are not met.

**Path to PASS** (estimated 1-2 days of work):
1. ✏️ Create `production/playtests/` + document ≥3 playtest sessions with fun-hypothesis result
2. ✏️ Run `/playtest-report` → file playtest report
3. ✏️ Run `/ux-review` on hud.md, main-menu.md, pause.md → reach APPROVED
4. ✏️ Update `design/gdd/systems-index.md` to reconcile 6 stale GDD statuses (ADVISORY but clean before sprint 3)

**Note**: The user may choose to override this verdict and advance to Production despite the blockers. The verdict is advisory. If overriding: document the acceptance of risk in this file and update `production/stage.txt`.

---

## QA Sign-Off Condition Update

The QA Sign-Off from 2026-05-14 (`production/qa/qa-signoff-sprint2-2026-05-14.md`) had one BLOCKING condition:
- **[RESOLVED]** Condition 1 — CI-RUN: 516/518 PASS confirmed 2026-05-15. `production/qa/ci-run-failure-analysis.md` filed.

Advisory conditions (VIS-2, VIS-3, BUG-0001) remain open — see Recommendations above.
