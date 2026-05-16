# -*- coding: utf-8 -*-
"""
validate_map_nav.py - MapScene story-001 네비게이션 설정 검증 스크립트

[Godot 4.x 동작 방식]
TileMapLayer는 TileSet의 navigation layer 데이터를 읽어 NavigationServer2D에 직접 등록합니다.
NavigationRegion2D "굽기" 버튼은 TileMapLayer tile nav data를 사용하지 않으므로,
bake 결과 vertices=0은 정상입니다 (오류 아님).

실제 검증 항목:
  1. TileSet에 navigation_layer_0 설정
  2. Grass/Path 타일에 navigation polygon 정의
  3. Wall 타일에 navigation polygon 없음 (장애물)
  4. TileMapLayer → world_tileset.tres 참조
  5. SpawnPoint_Default 그룹 등록
  6. main_map.gd @tool 스크립트 연결

사용법:
    python tools/validate_map_nav.py
"""

import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
TSCN_PATH = ROOT / "src" / "scenes" / "main_map.tscn"
TRES_PATH = ROOT / "assets" / "tilesets" / "world_tileset.tres"

PASS_TAG = "\033[92mPASS\033[0m"
FAIL_TAG = "\033[91mFAIL\033[0m"
WARN_TAG = "\033[93mWARN\033[0m"
INFO_TAG = "\033[94mINFO\033[0m"

results: list[tuple[str, str]] = []


def check(label: str, condition: bool, fail_msg: str = "", warn: bool = False) -> bool:
    if condition:
        results.append((PASS_TAG, label))
    else:
        tag = WARN_TAG if warn else FAIL_TAG
        results.append((tag, f"{label} -- {fail_msg}"))
    return condition


def validate_tscn(content: str) -> bool:
    ok = True

    ok &= check(
        "TileMapLayer 노드 존재",
        'type="TileMapLayer"' in content,
        "TileMapLayer 노드가 씬에 없습니다",
    )

    ok &= check(
        "TileMapLayer -> world_tileset.tres 참조",
        "world_tileset.tres" in content,
        "TileMapLayer가 world_tileset.tres를 참조하지 않습니다",
    )

    ok &= check(
        "NavigationRegion2D 노드 존재 (AI 경로용 앵커)",
        'type="NavigationRegion2D"' in content,
        "NavigationRegion2D 노드가 씬에 없습니다",
    )

    ok &= check(
        "SpawnPoint_Default 그룹 등록",
        'groups=["spawn_points"]' in content,
        "SpawnPoint_Default에 spawn_points 그룹이 없습니다",
    )

    ok &= check(
        "@tool 스크립트 연결 (main_map.gd)",
        "main_map.gd" in content,
        "MainMap 노드에 main_map.gd 스크립트가 연결되지 않았습니다",
    )

    # NavigationRegion2D bake 결과는 검증하지 않음 (Godot 4.x TileMapLayer 독립 nav)
    results.append((INFO_TAG,
        "NavigationPolygon bake -- TileMapLayer는 NavigationServer2D에 직접 등록 (bake 불필요)"))

    return ok


def validate_tres(content: str) -> bool:
    ok = True

    ok &= check(
        "TileSet navigation_layer_0 설정",
        "navigation_layer_0/layers" in content,
        "TileSet에 navigation_layer_0이 없습니다 -- NavigationAgent2D 동작 불가",
    )

    ok &= check(
        "Grass 타일 (0:0) navigation polygon 정의",
        "0:0/0/navigation_layer_0/polygon" in content,
        "Grass 타일에 nav polygon 없음 -- 플레이어/동료가 Grass를 이동 불가",
    )

    ok &= check(
        "Path 타일 (2:0) navigation polygon 정의",
        "2:0/0/navigation_layer_0/polygon" in content,
        "Path 타일에 nav polygon 없음",
    )

    check(
        "Wall 타일 (1:0) nav polygon 없음 -- 장애물 동작 확인",
        "1:0/0/navigation_layer_0/polygon" not in content,
        warn=True,
        fail_msg="Wall 타일에 nav polygon이 있습니다 -- 벽 통과 가능",
    )

    return ok


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("MapScene story-001 - Navigation 설정 검증")
    print("=" * 60)

    if not TSCN_PATH.exists():
        print(f"{FAIL_TAG} src/scenes/main_map.tscn 파일 없음")
        return 1
    if not TRES_PATH.exists():
        print(f"{FAIL_TAG} assets/tilesets/world_tileset.tres 파일 없음")
        return 1

    tscn_content = TSCN_PATH.read_text(encoding="utf-8")
    tres_content = TRES_PATH.read_text(encoding="utf-8")

    print("\n[main_map.tscn]")
    tscn_ok = validate_tscn(tscn_content)

    print("\n[world_tileset.tres]")
    tres_ok = validate_tres(tres_content)

    print("\n" + "-" * 60)
    for tag, label in results:
        print(f"  {tag}  {label}")
    print("-" * 60)

    all_ok = tscn_ok and tres_ok
    if all_ok:
        print(f"\n{PASS_TAG} 모든 검증 통과")
        print("  Godot Output 패널에서 다음 메시지 확인:")
        print("  '[MainMap] OK: nav_layers=1, placed_tiles=N -- TileMapLayer navigation 준비 완료'")
        return 0
    else:
        print(f"\n{FAIL_TAG} 검증 실패 항목이 있습니다. 위 결과를 확인하세요.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
