extends PanelContainer

@onready var game_manager: GameManager = $"/root/Game"
var inventory: Inventory
var item_dragging: ItemDragging

@export var equip_panels: Array[EquipSlotPanelContainer] = []

func _ready() -> void:
	item_dragging = $"../ItemDragging"
	assert(item_dragging)
	item_dragging.panel_providers.append(self)
	item_dragging.drag_pre_end.connect(on_drag_pre_end)

	assert(!equip_panels.is_empty())
	for panel in equip_panels:
		panel.gui_input.connect(func (e): on_equip_panel_gui_input(panel, e))

	game_manager.game_manager_ready.connect(func (): set_inventory(game_manager.player_stats.inventory))

func set_inventory(inventory: Inventory):
	self.inventory = inventory

func on_equip_panel_gui_input(equip_panel: EquipSlotPanelContainer, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			if equip_panel.current_item:
				item_dragging.start_drag(equip_panel.current_item, equip_panel.sprite)

func get_panels():
	return equip_panels

func drag_ended_on_panel(target_panel: EquipSlotPanelContainer, item: Item) -> bool:
	if item.item_type.attributes.type_flag & target_panel.equip_flag:
		inventory.remove_item(item)
		if target_panel.equip_flag & ItemAttributes.TypeFlag.CONSUMABLE:
			print("TODO Consume")
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
