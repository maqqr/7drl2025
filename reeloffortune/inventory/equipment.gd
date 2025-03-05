class_name Equipment
extends Resource

@export var slot: Dictionary[ItemAttributes.TypeFlag, Item] = {}

const SLOTS: Array[ItemAttributes.TypeFlag] = [ItemAttributes.TypeFlag.ROD, ItemAttributes.TypeFlag.BAIT, ItemAttributes.TypeFlag.BOOTS, ItemAttributes.TypeFlag.CLOTHING]

func create_empty_slots():
	for s in SLOTS:
		slot[s] = null

func is_equipped(item: Item) -> bool:
	for s in SLOTS:
		if slot[s] == item:
			return true
	return false
