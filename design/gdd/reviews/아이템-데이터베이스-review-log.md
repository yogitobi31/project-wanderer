# Review Log: 아이템 데이터베이스 (Item Database)

## Review — 2026-04-25 — Verdict: MAJOR REVISION NEEDED → Revised

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, godot-gdscript-specialist, creative-director
Blocking items: 9 | Recommended: 6
Summary: 데이터 스키마 아키텍처는 견고하나, Pillar 1(Earned Fellowship) 판타지 전달을 위한 UI/오디오 계약이 완전히 부재했다. max_stack CONSUMABLE 기본값 불일치(99 vs 20)가 4개 전문가 전원에게 확인된 구현 불가 블로커였으며, 퀘스트 상태 머신 GDD와의 교차-시스템 계약(QUEST_ITEM 자동 제거, 복수 퀘스트 소비 순서)이 두 Done 시스템 간 낙하된 상태였다. 이번 리뷰 세션에서 모든 블로커를 즉시 수정 완료.
Prior verdict resolved: First review (no prior verdict)

### 이번 리뷰에서 해소된 블로커

1. **UI/오디오 계약 부재** → Visual/Audio Requirements, UI Requirements 섹션 채움 + 교차-시스템 계약 4개 명시
2. **퀘스트 상태 머신 교차 계약 불이행** → Interactions에 [계약 1] QUEST_ITEM 제거 인터페이스 + Open Questions 추적 항목 추가
3. **max_stack CONSUMABLE 기본값 강제 메커니즘 미명시** → `CONSUMABLE_MAX_STACK_DEFAULT=20` 상수, `_validate_definitions()` 보정 규칙, AC-ITEM-CR-11 재작성
4. **HEAL effect_value=0.0 조용한 버그** → push_error + 등록 거부 검증 규칙, AC-ITEM-EC-04 추가
5. **Rule 7 다운스트림 계약 부재** → [계약 2] 인벤토리 시스템 카테고리 검사 의무 명시
6. **category/effect_type int vs enum 타입** → @export 타입 지침 추가
7. **Array[StringName] 직렬화 경계** → 주의사항 명시
8. **Autoload 로드 전략 미명시** → DirAccess 스캔 전략, Autoload 등록 순서 명시
9. **quest_tags 역방향 검증 누락** → quest_tags 비어 있지 않음 + is_quest_item=false → push_error + 거부 규칙 추가

### 남은 추적 항목

- 퀘스트 상태 머신 GDD 재검토 필요 (Producer 조정): QUEST_ITEM 자동 제거 인터페이스, 복수 퀘스트 소비 순서
- AC-ITEM-EC-02: 퀘스트 상태 머신 GDD 완성 후 Integration 테스트로 전환 [DEFERRED]
- CONSUMABLE effect_value 수치: 체력/데미지 시스템 GDD 완성 후 결정
