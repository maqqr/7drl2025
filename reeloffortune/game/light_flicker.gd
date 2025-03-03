extends OmniLight3D

var time2 = 0
var time = 0
var noise = FastNoiseLite.new()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	time2 += delta
	time += delta * 200 + 10 * noise.get_noise_1d(time2 * 100)
	light_energy = 4 + 0.7 * sin(time * 0.05)
