extends PanelContainer

class DragOperation:
	var item: Item
	var original_sprite: Sprite2D
	var drag_sprite: Sprite2D
	var target_panel: ItemPanel
	func _init(item: Item, original_sprite: Sprite2D):
		assert(item && original_sprite)
		self.item = item
		self.original_sprite = original_sprite
		drag_sprite = Sprite2D.new()
		drag_sprite.texture = item.item_type.sprite
		drag_sprite.scale = Vector2(2.0, 2.0)
		drag_sprite.z_index = 1

	func start(parent: Control):
		original_sprite.visible = false
		parent.add_child(drag_sprite)

	func stop():
		original_sprite.visible = true
		drag_sprite.queue_free()

@onready var game_manager: GameManager = $"/root/Game"
@onready var grid_container: Control = $"BackgroundGrid"
var slot_to_panel_dict: Dictionary[Vector2i, ItemPanel] = {}

var inventory: Inventory
var drag_operation: DragOperation
var item_sprite_container: Control
var item_sprite_dict: Dictionary[Item, Sprite2D] = {}
var need_refresh: bool

func _ready() -> void:
	item_sprite_container = Control.new()
	item_sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item_sprite_container)

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
				start_drag(item)

func start_drag(item: Item) -> void:
	assert(!drag_operation)
	drag_operation = DragOperation.new(item, item_sprite_dict[item])
	drag_operation.start(self)

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

	if drag_operation:
		var mouse_pos = get_viewport().get_mouse_position()
		drag_operation.drag_sprite.global_position = mouse_pos

		drag_operation.target_panel = null
		for panel: ItemPanel in grid_container.get_children():
			if panel.get_rect().has_point(get_local_mouse_position()):
				drag_operation.target_panel = panel

		if Input.is_action_just_released("click"):
			# Drop item to a slot
			if drag_operation.target_panel:
				var slot = drag_operation.target_panel.slot
				if drag_operation.item.item_type.item_size.x >= 3:
					slot.x -= 1
				if inventory.item_fits_in_slot(drag_operation.item, slot):
					drag_operation.item.inventory_slot = slot
			else:
				# TODO: Drop signal
				var pos = game_manager.cursor_tile if game_manager.tilemap.is_walkable(game_manager.cursor_tile) else game_manager.player.map_position
				game_manager.create_ground_item(pos, drag_operation.item)
				inventory.remove_item(drag_operation.item)
			drag_operation.stop()
			drag_operation = null
			inventory.inventory_changed.emit()
