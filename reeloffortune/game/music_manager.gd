extends Node

var audio: AudioStreamPlayer

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	add_child(audio)
	
	audio.stream = preload("res://audio/music/menu.ogg")
	#audio.play()
