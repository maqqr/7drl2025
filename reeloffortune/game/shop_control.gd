class_name ShopControl
extends Control

@export var continue_button: Button
@export var sell_panel: SellSlotPanelContainer
@export var shop_items_container: VBoxContainer

@onready var game_manager: GameManager = $"/root/Game"
var inventory: Inventory
var equipment: Equipment
var item_dragging: ItemDragging

var offered_rod_types: Dictionary[Item.Quality, ItemType] = {}
var offered_boot_types: Dictionary[Item.Quality, ItemType] = {}

class SpecialItemType:
	var name

# Special items that are not actual items, like max stamina increase
class SpecialItem:
	var item_type: SpecialItemType
	var price: int
	var on_buy: Callable
	func _init(p_name: String, p_price: int, p_on_buy: Callable):
		self.item_type = SpecialItemType.new()
		self.item_type.name = p_name
		self.price = p_price
		self.on_buy = p_on_buy

	func get_buy_price() -> int:
		return price

	func get_value() -> int:
		return price

signal continue_pressed

func _ready():
	item_dragging = $"../ItemDragging"
	assert(item_dragging)
	item_dragging.panel_providers.append(self)
	continue_button.pressed.connect(func (): continue_pressed.emit())

	game_manager.game_manager_ready.connect(on_game_manager_ready)

func on_game_manager_ready():
	self.inventory = game_manager.player_stats.inventory
	self.equipment = game_manager.player_stats.equipment

	offered_rod_types[Item.Quality.TARNISHED] = game_manager.get_item_type_by_name("Common Rod")
	offered_rod_types[Item.Quality.COMMON] = game_manager.get_item_type_by_name("Fine Rod")
	offered_rod_types[Item.Quality.FINE] = game_manager.get_item_type_by_name("Premium Rod")
	
	offered_boot_types[Item.Quality.TARNISHED] = game_manager.get_item_type_by_name("Common Boots")
	offered_boot_types[Item.Quality.COMMON] = game_manager.get_item_type_by_name("Fine Boots")
	offered_boot_types[Item.Quality.FINE] = game_manager.get_item_type_by_name("Premium Boots")

func set_shop_visible(p_is_visible: bool) -> void:
	visible = p_is_visible
	global_position.x = 800 if visible else 3000

	if !visible:
		return

	MusicManager.play_music(MusicManager.Music.SHOP)

	# Clear old items
	for child in shop_items_container.get_children():
		child.free()
	
	# Randomize shop contents
	var items = []

	# Offer more stamina
	if game_manager.player_stats.max_stamina < game_manager.INITIAL_STAMINA + 20:
		items.append(SpecialItem.new("+10 Max Stamina", 10, func(): game_manager.player_stats.max_stamina += 10))

	# Offer larger inventory
	if game_manager.player_stats.inventory.size.x == 3:
		items.append(SpecialItem.new("+3 Inventory Slots", 20, func(): game_manager.player_stats.inventory.size.x += 1; game_manager.player_stats.inventory.inventory_size_changed.emit()))
	elif game_manager.player_stats.inventory.size.y == 3:
		items.append(SpecialItem.new("+4 Inventory Slots", 30, func(): game_manager.player_stats.inventory.size.y += 1; game_manager.player_stats.inventory.inventory_size_changed.emit()))

	# Offer better rod
	var current_rod: Item = null
	if game_manager.player_stats.equipment.slot.has(ItemAttributes.TypeFlag.ROD):
		current_rod = game_manager.player_stats.equipment.slot[ItemAttributes.TypeFlag.ROD]

	if !current_rod:
		var item = Item.new()
		item.item_type = game_manager.get_item_type_by_name("Basic Rod")
		item.quality = Item.Quality.TARNISHED
		items.append(item)
	elif offered_rod_types.has(current_rod.quality):
		var item = Item.new()
		item.item_type = offered_rod_types[current_rod.quality]
		match current_rod.quality:
			Item.Quality.TARNISHED: item.quality = Item.Quality.COMMON
			Item.Quality.COMMON: item.quality = Item.Quality.FINE
			Item.Quality.FINE: item.quality = Item.Quality.PREMIUM
		items.append(item)

	# Offer better boots
	var current_boots: Item = null
	if game_manager.player_stats.equipment.slot.has(ItemAttributes.TypeFlag.BOOTS):
		current_boots = game_manager.player_stats.equipment.slot[ItemAttributes.TypeFlag.BOOTS]

	if !current_boots:
		var item = Item.new()
		item.item_type = game_manager.get_item_type_by_name("Soggy Boots")
		item.quality = Item.Quality.TARNISHED
		items.append(item)
	elif offered_boot_types.has(current_boots.quality):
		var item = Item.new()
		item.item_type = offered_boot_types[current_boots.quality]
		match current_boots.quality:
			Item.Quality.TARNISHED: item.quality = Item.Quality.COMMON
			Item.Quality.COMMON: item.quality = Item.Quality.FINE
			Item.Quality.FINE: item.quality = Item.Quality.PREMIUM
		items.append(item)

	# Remove offers until three remain
	while items.size() > 3:
		items.remove_at(randi_range(0, items.size() - 1))

	# Fill extra space with random materials
	var potential_item_types = []
	for item_type in game_manager.item_types:
		if item_type.attributes.type_flag & ItemAttributes.TypeFlag.MATERIAL and !(item_type.attributes.type_flag & ItemAttributes.TypeFlag.FISH):
			if item_type.base_value > 0:
				potential_item_types.append(item_type)

	while items.size() < 3:
		var item = Item.new()
		item.item_type = potential_item_types[randi_range(0, potential_item_types.size() - 1)]
		item.quality = Item.Quality.COMMON
		items.append(item)

	for item in items:
		var item_control = preload("res://ui/shop_item_h_box_container.tscn").instantiate()
		shop_items_container.add_child(item_control)
		item_control.find_child("Button").pressed.connect(func (): buy_item(item_control, item))
		item_control.find_child("Button").text = str(item.get_buy_price())
		item_control.find_child("Label").text = item.item_type.name

func get_panels():
	return [sell_panel]

func drag_ended_on_panel(_target_panel: SellSlotPanelContainer, item: Item) -> bool:
	inventory.remove_item(item)
	equipment.remove_item(item)
	game_manager.player_stats.money += item.get_value()
	game_manager.message_buffer.add_message(MessageBuffer.MSG_SELL.format({ "item": item.item_type.name, "value": item.get_value() }))

	if item.item_type.is_legendary_fish:
		get_tree().change_scene_to_file("res://menu/winmenu.tscn")

	return true

func buy_item(shop_item_control: Control, item) -> void:
	var item_value = item.get_buy_price()
	if game_manager.player_stats.money < item_value:
		game_manager.message_buffer.add_message(MessageBuffer.MSG_BUY_FAIL_MONEY)
		return

	if item is Item:
		var slot = inventory.get_free_slot_for_item(item)
		if slot != Inventory.INVALID_SLOT:
			game_manager.message_buffer.add_message(MessageBuffer.MSG_BUY.format({ "item": item.item_type.name, "value": item_value }))
			game_manager.player_stats.money -= item_value
			inventory.add_item(slot, item)
			shop_item_control.queue_free()
		else:
			game_manager.message_buffer.add_message(MessageBuffer.MSG_BUY_FAIL_SPACE)
	elif item is SpecialItem:
		game_manager.player_stats.money -= item_value
		item.on_buy.call()
		shop_item_control.queue_free()
