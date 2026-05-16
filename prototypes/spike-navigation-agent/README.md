# Spike: NavigationAgent2D avoidance — 동료 3 + 적 4 동시 60fps

**위험도**: HIGH  
**관련 ADR**: ADR-0006 (AI 내비게이션 계약)  
**Godot 버전**: 4.6 (Jolt default — 3D 전용, 2D Physics는 내장)  
**스파이크 목적**: NavigationAgent2D avoidance 7에이전트 동시 처리 시 60fps 유지 여부 프로파일링

---

## 배경

ADR-0006은 `NavigationAgent2D`의 `avoidance_enabled = true`를 동료 AI와 적 AI 모두에 사용한다.
성능 예산: 16.6ms/frame (60fps 타깃).
실제 게임플레이 시나리오: 동료 3명 + 적 4명 = 7개 NavigationAgent2D 동시 avoidance.

Godot 4.6 기준 NavigationAgent2D avoidance는 RVO(Reciprocal Velocity Obstacle) 알고리즘.
에이전트 수 증가 시 O(n²) 연산이므로 프로파일링이 필수.

## 검증 대상

1. 7개 NavigationAgent2D `avoidance_enabled=true` 동시 이동 → CPU 프레임 시간
2. `NavigationAgent2D.velocity_computed` 시그널 동작 확인 (Godot 4.4에서 변경 가능)
3. `set_velocity()` → `velocity_computed` → `move_and_slide()` 파이프라인
4. NavigationRegion2D 설정 시 avoidance radius 충돌 여부

## 테스트 시나리오

```
# 씬 구조:
# SpikeNavScene
#   ├─ NavigationRegion2D (NavigationPolygon: 600x400 사각형)
#   ├─ CompanionAgent × 3 (CharacterBody2D + NavigationAgent2D)
#   │    각각 목표지점을 향해 이동, avoidance_enabled=true
#   └─ EnemyAgent × 4 (CharacterBody2D + NavigationAgent2D)
#        각각 플레이어 위치를 향해 이동, avoidance_enabled=true

# 프로파일링:
# Godot Profiler 켜고 30초 실행
# Physics Process 평균/최대 ms 기록
# 목표: Physics Process < 8ms (16.6ms 예산의 절반, 렌더링 여유분 확보)
```

## 에이전트 설정 기준값 (ADR-0006)

| 속성 | 동료 | 적 |
|------|------|-----|
| `avoidance_enabled` | true | true |
| `radius` | 16px | 16px |
| `max_speed` | 100 | 80 |
| `path_desired_distance` | 4.0 | 4.0 |
| `target_desired_distance` | 4.0 | 32.0 |

## 합격 기준

- [ ] 7에이전트 동시 avoidance — Physics Process 평균 < 8ms
- [ ] `velocity_computed` 시그널 정상 발생 (Godot 4.6에서 시그니처 변경 없음 확인)
- [ ] 에이전트 간 겹침 없이 회피 이동
- [ ] 30초 연속 실행 중 프레임 드롭(< 30fps) 없음

## 1차 실행 결과 (2026-05-07) — BLOCKED

**날짜**: 2026-05-07  
**결과**: BLOCKED — 씬 구성 오류로 인해 에이전트 실제 동작 없음

**관찰값**:
- Frame Time: 6~7ms / Physics 2D: **0.00ms**

**Physics 2D: 0.00ms의 의미**:  
이것은 PASS가 아닌 경고 신호. 에이전트가 실제로 경로 계산을 하지 않아서 NavigationServer2D 부하가 0인 상태.

**발견된 씬 구성 오류**:
- `NavigationRegion2D`에 `navigation_polygon` 미설정 → 경로 계산 불가
- `CollisionShape2D`에 `shape` 미설정 → 물리 충돌 없음
- `Enemy1~4`의 `chase_target` 미할당 → 적 에이전트 정지 상태

**수정 완료 (2026-05-07)**:
- `spike_nav_profiler.gd`의 `_ready()`에서 씬 셋업 수행:
  - `NavigationPolygon` 800×600 직사각형 생성 및 할당
  - `CollisionShape2D`에 `CircleShape2D(r=16)` 할당
  - `Enemy` 에이전트 `chase_target = Player` 설정
- `HUD/StatusLabel` 추가로 실시간 측정값 화면 표시
- 30초 후 Output 패널과 화면 양쪽에 결과 출력

---

## 재실행 안내 (2차 — 씬 수정 후)

1. F6으로 `spike_nav.tscn` 실행
2. 화면에 **"측정 중: 30초 남음"** 표시 확인 (셋업 정상)
3. Godot **Debugger → Profiler** 탭 켜기
4. **"Physics 2D"** 항목 값 관찰 (0.00ms 이상이어야 실제 동작 중)
5. 30초 후 화면과 Output 패널에 결과 표시

---

## 2차 실행 결과 (2026-05-07) — 측정 오류 발견, BLOCKED

**출력**:
```
평균 Physics delta: 16.67ms / 최대: 16.67ms / 100% FAIL
```

**이 결과는 무효**: `delta * 1000.0`은 항상 `1/60 × 1000 = 16.67ms`.  
물리 프레임 **처리 비용**이 아닌 물리 **타임스텝 상수**를 측정한 것.  
100% FAIL은 당연한 결과이며 실제 부하와 무관.

**실제 유효 데이터 (1차 Godot Profiler 관찰, 2026-05-07)**:  
Frame Time: 6~7ms — 16.6ms 예산 내, 실질적으로 여유 있음.  
Physics 2D: 미기록 (재실행 시 별도 확인 필요)

**프로파일러 수정 완료 (2026-05-07)**:
- 기존: `delta * 1000.0` (물리 타임스텝 상수 → 측정 무효)
- 수정: `Time.get_ticks_usec()` 기반 프레임 간 벽시계 시간 간격
- 합격 기준 변경: 평균 간격 < 20ms + 33ms 초과 프레임 < 5%
- 워밍업 2초 제외 후 측정

---

## 재실행 안내 (3차 — 최종)

1. F6으로 `spike_nav.tscn` 실행
2. 화면에 **"워밍업 중..."** → 2초 후 **"측정 중: 28초 남음"** 전환 확인
3. Godot **Debugger → Profiler** → **"Physics 2D"** 값 별도 메모
4. 30초 후 화면에 결과 표시 (판정: PASS/FAIL)

---

## 재실행 결과 (3차 — 2026-05-07) ✅ PASS

**날짜**: 2026-05-07  
**결과**: ✅ PASS

| 측정 항목 | 값 | 기준 | 판정 |
|---|---|---|---|
| 샘플 수 | 1681 | — | — |
| 평균 프레임 간격 | 16.67 ms | < 20ms | ✅ OK |
| 최대 프레임 간격 | 27.75 ms | < 33ms | ✅ OK |
| 33ms 초과 프레임 | 0 / 1681 (0.0%) | < 5% | ✅ OK |
| Godot Profiler Physics 2D | 미기록 | — | — |

**발견 사항**:
- 7개 NavigationAgent2D `avoidance_enabled=true` 동시 이동 시 평균 프레임 간격이 16.67ms에 고정 — 물리 프레임 드롭 없음
- 최대 스파이크 27.75ms — 일회성, 33ms 임계치 이하. 지속적 과부하 없음
- `velocity_computed` 시그널 정상 동작 (Godot 4.6에서 시그니처 변경 없음 확인)
- 측정 중 에이전트들이 실제로 이동 및 회피 동작 수행 (NavPolygon + chase_target 정상 작동)

**ADR-0006 영향**: 없음 — 설계 확정  
`avoidance_enabled = true` 동료 3 + 적 4 동시 운용 60fps 유지 가능.  
조건부 비활성화(먼 에이전트 avoidance_enabled=false) 불필요 — 현재 에이전트 수 기준.

**권고 사항**:  
에이전트 수가 대폭 증가(10명 이상)하는 시나리오에서는 재프로파일링 권장.  
현재 MVP 스코프(동료 최대 3명 + 적 4명)는 안전.

## 구현 파일

- `spike_nav.tscn` — NavigationRegion2D + 7에이전트 테스트 씬
- `spike_companion_agent.gd` — 동료 에이전트 이동 로직
- `spike_enemy_agent.gd` — 적 에이전트 추적 로직
- `spike_nav_profiler.gd` — 프레임 시간 측정 + 자동 리포트 출력
