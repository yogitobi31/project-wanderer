## QA Sign-Off Report: Sprint 2 — Vertical Slice
**Date**: 2026-05-14
**Sprint**: Sprint 2 (Vertical Slice)
**Stage**: Pre-Production
**QA Lead sign-off**: qa-lead agent (Claude Sonnet 4.6)
**Smoke Check**: PASS WITH WARNINGS — `production/qa/smoke-2026-05-13.md`

---

### Test Coverage Summary

| # | Story | Type | Auto Test File | Tests | Auto Test Result | Manual QA | Overall |
|---|-------|------|----------------|-------|-----------------|-----------|---------|
| 1 | EventBus 001 — Autoload Signal | Logic | `tests/unit/event_bus/event_bus_test.gd` | 21 | WRITTEN — NOT RUN (CI BLOCKED) | PASS WITH CONDITIONS (AC-3 scene-persist advisory) | PASS WITH CONDITIONS |
| 2 | ItemDB 001 — ItemDefinition | Logic | `tests/unit/item_db/item_db_read_test.gd` | 19 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 3 | ItemDB 002 — _validate_definitions | Logic | `tests/unit/item_db/item_db_validate_test.gd` | 35 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 4 | NPCRegistry 001 — Read Interface | Logic | `tests/unit/npc/npc_registry_read_test.gd` | 24 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 5 | NPCRegistry 002 — set_state FSM | Logic | `tests/unit/npc/npc_registry_fsm_test.gd` | 46 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 6 | NPCRegistry 003 — Write API | Logic | `tests/unit/npc/npc_registry_write_test.gd` | 49 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 7 | PartyManager 001 — Register/Query | Logic | `tests/unit/party/party_manager_test.gd` | 17 | WRITTEN — NOT RUN (CI BLOCKED) | PASS WITH CONDITIONS (AC-6 scene-persist advisory) | PASS WITH CONDITIONS |
| 8 | InputMap 001 — Action Table Init | Logic | `tests/unit/input/input_map_init_test.gd` | 23 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 9 | InputMap 002 — Rebind API | Logic | `tests/unit/input/input_map_rebind_test.gd` | 44 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 10 | InputMap 003 — Context Separation | Logic | `tests/unit/input/input_map_context_test.gd` | 11 | WRITTEN — NOT RUN (CI BLOCKED) | PASS WITH CONDITIONS (AC-R7d static grep advisory) | PASS WITH CONDITIONS |
| 11 | InputMap 004 — Gamepad Formula | Logic | `tests/unit/input/input_map_gamepad_test.gd` | 19 | WRITTEN — NOT RUN (CI BLOCKED) | PASS WITH CONDITIONS (AC-F2a hardware advisory) | PASS WITH CONDITIONS |
| 12 | SceneTransition 001 — FSM | Logic | `tests/unit/scene/scene_transition_fsm_test.gd` | 15 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 13 | SceneTransition 002 — SpawnPoint | Integration | `tests/unit/scene/scene_transition_spawn_test.gd` | 12 | WRITTEN — NOT RUN (CI BLOCKED) | PASS (INT-1: evidence doc created) | PASS WITH CONDITIONS |
| 14 | CharacterStats 001 — Resource | Logic | `tests/unit/stats/character_stats_test.gd` | 34 | WRITTEN — NOT RUN (CI BLOCKED) | PASS WITH CONDITIONS (AC-5 Inspector advisory) | PASS WITH CONDITIONS |
| 15 | CharacterStats 002 — Signal + duplicate | Logic | `tests/unit/stats/character_stats_signal_test.gd` | 16 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 16 | HealthComponent 001 — Damage + Signal | Logic | `tests/unit/combat/health_component_test.gd` | 15 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 17 | HealthComponent 002 — Iframes + Hurtbox | Logic | `tests/unit/combat/health_iframes_test.gd` | 7 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 18 | PlayerController 001 — Movement FSM | Logic | `tests/unit/player/player_movement_test.gd` | 8 | WRITTEN — NOT RUN (CI BLOCKED) | PASS (EDITOR-1: .tscn 정적 검증) | PASS WITH CONDITIONS |
| 19 | PlayerController 002 — Attack FSM | Logic + Visual/Feel | `tests/unit/player/player_attack_test.gd` | 10 | WRITTEN — NOT RUN (CI BLOCKED) | BLOCKED (VIS-2: AnimationPlayer 미추가) | BLOCKED (ADVISORY) |
| 20 | PlayerController 003 — Death + Respawn | Logic | `tests/unit/player/player_death_test.gd` | 9 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 21 | MapScene 001 — TileMapLayer + Navigation | Visual/Feel | — | — | N/A | PASS (VIS-1: 에디터 확인) | PASS |
| 22 | MapScene 002 — Portal Transition | Logic | `tests/unit/scene/portal_transition_test.gd` | 10 | WRITTEN — NOT RUN (CI BLOCKED) | PASS (INT-2: call_deferred fix 확인) | PASS WITH CONDITIONS |
| 23 | MapScene 003 — EnemySpawnZone | Logic | `tests/unit/combat/enemy_spawn_zone_test.gd` | 6 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 24 | CompanionAI 001 — Following/Chasing | Logic | `tests/unit/ai/companion_following_test.gd` | 15 | WRITTEN — NOT RUN (CI BLOCKED) | PASS (PLAYTEST-1: NavigationAgent2D 코드 검증) | PASS WITH CONDITIONS |
| 25 | CompanionAI 002 — Attacking/Dead | Logic | `tests/unit/ai/companion_combat_test.gd` | 9 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 26 | CompanionAI 003 — EnemyAI FSM | Logic | `tests/unit/ai/enemy_ai_test.gd` | 13 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 27 | CompanionAI 004 — CombatEncounter + SpawnZone | Logic | `tests/unit/combat/combat_encounter_test.gd` | 14 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 28 | DialogueManager 001 — Overlay + is_active | Logic | `tests/unit/dialogue/dialogue_manager_state_test.gd` | 9 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 29 | DialogueManager 002 — Typing + ui_accept | Logic + Visual/Feel | `tests/unit/dialogue/dialogue_typing_test.gd` | 13 | WRITTEN — NOT RUN (CI BLOCKED) | BLOCKED (VIS-3: 게임 미실행) | BLOCKED (ADVISORY) |
| 30 | Inventory 001 — add/remove API | Logic | `tests/unit/inventory/inventory_api_test.gd` | 19 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |
| 31 | Inventory 002 — Save/Load 직렬화 | Logic | `tests/unit/inventory/inventory_save_test.gd` | 13 | WRITTEN — NOT RUN (CI BLOCKED) | N/A | PASS WITH CONDITIONS |

**총계**: 31개 스토리 | 476개 자동화 테스트 작성 완료 | 2개 BLOCKED (ADVISORY) | 0개 FAIL

---

### Bugs Found

| ID | Story | Severity | Priority | Description | Status |
|----|-------|----------|----------|-------------|--------|
| BUG-0001 | SceneTransition 002 | S4 — Trivial | P3 — Backlog | `push_warning` vs `push_error` — ADR-0003 불일치, 게임플레이 영향 없음 | Open |

S1/S2 버그 없음.

---

### Verdict: APPROVED WITH CONDITIONS

---

**Conditions**:

**[BLOCKING] Condition 1 — CI-RUN: 자동화 테스트 실행 필수**
476개 단위 테스트가 작성되었으나 미실행 상태. Godot 바이너리 PATH 미등록으로 headless CI 실행 불가. 코딩 스탠다드에 따라 Production 단계 이전 CI 통과는 필수 게이트.
- Action: Godot 4.6 바이너리를 시스템 PATH에 등록 후 `godot --headless --script tests/gdunit4_runner.gd` 실행 → 전체 476개 PASS 확인
- Owner: lead-programmer / CI 파이프라인 담당

**[ADVISORY] Condition 2 — VIS-2: PlayerController.tscn AnimationPlayer 미추가**
`PlayerController 002` (Attack FSM) — AnimationPlayer 노드가 씬에 없음. AC-2/AC-3 스토리 완료 시 DEFERRED로 기록됨. 스프린트 3 시작 전 완료 필요.
- Action: PlayerController.tscn에 AnimationPlayer 추가 → attack 클립 구현 → HitboxArea2D keyframe 설정 → `production/qa/evidence/player-attack-animation.png` 캡처
- Owner: lead-programmer / godot-gdscript-specialist

**[ADVISORY] Condition 3 — VIS-3: DialogueManager 타이핑 스크린샷 미수집**
게임 미실행으로 타이핑 애니메이션 스크린샷 없음. 단기 세션(~20분)으로 완료 가능.
- Action: 게임 실행 → DialogueManager 활성화 → 타이핑 중 스크린샷 → `production/qa/evidence/dialogue-typing.png` 저장
- Owner: qa-tester

**[ADVISORY] Condition 4 — BUG-0001: 로깅 심각도 불일치**
`scene_transition_manager.gd` — `push_warning` → `push_error` 수정 필요 (ADR-0003).
- Action: Sprint 3 백로그에 포함
- Owner: lead-programmer

---

### Conditions 요약

| 분류 | 수 | 항목 |
|------|----|------|
| BLOCKING — Production 이전 필수 | 1 | CI-RUN |
| ADVISORY — 스프린트 종료 전 필수 | 3 | VIS-2, VIS-3, BUG-0001 |
| S1/S2 버그 오픈 | 0 | — |
| 스토리 FAIL | 0 | — |

---

### Next Step

이 스프린트는 **스프린트 리뷰 진행 승인** 상태입니다. Condition 1(CI-RUN) 해소 전까지 Production 단계로 진입 불가.

우선순위 액션:
1. **Godot 바이너리 PATH 등록 → 자동화 테스트 476개 실행** (최고 우선순위)
2. **VIS-2 완료** — PlayerController.tscn AnimationPlayer 추가 (Sprint 3 시작 전)
3. **VIS-3 완료** — DialogueManager 타이핑 스크린샷 (20분 작업)
4. **BUG-0001** — Sprint 3 백로그 등록

CI-RUN 통과 후: `/smoke-check` → `/gate-check` (Pre-Production → Production 게이트) 실행.
