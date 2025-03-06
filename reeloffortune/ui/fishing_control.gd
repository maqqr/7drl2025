extends Control

var difficulty = 1.0

var time = 0.0

@export var fish_position = 0.5
var fish_velocity = 0.0
var fish_target_velocity = 0.0
var fish_next_change = 0.0
var fish_stamina = 5.0

@export var bar_position = 1.0
var bar_width = 80.0
var bar_speed = 0.7
var bar_original_height = 20.0
var bar_height = bar_original_height

var fish_sprite: Sprite2D
var fish_offset_y = 0.0
var fish_target_offset_y = 0.0
var progress_container: Control
var bar_control: Control
var line: Line2D

signal fishing_ended(success: bool)

func setup(rod_strength: float, fish_entry: FishEntry) -> void:
	difficulty = fish_entry.strength / rod_strength
	print("Difficulty ", difficulty)
	fish_sprite.texture = fish_entry.item_type.sprite

func _ready() -> void:
	progress_container = find_child("ProgressPanelContainer")
	fish_sprite = find_child("FishSprite")
	bar_control = find_child("GreenPanel")
	line = find_child("Line2D")
	assert(progress_container and fish_sprite and bar_control and line)
	bar_control.size.x = bar_width

	line.points[0] = Vector2(-64.0, 16.0)

func _process(delta: float) -> void:
	time += delta
	var reel_pressed = Input.is_action_pressed("reel")
	if reel_pressed:
		bar_position -= bar_speed * 0.66 * delta
	else:
		bar_position += bar_speed * delta

	bar_position = clamp(bar_position, 0.0, 1.0)

	# Change behaviour at random intervals
	if time >= fish_next_change:
		fish_next_change = time + 0.1 + randf()
		fish_target_velocity = -0.1 + 0.5 * randf()
		
		# Random burst of speed
		if fish_stamina > 0.0 and fish_position < 0.3 and randf() < 0.5:
			fish_target_velocity += 0.5

	fish_velocity += (fish_target_velocity - fish_velocity) * 2.0 * delta

	var pull_velocity = 0.0
	if fish_sprite.global_position.x >= bar_control.global_position.x and fish_sprite.global_position.x <= bar_control.global_position.x + bar_control.get_rect().size.x:
		fish_velocity -= 0.1 * delta
		fish_target_offset_y = 4.0
		
		bar_height = bar_original_height + 4.0

		if reel_pressed:
			fish_velocity -= 0.2 * delta
			fish_target_offset_y = 15.0
			fish_position -= 0.05 * delta
			pull_velocity = -0.1
			fish_stamina = max(0.0, fish_stamina - delta)
	else:
		fish_target_offset_y = 0.0
		bar_height = bar_original_height

	fish_offset_y += (fish_target_offset_y - fish_offset_y) * 4.0 * delta

	var fish_vel_mult = 0.9 if reel_pressed else 1.0

	fish_position += (fish_velocity * fish_vel_mult + pull_velocity) * delta

	if fish_position >= 1.0 or fish_position <= 0.0:
		finish(fish_position <= 0.0)

	update_visuals()

func update_visuals() -> void:
	fish_sprite.global_position.y = fish_offset_y + fish_sprite.get_parent().global_position.y + fish_sprite.get_parent().get_rect().size.y * 0.5
	fish_sprite.global_position.x = progress_container.global_position.x + progress_container.size.x * fish_position

	bar_control.size.y = bar_height
	bar_control.global_position.x = progress_container.global_position.x + (progress_container.get_rect().size.x - bar_width) * bar_position
	bar_control.global_position.y = progress_container.global_position.y + 5.0 - bar_height * 0.5

	line.points[1] = fish_sprite.position

func finish(success: bool) -> void:
	fishing_ended.emit(success)
	self.queue_free()
