class_name ItemDragging
extends Control

class DragOperation:
	var item: Item
	var original_slot_sprite: Sprite2D
	var drag_sprite: Sprite2D

	func _init(p_item: Item, p_original_slot_sprite: Sprite2D):
		assert(p_item && p_original_slot_sprite)
		self.item = p_item
		self.original_slot_sprite = p_original_slot_sprite
		drag_sprite = Sprite2D.new()
		drag_sprite.texture = p_item.item_type.sprite
		drag_sprite.scale = Vector2(2.0, 2.0)
		drag_sprite.z_index = 1

	func start(parent: Control):
		if original_slot_sprite:
			original_slot_sprite.visible = false
		parent.add_child(drag_sprite)

	func cancel():
		if original_slot_sprite:
			original_slot_sprite.visible = true
		drag_sprite.queue_free()

	func stop():
		drag_sprite.queue_free()

@onready var game_manager: GameManager = $"/root/Game"
var drag_operation: DragOperation
var inventory: Inventory

var panel_providers = []

signal drag_pre_end(item: Item, success: bool)

func _ready() -> void:
	game_manager.game_manager_ready.connect(func (): set_inventory(game_manager.player_stats.inventory))

func _process(_delta: float) -> void:
	if drag_operation:
		var mouse_pos = get_viewport().get_mouse_position()
		drag_operation.drag_sprite.global_position = mouse_pos

		var target_panel = null
		var target_panel_provider = null
		for panel_provider in panel_providers:
			for panel in panel_provider.get_panels():
				if panel.get_rect().has_point(panel.get_parent().get_local_mouse_position()):
					target_panel = panel
					target_panel_provider = panel_provider

		if Input.is_action_just_released("click"):
			var success: bool = false
			if target_panel:
				success = target_panel_provider.drag_ended_on_panel(target_panel, drag_operation.item)
			else:
				# TODO: Drop signal
				if game_manager.allow_input_mode == GameManager.InputMode.ALLOWED: # This is a hack to prevent dropping items in shop
					var pos = game_manager.cursor_tile if game_manager.tilemap.is_walkable(game_manager.cursor_tile) and game_manager.cursor_tile.distance_squared_to(game_manager.player.map_position) <= game_manager.PICKUP_DIST_SQ else game_manager.player.map_position
					game_manager.create_ground_item(pos, drag_operation.item)
					inventory.remove_item(drag_operation.item)
					game_manager.player_stats.equipment.remove_item(drag_operation.item)
					game_manager.message_buffer.add_message(MessageBuffer.MSG_DROP.format({ "item": drag_operation.item.item_type.name }))
					success = true

			drag_pre_end.emit(target_panel, drag_operation.item, success)

			if success:
				drag_operation.stop()
			else:
				# Try to rescue a crafted item
				print("Item rescue")
				var not_equipped = !game_manager.player_stats.equipment.is_equipped(drag_operation.item)
				if not_equipped and drag_operation.item.inventory_slot == Inventory.INVALID_SLOT:
					game_manager.try_add_item(drag_operation.item)
				drag_operation.cancel()
			drag_operation = null

func start_drag(item: Item, original_slot_sprite: Sprite2D) -> void:
	if game_manager.allow_input_mode == GameManager.InputMode.NONE:
		return

	assert(!drag_operation)
	drag_operation = DragOperation.new(item, original_slot_sprite)
	drag_operation.start(self)

func set_inventory(p_inventory: Inventory) -> void:
	self.inventory = p_inventory
