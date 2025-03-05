class_name EquipSlotPanelContainer
extends PanelContainer

@export var equip_flag: ItemAttributes.TypeFlag

var sprite: Sprite2D
var current_item: Item

func _ready() -> void:
	if equip_flag & ItemAttributes.TypeFlag.ROD:
		custom_minimum_size.x *= 3
	
	var text = ""
	if equip_flag & ItemAttributes.TypeFlag.CONSUMABLE:
		text = "Eat"
	else:
		var tags: PackedStringArray = ItemAttributes.type_str(equip_flag)
		assert(tags.size() == 1)
		text = tags[0].capitalize().substr(0, 5)
	$RichTextLabel.text = "[i]" + text + "[/i]"

func set_item(game_manager: GameManager, item: Item) -> void:
	current_item = item
	if item:
		$RichTextLabel.visible = false
		if !sprite:
			sprite = Sprite2D.new()
			sprite.scale = Vector2(2, 2)
			sprite.position = Vector2(80 * item.item_type.item_size.x, 80) * 0.5
			add_child(sprite)
		sprite.texture = item.item_type.sprite
		sprite.visible = true
		tooltip_text = item.make_tooltip(game_manager)
	else:
		$RichTextLabel.visible = true
		if sprite:
			sprite.queue_free()

func _make_custom_tooltip(for_text):
	if for_text.is_empty():
		return null
	var tooltip = preload("res://ui/tooltip.tscn").instantiate()
	var rich_text = tooltip.get_node("RichTextLabel")
	rich_text.text = for_text
	return tooltip
