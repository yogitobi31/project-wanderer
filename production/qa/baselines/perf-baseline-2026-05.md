# Performance Baseline — 2026-05

**측정자**: Juwon  
**측정일**: 2026-05-16  
**빌드 커밋**: 4e3c868 (Fix HealthComponent interface doc drift in architecture.md)  
**Godot 버전**: 4.6  
**렌더러**: Compatibility (2D)  
**측정 환경**: [ PC 사양 기입 — CPU, GPU, RAM ]

> **목적**: Pre-Production → Production 게이트 CONCERNS 해소 (TD 지적).
> 이 문서가 완성되면 S3-3 done으로 처리.

---

## 측정 방법

Godot 에디터 → **Debugger 탭 → Monitors**에서 측정.  
각 시나리오는 **30초 이상 실행** 후 안정화된 값을 기록.  
측정 중 다른 프로그램 최소화 권장.

---

## 예산 기준 (technical-preferences.md)

| 항목 | 예산 | 출처 |
|---|---|---|
| 목표 프레임레이트 | 60 fps | technical-preferences.md |
| 프레임 예산 | 16.6 ms | technical-preferences.md |
| Draw Calls | < 200 | technical-preferences.md |
| 메모리 상한 | 512 MB | technical-preferences.md |

---

## 시나리오 1: Idle (기본 대기)

**조건**: 플레이어 1명, 동료 0명, 적 0명. 타운/맵 씬에서 이동 없이 대기.

| 항목 | 측정값 | 예산 | 판정 |
|---|---|---|---|
| FPS | 144 | ≥ 60 | PASS |
| Process Time (ms) | 7.15 | ≤ 16.6 ms | PASS |
| Physics Process (ms) | 1.29 | — | 참고값 |
| Navigation Process (ms) | 0.22 | — | 참고값 |
| Draw Calls | 13 | < 200 | PASS |
| Static Memory (MiB) | 48.99 | < 300 MB | PASS |
| Video Memory (MiB) | 22.12 | — | 참고값 |
| Objects / Nodes | 2103 / 86 | — | 참고값 |

**비고**: 헤드룸 충분. FPS 144 (예산의 240%), Draw Calls 13/200 (6.5%). 메모리 매우 여유.

---

## 시나리오 2: 이동 (플레이어 + 동료)

**조건**: 플레이어 1명 + 동료 3명(서린/돌쇠/마루). 맵에서 이동 중.  
`src/characters/companion_ai.gd` NavigationAgent2D 경로 탐색 포함.

| 항목 | 측정값 | 예산 | 판정 |
|---|---|---|---|
| FPS | 144 | ≥ 60 | PASS |
| Process Time (ms) | 7.28 | ≤ 16.6 ms | PASS |
| Physics Process (ms) | 0.47 | — | 참고값 |
| Navigation Process (ms) | 0.00 | — | 참고값 |
| Draw Calls | 11 | < 200 | PASS |
| Static Memory (MiB) | 48.87 | < 350 MB | PASS |
| Objects / Nodes | 2093 / 74 | — | 참고값 |

**비고**: Navigation Process 0.00ms — avoidance OFF 상태에서 동료 3명 경로 탐색 부하 사실상 없음. Idle 대비 Process Time +0.13ms, Draw Calls 오히려 -2 (렌더링 배칭 차이).

---

## 시나리오 3: 전투 (적 9명 — NavigationAgent2D 스트레스)

**조건**: 플레이어 1명 + 동료 3명 + 적 9명. 전투 씬에서 동시 전투 중.  
이 시나리오가 **C-7 NavigationAgent2D 스트레스 테스트**를 겸한다.

| 항목 | 측정값 | 예산 | 판정 |
|---|---|---|---|
| FPS (avoidance OFF) | 144 | ≥ 55 (전투 허용 하한) | PASS |
| Process Time (ms) | 7.15 | ≤ 18 ms (전투 허용 상한) | PASS |
| Physics Process (ms) | 0.61 | — | 참고값 |
| Navigation Process (ms) | 0.00 | — | 참고값 |
| Draw Calls | 29 | < 200 | PASS |
| Static Memory (MiB) | 49.80 | < 400 MB | PASS |
| Objects / Nodes | 2244 / 191 | — | 참고값 |
| NavigationAgent2D avoidance 활성 여부 | OFF | OFF (ADR-0006) | — |

**NavigationAgent2D 관찰 항목**:
- 적 9명이 서로 겹치는 현상 발생 여부: **발생** (avoidance OFF 예상 결과)
- 경로 탐색 stutter (프레임 스파이크) 발생 여부: **없음**
- avoidance OFF 상태에서 전투 흐름 플레이어블 여부: 플레이어블

**비고 (ADR-0006 관련)**:
- avoidance OFF FPS: 144 / Navigation Process: 0.00ms
- avoidance ON FPS: **144** (차이: **0 fps** — 비용 없음)
- **결론**: 개발 머신 기준 avoidance ON/OFF 성능 차이 없음. 단, 겹침 현상은 avoidance OFF에서 발생. ADR-0006 재검토 대상 — avoidance 활성화가 성능상 안전함을 이 머신에서 확인. 저사양 타겟 하드웨어 프로파일링 전까지는 ADR-0006 유지 권장.

---

## 시나리오 4: UI 오버레이 (HUD 풀 표시)

**조건**: 전투 씬 + HUD 전체 표시 (HP 바, 퀘스트 트래커, 인벤토리 오버레이 포함).

| 항목 | 측정값 | 예산 | 판정 |
|---|---|---|---|
| FPS | N/A | ≥ 60 | BLOCKED |
| Draw Calls (UI 포함) | N/A | < 200 | BLOCKED |
| UI 씬 전환 시간 (ms) | N/A | < 100 ms | BLOCKED |

**BLOCKED 사유**: I키 입력 시 인벤토리 UI 미반응. UI 시스템이 perf_stress_test.tscn에 연결되지 않음.  
InputMap 액션 등록 또는 Inventory UI autoload 연결 후 재측정 필요.

**Follow-up QA 항목**: UI 시스템 연결 완료 후 아래 조건으로 재측정
- `inventory` InputMap 액션 → I키 바인딩 확인
- InventoryUI 씬이 HUD CanvasLayer를 통해 올바르게 토글되는지 확인
- 재측정 위치: `tests/scenes/perf/perf_stress_test.tscn` 동일 씬에서 실행

---

## 종합 판정

| 시나리오 | 판정 |
|---|---|
| 1. Idle | PASS |
| 2. 이동 (동료 3명) | PASS |
| 3. 전투 9명 (NavAgent 스트레스) | PASS |
| 4. UI 오버레이 | BLOCKED (UI 미연결) |

**전체 판정**: CONDITIONAL

**조건**: 시나리오 1~3 모두 PASS — 핵심 성능 예산 충족 확인. 시나리오 4는 UI 시스템 구현 완료 후 Polish 단계 진입 전 재측정. Production 진입 비차단.

---

## 발견된 병목

없음. 모든 측정 시나리오에서 예산 내 동작 확인.

---

## ADR-0006 업데이트 필요 사항

이번 프로파일링으로 확인된 사항:
- 개발 머신(FPS 144 기준)에서 avoidance ON/OFF 성능 차이 없음 (0fps 차이)
- avoidance OFF 시 적 9명 겹침 현상 발생 — 시각적 품질 문제는 존재
- 저사양 타겟 하드웨어에서의 검증은 미완 → ADR-0006 현행 유지 권장

**권고**: ADR-0006에 이번 측정 결과를 Evidence로 추가. avoidance 활성화 여부는 Polish 단계 초기에 저사양 환경 테스트 후 재결정.

---

## 다음 단계

- **C-6, C-7 완료** — S3-3, S3-4 done 처리 가능.
- **UI 오버레이 재측정** — S3-8 SaveManager 또는 UI 연결 스토리 완료 후 별도 QA 항목으로 실행.
