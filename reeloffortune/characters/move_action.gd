class_name MoveAction
extends RefCounted

var progress: float = 0.0
var duration: float = 0.5
var character: Character
var from: Vector2i
var to: Vector2i
var target_angle: float

var walk_animation_name: StringName = &"Armature|walk"

func _init(character: Character, from: Vector2i, to: Vector2i, direction: Vector2i):
	self.character = character
	self.from = from
	self.to = to
	var dir = Vector2(direction).normalized()
	self.target_angle = atan2(dir.x, dir.y)
	if not self.character.animation_player.current_animation == walk_animation_name and from != to:
		self.character.animation_player.play(walk_animation_name, 0.3)

func execute(delta: float) -> bool:
	progress = min(1.0, progress + delta / duration)
	character.global_position = GameTileMap.to_scene_pos(from).lerp(GameTileMap.to_scene_pos(to), progress)
	character.global_rotation.y = lerp_angle(character.global_rotation.y, target_angle, progress)
	return progress >= 1.0
