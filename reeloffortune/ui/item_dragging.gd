class_name ItemDragging
extends Control

class DragOperation:
	var item: Item
	var original_slot_sprite: Sprite2D
	var drag_sprite: Sprite2D

	func _init(item: Item, original_slot_sprite: Sprite2D):
		assert(item && original_slot_sprite)
		self.item = item
		self.original_slot_sprite = original_slot_sprite
		drag_sprite = Sprite2D.new()
		drag_sprite.texture = item.item_type.sprite
		drag_sprite.scale = Vector2(2.0, 2.0)
		drag_sprite.z_index = 1

	func start(parent: Control):
		original_slot_sprite.visible = false
		parent.add_child(drag_sprite)

	func cancel():
		original_slot_sprite.visible = true
		drag_sprite.queue_free()

	func stop():
		drag_sprite.queue_free()

@onready var game_manager: GameManager = $"/root/Game"
var drag_operation: DragOperation
var inventory: Inventory

var panel_providers = []

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
				var pos = game_manager.cursor_tile if game_manager.tilemap.is_walkable(game_manager.cursor_tile) else game_manager.player.map_position
				game_manager.create_ground_item(pos, drag_operation.item)
				inventory.remove_item(drag_operation.item)
				success = true

			if success:
				drag_operation.stop()
			else:
				drag_operation.cancel()
			drag_operation = null

func start_drag(item: Item, original_slot_sprite: Sprite2D) -> void:
	assert(!drag_operation)
	drag_operation = DragOperation.new(item, original_slot_sprite)
	drag_operation.start(self)

func set_inventory(inventory: Inventory) -> void:
	self.inventory = inventory
