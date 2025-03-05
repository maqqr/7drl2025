extends Node

var audio: AudioStreamPlayer

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	add_child(audio)
	
	audio.stream = preload("res://audio/music/menu.ogg")
	audio.volume_linear = 0.6
	if not OS.has_feature("editor"):
		audio.play()
