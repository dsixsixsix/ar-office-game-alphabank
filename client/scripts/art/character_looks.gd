class_name CharacterLooks
extends RefCounted
## Appearance of every NPC. Keys match sprite sheet file names in assets/characters/.
## The player's look is built from the saved outfit instead, see Outfit.to_look().
## top: shirt | blouse | tee | jacket | suit | hoodie | cardigan | bomber, plus wardrobe tops (see Outfit)
## hair: short | long | bun | buzz | ponytail | curly | bald | side_part | afro | mohawk
## mask: "" | fox | raccoon | deer | cat


static func all() -> Dictionary[String, Dictionary]:
	return {
		"anna": with_defaults({
			"skin": 0, "hair": "long", "hair_color": "#e3b565",
			"top": "blouse", "top_color": "#5b8fd6", "pants_color": "#3b3b44",
			"shoes_color": "#6b3a2a", "badge": true,
		}),
		"sergey": with_defaults({
			"skin": 1, "hair": "buzz", "hair_color": "#1e1a18", "beard": true,
			"top": "hoodie", "top_color": "#7d8089", "pants_color": "#26324a",
			"shoes_color": "#f0f0f0", "shoes_style": "sneakers", "headphones": true,
		}),
		"olga": with_defaults({
			"skin": 2, "hair": "bun", "hair_color": "#7a3322", "glasses": true,
			"top": "cardigan", "top_color": "#4c9e72", "inner_color": "#f2eee8",
			"pants_color": "#5a4a42", "bottom": "skirt", "shoes_color": "#2a2020", "badge": true,
		}),
		"igor": with_defaults({
			"skin": 0, "hair": "bald", "hair_color": "#9a9a9a", "glasses": true, "mustache": true,
			"top": "suit", "top_color": "#c7b08c", "inner_color": "#fbfaf8", "tie": "#b01e14",
			"pants_color": "#a8926e", "shoes_color": "#3a2418", "hand": "briefcase",
		}),
		"reception": with_defaults({
			"skin": 1, "hair": "ponytail", "hair_color": "#2a1a14",
			"top": "blouse", "top_color": "#fbfaf8", "scarf": "#ef3124",
			"pants_color": "#1f1f24", "shoes_color": "#ef3124", "badge": true,
		}),
		"fox": with_defaults({
			"skin": 1, "hair": "short", "hair_color": "#2a1a14", "mask": "fox", "mask_color": "#e0452c",
			"top": "bomber", "top_color": "#5a2a7a", "inner_color": "#1f1f24",
			"pants_color": "#1f1f24", "shoes_color": "#fbfaf8", "shoes_style": "sneakers",
		}),
		"raccoon": with_defaults({
			"skin": 2, "hair": "curly", "hair_color": "#1a1412", "mask": "raccoon", "mask_color": "#9e1f2a",
			"top": "tee", "top_color": "#2fb3a6", "pants_color": "#3a3a44", "shoes_color": "#2a2020",
		}),
		"deer": with_defaults({
			"skin": 0, "hair": "long", "hair_color": "#3a2418", "mask": "deer", "mask_color": "#c43a3a",
			"top": "hoodie", "top_color": "#7a1f3a", "pants_color": "#2c2c34", "shoes_color": "#f0e6d0",
		}),
		"cat": with_defaults({
			"skin": 3, "hair": "bun", "hair_color": "#141012", "mask": "cat", "mask_color": "#d81f4a",
			"top": "tee", "top_color": "#1f1f24", "pants_color": "#e8e0d0", "shoes_color": "#d81f4a",
		}),
	}


static func with_defaults(values: Dictionary) -> Dictionary:
	var defaults: Dictionary = {
		"skin": 1, "hair": "short", "hair_color": "#3b2a20",
		"top": "shirt", "top_color": "#fbfaf8", "inner_color": "#fbfaf8",
		"bottom": "pants", "pants_color": "#2c3a55", "shoes_style": "shoes", "shoes_color": "#222222",
		"glasses": false, "beard": false, "mustache": false, "tie": "", "scarf": "",
		"badge": false, "headphones": false, "mask": "", "mask_color": "#ef3124",
		"hat": "", "face_item": "", "back": "", "hand": "",
	}
	defaults.merge(values, true)
	return defaults
