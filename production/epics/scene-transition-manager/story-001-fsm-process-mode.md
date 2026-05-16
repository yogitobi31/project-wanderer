# Story 001: FSM 상태 전환·process_mode 계약·중복 요청 방어

> **Epic**: SceneTransitionManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/씬전환-시스템.md`
**Requirements**: `TR-scene-001`, `TR-scene-002`, `TR-scene-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: 씬 전환·맵 구조·UI 오버레이 계약
**ADR Decision Summary**: 4-state FSM (IDLE → FADING_OUT → LOADING → FADING_IN → IDLE). 비동기 로딩은 `ResourceLoader.load_threaded_request()` + `_process()` 폴링. 전환 중 씬 루트 `PROCESS_MODE_DISABLED`, SceneTransitionManager 자신은 `PROCESS_MODE_ALWAYS` 유지.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `ResourceLoader.load_threaded_request()` / `load_threaded_get_status()` / `load_threaded_get()` — Godot 4.0+ 안정. `get_tree().change_scene_to_packed()` — 4.x 안정. `PROCESS_MODE_DISABLED` / `PROCESS_MODE_INHERIT` / `PROCESS_MODE_ALWAYS` — 4.x 안정. `Tween` 생성 패턴: `create_tween()` (4.x 권장, `SceneTreeTween` 사용).

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload 등록 순서 8번, `*res://src/core/scene_transition_manager.gd`
- Required: `SceneTransitionManager` 자신은 항상 `PROCESS_MODE_ALWAYS` — 폴링 중단 방지
- Required: `get_tree().change_scene_to_packed()` 호출은 SceneTransitionManager 내부에서만
- Forbidden: 다른 노드에서 `SceneTree.change_scene_to_file()` / `change_scene_to_packed()` 직접 호출

---

## Acceptance Criteria

*From GDD `design/gdd/씬전환-시스템.md`:*

**FSM 중복 요청 방어:**
- [ ] 전환 진행 중 `request_transition()` 재호출 시 두 번째 요청은 무시되고 `push_warning()` 1회 출력 (AC-2)
- [ ] `is_transitioning()` → 전환 중 `true`, IDLE 상태 `false` (AC-2 보조)

**process_mode 계약:**
- [ ] 전환 시작 시 현재 씬 루트 `process_mode == PROCESS_MODE_DISABLED` (AC-5a)
- [ ] 전환 완료(`transition_completed` 발행) 후 새 씬 루트 `process_mode == PROCESS_MODE_INHERIT` (AC-5b)
- [ ] SceneTransitionManager 자신의 `process_mode` 는 전환 중에도 `PROCESS_MODE_ALWAYS` 유지 (AC-5c)

**에러 복구:**
- [ ] 잘못된 `scene_path` 전달 시 크래시 없이 `push_error()` 1회, `state → IDLE` 복귀, 오버레이 유지 (AC-6)

---

## Implementation Notes

*Derived from ADR-0003 + GDD R-1~R-6:*

```gdscript
# src/core/scene_transition_manager.gd
extends Node

signal transition_completed(scene_path: String)

enum State { IDLE, FADING_OUT, LOADING, FADING_IN }
enum TransitionType { DEFAULT, INSTANT, CUT }

const FADE_OUT_DURATION: float = 0.3
const FADE_IN_DURATION: float = 0.4

var _state: State = State.IDLE
var _target_path: String = ""
var _overlay: ColorRect

func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    _setup_overlay()

func request_transition(scene_path: String, spawn_point_id: String = "",
        transition_type: TransitionType = TransitionType.DEFAULT,
        metadata: Dictionary = {}) -> void:
    if _state != State.IDLE:
        push_warning("SceneTransitionManager: transition already in progress, dropping request for: " + scene_path)
        return
    _target_path = scene_path
    _begin_fade_out(spawn_point_id, transition_type, metadata)

func is_transitioning() -> bool:
    return _state != State.IDLE

func _begin_fade_out(spawn_point_id: String, type: TransitionType, meta: Dictionary) -> void:
    _state = State.FADING_OUT
    # 현재 씬 루트 DISABLED
    var current_scene := get_tree().current_scene
    if current_scene:
        current_scene.process_mode = PROCESS_MODE_DISABLED
    # 페이드 아웃 트윈
    _overlay.visible = true
    var tween := create_tween()
    tween.tween_property(_overlay, "modulate:a", 1.0, FADE_OUT_DURATION)
    await tween.finished
    _begin_loading(spawn_point_id, meta)

func _begin_loading(spawn_point_id: String, meta: Dictionary) -> void:
    _state = State.LOADING
    ResourceLoader.load_threaded_request(_target_path)
    # _process()에서 폴링

func _process(_delta: float) -> void:
    if _state != State.LOADING:
        return
    var progress: Array = []
    var status := ResourceLoader.load_threaded_get_status(_target_path, progress)
    match status:
        ResourceLoader.THREAD_LOAD_LOADED:
            _swap_scene()
        ResourceLoader.THREAD_LOAD_FAILED:
            push_error("SceneTransitionManager: failed to load: " + _target_path)
            _state = State.IDLE  # 오버레이 유지, 검은 화면

func _swap_scene() -> void:
    var packed: PackedScene = ResourceLoader.load_threaded_get(_target_path)
    get_tree().change_scene_to_packed(packed)
    await get_tree().process_frame
    # 새 씬 루트 DISABLED (페이드 인 완료 전)
    var new_scene := get_tree().current_scene
    if new_scene:
        new_scene.process_mode = PROCESS_MODE_DISABLED
    _begin_fade_in()

func _begin_fade_in() -> void:
    _state = State.FADING_IN
    var tween := create_tween()
    tween.tween_property(_overlay, "modulate:a", 0.0, FADE_IN_DURATION)
    await tween.finished
    _overlay.visible = false
    # 새 씬 루트 INHERIT 복귀
    var new_scene := get_tree().current_scene
    if new_scene:
        new_scene.process_mode = PROCESS_MODE_INHERIT
    _state = State.IDLE
    transition_completed.emit(_target_path)

func _setup_overlay() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 128
    add_child(layer)
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 1)
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.modulate.a = 0.0
    _overlay.visible = false
    layer.add_child(_overlay)
```

---

## Out of Scope

- Story 002: SpawnPoint 조회·폴백·플레이어 스폰 위치 설정
- AudioManager 연동 — AudioManager epic 완성 후 통합
- metadata 전달 (`_on_scene_ready()`) — 다운스트림 씬 구현 시 추가

---

## QA Test Cases

- **AC-2**: 중복 요청 무시
  - Given: SceneTransitionManager, `_state = FADING_OUT` (전환 진행 중)
  - When: `request_transition("res://scenes/other.tscn")` 재호출
  - Then: `push_warning()` 1회, `_target_path` 변경 없음, `_state` 유지

- **AC-2 보조**: is_transitioning()
  - Given: IDLE 상태
  - When: `is_transitioning()` 호출
  - Then: false
  - Edge cases: FADING_OUT / LOADING / FADING_IN 상태에서 → true

- **AC-5a**: 전환 시작 시 씬 루트 DISABLED
  - Given: 현재 씬 루트가 있는 상태
  - When: `request_transition()` 호출 후 FADING_OUT 진입 (mock 씬 루트 사용)
  - Then: 씬 루트 `process_mode == PROCESS_MODE_DISABLED`

- **AC-5b**: 전환 완료 후 새 씬 루트 INHERIT
  - Given: 전환 시뮬레이션 완료 (mock 사용)
  - When: `transition_completed` 신호 발행 시점
  - Then: 새 씬 루트 `process_mode == PROCESS_MODE_INHERIT`

- **AC-5c**: SceneTransitionManager 자신 PROCESS_MODE_ALWAYS
  - Given: SceneTransitionManager `_ready()` 완료
  - When: `process_mode` 조회
  - Then: `PROCESS_MODE_ALWAYS`

- **AC-6**: 잘못된 scene_path 에러 복구
  - Given: `_state = LOADING`, `STATUS_FAILED` 반환 시뮬레이션
  - When: `_process()` 1회 실행
  - Then: `push_error()` 1회, `_state == IDLE`, `_overlay.visible == true`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/scene/scene_transition_fsm_test.gd` — GUT 테스트, 위 6개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer, 독립 초기화)
- Unlocks: Story 002 (scene-transition-manager), 맵/지역 시스템 epic

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: 6/6 passing
**Deviations**:
- ADVISORY: ADR-0003 mentions `get_tree().paused = true` but implementation uses per-node `PROCESS_MODE_DISABLED` on scene root — story ACs explicitly required this approach. Recommend clarifying ADR-0003.
**Test Evidence**: Logic — `tests/unit/scene/scene_transition_fsm_test.gd` (15 tests, 6 AC groups covered)
**Code Review**: Complete (CHANGES REQUIRED → fixes applied → APPROVED)
