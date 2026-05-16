# Epic: MapScene

> **Layer**: Core
> **GDD**: design/gdd/맵-지역-시스템.md
> **Architecture Module**: MapScene (Feature)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories map-scene`

## Overview

MapScene은 각 게임 지역을 구성하는 씬 구조 계약을 구현한다. TileMapLayer(TileMap 사용 금지)로 타일 렌더링과 충돌을 처리하고, NavigationRegion2D로 AI 경로 탐색 메시를 제공한다. 포탈 Area2D가 씬 전환을 트리거하며, EnemySpawnZone으로 동적 적 스폰을 관리한다. 모든 맵 씬은 `SpawnPoint_Default`를 포함하는 "spawn_points" 그룹을 필수로 가진다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: 씬전환·맵구조·UI오버레이 계약 | TileMapLayer 강제, 필수 노드 구성(SpawnPoints, Portals, EnemySpawnZones), 포탈 진입 조건 | HIGH |
| ADR-0006: AI 내비게이션 계약 | NavigationRegion2D bake 필수, EnemySpawnZone 스케일링 공식 | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-map-001 | TileMapLayer + NavigationRegion2D 맵 구성 — TileMap 사용 금지 (4.3에서 deprecated) | ADR-0003 ✅ |
| TR-map-002 | 맵 씬 필수 노드 — Area2D 포탈, EnemySpawnZone, SpawnPoint 그룹 | ADR-0003 ✅ |
| TR-map-003 | 포탈 진입 조건 — DialogueManager.is_active() == false 확인 후 씬 전환 허용 | ADR-0003 ✅ |

## Engine Risk Note

**HIGH**: `TileMapLayer` — Godot 4.3에서 TileMap 대체. NavigationRegion2D bake와의 호환성을 첫 맵 씬 구현 시 즉시 확인 필요 (B2 스파이크 `spike-tilemaplayer` 결과 반영 필수).

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/맵-지역-시스템.md` are verified
- 프로젝트 내 TileMap 노드 없음 — `Grep "TileMap"` 확인
- 모든 맵 씬에 SpawnPoint_Default 노드 존재 — 수동 확인
- 포탈 진입 시 DialogueManager.is_active 체크 동작 — 수동 플레이테스트 확인
- NavigationRegion2D bake 후 CompanionAI 경로 탐색 정상 동작 — 수동 확인
- All Visual/Feel stories have screenshot evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories map-scene` to break this epic into implementable stories.
