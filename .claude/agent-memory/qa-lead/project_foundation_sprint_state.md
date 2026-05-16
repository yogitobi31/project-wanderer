---
name: Sprint 2 (Vertical Slice) QA State
description: Smoke check verdict, open manual QA obligations, and blockers from the 31-story Vertical Slice sprint — last reviewed 2026-05-12
type: project
---

Sprint 2 Vertical Slice (31 stories, 13 epics) underway as of 2026-05-12. All 31 stories are marked Complete in story files. Smoke check PASS WITH WARNINGS (production/qa/smoke-2026-05-13.md).

**Why:** Vertical Slice sprint building on Foundation. Core game loop includes PlayerController (3 stories), CompanionAI (4 stories), HealthComponent (2 stories), CharacterStats (2 stories), MapScene (3 stories), DialogueManager (2 stories), Inventory (2 stories).

**How to apply:** Sprint 2 QA cycle is active. 30/31 stories have automated unit test coverage. One story (MapScene 001) is Visual/Feel with missing screenshot evidence — ADVISORY blocker for /story-done. One Integration story (SceneTransitionManager 002) has deferred manual playtest ACs (AC-1 and AC-3). Multiple stories have DEFERRED ACs requiring manual playtest before Vertical Slice sign-off.

---

## Automated Test Coverage (31 stories)

30 COVERED, 1 MANUAL (MapScene 001 — Visual/Feel, screenshot missing)
All test files in tests/unit/ subdirectories. No tests/integration/ directory.
Godot binary NOT in PATH — tests NOT RUN headlessly. Manual confirmation required in local editor or CI.

---

## Open Manual QA Sessions (Sprint 2)

| Session | Stories | ACs | Status | Est. |
|---------|---------|-----|--------|------|
| VIS-1 — MapScene Screenshot | map-scene/001 | AC-3 NavigationAgent2D pathfinding, AC-5 @tool tile placement | Not run — ADVISORY blocker | 30 min |
| INT-1 — Scene Transition Playtest | scene-transition/002 | AC-1 fade order, AC-3 SpawnPoint match | Not run — ADVISORY | 20 min |
| INT-2 — Portal End-to-End | map-scene/002 | AC-1 body_entered → transition_to wiring | Not run — ADVISORY | 15 min |
| VIS-2 — PlayerController Attack Animation | player-controller/002 | AC-2/3 hitbox monitoring keyframes | Not run — ADVISORY | 20 min |
| VIS-3 — Dialogue Typing Animation | dialogue-manager/002 | AC-4 grab_focus UX | Not run — ADVISORY | 15 min |
| PLAYTEST-1 — CompanionAI Following | companion-ai/001 | AC-5 NavigationAgent2D target_position write-path | Not run — ADVISORY | 30 min |
| PLAYTEST-2 — EnemySpawnZone Position | map-scene/003 | AC-3 spawn position spread | Not run — ADVISORY | 20 min |
| PREV — Autoload Persistence | From Foundation | EventBus AC-3, PartyManager AC-6 | Carried from Sprint 1 | 30 min |
| PREV — Gamepad Hardware | From Foundation | InputMapManager 004 AC-F2a | Carried from Sprint 1 | 20 min |

## Open Bugs

| ID | Severity | Description |
|----|----------|-------------|
| BUG-0001 | S4 | ADR-0003 documents push_error for missing SpawnPoint_Default; source uses push_warning. No gameplay impact. Assign to lead-programmer. |

---

## Smoke Check Verdict: PASS WITH WARNINGS (2026-05-13)

Warnings:
1. Automated tests NOT RUN — Godot binary not in PATH. Must confirm in local editor or CI.
2. MapScene 001 Visual/Feel evidence missing — production/qa/evidence/main-map-scene-structure.png not created.
3. PlayerController FSM, CompanionAI/EnemyAI combat, 60fps performance — unverified this session.

---

## Deferred ACs by Story (ADVISORY — required before Vertical Slice final sign-off)

- player-controller/001: AC-1/2 (scene structure, physics layers) — requires PlayerController.tscn editor
- player-controller/002: AC-2/3 (hitbox keyframes) — requires AnimationPlayer scene work
- companion-ai/001: AC-5 — NavigationAgent2D target_position write-path, headlessly untestable
- map-scene/002: AC-1 — portal body_entered → request_transition wiring (end-to-end)
- map-scene/003: AC-3 — spawn position spread (playtest)
- scene-transition/002: AC-1, AC-3 — fade order, SpawnPoint match (playtest)
- dialogue-manager/002: AC-4 — grab_focus UX (playtest)
- character-stats/001: AC-5 — Inspector @export visibility (manual)

## Notable Tech Debt Carried Forward (Sprint 1 + Sprint 2)

- item-db/002: CR-07 duplicate-id test uses harness simulation, not real DirAccess — integration test needed
- item-db/002: sentinel magic number 99 not extracted to ItemDefinition.MAX_STACK_SENTINEL
- input-map/002: _save_to_cfg() only serializes keyboard events; gamepad/mouse persistence deferred
- input-map/002: AC-E-save-fail path Linux reliability low — harden before save/load epic
- scene-transition/001: ADR-0003 mentions get_tree().paused but implementation uses PROCESS_MODE_DISABLED — ADR-0003 update needed
- npc-registry 002/003: HOSTILE transition ACs (CR-06, CR-06b, EC-04) deferred to VS+
- dialogue-manager/001: finish_dialogue() renamed public (deferred grab_focus to story-002)
- player-controller/002: Input.is_action_just_pressed() used directly instead of InputMapManager wrapper
- inventory/001: ItemDB.has_item() → actual API is ItemDB.has() (advisory — documentation only)
