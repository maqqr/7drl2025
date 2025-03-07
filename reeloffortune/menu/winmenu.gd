extends Node3D

func _ready() -> void:
	$player/AnimationPlayer.play("Armature|dance")
	MusicManager.play_music(MusicManager.Music.END)

func _process(delta: float) -> void:
	pass

func on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/mainmenu.tscn")
