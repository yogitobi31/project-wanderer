# Spike: duplicate_deep() — NPCRegistry 스냅샷 무결성

**위험도**: HIGH  
**관련 ADR**: ADR-0001 (Data Registry Autoload)  
**Godot 버전**: 4.6  
**스파이크 목적**: `Resource.duplicate(true)` (deep copy)가 Godot 4.6에서 중첩 Resource를 올바르게 복사하는지 검증

---

## 배경

ADR-0001의 `get_snapshot()` 메서드는 NPCRecord 배열 전체를 deep copy하여 반환해야 한다.
NPCRecord는 `CharacterStats` Resource를 포함하는 중첩 Resource 구조다.
Godot 4.4~4.6에서 `duplicate(true)`의 중첩 Resource 처리 방식이 변경되었을 수 있다.

## 검증 대상

1. `Resource.duplicate(true)` — 중첩 Resource 참조가 독립 복사되는가?
2. 원본 수정이 복사본에 영향을 주지 않는가?
3. `Array[NPCRecord]`에서 각 원소를 duplicate(true) 했을 때 deep copy되는가?
4. `@export var stats: CharacterStats`가 있는 Resource를 duplicate(true) 하면 stats도 복사되는가?

## 테스트 시나리오

```
# 테스트 구조
# NPCRecord → CharacterStats (중첩)
# 배열 [NPCRecord, NPCRecord] 스냅샷 후 원본 변경 → 스냅샷 불변 확인

class_name SpikeRecord extends Resource
@export var name: String = ""
@export var stats: SpikeStats  # 중첩 Resource

class_name SpikeStats extends Resource  
@export var hp: int = 100
```

## 합격 기준

- [ ] `original.duplicate(true)` 후 `original.stats.hp = 999` 변경해도 copy.stats.hp = 100 유지
- [ ] `Array` deep copy 시 각 원소가 독립적으로 복사됨
- [ ] GUT 테스트로 자동화 가능

## 결과

**날짜**: 2026-05-07  
**결과**: ✅ PASS — 6/6 통과  

**발견 사항**:
- `Resource.duplicate(true)` — 중첩 Resource(`CharacterStats`) 독립 복사 정상 동작 ✅
- 원본 `stats.hp` 변경 후 복사본 `stats.hp` 불변 확인 ✅
- `duplicate(false)` — shallow copy, stats가 동일 객체 참조 확인 ✅
- `Array[SpikeRecord]` 루프 duplicate(true) 스냅샷 — 원본 변경 후 스냅샷 불변 ✅
- 복사본 변경이 원본에 영향 없음 ✅

**ADR-0001 영향**: 없음 — `get_snapshot()` 설계 확정  
`duplicate(true)` 방식으로 NPCRecord 배열 스냅샷 구현 안전. 변경 불필요.  

## 구현 파일

- `spike_record.gd` — 테스트용 NPCRecord 모사 리소스
- `spike_stats.gd` — 테스트용 CharacterStats 모사 리소스
- `spike_duplicate_deep_test.gd` — GUT 테스트 (테스트 실행: GUT 패널에서 실행)
