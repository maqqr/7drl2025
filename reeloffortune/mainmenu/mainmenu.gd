extends Control

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")
