# QA Plan — Sprint 2 (Vertical Slice)
**Date**: 2026-05-13
**Sprint**: Sprint 2 (Vertical Slice)
**Stage**: Pre-Production
**QA Lead**: qa-lead agent
**Stories in scope**: 31 (Foundation 13 + Core/Feature 18)
**Smoke Check**: PASS WITH WARNINGS (`production/qa/smoke-2026-05-13.md`)

---

## Scope

| Epic | Stories | Layer |
|------|---------|-------|
| EventBus | story-001 | Foundation |
| ItemDB | story-001, 002 | Foundation |
| NPCRegistry | story-001, 002, 003 | Foundation |
| PartyManager | story-001 | Foundation |
| InputMapManager | story-001, 002, 003, 004 | Foundation |
| SceneTransitionManager | story-001, 002 | Foundation |
| CharacterStats | story-001, 002 | Core |
| HealthComponent | story-001, 002 | Core |
| PlayerController | story-001, 002, 003 | Core |
| MapScene | story-001, 002, 003 | Feature |
| CompanionAI | story-001, 002, 003, 004 | Feature |
| DialogueManager | story-001, 002 | Feature |
| Inventory | story-001, 002 | Feature |

---

## Story Classification Table

| # | Story | Type | Auto Test File | Tests | Manual Required | Gate |
|---|-------|------|----------------|-------|-----------------|------|
| 1 | EventBus 001 — Autoload Signal | Logic | `tests/unit/event_bus/event_bus_test.gd` | 21 | AC-3 scene persist (advisory) | ADVISORY |
| 2 | ItemDB 001 — ItemDefinition | Logic | `tests/unit/item_db/item_db_read_test.gd` | 19 | 없음 | — |
| 3 | ItemDB 002 — _validate_definitions | Logic | `tests/unit/item_db/item_db_validate_test.gd` | 35 | 없음 | — |
| 4 | NPCRegistry 001 — Read Interface | Logic | `tests/unit/npc/npc_registry_read_test.gd` | 24 | 없음 | — |
| 5 | NPCRegistry 002 — set_state FSM | Logic | `tests/unit/npc/npc_registry_fsm_test.gd` | 46 | 없음 | — |
| 6 | NPCRegistry 003 — Write API | Logic | `tests/unit/npc/npc_registry_write_test.gd` | 49 | 없음 | — |
| 7 | PartyManager 001 — Register/Query | Logic | `tests/unit/party/party_manager_test.gd` | 17 | AC-6 scene persist (advisory) | ADVISORY |
| 8 | InputMap 001 — 액션 테이블 초기화 | Logic | `tests/unit/input/input_map_init_test.gd` | 23 | 없음 | — |
| 9 | InputMap 002 — 리바인딩 API | Logic | `tests/unit/input/input_map_rebind_test.gd` | 44 | 없음 | — |
| 10 | InputMap 003 — 컨텍스트 분리 | Logic | `tests/unit/input/input_map_context_test.gd` | 11 | AC-R7d static grep (advisory) | ADVISORY |
| 11 | InputMap 004 — 게임패드 공식 | Logic | `tests/unit/input/input_map_gamepad_test.gd` | 19 | AC-F2a 하드웨어 (advisory) | ADVISORY |
| 12 | SceneTransition 001 — FSM | Logic | `tests/unit/scene/scene_transition_fsm_test.gd` | 15 | 없음 | — |
| 13 | SceneTransition 002 — SpawnPoint | Integration | `tests/unit/scene/scene_transition_spawn_test.gd` | 12 | AC-1 페이드 순서, AC-3 SpawnPoint 위치 | **BLOCKING** |
| 14 | CharacterStats 001 — Resource 구조 | Logic | `tests/unit/stats/character_stats_test.gd` | 34 | AC-5 Inspector visibility (advisory) | ADVISORY |
| 15 | CharacterStats 002 — Signal + duplicate | Logic | `tests/unit/stats/character_stats_signal_test.gd` | 16 | 없음 | — |
| 16 | HealthComponent 001 — 데미지 + 신호 | Logic | `tests/unit/combat/health_component_test.gd` | 15 | 없음 | — |
| 17 | HealthComponent 002 — Iframes + Hurtbox | Logic | `tests/unit/combat/health_iframes_test.gd` | 7 | 없음 | — |
| 18 | PlayerController 001 — 이동 FSM | Logic | `tests/unit/player/player_movement_test.gd` | 8 | AC-1/2 씬 구조 에디터 확인 | **BLOCKING** |
| 19 | PlayerController 002 — 공격 FSM | Logic + Visual/Feel | `tests/unit/player/player_attack_test.gd` | 10 | 스크린샷 `player-attack-animation.png` | **BLOCKING** |
| 20 | PlayerController 003 — 사망 + 리스폰 | Logic | `tests/unit/player/player_death_test.gd` | 9 | 없음 | — |
| 21 | MapScene 001 — TileMapLayer + Navigation | Visual/Feel | — | — | 스크린샷 `main-map-scene-structure.png` | **BLOCKING** |
| 22 | MapScene 002 — 포탈 전환 | Logic | `tests/unit/scene/portal_transition_test.gd` | 10 | AC-1 end-to-end 포탈 배선 수동 확인 | **BLOCKING** |
| 23 | MapScene 003 — EnemySpawnZone | Logic | `tests/unit/combat/enemy_spawn_zone_test.gd` | 6 | 없음 | — |
| 24 | CompanionAI 001 — Following/Chasing | Logic | `tests/unit/ai/companion_following_test.gd` | 15 | AC-5 NavigationAgent2D 경로 플레이테스트 | **BLOCKING** |
| 25 | CompanionAI 002 — Attacking/Dead | Logic | `tests/unit/ai/companion_combat_test.gd` | 9 | 없음 | — |
| 26 | CompanionAI 003 — EnemyAI FSM | Logic | `tests/unit/ai/enemy_ai_test.gd` | 13 | 없음 | — |
| 27 | CompanionAI 004 — CombatEncounter + SpawnZone | Logic | `tests/unit/combat/combat_encounter_test.gd` | 14 | 없음 | — |
| 28 | DialogueManager 001 — 오버레이 + is_active | Logic | `tests/unit/dialogue/dialogue_manager_state_test.gd` | 9 | 없음 | — |
| 29 | DialogueManager 002 — 타이핑 + ui_accept | Logic + Visual/Feel | `tests/unit/dialogue/dialogue_typing_test.gd` | 13 | 스크린샷 `dialogue-typing.png` | **BLOCKING** |
| 30 | Inventory 001 — add/remove API | Logic | `tests/unit/inventory/inventory_api_test.gd` | 19 | 없음 | — |
| 31 | Inventory 002 — Save/Load 직렬화 | Logic | `tests/unit/inventory/inventory_save_test.gd` | 13 | 없음 | — |

**총 자동화 테스트**: ~476개 (30개 Logic/Integration 스토리 커버)

---

## Automated Test Requirements

모든 30개 Logic/Integration 스토리의 테스트 파일이 `tests/unit/`에 존재 확인됨.

| 디렉토리 | 파일 수 |
|---------|--------|
| tests/unit/event_bus/ | 1 |
| tests/unit/item_db/ | 2 |
| tests/unit/npc/ | 3 |
| tests/unit/party/ | 1 |
| tests/unit/input/ | 4 |
| tests/unit/scene/ | 3 |
| tests/unit/stats/ | 2 |
| tests/unit/combat/ | 4 |
| tests/unit/player/ | 3 |
| tests/unit/ai/ | 3 |
| tests/unit/dialogue/ | 2 |
| tests/unit/inventory/ | 2 |

CI 커맨드: `godot --headless --script tests/gdunit4_runner.gd`

> ⚠️ **현재 상태**: Godot 바이너리 PATH 미등록으로 자동 테스트 NOT RUN.
> 로컬 Godot 에디터 또는 CI에서 수동 실행 후 결과 확인 필요. 스프린트 사인오프 전 필수.

---

## Manual QA Scope

아래 항목들은 `/story-done` 전 반드시 처리해야 하는 BLOCKING 후속 QA 작업입니다.

| 세션 | 스토리 | 필요 작업 | 산출물 경로 | 소요 |
|------|--------|----------|------------|------|
| **VIS-1** | MapScene 001 | Godot 에디터에서 TileMapLayer + NavigationRegion2D + SpawnPoint 씬 구조 스크린샷 | `production/qa/evidence/main-map-scene-structure.png` | 30분 |
| **VIS-2** | PlayerController 002 | AnimationPlayer 공격 키프레임 + HitboxArea2D monitoring 토글 스크린샷 | `production/qa/evidence/player-attack-animation.png` | 20분 |
| **VIS-3** | DialogueManager 002 | 타이핑 애니메이션 실행 스크린샷 + grab_focus UX 확인 | `production/qa/evidence/dialogue-typing.png` | 20분 |
| **INT-1** | SceneTransition 002 | 페이드아웃 → 씬 스왑 → 페이드인 순서 확인 (AC-1) + SpawnPoint 위치 일치 확인 (AC-3) | `production/qa/evidence/scene-transition-spawn-evidence.md` | 25분 |
| **INT-2** | MapScene 002 | 포탈 Area2D 진입 → `request_transition()` 발화 → 씬 전환 완료 end-to-end 확인 (AC-1) | 플레이테스트 메모 (session extract) | 15분 |
| **EDITOR-1** | PlayerController 001 | Godot 에디터에서 CharacterBody2D 레이어/마스크 설정 확인 (AC-1, AC-2) | 플레이테스트 메모 (session extract) | 15분 |
| **PLAYTEST-1** | CompanionAI 001 | 게임 루프 실행: 동료가 플레이어 방향으로 이동, 40px에서 정지, 600px 이상 시 순간이동 확인 (AC-5) | 플레이테스트 메모 (session extract) | 30분 |
| **CI-RUN** | 전체 31개 | Godot 바이너리 PATH 등록 후 `godot --headless --script tests/gdunit4_runner.gd` 실행, 전체 통과 확인 | CI 로그 또는 콘솔 출력 | ~10분 |

**총 예상 소요**: ~2시간 45분

---

## Out of Scope

- 비주얼 / VFX / 애니메이션 fidelity 검증 (아직 구현 없음)
- HUD / 체력바 UI (GDD 미작성 — Feature 스프린트 이후)
- SaveManager 전체 직렬화 (GDD 미작성 — MVP 이후)
- AudioManager BGM 페이드 (TODO 주석 — 에픽 완료 후)
- 플랫폼별 렌더링 검증 (PC 타겟, Steam Deck 실기 확인은 추후)
- 성능 프로파일링 60fps (플레이어블 빌드 후 별도 세션)

---

## Entry Criteria

- [x] Smoke check PASS WITH WARNINGS 확인 (`production/qa/smoke-2026-05-13.md`)
- [x] 31개 스토리 모두 `/story-done` 또는 COMPLETE WITH NOTES 처리됨
- [x] BUG-0001 (S4/Trivial) 오픈 — 게임플레이 영향 없음, 블로킹 아님
- [ ] Godot 바이너리 PATH 등록 → 자동 테스트 1회 실행 확인 (**미완료**)

---

## Exit Criteria

- [ ] 모든 Logic 스토리의 자동화 테스트 PASS (CI 또는 로컬 실행)
- [ ] 8개 BLOCKING 후속 QA 작업 모두 완료 및 에비던스 파일 존재
- [ ] QA 사인오프 리포트 작성 완료 (`production/qa/qa-signoff-sprint2-*.md`)
- [ ] 오픈 S1/S2 버그 없음 (현재 없음 — BUG-0001은 S4)

---

## Open Bugs

| ID | 스토리 | 심각도 | 내용 | 상태 |
|----|--------|--------|------|------|
| BUG-0001 | SceneTransition 002 | S4/Trivial | `push_warning` vs `push_error` — ADR-0003 불일치, 게임플레이 영향 없음 | Open |

---

## Notes

- 이번 세션에서 `scene_transition_manager.gd:128` 포탈 진입 물리 콜백 버그 수정 완료.
  `_set_scene_process_mode()` → `call_deferred("_set_scene_process_mode", ...)` 변경.
  포탈 전환 재확인 PASS.
- Smoke check 경고 항목들은 ADVISORY이지만 각 해당 스토리의 `/story-done` 전 반드시 해소 필요.
