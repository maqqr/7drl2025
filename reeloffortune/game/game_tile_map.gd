class_name GameTileMap
extends Node

enum TileType {
	WALL,
	FLOOR,
	WATER,
}

const TILE_PREFABS: Dictionary[TileType, PackedScene] = {
	TileType.WALL: preload("res://tile/wall.tscn"),
	TileType.FLOOR: preload("res://tile/floor.tscn"),
	TileType.WATER: preload("res://tile/floor.tscn"),
}

var width: int
var height: int
var tiles: PackedInt32Array

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func get_tile(position: Vector2i) -> TileType:
	if position.x >= 0 and position.x < width and position.y >= 0 and position.y < height:
		var value = tiles[position.x + position.y * width]
		return value as TileType
	return TileType.WALL

func set_tiles(width: int, height: int, tiles: PackedInt32Array) -> void:
	self.width = width
	self.height = height
	self.tiles = tiles
	for y in height:
		for x in width:
			var prefab = TILE_PREFABS[get_tile(Vector2i(x, y))]
