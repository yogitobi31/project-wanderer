# Smoke Test: Critical Paths

**Purpose**: QA 핸드오프 전 15분 이내에 실행하는 핵심 경로 체크리스트.
**Run via**: `/smoke-check` (이 파일을 읽음)
**Update**: 새 핵심 시스템이 구현될 때마다 항목 추가.

## Core Stability (항상 실행)

1. 게임이 메인 씬 없이 크래시 없이 실행됨
2. 9개 Autoload (EventBus → AudioManager) 순서대로 초기화됨
3. InputMapManager.is_ready == true (14개 액션 등록 완료)

## Foundation Layer (항상 실행)

4. NPCRegistry — NPC 등록·조회 정상 동작
5. PartyManager — 동료 등록·파티 쿼리 정상 동작
6. ItemDB — 아이템 정의 로드, _validate_definitions() 오류 없음
7. SceneTransitionManager — 씬 전환 FSM IDLE 상태에서 시작

## Core Mechanic (스프린트별 업데이트)

<!-- Vertical Slice 구현 시 핵심 루프 항목 추가 -->
8. [플레이어 이동 — PlayerController 구현 후 추가]
9. [동료 영입 흐름 — CompanionRecruitment 구현 후 추가]
10. [전투 루프 — CombatSystem 구현 후 추가]

## Data Integrity

11. Save 완료 오류 없음 (SaveManager 구현 후 활성화)
12. Load 후 상태 정상 복원 (SaveManager 구현 후 활성화)

## Performance

13. 메인 루프 60fps 유지 (타겟 하드웨어 기준)
14. 5분 플레이 후 메모리 증가 없음 (핵심 루프 구현 후 활성화)
