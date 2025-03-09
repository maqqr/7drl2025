extends Control

@export var title_sprite: Sprite2D
@export var story_text: Control

var continue_pressed: bool
var can_press_continue: bool

func _ready() -> void:
	MusicManager.play_music(MusicManager.Music.MENU)

func _process(_delta: float) -> void:
	pass

func on_start_pressed() -> void:
	$Button.queue_free()
	
	var tween = get_tree().create_tween()
	tween.tween_property(title_sprite, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), 2.0)
	tween.tween_interval(1)

	tween.tween_property(story_text.get_parent(), "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0)
	tween.tween_callback(func (): can_press_continue = true)

func on_continue_pressed() -> void:
	if continue_pressed or !can_press_continue:
		return
	continue_pressed = true
	var tween = get_tree().create_tween()
	tween.tween_property(story_text.get_parent(), "modulate", Color(0.0, 0.0, 0.0, 0.0), 2.0)
	tween.tween_callback(start_game)

func start_game() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")
