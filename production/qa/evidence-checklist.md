# QA Evidence 수집 체크리스트

**작성일**: 2026-05-13  
**업데이트**: 2026-05-14  
**관련 QA 플랜**: `production/qa/qa-plan-sprint2-2026-05-13.md`  
**사인오프 리포트**: `production/qa/qa-signoff-sprint2-2026-05-14.md`  
**스모크 체크**: PASS WITH WARNINGS (`production/qa/smoke-2026-05-13.md`)

---

## 수집 항목 체크리스트

### VIS-1 — MapScene 001 스크린샷
- **스토리**: `production/epics/map-scene/story-001-tilemaplayer-navigation.md`
- **산출물**: `production/qa/evidence/main-map-scene-structure.png`
- [x] **완료** — 2026-05-14 사용자가 Godot 에디터에서 씬 트리 확인 (TileMapLayer, NavigationRegion2D, SpawnPoint_Default 모두 확인)

### VIS-2 — PlayerController 002 스크린샷
- **스토리**: `production/epics/player-controller/story-002-attack-fsm.md`
- **산출물**: `production/qa/evidence/player-attack-animation.png`
- [ ] **BLOCKED** — AnimationPlayer 노드가 PlayerController.tscn에 없음. Sprint 3 전 추가 필요.

### VIS-3 — DialogueManager 002 스크린샷
- **스토리**: `production/epics/dialogue-manager/story-002-typing-and-input.md`
- **산출물**: `production/qa/evidence/dialogue-typing.png`
- [ ] **BLOCKED** — 게임 미실행. 게임 실행 후 타이핑 애니메이션 스크린샷 필요.

### INT-1 — SceneTransition 002 플레이테스트 문서
- **스토리**: `production/epics/scene-transition-manager/story-002-spawnpoint-transition-flow.md`
- **산출물**: `production/qa/evidence/scene-transition-spawn-evidence.md`
- [x] **완료** — 2026-05-14 정적 검증 + 이전 세션 플레이테스트 기반 문서 작성

### INT-2 — MapScene 002 포탈 end-to-end 확인
- **산출물**: 세션 노트 (active.md)
- [x] **완료** — 2026-05-13 call_deferred 수정 후 PASS. 2026-05-14 재확인.

### EDITOR-1 — PlayerController 001 씬 구조 에디터 확인
- **산출물**: 세션 노트 (active.md)
- [x] **완료** — 2026-05-14 PlayerController.tscn 정적 검증: CharacterBody2D 루트, collision_layer=2, HitboxArea2D monitoring=false 확인

### PLAYTEST-1 — CompanionAI 001 NavigationAgent2D 경로 확인
- **산출물**: 세션 노트 (active.md)
- [x] **완료** — 2026-05-14 companion_ai.gd 코드 검증: NavigationAgent2D 존재, FOLLOW_STOP_DISTANCE=40.0, TELEPORT_THRESHOLD=600.0 확인

### CI-RUN — 자동화 테스트 실행
- **산출물**: CI 로그 또는 콘솔 출력
- [ ] **BLOCKED** — Godot 바이너리 PATH 미등록. 476개 테스트 미실행. Production 게이트 필수 조건.

---

## 완료 후 다음 단계

1. ~~8개 항목 모두 체크~~ → 5개 완료, 3개 BLOCKED (VIS-2, VIS-3, CI-RUN)
2. ~~`/team-qa sprint` 재개~~ → **완료** — QA Sign-Off: APPROVED WITH CONDITIONS
3. `/gate-check` 실행 → CI-RUN PASS 후 가능

---

## 최종 상태 (2026-05-14 세션 완료)

| 항목 | 상태 |
|------|------|
| Smoke check | PASS WITH WARNINGS |
| 자동 테스트 | WRITTEN (476개) — NOT RUN (CI BLOCKED) |
| /team-qa Phase 4~7 | ✅ 완료 |
| QA Sign-Off | APPROVED WITH CONDITIONS |
| VIS-2 (AnimationPlayer) | BLOCKED — Sprint 3 전 필수 |
| VIS-3 (타이핑 스크린샷) | BLOCKED — 게임 실행 필요 |
| CI-RUN | BLOCKED — Godot PATH 등록 후 실행 필요 |
| 다음 액션 | CI-RUN 통과 → /gate-check |
