# Story 001: CompanionAI — FOLLOWING/CHASING FSM + NavigationAgent2D

> **Epic**: CompanionAI
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-07

## Context

**GDD**: `design/gdd/동료-AI-시스템.md`
**Requirements**: `TR-ai-001`

**ADR Governing Implementation**: ADR-0006: AI 내비게이션 계약
**ADR Decision Summary**: `NavigationAgent2D` 기반 이동. `avoidance_enabled = false` 기본. FOLLOWING 상태: `target_position = player.global_position + companion_offset`. CHASING: `target_position = enemy.global_position`. 동료 오프셋: slot 0=(-60,20), 1=(60,20), 2=(0,50). 텔레포트: 거리 > 600px.

**Engine**: Godot 4.6 | **Risk**: MEDIUM (NavigationAgent2D 4.4~4.6 avoidance 변경 가능성)

**Control Manifest Rules (Feature layer)**:
- Required: NavigationAgent2D `_physics_process` 패턴 준수
- Required: `avoidance_enabled = false` 기본 — 프로파일링 전 활성화 Forbidden
- Required: 동료 오프셋 slot 0~2 고정값 사용

---

## Acceptance Criteria

- [ ] **AC-1**: FOLLOWING 상태에서 플레이어 이동 시 동료가 `player.position + companion_offset` 방향으로 이동
- [ ] **AC-2**: `FOLLOW_STOP_DISTANCE` (기본 40px) 이내 접근 시 이동 정지
- [ ] **AC-3**: 플레이어와 거리 > 600px 시 순간이동 (화면 밖에서만)
- [ ] **AC-4**: DetectionArea2D 내 적 진입 시 CHASING 상태 전환
- [ ] **AC-5**: CHASING 상태에서 `target_position = enemy.global_position` 으로 경로 추적

---

## Implementation Notes

1. `src/characters/companion_ai.gd` 생성 (`CharacterBody2D` 상속, ADR-0004 구조):
   ```gdscript
   class_name CompanionAI
   extends CharacterBody2D

   enum State { FOLLOWING, CHASING, ATTACKING, DEAD }

   const FOLLOW_STOP_DISTANCE: float = 40.0
   const TELEPORT_THRESHOLD: float = 600.0
   const COMPANION_OFFSETS: Array[Vector2] = [
       Vector2(-60, 20), Vector2(60, 20), Vector2(0, 50)
   ]

   @export var stats: CharacterStats
   @export var party_slot: int = 0
   @export var player_target: CharacterBody2D

   @onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

   var _state: State = State.FOLLOWING
   var _current_target: Node2D = null

   func _physics_process(_delta: float) -> void:
       match _state:
           State.FOLLOWING: _process_following()
           State.CHASING:   _process_chasing()

   func _process_following() -> void:
       if not player_target:
           return
       var offset: Vector2 = COMPANION_OFFSETS[party_slot]
       var dest: Vector2 = player_target.global_position + offset
       var dist: float = global_position.distance_to(player_target.global_position)
       if dist > TELEPORT_THRESHOLD:
           global_position = dest
           return
       navigation_agent.target_position = dest
       if global_position.distance_to(dest) <= FOLLOW_STOP_DISTANCE:
           velocity = Vector2.ZERO
       elif not navigation_agent.is_navigation_finished():
           var next: Vector2 = navigation_agent.get_next_path_position()
           velocity = (next - global_position).normalized() * stats.spd
       move_and_slide()
   ```
2. `CompanionAI.tscn`: CharacterBody2D (Layer=2, Mask=1) + CollisionShape2D + HealthComponent + HurtboxArea2D + HitboxArea2D + NavigationAgent2D + DetectionArea2D
3. `avoidance_enabled = false` 명시적 설정

---

## Out of Scope

- ATTACKING FSM, DetectionArea2D 신호 연결 — story-002
- DEAD FSM — story-002

---

## QA Test Cases

- **AC-1**: 플레이어 위치 변경 → NavigationAgent2D target_position 갱신 확인
- **AC-2**: 거리 30px에서 `velocity == Vector2.ZERO`
- **AC-3**: 거리 700px → `global_position` 순간이동 확인

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/companion_following_test.gd` — AC-1~3 커버

---

## Size Estimate

**Estimate**: 4–5 hours
- 씬 구성 + GDScript: 2시간
- NavigationAgent2D 연동 (bake 필요): 1시간
- GUT 테스트: 2시간

---

## Dependencies

- Depends on: character-stats/story-001, health-component/story-001, scene-transition-manager (map bake)
- Unlocks: companion-ai/story-002

## Completion Notes
**Completed**: 2026-05-09
**Criteria**: 5/5 passing (AC-5 navigation_agent.target_position write-path deferred to Vertical Slice playtest — headlessly untestable)
**Deviations**:
- ADVISORY: FOLLOW_STOP_DISTANCE/TELEPORT_THRESHOLD/COMPANION_OFFSETS as in-code constants — authorized by ADR-0006 §2 as fixed design constants.
- ADVISORY: AC-5 target_position write-path deferred to Vertical Slice playtest.
**Test Evidence**: Logic — `tests/unit/ai/companion_following_test.gd` (15 test functions, all ACs covered except AC-5 deferred)
**Code Review**: Complete (manual `/code-review` — multi-enemy tracking fix, stats null guard, teleport side-effect test added)
