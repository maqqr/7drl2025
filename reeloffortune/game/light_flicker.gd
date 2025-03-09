extends OmniLight3D

var time2 = 0
var time = 0
var noise = FastNoiseLite.new()
var phase = 0

@export var energy_multiplier = 1.0
@export var flicker_mesh: Node3D

func _ready() -> void:
	phase = randf() * 100

func _process(delta: float) -> void:
	time2 += delta
	time += delta * 200 + 10 * noise.get_noise_1d(time2 * 100 + phase)
	light_energy = energy_multiplier * (4 + 0.7 * sin(time * 0.05 + phase))

	if flicker_mesh:
		var s = light_energy
		flicker_mesh.scale = Vector3(s, s, s)
