# Systems Index: 유랑단 (The Wandering Band)

> **Status**: Draft
> **Created**: 2026-04-17
> **Last Updated**: 2026-05-16
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

유랑단은 실시간 파티 전투와 동료 영입 퀘스트를 중심으로 한 2D 픽셀 아트 액션 RPG다.
핵심 루프는 "동료를 찾아가 퀘스트로 설득하고, 합류한 동료와 함께 전투하고 세계를 탐험한다"로
이루어진다. 게임의 모든 시스템은 이 루프를 지지하거나, 루프가 만들어내는 성장을 가시적으로
보여주기 위해 존재한다. Pillar 1 (Earned Fellowship), Pillar 2 (Visible Snowball),
Pillar 3 (Team Unlocks World), Pillar 4 (Small but True)가 모든 설계 결정의 기준이 된다.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 능력치 시스템 | Core | MVP | Done | design/gdd/능력치-시스템.md | — |
| 2 | NPC 상태 관리 (inferred) | Core | MVP | Approved | design/gdd/NPC-상태-관리.md | — |
| 3 | 아이템 데이터베이스 (inferred) | Economy | MVP | Approved | design/gdd/아이템-데이터베이스.md | — |
| 4 | 입력 매핑 시스템 (inferred) | Core | MVP | Approved | design/gdd/입력-매핑-시스템.md | — |
| 5 | 씬 전환 시스템 (inferred) | Core | MVP | Approved | design/gdd/씬전환-시스템.md | — |
| 6 | 히트박스 / 충돌 감지 (inferred) | Core | MVP | Approved | design/gdd/히트박스-충돌-감지.md | — |
| 7 | 오디오 매니저 (inferred) | Audio | MVP | Approved | design/gdd/오디오-매니저.md | — |
| 8 | 플레이어 캐릭터 컨트롤러 | Core | MVP | Reviewed | design/gdd/플레이어-캐릭터-컨트롤러.md | 입력 매핑, 능력치 |
| 9 | 체력 / 데미지 시스템 (inferred) | Gameplay | MVP | Reviewed | design/gdd/체력-데미지-시스템.md | 능력치 |
| 10 | 인벤토리 시스템 (inferred) | Economy | MVP | Approved | design/gdd/인벤토리-시스템.md | 아이템 데이터베이스 |
| 11 | 동료 AI 시스템 (inferred) | Gameplay | MVP | Reviewed | design/gdd/동료-AI-시스템.md | 능력치, 히트박스, NPC 상태 |
| 12 | 대화 시스템 (inferred) | Narrative | MVP | Reviewed | design/gdd/대화-시스템.md | NPC 상태 |
| 13 | 맵 / 지역 시스템 (inferred) | Core | MVP | Approved | design/gdd/맵-지역-시스템.md | 씬 전환 |
| 14 | 퀘스트 상태 머신 (inferred) | Narrative | MVP | Reviewed | design/gdd/퀘스트-상태-머신.md | NPC 상태, 인벤토리 |
| 15 | 수집 / 자원 시스템 | Economy | MVP | Approved | design/gdd/수집-자원-시스템.md | 인벤토리, 아이템 DB |
| 16 | 실시간 파티 전투 | Gameplay | MVP | Approved | design/gdd/실시간-파티-전투.md | 플레이어 컨트롤러, 체력/데미지, 히트박스, 동료 AI |
| 17 | 동료 영입 퀘스트 | Gameplay | MVP | Reviewed | design/gdd/동료-영입-퀘스트.md | 퀘스트 상태머신, 대화, NPC 상태 |
| 18 | 동료 합류 이벤트 (inferred) | Gameplay | MVP | Approved | design/gdd/동료-합류-이벤트.md | 동료 영입 퀘스트, 오디오 |
| 19 | 파티 매니저 | Core | MVP | Done | design/gdd/파티-매니저.md | NPC 상태 관리 |
| 20 | 이벤트 버스 | Core | MVP | Done | design/gdd/이벤트-버스.md | — |
| 21 | 경험치 / 레벨업 시스템 (inferred) | Progression | Vertical Slice | Not Started | — | 능력치 |
| 22 | 동료 성장 시스템 | Progression | Vertical Slice | Not Started | — | 경험치/레벨업, 능력치 |
| 23 | 세이브 / 로드 시스템 (inferred) | Persistence | Vertical Slice | Not Started | — | 플레이어 컨트롤러, NPC 상태, 인벤토리, 퀘스트 상태머신 |
| 24 | 월드 조건 시스템 (inferred) | Gameplay | Vertical Slice | Not Started | — | 맵/지역, NPC 상태 |
| 25 | 팀 구성 기반 월드 잠금 해제 | Gameplay | Vertical Slice | Not Started | — | 월드 조건, 동료 영입 퀘스트 |
| 26 | 전투 UI (inferred) | UI | Vertical Slice | Not Started | — | 실시간 파티 전투, 체력/데미지 |
| 27 | 게임 HUD (inferred) | UI | Vertical Slice | Not Started | — | 체력/데미지, 수집/자원, 동료 성장 |
| 28 | 메인 메뉴 / 설정 UI (inferred) | UI | Vertical Slice | Not Started | — | 세이브/로드, 입력 매핑 |

---

## Categories

| Category | Description | 이 게임에서의 역할 |
|----------|-------------|-------------------|
| **Core** | 모든 것이 의존하는 기반 인프라 | 입력, 씬 전환, 능력치, NPC 상태, 충돌 감지 |
| **Gameplay** | 게임을 재미있게 만드는 시스템 | 전투, AI, 영입, 잠금 해제 |
| **Progression** | 플레이어와 동료가 성장하는 방식 | XP, 레벨업, 동료 능력치 성장 |
| **Economy** | 자원 생성과 소비 | 아이템 DB, 인벤토리, 수집/자원 |
| **Persistence** | 게임 상태 저장과 재개 | 세이브/로드 |
| **UI** | 플레이어에게 정보를 전달하는 화면 | HUD, 전투 UI, 메인 메뉴 |
| **Audio** | 사운드와 음악 | 오디오 매니저 |
| **Narrative** | 이야기와 대화 전달 | 대화 시스템, 퀘스트 상태머신 |

---

## Priority Tiers

| Tier | 정의 | 목표 마일스톤 | 설계 우선도 |
|------|------|---------------|------------|
| **MVP** | 코어 루프를 작동시키는 데 필수. 이것 없이는 "재미있는가?"를 검증할 수 없음 | 첫 플레이어블 프로토타입 (3~5주) | 최우선 설계 |
| **Vertical Slice** | 완성된 경험 하나를 보여주는 데 필요. 전체 게임의 방향을 증명 | 버티컬 슬라이스 (3~4개월) | 두 번째 설계 |
| **Alpha** | 현재 없음 — VS 이후 플레이테스트 결과에 따라 추가 | — | — |
| **Full Vision** | 현재 없음 — 폴리시/에지케이스는 추후 식별 | 베타 / 출시 | 나중에 |

---

## Dependency Map

### Foundation Layer (의존성 없음)

1. **능력치 시스템** — 전투 공식의 모든 입력값. 5개 시스템이 의존하는 병목.
2. **NPC 상태 관리** — NPC의 상태 데이터 저장소. 5개 시스템이 의존하는 병목.
3. **아이템 데이터베이스** — 모든 아이템 정의. 인벤토리/수집의 기반.
4. **입력 매핑 시스템** — 키보드/마우스/게임패드 바인딩. 플레이어 컨트롤의 기반.
5. **씬 전환 시스템** — Godot 씬 로드/언로드 인프라. 맵 이동의 기반.
6. **히트박스 / 충돌 감지** — Godot Physics 2D 기반. 실시간 전투의 물리적 기반.
7. **오디오 매니저** — BGM/SFX 재생 관리. 동료 합류 이벤트의 청각 피드백 기반.

### Core Layer (Foundation에 의존)

1. **플레이어 캐릭터 컨트롤러** — depends on: 입력 매핑, 능력치
2. **체력 / 데미지 시스템** — depends on: 능력치
3. **인벤토리 시스템** — depends on: 아이템 데이터베이스
4. **동료 AI 시스템** — depends on: 능력치, 히트박스, NPC 상태 관리
5. **대화 시스템** — depends on: NPC 상태 관리
6. **맵 / 지역 시스템** — depends on: 씬 전환

### Feature Layer (Core에 의존)

1. **퀘스트 상태 머신** — depends on: NPC 상태 관리, 인벤토리
2. **수집 / 자원 시스템** — depends on: 인벤토리, 아이템 데이터베이스
3. **실시간 파티 전투** — depends on: 플레이어 컨트롤러, 체력/데미지, 히트박스, 동료 AI
4. **동료 영입 퀘스트** — depends on: 퀘스트 상태머신, 대화, NPC 상태
5. **경험치 / 레벨업 시스템** — depends on: 능력치
6. **동료 성장 시스템** — depends on: 경험치/레벨업, 능력치
7. **세이브 / 로드 시스템** — depends on: 플레이어 컨트롤러, NPC 상태, 인벤토리, 퀘스트 상태머신
8. **월드 조건 시스템** — depends on: 맵/지역, NPC 상태
9. **팀 구성 기반 월드 잠금 해제** — depends on: 월드 조건, 동료 영입 퀘스트
10. **동료 합류 이벤트** — depends on: 동료 영입 퀘스트, 오디오 매니저

### Presentation Layer (Feature에 의존)

1. **전투 UI** — depends on: 실시간 파티 전투, 체력/데미지
2. **게임 HUD** — depends on: 체력/데미지, 수집/자원, 동료 성장
3. **메인 메뉴 / 설정 UI** — depends on: 세이브/로드, 입력 매핑

---

## Recommended Design Order

| 순서 | 시스템 | Priority | Layer | 담당 에이전트 | 예상 난이도 |
|------|--------|----------|-------|--------------|-------------|
| 1 | 능력치 시스템 | MVP | Foundation | game-designer | S |
| 2 | NPC 상태 관리 | MVP | Foundation | game-designer | S |
| 3 | 아이템 데이터베이스 | MVP | Foundation | game-designer | S |
| 4 | 입력 매핑 시스템 | MVP | Foundation | game-designer | S |
| 5 | 씬 전환 시스템 | MVP | Foundation | godot-specialist | S |
| 6 | 히트박스 / 충돌 감지 | MVP | Foundation | godot-gdscript-specialist | S |
| 7 | 오디오 매니저 | MVP | Foundation | game-designer | S |
| 8 | 플레이어 캐릭터 컨트롤러 | MVP | Core | godot-gdscript-specialist | M |
| 9 | 체력 / 데미지 시스템 | MVP | Core | systems-designer | M |
| 10 | 인벤토리 시스템 | MVP | Core | game-designer | M |
| 11 | 동료 AI 시스템 | MVP | Core | ai-programmer + game-designer | L |
| 12 | 대화 시스템 | MVP | Core | game-designer | M |
| 13 | 맵 / 지역 시스템 | MVP | Core | godot-specialist | M |
| 14 | 퀘스트 상태 머신 | MVP | Feature | game-designer | M |
| 15 | 수집 / 자원 시스템 | MVP | Feature | game-designer | S |
| 16 | 실시간 파티 전투 | MVP | Feature | systems-designer | L |
| 17 | 동료 영입 퀘스트 | MVP | Feature | game-designer | L |
| 18 | 동료 합류 이벤트 | MVP | Feature | game-designer | S |
| 19 | 경험치 / 레벨업 시스템 | VS | Feature | systems-designer | M |
| 20 | 동료 성장 시스템 | VS | Feature | systems-designer | M |
| 21 | 세이브 / 로드 시스템 | VS | Feature | godot-specialist | M |
| 22 | 월드 조건 시스템 | VS | Feature | game-designer | S |
| 23 | 팀 구성 기반 월드 잠금 해제 | VS | Feature | game-designer | M |
| 24 | 전투 UI | VS | Presentation | godot-specialist | M |
| 25 | 게임 HUD | VS | Presentation | godot-specialist | M |
| 26 | 메인 메뉴 / 설정 UI | VS | Presentation | godot-specialist | M |

> 난이도: S = 1세션, M = 2~3세션, L = 4세션+

---

## Circular Dependencies

없음. 모든 의존이 단방향.

---

## High-Risk Systems

| 시스템 | 위험 유형 | 위험 설명 | 완화 방안 |
|--------|-----------|-----------|-----------|
| **동료 AI 시스템** | 기술적 | 10명 동시 실시간 AI — Godot NavMesh + 상태머신 미검증. 성능 병목 가능성. | MVP에서 동료 3명으로 제한해 프로토타입 검증. 이후 `/prototype [companion-ai]` 실행. |
| **능력치 시스템** | 설계 | 5개 시스템의 기반. 잘못 설계하면 체력/데미지/성장 전체 수정 필요. | 설계 1순위. 변경 비용이 가장 낮을 때 충분한 검토 필요. |
| **NPC 상태 관리** | 설계 | 5개 시스템의 기반. 상태 구조를 유연하게 설계해야 세이브/로드와 충돌 안 함. | 설계 2순위. 직렬화 친화적 구조 고려 필수. |
| **실시간 파티 전투** | 설계 + 기술 | MVP의 핵심 가설이자 가장 복잡한 시스템. "혼자 싸울 때와 5명이 함께 싸울 때가 다른 느낌"을 구현해야 함. | AI, 히트박스, 체력 시스템 완료 후 설계. 프로토타입 필수. |

---

## Progress Tracker

| 지표 | 수치 |
|------|------|
| 총 식별 시스템 | 28 |
| 설계 시작됨 | 20 |
| 설계 검토 완료 | 20 |
| Approved (교차 리뷰 통과 또는 수정 완료) | 20 |
| Needs Revision | 0 |
| MVP 시스템 설계 완료 | 20 / 20 |
| Vertical Slice 시스템 설계 완료 | 0 / 8 |
| 마지막 교차 리뷰 | design/gdd/reviews/gdd-cross-review-2026-04-26.md |

---

## Next Steps

- [x] `/design-system 능력치-시스템` — 설계 순서 1번, 가장 많은 시스템의 기반
- [ ] `/design-system NPC-상태-관리` — 설계 순서 2번, 두 번째 병목 시스템
- [ ] `/prototype companion-ai` — 고위험 기술 검증, 설계와 병행 권장
- [ ] `/design-review design/gdd/[system].md` — 각 GDD 완성 후 품질 검증
- [ ] `/gate-check pre-production` — MVP 18개 시스템 GDD 완성 후 실행
