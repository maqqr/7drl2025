class_name CraftingControl
extends Control

var x_open: float
var x_close: float

@onready var game_manager: GameManager = $"/root/Game"
var inventory: Inventory
var item_dragging: ItemDragging

@export var material1_panel: CraftingPanel
@export var material2_panel: CraftingPanel
@export var result_panel: CraftingPanel
@export var break_panel: CraftingPanel

var material1: Item
var material2: Item
var result: Item

const RANDOM_EAT_MSGS = [
	"Sweet? Fishy? Is that... metal? You're unsure.",
	"It tastes... indescribable.",
	"It tingles, then numbs. What was that flavor?",
	"A subtle spice, then a slick chill.",
	"Fruity, then... earthy? Your senses are confused.",
	"It pulses slightly. Is it alive? You can't tell.",
	"A faint glow, a metallic tang. You're perplexed.",
	"Sweet, then bitter, then... nothing? You feel disoriented.",
	"A strange texture, a shifting taste. You feel wary.",
]

func _ready() -> void:
	x_close = global_position.x
	x_open = x_close - $PanelContainer.get_rect().size.x

	item_dragging = $"../ItemDragging"
	assert(item_dragging)
	item_dragging.panel_providers.append(self)

	result_panel.gui_input.connect(on_result_panel_gui_input)
	game_manager.game_manager_ready.connect(func (): set_inventory(game_manager.player_stats.inventory))

func set_open(is_open: bool) -> void:
	var target_pos = Vector2(x_open, 0.0) if is_open else Vector2(x_close, 0.0)
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT)

func get_panels():
	return [material1_panel, material2_panel, result_panel, break_panel]

func drag_ended_on_panel(target_panel: CraftingPanel, item: Item) -> bool:
	if inventory.items.find(item) == -1:
		return false

	if target_panel == material1_panel or target_panel == material2_panel:
		if !(item.item_type.attributes.type_flag & ItemAttributes.TypeFlag.MATERIAL):
			game_manager.message_buffer.add_message(MessageBuffer.MSG_IS_NOT_MAT.format({ "item": item.item_type.name }))
			return false

		target_panel.set_sprite_from_item(game_manager, item)
		if target_panel == material1_panel:
			material1 = item
			if item == material2:
				material2 = null
				material2_panel.set_sprite_from_item(game_manager, null)
		if target_panel == material2_panel:
			material2 = item
			if item == material1:
				material1 = null
				material1_panel.set_sprite_from_item(game_manager, null)

		# Create crafted item result and preview
		if material1 and material2:
			result = combine(material1, material2)
			result_panel.set_sprite_from_item(game_manager, result)

	if target_panel == break_panel:
		if !item.item_type.breakdown.is_empty():
			var old_slot = item.inventory_slot
			inventory.remove_item(item)
			var new_item = breakdown(item)
			inventory.add_item(old_slot, new_item)
			return true

	return false

func on_result_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			if result:
				item_dragging.start_drag(result, result_panel.sprite)
				for item in [material1, material2]:
					inventory.remove_item(item)

func set_inventory(inventory: Inventory) -> void:
	self.inventory = inventory
	inventory.inventory_changed.connect(on_inventory_change)
	on_inventory_change()

func on_inventory_change() -> void:
	material1 = null
	material2 = null
	material1_panel.set_sprite_from_item(game_manager, null)
	material2_panel.set_sprite_from_item(game_manager, null)
	result = null
	result_panel.set_sprite_from_item(game_manager, null)

func breakdown(item: Item) -> Item:
	var index = randi_range(0, item.item_type.breakdown.size() - 1)
	var new_item_type = item.item_type.breakdown[index]

	if !game_manager.player_stats.breakdown_knowledge.has(item.item_type):
		game_manager.player_stats.breakdown_knowledge[item.item_type] = []

	if game_manager.player_stats.breakdown_knowledge[item.item_type].find(new_item_type) == -1:
		game_manager.player_stats.breakdown_knowledge[item.item_type].append(new_item_type)
		game_manager.message_buffer.add_message(MessageBuffer.MSG_LEARN.format({ "item": item.item_type.name, "result": new_item_type.name }))

	var new_item = Item.new()
	new_item.item_type = new_item_type
	new_item.quality = item.quality
	new_item.inventory_slot = item.inventory_slot

	if new_item.item_type.attributes.type_flag & ItemAttributes.TypeFlag.BAIT:
		match new_item.quality:
			Item.Quality.FINE: new_item.bait_uses_left = 1
			Item.Quality.PREMIUM: new_item.bait_uses_left = 2

	return new_item

func combine(item1: Item, item2: Item) -> Item:
	result = Item.new()
	result.quality = max(material1.quality, material2.quality)
	result.is_crafted = true
	
	# Create new custom item type
	result.item_type = ItemType.new()
	result.item_type.name = "Crafted Bait"
	result.item_type.base_value = int((material1.item_type.base_value + material2.item_type.base_value) * 0.5)
	result.item_type.item_size = Vector2i(1, 1)
	result.item_type.attributes = ItemAttributes.new()
	result.item_type.sprite = preload("res://sprites/bait.png")
	result.item_type.stamina_gain = material1.item_type.stamina_gain + material2.item_type.stamina_gain
	result.item_type.eat_msg = RANDOM_EAT_MSGS[randi_range(0, RANDOM_EAT_MSGS.size() - 1)]

	var attr = result.item_type.attributes

	# Determine attributes
	attr.type_flag = item1.item_type.attributes.type_flag | item2.item_type.attributes.type_flag
	attr.size = max(item1.item_type.attributes.size, item2.item_type.attributes.size)
	attr.attraction_flag = item1.item_type.attributes.attraction_flag | item2.item_type.attributes.attraction_flag
	attr.color = ItemAttributes.color_mix(item1.item_type.attributes.color, item2.item_type.attributes.color)
	attr.stickyness = ItemAttributes.stickyness_mix(item1.item_type.attributes.stickyness, item2.item_type.attributes.stickyness)
	attr.sharpness = ItemAttributes.sharpness_mix(item1.item_type.attributes.sharpness, item2.item_type.attributes.sharpness)
	attr.temperature = ItemAttributes.temperature_mix(item1.item_type.attributes.temperature, item2.item_type.attributes.temperature)

	# Always add bait and remove fish and material attribute
	attr.type_flag |= ItemAttributes.TypeFlag.BAIT
	attr.type_flag &= ~ItemAttributes.TypeFlag.FISH
	attr.type_flag &= ~ItemAttributes.TypeFlag.MATERIAL

	if attr.type_flag & ItemAttributes.TypeFlag.BAIT:
		match result.quality:
			Item.Quality.FINE: result.bait_uses_left = 1
			Item.Quality.PREMIUM: result.bait_uses_left = 2

	result.inventory_slot = Inventory.INVALID_SLOT
	return result
