# Review Log: NPC 상태 관리 (NPC State Manager)

---

## Review — 2026-04-25 — Verdict: NEEDS REVISION → REVISED (Pending Re-review)

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, narrative-director, godot-gdscript-specialist, creative-director
Blocking items: 8 | Recommended: 10
Summary: Player Fantasy가 세 레이어(저장/조회/표현) 모두에서 손상되어 있었음 — `_quest_flags` @export 누락으로 ResourceSaver가 묵음 폐기, 대화 레이어 읽기 경로 없음. QUEST_ACTIVE + quest_abandoned 이중 진실을 QUEST_ABANDONED(6) 신규 상태로 해소. set_state()가 party_slot 자동 할당 담당으로 확정, get_companions() .duplicate() 반환으로 캐시 재진입 버그 방지, schema_version 필드 추가, DEPARTED→HOSTILE 차단, bond_tags AC 추가. 대화 시스템 인터페이스 계약 스텁 추가.
Prior verdict resolved: Yes (2026-04-19 12개 블로커 → 이번 8개 신규 블로커 동일 세션 수정 완료)

---

## Review — 2026-04-19 — Verdict: NEEDS REVISION → REVISED (Pending Re-review)

Scope signal: L
Specialists: game-designer, systems-designer, godot-gdscript-specialist, narrative-director, qa-lead, creative-director
Blocking items: 12 | Recommended: 13
Summary: Foundation 데이터 레이어로서 스키마 미완성(필드 4개 미정의), HOSTILE 터미널 상태의 Pillar 4 위반, tags 정의 시 고정으로 인한 Pillar 1/2 충돌, Autoload 초기화 순서 오류, GUT 단위 테스트 불가 AC 구조 등 12개 블로킹 이슈 발견. 동일 세션 내 수정 완료: NPCRecord 필드 스키마 확정, recruitment_tags/bond_tags 분리, HOSTILE quest_flags 복구 예약, QUEST_ACTIVE 포기 패턴 추가, error_occurred 신호 요구사항 명시, AC 18개로 확장.
Prior verdict resolved: N/A (최초 리뷰 + 동일 세션 수정)
