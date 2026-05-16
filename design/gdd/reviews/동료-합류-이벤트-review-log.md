# Review Log: 동료 합류 이벤트 (Companion Join Event)

---

## Review — 2026-04-26 — Verdict: MAJOR REVISION NEEDED → Revised

Scope signal: M
Specialists: game-designer, systems-designer, qa-lead, gameplay-programmer, godot-gdscript-specialist, creative-director
Blocking items: 6 | Recommended: 5
Summary: 감정 시퀀스가 역전되어 HUD가 캐릭터 등장 이전에 갱신되고 SFX가 시각 연출과 분리되어 있었다(B-1). Godot await 패턴 3종이 `_is_playing` 영구 잠금을 유발하는 런타임 버그였으며(B-2), `companion_scenes` 딕셔너리와 `CompanionLayer` 경로가 전혀 정의되어 있지 않아 구현이 불가능한 상태였다(B-3/B-4). AC 4개가 검증 불가, 2개가 누락이었다(B-6). 같은 세션 내에서 모든 블로커 해소 완료.
Prior verdict resolved: N/A (첫 리뷰, 동일 세션 수정)

### 핵심 변경 사항 (2026-04-26)

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 신호 구조 | `companion_joined` 1개 (Phase A 직후) | `companion_data_registered` (Phase A, 내부) + `companion_appeared` (Phase C 완료, HUD) |
| SFX 타이밍 | Phase A 완료 직후 fire-and-forget | Phase C 씬 인스턴스화 직후 (페이드인과 동시) |
| companion_scenes | 미정의 | `@export var companion_scenes: Dictionary[StringName, PackedScene]` |
| CompanionLayer 조회 | `get_node()` 경로 미지정 | `get_tree().get_first_node_in_group(&"companion_layer")` |
| EC-1 (노드 해제) | `_exit_tree()` 만 | + `is_instance_valid(self)` await 후 체크 |
| EC-2 (Pause) | CompanionJoinEvent만 ALWAYS | AnimationPlayer도 PROCESS_MODE_ALWAYS |
| EC-9 (신규) | 없음 | `has_animation("join_in")` 가드 + 폴백 |
| AC 수 | 10개 (4개 불합격) | 12개 (모두 독립 검증 가능) |
