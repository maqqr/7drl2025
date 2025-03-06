extends PanelContainer

@onready var game_manager: GameManager = $"/root/Game"
var inventory: Inventory
var equipment: Equipment
var item_dragging: ItemDragging

@export var equip_panels: Array[EquipSlotPanelContainer] = []
@export var stamina_label: Label
@export var money_label: Label
@export var depth_label: Label

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
	game_manager.player.stamina_changed.connect(func (old_value, new_value): update_labels())
	update_labels()

func update_labels():
	stamina_label.text = "Stamina: " + str(game_manager.player.stamina) + "/" + str(game_manager.player.stats.max_stamina)

func on_equip_panel_gui_input(equip_panel: EquipSlotPanelContainer, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			if equip_panel.current_item:
				item_dragging.start_drag(equip_panel.current_item, equip_panel.sprite)

func get_panels():
	return equip_panels

func drag_ended_on_panel(target_panel: EquipSlotPanelContainer, item: Item) -> bool:
	if target_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE and !(item.item_type.attributes.type_flag & ItemAttributes.TypeFlag.CONSUMABLE):
		game_manager.message_buffer.add_message(MessageBuffer.MSG_EAT_FAIL)

	if item.item_type.attributes.type_flag & target_panel.equip_flag:
		inventory.remove_item(item)
		if target_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE:
			game_manager.message_buffer.add_message(MessageBuffer.MSG_EAT.format({ "item": item.item_type.name, "msg": item.item_type.eat_msg }))
			game_manager.player.set_stamina(game_manager.player.stamina + item.item_type.stamina_gain)
			return true

		game_manager.player_stats.equipment.slot[target_panel.equip_flag] = item
		target_panel.set_item(game_manager, item)
		
		if target_panel.equip_flag & ItemAttributes.TypeFlag.ROD:
			game_manager.set_player_unarmed(false)
		return true
	return false

func on_drag_pre_end(target_panel, item: Item, success: bool) -> void:
	if success:
		for equip_panel in equip_panels:
			if target_panel != equip_panel and equip_panel.current_item == item:
				equip_panel.set_item(game_manager, null)
				if equip_panel.equip_flag & ItemAttributes.TypeFlag.ROD:
					game_manager.set_player_unarmed(true)

func on_equipment_changed(type_flag: ItemAttributes.TypeFlag, item: Item) -> void:
	for equip_panel in equip_panels:
		if equip_panel.equip_flag == type_flag:
			equip_panel.set_item(game_manager, item)
			break
