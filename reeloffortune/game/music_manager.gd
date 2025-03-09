extends Node

var audio: AudioStreamPlayer

enum Music {
	MENU,
	GAME,
	SHOP,
	END,
}

var muted: bool = false

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	add_child(audio)

func play_music(m: Music):
	match m:
		Music.GAME: audio.stream = preload("res://audio/music/land_with_no_dragons.ogg")
		Music.SHOP: audio.stream = preload("res://audio/music/sealed.ogg")
		Music.MENU, Music.END:
			audio.stop()
			return

	audio.volume_linear = 0.6
	if not OS.has_feature("editor"):
		audio.play()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("mute"):
		muted = !muted
		audio.volume_linear = 0.0 if muted else 0.6
