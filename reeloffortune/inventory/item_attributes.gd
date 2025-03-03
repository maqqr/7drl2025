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

enum Attraction {
	NONE, LUMINESCENT, SCENTED, VIBRATING, MIMICRY, FLAVORFUL
}
static func attraction_str(a: Attraction) -> String:
	match a:
		Attraction.LUMINESCENT: return "luminescent"
		Attraction.SCENTED: return "scented"
		Attraction.VIBRATING: return "vibrating"
		Attraction.MIMICRY: return "mimicry"
		Attraction.FLAVORFUL: return "flavorful"
	return ""

enum ColorAttribute {
	NONE, DULL_COLOR, COLORFUL
}
static func color_str(c: ColorAttribute) -> String:
	match c:
		ColorAttribute.DULL_COLOR: return "dull color"
		ColorAttribute.COLORFUL: return "colorful"
	return ""

enum TextureAttribute {
	NONE, STICKY, SLIPPERY, SHARP, SMOOTH
}
static func texture_str(t: TextureAttribute) -> String:
	match t:
		TextureAttribute.STICKY: return "sticky"
		TextureAttribute.SLIPPERY: return "slippery"
		TextureAttribute.SHARP: return "sharp"
		TextureAttribute.SMOOTH: return "smooth"
	return ""

enum Temperature {
	NEUTRAL, COLD, WARM
}
static func temperature_str(t: Temperature) -> String:
	match t:
		Temperature.COLD: return "cold"
		Temperature.WARM: return "warm"
	return ""

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
@export var attraction: Attraction
@export var color: ColorAttribute
@export var texture: TextureAttribute
@export var temperature: Temperature
