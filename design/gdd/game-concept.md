# Game Concept: 유랑단 (The Wandering Band)

*Created: 2026-04-16*
*Status: Draft*

---

## Elevator Pitch

> 한때 사람들이 살던 세계를 홀로 떠돌며, 저마다 사연을 가진 이들을 한 명씩 설득해
> 팀을 꾸리는 실시간 액션 RPG.
> 팀이 커질수록 세계가 열리고, 전투가 달라진다.
>
> *"It's a real-time action RPG where you recruit a team of misfits one quest
> at a time, and your growing band of companions is both your key to the world
> and your weapon in it."*

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 실시간 액션 RPG + 파티 빌더 |
| **Platform** | PC (Steam / Epic) |
| **Target Audience** | 인디 RPG 팬, 20~35세, 이야기와 성장에 관심 있는 플레이어 |
| **Player Count** | 싱글플레이어 |
| **Session Length** | 30~60분 |
| **Monetization** | Premium (미정) |
| **Estimated Scope** | Large (18–24개월, 솔로) |
| **Comparable Titles** | 퍼스트퀸4, 스타듀밸리, 파이어 엠블렘 |

---

## Core Fantasy

당신이 이 팀의 리더다 — 그리고 이 팀은 당신이 직접 찾아가서 설득한 사람들로만 이루어져 있다.

처음엔 혼자(혹은 둘)로 시작한다. 세계를 돌아다니며 제각각의 사연을 가진 인물들을 만난다. 그들의 문제를 이해하고, 퀘스트를 완수해서 신뢰를 얻는다. 한 명이 합류할 때마다 전투가 눈에 보이게 달라진다. 팀이 커질수록 새로운 길이 열린다.

클라이막스는 수치가 아니다 — 화면을 가득 채운 내 팀이 함께 싸우는 그 순간이다.

---

## Unique Hook

파이어 엠블렘처럼 캐릭터를 모으는데, **AND ALSO** 그 캐릭터들이 퍼스트퀸4처럼 실시간으로 나와 함께 전장을 누비며, 누가 팀에 있느냐에 따라 탐험 범위 자체가 달라진다.

---

## Visual Identity Anchor

*확정됨 — 전체 아트 바이블: `design/art/art-bible.md`*

- **Visual Direction**: Warm but Worn — 서양 중세 판타지, 절정 이후의 세계
- **Visual Rule**: "의심스러울 때는 가독성을 우선하라 — 화면의 모든 캐릭터는 '유닛'이 아닌 '사람'으로 즉시 읽혀야 한다."
- **Supporting Principles**: 따뜻하되 낡은 / 실루엣이 먼저 / 조용한 순간을 위한 공간
- **Color Philosophy**: 14색 마스터 팔레트. 앰버/녹슨 붉은색/바랜 초록/흙빛. 적은 차가운 Dusk Iron으로 신호.
- **References**: 퍼스트퀸4 (군중 속 개인 가독성) / 스타듀밸리 (밀도 계약) / 언더테일 (절제 구성) / Hyper Light Drifter (두 시대 건축) / FFT (대규모 캐스트 실루엣)

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 4 | 전투 시 팀원 증가에 따른 시각적 피드백, 전장 활기 |
| **Fantasy** (make-believe, role-playing) | 3 | 유랑단 단장으로서의 정체성, 각 동료의 개성 |
| **Narrative** (drama, story arc) | 2 | 각 동료의 영입 퀘스트, 팀의 점진적 이야기 |
| **Challenge** (obstacle course, mastery) | 5 | 전투 난이도 곡선, 팀 구성 전략 |
| **Fellowship** (social connection) | 1 | 동료 영입 과정, 팀이 "내가 만든 사람들"이라는 소유감 |
| **Discovery** (exploration, secrets) | 2 | 새 동료와 함께 열리는 지역, 숨겨진 퀘스트 |
| **Expression** (self-expression, creativity) | 6 | 어떤 동료를 먼저 영입할지 선택, 팀 구성 전략 |
| **Submission** (relaxation, comfort zone) | N/A | — |

### Key Dynamics (Emergent player behaviors)

- 플레이어가 자연스럽게 "다음 동료는 누구를 영입할까" 계획을 세운다
- 팀 조합을 바꿔보며 전투 시너지를 실험한다
- 동료 퀘스트의 이야기를 더 이해하기 위해 지역을 재탐험한다
- "이 동료가 있어야 저 지역에 갈 수 있겠구나" 직감으로 영입 순서를 결정한다

### Core Mechanics (Systems we build)

1. **실시간 파티 전투** — 플레이어 캐릭터와 동료들이 실시간으로 함께 이동하고 전투
2. **동료 영입 퀘스트** — 각 NPC는 고유한 문제를 가지며, 해결해야 합류
3. **팀 구성 기반 월드 잠금 해제** — 특정 동료가 있어야 접근 가능한 지역/이벤트
4. **수집 및 자원 시스템** — 퀘스트 수행에 필요한 아이템 수집과 자원 관리
5. **동료 성장 시스템** — 전투 경험치로 스킬/능력치 성장

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 어느 동료를 먼저 영입할지, 어느 지역을 탐험할지 선택 | Supporting |
| **Competence** (mastery, skill growth) | 전투 숙달, 팀 시너지 발견, 어려운 영입 퀘스트 완수 | Supporting |
| **Relatedness** (connection, belonging) | 동료들의 사연을 이해하고, "내가 모은 팀"이라는 소속감 | **Core** |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 동료 수집, 팀 완성이라는 명확한 목표
- [x] **Explorers** — 팀원이 열어주는 새 지역과 숨겨진 이야기 발견
- [ ] **Socializers** — 싱글플레이어 중심
- [ ] **Killers/Competitors** — PvP 없음

### Flow State Design

- **Onboarding curve**: 첫 10분 — 혼자 전투 후 첫 동료를 자연스럽게 만남. 동료 합류 시 전투가 어떻게 달라지는지 즉시 체감.
- **Difficulty scaling**: 동료 수가 증가할수록 적의 규모도 증가. 팀 구성에 따라 다른 전략 필요.
- **Feedback clarity**: 동료 합류 시 명확한 시각/청각 연출. 스탯/스킬 변화가 전투에서 즉시 느껴짐.
- **Recovery from failure**: 사망 시 패널티 낮음 (첫 게임 친화적). 동료를 잃지 않음 — 재도전 장벽 최소화.

---

## Core Loop

### Moment-to-Moment (30초)
이동 → 적 조우 → 팀과 함께 실시간 전투 → 아이템/자원 획득 → 이동

전투는 팀이 커질수록 시각적으로 달라져야 한다. 혼자 싸울 때와 5명이 함께 싸울 때가 완전히 다른 느낌이어야 함.

### Short-Term (5~15분)
탐험 중 잠재 동료 발견 → 대화로 그 사람의 문제 파악 → 퀘스트 수행(아이템 획득/적 처치/장소 방문) → 퀘스트 완료 → 동료 합류 → 팀 전력 체감 상승

### Session-Level (30~60분)
새 지역 진입 → 1~2명의 잠재 동료 발견 및 퀘스트 진행 → 전투와 탐험으로 퀘스트 조건 충족 → 합류 완료 → 이전엔 막혀 있던 새 지역 또는 이벤트 해금 → 다음 동료의 흔적 발견

세션은 "동료 합류"로 자연스럽게 완결되며, 다음 목표가 항상 보인다.

### Long-Term Progression
혼자 → 3인 팀 → 5인 팀 → 완전한 유랑단 (8~10명).
각 합류마다 전투 조합과 접근 가능 지역이 달라짐. 모든 동료를 모으면 최종 콘텐츠 해금.

### Retention Hooks

- **Curiosity**: "저 지역은 어떤 동료가 있어야 들어갈 수 있을까?" / 미완료 퀘스트의 이야기
- **Investment**: 직접 모은 팀에 대한 애착, 각 동료의 사연
- **Social**: 싱글플레이어 — 커뮤니티 공유 (팀 구성, 최애 캐릭터)
- **Mastery**: 팀 조합 최적화, 숨겨진 시너지 발견

---

## Game Pillars

### Pillar 1: 모인 사람들 (Earned Fellowship)
이 팀의 모든 사람은 플레이어가 직접 찾아가서 설득한 사람이다. 어떤 동료도 그냥 주어지지 않는다.

*Design test*: 상점에서 구매하는 용병 시스템 vs. 퀘스트로 영입하는 동료 — 이 기둥은 퀘스트를 선택한다.

### Pillar 2: 눈에 보이는 성장 (Visible Snowball)
팀원이 한 명 늘 때마다 전투가 눈에 띄게 달라진다. 성장은 수치가 아니라 화면으로 느껴진다.

*Design test*: 스탯만 올라가는 레벨업 vs. 새 캐릭터가 실시간으로 함께 뛰어다니는 합류 — 이 기둥은 후자를 선택한다.

### Pillar 3: 팀이 곧 열쇠다 (Team Unlocks World)
누가 팀에 있느냐가 어디에 갈 수 있는지를 결정한다. 탐험의 범위는 시간이 아니라 동료가 확장한다.

*Design test*: 시간 경과로 열리는 콘텐츠 vs. 특정 동료가 있어야 열리는 콘텐츠 — 이 기둥은 동료를 선택한다.

### Pillar 4: 작지만 진짜인 이야기 (Small but True)
각 동료의 사연은 거창할 필요 없다. 납득이 되면 된다. 이야기의 규모보다 감정의 진실함이 우선이다.

*Design test*: 세계를 구하는 영웅 서사 vs. "이 사람이 왜 혼자였는지" 이해하는 순간 — 이 기둥은 후자를 선택한다.

### Anti-Pillars (What This Game Is NOT)

- **기지 건설 RTS가 아니다**: Pillar 2를 희생하고 전략 복잡도에 빠진다. 전투는 내 팀과 함께 몸으로 싸우는 것이어야 한다.
- **도감 수집 게임(포켓몬식)이 아니다**: Pillar 1을 망친다. 영입은 이해와 설득이지, 포획이 아니다.
- **거대한 오픈 월드가 아니다**: 첫 게임 범위를 벗어나고 Pillar 4의 이야기 밀도가 희석된다.
- **비주얼 노벨이 아니다**: Pillar 2가 사라진다. 전투의 짜릿함 없이는 유랑단이 아니다.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **퍼스트퀸4** | 실시간 군단 전투, 팀이 커지는 스노우볼 감각 | 동료 영입을 퀘스트/관계 기반으로 깊이 있게 | 코어 판타지를 검증한 고전 레퍼런스 |
| **스타듀밸리** | 신뢰 수치→해금 시스템, NPC 각자의 이야기 | 농장 경영 대신 전투와 탐험이 메인 루프 | 관계 기반 해금이 실제로 동작함을 증명 |
| **삼국지3** | 인물 수집과 세력 강화의 장기 루프 | 턴제 전략 대신 실시간 개인 액션 RPG | 인물 영입의 전략적 깊이와 만족감 |

**비게임 영감**: 구로사와 아키라 영화의 "7인의 사무라이" 구조 — 각자의 이유로 모인 팀이 하나가 되는 과정.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 20–35세 |
| **Gaming experience** | 미드코어 (인디 RPG 경험 있음) |
| **Time availability** | 평일 저녁 30~60분, 주말 2시간+ |
| **Platform preference** | PC (Steam) |
| **Current games they play** | 스타듀밸리, 언더테일, 파이어 엠블렘 |
| **What they're looking for** | 이야기 있는 동료들과 함께 성장하는 경험 — 단순 수치 RPG가 아닌 것 |
| **What would turn them away** | 반복적인 그라인드, 이야기 없는 캐릭터, 너무 높은 전투 난이도 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4 — 2D에 강하고 인디 친화적, 무료 오픈소스 |
| **Key Technical Challenges** | 여러 동료 캐릭터의 실시간 AI 동시 제어 (Pillar 2의 핵심) |
| **Art Style** | 2D 픽셀 아트 (미확정 — /art-bible 후 확정) |
| **Art Pipeline Complexity** | Medium — 커스텀 2D 캐릭터 스프라이트 다수 |
| **Audio Needs** | Moderate — 전투/탐험 BGM, 동료 합류 연출음 |
| **Networking** | None — 싱글플레이어 |
| **Content Volume** | MVP: 동료 3명, 맵 3개, 퀘스트 3개. Full: 동료 10명, 지역 8~10개 |
| **Procedural Systems** | 없음 — 핸드크래프티드 퀘스트와 지역 |

---

## Risks and Open Questions

### Design Risks
- 동료 AI가 "나와 함께 싸운다"는 느낌보다 "옆에서 돌아다니는 오브젝트"처럼 느껴질 위험
- 각 동료 퀘스트의 이야기 품질 편차 — 일부 퀘스트가 재미없으면 해당 캐릭터 영입 동기 하락

### Technical Risks
- 실시간 전투에서 여러 캐릭터 AI 동시 제어 — Godot NavMesh + 상태 머신 필요, 미검증
- 팀 규모 증가에 따른 전투 성능 최적화 (10명 이상 동시 처리)

### Market Risks
- 파이어 엠블렘, 언더테일 등 강력한 레퍼런스 게임 대비 차별화 소구 필요
- 한국 개발자 인디 PC 게임의 Steam 노출 어려움

### Scope Risks
- "동료 한 명만 더 추가하면..." 유혹에 의한 영입 퀘스트 과잉 확장
- 첫 게임으로서 전투 시스템 + 관계 시스템 동시 구현의 복잡도

### Open Questions
- 동료 AI는 얼마나 자율적으로 행동해야 하는가? (완전 자동 vs. 플레이어 지시 하이브리드) — 프로토타입으로 검증
- 동료 사망/이탈 시스템이 있어야 하는가? — 첫 게임에서는 제외 권장
- 전투는 얼마나 복잡해야 하는가? — MVP에서 단순 버전으로 시작, 반응 보고 확장

---

## MVP Definition

**Core hypothesis**: "동료 영입 퀘스트 완료 → 합류 → 전투 변화"의 한 사이클이 30~60분 플레이에서 충분히 재미있는가?

**Required for MVP**:
1. 실시간 이동 + 기본 전투 (플레이어 캐릭터 + 동료 자동 전투)
2. 동료 3명, 각 1개의 간단한 영입 퀘스트
3. 소형 맵 3개 (각 동료의 퀘스트 지역)
4. 동료 합류 시 전투 시각 변화 (화면에 추가 캐릭터)

**Explicitly NOT in MVP**:
- 복잡한 스킬 트리 또는 장비 시스템
- 스토리 연출 (컷씬, 풀 다이얼로그)
- 음악/효과음 완성본
- 팀 구성 기반 지역 잠금 해제 (2차 목표)

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 동료 3명, 맵 3개, 퀘스트 3개 | 기본 전투 + 영입 루프 | 3–5주 |
| **Vertical Slice** | 동료 5명, 맵 5개, 시너지 1~2개 | 전투 + 영입 + 팀 잠금 해제 | 3~4개월 |
| **Alpha** | 동료 8명, 전 지역 플레이 가능 | 전체 시스템 (거칠게) | 8~12개월 |
| **Full Vision** | 동료 10명+, 완성된 이야기와 엔딩 | 모든 기능 + 폴리시 | 18–24개월, 솔로 |

---

## Next Steps

- [ ] `/setup-engine` — Godot 4 엔진 설정 및 버전별 레퍼런스 문서 갱신
- [ ] `/art-bible` — 비주얼 아이덴티티 확정 (GDD 작성 전 필수)
- [ ] `/design-review design/gdd/game-concept.md` — 컨셉 완성도 검증
- [ ] `/map-systems` — 시스템 분해 및 의존성 매핑
- [ ] `/design-system [combat]` — 전투 시스템 GDD 작성
- [ ] `/design-system [recruitment]` — 영입 시스템 GDD 작성
- [ ] `/create-architecture` — 마스터 아키텍처 블루프린트
- [ ] `/prototype [recruitment-combat-loop]` — 코어 루프 프로토타입
- [ ] `/playtest-report` — 코어 가설 검증
- [ ] `/sprint-plan new` — 첫 스프린트 계획
