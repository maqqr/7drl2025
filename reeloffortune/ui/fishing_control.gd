extends Control

var difficulty = 1.0

var time = 0.0

@export var help_text: Label
var show_fish_stamina: bool = false

@export var fish_position = 0.5
var fish_velocity = 0.0
var fish_target_velocity = 0.0
var fish_next_change = 0.0
var fish_stamina = 5.0
var fish_initial_stamina = 5.0

@export var bar_position = 1.0
var bar_width = 80.0
var bar_speed = 0.7
var bar_original_height = 20.0
var bar_height = bar_original_height

var current_fish_entry: FishEntry
var fish_sprite: Sprite2D
var fish_offset_y = 0.0
var fish_target_offset_y = 0.0
var progress_container: Control
var bar_control: Control
var line: Line2D

signal fishing_ended(success: bool)

func setup(rod_strength: float, fish_entry: FishEntry) -> void:
	current_fish_entry = fish_entry
	difficulty = fish_entry.strength / rod_strength
	print(rod_strength, " vs. ", fish_entry.strength, ", difficulty ", difficulty)
	fish_sprite.texture = fish_entry.item_type.sprite
	fish_initial_stamina = fish_entry.stamina
	fish_stamina = fish_initial_stamina

	bar_control.self_modulate = Color.GREEN_YELLOW
	if difficulty >= 0.8:
		bar_control.self_modulate = Color.YELLOW
	if difficulty > 1.2:
		bar_control.self_modulate = Color.ORANGE_RED

func _ready() -> void:
	progress_container = find_child("ProgressPanelContainer")
	fish_sprite = find_child("FishSprite")
	bar_control = find_child("GreenPanel")
	line = find_child("Line2D")
	assert(progress_container and fish_sprite and bar_control and line)
	bar_control.size.x = bar_width

	line.points[0] = Vector2(-64.0, 16.0)

	const FADE_COLORS = [Color(0.7, 0.7, 0.7), Color(0.4, 0.4, 0.4), Color(0.1, 0.1, 0.1)]

	const FADE_DELAY = 0.07
	var tween = get_tree().create_tween()
	tween.tween_interval(3)
	# Fade out
	for col in FADE_COLORS:
		tween.tween_property(help_text, "self_modulate", col, 0.0)
		tween.tween_interval(FADE_DELAY)
	tween.tween_property(help_text, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), 0.0)
	tween.tween_interval(0.1)
	tween.tween_callback(func (): show_fish_stamina = true)
	# Fade in
	for i in range(FADE_COLORS.size() - 1, -1, -1):
		tween.tween_property(help_text, "self_modulate", FADE_COLORS[i], 0.0)
		tween.tween_interval(FADE_DELAY)
	tween.tween_property(help_text, "self_modulate", Color(1.0, 1.0, 1.0), 0.0)

func _process(delta: float) -> void:
	time += delta

	if show_fish_stamina:
		help_text.text = "Fish stamina: " + str(int(100 * (fish_stamina / fish_initial_stamina))) + "%"

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
			fish_target_velocity += 0.2 + 0.3 * difficulty
			fish_stamina = max(0.0, fish_stamina - fish_initial_stamina * 0.05)
			create_bubbles()

	fish_velocity += (fish_target_velocity - fish_velocity) * 2.0 * delta

	var pull_velocity = 0.0
	if fish_sprite.global_position.x >= bar_control.global_position.x and fish_sprite.global_position.x <= bar_control.global_position.x + bar_control.get_rect().size.x:
		fish_velocity -= 0.1 * delta
		fish_target_offset_y = 4.0
		
		bar_height = bar_original_height + 4.0

		if reel_pressed:
			fish_velocity -= max(0, (0.2 + 0.2 * (1.0 - difficulty)) * delta)
			fish_target_offset_y = 15.0
			fish_position -= (0.1 + 0.03 * (1.0 - difficulty)) * delta
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

func create_bubbles() -> void:
	for i in randi_range(1, 3):
		var bubble = preload("res://ui/bubble_sprite.tscn").instantiate()
		fish_sprite.get_parent().add_child(bubble)
		#fish_sprite.get_parent().move_child(bubble, 0)
		bubble.global_position = fish_sprite.global_position + Vector2((current_fish_entry.item_type.item_size.x * 40) / 3.0, 0.0)

func finish(success: bool) -> void:
	fishing_ended.emit(success)
	self.queue_free()
