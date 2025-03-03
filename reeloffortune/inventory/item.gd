class_name Item
extends Resource

enum Quality {
	TARNISHED, COMMON, FINE, PREMIUM
}
func quality_str(q: Quality) -> String:
	match q:
		Quality.TARNISHED: return "tarnished"
		Quality.COMMON: return "common"
		Quality.FINE: return "fine"
		Quality.PREMIUM: return "premium"
	return ""

@export var item_type: ItemType
@export var quality: Quality
@export var is_crafted: bool
@export var inventory_slot: Vector2i

func make_tooltip():
	var tags: PackedStringArray = ItemAttributes.type_str(item_type.attributes.type_flag)
	var add_if_not_empty = func (t): if not t.is_empty(): tags.append(t)
	add_if_not_empty.call(ItemAttributes.attraction_str(item_type.attributes.attraction))
	add_if_not_empty.call(ItemAttributes.color_str(item_type.attributes.color))
	add_if_not_empty.call(ItemAttributes.texture_str(item_type.attributes.texture))
	add_if_not_empty.call(ItemAttributes.temperature_str(item_type.attributes.temperature))
	var info = {
		"name": item_type.name,
		"qual": quality_str(quality),
		"craf": "\nIt is crafted by you." if is_crafted else "",
		"size": ItemAttributes.size_str(item_type.attributes.size),
		"tags": ", ".join(tags),
	}
	return "[b]{name}[/b]\nIt is {qual} quality.{craf}\nIt is {size} size.\n({tags})".format(info)
