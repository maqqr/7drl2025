class_name ItemPanel
extends Panel

@export var slot: Vector2i

func _init(slot: Vector2i):
	custom_minimum_size = Vector2i(80.0, 80.0)
	self.slot = slot

func _make_custom_tooltip(for_text):
	if for_text.is_empty():
		return null
	var tooltip = preload("res://ui/tooltip.tscn").instantiate()
	var rich_text = tooltip.get_node("RichTextLabel")
	rich_text.text = for_text
	return tooltip
