extends Sprite2D

var rise_speed: float
var phase: float
var time: float

func _ready() -> void:
	phase = randf()
	rise_speed = randf_range(-8, -32)

func _process(delta: float):
	time += delta
	position.x += 20 * sin(time + phase) * delta
	position.y += rise_speed * delta
