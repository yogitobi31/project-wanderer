# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: GdUnit4
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-05-05

## Directory Layout

```
tests/
  unit/           # 단위 테스트 (공식, 상태 머신, 로직) — 시스템별 서브디렉토리
  integration/    # 크로스 시스템 테스트 및 저장/로드 라운드트립
  smoke/          # /smoke-check 게이트용 핵심 경로 체크리스트
  evidence/       # 수동 QA 스크린샷·사인오프 문서
  scenes/manual/  # 수동 QA 테스트 씬
  gdunit4_runner.gd  # CI 헤드리스 실행 엔트리포인트
```

## 테스트 실행

```bash
# CI / 로컬 헤드리스
godot --headless --script tests/gdunit4_runner.gd

# Godot 에디터 내
# GdUnit4 패널 → Run All
```

## GdUnit4 설치

1. Godot 에디터 → AssetLib → "GdUnit4" 검색 → Download & Install
2. 플러그인 활성화: Project → Project Settings → Plugins → GdUnit4 ✓
3. 에디터 재시작
4. 확인: `res://addons/gdunit4/` 존재 여부

## 테스트 명명 규칙

- **파일**: `[system]_[feature]_test.gd`
- **함수**: `test_[scenario]_[expected]()`
- **예시**: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## 스토리 타입별 테스트 증거

| 스토리 타입 | 필요 증거 | 위치 | 게이트 |
|---|---|---|---|
| Logic | 자동화 단위 테스트 — 통과 필수 | `tests/unit/[system]/` | BLOCKING |
| Integration | 통합 테스트 또는 플레이테스트 문서 | `tests/integration/[system]/` | BLOCKING |
| Visual/Feel | 스크린샷 + 리드 사인오프 | `tests/evidence/` | ADVISORY |
| UI | 수동 워크스루 또는 인터랙션 테스트 | `tests/evidence/` | ADVISORY |
| Config/Data | 스모크 체크 통과 | `production/qa/smoke-*.md` | ADVISORY |

## CI

`main` 브랜치 푸시 및 모든 PR에서 자동으로 테스트 실행.
테스트 실패 시 머지 차단.
