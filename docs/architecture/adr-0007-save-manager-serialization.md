# ADR-0007: SaveManager — 직렬화 포맷·저장 계약·Autoload 순서

## Status
Accepted

## Date
2026-05-06

## Last Verified
2026-05-06

## Decision Makers
Juwon + Technical Director

## Summary

퀘스트 상태, 인벤토리, NPC 상태, 파티 구성, 플레이어 위치를 씬 전환 후에도 유지하려면 세이브 시스템이 필요하다. MVP 단일 저장 슬롯 기준으로 **JSON + FileAccess** 방식을 채택하고, 각 Autoload가 `get_save_data()` / `load_save_data()` 인터페이스를 구현해 SaveManager가 오케스트레이션하는 구조로 결정한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Persistence) |
| **Knowledge Risk** | LOW — `FileAccess`, `JSON` API는 Godot 4.0에서 안정화됨 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | `FileAccess.open()` null-on-failure 패턴 (Godot 4.x 표준) |
| **Verification Required** | `FileAccess.open()` 반환값이 null일 때 오류 경로 정상 처리 확인 (Godot 3의 ERR_* 코드 패턴과 다름) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Accepted) — SaveManager는 9번째 Autoload로 등록. 모든 데이터 Autoload 초기화 완료 후 등록 |
| **Enables** | 세이브/로드 기능이 필요한 모든 Core·Feature 스토리 |
| **Blocks** | None — SaveManager 없이 MVP 게임 루프는 가능하나 진행 저장 불가 |
| **Ordering Note** | ADR-0002의 Autoload 등록 순서: EventBus(1) → ItemDB(2) → NPCRegistry(3) → PartyManager(4) → Inventory(5) → QuestManager(6) → InputMapManager(7) → SceneTransitionManager(8) → **SaveManager(9)** → AudioManager(10) |

## Context

### Problem Statement

9개 Autoload(EventBus, ItemDB, NPCRegistry, PartyManager, Inventory, QuestManager, InputMapManager, SceneTransitionManager, AudioManager)가 런타임 상태를 메모리에서 관리한다. 게임 종료 후 이 상태를 복원하려면 직렬화 포맷, 저장 위치, 저장/복원 오케스트레이션 계약을 지금 결정해야 한다. 결정 없이 스토리가 구현되면 각 시스템이 독자적인 저장 방식을 선택해 나중에 통합이 불가능해진다.

### Current State

신규 프로젝트. 세이브 시스템 없음. MVP 게임 루프(동료 영입 3회, 전투, 퀘스트)는 단일 세션으로 플레이 가능하지만 진행 저장 기능이 없다.

### Constraints

- GDScript 싱글스레드 — 저장/로드 중 메인 스레드가 블로킹됨. MVP 세이브 파일은 수 KB 이하이므로 허용 범위 내.
- `user://` 디렉터리: Steam/PC 플랫폼에서 플랫폼별 앱 데이터 경로로 자동 매핑됨. 직접 경로 조작 불필요.
- MVP 단일 슬롯: 세이브 슬롯 선택 UI 없음. `save_001.json` 단일 파일.
- Post-MVP 스코프 제외: 클라우드 저장, 암호화, 다중 슬롯, 자동 저장.

### Requirements

- TR-save-001: QuestManager 퀘스트 상태(`NOT_STARTED / ACTIVE / COMPLETED`) 저장·복원
- TR-save-002: Inventory 아이템 목록(item_id, quantity) 저장·복원
- TR-save-003: NPCRegistry 관계 상태(`RelationshipState` enum) 저장·복원
- TR-save-004: PartyManager 파티 구성(companion_id 배열) 저장·복원
- TR-save-005: 플레이어 현재 씬 경로 + 스폰 포인트 이름 저장·복원
- TR-save-006: 저장 파일 없을 때 `has_save()` = false, 로드 시도 무시

## Decision

### 1. 직렬화 포맷: JSON + FileAccess

```gdscript
# 저장 예시
func save_game() -> void:
    var data: Dictionary = _collect_save_data()
    var json_string: String = JSON.stringify(data, "\t")
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager: 파일 열기 실패 — %s" % SAVE_PATH)
        return
    file.store_string(json_string)
    # FileAccess는 scope 종료 시 자동 close

# 로드 예시
func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        push_error("SaveManager: 세이브 파일 없음")
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("SaveManager: 파일 읽기 실패")
        return
    var json_string: String = file.get_as_text()
    var data: Variant = JSON.parse_string(json_string)
    if not data is Dictionary:
        push_error("SaveManager: JSON 파싱 실패")
        return
    _distribute_save_data(data)
```

**채택 이유**: 사람이 읽을 수 있는 포맷 → 개발 중 세이브 파일 직접 편집으로 디버그 가능. Godot 4 표준 API 사용으로 플랫폼 이식성 보장.

### 2. 저장 위치

```
user://saves/save_001.json
```

`SAVE_PATH` 상수로 SaveManager에 정의. 하위 디렉터리 `saves/`는 첫 저장 시 `DirAccess.make_dir_recursive_absolute()` 로 생성.

### 3. Autoload 직렬화 계약 (인터페이스)

데이터를 가진 Autoload는 다음 두 메서드를 구현한다:

```gdscript
# 각 Autoload가 구현해야 하는 인터페이스 (GDScript — 타입 힌트 강제)
func get_save_data() -> Dictionary:
    # 이 Autoload의 현재 상태를 Dictionary로 반환
    # 반환 딕셔너리는 JSON-serializable 타입만 포함
    # (String, int, float, bool, Array, Dictionary)
    pass

func load_save_data(data: Dictionary) -> void:
    # get_save_data()가 반환한 구조와 동일한 data를 받아 상태 복원
    # data에 없는 키는 기본값으로 처리 (방어적 로드)
    pass
```

**직렬화 대상 Autoload:**

| Autoload | get_save_data() 포함 내용 |
|----------|--------------------------|
| `QuestManager` | `quests`: `{ quest_id: state_int }` |
| `Inventory` | `items`: `[ { "item_id": String, "quantity": int } ]` |
| `NPCRegistry` | `npc_states`: `{ npc_id: relationship_state_int }` |
| `PartyManager` | `party`: `[ companion_id_string ]` |

**플레이어 씬 상태** (SaveManager가 직접 관리):

```gdscript
# SaveManager 내부 — 씬 정보는 Autoload가 아닌 SaveManager가 직접 보관
var _current_scene_path: String = ""
var _spawn_point_name: String = "SpawnPoint_Default"

func record_player_location(scene_path: String, spawn_name: String) -> void:
    _current_scene_path = scene_path
    _spawn_point_name = spawn_name
```

씬 전환 완료 시 SceneTransitionManager가 `SaveManager.record_player_location()`을 호출한다.

### 4. 저장/로드 오케스트레이션

```gdscript
# SaveManager.gd
const SAVE_PATH: String = "user://saves/save_001.json"
const SAVE_VERSION: int = 1  # 세이브 포맷 버전 — 마이그레이션 키

func save_game() -> void:
    var data: Dictionary = {
        "version": SAVE_VERSION,
        "quest_manager": QuestManager.get_save_data(),
        "inventory": Inventory.get_save_data(),
        "npc_registry": NPCRegistry.get_save_data(),
        "party_manager": PartyManager.get_save_data(),
        "player_location": {
            "scene_path": _current_scene_path,
            "spawn_point": _spawn_point_name,
        }
    }
    # ... FileAccess 저장 (위 예시 참조)

func load_game() -> void:
    # ... FileAccess 로드
    QuestManager.load_save_data(data.get("quest_manager", {}))
    Inventory.load_save_data(data.get("inventory", {}))
    NPCRegistry.load_save_data(data.get("npc_registry", {}))
    PartyManager.load_save_data(data.get("party_manager", {}))
    # 씬 전환은 SceneTransitionManager에 위임
    var loc: Dictionary = data.get("player_location", {})
    SceneTransitionManager.transition_to(
        loc.get("scene_path", "res://src/scenes/main_map.tscn"),
        loc.get("spawn_point", "SpawnPoint_Default")
    )

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
```

### 5. 저장 트리거 (MVP)

명시적 세이브 포인트 — 맵에 `SavePoint` 노드 배치. 플레이어가 인터랙션 시 `SaveManager.save_game()` 호출. 자동 저장 없음 (Post-MVP 스코프).

### Architecture Diagram

```
플레이어 → SavePoint 인터랙션
                  │
                  ▼
           SaveManager.save_game()
           ┌──────────────────────────┐
           │  _collect_save_data()    │
           │  ├─ QuestManager.get_save_data()  │
           │  ├─ Inventory.get_save_data()     │
           │  ├─ NPCRegistry.get_save_data()   │
           │  ├─ PartyManager.get_save_data()  │
           │  └─ _player_location              │
           └──────────────┬───────────┘
                          │ JSON.stringify()
                          ▼
                 user://saves/save_001.json

로드 흐름 (타이틀 → 이어하기):
  SaveManager.load_game()
  ├─ QuestManager.load_save_data()
  ├─ Inventory.load_save_data()
  ├─ NPCRegistry.load_save_data()
  ├─ PartyManager.load_save_data()
  └─ SceneTransitionManager.transition_to(scene, spawn)
```

## Alternatives Considered

### Alternative 1: ConfigFile (Godot 내장 .ini 포맷)

- **Description**: `ConfigFile` 클래스로 섹션/키 기반 저장
- **Pros**: Godot 내장 API, 간단한 키-값 데이터에 적합
- **Cons**: 중첩 딕셔너리 표현이 불편. 퀘스트 상태처럼 동적 키를 가진 딕셔너리 직렬화가 JSON보다 번거로움
- **Rejection Reason**: MVP 세이브 데이터 구조(딕셔너리 중첩)에는 JSON이 더 직접적

### Alternative 2: var_to_bytes (바이너리)

- **Description**: GDScript 내장 `var_to_bytes()` / `bytes_to_var()`로 Variant 직렬화
- **Pros**: 가장 간단한 코드. 타입 정보 보존.
- **Cons**: 사람이 읽을 수 없음. 디버그 시 세이브 파일 직접 확인 불가. 포맷 변경 시 하위 호환 보장 어려움
- **Rejection Reason**: 개발 중 세이브 데이터 검사·수정이 필요한 인디 RPG에는 불적합

### Alternative 3: ResourceSaver (Godot Resource 직렬화)

- **Description**: `Resource` 서브클래스로 세이브 데이터 정의, `ResourceSaver.save()` 사용
- **Pros**: Godot 에디터에서 .tres 파일 직접 편집 가능
- **Cons**: 세이브 데이터는 런타임 가변 상태 — Resource 패턴(정적 에셋)과 의미론적 불일치. 동적 딕셔너리를 Resource로 표현하면 불필요한 복잡성
- **Rejection Reason**: 세이브 데이터는 에셋이 아니라 런타임 상태. JSON이 더 적합

## Consequences

### Positive

- 세이브 파일이 사람이 읽을 수 있는 JSON → 개발 중 수동 편집으로 빠른 상태 재현 가능
- 각 Autoload가 자신의 저장 로직을 소유 → 시스템 추가 시 SaveManager 수정 최소화
- `SAVE_VERSION` 필드로 포맷 마이그레이션 기반 준비

### Negative

- 각 Autoload가 `get_save_data()` / `load_save_data()` 구현 필요 → 스토리 공수 추가
- JSON은 GDScript 타입 정보 손실 (`StringName` → `String` 변환 필요). 로드 시 명시적 캐스팅 필요
- 저장 중 앱 종료 시 파일 손상 가능 (MVP에서 허용 — 원자적 저장 Post-MVP 스코프)

### Neutral

- `user://` 경로는 플랫폼마다 다른 절대 경로로 매핑됨 (Godot 자동 처리)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `FileAccess.open()` null 반환 미처리 | LOW | HIGH — 크래시 | `if file == null: push_error()` 가드 필수. Godot 4.x에서 Godot 3 ERR_* 패턴 혼용 금지 |
| 세이브 포맷 변경 시 구버전 파일 로드 실패 | MEDIUM | MEDIUM | `SAVE_VERSION` 필드로 마이그레이션 경로 준비. MVP 기간 단일 버전이므로 현재는 LOW 위험 |
| 중간 저장 시 파일 손상 | LOW | MEDIUM | MVP 허용. Post-MVP에서 임시 파일 → 원자적 교체 패턴으로 개선 |
| StringName ↔ String 타입 불일치 | MEDIUM | LOW | `load_save_data()` 구현 시 `StringName(data["key"])` 명시적 캐스팅 |

## Performance Implications

| Metric | Expected | Budget |
|--------|----------|--------|
| 저장 소요 시간 | < 5ms (수 KB JSON) | 16.6ms (1프레임) |
| 로드 소요 시간 | < 10ms | 씬 전환 중 — 사용자 체감 없음 |
| 세이브 파일 크기 | 5–20 KB (MVP 데이터 기준) | 제한 없음 |

저장/로드는 씬 전환 블랙스크린 중에 실행 → 메인 스레드 블로킹이 사용자에게 보이지 않음.

## Migration Plan

신규 프로젝트. 기존 세이브 파일 없음. 추후 포맷 변경 시:
1. `SAVE_VERSION` 값 증가
2. `load_game()` 내부에 버전 분기 추가
3. 구버전 파일 → 신버전 구조 마이그레이션 함수 작성

**롤백 플랜**: 세이브 파일 삭제 후 새 게임 시작. MVP 단일 슬롯이므로 롤백 비용 낮음.

## Validation Criteria

- [ ] `save_game()` 후 `user://saves/save_001.json` 파일 생성 확인 (단위 테스트)
- [ ] `load_game()` 후 QuestManager, Inventory, NPCRegistry, PartyManager 상태가 저장 시점으로 복원됨 (단위 테스트)
- [ ] `has_save()` — 파일 없을 때 `false`, 있을 때 `true` (단위 테스트)
- [ ] `FileAccess.open()` 실패 시 크래시 없이 오류 로그만 출력 (단위 테스트)
- [ ] 저장 → 앱 재시작 → 로드 → 플레이어가 저장 시점 씬·위치에서 시작 (수동 플레이테스트)

## GDD Requirements Addressed

| GDD 문서 | 시스템 | 요구사항 | 이 ADR의 해결 방식 |
|---------|--------|---------|-----------------|
| `퀘스트-상태-머신.md` Dependencies | QuestManager | "세이브/로드 시스템이 `quests` 딕셔너리 저장/복원" | QuestManager.get_save_data() / load_save_data() 계약으로 구현 |
| `NPC-상태-관리.md` | NPCRegistry | NPC 관계 상태 영속 | NPCRegistry.get_save_data()에 RelationshipState int 직렬화 |
| `인벤토리-시스템.md` | Inventory | 아이템 목록 영속 | Inventory.get_save_data()에 item_id + quantity 배열 |
| `동료-합류-이벤트.md` | PartyManager | 파티 구성 영속 | PartyManager.get_save_data()에 companion_id 배열 |

## Related

- ADR-0001: NPCRegistry Autoload (데이터 소유자)
- ADR-0002: Foundation Autoload 등록 순서 (SaveManager 등록 위치)
- ADR-0003: 씬 전환 계약 (로드 후 씬 전환 위임)
- `design/gdd/퀘스트-상태-머신.md` (저장 계약 참조)
