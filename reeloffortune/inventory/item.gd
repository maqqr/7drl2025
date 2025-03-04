class_name Item
extends Resource

enum Quality {
	TARNISHED, COMMON, FINE, PREMIUM
}
static func quality_str(q: Quality) -> String:
	match q:
		Quality.TARNISHED: return "tarnished"
		Quality.COMMON: return "common"
		Quality.FINE: return "fine"
		Quality.PREMIUM: return "premium"
	return ""

static func quality_multiplier(q: Quality) -> int:
	match q:
		Quality.TARNISHED: return 0.5
		Quality.COMMON: return 1.0
		Quality.FINE: return 1.5
		Quality.PREMIUM: return 2.0
	return 0.0

@export var item_type: ItemType
@export var quality: Quality
@export var is_crafted: bool
@export var inventory_slot: Vector2i

func get_value() -> int:
	return int(quality_multiplier(quality) * item_type.base_value)

func make_tooltip(game_manager: GameManager):
	var tags: PackedStringArray = ItemAttributes.type_str(item_type.attributes.type_flag)
	var add_if_not_empty = func (t): if not t.is_empty(): tags.append(t)
	add_if_not_empty.call(ItemAttributes.attraction_str(item_type.attributes.attraction))
	add_if_not_empty.call(ItemAttributes.color_str(item_type.attributes.color))
	add_if_not_empty.call(ItemAttributes.texture_str(item_type.attributes.texture))
	add_if_not_empty.call(ItemAttributes.temperature_str(item_type.attributes.temperature))

	var breakdown := PackedStringArray()
	if game_manager:
		var total = item_type.breakdown.size()
		if game_manager.player_stats.breakdown_knowledge.has(item_type):
			for known_item_type: ItemType in game_manager.player_stats.breakdown_knowledge[item_type]:
				breakdown.append(known_item_type.name)
		while breakdown.size() < total:
			breakdown.append("???")

	var info = {
		"name": item_type.name,
		"qual": quality_str(quality),
		"craf": "\nIt is crafted by you." if is_crafted else "",
		"size": ItemAttributes.size_str(item_type.attributes.size),
		"tags": ", ".join(tags),
		"break": ("\nIt breaks down into:\n - " + ", ".join(breakdown)) if !breakdown.is_empty() else "",
		"value": get_value(),
	}
	return "[b]{name}[/b] ([i]{qual}[/i])\nValue: {value}\nIt is {size}-sized.{craf}{break}\n\n({tags})".format(info)
