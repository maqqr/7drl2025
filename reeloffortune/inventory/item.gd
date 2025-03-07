class_name Item
extends Resource

enum Quality {
	TARNISHED, COMMON, FINE, PREMIUM, LEGENDARY
}
static func quality_str(q: Quality) -> String:
	match q:
		Quality.TARNISHED: return "tarnished"
		Quality.COMMON: return "common"
		Quality.FINE: return "fine"
		Quality.PREMIUM: return "premium"
		Quality.LEGENDARY: return "legendary"
	return ""

static func quality_color(q: Quality) -> Color:
	match q:
		Quality.TARNISHED: return Color.GRAY
		Quality.COMMON: return Color.WHITE
		Quality.FINE: return Color.LAWN_GREEN
		Quality.PREMIUM: return Color.DEEP_SKY_BLUE
		Quality.LEGENDARY: return Color.ORANGE
	return Color.WHITE

static func quality_multiplier(q: Quality) -> float:
	match q:
		Quality.TARNISHED: return 0.5
		Quality.COMMON: return 1.0
		Quality.FINE: return 1.5
		Quality.PREMIUM: return 2.0
		Quality.LEGENDARY: return 10.0
	return 0.0

@export var item_type: ItemType
@export var quality: Quality
@export var is_crafted: bool
@export var inventory_slot: Vector2i

func get_stamina_restore_amount() -> int:
	return int(quality_multiplier(quality) * item_type.stamina_gain)

func get_value() -> int:
	return int(quality_multiplier(quality) * item_type.base_value)

func get_buy_price() -> int:
	if item_type.attributes.type_flag & ItemAttributes.TypeFlag.ROD:
		if quality == Quality.TARNISHED:
			return 0
		else:
			return int(quality_multiplier(quality) * 40)
	else:
		return get_value()

func make_tooltip(game_manager: GameManager) -> String:
	var tags: PackedStringArray = ItemAttributes.type_str(item_type.attributes.type_flag)
	var add_if_not_empty = func (t): if not t.is_empty(): tags.append(t)
	for tag in ItemAttributes.attraction_flag_str(item_type.attributes.attraction_flag):
		tags.append(tag)
	add_if_not_empty.call(ItemAttributes.color_str(item_type.attributes.color))
	add_if_not_empty.call(ItemAttributes.sharpness_str(item_type.attributes.sharpness))
	add_if_not_empty.call(ItemAttributes.stickyness_str(item_type.attributes.stickyness))
	add_if_not_empty.call(ItemAttributes.temperature_str(item_type.attributes.temperature))

	var breakdown := PackedStringArray()
	if game_manager:
		var total = item_type.breakdown.size()
		if game_manager.player_stats.breakdown_knowledge.has(item_type):
			for known_item_type: ItemType in game_manager.player_stats.breakdown_knowledge[item_type]:
				breakdown.append(known_item_type.name)
		while breakdown.size() < total:
			breakdown.append("???")

	var stam_gain = get_stamina_restore_amount()
	var info = {
		"col": "#" + quality_color(quality).to_html(false),
		"name": item_type.name,
		"qual": quality_str(quality),
		"craf": "\nIt is crafted by you." if is_crafted else "",
		"size": ItemAttributes.size_str(item_type.attributes.size),
		"tags": ", ".join(tags),
		"break": ("\nIt breaks down into:\n - " + ", ".join(breakdown)) if !breakdown.is_empty() else "",
		"value": str(get_value()) + " [img=24]res://icons/coin.png[/img]",
		"stam": "" if stam_gain == 0 else "\nRestores " + str(stam_gain) + " stamina."
	}
	return "[color={col}][b]{name}[/b] ([i]{qual}[/i])[/color]\nValue: {value}\nIt is {size}-sized.{stam}{craf}{break}\n\n({tags})".format(info)
