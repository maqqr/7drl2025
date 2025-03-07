extends Control

func _ready() -> void:
	MusicManager.play_music(MusicManager.Music.MENU)

func _process(_delta: float) -> void:
	pass

func on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")
