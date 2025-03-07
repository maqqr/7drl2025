class_name Inventory
extends Resource

const INVALID_SLOT = Vector2i(-1, -1)

@export var items: Array[Item] = []
@export var size: Vector2i = Vector2i(4, 4)

signal inventory_changed
signal inventory_size_changed

func is_slot_empty(slot: Vector2i) -> bool:
	for item in items:
		if Rect2i(item.inventory_slot, item.item_type.item_size).has_point(slot):
			return false
	return true

func item_fits_in_slot(item: Item, slot: Vector2i) -> bool:
	var rect = Rect2i(slot, item.item_type.item_size)
	for inv_item in items:
		if Rect2i(inv_item.inventory_slot, inv_item.item_type.item_size).intersects(rect):
			return false
	return Rect2i(Vector2i(0, 0), size).encloses(rect)

func get_free_slot_for_item(item: Item) -> Vector2i:
	for y in size.x:
		for x in size.y:
			var slot = Vector2i(x, y)
			if item_fits_in_slot(item, slot):
				return slot
	return INVALID_SLOT

func get_item_at_slot(slot: Vector2i) -> Item:
	for item in items:
		if Rect2i(item.inventory_slot, item.item_type.item_size).has_point(slot):
			return item
	return null

func add_item(slot: Vector2i, item: Item) -> void:
	assert(item_fits_in_slot(item, slot))
	item.inventory_slot = slot
	items.append(item)
	inventory_changed.emit()

func remove_item_from_slot(slot: Vector2i) -> bool:
	for item in items:
		if item.inventory_slot == slot:
			items.erase(item)
			inventory_changed.emit()
			return true
	return false

func remove_item(item: Item) -> void:
	items.erase(item)
	item.inventory_slot = Inventory.INVALID_SLOT
	inventory_changed.emit()
