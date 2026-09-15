class_name Outfit
extends RefCounted
## Player outfit: one wardrobe item per slot plus colours. Converts to a CharacterPainter look.

const SLOTS: Array[String] = ["skin", "hair", "top", "bottom", "shoes", "hat", "face", "back", "hand"]
## Slot -> outfit key of the colour the player can pick for it.
const COLOR_KEYS: Dictionary[String, String] = {
	"hair": "hair_color", "top": "top_color", "bottom": "pants_color", "shoes": "shoes_color",
}
## Tops with a fixed colour scheme ignore the chosen top colour.
const FIXED_TOP_COLORS: Dictionary[String, String] = {
	"alfa_hoodie": "#ef3124", "alfa_tee": "#fbfaf8", "tuxedo": "#23232a", "armor": "#aeb4bc",
}
const MASK_COLOR: String = "#d6283a"
const NONE: String = "none"


static func default_outfit() -> Dictionary:
	return {
		"skin": "1", "hair": "side_part", "hair_color": "#4a2f22",
		"top": "jacket", "top_color": "#ef3124", "bottom": "pants", "pants_color": "#2c3a55",
		"shoes": "shoes", "shoes_color": "#2a2020",
		"hat": NONE, "face": NONE, "back": NONE, "hand": NONE,
	}


## Copy with every known key present and stringified; unknown keys are dropped.
static func normalized(outfit: Dictionary) -> Dictionary:
	var result: Dictionary = default_outfit()
	for key: String in result:
		if outfit.has(key):
			result[key] = str(outfit[key])
	return result


## Stable text key of an outfit, used for caching painted sheets.
static func key(outfit: Dictionary) -> String:
	var normal: Dictionary = normalized(outfit)
	var parts: PackedStringArray = PackedStringArray()
	for name: String in normal:
		parts.append("%s=%s" % [name, normal[name]])
	return "|".join(parts)


static func is_valid_color(value: String) -> bool:
	if value.length() != 7 or not value.begins_with("#"):
		return false
	return value.substr(1).is_valid_hex_number()


static func to_look(outfit: Dictionary) -> Dictionary:
	var o: Dictionary = normalized(outfit)
	var top_style: String = o["top"]
	var look: Dictionary = {
		"skin": int(o["skin"]), "hair": o["hair"], "hair_color": o["hair_color"],
		"top": top_style, "top_color": FIXED_TOP_COLORS.get(top_style, o["top_color"]), "inner_color": "#fbfaf8",
		"bottom": o["bottom"], "pants_color": o["pants_color"],
		"shoes_style": o["shoes"], "shoes_color": o["shoes_color"],
		"hat": _item(o["hat"]), "back": _item(o["back"]), "hand": _item(o["hand"]), "badge": true,
	}
	if top_style == "suit":
		look["tie"] = "#b01e14"
	var face: String = o["face"]
	match face:
		"glasses":
			look["glasses"] = true
		"mustache":
			look["mustache"] = true
		"beard":
			look["beard"] = true
		NONE:
			pass
		_:
			if face.begins_with("mask_"):
				look["mask"] = face.trim_prefix("mask_")
				look["mask_color"] = MASK_COLOR
			else:
				look["face_item"] = face
	return CharacterLooks.with_defaults(look)


static func _item(value: String) -> String:
	return "" if value == NONE else value
