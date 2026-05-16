# QA Plan — Foundation Sprint
**Date**: 2026-05-03
**Stage**: Technical Setup
**Scope**: 6 Foundation Epics — 13 Stories
**QA Lead**: qa-lead

---

## Scope

| Epic | Stories |
|---|---|
| EventBus | story-001 |
| ItemDB | story-001, story-002 |
| NPCRegistry | story-001, story-002, story-003 |
| PartyManager | story-001 |
| InputMapManager | story-001, story-002, story-003, story-004 |
| SceneTransitionManager | story-001, story-002 |

---

## Story Classification Table

| Story | Type | Auto Test File | Functions | Manual QA | Gate Level |
|---|---|---|---|---|---|
| event-bus/001 | Logic | tests/unit/event_bus/event_bus_test.gd | 22 | — | BLOCKING |
| item-db/001 | Logic | tests/unit/item_db/item_db_read_test.gd | 18 | — | BLOCKING |
| item-db/002 | Logic | tests/unit/item_db/item_db_validate_test.gd | 25 | — | BLOCKING |
| npc-registry/001 | Logic | tests/unit/npc/npc_registry_read_test.gd | 23 | — | BLOCKING |
| npc-registry/002 | Logic | tests/unit/npc/npc_registry_fsm_test.gd | 33 | — | BLOCKING |
| npc-registry/003 | Logic | tests/unit/npc/npc_registry_write_test.gd | 27 | — | BLOCKING |
| party-manager/001 | Logic | tests/unit/party/party_manager_test.gd | 15 | — | BLOCKING |
| input-map/001 | Logic | tests/unit/input/input_map_init_test.gd | 21 | — | BLOCKING |
| input-map/002 | Logic | tests/unit/input/input_map_rebind_test.gd | 44 | — | BLOCKING |
| input-map/003 | Logic | tests/unit/input/input_map_context_test.gd | 11 | — | BLOCKING |
| input-map/004 | Logic | tests/unit/input/input_map_gamepad_test.gd | 20 | — | BLOCKING |
| scene-transition/001 | Logic | tests/unit/scene/scene_transition_fsm_test.gd | 15 | — | BLOCKING |
| scene-transition/002 | Integration | tests/unit/scene/scene_transition_spawn_test.gd | 12 | AC-1, AC-3 (빌드 후) | BLOCKING |

**Total automated test functions**: 286

---

## Automated Test Requirements

Run command:
```
godot --headless --script tests/gdunit4_runner.gd
```

All 13 test files in `tests/unit/` must pass. Gate: BLOCKING.

---

## Manual QA Scope

| Story | AC | Test | Prerequisite |
|---|---|---|---|
| scene-transition/002 | AC-1: 페이드 아웃→씬 교체→페이드 인 순서 | 두 테스트 씬 + 실행 빌드 | PlayerController 구현 후 |
| scene-transition/002 | AC-3: SpawnPoint_inn 위치에 플레이어 스폰 | SpawnPoint_inn Marker2D 배치된 씬 | PlayerController 구현 후 |

Evidence 작성 위치: `production/qa/evidence/scene-transition-spawn-evidence.md`

---

## Out of Scope

- PlayerController, HealthComponent, CharacterStats — Core 레이어 미구현
- DialogueManager, QuestManager — Feature 레이어 미구현
- AudioManager — Foundation 에픽이나 이번 스프린트 구현 대상 아님
- 게임패드 물리 하드웨어 검증 (input-map/004 AC-F2a) — 실기기 필요
- 렌더러 시각 출력 검증 — 빌드 필요

---

## Entry Criteria

- [x] 13개 스토리 모두 Status: Complete
- [x] 자동화 테스트 286개 파일 존재
- [x] Autoload 9개 project.godot에 등록 확인

---

## Exit Criteria

- [ ] godot --headless 테스트 실행 전체 PASS
- [ ] scene-transition/002 수동 플레이테스트 증거문서 작성 (빌드 후)
- [ ] 렌더러 불일치 ADR/설정 정렬 (gate-check 전)

---

## Smoke Check Result

**Verdict**: PASS WITH WARNINGS

| Finding | Severity | Status |
|---|---|---|
| scene-transition/002 플레이테스트 증거 없음 | ADVISORY | Open — 빌드 후 |
| project.godot renderer="mobile" vs Compatibility Renderer 명시 불일치 | WARNING | Open — gate-check 전 확인 |
| 10개 스토리 Test Evidence 체크박스 미업데이트 | ADVISORY | 정리 필요 |
| ADR-0003 get_tree().paused 대신 PROCESS_MODE_DISABLED 사용 | ADVISORY | 문서 업데이트 필요 |
| AudioManager TODO (scene_transition_manager.gd:138) | ADVISORY | AudioManager epic에서 해결 |
