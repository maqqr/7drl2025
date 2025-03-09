class_name Equipment
extends Resource

@export var slot: Dictionary[ItemAttributes.TypeFlag, Item] = {}

const SLOTS: Array[ItemAttributes.TypeFlag] = [ItemAttributes.TypeFlag.ROD, ItemAttributes.TypeFlag.BAIT, ItemAttributes.TypeFlag.BOOTS, ItemAttributes.TypeFlag.CLOTHING]

signal equipment_changed(type_flag: ItemAttributes.TypeFlag, item: Item)

func create_empty_slots():
	for s in SLOTS:
		slot[s] = null

func is_equipped(item: Item) -> bool:
	for s in SLOTS:
		if slot[s] == item:
			return true
	return false

func set_item_to_slot(type_flag: ItemAttributes.TypeFlag, item: Item):
	assert(SLOTS.find(type_flag) != -1)
	slot[type_flag] = item
	equipment_changed.emit(type_flag, item)

func remove_item(item: Item):
	for s in SLOTS:
		if slot[s] == item:
			equipment_changed.emit(s, item)
			slot[s] = null
