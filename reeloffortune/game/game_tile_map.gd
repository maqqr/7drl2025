class_name GameTileMap
extends Node

const TILE_PREFABS: Dictionary[Enum.TileType, PackedScene] = {
	Enum.TileType.WALL: preload("res://tile/wall.tscn"),
	Enum.TileType.FLOOR: preload("res://tile/floor.tscn"),
	Enum.TileType.WATER: preload("res://tile/water.tscn"),
	Enum.TileType.DOWNSTAIRS: preload("res://tile/downstairs.tscn"),
}

var width: int
var height: int
var tiles: PackedInt32Array
var tile_nodes: Array[Node3D] = []
var wall_deco_prefab: PackedScene = preload("res://tile/wall_deco.tscn")

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

static func to_tile_pos(pos: Vector3) -> Vector2i:
	return Vector2i(round(pos.x), round(pos.z))

static func to_scene_pos(tile_pos: Vector2i) -> Vector3:
	return Vector3(tile_pos.x, 0.0, tile_pos.y)

func get_tile(position: Vector2i) -> Enum.TileType:
	if position.x >= 0 and position.x < width and position.y >= 0 and position.y < height:
		var value = tiles[position.x + position.y * width]
		return value as Enum.TileType
	return Enum.TileType.WALL

func set_tiles(p_width: int, p_height: int, p_tiles: PackedInt32Array) -> void:
	for old_tile in tile_nodes:
		old_tile.queue_free()
	tile_nodes.clear()
	self.width = p_width
	self.height = p_height
	self.tiles = p_tiles
	for y in height:
		for x in width:
			# Add tile model
			var tile_pos = Vector2i(x, y)
			var prefab = TILE_PREFABS[get_tile(tile_pos)]
			var node: Node3D = prefab.instantiate()
			add_child(node)
			node.global_position = to_scene_pos(tile_pos)
			tile_nodes.append(node)

			const DIRS = [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1)]
			for i in range(DIRS.size()):
				# Add wall tile decoration
				if get_tile(tile_pos) != Enum.TileType.WALL and get_tile(tile_pos + DIRS[i]) == Enum.TileType.WALL:
					var deco: Node3D = wall_deco_prefab.instantiate()
					add_child(deco)
					deco.global_position = to_scene_pos(tile_pos)
					deco.rotate(Vector3(0, 1, 0), PI * 0.5 * i)

				# Add water tile decoration
				if get_tile(tile_pos) == Enum.TileType.WATER and get_tile(tile_pos + DIRS[i]) != Enum.TileType.WATER:
					var deco: Node3D = wall_deco_prefab.instantiate()
					add_child(deco)
					deco.global_position = to_scene_pos(tile_pos) + Vector3(0.0, -0.66, 0.0)
					deco.rotate(Vector3(0, 1, 0), PI * 0.5 * i)

func find_tile(tile_type: Enum.TileType, take_first: bool = false) -> Vector2i:
	var candidates = []
	for y in height:
		for x in width:
			var pos = Vector2i(x, y)
			if get_tile(pos) == tile_type:
				if take_first:
					return pos
				candidates.append(pos)
	if candidates.is_empty():
		push_error("Tile " + str(tile_type) + " not found")
		return Vector2i.ZERO
	return candidates[randi_range(0, candidates.size() - 1)]

func is_walkable(pos: Vector2i) -> bool:
	return get_tile(pos) == Enum.TileType.FLOOR || get_tile(pos) == Enum.TileType.DOWNSTAIRS
