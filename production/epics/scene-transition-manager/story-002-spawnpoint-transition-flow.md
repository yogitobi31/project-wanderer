# Story 002: SpawnPoint 조회·폴백·전환 완료 흐름

> **Epic**: SceneTransitionManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/씬전환-시스템.md`
**Requirements**: `TR-scene-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 씬 전환·맵 구조·UI 오버레이 계약
**ADR Decision Summary**: SpawnPoint 명명 규칙 — 그룹 `"spawn_points"`, 노드 이름 `SpawnPoint_{id}`. `spawn_point_id` 없거나 불일치 시 `SpawnPoint_Default` 폴백, 그것도 없으면 `Vector2.ZERO` + 경고.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `get_tree().get_nodes_in_group("spawn_points")` — 4.x 안정. `Node.name` 비교 — StringName 사용 권장(`&"SpawnPoint_Default"`). 씬 루트가 `_on_scene_ready(meta)` 구현 여부 — `has_method()` 확인 후 호출.

**Control Manifest Rules (Foundation layer)**:
- Required: SpawnPoint 노드 명명: `SpawnPoint_{id}`, 그룹: `"spawn_points"`
- Required: 폴백 우선순위 — `SpawnPoint_{id}` → `SpawnPoint_Default` → `Vector2.ZERO`
- Forbidden: PlayerController 직접 참조 — `set_spawn_position()` 인터페이스 계약만 사용

---

## Acceptance Criteria

*From GDD `design/gdd/씬전환-시스템.md`:*

- [ ] `request_transition(path)` 호출 시 페이드 아웃 → 씬 교체 → 페이드 인이 순서대로 실행된다 (AC-1 — 수동 플레이테스트)
- [ ] `spawn_point_id`와 일치하는 `Marker2D` 노드(`SpawnPoint_{id}`)가 있을 때 플레이어가 해당 위치에 스폰된다 (AC-3 — 수동 플레이테스트)
- [ ] 일치하는 `Marker2D`가 없을 때 `Vector2.ZERO`에 스폰되고 `push_warning()` 1회 출력된다 (AC-4)

---

## Implementation Notes

*Derived from ADR-0003 + GDD R-7:*

```gdscript
# SceneTransitionManager._apply_spawn(spawn_point_id) — _swap_scene() 내 호출
func _apply_spawn(spawn_point_id: String) -> void:
    var spawn_pos := Vector2.ZERO
    var spawn_nodes := get_tree().get_nodes_in_group("spawn_points")

    if spawn_point_id != "":
        var target_name := &"SpawnPoint_" + spawn_point_id
        for node in spawn_nodes:
            if node.name == target_name and node is Marker2D:
                spawn_pos = node.global_position
                break
        else:
            # 이름 일치 없음 → DefaultSpawn 시도
            for node in spawn_nodes:
                if node.name == &"SpawnPoint_Default" and node is Marker2D:
                    spawn_pos = node.global_position
                    break
            else:
                push_warning("SceneTransitionManager: no spawn point found for id='" + spawn_point_id + "', using Vector2.ZERO")
    else:
        # spawn_point_id 미제공 → DefaultSpawn
        for node in spawn_nodes:
            if node.name == &"SpawnPoint_Default" and node is Marker2D:
                spawn_pos = node.global_position
                break

    # 플레이어 캐릭터 컨트롤러에 위치 전달
    var player := get_tree().get_first_node_in_group("player")
    if player and player.has_method("set_spawn_position"):
        player.set_spawn_position(spawn_pos)

# metadata 전달 — 새 씬 루트에 _on_scene_ready() 구현 시 자동 호출
func _deliver_metadata(meta: Dictionary) -> void:
    var new_scene := get_tree().current_scene
    if new_scene and new_scene.has_method("_on_scene_ready"):
        new_scene._on_scene_ready(meta)
```

**SpawnPoint 씬 구성 규칙**:
- 씬 안에 `Marker2D` 노드 추가
- 이름: `SpawnPoint_{id}` (예: `SpawnPoint_entrance`, `SpawnPoint_Default`)
- 그룹: `"spawn_points"` 추가
- 레벨 디자이너가 배치 — 코드로 생성하지 않음

**AudioManager null 가드**:
```gdscript
# 오디오 매니저 미완성 시 null 가드
if AudioManager:
    AudioManager.request_music_fade_out(FADE_OUT_DURATION)
```

---

## Out of Scope

- Story 001: FSM 상태 전환, process_mode 계약, 중복 요청 방어
- AudioManager 연동 완성 — AudioManager epic 완성 후 null 가드 제거
- `_on_scene_ready()` 구현 — 각 씬의 책임

---

## QA Test Cases

- **AC-1**: 전환 순서 (수동 플레이테스트)
  - Setup: 두 테스트 씬 준비 (SceneA → SceneB), `request_transition("res://SceneB.tscn")` 호출
  - Verify: (1) 화면이 검게 페이드 아웃됨, (2) SceneB 콘텐츠 노출, (3) 화면이 다시 밝아짐
  - Pass condition: 세 단계가 끊김 없이 순서대로 진행, 전환 중 입력 반응 없음

- **AC-3**: 일치 SpawnPoint 스폰 (수동 플레이테스트)
  - Setup: SceneB에 `SpawnPoint_inn`(`Marker2D`, 위치 (200, 300), 그룹 `spawn_points`) 배치
  - When: `request_transition("res://SceneB.tscn", "inn")` 호출
  - Verify: 전환 완료 후 플레이어 위치 = (200, 300)
  - Pass condition: 플레이어가 `SpawnPoint_inn` 위치에 정확히 등장

- **AC-4**: SpawnPoint 불일치 → Vector2.ZERO + 경고
  - Given: 새 씬에 `spawn_point_id`와 일치하는 Marker2D 없음
  - When: `request_transition(path, "nonexistent_id")` 후 스폰 처리
  - Then: `push_warning()` 1회, 플레이어 위치 = Vector2.ZERO
  - Edge cases: spawn_points 그룹 자체가 없는 씬 → 동일 결과

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/scene-transition-spawn-evidence.md` — 수동 플레이테스트 결과 문서 (AC-1, AC-3)
- AC-4: `push_warning()` 단위 테스트로 보완 권장 (`tests/unit/scene/scene_transition_spawn_test.gd`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (scene-transition-manager) DONE — FSM 구조 필요
- Unlocks: 맵/지역 시스템 epic (씬 전환 완성 후 맵 이동 구현 가능)

## Completion Notes
**Completed**: 2026-05-03
**Criteria**: 1/3 passing, 2/3 DEFERRED (AC-1, AC-3 수동 플레이테스트 필요)
**Deviations**:
- SpawnPoint_DefaultSpawn → SpawnPoint_Default 명칭 불일치 → GDD·story 수정 완료
- AudioManager null 가드: TODO(ADR-0003) 주석 추가 완료 (AudioManager epic 완성 후 구현)
- TransitionType.INSTANT/CUT 미구현 → push_warning 추가 완료
**Test Evidence**: `tests/unit/scene/scene_transition_spawn_test.gd` (12 tests, AC-4 커버) | `production/qa/evidence/scene-transition-spawn-evidence.md` — playtest 시 작성 필요 (AC-1, AC-3)
**Code Review**: Complete (APPROVED — code-review 단계에서 BLOCKING 2건 수정)
