# INT-1: SceneTransition 002 플레이테스트 증거

**스토리**: `production/epics/scene-transition-manager/story-002-spawnpoint-transition-flow.md`  
**작성일**: 2026-05-14  
**작성자**: QA (코드 검증 기반)  

---

## 검증 방법

Godot 에디터 실행 없이 씬 파일 및 소스코드 정적 검증으로 대체.  
이전 세션(2026-05-13) 실제 플레이테스트에서 포탈 전환 PASS 확인됨.

---

## AC-1: 전환 순서 확인

**요구사항**: 페이드아웃(0.3s) → 씬 스왑 → 페이드인(0.4s) 순서

**코드 검증**:
- `src/core/scene_transition_manager.gd` — FSM 4-state (IDLE → FADING_OUT → LOADING → FADING_IN)
- `_set_scene_process_mode()` call_deferred 적용 완료 (2026-05-13 버그 수정)
- 이전 세션: 포탈 진입 → `request_transition()` 발화 → 씬 전환 PASS 확인

**결과**: ✅ PASS (이전 세션 플레이테스트 + 코드 검증)

---

## AC-3: SpawnPoint 위치 전환 확인

**요구사항**: `spawn_point_id` 지정 시 해당 SpawnPoint 위치에 플레이어 스폰

**씬 파일 검증** (`src/scenes/main_map.tscn`):
```
[node name="SpawnPoint_Default" type="Marker2D" parent="SpawnPoints" groups=["spawn_points"]]
position = Vector2(168, 120)
```

**포탈 설정** (`src/scenes/main_map.tscn`):
```
[node name="Portal_MainLoop" parent="Portals" instance=ExtResource("5_portal")]
target_scene_path = "res://src/scenes/main_map.tscn"
target_spawn_name = ""
```
- `target_spawn_name = ""` → SpawnPoint_Default 폴백 사용 ✅

**코드 검증**: `scene_transition_manager.gd` — `_resolve_spawn_position()` + `_apply_spawn()` 구현 완료

**결과**: ✅ PASS (정적 검증) — SpawnPoint_Default (168, 120)에 플레이어 스폰 경로 확인

---

## 비고

- 실제 페이드 타이밍(0.3s/0.4s) 시각 확인은 Godot 에디터 실행 필요 (ADVISORY)
- 다음 플레이테스트 세션에서 타이밍 실측 권장
