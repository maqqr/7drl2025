class_name Character
extends Node3D

@export var health: int
@export var stats: CharacterStats
@export var map_position: Vector2i
@export var unarmed: bool = true
var animation_player: AnimationPlayer

func _ready() -> void:
	animation_player = find_child("AnimationPlayer")

func _process(delta: float) -> void:
	pass

func play_idle():
	if animation_player.current_animation != get_idle_animation_name():
		animation_player.play(get_idle_animation_name(), 0.5, 1.0)

func teleport_to(pos: Vector2i) -> void:
	map_position = pos
	global_position = GameTileMap.to_scene_pos(map_position)

func get_idle_animation_name() -> StringName:
	return &"Armature|idle" if !unarmed else &"Armature|idle_unarmed"

func get_walk_animation_name() -> StringName:
	return &"Armature|walk" if !unarmed else &"Armature|walk_unarmed"
