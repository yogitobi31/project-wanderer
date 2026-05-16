# Architecture Review Report

> **Date**: 2026-04-28
> **Engine**: Godot 4.6 (Compatibility Renderer, GDScript)
> **GDDs Reviewed**: 20 (MVP 시스템 전체, systems-index.md 기준)
> **ADRs Reviewed**: 6 (ADR-0001 ~ ADR-0006)
> **Verdict**: ✅ **PASS**

---

## Traceability Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered | 47 | 100% |
| ⚠️ Partial | 0 | 0% |
| ❌ Gaps | 0 | 0% |
| **Total** | **47** | **100%** |

### ADR별 커버 분포

| ADR | 제목 | 커버 TR | 커버 수 |
|---|---|---|---|
| ADR-0001 | Data Registry Autoload | TR-npc-001~003, TR-item-001~002 | 5 |
| ADR-0002 | Foundation Autoload 등록 순서 및 초기화 계약 | TR-npc-004~005, TR-item-003, TR-input-001~004, TR-audio-001~003, TR-inv-001~002, TR-party-001~002, TR-ebus-001, TR-quest-001~002 | 17 |
| ADR-0003 | 씬 전환·맵 구조·UI 오버레이 계약 | TR-scene-001~004, TR-map-001~003, TR-dial-001 | 8 |
| ADR-0004 | 전투 시스템 계약 (물리 레이어·데미지·HealthComponent) | TR-health-001~003, TR-hitbox-001~003, TR-player-001~003 | 9 |
| ADR-0005 | CharacterStats Resource 패턴 | TR-stats-001~004 | 4 |
| ADR-0006 | AI 내비게이션 계약 | TR-ai-001~002, TR-combat-001~002 | 4 |

---

## Cross-ADR Conflicts

### ⚠️ MINOR — ADR-0004 vs architecture.md: HealthComponent 인터페이스 표현 차이

| 항목 | 내용 |
|---|---|
| **Type** | Integration contract (표현 차이, 의미 충돌 아님) |
| **architecture.md (line 387)** | `func take_damage(raw_atk: int, raw_def: int) -> void` |
| **ADR-0004** | `hit_confirmed(attack_data: Dictionary)` 신호 수신 후 attack_data["damage"]에서 추출 |
| **Impact** | ADR이 architecture.md보다 상세하고 신호 체인을 명시함. 두 표현 모두 `max(1, atk - def)` 공식을 결론으로 가짐. |
| **Resolution** | ADR-0004가 우선 (ADR이 architecture.md를 supersede). Stories 작성 시 ADR-0004를 참조. architecture.md는 차후 업데이트 (비차단). |

### 그 외 충돌 — 없음

| 검사 항목 | 결과 |
|---|---|
| ADR-0005 `stats.atk`, `stats.def` → ADR-0004 데미지 공식 입력 | ✅ 일치 |
| ADR-0005 `stats.spd` → ADR-0006 NavigationAgent2D 이동 속도 | ✅ 일치 |
| ADR-0006 CharacterBody2D + Hitbox → ADR-0004 7-레이어 구조 | ✅ 일치 |
| ADR-0006 `PartyManager.companion_count` → ADR-0002 Track 1 | ✅ 일치 |
| ADR-0004 `health_depleted` → ADR-0006 DEAD 상태 진입 | ✅ 일치 |
| ADR-0005 `duplicate()` shallow copy → ADR-0001 `duplicate_deep()` (NPCRegistry) | ✅ 무충돌 — CharacterStats는 primitive 필드만, NPCRegistry는 중첩 Resource |

---

## ADR Dependency Order

위상정렬 — 올바른 구현 순서:

```
Foundation (의존성 없음):
  1. ADR-0001 — Data Registry Autoload

Foundation 의존:
  2. ADR-0002 — Foundation Autoload 등록 순서 (← ADR-0001)
  3. ADR-0005 — CharacterStats Resource 패턴 (← ADR-0001)

Core 의존:
  4. ADR-0003 — 씬·맵·UI 오버레이 계약 (← ADR-0001, ADR-0002)
  5. ADR-0004 — 전투 시스템 계약 (← ADR-0002)

Feature 의존:
  6. ADR-0006 — AI 내비게이션 계약 (← ADR-0004, ADR-0005)
```

- 순환 의존: 없음
- 미해결 의존성: 없음 (모든 ADR Accepted)

---

## Engine Compatibility Audit

**Engine Compatibility 섹션 보유**: 6 / 6 (100%)

| ADR | Post-Cutoff API | 검증 출처 | 결과 |
|---|---|---|---|
| ADR-0001 | `duplicate_deep()` (4.5+) | `breaking-changes.md` L40 — "Resources: duplicate_deep() added" | ✅ 확인됨 |
| ADR-0002 | `physical_keycode` 저장 (4.5) | `breaking-changes.md` L46 — "SDL3 gamepad driver" 함께 4.5 변경 | ✅ 확인됨 |
| ADR-0003 | `TileMapLayer` (4.3 대체) | `deprecated-apis.md` L12 — TileMap → TileMapLayer | ✅ 확인됨 |
| ADR-0003 | `grab_focus()` dual-focus (4.6) | `breaking-changes.md` L16 — "Dual-focus system" | ✅ 확인됨 |
| ADR-0004 | 없음 — Area2D, CharacterBody2D stable | — | ✅ 안전 |
| ADR-0005 | 없음 — Resource, @export stable | — | ✅ 안전 |
| ADR-0006 | `NavigationAgent2D` (4.5 dedicated 2D server) | `navigation.md` L41~54, `breaking-changes.md` L41 | ⚠️ MEDIUM — 프로파일링 필요 (ADR에 명시) |

**Deprecated API 참조**: 없음 ✅
**Stale Version 참조**: 없음 — 모든 ADR Godot 4.6 명시 ✅

---

## GDD Revision Flags

**없음** — 모든 GDD 가정이 검증된 엔진 동작과 일치합니다.

ADR-0006의 NavigationAgent2D avoidance MEDIUM 위험은 GDD 가정 충돌이 아닌 성능 검증 필요 항목입니다. 프로토타입 단계에서 프로파일링 후 ADR-0006에 결과 기록.

---

## Architecture Document Coverage

`docs/architecture/architecture.md` (TD APPROVED 2026-04-27) 검증:

| 항목 | 결과 |
|---|---|
| 20개 GDD 시스템 모두 레이어 맵에 포함 | ✅ |
| 크로스-시스템 통신 데이터 플로우 4개 시나리오 명시 | ✅ |
| API 경계가 모든 통합 요건 지원 | ✅ |
| 고아 아키텍처 없음 (GDD 없는 시스템 없음) | ✅ |

**Open Questions 처리 상태**:

| 질문 | 처리 방식 | 차단 여부 |
|---|---|---|
| `grab_focus()` dual-focus 실기기 검증 | ADR-0003 Verification Required 위임 | 비차단 |
| NavigationAgent2D avoidance 60fps 프로파일링 | ADR-0006 Verification Required + 프로토타입 | 비차단 |
| SaveManager 직렬화 포맷 | MVP 이후 별도 GDD | 비차단 |
| HUD GDD 미작성 | Feature Layer 시작 전 작성 필요 | Feature 구현 전 필요 |

---

## Verdict: ✅ PASS

### Blocking Issues

없음 — Pre-Production 게이트 진입 가능.

### 비차단 권장 사항

1. **architecture.md 인터페이스 동기화** (비차단): HealthComponent `take_damage()` 표기를 ADR-0004의 `hit_confirmed` 신호 패턴으로 정렬
2. **HUD GDD 작성**: 체력바·파티 상태 UI (Feature Layer 구현 시작 전)
3. **NavigationAgent2D avoidance 프로토타입**: 동료 3명 + 적 6명 동시 60fps 검증 → 결과를 ADR-0006에 기록
4. **다음 단계**: `/create-epics` — GDD + ADR → Epic 변환

### Gate Guidance

모든 차단 이슈가 해결되었습니다. `/gate-check pre-production`을 실행하여 Pre-Production 단계 진입을 확인하세요.

---

## Files Written

- `docs/architecture/architecture-review-2026-04-28.md` ← this file
- `docs/architecture/traceability-index.md`
- `docs/architecture/tr-registry.yaml`
