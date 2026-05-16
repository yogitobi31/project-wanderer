# QA Plan — Foundation Sprint
**Date**: 2026-05-05
**Sprint**: Foundation Sprint (Technical Setup stage)
**QA Lead**: qa-lead agent
**Stories in scope**: 13 (6 epics)

---

## Scope

| Epic | Stories | Layer |
|------|---------|-------|
| EventBus | story-001 | Foundation |
| NPCRegistry | story-001, 002, 003 | Foundation |
| PartyManager | story-001 | Foundation |
| ItemDB | story-001, 002 | Foundation |
| InputMapManager | story-001, 002, 003, 004 | Foundation |
| SceneTransitionManager | story-001, 002 | Foundation |

---

## Story Classification Table

| # | Story | Type | Auto Test File | Tests | Manual Required | Gate |
|---|-------|------|----------------|-------|-----------------|------|
| 1 | EventBus — Autoload & Signal | Logic | event_bus_test.gd | 21 | AC-3 scene persist (advisory) | ADVISORY |
| 2 | ItemDB 001 — ItemDefinition | Logic | item_db_read_test.gd | 19 | 없음 | — |
| 3 | ItemDB 002 — _validate_definitions | Logic | item_db_validate_test.gd | 35 | 없음 | — |
| 4 | NPCRegistry 001 — Read interface | Logic | npc_registry_read_test.gd | 24 | 없음 | — |
| 5 | NPCRegistry 002 — set_state FSM | Logic | npc_registry_fsm_test.gd | 46 | 없음 | — |
| 6 | NPCRegistry 003 — Write API | Logic | npc_registry_write_test.gd | 49 | 없음 | — |
| 7 | PartyManager 001 — Register/Query | Logic | party_manager_test.gd | 17 | AC-6 scene persist (advisory) | ADVISORY |
| 8 | InputMap 001 — 액션 테이블 초기화 | Logic | input_map_init_test.gd | 23 | 없음 | — |
| 9 | InputMap 002 — 리바인딩 API | Logic | input_map_rebind_test.gd | 44 | 없음 | — |
| 10 | InputMap 003 — 컨텍스트 분리 | Logic | input_map_context_test.gd | 11 | AC-R7d grep (advisory) | ADVISORY |
| 11 | InputMap 004 — 게임패드 공식 | Logic | input_map_gamepad_test.gd | 19 | AC-F2a 하드웨어 (advisory) | ADVISORY |
| 12 | SceneTransition 001 — FSM | Logic | scene_transition_fsm_test.gd | 15 | 없음 | — |
| 13 | SceneTransition 002 — SpawnPoint | **Integration** | scene_transition_spawn_test.gd | 12 (partial) | AC-1, AC-3 **필수** | **BLOCKING** |

**총 자동화 테스트: 335개**

---

## Automated Test Requirements

모든 13개 스토리의 테스트 파일이 `tests/unit/`에 존재 확인됨.

| 디렉토리 | 파일 수 |
|---------|--------|
| tests/unit/event_bus/ | 1 |
| tests/unit/item_db/ | 2 |
| tests/unit/npc/ | 3 |
| tests/unit/party/ | 1 |
| tests/unit/input/ | 4 |
| tests/unit/scene/ | 2 |

CI 커맨드: `godot --headless --script tests/gdunit4_runner.gd`

---

## Manual QA Scope

| 세션 | 스토리 | AC | 소요 | Gate |
|------|--------|-----|------|------|
| **Session B** | SceneTransition 002 | AC-1 (페이드 순서), AC-3 (SpawnPoint 위치) | 45-60분 | **BLOCKING** |
| Session A | EventBus AC-3, PartyManager AC-6 | Autoload 씬 전환 후 상태 유지 | 30분 | ADVISORY |
| Session C | InputMap 004 AC-F2a | 실제 게임패드 대각선 정규화 | 20분 | ADVISORY |
| Session D | InputMap 003 AC-R7d | src/ 하드코딩 키코드 grep | 5분 | ADVISORY |

**Session B는 스프린트 사인오프 전 필수 완료.**
Session A/C/D는 첫 플레이어블 빌드 전까지 어드바이저리 완료 권장.

---

## Out of Scope

- 비주얼 / VFX / 애니메이션 검증 (아직 구현 없음)
- 실제 게임플레이 루프 플레이테스트 (Feature 스프린트 이후)
- 플랫폼별 렌더링 검증 (PC 타겟, 추후 Steam Deck 실기 확인)
- SaveManager (GDD 미작성 — MVP 이후)
- HUD / UI 시스템 (GDD 미작성)

---

## Entry Criteria

- [x] 모든 자동화 테스트 파일 존재 확인 (13/13)
- [x] `src/core/` 소스 파일 존재 확인 (8개)
- [x] Smoke Check: PASS WITH WARNINGS
- [ ] Session B 수동 QA 실행 및 증거 파일 작성 (BLK-01)

---

## Exit Criteria

- All 13 stories: PASS or PASS WITH NOTES
- BLK-01 해소: `production/qa/evidence/scene-transition-spawn-evidence.md` 작성 완료
- 오픈 S1/S2 버그 없음
- QA 사인오프 리포트 작성 완료

---

## Smoke Check Result

**PASS WITH WARNINGS**

| # | 경고 | 심각도 |
|---|------|--------|
| W1 | `production/qa/evidence/` 디렉토리 부재 → **이 플랜 작성 시 생성 완료** | 해소 |
| W2 | `tests/integration/` 디렉토리 없음 | ADVISORY |
| W3 | project.godot `Mobile` 피처 플래그 — PC 타겟 의도와 불일치 가능 | 확인 필요 |
| W4 | `assets/data/items/` 픽스처 경로 미감사 | ADVISORY |
| W5 | CI 러너 미확인 | ADVISORY |

---

## Blockers

**BLK-01 — SceneTransition 002 수동 QA 증거 없음**
- 파일: `production/qa/evidence/scene-transition-spawn-evidence.md` (미작성)
- 미검증 AC: AC-1 (페이드 아웃→씬 교체→페이드 인), AC-3 (SpawnPoint 이름 기반 위치)
- 해결: Manual QA Session B 실행 후 증거 파일 작성
