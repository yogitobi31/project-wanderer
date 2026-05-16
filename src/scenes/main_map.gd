@tool
extends Node2D

const TILE_GRASS := Vector2i(0, 0)
const TILE_WALL  := Vector2i(1, 0)
const TILE_PATH  := Vector2i(2, 0)
const SOURCE_ID  := 0

## 20x15 테스트맵 레이아웃 (G=Grass, W=Wall, P=Path)
const MAP_ROWS: Array[String] = [
	"WWWWWWWWWWWWWWWWWWWW",
	"WGGGGGGGGGGGGGGGGGGW",
	"WGGWWGGGGGGGGGGWWGGW",
	"WGGWWGGGGGGGGGGWWGGW",
	"WGGGGGGGGGGGGGGGGGGW",
	"WGGGGGWWGGGGWWGGGGGW",
	"WGGGGGWWGGGGWWGGGGGW",
	"WPPPPPPPPPPPPPPPPPPW",
	"WGGGGGGGGGGGGGGGGGGW",
	"WGGGGGWWGGGGWWGGGGGW",
	"WGGGGGWWGGGGWWGGGGGW",
	"WGGGGGGGGGGGGGGGGGGW",
	"WGGWWGGGGGGGGGGWWGGW",
	"WGGGGGGGGGGGGGGGGGGW",
	"WWWWWWWWWWWWWWWWWWWW",
]


func _ready() -> void:
	_populate_tiles()
	_validate_navigation()
	_wire_party()


func _wire_party() -> void:
	var player: CharacterBody2D = get_node_or_null("PlayerController")
	var companion_a: Node = get_node_or_null("Companion_A")
	if is_instance_valid(companion_a) and is_instance_valid(player):
		companion_a.player_target = player


func _populate_tiles() -> void:
	var tile_layer: TileMapLayer = $NavigationRegion2D/TileMapLayer
	if not is_instance_valid(tile_layer):
		push_error("[MainMap] TileMapLayer not found")
		return
	tile_layer.clear()
	for row_idx: int in MAP_ROWS.size():
		var row: String = MAP_ROWS[row_idx]
		for col_idx: int in row.length():
			var atlas: Vector2i
			match row[col_idx]:
				"W": atlas = TILE_WALL
				"P": atlas = TILE_PATH
				_:   atlas = TILE_GRASS
			tile_layer.set_cell(Vector2i(col_idx, row_idx), SOURCE_ID, atlas)


## TileMapLayer 네비게이션 상태를 Output 패널에 출력합니다.
## Godot 4.x: TileMapLayer는 NavigationServer2D에 직접 등록됩니다.
## NavigationRegion2D bake는 TileMapLayer tile nav data를 읽지 않으므로 사용하지 않습니다.
func _validate_navigation() -> void:
	var tile_layer: TileMapLayer = $NavigationRegion2D/TileMapLayer
	if not is_instance_valid(tile_layer):
		push_error("[MainMap] FAIL: TileMapLayer not found")
		return

	var tile_set: TileSet = tile_layer.tile_set
	if tile_set == null:
		push_error("[MainMap] FAIL: TileSet is null - AC-4 위반")
		return

	var nav_layer_count: int = tile_set.get_navigation_layers_count()
	var used_cell_count: int = tile_layer.get_used_cells().size()

	if nav_layer_count == 0:
		push_warning("[MainMap] WARN: TileSet에 navigation layer가 없음 - NavigationAgent2D 동작 불가")
	elif used_cell_count == 0:
		push_warning("[MainMap] WARN: 배치된 타일 없음 - _populate_tiles() 확인 필요")
	else:
		print("[MainMap] OK: nav_layers=%d, placed_tiles=%d - TileMapLayer navigation 준비 완료" \
				% [nav_layer_count, used_cell_count])
