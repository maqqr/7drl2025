extends PanelContainer

@onready var game_manager: GameManager = $"/root/Game"
var inventory: Inventory
var equipment: Equipment
var item_dragging: ItemDragging

@export var equip_panels: Array[EquipSlotPanelContainer] = []
@export var stamina_label: RichTextLabel
@export var money_label: RichTextLabel
@export var depth_label: RichTextLabel

func _ready() -> void:
	item_dragging = $"../ItemDragging"
	assert(item_dragging)
	item_dragging.panel_providers.append(self)
	item_dragging.drag_pre_end.connect(on_drag_pre_end)

	assert(!equip_panels.is_empty())
	for panel in equip_panels:
		panel.gui_input.connect(func (e): on_equip_panel_gui_input(panel, e))

	assert(stamina_label and money_label and depth_label)

	game_manager.game_manager_ready.connect(on_game_manager_ready)

func on_game_manager_ready():
	self.inventory = game_manager.player_stats.inventory
	self.equipment = game_manager.player_stats.equipment
	self.equipment.equipment_changed.connect(on_equipment_changed)
	game_manager.player_stats.stats_changed.connect(update_labels)
	update_labels()

func update_labels():
	var stam_color = Color.WHITE
	if game_manager.player_stats.stamina <= game_manager.player_stats.max_stamina * 0.5:
		stam_color = Color.YELLOW
	if game_manager.player_stats.stamina <= game_manager.player_stats.max_stamina * 0.25:
		stam_color = Color.RED
	stamina_label.text = "[color=#" + stam_color.to_html(false) + "]Stamina: " + str(game_manager.player_stats.stamina) + "/" + str(game_manager.player_stats.max_stamina) + "[/color]"
	money_label.text = "Money: " + str(game_manager.player_stats.money) + " [img=24]res://icons/coin.png[/img]"
	depth_label.text = "Depth: " + str(game_manager.depth)

func on_equip_panel_gui_input(equip_panel: EquipSlotPanelContainer, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			if equip_panel.current_item:
				item_dragging.start_drag(equip_panel.current_item, equip_panel.sprite)
			else:
				var action = "consume" if equip_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE else "equip"
				game_manager.message_buffer.add_message(MessageBuffer.MSG_EQUIP_HELP.format({ "action": action }))

func get_panels():
	return equip_panels

func drag_ended_on_panel(target_panel: EquipSlotPanelContainer, item: Item) -> bool:
	if target_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE and !(item.item_type.attributes.type_flag & ItemAttributes.TypeFlag.CONSUMABLE):
		game_manager.message_buffer.add_message(MessageBuffer.MSG_EAT_FAIL)
		return false

	if item.item_type.attributes.type_flag & target_panel.equip_flag:
		var previous_slot = item.inventory_slot
		var previously_equipped = null
		if game_manager.player_stats.equipment.slot.has(target_panel.equip_flag):
			previously_equipped = game_manager.player_stats.equipment.slot[target_panel.equip_flag]

		inventory.remove_item(item)
		if target_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE:
			game_manager.message_buffer.add_message(MessageBuffer.MSG_EAT.format({ "item": item.item_type.name, "msg": item.item_type.eat_msg }))
			game_manager.player_stats.stamina += item.get_stamina_restore_amount()
			return true

		game_manager.player_stats.equipment.slot[target_panel.equip_flag] = item
		target_panel.set_item(game_manager, item)

		if previously_equipped and previously_equipped != item:
			if previous_slot != Inventory.INVALID_SLOT:
				inventory.add_item(previous_slot, previously_equipped)
			else:
				game_manager.create_ground_item(game_manager.player.map_position, previously_equipped)

		if target_panel.equip_flag & ItemAttributes.TypeFlag.ROD:
			game_manager.set_player_unarmed(false)
		return true
	else:
		var tags: PackedStringArray = ItemAttributes.type_str(target_panel.equip_flag)
		assert(tags.size() == 1)
		var type_name: String = tags[0]
		game_manager.message_buffer.add_message(MessageBuffer.MSG_WRONG_TYPE.format({ "item": item.item_type.name, "type": type_name }))
	return false

func on_drag_pre_end(target_panel, item: Item, success: bool) -> void:
	if success:
		for equip_panel in equip_panels:
			if target_panel != equip_panel and equip_panel.current_item == item:
				game_manager.player_stats.equipment.slot[equip_panel.equip_flag] = null
				equip_panel.set_item(game_manager, null)
				if equip_panel.equip_flag & ItemAttributes.TypeFlag.ROD:
					game_manager.set_player_unarmed(true)

func on_equipment_changed(type_flag: ItemAttributes.TypeFlag, item: Item) -> void:
	for equip_panel in equip_panels:
		if equip_panel.equip_flag == type_flag:
			equip_panel.set_item(game_manager, item)
			break
