class_name BreakAction
extends RefCounted

var progress: float = 0.0
var duration: float = 1.0
var character: Character
var from: Vector2i
var to: Vector2i
var target_angle: float
var target_breakable: Breakable

const SIGNAL_TIME = 0.6

signal break_signal

func _init(p_character: Character, p_from: Vector2i, p_to: Vector2i, p_direction: Vector2i, p_breakable: Breakable):
	self.character = p_character
	self.from = p_from
	self.to = p_to
	var dir = Vector2(p_direction).normalized()
	self.target_angle = atan2(dir.x, dir.y)
	self.target_breakable = p_breakable
	self.character.animation_player.stop()
	self.character.animation_player.play(character.get_break_animation_name(), 0.3)

func execute(game_manager: GameManager, delta: float) -> bool:
	var prev_progress = progress
	progress = min(1.0, progress + delta / duration)
	character.global_rotation.y = lerp_angle(character.global_rotation.y, target_angle, progress)

	if progress >= SIGNAL_TIME and prev_progress < SIGNAL_TIME:
		break_signal.emit()

	return progress >= 1.0
