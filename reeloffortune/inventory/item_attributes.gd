class_name ItemAttributes
extends Resource

enum Size {
	TINY, SMALL, MEDIUM, LARGE, MASSIVE
}
static func size_str(s: Size) -> String:
	match s:
		Size.TINY: return "tiny"
		Size.SMALL: return "small"
		Size.MEDIUM: return "medium"
		Size.LARGE: return "large"
		Size.MASSIVE: return "massive"
	return ""

enum AttractionFlag {
	NONE = 0, LUMINESCENT = 1, SCENTED = 2, VIBRATING = 4, MIMICRY = 8, FLAVORFUL = 16
}
static func attraction_flag_str(a: AttractionFlag) -> PackedStringArray:
	var result: PackedStringArray = []
	if a & AttractionFlag.LUMINESCENT: result.append("luminescent")
	if a & AttractionFlag.SCENTED: result.append("scented")
	if a & AttractionFlag.VIBRATING: result.append("vibrating")
	if a & AttractionFlag.MIMICRY: result.append("mimicry")
	if a & AttractionFlag.FLAVORFUL: result.append("flavorful")
	return result

enum ColorAttribute {
	NONE, DULL_COLOR, COLORFUL
}
static func color_str(c: ColorAttribute) -> String:
	match c:
		ColorAttribute.DULL_COLOR: return "dull color"
		ColorAttribute.COLORFUL: return "colorful"
	return ""

static func color_mix(c1: ColorAttribute, c2: ColorAttribute) -> ColorAttribute:
	return generic_exclusive_mix(c1, c2) as ColorAttribute

enum Stickyness {
	NONE, STICKY, SLIPPERY
}
static func stickyness_str(t: Stickyness) -> String:
	match t:
		Stickyness.STICKY: return "sticky"
		Stickyness.SLIPPERY: return "slippery"
	return ""

static func stickyness_mix(c1: Stickyness, c2: Stickyness) -> Stickyness:
	return generic_exclusive_mix(c1, c2) as Stickyness

enum Sharpness {
	NONE, SHARP, SMOOTH
}
static func sharpness_str(t: Sharpness) -> String:
	match t:
		Sharpness.SHARP: return "sharp"
		Sharpness.SMOOTH: return "smooth"
	return ""

static func sharpness_mix(c1: Sharpness, c2: Sharpness) -> Sharpness:
	return generic_exclusive_mix(c1, c2) as Sharpness

enum Temperature {
	NEUTRAL, COLD, WARM
}
static func temperature_str(t: Temperature) -> String:
	match t:
		Temperature.COLD: return "cold"
		Temperature.WARM: return "warm"
	return ""

static func temperature_mix(t1: Temperature, t2: Temperature) -> Temperature:
	return generic_exclusive_mix(t1, t2) as Temperature

enum TypeFlag {
	BAIT = 1, MATERIAL = 2, ROD = 4, CONSUMABLE = 8, CLOTHING = 16, BOOTS = 32, FISH = 64, CURSED = 128
}
static func type_str(t: TypeFlag) -> PackedStringArray:
	var result: PackedStringArray = []
	if t & TypeFlag.BAIT: result.append("bait")
	if t & TypeFlag.MATERIAL: result.append("material")
	if t & TypeFlag.ROD: result.append("rod")
	if t & TypeFlag.CONSUMABLE: result.append("consumable")
	if t & TypeFlag.CLOTHING: result.append("clothing")
	if t & TypeFlag.BOOTS: result.append("boots")
	if t & TypeFlag.FISH: result.append("fish")
	if t & TypeFlag.CURSED: result.append("cursed")
	return result

@export_flags("BAIT", "MATERIAL", "ROD", "CONSUMABLE", "CLOTHING", "BOOTS", "FISH", "CURSED") var type_flag: int
@export var size: Size
@export_flags("LUMINESCENT", "SCENTED", "VIBRATING", "MIMICRY", "FLAVORFUL") var attraction_flag: int
@export var color: ColorAttribute
@export var stickyness: Stickyness
@export var sharpness: Sharpness
@export var temperature: Temperature

static func generic_exclusive_mix(v1: int, v2: int) -> int:
	if v1 == 0:
		return v2
	if v2 == 0:
		return v1
	if v1 == v2:
		return v1
	return 0
