# Spike: TileMapLayer — MapScene 타일 API 검증

**위험도**: HIGH  
**관련 ADR**: ADR-0003 (씬 전환·맵·UI 오버레이 계약)  
**Godot 버전**: 4.6  
**스파이크 목적**: Godot 4.4에서 TileMap이 TileMapLayer로 분리된 이후 API 동작 검증

---

## 배경

Godot 4.4부터 `TileMap` 노드가 레거시가 되고 `TileMapLayer`로 교체되었다.
ADR-0003은 `"spawn_points"` 그룹으로 SpawnPoint 노드를 찾는 방식을 사용하지만,
TileMapLayer 기반 씬에서 그룹 검색, 좌표 변환, 타일 조회 API가 변경되었을 수 있다.

## 검증 대상

1. `TileMapLayer` 노드 — 기본 타일 배치, `local_to_map()`, `map_to_local()` 동작
2. `get_used_cells()` — 사용 중인 셀 목록 반환 API
3. `get_tree().get_nodes_in_group("spawn_points")` — TileMapLayer 씬에서 그룹 검색
4. SpawnPoint 노드를 TileMapLayer 씬에 배치했을 때 `global_position` 접근

## 테스트 시나리오

```
# 씬 구조:
# MapScene (Node2D)
#   ├─ TileMapLayer (지형 레이어)
#   └─ SpawnPoints (Node2D)
#        ├─ SpawnPoint_Default (Marker2D, 그룹: "spawn_points")
#        └─ SpawnPoint_inn (Marker2D, 그룹: "spawn_points")

# 검증:
# get_tree().get_nodes_in_group("spawn_points") 가 [SpawnPoint_Default, SpawnPoint_inn] 반환
# SpawnPoint_inn.global_position == Vector2(200, 300)
```

## 합격 기준

- [ ] TileMapLayer 노드 생성 및 타일 배치 정상 동작
- [ ] `local_to_map()` / `map_to_local()` 반환 타입 확인 (Vector2i 여부)
- [ ] `"spawn_points"` 그룹 노드가 TileMapLayer 씬 내에서 정상 조회됨
- [ ] SceneTransitionManager의 SpawnPoint 탐색 로직과 호환 확인

## 결과 (스파이크 실행 후 기입)

**날짜**: 2026-05-07  
**결과**: BLOCKED — 오류 수정 후 재실행 필요  
**발견 사항**: 아래 "Spike Result" 섹션 참조  
**ADR-0003 영향**: 판단 보류

---

## Spike Result: spike-tilemaplayer

**Status**: BLOCKED / NOT PASSED

**Reason**:  
Godot 디버거에서 스크립트/리소스 오류가 확인되어 스파이크 결과를 신뢰할 수 없는 상태였음.  
스크립트 파싱 오류 수정 완료 (2026-05-07). 재실행 후 아래 결과란을 갱신할 것.

**Observed Errors (2026-05-07 실행 시)**:
- `spike_tilemaplayer_test.gd` — `Builtin type cannot be used as a name`  
  → `assert_is(result, Vector2i, ...)` / `assert_is(result, Vector2, ...)` 에서 발생  
  → **수정 완료**: `assert_true(result is Vector2i, ...)` / `assert_true(result is Vector2, ...)` 로 교체

**Known Issues / External Project Errors (spike와 무관)**:
- `res://assets/data/items/old_key.tres` — Failed loading resource  
- `res://assets/data/items/herb_moonleaf.tres` — Parse Error: Can't create sub resource of type  
  → 원인: `.tres` 파일에 스크립트 참조(`ExtResource`) 누락 — `type="ItemDefinition"`만으로는 Godot 4.6 클래스 DB 의존 발생  
  → **수정 완료**: 세 `.tres` 파일 모두 `script = ExtResource(...)` 형식으로 수정 (2026-05-07)  
  → item-db 스토리 관련 오류이며 TileMapLayer 스파이크 테스트 로직과 무관

**Decision**:  
빨간 오류가 남아있는 상태에서는 PASS로 기록하지 않음.  
스크립트 수정과 리소스 오류 수정 완료 후 재실행 필요.

**Next Action**:  
1. Godot 에디터를 재시작하여 클래스 DB 갱신 확인  
2. 디버거 빨간 오류 0개 상태에서 GUT 재실행  
3. 결과 확인 후 이 섹션 갱신

---

## 재실행 결과 (수정 후)

**날짜**: 2026-05-07  
**결과**: ✅ PASS — 5/5 통과  

**발견 사항**:
- `TileMapLayer` 클래스 Godot 4.6에서 정상 존재 ✅
- `get_tree().get_nodes_in_group("spawn_points")` — TileMapLayer 씬에서 정상 동작 ✅
- SpawnPoint `position` 접근 정상 ✅
- `local_to_map()` 반환 타입 `Vector2i` 확인 ✅
- `map_to_local()` 반환 타입 `Vector2` 확인 ✅
- **⚠️ 주의**: `local_to_map()` / `map_to_local()` 호출 전 `TileMapLayer.tile_set` 반드시 할당 필요. null이면 엔진 에러(`tile_set.is_null()`) 발생 + 기본값 반환. MapScene 초기화 순서에 반영 필요.

**ADR-0003 영향**: MINOR  
- `"spawn_points"` 그룹 탐색 방식 — ADR-0003 설계대로 동작 확인, 변경 불필요  
- `TileMapLayer.tile_set` null 가드 추가 권고: MapScene 초기화 시 tile_set 할당 완료 후 좌표 변환 호출할 것. ADR-0003 주석 또는 MapScene 에픽 구현 노트에 기록 권장.  

## 구현 파일

- `spike_map.tscn` — TileMapLayer + SpawnPoint 테스트 씬
- `spike_tilemaplayer_test.gd` — GUT 테스트
