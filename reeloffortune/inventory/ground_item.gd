class_name GroundItem
extends Node3D

@export var map_position: Vector2i
@export var item: Item

func _ready():
	$Sprite3D.texture = item.item_type.sprite
	global_position = GameTileMap.to_scene_pos(map_position)
