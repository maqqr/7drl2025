class_name Character
extends Node3D

@export var health: int
@export var stats: CharacterStats
@export var map_position: Vector2i
var animation_player: AnimationPlayer

var idle_animation: StringName = &"Armature|idle"

func _ready() -> void:
	animation_player = find_child("AnimationPlayer")

func _process(delta: float) -> void:
	pass

func play_idle():
	if animation_player.current_animation != idle_animation:
		animation_player.play(idle_animation, 0.5, 1.0)

func teleport_to(pos: Vector2i) -> void:
	map_position = pos
	global_position = GameTileMap.to_scene_pos(map_position)
