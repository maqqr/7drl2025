class_name GameTileMap
extends Node

const TILE_PREFABS: Dictionary[Enum.TileType, PackedScene] = {
	Enum.TileType.WALL: preload("res://tile/wall.tscn"),
	Enum.TileType.FLOOR: preload("res://tile/floor.tscn"),
	Enum.TileType.WATER: preload("res://tile/water.tscn"),
}

var width: int
var height: int
var tiles: PackedInt32Array
var tile_nodes: Array[Node3D] = []

func _ready() -> void:
	pass

func _process(delta: float) -> void:
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

func set_tiles(width: int, height: int, tiles: PackedInt32Array) -> void:
	for old_tile in tile_nodes:
		old_tile.queue_free()
	tile_nodes.clear()
	self.width = width
	self.height = height
	self.tiles = tiles
	for y in height:
		for x in width:
			var tile_pos = Vector2i(x, y)
			var prefab = TILE_PREFABS[get_tile(tile_pos)]
			var node: Node3D = prefab.instantiate()
			add_child(node)
			node.global_position = to_scene_pos(tile_pos)
			tile_nodes.append(node)

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
	return candidates[randi_range(0, candidates.size())]

func is_walkable(pos: Vector2i) -> bool:
	return get_tile(pos) == Enum.TileType.FLOOR
