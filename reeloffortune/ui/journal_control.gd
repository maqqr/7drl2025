class_name JournalControl
extends Control

@onready var game_manager: GameManager = $"/root/Game"

@export var button_container: Control
@export var fish_title_label: Label
@export var fish_description_label: RichTextLabel
@export var fish_sprite: Sprite2D

func _ready() -> void:
	assert(button_container and fish_title_label and fish_description_label and fish_sprite)
	game_manager.game_manager_ready.connect(on_game_manager_ready)

func on_game_manager_ready():
	set_open(false)

func fish_entry_sort(a: FishEntry, b: FishEntry):
	if a.item_type.is_legendary_fish or (a.is_known and !b.is_known):
		return true
	return false

func set_open(is_open: bool) -> void:
	visible = is_open

	for child in button_container.get_children():
		child.queue_free()

	var sorted_entries = game_manager.fish_entries
	sorted_entries.sort_custom(fish_entry_sort)

	for fish_entry in sorted_entries:
		var button = Button.new()
		button.text = fish_entry.item_type.name if fish_entry.is_known else "???"
		button.pressed.connect(func (): set_active_fish(fish_entry))
		button_container.add_child(button)

	set_active_fish(sorted_entries[0])

func make_list(attractions: Array[FishEntry.Attraction]) -> String:
	var result = ""
	for i in range(attractions.size()):
		if i > 0:
			result += ", "
		result += FishEntry.attraction_str(attractions[i])
	return result

func set_active_fish(fish_entry: FishEntry):
	fish_title_label.text = fish_entry.item_type.name if fish_entry.is_known else "???"
	fish_description_label.text = ""
	fish_sprite.texture = null
	if !fish_entry.is_known:
		return

	fish_sprite.texture = fish_entry.item_type.sprite

	var info = {
		"desc": fish_entry.description,
		"attr": make_list(fish_entry.attractions),
		"minor": "\nIt is slightly interested in:\n - " + make_list(fish_entry.minor_attractions) if !fish_entry.minor_attractions.is_empty() else "",
		"baitsize": "\nIt is hooked by baits that are " + ItemAttributes.size_str(fish_entry.get_max_bait_size()) + "-sized or smaller. Preferred size is " + ItemAttributes.size_str(fish_entry.get_preferred_bait_size()) + ".",
		"depth": "\n\nIt can be caught from depth " + str(max(1, fish_entry.min_depth)) + " or deeper."
	}
	var template = "[i]{desc}\n\nIt is attracted to:\n - {attr}{minor}{baitsize}{depth}[/i]"
	fish_description_label.text = template.format(info)
