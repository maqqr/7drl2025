extends Control

func _make_custom_tooltip(for_text):
	var tooltip = preload("res://ui/tooltip.tscn").instantiate()
	var rich_text = tooltip.get_node("RichTextLabel")
	rich_text.text = for_text
	return tooltip
