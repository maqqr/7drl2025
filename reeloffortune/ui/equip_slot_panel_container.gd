class_name EquipSlotPanelContainer
extends PanelContainer

@export var equip_flag: ItemAttributes.TypeFlag

var sprite: Sprite2D
var current_item: Item

var debug_label: Label

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
	
	#debug_label = Label.new()
	#debug_label.text = "asd"
	#$"/root/Game/GUI".add_child.call_deferred(debug_label)

func _process(_delta: float) -> void:
	if debug_label:
		debug_label.global_position = global_position
		debug_label.label_settings = LabelSettings.new()
		debug_label.label_settings.font_size = 9
		debug_label.text = "null"
		if current_item:
			debug_label.text = current_item.item_type.name

		var game_manager: GameManager = $"/root/Game"
		var slot = "null"
		if game_manager.player_stats.equipment.slot.has(equip_flag):
			var item = game_manager.player_stats.equipment.slot[equip_flag]
			if item:
				slot = item.item_type.name
		debug_label.text += "\n" + slot

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
