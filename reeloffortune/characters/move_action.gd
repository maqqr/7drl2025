class_name MoveAction
extends RefCounted

var progress: float = 0.0
var duration: float = 0.5
var character: Character
var from: Vector2i
var to: Vector2i
var target_angle: float

func _init(p_character: Character, p_from: Vector2i, p_to: Vector2i, p_direction: Vector2i):
	self.character = p_character
	self.from = p_from
	self.to = p_to
	var dir = Vector2(p_direction).normalized()
	self.target_angle = atan2(dir.x, dir.y)
	if not self.character.animation_player.current_animation == character.get_walk_animation_name() and p_from != p_to:
		self.character.animation_player.play(character.get_walk_animation_name(), 0.3)

func get_tile_floor_height(game_manager: GameManager, pos: Vector2i) -> float:
	match game_manager.tilemap.get_tile(pos):
		Enum.TileType.DOWNSTAIRS: return -0.6
	return 0.0

func get_tile_scene_position(game_manager: GameManager, pos: Vector2i) -> Vector3:
	return GameTileMap.to_scene_pos(pos) + Vector3(0.0, get_tile_floor_height(game_manager, pos), 0.0)

func execute(game_manager: GameManager, delta: float) -> bool:
	progress = min(1.0, progress + delta / duration)
	character.global_position = get_tile_scene_position(game_manager, from).lerp(get_tile_scene_position(game_manager, to), progress)
	character.global_rotation.y = lerp_angle(character.global_rotation.y, target_angle, progress)
	return progress >= 1.0
