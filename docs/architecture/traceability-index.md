# Architecture Traceability Index

> Last Updated: 2026-04-28
> Engine: Godot 4.6 (Compatibility Renderer, GDScript)
> Review: `docs/architecture/architecture-review-2026-04-28.md`

## Coverage Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered | 47 | 100% |
| ⚠️ Partial | 0 | 0% |
| ❌ Gaps | 0 | 0% |
| **Total** | **47** | **100%** |

---

## Full Traceability Matrix

### Foundation Layer (ADR-0001, ADR-0002)

| TR-ID | GDD | 요구사항 요약 | ADR | Status |
|---|---|---|---|---|
| TR-npc-001 | NPC-상태-관리.md | NPCRegistry Autoload — NPC 상태 전역 단일 접근 경로 | ADR-0001 | ✅ |
| TR-npc-002 | NPC-상태-관리.md | get_npc() 호출 시 duplicate_deep()으로 스냅샷 반환 | ADR-0001 | ✅ |
| TR-npc-003 | NPC-상태-관리.md | set_state()로 RelationshipState 변경, npc_state_changed 신호 발행 | ADR-0001 | ✅ |
| TR-npc-004 | NPC-상태-관리.md | is_initialized guard + registry_initialized 신호 (타이밍 안전) | ADR-0002 | ✅ |
| TR-npc-005 | NPC-상태-관리.md | MAX_PARTY_SIZE = 3 — PartyManager 소유, COMPANION 전환 시 검사 | ADR-0002 | ✅ |
| TR-item-001 | 아이템-데이터베이스.md | ItemDB Autoload — 아이템 정의 전역 읽기 전용 접근 경로 | ADR-0001 | ✅ |
| TR-item-002 | 아이템-데이터베이스.md | get()/has() 읽기 전용 인터페이스만 노출, 런타임 수정 금지 | ADR-0001 | ✅ |
| TR-item-003 | 아이템-데이터베이스.md | _validate_definitions() + error_occurred 신호 (로드 오류 감지) | ADR-0002 | ✅ |
| TR-input-001 | 입력-매핑-시스템.md | InputMapManager Autoload — 액션 바인딩 전역 관리 | ADR-0002 | ✅ |
| TR-input-002 | 입력-매핑-시스템.md | is_ui_active context separation — UI 활성 시 gameplay 입력 차단 | ADR-0002 | ✅ |
| TR-input-003 | 입력-매핑-시스템.md | ConfigFile 기반 키 바인딩 영속성 (user://input_bindings.cfg) | ADR-0002 | ✅ |
| TR-input-004 | 입력-매핑-시스템.md | physical_keycode 기반 저장 (Godot 4.5 best practice) | ADR-0002 | ✅ |
| TR-audio-001 | 오디오-매니저.md | AudioManager Autoload — SFX/BGM 전역 재생 관리 | ADR-0002 | ✅ |
| TR-audio-002 | 오디오-매니저.md | 3 Audio buses (Master, Music, SFX) 버스 구조 | ADR-0002 | ✅ |
| TR-audio-003 | 오디오-매니저.md | SFX pool 8개 — 동시 재생 지원, 오버플로 시 오래된 것 재사용 | ADR-0002 | ✅ |
| TR-inv-001 | 인벤토리-시스템.md | Inventory Autoload — 아이템 수량 전역 관리 | ADR-0002 | ✅ |
| TR-inv-002 | 인벤토리-시스템.md | Dictionary 기반 {item_id→quantity} 저장, add/remove/has 인터페이스 | ADR-0002 | ✅ |
| TR-party-001 | 파티-매니저.md | PartyManager Autoload — 파티 멤버십 전역 관리 | ADR-0002 | ✅ |
| TR-party-002 | 파티-매니저.md | register_companion() — MAX_PARTY_SIZE(3) 초과 시 실패 | ADR-0002 | ✅ |
| TR-ebus-001 | 이벤트-버스.md | EventBus Autoload — companion_join_requested 크로스-시스템 신호 | ADR-0002 | ✅ |
| TR-quest-001 | 퀘스트-상태-머신.md | QuestManager Autoload — 3-state FSM (NOT_STARTED/ACTIVE/COMPLETED) | ADR-0002 | ✅ |
| TR-quest-002 | 퀘스트-상태-머신.md | 완료 조건 자동 평가 (NPC 상태, 아이템, 위치 기반 notify 메서드) | ADR-0002 | ✅ |

### Scene / Map / UI Layer (ADR-0003)

| TR-ID | GDD | 요구사항 요약 | ADR | Status |
|---|---|---|---|---|
| TR-scene-001 | 씬전환-시스템.md | 씬 전환 중 PROCESS_MODE_DISABLED — 모든 게임플레이 노드 일시 정지 | ADR-0003 | ✅ |
| TR-scene-002 | 씬전환-시스템.md | ResourceLoader.load_threaded_request() 비동기 씬 로딩 | ADR-0003 | ✅ |
| TR-scene-003 | 씬전환-시스템.md | 4-state FSM: IDLE → FADING_OUT → LOADING → FADING_IN → IDLE | ADR-0003 | ✅ |
| TR-scene-004 | 씬전환-시스템.md | SpawnPoint 그룹 명명 규칙 — SpawnPoint_{id}, SpawnPoint_Default 폴백 | ADR-0003 | ✅ |
| TR-map-001 | 맵-지역-시스템.md | TileMapLayer + NavigationRegion2D 맵 구성 (TileMap 사용 금지) | ADR-0003 | ✅ |
| TR-map-002 | 맵-지역-시스템.md | Area2D 포탈 + EnemySpawnZone 노드 필수 포함 | ADR-0003 | ✅ |
| TR-map-003 | 맵-지역-시스템.md | 포탈 진입 전 DialogueManager.is_active() == false 확인 | ADR-0003 | ✅ |
| TR-dial-001 | 대화-시스템.md | DialogueManager CanvasLayer 오버레이, grab_focus(), is_active 씬 전환 차단 | ADR-0003 | ✅ |

### Core Layer (ADR-0004, ADR-0005)

| TR-ID | GDD | 요구사항 요약 | ADR | Status |
|---|---|---|---|---|
| TR-health-001 | 체력-데미지-시스템.md | HealthComponent 컴포넌트 패턴 — 플레이어·동료·적 동일 노드 | ADR-0004 | ✅ |
| TR-health-002 | 체력-데미지-시스템.md | final_damage = max(1, damage - defense) — 방어력 아무리 높아도 최소 1 | ADR-0004 | ✅ |
| TR-health-003 | 체력-데미지-시스템.md | health_depleted() 이후 사망 처리는 캐릭터 컨트롤러에 위임 | ADR-0004 | ✅ |
| TR-hitbox-001 | 히트박스-충돌-감지.md | 모든 전투 판정은 Area2D Hitbox/Hurtbox 기반 (PhysicsBody 직접 충돌 금지) | ADR-0004 | ✅ |
| TR-hitbox-002 | 히트박스-충돌-감지.md | 7개 Physics 레이어 번호 고정 — world/player_body/enemy_body/player_hitbox/enemy_hitbox/player_hurtbox/enemy_hurtbox | ADR-0004 | ✅ |
| TR-hitbox-003 | 히트박스-충돌-감지.md | Iframes DURATION = 0.5초, HurtboxArea2D.monitoring 토글로 다단 피격 방지 | ADR-0004 | ✅ |
| TR-player-001 | 플레이어-캐릭터-컨트롤러.md | PlayerController — CharacterBody2D + move_and_slide() 이동 | ADR-0004 | ✅ |
| TR-player-002 | 플레이어-캐릭터-컨트롤러.md | 플레이어 씬 루트 구조가 동료·적과 동일 (CharacterBody2D + HealthComponent + Hurtbox + Hitbox) | ADR-0004 | ✅ |
| TR-player-003 | 플레이어-캐릭터-컨트롤러.md | HitboxArea2D는 공격 애니메이션 프레임에서만 monitoring = true | ADR-0004 | ✅ |
| TR-stats-001 | 능력치-시스템.md | 플레이어·동료·적 모두 동일한 CharacterStats Resource 클래스 사용 | ADR-0005 | ✅ |
| TR-stats-002 | 능력치-시스템.md | base_* + mod_* 두 층 구조 — 영구값(레벨업)과 임시값(버프/디버프) 분리 | ADR-0005 | ✅ |
| TR-stats-003 | 능력치-시스템.md | 스탯 변경 시 stats_changed(stat_name: StringName) 신호 발행 | ADR-0005 | ✅ |
| TR-stats-004 | 능력치-시스템.md | 런타임 인스턴스는 stats_template.duplicate()로 생성 — 템플릿 .tres 원본 보호 | ADR-0005 | ✅ |

### Feature Layer (ADR-0006)

| TR-ID | GDD | 요구사항 요약 | ADR | Status |
|---|---|---|---|---|
| TR-ai-001 | 동료-AI-시스템.md | CompanionAI — NavigationAgent2D 기반 3-state FSM (FOLLOWING/CHASING/ATTACKING/DEAD) | ADR-0006 | ✅ |
| TR-ai-002 | 동료-AI-시스템.md | EnemyAI — NavigationAgent2D 기반 3-state FSM (IDLE/CHASING/ATTACKING/DEAD) | ADR-0006 | ✅ |
| TR-combat-001 | 실시간-파티-전투.md | CombatEncounter 노드 — 구역 내 모든 적 처치 시 combat_cleared(encounter_id) 발행 | ADR-0006 | ✅ |
| TR-combat-002 | 실시간-파티-전투.md | EnemySpawnZone — enemy_count = base(3) + companion_count × 1 동적 결정 | ADR-0006 | ✅ |

---

## Known Gaps

없음 — 47/47 커버됨.

## Superseded Requirements

없음.

## History

| Date | Covered | Partial | Gaps | Total | Notes |
|---|---|---|---|---|---|
| 2026-04-28 | 47 | 0 | 0 | 47 | 초기 리뷰 — ADR-0001~0006 완성 후 |
