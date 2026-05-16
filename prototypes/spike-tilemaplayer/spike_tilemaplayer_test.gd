extends GutTest

# Spike: TileMapLayer API — Godot 4.6 검증
# ADR-0003: "spawn_points" 그룹으로 SpawnPoint 조회

var _scene_root: Node

func before_each() -> void:
	# 씬 구조 수동 구성 (tscn 없이 GUT headless 실행 가능하도록)
	_scene_root = Node2D.new()
	add_child(_scene_root)

func after_each() -> void:
	# queue_free()는 다음 프레임에 해제 — 테스트 간 그룹 노드 잔존으로 격리 실패
	_scene_root.free()

func test_tilemaplayer_node_exists_in_godot_46() -> void:
	# TileMapLayer 클래스가 존재하는지 확인 (Godot 4.4 이전: 없음)
	var layer := TileMapLayer.new()
	assert_not_null(layer, "TileMapLayer 클래스가 Godot 4.6에 존재해야 한다")
	layer.free()

func test_spawn_point_group_query() -> void:
	# SpawnPoint 노드를 "spawn_points" 그룹에 추가하고 조회
	var spawnpoint_default := Marker2D.new()
	spawnpoint_default.name = "SpawnPoint_Default"
	spawnpoint_default.position = Vector2(100, 100)
	spawnpoint_default.add_to_group("spawn_points")
	_scene_root.add_child(spawnpoint_default)

	var spawnpoint_inn := Marker2D.new()
	spawnpoint_inn.name = "SpawnPoint_inn"
	spawnpoint_inn.position = Vector2(200, 300)
	spawnpoint_inn.add_to_group("spawn_points")
	_scene_root.add_child(spawnpoint_inn)

	var found: Array[Node] = _scene_root.get_tree().get_nodes_in_group("spawn_points")

	assert_eq(found.size(), 2, "spawn_points 그룹에 2개 노드가 있어야 한다")

func test_spawn_point_position_accessible() -> void:
	var spawnpoint := Marker2D.new()
	spawnpoint.name = "SpawnPoint_inn"
	spawnpoint.position = Vector2(200, 300)
	spawnpoint.add_to_group("spawn_points")
	_scene_root.add_child(spawnpoint)

	var found: Array[Node] = _scene_root.get_tree().get_nodes_in_group("spawn_points")
	assert_eq(found.size(), 1)

	var node := found[0] as Node2D
	assert_not_null(node, "spawn_points 노드가 Node2D로 캐스팅 가능해야 한다")
	assert_eq(node.position, Vector2(200, 300), "SpawnPoint 위치가 (200, 300)이어야 한다")

func test_tilemaplayer_local_to_map_returns_vector2i() -> void:
	var layer := TileMapLayer.new()
	# TileSet 미할당 시 "tile_set.is_null()" 엔진 에러 + Vector2i() 반환 → GUT Unexpected Error
	layer.tile_set = TileSet.new()
	_scene_root.add_child(layer)

	var result = layer.local_to_map(Vector2(32, 32))
	# assert_is()는 builtin 타입을 인자로 받지 못함 — is 키워드로 대체
	assert_true(result is Vector2i, "local_to_map() 반환 타입이 Vector2i여야 한다")

func test_tilemaplayer_map_to_local_returns_vector2() -> void:
	var layer := TileMapLayer.new()
	# TileSet 미할당 시 "tile_set.is_null()" 엔진 에러 + Vector2() 반환 → GUT Unexpected Error
	layer.tile_set = TileSet.new()
	_scene_root.add_child(layer)

	var result = layer.map_to_local(Vector2i(1, 1))
	# assert_is()는 builtin 타입을 인자로 받지 못함 — is 키워드로 대체
	assert_true(result is Vector2, "map_to_local() 반환 타입이 Vector2여야 한다")
