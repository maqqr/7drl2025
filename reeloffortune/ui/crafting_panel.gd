class_name CraftingPanel
extends Panel

var sprite: Sprite2D

func set_sprite_from_item(game_manager: GameManager, item: Item) -> void:
	if item:
		if !sprite:
			sprite = Sprite2D.new()
			sprite.scale = Vector2(2, 2)
			sprite.position = Vector2(40, 40)
			add_child(sprite)
		sprite.texture = item.item_type.sprite
		tooltip_text = item.make_tooltip(game_manager)
	else:
		if sprite:
			sprite.queue_free()

func _make_custom_tooltip(for_text):
	if for_text.is_empty():
		return null
	var tooltip = preload("res://ui/tooltip.tscn").instantiate()
	var rich_text = tooltip.get_node("RichTextLabel")
	rich_text.text = for_text
	return tooltip
