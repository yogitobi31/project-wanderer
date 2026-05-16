# Playtest Report — Vertical Slice Sprint 2

## Session Info
- **Date**: 2026-05-13 ~ 2026-05-16 (3회)
- **Build**: Vertical Slice — main_map.tscn (Sprint 2, CI 516/518 PASS)
- **Duration**: 총 약 90분 (25 + 30 + 35)
- **Tester**: Juwon (Developer)
- **Platform**: PC (Windows)
- **Input Method**: Keyboard + Mouse
- **Session Type**: Targeted test — 핵심 루프 & Player Fantasy 검증

---

## Test Focus

이동 → 전투 → 포탈 핵심 루프가 Game Concept의 Player Fantasy 4개 필라와 일치하는지 검증. 특히 **Visible Snowball** ("동료가 늘수록 게임이 달라진다") 가설을 동료 0→1→2명 누진 테스트로 확인.

---

## First Impressions (Session 001 기준)

- **Understood the goal?** Yes — 이동, 공격, 포탈 즉각 이해
- **Understood the controls?** Yes — WASD + 스페이스바 직관적
- **Emotional response**: Engaged (긴장감 있는 전투), 약간 Lonely (동료 없음)
- **Notes**: 혼자 싸울 때의 "외로움"이 설계 의도(Earned Fellowship 대비)와 일치

---

## Gameplay Flow

### What worked well
- PlayerController IDLE↔MOVING 전환 지연 없음. 이동 반응성 우수.
- Iframes 0.5초 — 피격 후 전술적 회피 여지를 줌. 전투 리듬 형성.
- 동료 합류 시 HUD 슬롯 추가 애니메이션 — "파티가 생겼다"는 시각적 피드백 효과적.
- `combat_cleared` → 포탈 전환 흐름이 자연스러움. 루프 종결감 있음.
- 동료 사망 X 아이콘 — "잃은 느낌" 감정적으로 의미 있음.
- NavigationAgent2D 7 에이전트 동시 60fps 유지 — 성능 우려 해소.

### Pain points
- CompanionAI 좁은 통로 겹침 현상 — 동료 수 증가 시 빈도 상승 **[Severity: Medium]**
- FOLLOW_STOP_DISTANCE 40px — 동료가 플레이어 이동을 방해할 수 있는 거리 **[Severity: Low]**
- 씬 전환 0.3초 검은 화면 공백 — Session 001 발견, Session 002에서 `call_deferred` 수정 후 해소

### Confusion points
- 없음 — 핵심 루프 조작이 즉각적으로 이해됨

### Moments of delight
- Session 003 3회차: "팀이 생겼다" 체감 — 동료 2명과 함께 적 5마리와 싸울 때 "이 게임이 말하려는 것"이 처음으로 느껴짐
- 동료 사망 슬롯이 X로 남는 디자인 — 예상보다 감정적 임팩트가 강했음

---

## Bugs Encountered

| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|
| B-001 | 대각선 이동 시 스프라이트 방향이 4방향으로만 고정 | Low | Yes — 항상 재현 |
| B-002 | 씬 전환 0.3초 검은 화면 공백 | Low | Yes — `call_deferred` 수정으로 해소 ✅ |
| B-003 | CompanionAI 좁은 통로 겹침 (동료 2명 기준 빈도 증가) | Medium | Yes — 좁은 통로에서 재현 |

---

## Feature-Specific Feedback

### 핵심 루프 (이동→전투→포탈)
- **Understood purpose?** Yes
- **Found engaging?** Yes — 3회 반복에도 루프 자체의 재미 유지됨
- **Suggestions**: 포탈 전환 후 다음 맵에 새 동료 등장 → 루프에 "보상" 구조 추가 시 반복 동기 강화

### HUD (파티 슬롯 + HP바)
- **Understood purpose?** Yes
- **Found engaging?** Yes — 슬롯 증가가 성장 피드백으로 작동
- **Suggestions**: 동료 아이콘에 캐릭터 실루엣 추가 시 개성 부여 가능 (현재 플레이스홀더)

### CompanionAI
- **Understood purpose?** Yes
- **Found engaging?** Yes — "함께 싸우는" 느낌 전달됨
- **Suggestions**: avoidance 파라미터 조정 + FOLLOW_STOP_DISTANCE 60~80px 테스트 권장

---

## Quantitative Data

- **Deaths**: 0 (개발자 테스트 — 의도적 회피)
- **동료 사망**: Session 003 1회 (의도적 노출)
- **루프 반복**: Session 003에서 3회 연속 완주
- **60fps 유지**: 7 에이전트 동시 이동에서 확인

---

## Overall Assessment

- **Would play again?** Yes
- **Difficulty**: Just Right (동료 수에 비례한 적 스케일링이 균형 유지)
- **Pacing**: Good
- **Session length preference**: Good (현재 Vertical Slice 분량은 적절)

---

## Player Fantasy 최종 판정

| 필라 | 판정 | 근거 |
|---|---|---|
| Earned Fellowship | ✅ PASS | 동료 2명 전투에서 "함께 싸우는" 체감 완전 전달. 동료 사망 감정적 손실감 확인. |
| Visible Snowball | ✅ PASS | HUD 슬롯 + 화면 내 캐릭터 수가 동료 수에 비례. 3회차에서 "달라진 게임" 체감. |
| Team Unlocks World | △ 미검증 | Vertical Slice 범위 밖. 포탈로 "다음이 있다" 암시만 전달. |
| Small but True | △ 보류 | 타일셋/스프라이트 플레이스홀더 — 아트 작업 후 재판단 필요. |

**핵심 가설 판정: ✅ "동료가 늘수록 게임이 달라진다" — 검증됨.**

---

## Top 3 Priorities

1. **CompanionAI 좁은 통로 겹침 해소** — avoidance 파라미터 조정 (Sprint 3)
2. **FOLLOW_STOP_DISTANCE 튜닝** — 40px → 60~80px 테스트 (Sprint 3)
3. **적 사망 애니메이션 추가** — VIS-2 백로그 (Sprint 3 전 필수)

---

## Action Routing

| 카테고리 | 항목 |
|---|---|
| Design changes | 없음 — 핵심 루프 설계 의도 충족 |
| Balance adjustments | FOLLOW_STOP_DISTANCE 40→60~80px 튜닝 |
| Bug reports | B-001 (대각선 스프라이트), B-003 (CompanionAI 통로 겹침) |
| Polish items | 적 사망 애니메이션, 동료 아이콘 캐릭터 실루엣 |

---

*CD-PLAYTEST: Lean mode — skipped.*
