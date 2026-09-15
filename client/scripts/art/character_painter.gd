class_name CharacterPainter
extends RefCounted
## Paints three-quarter-view character frames. The 32x48 body sits inside a 48x64 frame at BODY_OFFSET,
## which leaves room for hats, wings, balloons and other accessories.
## Sheet layout: rows = Dir (down, up, side facing right), columns = idle A, idle B, walk 1-4.
## Used by the art generator for NPC sheets and at runtime for the customisable player.

enum Dir { DOWN, UP, SIDE }

const FRAME: Vector2i = Vector2i(48, 64)
const BODY_OFFSET: Vector2i = Vector2i(8, 16)
const COLUMNS: int = 6
const EYE: Color = Color("#1a1418")
const WALK_LEG: Array[int] = [1, 0, -1, 0]
const WALK_BOB: Array[int] = [0, -1, 0, -1]
const OPEN_TOPS: Array[String] = ["jacket", "suit", "bomber", "cardigan"]
## Wardrobe tops that reuse the silhouette of a base style.
const BASE_TOP: Dictionary[String, String] = {
	"alfa_hoodie": "hoodie", "alfa_tee": "tee", "tuxedo": "suit", "tracksuit": "bomber", "hawaiian": "shirt",
}
const NO_BADGE_TOPS: Array[String] = ["robe", "armor", "tuxedo", "hawaiian", "sweater_xmas"]
const MARK: Array[String] = ["..X..", ".X.X.", ".XXX.", "X...X", ".....", "XXXXX"]
const MARK_SMALL: Array[String] = [".X.", "X.X", "XXX", "...", "XXX"]

const GOLD: Color = Color("#f7c948")
const GOLD_DARK: Color = Color("#c9951e")
const METAL: Color = Color("#aeb4bc")
const RED_DARK: Color = Color("#a3141c")

var c: PixelCanvas
var look: Dictionary

var skin: Color
var skin_s: Color
var lip: Color
var hair: Color
var hair_s: Color
var hair_l: Color
var top: Color
var top_s: Color
var top_l: Color
var inner: Color
var pants: Color
var pants_s: Color
var shoes: Color
var shoes_s: Color
var mask: Color
var mask_s: Color
var mask_l: Color

## Animation column of the frame being painted; drives flapping, waving and spinning accessories.
var _col: int = 0
var _hand: Vector2i = Vector2i.ZERO
var _hand_dir: int = 1


func _init(p_look: Dictionary) -> void:
	look = CharacterLooks.with_defaults(p_look)
	skin = Palette.SKIN_TONES[clampi(int(look["skin"]), 0, Palette.SKIN_TONES.size() - 1)]
	skin_s = Palette.shade(skin, 0.14)
	lip = Palette.shade(skin, 0.3).lerp(Color("#b8454a"), 0.35)
	hair = Color(look["hair_color"])
	hair_s = Palette.shade(hair, 0.16)
	hair_l = Palette.light(hair, 0.16)
	top = Color(look["top_color"])
	top_s = Palette.shade(top, 0.16)
	top_l = Palette.light(top, 0.1)
	inner = Color(look["inner_color"])
	pants = Color(look["pants_color"])
	pants_s = Palette.shade(pants, 0.12)
	shoes = Color(look["shoes_color"])
	shoes_s = Palette.shade(shoes, 0.2)
	mask = Color(look["mask_color"])
	mask_s = Palette.shade(mask, 0.2)
	mask_l = Palette.light(mask, 0.3)


static func sheet_size() -> Vector2i:
	return Vector2i(COLUMNS * FRAME.x, 3 * FRAME.y)


func paint_sheet(canvas: PixelCanvas) -> void:
	c = canvas
	for direction: int in 3:
		for column: int in COLUMNS:
			_paint_cell(Rect2i(column * FRAME.x, direction * FRAME.y, FRAME.x, FRAME.y), direction, column)


## Paints a single frame into the top-left 48x64 cell of the canvas, e.g. for wardrobe thumbnails.
func paint_frame(canvas: PixelCanvas, direction: int, column: int = 0) -> void:
	c = canvas
	_paint_cell(Rect2i(Vector2i.ZERO, FRAME), direction, column)


func _paint_cell(cell: Rect2i, direction: int, column: int) -> void:
	c.set_cell(cell)
	c.origin = cell.position + BODY_OFFSET
	_col = column
	var walking: bool = column >= 2
	var bob: int = WALK_BOB[column - 2] if walking else column
	var leg: int = WALK_LEG[column - 2] if walking else 0
	if direction == Dir.SIDE:
		_side(bob, leg, walking)
	else:
		_front(bob, leg, direction == Dir.DOWN)
	c.outline(0.78)


func _top_style() -> String:
	return BASE_TOP.get(look["top"], look["top"])


func _short_sleeves() -> bool:
	return _top_style() == "tee" or look["top"] == "hawaiian"


func _bare_legs() -> bool:
	return look["top"] == "robe"


func _glyph(rows: Array[String], x: int, y: int, color: Color) -> void:
	for row: int in rows.size():
		for column: int in rows[row].length():
			if rows[row][column] == "X":
				c.px(x + column, y + row, color)


# --- Front and back ----------------------------------------------------------


func _front(b: int, leg: int, facing: bool) -> void:
	var ty: int = 19 + b
	if facing:
		_back_item(Dir.DOWN, b)
	else:
		_hand_item(Vector2i(7, ty + 11 - leg), -1)
	if not facing and look["hair"] == "long":
		c.rect(9, 12 + b, 14, 12, hair_s)
	_legs_front(b, leg, facing)
	# Arms swing opposite to the legs.
	for arm: Array in [[7, -leg], [23, leg]]:
		var arm_x: int = arm[0]
		var hand_y: int = ty + 11 + int(arm[1])
		var sleeve_end: int = ty + 5 if _short_sleeves() else hand_y
		c.rect(arm_x, ty + 1, 2, hand_y - ty - 1, skin)
		c.rect(arm_x, ty + 1, 2, sleeve_end - ty - 1, top)
		c.vline(arm_x + (1 if arm_x < 16 else 0), ty + 2, sleeve_end - ty - 2, top_s)
		if look["top"] == "tracksuit":
			c.vline(arm_x if arm_x < 16 else arm_x + 1, ty + 2, sleeve_end - ty - 3, Palette.WHITE)
		if look["top"] == "armor":
			c.ellipse(arm_x + 1.0, ty + 2.0, 2.5, 2.5, top_l)
		c.rect(arm_x, hand_y, 2, 2, skin)
		c.px(arm_x + 1, hand_y + 1, skin_s)
	# Torso.
	var torso_h: int = 21 if look["top"] == "robe" else 14
	c.rect(9, ty + 1, 14, torso_h, top)
	c.hline(10, ty, 12, top)
	c.rect(21, ty + 1, 2, torso_h, top_s)
	c.vline(10, ty + 1, 6, top_l)
	if torso_h == 14:
		c.hline(9, ty + 14, 14, pants_s)
	c.rect(14, ty - 2, 4, 3, skin_s)
	if facing:
		_front_clothes(ty)
	else:
		_back_clothes(ty)
	_head_front(b, facing)
	if facing:
		_face_item_front(b)
	_hat(b, Dir.DOWN if facing else Dir.UP)
	if facing:
		_front_overlay(ty)
		_hand_item(Vector2i(23, ty + 11 + leg), 1)
	else:
		_back_item(Dir.UP, b)


func _legs_front(b: int, leg: int, facing: bool) -> void:
	var hip: int = 33 + b
	var bottom: String = look["bottom"]
	var cloth_end_offset: int = 99
	if bottom == "shorts":
		cloth_end_offset = 6
	elif bottom == "skirt" or _bare_legs():
		cloth_end_offset = 0
	for foot: Array in [[10, 45 + leg], [16, 45 - leg]]:
		var x: int = foot[0]
		var foot_y: int = foot[1]
		var cloth_end: int = mini(hip + cloth_end_offset, foot_y)
		if cloth_end > hip:
			c.rect(x, hip, 6, cloth_end - hip, pants)
			c.vline(x + 5, hip + 1, cloth_end - hip - 1, pants_s)
			if bottom == "track":
				c.vline(x if x < 16 else x + 5, hip + 1, cloth_end - hip - 1, Palette.WHITE)
		if foot_y > cloth_end:
			c.rect(x + 1, cloth_end, 4, foot_y - cloth_end, skin)
			c.vline(x + 4, cloth_end, foot_y - cloth_end, skin_s)
		_shoe(x, foot_y, 6, facing)
	if bottom == "skirt" and not _bare_legs():
		c.polygon(PackedVector2Array([Vector2(9, hip - 1), Vector2(23, hip - 1), Vector2(25, hip + 7), Vector2(7, hip + 7)]), pants)
		c.hline(8, hip + 6, 17, pants_s)
		c.vline(16, hip, 6, pants_s)


func _shoe(x: int, y: int, w: int, front_facing: bool) -> void:
	match look["shoes_style"]:
		"sneakers":
			c.rect(x, y, w, 2, shoes)
			c.hline(x, y + 1, w, Palette.WHITE)
			c.px(x + 1, y, Palette.light(shoes, 0.2))
		"slippers":
			var fluff: Color = Color("#f6eef2")
			c.rect(x - 1, y - 1, w + 1, 3, fluff)
			c.hline(x - 1, y + 1, w + 1, Color("#d9cbd2"))
			c.px(x, y - 2, fluff)
			c.px(x + w - 2, y - 2, fluff)
			c.px(x, y - 1, Color("#f59ab0"))
			c.px(x + w - 2, y - 1, Color("#f59ab0"))
		"boots":
			c.rect(x, y - 4, w, 6, shoes)
			c.hline(x, y - 4, w, Palette.light(shoes, 0.15))
			c.hline(x, y + 1, w, shoes_s)
		_:
			c.rect(x, y, w, 2, shoes)
			c.hline(x, y + (1 if front_facing else 0), w, shoes_s)


func _front_clothes(ty: int) -> void:
	var style: String = _top_style()
	match style:
		"shirt":
			c.px(13, ty + 1, Palette.light(top, 0.2))
			c.px(18, ty + 1, Palette.light(top, 0.2))
			for y: int in range(ty + 4, ty + 13, 3):
				c.px(16, y, top_s)
		"blouse":
			c.rect(15, ty, 2, 2, skin)
			c.px(16, ty + 2, skin_s)
			c.hline(12, ty + 8, 8, top_s)
		"tee":
			c.rect(14, ty, 4, 1, skin)
			c.hline(13, ty + 1, 6, top_s)
		"jacket", "suit", "bomber", "cardigan":
			c.rect(14, ty + 1, 4, 13 if style == "cardigan" else 9, inner)
			if style == "bomber":
				c.vline(16, ty + 1, 13, top_s)
				c.hline(9, ty + 13, 14, top_s)
				c.hline(12, ty, 8, inner)
			elif style == "cardigan":
				c.vline(13, ty + 1, 13, top_s)
				c.vline(18, ty + 1, 13, top_s)
				for y: int in range(ty + 4, ty + 13, 3):
					c.px(13, y, top_l)
			else:
				c.line(13, ty + 1, 15, ty + 7, top_s)
				c.line(18, ty + 1, 16, ty + 7, top_s)
				c.px(15, ty + 10, Palette.shade(top, 0.4))
				c.px(15, ty + 12, Palette.shade(top, 0.4))
		"hoodie":
			c.rect(12, ty - 1, 8, 2, top_s)
			c.hline(10, ty, 12, top_s)
			c.vline(14, ty + 2, 4, Palette.WHITE)
			c.vline(18, ty + 2, 4, Palette.WHITE)
			if look["top"] != "alfa_hoodie":
				c.hline(11, ty + 9, 10, top_s)
				c.vline(11, ty + 9, 4, top_s)
				c.vline(20, ty + 9, 4, top_s)
		"sweater_xmas":
			c.hline(12, ty, 8, top_s)
			_knit_pattern(ty)
		"robe":
			c.polygon(PackedVector2Array([Vector2(13, ty), Vector2(19, ty), Vector2(16, ty + 6)]), skin)
			c.line(13, ty + 1, 16, ty + 7, top_l)
			c.line(19, ty + 1, 16, ty + 7, top_s)
			c.hline(9, ty + 9, 14, top_s)
			c.vline(17, ty + 10, 5, top_s)
			c.vline(19, ty + 10, 4, top_s)
			c.hline(9, ty + 21, 14, top_s)
		"armor":
			_armor_plates(ty, 9, 14)
	match look["top"]:
		"alfa_hoodie":
			_glyph(MARK, 14, ty + 6, Palette.WHITE)
		"alfa_tee":
			_glyph(MARK, 14, ty + 4, Palette.ALFA_RED)
		"hawaiian":
			c.polygon(PackedVector2Array([Vector2(14, ty), Vector2(18, ty), Vector2(16, ty + 4)]), skin)
			for spot: Vector2i in [Vector2i(11, 3), Vector2i(19, 5), Vector2i(13, 9), Vector2i(20, 11), Vector2i(10, 12), Vector2i(17, 12)]:
				c.px(spot.x, ty + spot.y, GOLD)
				c.px(spot.x - 1, ty + spot.y, Color("#f59ab0"))
				c.px(spot.x + 1, ty + spot.y, Color("#f59ab0"))
				c.px(spot.x, ty + spot.y - 1, Color("#f59ab0"))
				c.px(spot.x, ty + spot.y + 1, Color("#4f9a4a"))
		"tracksuit":
			c.hline(12, ty, 8, Palette.WHITE)
			c.vline(10, ty + 2, 11, Palette.WHITE)
		"tuxedo":
			c.rect(14, ty + 1, 4, 2, Palette.INK)
			c.px(15, ty + 1, Color("#3a3a44"))
			c.px(16, ty + 5, Palette.INK)
			c.px(16, ty + 8, Palette.INK)
	if look["tie"] != "":
		var tie: Color = Color(look["tie"])
		c.rect(15, ty + 1, 2, 2, Palette.shade(tie, 0.15))
		c.rect(15, ty + 3, 2, 7, tie)
		c.px(15, ty + 10, tie)
	if look["scarf"] != "":
		var scarf: Color = Color(look["scarf"])
		c.rect(12, ty, 8, 2, scarf)
		c.rect(17, ty + 2, 2, 5, Palette.shade(scarf, 0.12))
	if look["badge"] and not NO_BADGE_TOPS.has(look["top"]):
		if OPEN_TOPS.has(style):
			c.rect(10, ty + 6, 3, 4, Palette.WHITE)
			c.hline(10, ty + 6, 3, Palette.ALFA_RED)
		elif look["top"] != "alfa_hoodie" and look["top"] != "alfa_tee":
			c.line(13, ty + 1, 14, ty + 8, Palette.ALFA_RED)
			c.line(18, ty + 1, 17, ty + 8, Palette.ALFA_RED)
			c.rect(14, ty + 8, 4, 5, Palette.WHITE)
			c.hline(14, ty + 8, 4, Palette.ALFA_RED)
	if look["headphones"]:
		c.rect(11, ty - 1, 10, 2, Palette.INK)
		c.rect(10, ty - 1, 2, 3, Palette.INK)
		c.rect(20, ty - 1, 2, 3, Palette.INK)


func _knit_pattern(ty: int) -> void:
	for x: int in range(9, 23):
		c.px(x, ty + 3 + x % 2, Palette.WHITE)
		c.px(x, ty + 11 + (x + 1) % 2, Palette.WHITE)
	for x: int in range(10, 22, 4):
		c.px(x, ty + 7, Color("#3f9e4a"))
		c.px(x + 1, ty + 6, Palette.WHITE)
		c.px(x + 1, ty + 8, Palette.WHITE)


func _armor_plates(ty: int, x: int, w: int) -> void:
	for plate_y: int in [ty + 4, ty + 8]:
		c.hline(x, plate_y, w, top_s)
		c.px(x + 1, plate_y + 1, top_l)
		c.px(x + w - 2, plate_y + 1, top_l)
	c.vline(x + 3, ty + 2, 8, Palette.light(top, 0.25))
	c.rect(x, ty + 12, w, 2, Color("#6b4a2a"))
	c.px(x + w / 2, ty + 12, GOLD)


func _back_clothes(ty: int) -> void:
	match _top_style():
		"hoodie":
			c.rect(11, ty - 1, 10, 5, top_s)
			c.hline(12, ty + 4, 8, Palette.shade(top, 0.25))
		"jacket", "suit", "bomber", "cardigan":
			c.vline(16, ty + 3, 11, top_s)
			c.hline(12, ty, 8, top_s)
		"sweater_xmas":
			c.hline(12, ty, 8, top_s)
			_knit_pattern(ty)
		"robe":
			c.hline(12, ty, 8, top_s)
			c.hline(9, ty + 9, 14, top_s)
			c.vline(16, ty + 10, 10, top_s)
		"armor":
			_armor_plates(ty, 9, 14)
		_:
			c.hline(12, ty, 8, top_s)
	if look["top"] == "alfa_hoodie":
		_glyph(MARK, 14, ty + 6, Palette.WHITE)
	if look["headphones"]:
		c.rect(11, ty - 1, 10, 2, Palette.INK)


## Straps, collars and anything worn on the back that shows across the chest.
func _front_overlay(ty: int) -> void:
	match look["back"]:
		"alfa_backpack":
			c.vline(11, ty + 1, 9, RED_DARK)
			c.vline(20, ty + 1, 9, RED_DARK)
			c.px(11, ty + 6, METAL)
			c.px(20, ty + 6, METAL)
		"cape_red":
			c.hline(10, ty, 12, Palette.ALFA_RED)
			c.px(16, ty + 1, GOLD)
		"guitar":
			c.line(10, ty + 1, 21, ty + 12, Color("#4a2c18"))


func _head_front(b: int, facing: bool) -> void:
	if look["hair"] == "afro" and look["mask"] == "":
		c.ellipse(16.0, 7.5 + b, 11.0, 9.0, hair_s)
		c.ellipse(15.5, 7.0 + b, 10.5, 8.5, hair)
	c.rect(8, 10 + b, 1, 3, skin_s)
	c.rect(23, 10 + b, 1, 3, skin_s)
	c.ellipse(16.0, 11.0 + b, 7.0, 7.5, skin_s)
	c.ellipse(15.5, 10.5 + b, 6.5, 7.0, skin)
	if look["mask"] != "":
		_mask_front(b, facing)
		return
	var style: String = look["hair"]
	if not facing:
		_hair_back(b, style)
		return
	_hair_front(b, style)
	c.hline(11, 8 + b, 3, hair_s)
	c.hline(18, 8 + b, 3, hair_s)
	for eye_x: int in [12, 18]:
		c.rect(eye_x, 10 + b, 2, 2, EYE)
		c.px(eye_x, 10 + b, Palette.WHITE)
	c.px(16, 13 + b, skin_s)
	c.hline(15, 15 + b, 3, lip)
	c.px(14, 14 + b, lip)
	c.px(18, 14 + b, lip)
	c.px(11, 13 + b, Color(1.0, 0.45, 0.45, 0.35))
	c.px(20, 13 + b, Color(1.0, 0.45, 0.45, 0.35))
	if look["beard"]:
		c.rect(11, 14 + b, 11, 4, hair_s)
		c.rect(13, 18 + b, 7, 1, hair_s)
		c.hline(15, 15 + b, 3, lip)
	if look["mustache"]:
		c.hline(14, 14 + b, 5, hair)
	if look["glasses"]:
		for lens_x: int in [11, 17]:
			c.hline(lens_x, 9 + b, 4, Palette.INK)
			c.hline(lens_x, 12 + b, 4, Palette.INK)
			c.vline(lens_x, 9 + b, 4, Palette.INK)
			c.vline(lens_x + 3, 9 + b, 4, Palette.INK)
		c.hline(15, 10 + b, 2, Palette.INK)


func _hair_front(b: int, style: String) -> void:
	var hairline: int = 6 + b
	match style:
		"bald":
			c.rect(9, 7 + b, 2, 5, hair)
			c.rect(21, 7 + b, 2, 5, hair)
			c.px(13, 5 + b, Palette.light(skin, 0.2))
			return
		"buzz", "mohawk":
			for y: int in range(3 + b, hairline):
				for x: int in range(9, 23):
					if c.get_px(x, y).a > 0.0 and (x + y) % 2 == 0:
						c.px(x, y, hair_s)
			if style == "mohawk":
				_mohawk(b, 14)
			return
		"bun":
			c.ellipse(16.0, 2.5 + b, 3.5, 2.5, hair)
			hairline = 5 + b
		"ponytail":
			hairline = 5 + b
			c.rect(22, 7 + b, 2, 6, hair_s)
	for y: int in range(2 + b, hairline + 1):
		for x: int in range(8, 24):
			if c.get_px(x, y).a > 0.0:
				c.px(x, y, hair)
	c.hline(12, 3 + b, 4, hair_l)
	match style:
		"side_part":
			c.rect(9, 7 + b, 5, 1, hair)
			c.rect(9, 7 + b, 1, 4, hair)
			c.rect(22, 7 + b, 1, 3, hair)
			c.px(14, 4 + b, hair_s)
		"short":
			c.rect(9, 7 + b, 1, 3, hair)
			c.rect(22, 7 + b, 1, 3, hair)
		"long":
			c.px(16, 3 + b, hair_s)
			c.rect(8, 6 + b, 3, 17, hair)
			c.rect(21, 6 + b, 3, 17, hair)
			c.vline(10, 8 + b, 14, hair_s)
		"curly":
			for x: int in range(8, 25, 2):
				c.px(x, 2 + b + (x / 2) % 2, hair)
			c.rect(8, 6 + b, 2, 6, hair)
			c.rect(22, 6 + b, 2, 6, hair)
		"afro":
			c.rect(7, 6 + b, 3, 7, hair)
			c.rect(22, 6 + b, 3, 7, hair)


func _mohawk(b: int, x: int) -> void:
	c.rect(x, -3 + b, 4, 8, hair)
	c.vline(x + 3, -2 + b, 7, hair_s)
	c.vline(x, -2 + b, 6, hair_l)
	c.px(x + 1, -4 + b, hair)
	c.px(x + 3, -4 + b, hair)


func _hair_back(b: int, style: String) -> void:
	for y: int in range(2 + b, 19 + b):
		for x: int in range(8, 24):
			if c.get_px(x, y).a > 0.0 and y < 16 + b:
				c.px(x, y, hair if (style != "buzz" and style != "mohawk" or (x + y) % 2 == 0) else skin_s)
	if style == "bald":
		c.ellipse(15.5, 7.0 + b, 6.0, 4.5, skin)
		c.px(13, 5 + b, Palette.light(skin, 0.2))
	c.hline(11, 4 + b, 6, hair_l)
	match style:
		"long":
			c.rect(9, 14 + b, 14, 9, hair)
			c.vline(16, 6 + b, 16, hair_s)
		"ponytail":
			c.rect(15, 13 + b, 3, 10, hair)
			c.hline(15, 13 + b, 3, Palette.ALFA_RED)
		"bun":
			c.ellipse(16.0, 3.0 + b, 3.5, 3.0, hair)
			c.hline(14, 5 + b, 4, hair_s)
		"mohawk":
			_mohawk(b, 14)


func _mask_front(b: int, facing: bool) -> void:
	var kind: String = look["mask"]
	var y: int = b
	if not facing:
		_hair_back(b, look["hair"])
		c.hline(9, 10 + y, 14, Palette.INK)
	c.ellipse(16.0, 11.0 + y, 7.5, 7.5, mask_s)
	c.ellipse(15.5, 10.5 + y, 7.0, 7.0, mask)
	match kind:
		"fox":
			for side: int in [1, -1]:
				c.polygon(_mirror([Vector2(8, 1), Vector2(13, 5), Vector2(9, 9)], side, y), mask)
				c.polygon(_mirror([Vector2(9, 3), Vector2(12, 5), Vector2(10, 7)], side, y), mask_s)
			if facing:
				c.polygon(PackedVector2Array([Vector2(9, 12 + y), Vector2(16, 19 + y), Vector2(23, 12 + y), Vector2(16, 14 + y)]), mask_l)
				c.px(16, 15 + y, Palette.INK)
		"raccoon":
			c.ellipse(10.0, 4.0 + y, 2.5, 2.5, mask_s)
			c.ellipse(22.0, 4.0 + y, 2.5, 2.5, mask_s)
			if facing:
				c.rect(9, 9 + y, 14, 4, Palette.shade(mask, 0.4))
				c.ellipse(16.0, 15.5 + y, 4.0, 2.5, mask_l)
				c.px(16, 14 + y, Palette.INK)
		"deer":
			for side: int in [1, -1]:
				var base_x: int = 11 if side == 1 else 21
				c.line(base_x, 4 + y, base_x - 2 * side, 0 + y, Palette.shade(mask, 0.45))
				c.line(base_x - 1 * side, 2 + y, base_x - 4 * side, 1 + y, Palette.shade(mask, 0.45))
				c.ellipse(16.0 - 9.0 * side, 8.0 + y, 2.0, 1.0, mask)
			if facing:
				c.ellipse(16.0, 15.0 + y, 3.5, 3.0, mask_l)
				c.rect(15, 14 + y, 3, 2, Palette.INK)
		"cat":
			for side: int in [1, -1]:
				c.polygon(_mirror([Vector2(8, 1), Vector2(14, 6), Vector2(8, 9)], side, y), mask)
			if facing:
				c.px(16, 13 + y, Color("#f59ab0"))
				c.hline(7, 14 + y, 4, mask_s)
				c.hline(22, 14 + y, 4, mask_s)
	if facing:
		for eye_x: int in [11, 18]:
			var eye_color: Color = Color("#f7e04a") if kind == "cat" else Palette.INK
			c.rect(eye_x, 10 + y, 3, 2, eye_color)
			c.px(eye_x + (1 if kind == "cat" else 0), 10 + y, Palette.INK if kind == "cat" else Palette.WHITE)


func _face_item_front(b: int) -> void:
	if look["mask"] != "":
		return
	match look["face_item"]:
		"sunglasses":
			c.rect(11, 9 + b, 4, 3, Palette.INK)
			c.rect(17, 9 + b, 4, 3, Palette.INK)
			c.hline(15, 10 + b, 2, Palette.INK)
			c.px(12, 9 + b, Color("#6a7a90"))
			c.px(18, 9 + b, Color("#6a7a90"))
		"pixel_shades":
			c.hline(9, 9 + b, 14, Palette.INK)
			c.rect(10, 10 + b, 5, 2, Palette.INK)
			c.rect(17, 10 + b, 5, 2, Palette.INK)
			c.rect(11, 12 + b, 3, 1, Palette.INK)
			c.rect(18, 12 + b, 3, 1, Palette.INK)
			c.px(11, 10 + b, Palette.WHITE)
			c.px(12, 11 + b, Palette.WHITE)
			c.px(18, 10 + b, Palette.WHITE)
			c.px(19, 11 + b, Palette.WHITE)
		"clown_nose":
			c.ellipse(16.0, 13.0 + b, 2.2, 2.0, Color("#e0202a"))
			c.px(15, 12 + b, Palette.WHITE)
		"vr":
			c.rect(9, 8 + b, 14, 5, Color("#e9eaec"))
			c.rect(10, 9 + b, 12, 3, Color("#2a2f3a"))
			c.hline(11, 10 + b, 10, Color("#ff4a3d"))
			c.px(8, 10 + b, Palette.INK)
			c.px(23, 10 + b, Palette.INK)


func _mirror(points: Array, side: int, y: int) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(Vector2(point.x if side == 1 else 32.0 - point.x, point.y + y))
	return result


# --- Hats ----------------------------------------------------------------------


func _hat(b: int, view: int) -> void:
	var kind: String = look["hat"]
	if kind == "":
		return
	var side: bool = view == Dir.SIDE
	var x0: int = 10 if side else 9
	var w: int = 13 if side else 14
	var y: int = b
	match kind:
		"alfa_cap":
			var red: Color = Palette.ALFA_RED
			c.rect(x0, 1 + y, w, 6, red)
			c.hline(x0 + 1, 0 + y, w - 2, red)
			c.hline(x0 + 2, -1 + y, w - 4, red)
			c.rect(x0 + w - 3, 1 + y, 3, 6, Palette.shade(red, 0.12))
			c.hline(x0 + 2, 0 + y, 5, Palette.light(red, 0.2))
			if side:
				c.rect(21, 5 + y, 7, 2, Palette.shade(red, 0.22))
			elif view == Dir.DOWN:
				c.rect(8, 6 + y, 16, 2, Palette.shade(red, 0.22))
				_glyph(MARK_SMALL, 15, 1 + y, Palette.WHITE)
			else:
				c.rect(14, 5 + y, 4, 2, hair)
				c.hline(13, 4 + y, 6, Palette.shade(red, 0.3))
		"beanie":
			var knit: Color = Color("#2b6f8f")
			c.rect(x0 - 1, 0 + y, w + 2, 7, knit)
			c.hline(x0, -1 + y, w, knit)
			for kx: int in range(x0, x0 + w, 2):
				c.vline(kx, 0 + y, 4, Palette.shade(knit, 0.1))
			c.rect(x0 - 1, 5 + y, w + 2, 2, Palette.shade(knit, 0.18))
			c.ellipse(x0 + w / 2.0, -2.5 + y, 2.5, 2.5, Palette.WHITE)
		"crown":
			c.rect(x0, 2 + y, w, 4, GOLD)
			c.hline(x0, 5 + y, w, GOLD_DARK)
			for spike: int in 3:
				var sx: float = x0 + 1.5 + spike * (w - 3) / 2.0
				c.polygon(PackedVector2Array([Vector2(sx - 2.5, 3 + y), Vector2(sx, -3 + y), Vector2(sx + 2.5, 3 + y)]), GOLD)
				c.px(roundi(sx) - 1, -2 + y, Palette.light(GOLD, 0.3))
			c.px(x0 + w / 2, 3 + y, Palette.ALFA_RED)
			c.px(x0 + 2, 3 + y, Color("#5ac8d8"))
			c.px(x0 + w - 3, 3 + y, Color("#4f9a4a"))
		"cowboy":
			var leather: Color = Color("#8a5a2a")
			c.rect(x0 - 5, 5 + y, w + 10, 2, Palette.shade(leather, 0.1))
			c.hline(x0 - 6, 6 + y, w + 12, Palette.shade(leather, 0.2))
			c.rect(x0, -1 + y, w, 7, leather)
			c.hline(x0 + w / 2 - 1, -1 + y, 3, Palette.shade(leather, 0.15))
			c.vline(x0 + w - 2, 0 + y, 5, Palette.shade(leather, 0.12))
			c.rect(x0, 3 + y, w, 2, Palette.INK)
		"viking":
			var horn: Color = Color("#efe6cf")
			for horn_side: int in [-1, 1]:
				var base: float = 16.0 + horn_side * 6.0 + (0.5 if side else 0.0)
				c.polygon(PackedVector2Array([
					Vector2(base, 4 + y), Vector2(base + horn_side * 6.0, -1 + y),
					Vector2(base + horn_side * 7.0, -7 + y), Vector2(base + horn_side * 3.5, -2 + y), Vector2(base - horn_side * 1.0, 1 + y),
				]), horn)
			c.rect(x0, 0 + y, w, 6, METAL)
			c.hline(x0 + 1, -1 + y, w - 2, METAL)
			c.hline(x0 + 3, -2 + y, w - 6, METAL)
			c.vline(x0 + 2, -1 + y, 6, Palette.light(METAL, 0.2))
			c.rect(x0 - 1, 5 + y, w + 2, 2, Color("#6b4a2a"))
			for rivet: int in range(x0 + 1, x0 + w, 4):
				c.px(rivet, 5 + y, GOLD)
			if view == Dir.DOWN:
				c.rect(15, 7 + y, 2, 6, METAL)
		"propeller":
			c.rect(x0, 1 + y, w / 2, 6, Palette.ALFA_RED)
			c.rect(x0 + w / 2, 1 + y, w - w / 2, 6, GOLD)
			c.hline(x0 + 1, 0 + y, w - 2, Color("#3a7bd5"))
			c.hline(x0, 6 + y, w, Color("#3a7bd5"))
			var stick_x: int = x0 + w / 2
			c.vline(stick_x, -3 + y, 3, Palette.INK)
			if _col % 2 == 0:
				c.hline(stick_x - 6, -4 + y, 13, Color("#4f9a4a"))
			else:
				c.hline(stick_x - 2, -4 + y, 5, Color("#4f9a4a"))
				c.px(stick_x, -5 + y, Color("#4f9a4a"))
		"party_hat":
			var cone_x: float = x0 + w / 2.0
			for row: int in range(-9, 4):
				var half: float = (row + 9) * 5.0 / 12.0
				var stripe: Color = Color("#d6336c") if (row + 9) % 4 < 2 else GOLD
				c.hline(roundi(cone_x - half), row + y, maxi(1, roundi(half * 2.0)), stripe)
			c.ellipse(cone_x, -10.5 + y, 2.0, 2.0, Color("#5ac8d8"))
		"chef":
			var cloth: Color = Palette.WHITE
			var shade_cloth: Color = Color("#d8d3cb")
			c.rect(x0 + 1, -5 + y, w - 2, 9, cloth)
			c.ellipse(x0 + 3.5, -6.0 + y, 3.5, 3.0, cloth)
			c.ellipse(x0 + w - 3.5, -6.0 + y, 3.5, 3.0, cloth)
			c.ellipse(x0 + w / 2.0, -8.0 + y, 4.0, 3.5, cloth)
			c.vline(x0 + w - 2, -5 + y, 9, shade_cloth)
			c.rect(x0, 3 + y, w, 3, Color("#ece8e0"))
			c.hline(x0, 5 + y, w, shade_cloth)
		"headphones":
			c.hline(x0 + 1, 0 + y, w - 2, Palette.INK)
			c.px(x0, 1 + y, Palette.INK)
			c.px(x0 + w - 1, 1 + y, Palette.INK)
			if side:
				c.ellipse(14.0, 11.0 + y, 2.5, 3.5, Palette.INK)
				c.px(14, 11 + y, Palette.ALFA_RED)
			else:
				for cup_x: int in [6, 23]:
					c.rect(cup_x, 8 + y, 3, 7, Palette.INK)
					c.px(cup_x + 1, 11 + y, Palette.ALFA_RED)
				c.vline(8, 1 + y, 7, Palette.INK)
				c.vline(23, 1 + y, 7, Palette.INK)
		"bucket":
			var canvas_color: Color = Color("#e3d6b8")
			c.rect(x0, 0 + y, w, 6, canvas_color)
			c.hline(x0 + 1, -1 + y, w - 2, canvas_color)
			c.rect(x0 - 3, 5 + y, w + 6, 2, Palette.shade(canvas_color, 0.1))
			c.px(x0 - 3, 7 + y, Palette.shade(canvas_color, 0.1))
			c.px(x0 + w + 2, 7 + y, Palette.shade(canvas_color, 0.1))
			c.hline(x0, 3 + y, w, Color("#3f9e4a"))


# --- Back items and hand items ------------------------------------------------


## view DOWN: behind the body seen from the front; UP: over the back; SIDE: behind a right-facing body.
func _back_item(view: int, b: int) -> void:
	var kind: String = look["back"]
	if kind == "":
		return
	var ty: int = 19 + b
	var flap: int = _col % 2
	match kind:
		"alfa_backpack":
			var red: Color = Palette.ALFA_RED
			if view == Dir.UP:
				c.rect(10, ty + 1, 12, 12, red)
				c.hline(10, ty + 1, 12, Palette.light(red, 0.2))
				c.vline(21, ty + 1, 12, Palette.shade(red, 0.15))
				c.rect(11, ty + 9, 10, 4, Palette.shade(red, 0.12))
				c.hline(14, ty, 4, Palette.INK)
				_glyph(MARK, 14, ty + 2, Palette.WHITE)
			elif view == Dir.SIDE:
				c.rect(7, ty + 1, 6, 12, red)
				c.vline(7, ty + 1, 12, Palette.shade(red, 0.15))
				c.hline(8, ty + 1, 4, Palette.light(red, 0.2))
			else:
				c.rect(8, ty + 1, 16, 11, Palette.shade(red, 0.15))
		"angel_wings", "demon_wings":
			var angel: bool = kind == "angel_wings"
			var fill: Color = Color("#f6f4ef") if angel else Color("#3a1f3e")
			var detail: Color = Color("#cfc8bd") if angel else Color("#7a1f3a")
			if view == Dir.SIDE:
				_wing(PackedVector2Array([Vector2(3, 0), Vector2(-4, -8 - flap), Vector2(-10, -6 - flap), Vector2(-11, 1), Vector2(-7, 9), Vector2(1, 11)]), Vector2i(14, ty + 2), 1, fill, detail, angel)
			else:
				for wing_side: int in [-1, 1]:
					var root: Vector2i = Vector2i(10 if wing_side < 0 else 22, ty + 2)
					_wing(PackedVector2Array([Vector2(0, 0), Vector2(-8, -8 - flap), Vector2(-15, -6 - flap), Vector2(-16, 1), Vector2(-12, 8), Vector2(-5, 11), Vector2(0, 7)]), root, -wing_side, fill, detail, angel)
		"jetpack":
			var tanks: Array[int] = [9, 17]
			if view == Dir.SIDE:
				tanks = [6]
			for tank_x: int in tanks:
				c.rect(tank_x, ty, 6, 12, METAL)
				c.vline(tank_x + 1, ty + 1, 10, Palette.light(METAL, 0.25))
				c.vline(tank_x + 5, ty, 12, Palette.shade(METAL, 0.2))
				c.rect(tank_x, ty - 2, 6, 2, Palette.ALFA_RED)
				c.rect(tank_x + 1, ty + 12, 4, 1, Palette.INK)
				for flame: int in 3 + flap:
					c.hline(tank_x + 1 + flame / 2, ty + 13 + flame, maxi(1, 4 - flame), GOLD if flame < 2 else Color("#ff7a2a"))
		"cape_red":
			var red: Color = Color("#c3161f")
			if view == Dir.UP:
				c.polygon(PackedVector2Array([Vector2(9, ty), Vector2(23, ty), Vector2(26, ty + 22 + flap), Vector2(6, ty + 22 - flap)]), red)
				c.vline(13, ty + 4, 16, Palette.shade(red, 0.15))
				c.vline(19, ty + 4, 16, Palette.shade(red, 0.15))
				c.hline(10, ty, 12, Palette.light(red, 0.2))
			elif view == Dir.SIDE:
				c.polygon(PackedVector2Array([Vector2(12, ty), Vector2(16, ty + 1), Vector2(14, ty + 21), Vector2(3 - flap, ty + 20), Vector2(8, ty + 8)]), red)
				c.line(10, ty + 4, 6, ty + 18, Palette.shade(red, 0.15))
			else:
				c.rect(6, ty + 1, 20, 21, Palette.shade(red, 0.18))
		"guitar":
			var body_color: Color = Color("#c07a3a")
			var neck: Color = Color("#4a2c18")
			if view == Dir.UP:
				c.line(15, ty + 6, 24, ty - 6, neck)
				c.line(16, ty + 6, 25, ty - 6, neck)
				c.rect(23, ty - 9, 3, 4, neck)
				c.ellipse(12.0, ty + 10.0, 5.5, 6.5, body_color)
				c.ellipse(12.0, ty + 9.0, 1.5, 1.5, Palette.INK)
			elif view == Dir.SIDE:
				c.line(10, ty + 4, 3, ty - 8, neck)
				c.ellipse(9.0, ty + 10.0, 4.0, 6.5, body_color)
			else:
				c.line(19, ty + 4, 26, ty - 7, neck)
				c.line(20, ty + 4, 27, ty - 7, neck)
				c.rect(25, ty - 10, 3, 4, neck)


func _wing(shape: PackedVector2Array, root: Vector2i, direction: int, fill: Color, detail: Color, feathered: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in shape:
		points.append(Vector2(root.x + point.x * direction, root.y + point.y))
	c.polygon(points, fill)
	for i: int in 3:
		var tip: Vector2 = Vector2(root.x + (-13 + i * 3) * direction, root.y - 4 + i * 5)
		c.line(root.x, root.y + 1 + i * 2, roundi(tip.x), roundi(tip.y), detail)
	if feathered:
		for i: int in 4:
			c.px(root.x + (-14 + i * 3) * direction, root.y + 3 + i * 2, detail)


func _hr(x: int, y: int, w: int, h: int, color: Color) -> void:
	var left: int = _hand.x + x if _hand_dir > 0 else _hand.x + 1 - x - w + 1
	c.rect(left, _hand.y + y, w, h, color)


func _hand_item(hand: Vector2i, direction: int) -> void:
	var kind: String = look["hand"]
	if kind == "":
		return
	_hand = hand
	_hand_dir = direction
	var hx: int = hand.x
	var hy: int = hand.y
	match kind:
		"alfa_coffee":
			_hr(-1, -5, 4, 6, Palette.WHITE)
			_hr(-1, -6, 4, 1, Palette.INK)
			_hr(-1, -3, 4, 2, Palette.ALFA_RED)
			c.px(hx + 1, hy - 8 - _col % 2, Color(1, 1, 1, 0.7))
		"laptop":
			_hr(-2, -7, 2, 12, Color("#8f949c"))
			_hr(0, -7, 1, 12, Color("#6e737b"))
			_hr(-2, -4, 1, 2, Palette.ALFA_RED)
		"baguette":
			var crust: Color = Color("#d9a060")
			c.line(hx + 1, hy + 4, hx + 1 + 5 * direction, hy - 12, crust)
			c.line(hx + 2, hy + 4, hx + 2 + 5 * direction, hy - 12, Palette.shade(crust, 0.12))
			for score: int in 3:
				c.px(hx + 1 + (score + 1) * direction, hy - 1 - score * 4, Color("#f2d49a"))
		"alfa_flag":
			_hr(1, -19, 1, 22, Color("#8f949c"))
			for column: int in 10:
				var wave: int = 1 if (column + _col) % 4 >= 2 else 0
				_hr(2 + column, -19 + wave, 1, 7, Palette.ALFA_RED)
				for row: int in MARK_SMALL.size():
					var glyph_column: int = column - 4
					if glyph_column >= 0 and glyph_column < 3 and MARK_SMALL[row][glyph_column] == "X":
						_hr(2 + column, -18 + wave + row, 1, 1, Palette.WHITE)
		"balloon":
			var sway: int = 1 if _col % 3 == 1 else 0
			var bx: float = hx + 1 + 5 * direction + sway
			var by: float = -9.0 + float(_col % 2)
			c.line(hx + 1, hy, roundi(bx), roundi(by + 6.0), Color("#d8d1c6"))
			c.ellipse(bx, by, 4.5, 5.5, Palette.ALFA_RED)
			c.ellipse(bx - 1.5, by - 2.0, 1.2, 1.8, Palette.light(Palette.ALFA_RED, 0.35))
			c.px(roundi(bx), roundi(by + 5.5), RED_DARK)
		"rubber_chicken":
			var yellow: Color = Color("#f6d44a")
			_hr(-1, 2, 3, 6, yellow)
			_hr(0, -6, 2, 7, yellow)
			_hr(-1, -9, 3, 3, yellow)
			_hr(2, -8, 2, 1, Color("#f28a1a"))
			_hr(-1, -10, 2, 1, Palette.ALFA_RED)
			_hr(0, -8, 1, 1, Palette.INK)
			_hr(-1, 8, 1, 2, Color("#f28a1a"))
			_hr(1, 8, 1, 2, Color("#f28a1a"))
		"briefcase":
			var leather: Color = Color("#6b3f24")
			_hr(-3, 2, 8, 6, leather)
			_hr(-3, 7, 8, 1, Palette.shade(leather, 0.2))
			_hr(-1, 1, 4, 1, Palette.INK)
			_hr(0, 4, 2, 1, GOLD)
		"umbrella":
			var cx: int = hx + 1 + 4 * direction
			c.line(hx + 1, hy + 1, cx, -2, Palette.INK)
			c.polygon(PackedVector2Array([
				Vector2(cx - 12, 1), Vector2(cx - 9, -5), Vector2(cx, -9), Vector2(cx + 9, -5), Vector2(cx + 12, 1),
			]), Palette.ALFA_RED)
			c.line(cx, -8, cx - 6, 0, Palette.shade(Palette.ALFA_RED, 0.18))
			c.line(cx, -8, cx + 6, 0, Palette.shade(Palette.ALFA_RED, 0.18))
			for scallop: int in range(-11, 12, 4):
				c.px(cx + scallop, 1, Palette.WHITE)
			c.vline(cx, -11, 2, Palette.INK)
		"fish":
			var scales: Color = Color("#7aa0b8")
			c.ellipse(hx + 1.0, hy + 7.0, 2.2, 4.5, scales)
			c.vline(hx + 1, hy + 4, 6, Palette.light(scales, 0.25))
			c.polygon(PackedVector2Array([Vector2(hx - 2, hy + 14), Vector2(hx + 4, hy + 14), Vector2(hx + 1, hy + 10)]), Palette.shade(scales, 0.1))
			c.px(hx + 1, hy + 4, Palette.INK)
		"pizza":
			var cheese: Color = Color("#f2c230")
			c.polygon(PackedVector2Array([Vector2(hx - 2, hy - 1), Vector2(hx + 5, hy - 1), Vector2(hx + 1.5, hy + 8)]), cheese)
			c.hline(hx - 2, hy - 1, 7, Color("#c9853a"))
			c.px(hx, hy + 1, Palette.ALFA_RED)
			c.px(hx + 2, hy + 3, Palette.ALFA_RED)


# --- Side (facing right) -----------------------------------------------------


func _side(b: int, leg: int, walking: bool) -> void:
	var ty: int = 19 + b
	var stride: int = leg * 3
	var hip: int = 33 + b
	var near_lift: int = 1 if walking and leg == 0 else 0
	_back_item(Dir.SIDE, b)
	var bottom: String = look["bottom"]
	var knee: int = hip + (6 if bottom == "shorts" else (0 if bottom == "skirt" or _bare_legs() else 99))
	for pass_index: int in 2:
		var near: bool = pass_index == 1
		var offset: int = stride if near else -stride
		var foot_y: int = 45 - (near_lift if near else 0)
		for y: int in range(hip, foot_y):
			var t: float = float(y - hip) / maxf(1.0, foot_y - hip)
			var x: int = roundi(lerpf(14, 14 + offset, t))
			if y < knee:
				c.rect(x, y, 5, 1, pants if near else pants_s)
				if near and bottom == "track":
					c.px(x + 2, y, Palette.WHITE)
			else:
				c.rect(x + 1, y, 3, 1, skin if near else skin_s)
		_shoe(14 + offset, foot_y, 7, near)
	if bottom == "skirt" and not _bare_legs():
		c.polygon(PackedVector2Array([Vector2(11, hip - 1), Vector2(21, hip - 1), Vector2(23, hip + 7), Vector2(9, hip + 7)]), pants)
		c.hline(10, hip + 6, 13, pants_s)
	var arm: int = -leg if walking else 0
	# Far arm behind the torso.
	c.line(16, ty + 2, 16 - arm * 2, ty + 11, top_s)
	c.line(17, ty + 2, 17 - arm * 2, ty + 11, top_s)
	c.rect(16 - arm * 2, ty + 11, 2, 2, skin_s)
	var torso_h: int = 21 if look["top"] == "robe" else 14
	c.rect(12, ty + 1, 9, torso_h, top)
	c.hline(13, ty, 7, top)
	c.vline(12, ty + 1, torso_h, top_s)
	if torso_h == 14:
		c.hline(12, ty + 14, 9, pants_s)
	var style: String = _top_style()
	if OPEN_TOPS.has(style):
		c.vline(20, ty + 1, 13, inner)
		c.vline(19, ty + 1, 4, top_s)
	elif style == "hoodie":
		c.rect(11, ty - 1, 5, 5, top_s)
		c.hline(15, ty + 9, 5, top_s)
	match look["top"]:
		"robe":
			c.hline(12, ty + 9, 9, top_s)
			c.vline(20, ty + 1, 6, skin)
			c.hline(12, ty + 21, 9, top_s)
		"armor":
			_armor_plates(ty, 12, 9)
		"hawaiian":
			for spot: Vector2i in [Vector2i(14, 4), Vector2i(18, 8), Vector2i(15, 11)]:
				c.px(spot.x, ty + spot.y, GOLD)
				c.px(spot.x + 1, ty + spot.y, Color("#f59ab0"))
		"sweater_xmas":
			for x: int in range(12, 21):
				c.px(x, ty + 3 + x % 2, Palette.WHITE)
				c.px(x, ty + 11 + (x + 1) % 2, Palette.WHITE)
		"tuxedo":
			c.rect(20, ty + 1, 2, 2, Palette.INK)
		"alfa_tee":
			_glyph(MARK_SMALL, 17, ty + 4, Palette.ALFA_RED)
	if look["tie"] != "":
		c.vline(20, ty + 2, 8, Color(look["tie"]))
	if look["scarf"] != "":
		c.rect(15, ty, 6, 2, Color(look["scarf"]))
		c.rect(20, ty + 2, 2, 4, Color(look["scarf"]))
	if look["badge"] and not NO_BADGE_TOPS.has(look["top"]):
		c.rect(20, ty + 7, 2, 4, Palette.WHITE)
		c.px(20, ty + 7, Palette.ALFA_RED)
	if look["back"] == "alfa_backpack":
		c.line(13, ty + 1, 19, ty + 9, RED_DARK)
	# Near arm.
	for step: int in 10:
		var t: float = step / 9.0
		var x: int = roundi(lerpf(15, 15 + arm * 2, t))
		c.rect(x, ty + 2 + step, 3, 1, skin if _short_sleeves() and step > 3 else top)
		if look["top"] == "tracksuit":
			c.px(x + 1, ty + 2 + step, Palette.WHITE)
	if look["top"] == "armor":
		c.ellipse(16.5, ty + 2.5, 3.0, 2.5, top_l)
	c.rect(15 + arm * 2, ty + 12, 3, 2, skin)
	c.rect(15, ty - 2, 4, 3, skin_s)
	if look["headphones"]:
		c.rect(14, ty - 1, 6, 2, Palette.INK)
	_head_side(b)
	_hat(b, Dir.SIDE)
	_hand_item(Vector2i(15 + arm * 2, ty + 12), 1)


func _head_side(b: int) -> void:
	var style: String = look["hair"]
	if style == "afro" and look["mask"] == "":
		c.ellipse(13.5, 7.5 + b, 10.0, 8.5, hair_s)
		c.ellipse(13.0, 7.0 + b, 9.5, 8.0, hair)
	c.ellipse(16.0, 11.0 + b, 6.5, 7.5, skin_s)
	c.ellipse(16.5, 10.5 + b, 6.0, 7.0, skin)
	c.rect(23, 11 + b, 1, 2, skin)
	c.px(23, 12 + b, skin_s)
	if look["mask"] != "":
		_mask_side(b)
		return
	for y: int in range(2 + b, 17 + b):
		for x: int in range(8, 24):
			if c.get_px(x, y).a <= 0.0:
				continue
			var back: bool = x <= 15 and y <= 12 + b
			var top_cap: bool = y <= 5 + b + (1 if x > 19 else 0)
			if style == "bald":
				back = x <= 12 and y >= 8 + b and y <= 12 + b
				top_cap = false
			if back or top_cap:
				var shaved: bool = (style == "buzz" or style == "mohawk") and (x + y) % 2 != 0
				c.px(x, y, skin_s if shaved else hair)
	c.hline(12, 3 + b, 5, hair_l if style != "bald" else Palette.light(skin, 0.2))
	match style:
		"long":
			c.rect(9, 8 + b, 6, 14, hair)
		"ponytail":
			c.rect(7, 8 + b, 3, 10, hair)
			c.px(9, 8 + b, Palette.ALFA_RED)
		"bun":
			c.ellipse(10.0, 4.5 + b, 3.0, 3.0, hair)
		"curly":
			for y: int in range(3 + b, 13 + b, 2):
				c.px(8, y, hair)
		"mohawk":
			for x: int in range(10, 21, 2):
				c.rect(x, -2 + b + absi(15 - x) / 3, 2, 6, hair)
			c.hline(10, 3 + b, 11, hair_s)
	c.rect(15, 10 + b, 2, 3, skin_s)
	c.hline(19, 8 + b, 3, hair_s)
	c.rect(20, 10 + b, 1, 2, EYE)
	c.hline(20, 15 + b, 2, lip)
	if look["beard"]:
		c.rect(16, 14 + b, 7, 4, hair_s)
		c.hline(20, 15 + b, 2, lip)
	if look["mustache"]:
		c.hline(20, 14 + b, 3, hair)
	if look["glasses"]:
		c.hline(19, 9 + b, 4, Palette.INK)
		c.hline(19, 12 + b, 4, Palette.INK)
		c.vline(22, 9 + b, 4, Palette.INK)
		c.hline(15, 10 + b, 4, Palette.INK)
	match look["face_item"]:
		"sunglasses":
			c.rect(19, 9 + b, 4, 3, Palette.INK)
			c.hline(14, 10 + b, 5, Palette.INK)
		"pixel_shades":
			c.hline(14, 9 + b, 10, Palette.INK)
			c.rect(19, 10 + b, 5, 2, Palette.INK)
			c.px(20, 10 + b, Palette.WHITE)
		"clown_nose":
			c.ellipse(23.5, 12.5 + b, 2.0, 2.0, Color("#e0202a"))
		"vr":
			c.rect(17, 8 + b, 7, 5, Color("#e9eaec"))
			c.rect(22, 9 + b, 2, 3, Color("#2a2f3a"))
			c.hline(10, 10 + b, 7, Palette.INK)


func _mask_side(b: int) -> void:
	c.ellipse(16.0, 11.0 + b, 7.0, 7.5, mask_s)
	c.ellipse(16.5, 10.5 + b, 6.5, 7.0, mask)
	c.hline(9, 10 + b, 3, Palette.INK)
	match look["mask"]:
		"fox":
			c.polygon(PackedVector2Array([Vector2(20, 12 + b), Vector2(26, 14 + b), Vector2(20, 17 + b)]), mask_l)
			c.px(25, 14 + b, Palette.INK)
			c.polygon(PackedVector2Array([Vector2(11, 1 + b), Vector2(16, 4 + b), Vector2(12, 7 + b)]), mask)
		"raccoon":
			c.rect(17, 9 + b, 6, 3, Palette.shade(mask, 0.4))
			c.rect(21, 13 + b, 3, 3, mask_l)
			c.ellipse(12.0, 4.0 + b, 2.5, 2.5, mask_s)
		"deer":
			c.line(13, 4 + b, 10, 0 + b, Palette.shade(mask, 0.45))
			c.line(12, 2 + b, 8, 2 + b, Palette.shade(mask, 0.45))
			c.rect(21, 13 + b, 3, 4, mask_l)
			c.px(23, 13 + b, Palette.INK)
		"cat":
			c.polygon(PackedVector2Array([Vector2(12, 1 + b), Vector2(17, 5 + b), Vector2(11, 8 + b)]), mask)
			c.hline(21, 14 + b, 4, mask_s)
	var eye_color: Color = Color("#f7e04a") if look["mask"] == "cat" else Palette.INK
	c.rect(19, 10 + b, 2, 2, eye_color)
