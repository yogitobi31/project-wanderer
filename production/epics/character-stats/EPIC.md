# Epic: CharacterStats

> **Layer**: Core
> **GDD**: design/gdd/능력치-시스템.md
> **Architecture Module**: CharacterStats (Core)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories character-stats`

## Overview

CharacterStats는 플레이어·동료·적 모두가 공유하는 능력치 Resource 패턴을 구현한다. `base_*` 영구값과 `mod_*` 임시값을 두 층으로 분리하고, 다운스트림 시스템은 클램핑이 적용된 computed 프로퍼티(`max_hp`, `atk`, `def`, `spd`)만 읽는다. 에디터 Inspector에서 `.tres` 파일로 직접 편집 가능하며, 런타임 인스턴스는 `duplicate()`로 생성해 템플릿 원본을 보호한다. HealthComponent, PlayerController, CompanionAI 등 7개 다운스트림 시스템의 공통 데이터 계약이다.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: CharacterStats Resource 패턴 | `class_name CharacterStats extends Resource`, base_*/mod_* 두 층, computed 프로퍼티 클램핑, `duplicate()` 인스턴스, `stats_changed` 신호 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-stats-001 | 플레이어·동료·적이 동일한 CharacterStats 클래스를 사용 | ADR-0005 ✅ |
| TR-stats-002 | base_* + mod_* 두 층 구조로 영구값과 임시값 분리 | ADR-0005 ✅ |
| TR-stats-003 | 스탯 변경 시 stats_changed(stat_name) 신호 발행 | ADR-0005 ✅ |
| TR-stats-004 | 런타임 인스턴스는 duplicate()로 생성하여 템플릿 원본 보호 | ADR-0005 ✅ |
| TR-stats-005 | computed 프로퍼티에 클램핑 적용: max_hp[1,9999], atk[0,999], def[0,999], spd[10.0,600.0] | ADR-0005 ✅ |
| TR-stats-006 | GrowthRate는 CharacterStats와 별도 Resource로 분리 | ADR-0005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/능력치-시스템.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- `CharacterStats.duplicate()` 두 인스턴스가 독립적으로 동작 — 단위 테스트 통과
- computed 프로퍼티 클램핑 경계값 테스트 통과 (def=5, mod_def=-8 → 0)
- `stats_changed` 신호가 base_* 변경 시 정확히 1회 발행 — 단위 테스트 통과

## Next Step

Run `/create-stories character-stats` to break this epic into implementable stories.
