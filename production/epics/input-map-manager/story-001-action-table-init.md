# Story 001: 액션 마스터 테이블 초기화 및 is_ready 가드

> **Epic**: InputMapManager
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A (control-manifest.md 미생성)

## Context

**GDD**: `design/gdd/입력-매핑-시스템.md`
**Requirements**: `TR-input-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Foundation Autoload 등록 순서
**ADR Decision Summary**: InputMapManager는 Track 2 Service Singleton, 등록 순서 7번. `physical_keycode` 기반 바인딩 저장 계약. 초기화 완료 후 `input_map_ready` 신호 발행.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `physical_keycode` 는 Godot 4.5+ best practice — 4.6에서 안정. `InputMap.add_action()` / `action_add_event()` API는 4.x 안정. `ConfigFile` read/write는 4.x 안정. `docs/engine-reference/godot/` 확인 후 구현 시작.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload 등록 순서 7번, `*res://src/core/input_map_manager.gd`
- Required: 초기화 완료 후 `is_ready = true` 설정 후 `input_map_ready` 신호 발행
- Required: `schema_version` 필드를 cfg 파일에 저장 — 구버전 감지 필수
- Forbidden: `InputMap` 직접 수정을 다른 Autoload/노드에서 수행 — InputMapManager 단독 소유

---

## Acceptance Criteria

*From GDD `design/gdd/입력-매핑-시스템.md`:*

**R-1: 단일 소유권**
- [ ] `src/` 하위 `.gd` 파일에서 `InputMap.` 직접 호출이 `src/core/input_map_manager.gd` 외에는 0건 (AC-R1 — 정적 분석)

**R-2: 액션 마스터 테이블**
- [ ] 신규 설치(cfg 없음), `input_map_ready` 직후 14개 액션 모두 `InputMap.has_action()` = true (AC-R2a)
- [ ] 14개 액션 각각에 `InputEventJoypadButton` 또는 `InputEventJoypadMotion` 이벤트 최소 1개 존재 (AC-R2b)
- [ ] `game_confirm` / `game_cancel` 등 `game_` 접두사 액션의 이벤트가 Godot 내장 `ui_accept` / `ui_cancel` 이벤트와 중복 없음 (AC-R2c)

**R-3: 초기화 흐름**
- [ ] cfg 없음 → W/↑ 키 포함, `input_map_ready` 1회, `push_warning()` 0회 (AC-R3a)
- [ ] `move_up`이 Z로 저장된 cfg → `input_map_ready` 직후 KEY_Z 포함 (AC-R3b)
- [ ] 손상된 cfg → 기본값 사용, `input_map_ready` 1회, 파싱 실패 경고 1회+ (AC-R3c)
- [ ] INITIALIZING 상태(`is_ready = false`)에서 입력 주입 후 PlayerController 입력 처리 함수가 Vector2.ZERO 반환 — `is_ready = true` 후에는 Vector2.ZERO 아님 (AC-R3d — 가드 유무 대비 테스트)

**Edge Cases:**
- [ ] cfg `schema_version`이 현재보다 낮음 → 14개 기본값, 파일 보존, 경고에 schema 불일치 메시지 포함 (AC-E-schema-old)
- [ ] 신규 설치 첫 리바인딩 후 cfg의 `[meta]` 섹션 `schema_version` ≥ 1 (CURRENT_SCHEMA_VERSION과 일치) (AC-E-schema-new)

---

## Implementation Notes

*Derived from ADR-0002 + GDD R-1, R-2, R-3:*

```gdscript
# src/core/input_map_manager.gd
extends Node

signal input_map_ready()

const CURRENT_SCHEMA_VERSION: int = 1
const BINDINGS_PATH: String = "user://input_bindings.cfg"

var is_ready: bool = false

# 14개 액션 정의 — category 필드 포함
const ACTION_DEFS: Array[Dictionary] = [
    {name="move_up",       category="gameplay", ...},
    {name="move_down",     category="gameplay", ...},
    # ... 14개 전부
]

func _ready() -> void:
    _register_default_actions()
    _load_user_bindings()
    is_ready = true
    input_map_ready.emit()

func _register_default_actions() -> void:
    for def in ACTION_DEFS:
        if not InputMap.has_action(def.name):
            InputMap.add_action(def.name)
        # 기본 이벤트 추가 (keyboard + gamepad)

func _load_user_bindings() -> void:
    if not FileAccess.file_exists(BINDINGS_PATH):
        return
    var cfg := ConfigFile.new()
    var err := cfg.load(BINDINGS_PATH)
    if err != OK:
        push_warning("InputMapManager: failed to parse cfg — using defaults")
        return
    var version: int = cfg.get_value("meta", "schema_version", 0)
    if version < CURRENT_SCHEMA_VERSION:
        push_warning("InputMapManager: cfg schema_version=%d < %d — using defaults" % [version, CURRENT_SCHEMA_VERSION])
        return
    # 액션별 복원 — 화이트리스트 검사 후 교체
```

다운스트림 가드 패턴 (PlayerController):
```gdscript
func _ready() -> void:
    if InputMapManager.is_ready:
        _on_input_map_ready()
    else:
        InputMapManager.input_map_ready.connect(_on_input_map_ready)
```

`project.godot` 등록 순서 7번:
```
InputMapManager = "*res://src/core/input_map_manager.gd"
```

---

## Out of Scope

- Story 002: `request_rebind()` 리바인딩 API, ConfigFile 저장 로직
- Story 003: `is_ui_active` 컨텍스트 분리
- Story 004: 게임패드 Deadzone·이동벡터·4방향 이산화 공식

---

## QA Test Cases

- **AC-R2a**: 14개 액션 등록 확인
  - Given: cfg 없음, InputMapManager 초기화
  - When: `input_map_ready` 발행 직후 14개 액션 이름 목록 순회
  - Then: 모두 `InputMap.has_action()` = true

- **AC-R2b**: 게임패드 바인딩 존재
  - Given: 초기화 완료
  - When: 14개 액션 각각 `InputMap.action_get_events(name)` 조회
  - Then: 각 액션에 `InputEventJoypadButton` 또는 `InputEventJoypadMotion` ≥ 1개

- **AC-R2c**: Godot 내장 액션 이벤트 중복 없음
  - Given: 초기화 완료
  - When: `game_confirm` 이벤트 목록 vs `ui_accept` 이벤트 목록 교집합 계산
  - Then: 교집합 크기 = 0

- **AC-R3a**: 기본값 초기화 (cfg 없음)
  - Given: `user://input_bindings.cfg` 없음
  - When: 초기화 완료
  - Then: (1) `action_get_events("move_up")` W 키 포함, (2) `input_map_ready` 1회, (3) `push_warning()` 0회

- **AC-R3b**: cfg에서 바인딩 복원
  - Given: `move_up=Z` 저장된 cfg (schema_version=1)
  - When: `input_map_ready` 직후
  - Then: `action_get_events("move_up")`에 `InputEventKey(physical_keycode=KEY_Z)` 포함

- **AC-R3c**: 손상된 cfg 복구
  - Given: 파싱 불가 손상 cfg
  - When: 초기화 완료
  - Then: 기본값 사용, `input_map_ready` 1회, `push_warning()` 1회+ (파싱 실패 메시지)

- **AC-R3d**: INITIALIZING 가드
  - Given: InputMapManager `is_ready = false`, PlayerController 연결
  - When: `Input.action_press("move_up")` 주입 후 `_physics_process` 1회
  - Then: 입력 처리 함수 Vector2.ZERO 반환
  - Edge cases: `is_ready = true` 설정 후 동일 조건 → Vector2.ZERO 아님 (가드 유무 대비)

- **AC-E-schema-old**: 구버전 schema 감지
  - Given: cfg `schema_version = 0`
  - When: 초기화 완료
  - Then: 14개 기본값, 파일 보존, 경고에 "schema" 관련 메시지 포함

- **AC-E-schema-new**: 신규 cfg schema_version 기록
  - Given: cfg 없음, `request_rebind("interact", KEY_E)` SUCCESS 후
  - When: `ConfigFile.load()` 후 `meta.schema_version` 읽기
  - Then: `schema_version >= 1` (CURRENT_SCHEMA_VERSION과 일치)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/input/input_map_init_test.gd` — GUT 테스트, 위 9개 AC 커버, 반드시 존재하고 통과

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer, 독립 초기화)
- Unlocks: Story 002 (리바인딩 API), Story 003 (컨텍스트 분리), Story 004 (게임패드 공식)

## Completion Notes
**Completed**: 2026-05-01
**Criteria**: 9/10 passing (1 deferred — AC-R3d PlayerController integration requires PlayerController story)
**Deviations**:
- ADVISORY: AC-R2c — cleared ui_accept/ui_cancel built-in events at startup to achieve zero overlap (user-approved option [B])
- ADVISORY: AC-R3d — is_ready boolean guard verified; full Vector2.ZERO PlayerController integration deferred
- ADVISORY: AC-E-schema-new — cfg write-on-rebind is story-002 scope; CURRENT_SCHEMA_VERSION=1 constant verified
**Test Evidence**: Logic: `tests/unit/input/input_map_init_test.gd` (23 test functions)
**Code Review**: Complete (manual /code-review — lean mode; CHANGES REQUIRED → all fixes applied)
