extends PanelContainer

@onready var game_manager: GameManager = $"/root/Game"
@onready var grid_container: Control = $"BackgroundGrid"
var slot_to_panel_dict: Dictionary[Vector2i, ItemPanel] = {}

var inventory: Inventory
var item_sprite_container: Control
var item_sprite_dict: Dictionary[Item, Sprite2D] = {}
var need_refresh: bool
var item_dragging: ItemDragging

func _ready() -> void:
	item_sprite_container = Control.new()
	item_sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item_sprite_container)
	
	item_dragging = $"../../ItemDragging"
	assert(item_dragging)
	item_dragging.panel_providers.append(self)

func get_panels():
	return grid_container.get_children()

func drag_ended_on_panel(target_panel: ItemPanel, item: Item) -> bool:
	var slot = target_panel.slot
	if item.item_type.item_size.x >= 3:
		slot.x -= 1
	
	if inventory.items.find(item) != -1:
		if inventory.item_fits_in_slot(item, slot):
			item.inventory_slot = slot
			inventory.inventory_changed.emit()
			return true
		return false
	else:
		if !inventory.item_fits_in_slot(item, slot):
			slot = inventory.get_free_slot_for_item(item)

		if slot != Inventory.INVALID_SLOT:
			inventory.add_item(slot, item)
		return true

func set_inventory(inventory: Inventory) -> void:
	self.inventory = inventory
	inventory.inventory_changed.connect(on_inventory_change)
	on_inventory_size_change()
	on_inventory_change()

func on_inventory_size_change() -> void:
	custom_minimum_size = Vector2(Vector2i(80.0, 80.0) * inventory.size) + Vector2(24.0, 24.0)

	slot_to_panel_dict.clear()
	for child in grid_container.get_children():
		child.free()

	for y in inventory.size.y:
		for x in inventory.size.x:
			var slot = Vector2i(x, y)
			var panel = ItemPanel.new(slot)
			panel.position = Vector2(slot * Vector2i(80.0, 80.0))
			panel.theme_type_variation = "PanelSimple"
			panel.modulate = Color(0.3, 0.3, 0.3)
			panel.gui_input.connect(func (e): on_panel_gui_input(panel, e))
			grid_container.add_child(panel)
			slot_to_panel_dict[slot] = panel

func on_inventory_change() -> void:
	need_refresh = true

func on_panel_gui_input(panel: ItemPanel, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			var item = inventory.get_item_at_slot(panel.slot)
			if item:
				item_dragging.start_drag(item, item_sprite_dict[item])

func _process(delta: float) -> void:
	if need_refresh:
		need_refresh = false

		# Clear old items
		item_sprite_dict.clear()
		for child in item_sprite_container.get_children():
			child.free()

		# Clear tooltips
		for child: ItemPanel in grid_container.get_children():
			child.tooltip_text = ""

		for item: Item in inventory.items:
			var sprite = Sprite2D.new()
			sprite.texture = item.item_type.sprite
			sprite.offset = (Vector2i(40.0, 40.0) * item.item_type.item_size) / 2.0
			sprite.position = Vector2(Vector2i(80.0, 80.0) * item.inventory_slot)
			sprite.scale = Vector2i(2.0, 2.0)
			item_sprite_container.add_child(sprite)
			item_sprite_dict[item] = sprite
			for dx in item.item_type.item_size.x:
				for dy in item.item_type.item_size.y:
					slot_to_panel_dict[item.inventory_slot + Vector2i(dx, dy)].tooltip_text = item.make_tooltip(game_manager)
