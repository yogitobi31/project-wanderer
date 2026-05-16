# Sprint 4 Kickoff Checklist

**생성일**: 2026-05-16  
**출처**: gate-check Pre-Production → Production (CONCERNS 관리 항목)  
**단계**: Production Phase 진입 직후 — Day 0~1 완료 필수

---

## 🔴 High Priority (Day 0~1 필수 — Sprint 4 시작 전 완료)

- [ ] `production/milestones/M1.md` 생성
  - scope envelope (어떤 기능이 M1에 포함되는가)
  - 성공 기준 (무엇이 달성되어야 M1 완료인가)
  - 타겟 날짜
  - Pillar 3 (Team Unlocks World) 검증 일정 명시

- [ ] `production/risk-register/register.md` 생성
  - 최소 5개 항목: solo-dev 번아웃, SaveManager 계약 안정성, 플레이테스트 케이던스, scope creep, 아트 파이프라인

- [ ] `design/art/characters/player.md` 생성
  - 동료 스프라이트 작업 전 필수 (앵커 기준)
  - art-bible.md 섹션 5.1 내용 기반으로 작성

- [ ] **SaveManager (S3-8) → Sprint 4 Must Have 승격**
  - Should Have → Must Have
  - Sprint 4 첫 번째 구현 스토리로 배치
  - `src/core/save_manager.gd` 대상, ADR-0007 계약 기준

---

## 🟡 Medium Priority (Sprint 4 계획 시)

- [ ] `design/art/art-bible.md` Status 헤더 수정
  - "In Progress" → "Complete"
  - dated sign-off 추가: `*Art Director Sign-Off: Complete — Lean mode, 2026-05-16*`

- [ ] 동료 프로필 3종 Draft → Approved 승격
  - `design/art/characters/seo-rin.md`
  - `design/art/characters/dol-soe.md`
  - `design/art/characters/ma-ru.md`

- [ ] S3-5~S3-11 carryover 7 stories 트리아지
  - 각 스토리: Sprint 4 배정 or 이유와 함께 backlog 명시
  - sprint-status.yaml 업데이트

- [ ] Sprint 4 플레이테스트 케이던스 확정
  - 최소 1세션/스프린트 커밋

---

## 🟢 Low Priority (해당 작업 착수 전)

- [ ] 아트 생산 시작 시 "첫 5타일 리뷰" 체크포인트 설정
  - Pillar 4 (Small but True) 드리프트 감지

- [ ] 캠프 prop slot 수 확정 (최대 10개 미확정)
- [ ] fire-dying 타일 variant 요건 게임 디자이너 확인

- [ ] Session 003 "3회차에서 처음 느껴짐" 온보딩 UX 개선 검토

- [ ] TD Residual Concerns 처리
  - RC-1: Scenario 4 UI 오버레이 perf 재측정 (HUD 연결 후)
  - RC-2: ADR-0006 avoidance 저사양 하드웨어 검증
  - RC-3: 테스트 커버리지 최소 기준 정의
  - RC-4: Forbidden patterns 목록 추가 (technical-preferences.md)

---

## 진행 확인

Sprint 4 kickoff 전 아래 항목이 완료되어야 Sprint 4 Must Have가 실행 가능합니다:

```
[ ] M1 milestone 정의 완료
[ ] Risk register 생성 완료
[ ] Player visual profile 완료
[ ] SaveManager → Must Have 승격 완료
[ ] Sprint 4 계획 수립 (/sprint-plan new)
```
