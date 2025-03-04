extends PanelContainer

@export var equip_flag: ItemAttributes.TypeFlag

func _ready() -> void:
	if equip_flag & ItemAttributes.TypeFlag.ROD:
		custom_minimum_size.x *= 3
	var tags: PackedStringArray = ItemAttributes.type_str(equip_flag)
	assert(tags.size() == 1)
	$RichTextLabel.text = "[i]" + tags[0].capitalize().substr(0, 5) + "[/i]"
