class_name FishEntry
extends Resource

enum Attraction {
	LUMINESCENT,
	SCENTED,
	VIBRATING,
	MIMICRY,
	FLAVORFUL,
	DULL_COLOR,
	COLORFUL,
	STICKY,
	SLIPPERY,
	SHARP,
	SMOOTH,
	COLD,
	WARM,
	CURSED,
}

static func attraction_str(a: Attraction):
	match a:
		Attraction.LUMINESCENT: return "luminescent"
		Attraction.SCENTED: return "scented"
		Attraction.VIBRATING: return "vibrating"
		Attraction.MIMICRY: return "mimicry"
		Attraction.FLAVORFUL: return "flavorful"
		Attraction.DULL_COLOR: return "dull color"
		Attraction.COLORFUL: return "colorful"
		Attraction.STICKY: return "sticky"
		Attraction.SLIPPERY: return "slippery"
		Attraction.SHARP: return "sharp"
		Attraction.SMOOTH: return "smooth"
		Attraction.COLD: return "cold"
		Attraction.WARM: return "warm"
		Attraction.CURSED: return "cursed"
	assert(false)

@export var item_type: ItemType
@export var attractions: Array[Attraction]
@export var minor_attractions: Array[Attraction]
@export var min_depth: int
@export var strength: float
@export var stamina: float
@export_multiline var description: String

var is_known: bool = false

func get_max_bait_size() -> ItemAttributes.Size:
	#return max(ItemAttributes.Size.TINY, item_type.size - 1)
	return item_type.attributes.size

func get_preferred_bait_size() -> ItemAttributes.Size:
	return max(ItemAttributes.Size.TINY, item_type.attributes.size - 1)

static func attraction_match_count(attr_array: Array[Attraction], attr: ItemAttributes) -> int:
	var result = 0
	for attraction in attr_array:
		match attraction:
			Attraction.LUMINESCENT: if attr.attraction_flag & ItemAttributes.AttractionFlag.LUMINESCENT: result += 1
			Attraction.SCENTED: if attr.attraction_flag & ItemAttributes.AttractionFlag.SCENTED: result += 1
			Attraction.VIBRATING: if attr.attraction_flag & ItemAttributes.AttractionFlag.VIBRATING: result += 1
			Attraction.MIMICRY: if attr.attraction_flag & ItemAttributes.AttractionFlag.MIMICRY: result += 1
			Attraction.FLAVORFUL: if attr.attraction_flag & ItemAttributes.AttractionFlag.FLAVORFUL: result += 1
			Attraction.DULL_COLOR: if attr.color == ItemAttributes.ColorAttribute.DULL_COLOR: result += 1
			Attraction.COLORFUL: if attr.color == ItemAttributes.ColorAttribute.COLORFUL: result += 1
			Attraction.STICKY: if attr.stickyness == ItemAttributes.Stickyness.STICKY: result += 1
			Attraction.SLIPPERY: if attr.stickyness == ItemAttributes.Stickyness.SLIPPERY: result += 1
			Attraction.SHARP: if attr.sharpness == ItemAttributes.Sharpness.SHARP: result += 1
			Attraction.SMOOTH: if attr.sharpness == ItemAttributes.Sharpness.SMOOTH: result += 1
			Attraction.COLD: if attr.temperature == ItemAttributes.Temperature.COLD: result += 1
			Attraction.WARM: if attr.temperature == ItemAttributes.Temperature.WARM: result += 1
			Attraction.CURSED: if attr.type_flag & ItemAttributes.TypeFlag.CURSED: result += 1
			_: assert(false)
	return result

static func load_all() -> Array[FishEntry]:
	var fishes: Array[FishEntry] = []
	var paths = ItemType._get_all_file_paths("res://fish/fish_entries")
	for path in paths:
		fishes.append(load(path))

	# Fish config validation
	for fish in fishes:
		assert(fish.stamina > 0.0)
		assert(fish.strength > 0.0)
		assert(!fish.attractions.is_empty())

	return fishes
