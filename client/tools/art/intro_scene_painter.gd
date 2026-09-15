class_name IntroScenePainter
extends RefCounted
## Paints the side-view intro backgrounds, overlays and repeating layers listed in IntroArt.IMAGES.
## Rooms share one layout: ceiling to y 34, back wall to 116, floor below. Characters stand at y 146.

const W: int = 320
const FLOOR_ROWS: Array[int] = [116, 118, 121, 125, 130, 136, 143, 151, 160, 170, 180]
const INK: Color = Color("#24222a")
const METAL: Color = Color("#8f949c")
const WOOD: Color = Color("#a8794f")
const RED: Color = Color("#ef3124")
const WHITE: Color = Color("#fbfaf8")

const MARK_OUTER: PackedVector2Array = [Vector2(0.36, 0.0), Vector2(0.64, 0.0), Vector2(0.95, 0.72), Vector2(0.05, 0.72)]
const MARK_COUNTER: PackedVector2Array = [Vector2(0.5, 0.2), Vector2(0.6, 0.45), Vector2(0.4, 0.45)]
const MARK_GAP: PackedVector2Array = [Vector2(0.36, 0.58), Vector2(0.64, 0.58), Vector2(0.70, 0.72), Vector2(0.30, 0.72)]
const MARK_BAR: Rect2 = Rect2(0.05, 0.82, 0.9, 0.18)

var c: PixelCanvas
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func paint(id: String) -> Image:
	c = PixelCanvas.create(IntroArt.IMAGES[id])
	rng.seed = hash(id)
	match id:
		"bedroom":
			_bedroom()
		"bedroom_blanket":
			_blanket()
		"bathroom":
			_bathroom()
		"home_kitchen":
			_home_kitchen()
		"kitchen_table":
			_kitchen_table()
		"parking":
			_parking()
		"autobahn_sky":
			_autobahn_sky()
		"autobahn_far":
			_autobahn_far()
		"autobahn_mid":
			_autobahn_mid()
		"autobahn_road":
			_autobahn_road()
		"autobahn_rail":
			_autobahn_rail()
		"city_sky":
			_city_sky()
		"city_far":
			_city_far()
		"city_near":
			_city_near()
		"city_road":
			_city_road()
		"office_exterior":
			_office_exterior()
	return c.image


# --- Helpers ---------------------------------------------------------------------


## Solid object with a 1 px outline, top highlight and bottom/right shade.
func _obj(x: int, y: int, w: int, h: int, color: Color) -> void:
	c.rect(x - 1, y - 1, w + 2, h + 2, Palette.outline_of(color, 0.55))
	c.rect(x, y, w, h, color)
	c.hline(x, y, w, Palette.light(color, 0.1))
	c.hline(x, y + h - 1, w, Palette.shade(color, 0.12))
	c.vline(x + w - 1, y, h, Palette.shade(color, 0.08))


func _mark(x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy: int in h:
		for xx: int in w:
			var p: Vector2 = Vector2((xx + 0.5) / w, (yy + 0.5) / h)
			var in_letter: bool = (
				Geometry2D.is_point_in_polygon(p, MARK_OUTER)
				and not Geometry2D.is_point_in_polygon(p, MARK_COUNTER)
				and not Geometry2D.is_point_in_polygon(p, MARK_GAP)
			)
			if in_letter or MARK_BAR.has_point(p):
				c.px(x + xx, y + yy, color)


func _wrap_rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	for offset: int in [-W, 0, W]:
		c.rect(x + offset, y, w, h, color)


func _wrap_ellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for offset: int in [-W, 0, W]:
		c.ellipse(cx + offset, cy, rx, ry, color)


func _poly(points: Array, color: Color, dx: int = 0, dy: int = 0) -> void:
	var packed: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		packed.append(point + Vector2(dx, dy))
	c.polygon(packed, color)


func _room(ceiling: Color, wall: Color, floor_kind: String, floor_color: Color) -> void:
	c.rect(0, 0, W, 34, ceiling)
	c.hline(0, 32, W, Palette.shade(ceiling, 0.06))
	c.hline(0, 33, W, Palette.shade(ceiling, 0.14))
	c.rect(0, 34, W, 78, wall)
	for y: int in 6:
		c.hline(0, 34 + y, W, Color(0, 0, 0, 0.07 * (1.0 - y / 6.0)))
	var board: Color = wall.lerp(WHITE, 0.6)
	c.rect(0, 110, W, 6, board)
	c.hline(0, 110, W, Palette.shade(wall, 0.12))
	c.hline(0, 115, W, Palette.shade(board, 0.2))
	_floor(floor_kind, floor_color)
	for y: int in 5:
		c.hline(0, 116 + y, W, Color(0.1, 0.05, 0.05, 0.14 * (1.0 - y / 5.0)))


func _floor(kind: String, base: Color) -> void:
	for i: int in FLOOR_ROWS.size() - 1:
		var y0: int = FLOOR_ROWS[i]
		var h: int = FLOOR_ROWS[i + 1] - y0
		match kind:
			"wood":
				c.rect(0, y0, W, h, base if i % 2 == 0 else Palette.shade(base, 0.04))
				c.hline(0, y0, W, Palette.shade(base, 0.15))
				var x: int = rng.randi_range(0, 30)
				while x < W:
					c.vline(x, y0, h, Palette.shade(base, 0.13))
					x += rng.randi_range(40, 72)
				for k: int in h:
					if h > 2:
						c.hline(rng.randi_range(0, W - 16), y0 + rng.randi_range(1, h - 1), rng.randi_range(4, 14), Palette.shade(base, 0.05))
			"tile":
				c.rect(0, y0, W, h, base)
				c.hline(0, y0, W, Palette.shade(base, 0.12))
				var tile_w: int = 14 + i * 6
				var shift: int = tile_w / 2 if i % 2 == 1 else 0
				for x: int in range(-shift, W, tile_w):
					c.vline(x, y0, h, Palette.shade(base, 0.1))
				c.hline(0, y0 + 1, W, Palette.light(base, 0.05))


func _window(x: int, y: int, w: int, h: int, top: Color, bottom: Color, city: Color) -> void:
	_obj(x - 3, y - 3, w + 6, h + 6, Color("#f4f1ec"))
	c.gradient(x, y, w, h, top, bottom, 6)
	if city.a > 0.0:
		var bx: int = x
		while bx < x + w:
			var bw: int = rng.randi_range(4, 9)
			var bh: int = rng.randi_range(h / 5, h / 2)
			c.rect(bx, y + h - bh, mini(bw, x + w - bx), bh, city)
			for wy: int in range(y + h - bh + 2, y + h - 1, 3):
				if rng.randf() < 0.5:
					c.px(bx + 1, wy, Color(1.0, 0.9, 0.6, 0.6))
			bx += bw + 1
	c.vline(x + w / 2, y, h, Color("#f4f1ec"))
	c.hline(x, y + h / 2, w, Color("#f4f1ec"))
	c.line(x + 3, y + h - 4, x + 12, y + 3, Color(1, 1, 1, 0.35))
	_obj(x - 5, y + h + 3, w + 10, 3, Color("#ece6dc"))


func _curtain(x: int, y: int, w: int, h: int, color: Color) -> void:
	for i: int in w:
		var column: Color = color if (i / 2) % 2 == 0 else Palette.shade(color, 0.12)
		c.vline(x + i, y, h - (2 if i % 3 == 0 else 0), column)
	c.hline(x, y + h - 1, w, Palette.shade(color, 0.22))


func _picture(x: int, y: int, w: int, h: int, top: Color, bottom: Color) -> void:
	c.rect(x - 2, y - 2, w + 4, h + 4, Color("#5a3a26"))
	c.rect(x - 1, y - 1, w + 2, h + 2, Color("#f4efe6"))
	c.gradient(x, y, w, h, top, bottom, 4)


func _books(x: int, base_y: int, w: int) -> void:
	var bx: int = x
	while bx < x + w - 2:
		var bw: int = rng.randi_range(2, 3)
		var bh: int = rng.randi_range(6, 9)
		var hue: Color = Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.6), rng.randf_range(0.5, 0.85))
		if rng.randf() < 0.15:
			hue = RED
		c.rect(bx, base_y - bh, bw, bh, hue)
		c.px(bx, base_y - bh + 2, Palette.light(hue, 0.25))
		bx += bw
	c.rect(x - 2, base_y, w + 4, 2, Color("#8a5f3c"))


func _plant(cx: int, base_y: int, size: int) -> void:
	_obj(cx - size / 2, base_y - size / 2, size, size / 2, Color("#c9754a"))
	for i: int in size * 2:
		var angle: float = rng.randf_range(-2.8, -0.35)
		var length: float = rng.randf_range(0.4, 1.0) * size
		var tip: Vector2 = Vector2(cx, base_y - size / 2) + Vector2(cos(angle), sin(angle)) * length
		c.line(cx, base_y - size / 2, roundi(tip.x), roundi(tip.y), Color("#3f7f45"))
		c.ellipse(tip.x, tip.y, 2.0, 1.3, Color("#5fae5a") if i % 3 else Color("#8bd07a"))


func _tree(cx: int, base_y: int, height: int) -> void:
	c.rect(cx - 2, base_y - height / 2, 4, height / 2, Color("#6b4a36"))
	c.vline(cx + 1, base_y - height / 2, height / 2, Color("#553a2a"))
	var greens: Array[Color] = [Color("#3f7f45"), Color("#4f9a4a"), Color("#66b35a")]
	for layer: int in 3:
		for i: int in 6:
			var ox: float = rng.randf_range(-height * 0.32, height * 0.32)
			var oy: float = rng.randf_range(-height * 0.25, height * 0.12) - layer * 3
			c.ellipse(cx + ox, base_y - height * 0.66 + oy, rng.randf_range(6, 10), rng.randf_range(5, 8), greens[layer])


func _cloud(cx: int, cy: int, w: int, color: Color) -> void:
	for i: int in 5:
		c.ellipse(cx - w / 2.0 + i * w / 4.0, cy - (2.0 if i % 2 == 1 else 0.0), w / 5.0 + 2.0, 3.5 + (i % 2) * 1.5, color)
	c.hline(cx - w / 2, cy + 3, w, Palette.shade(color, 0.05))


# --- Home ------------------------------------------------------------------------


func _bedroom() -> void:
	_room(Color("#e9e3da"), Color("#c9d4e2"), "wood", Color("#b98a5e"))
	for x: int in range(4, W, 10):
		c.vline(x, 40, 70, Color(1, 1, 1, 0.09))
	# Ceiling lamp.
	c.vline(150, 24, 12, INK)
	_poly([Vector2(141, 45), Vector2(145, 36), Vector2(155, 36), Vector2(159, 45)], Color("#f3e3c0"))
	c.ellipse(150, 46, 4, 1.5, Color("#fff6d0"))
	# Window with dawn city and curtains.
	_window(198, 46, 46, 50, Color("#8fb3dc"), Color("#f6c39a"), Color(0.45, 0.48, 0.6, 0.75))
	c.ellipse(232, 86, 5, 5, Color("#ffe29a"))
	c.rect(182, 37, 78, 2, Color("#6b4a36"))
	_curtain(184, 39, 12, 66, Color("#d9594a"))
	_curtain(246, 39, 12, 66, Color("#d9594a"))
	_poly([Vector2(198, 101), Vector2(244, 101), Vector2(238, 158), Vector2(150, 158)], Color(1.0, 0.86, 0.55, 0.13))
	# Wardrobe with a box on top.
	_obj(10, 71, 46, 55, Color("#b98d5e"))
	c.vline(33, 73, 51, Palette.shade(Color("#b98d5e"), 0.2))
	c.rect(29, 96, 2, 6, METAL)
	c.rect(36, 96, 2, 6, METAL)
	c.rect(12, 120, 42, 4, Palette.shade(Color("#b98d5e"), 0.1))
	_obj(16, 62, 22, 8, Color("#d9c3a0"))
	_obj(40, 64, 12, 6, RED)
	# Car poster.
	_picture(66, 52, 24, 32, Color("#ff9a5c"), Color("#7a2a6a"))
	c.ellipse(78, 64, 5, 5, Color("#ffe08a"))
	_poly([Vector2(67, 80), Vector2(71, 76), Vector2(78, 74), Vector2(85, 76), Vector2(89, 79), Vector2(89, 82), Vector2(67, 82)], Color("#1a1420"))
	c.hline(66, 88, 24, WHITE)
	# Nightstand, lamp and clock body (digits are drawn at runtime).
	_obj(96, 110, 26, 16, Color("#8a5a3a"))
	c.hline(98, 117, 22, Palette.shade(Color("#8a5a3a"), 0.2))
	c.rect(108, 113, 3, 2, Color("#d9b04a"))
	c.rect(99, 98, 2, 12, INK)
	_poly([Vector2(95, 99), Vector2(97, 90), Vector2(103, 90), Vector2(105, 99)], Color("#f3e3c0"))
	_obj(107, 102, 15, 8, Color("#26242c"))
	# Bed: headboard, frame, mattress, pillow, footboard.
	_obj(122, 94, 6, 34, Color("#7a5234"))
	_obj(128, 114, 56, 12, Color("#8a5f3c"))
	c.rect(130, 126, 3, 3, INK)
	c.rect(178, 126, 3, 3, INK)
	c.rect(128, 108, 56, 6, Color("#f3f1ec"))
	c.hline(128, 113, 56, Color("#d9dde4"))
	c.ellipse(134, 106, 8, 3.5, Color("#c9d3e3"))
	c.ellipse(133, 105, 7, 2.5, Color("#f5f8fc"))
	_obj(182, 100, 4, 28, Color("#7a5234"))
	# Framed photos above the bed.
	_picture(140, 62, 16, 12, Color("#9fd2ea"), Color("#6f9e6a"))
	_picture(162, 58, 12, 16, Color("#f2d7a8"), Color("#c9754a"))
	# Rug and slippers.
	c.ellipse(238, 148, 50, 7, Color("#e8d8bd"))
	c.ellipse(238, 148, 44, 5, Color("#c8574a"))
	c.ellipse(238, 148, 30, 3, Color("#e8d8bd"))
	c.rect(190, 146, 6, 3, RED)
	c.rect(197, 147, 6, 3, RED)
	# Desk, laptop, chair and shelf.
	_obj(268, 106, 46, 3, Color("#e8e3db"))
	c.rect(270, 109, 2, 19, METAL)
	c.rect(310, 109, 2, 19, METAL)
	c.rect(281, 96, 18, 10, INK)
	c.rect(282, 97, 16, 8, Color("#3a5a8a"))
	c.rect(282, 97, 16, 2, RED)
	c.rect(279, 105, 22, 1, Color("#b9bec6"))
	c.rect(304, 100, 4, 6, WHITE)
	_obj(288, 104, 12, 16, Color("#343a48"))
	c.rect(292, 120, 2, 8, INK)
	_books(264, 64, 44)
	_plant(310, 64, 8)


func _blanket() -> void:
	# Top half: covering the sleeping player. Bottom half: thrown back to the foot of the bed.
	var blue: Color = Color("#3f6fb5")
	var covered: Array = [Vector2(140, 110), Vector2(148, 102), Vector2(170, 100), Vector2(184, 104), Vector2(186, 118), Vector2(140, 118)]
	_poly(covered, Palette.shade(blue, 0.15))
	_poly([Vector2(141, 109), Vector2(148, 103), Vector2(170, 101), Vector2(183, 105), Vector2(184, 115), Vector2(141, 115)], blue)
	for x: int in range(146, 184, 8):
		c.vline(x, 104, 11, Palette.light(blue, 0.12))
	c.hline(141, 110, 42, Palette.light(blue, 0.12))
	c.line(152, 108, 170, 104, Palette.shade(blue, 0.2))
	c.rect(140, 106, 6, 10, Color("#f5f8fc"))
	var bunched: Array = [Vector2(164, 112), Vector2(170, 102), Vector2(182, 99), Vector2(188, 104), Vector2(188, 120), Vector2(162, 120)]
	_poly(bunched, Palette.shade(blue, 0.15), 0, 180)
	_poly([Vector2(166, 111), Vector2(171, 104), Vector2(181, 101), Vector2(186, 105), Vector2(186, 116), Vector2(166, 116)], blue, 0, 180)
	c.line(170, 290, 184, 284, Palette.light(blue, 0.15))
	c.line(168, 294, 185, 290, Palette.shade(blue, 0.2))


func _bathroom() -> void:
	_room(Color("#f2f4f5"), Color("#e6edf0"), "tile", Color("#cfd6db"))
	var grout: Color = Color("#c5d3db")
	c.rect(0, 62, W, 48, Color("#eef4f6"))
	for y: int in range(62, 110, 6):
		c.hline(0, y, W, grout)
		for x: int in range((y / 6) % 2 * 3, W, 6):
			c.vline(x, y, 6, grout)
	c.rect(0, 59, W, 3, Color("#2f4f6f"))
	# Shower cabin.
	_obj(8, 122, 62, 5, WHITE)
	c.vline(38, 40, 16, METAL)
	c.rect(30, 56, 16, 3, METAL)
	for i: int in 5:
		c.vline(32 + i * 3, 60, 2, Color(0.6, 0.8, 0.95, 0.6))
	c.rect(10, 40, 58, 82, Color(0.75, 0.88, 0.95, 0.3))
	c.rect(9, 40, 1, 82, METAL)
	c.rect(68, 40, 1, 82, METAL)
	for i: int in 4:
		c.line(16 + i * 12, 118, 26 + i * 12, 48, Color(1, 1, 1, 0.25))
	# Towel radiator with a red towel.
	for x: int in [80, 91]:
		c.vline(x, 64, 42, METAL)
	for y: int in range(66, 106, 5):
		c.hline(80, y, 12, METAL)
	c.rect(79, 70, 14, 26, Color("#c4251b"))
	c.rect(79, 90, 14, 2, WHITE)
	# Mirror with light strip.
	c.rect(146, 44, 44, 3, Color("#fff6dc"))
	c.rect(146, 47, 44, 3, Color(1.0, 0.96, 0.8, 0.3))
	c.rect(140, 49, 56, 54, Color("#b9bec6"))
	c.gradient(142, 51, 52, 50, Color("#d8e6ec"), Color("#a9c1cd"), 5)
	# Vanity, basin, faucet, cup, soap.
	_obj(142, 108, 52, 20, Color("#f7f7f5"))
	c.vline(168, 110, 16, Color("#d8dcde"))
	c.rect(162, 116, 2, 5, METAL)
	c.rect(172, 116, 2, 5, METAL)
	_obj(140, 104, 56, 4, Color("#c9a071"))
	c.ellipse(168, 103, 12, 2.5, WHITE)
	c.ellipse(168, 103, 9, 1.5, Color("#dfe7ea"))
	c.rect(166, 94, 2, 9, METAL)
	c.rect(166, 94, 6, 2, METAL)
	c.rect(184, 96, 5, 8, Color("#5ac8d8"))
	c.vline(185, 90, 6, RED)
	c.vline(187, 91, 5, Color("#4f9a4a"))
	c.rect(148, 100, 6, 3, Color("#f5c2d0"))
	# Shelf with bottles and a plant.
	c.rect(208, 80, 46, 2, Color("#c9a071"))
	var colors: Array[Color] = [Color("#5ac8d8"), Color("#f5c2d0"), WHITE, Color("#8bd07a"), Color("#f2c230")]
	for i: int in 5:
		var h: int = rng.randi_range(6, 11)
		_obj(212 + i * 7, 80 - h, 4, h, colors[i])
	_plant(250, 80, 7)
	# Washing machine, basket and bath mat.
	_obj(262, 104, 26, 24, Color("#f4f4f4"))
	c.rect(263, 105, 24, 4, Color("#e0e2e4"))
	c.ellipse(275, 118, 7, 7, Color("#9aa0a8"))
	c.ellipse(275, 118, 5, 5, Color("#3a5a7a"))
	c.line(272, 116, 275, 113, Color(1, 1, 1, 0.4))
	_obj(292, 112, 18, 16, Color("#c9a071"))
	for y: int in range(114, 126, 3):
		c.hline(293, y, 16, Palette.shade(Color("#c9a071"), 0.15))
	c.rect(148, 146, 40, 6, Color("#7fb8c9"))
	for x: int in range(148, 188, 3):
		c.px(x, 152, Color("#7fb8c9"))


func _home_kitchen() -> void:
	_room(Color("#efe6d8"), Color("#f1e4cc"), "tile", Color("#d9c7a8"))
	# Subway-tile backsplash.
	c.rect(0, 76, 132, 28, Color("#fbfaf6"))
	for row: int in 6:
		var y: int = 76 + row * 5
		c.hline(0, y, 132, Color("#e0dbd0"))
		for x: int in range((row % 2) * 5, 132, 10):
			c.vline(x, y, 5, Color("#e0dbd0"))
	# Upper cabinets.
	for i: int in 5:
		_obj(8 + i * 24, 40, 23, 30, WOOD)
		c.rect(8 + i * 24 + 3, 43, 17, 24, Palette.light(WOOD, 0.04))
		c.rect(8 + i * 24 + 18, 62, 2, 5, METAL)
	# Counter with oven and hob.
	_obj(8, 104, 120, 24, WOOD)
	for x: int in range(32, 128, 24):
		c.vline(x, 105, 22, Palette.shade(WOOD, 0.2))
	c.rect(56, 104, 24, 24, Color("#3a3a40"))
	c.rect(58, 112, 20, 10, Color("#1a1a20"))
	c.line(60, 120, 66, 113, Color(1, 1, 1, 0.15))
	for x: int in range(59, 78, 5):
		c.px(x, 107, METAL)
	_obj(6, 100, 124, 4, Color("#e8e3db"))
	c.rect(56, 99, 24, 1, INK)
	# Kettle, fruit bowl, toaster.
	c.ellipse(66, 95, 6, 5, Color("#d0312d"))
	c.rect(62, 88, 8, 2, INK)
	c.line(72, 94, 75, 91, Color("#d0312d"))
	c.ellipse(27, 98, 7, 2.5, WHITE)
	c.ellipse(24, 95, 2.5, 2.5, Color("#f2a33a"))
	c.ellipse(28, 94, 2.5, 2.5, Color("#8bc34a"))
	c.ellipse(31, 96, 2.5, 2.5, RED)
	_obj(96, 92, 12, 8, Color("#c9ced6"))
	c.rect(98, 91, 3, 1, INK)
	c.rect(103, 91, 3, 1, INK)
	# Fridge with a small brand magnet.
	_obj(134, 78, 20, 50, Color("#dfe3e8"))
	c.hline(135, 96, 18, Color("#b9bec6"))
	c.rect(150, 84, 2, 8, METAL)
	c.rect(150, 100, 2, 12, METAL)
	c.rect(138, 102, 6, 7, WHITE)
	_mark(139, 103, 4, 5, RED)
	# Window with plants on the sill.
	_window(172, 46, 42, 44, Color("#8ec5ee"), Color("#e6f4fa"), Color(0.62, 0.72, 0.82, 0.8))
	_plant(180, 96, 7)
	_plant(194, 96, 6)
	_plant(206, 96, 7)
	# Hanging lamp over the table.
	c.vline(236, 24, 22, INK)
	_poly([Vector2(225, 55), Vector2(229, 46), Vector2(243, 46), Vector2(247, 55)], Color("#3f7f5a"))
	c.ellipse(236, 56, 8, 2, Color("#ffe7a8"))
	# Wall clock and calendar.
	c.ellipse(292, 52, 7, 7, INK)
	c.ellipse(292, 52, 5.5, 5.5, WHITE)
	c.vline(292, 48, 4, INK)
	c.hline(292, 52, 3, RED)
	_obj(276, 66, 26, 28, WHITE)
	c.rect(276, 66, 26, 6, RED)
	for row: int in 3:
		for col: int in 5:
			c.rect(279 + col * 5, 76 + row * 5, 2, 2, Color("#b9b4ac"))
	c.ellipse(290, 81, 3.5, 3.5, Color(0.94, 0.19, 0.14, 0.0))
	for step: int in 16:
		var angle: float = TAU * step / 16.0
		c.px(roundi(290 + cos(angle) * 3.5), roundi(81 + sin(angle) * 3.5), RED)
	# Chair back behind the seated player, below head height.
	c.rect(222, 117, 28, 3, Color("#8a5f3c"))
	c.rect(222, 117, 3, 14, Color("#8a5f3c"))
	c.rect(247, 117, 3, 14, Color("#8a5f3c"))


func _kitchen_table() -> void:
	var oak: Color = Color("#c9a071")
	c.rect(198, 124, 76, 7, oak)
	c.hline(198, 124, 76, Palette.light(oak, 0.15))
	c.rect(197, 123, 78, 1, Palette.outline_of(oak, 0.5))
	_obj(198, 131, 76, 5, WOOD)
	c.rect(202, 136, 4, 18, Palette.shade(WOOD, 0.1))
	c.rect(266, 136, 4, 18, Palette.shade(WOOD, 0.1))
	c.rect(224, 124, 24, 7, Color(0.94, 0.19, 0.14, 0.85))
	c.ellipse(236, 127, 11, 3, Color("#d9dde2"))
	c.ellipse(236, 126.5, 10, 2.5, WHITE)
	c.rect(252, 118, 6, 8, RED)
	c.rect(258, 120, 2, 4, RED)
	c.rect(253, 118, 4, 1, Color("#5a3a22"))
	c.rect(212, 116, 5, 9, Color(1.0, 0.7, 0.2, 0.9))
	c.rect(212, 116, 5, 1, WHITE)
	c.rect(262, 126, 8, 3, WHITE)


func _parking() -> void:
	c.gradient(0, 0, W, 142, Color("#7fb6e6"), Color("#d6ebf6"), 8)
	_cloud(170, 30, 50, Color(1, 1, 1, 0.85))
	_cloud(270, 46, 36, Color(1, 1, 1, 0.75))
	var x: int = 96
	while x < W:
		var bw: int = rng.randi_range(14, 30)
		var bh: int = rng.randi_range(30, 70)
		c.rect(x, 132 - bh, bw, bh, Color("#a9b8c8"))
		for wy: int in range(132 - bh + 4, 128, 6):
			for wx: int in range(x + 3, x + bw - 2, 5):
				c.rect(wx, wy, 2, 3, Color("#c3d0dc"))
		x += bw + rng.randi_range(0, 4)
	# Apartment block.
	var facade: Color = Color("#dccbb0")
	c.rect(0, 18, 104, 114, facade)
	c.vline(103, 18, 114, Palette.shade(facade, 0.2))
	for floor_index: int in 5:
		var y: int = 24 + floor_index * 20
		c.hline(0, y - 3, 104, Palette.shade(facade, 0.08))
		for col: int in 4:
			if floor_index == 4 and (col == 1 or col == 2):
				continue
			var wx: int = 6 + col * 25
			_obj(wx, y, 14, 12, Color("#f4f1ec"))
			var lit: bool = rng.randf() < 0.3
			c.gradient(wx + 1, y + 1, 12, 10, Color("#8fb6d6") if not lit else Color("#ffe7a8"), Color("#5a7a96") if not lit else Color("#e8b870"), 3)
			c.vline(wx + 7, y + 1, 10, Color("#f4f1ec"))
			if rng.randf() < 0.5:
				c.rect(wx + 1, y + 1, 3, 10, Color.from_hsv(rng.randf(), 0.4, 0.8))
			c.rect(wx - 1, y + 12, 16, 2, Color("#b9b0a0"))
	_obj(30, 97, 36, 4, Color("#9aa0a8"))
	c.rect(44, 92, 8, 3, Color("#fff4cf"))
	_obj(38, 102, 20, 30, Color("#6e4a36"))
	c.rect(42, 106, 12, 8, Color("#3a4a5a"))
	c.rect(54, 116, 2, 4, METAL)
	c.rect(62, 108, 3, 5, Color("#4a4f58"))
	_obj(70, 104, 10, 7, Color("#3a6fb5"))
	c.rect(74, 106, 2, 3, WHITE)
	c.rect(34, 132, 32, 2, Color("#b9b4ac"))
	# Trees and fence.
	_tree(124, 128, 44)
	_tree(152, 130, 38)
	for fx: int in range(108, 172, 4):
		c.vline(fx, 120, 12, Color("#3f7f5a"))
	c.hline(108, 120, 64, Color("#3f7f5a"))
	# Bins.
	_obj(84, 122, 8, 10, Color("#3f7f45"))
	_obj(94, 122, 8, 10, Color("#3a6fb5"))
	# Sidewalk, curb, asphalt and parking lines.
	c.rect(0, 132, W, 8, Color("#c9c4bc"))
	for jx: int in range(10, W, 20):
		c.vline(jx, 132, 8, Color("#b5b0a8"))
	c.rect(0, 140, W, 2, Color("#e3ded6"))
	c.rect(0, 142, W, 38, Color("#5a5d64"))
	for i: int in 160:
		c.px(rng.randi_range(0, W - 1), rng.randi_range(142, 179), Color("#676a72") if i % 2 else Color("#4f5258"))
	c.ellipse(120, 156, 16, 3, Color("#8fb3cf"))
	c.ellipse(116, 155, 6, 1, Color("#d6ebf6"))
	for lx: int in [162, 314]:
		c.line(lx, 162, lx + 6, 144, WHITE)
		c.line(lx + 1, 162, lx + 7, 144, WHITE)
	# Street lamp.
	c.rect(311, 44, 3, 96, Color("#3a3f46"))
	c.rect(300, 44, 12, 2, Color("#3a3f46"))
	c.rect(298, 46, 8, 3, Color("#fff4cf"))


# --- Autobahn at night in the rain -------------------------------------------------


func _autobahn_sky() -> void:
	c.gradient(0, 0, W, 120, Color("#0a0d1a"), Color("#2a2540"), 8)
	c.rect(0, 120, W, 60, Color("#1a1a28"))
	for y: int in 26:
		c.hline(0, 90 + y, W, Color(0.45, 0.25, 0.4, 0.14 * (y / 26.0)))
	for i: int in 9:
		var cx: float = rng.randf_range(0, W)
		var cy: float = rng.randf_range(18, 70)
		for k: int in 4:
			c.ellipse(cx + k * 14, cy + (k % 2) * 3, 16, 7, Color("#141a2c"))
			c.ellipse(cx + k * 14, cy - 3 + (k % 2) * 3, 12, 3, Color("#232a40"))


func _autobahn_far() -> void:
	for x: int in W:
		var ridge: float = 16.0 + 6.0 * sin(TAU * x / W * 2.0) + 3.0 * sin(TAU * x / W * 7.0)
		c.vline(x, roundi(ridge), 44 - roundi(ridge), Color("#141726"))
		if x % 5 == 0:
			c.ellipse(x, ridge, 3, 2, Color("#141726"))
	for i: int in 40:
		var lx: int = rng.randi_range(0, W - 1)
		var ly: int = rng.randi_range(28, 42)
		c.px(lx, ly, Color("#ffcf73") if i % 3 else Color("#f4f6ff"))
	c.vline(210, 2, 20, Color("#2a2e40"))
	c.px(210, 2, Color("#ff3b30"))


func _autobahn_mid() -> void:
	for lamp_x: int in [40, 120, 200, 280]:
		for i: int in 3:
			_wrap_ellipse(lamp_x + 12, 11, 6 + i * 7, 4 + i * 5, Color(1.0, 0.7, 0.28, 0.2 / (i + 1)))
		_poly([Vector2(lamp_x + 8, 12), Vector2(lamp_x + 16, 12), Vector2(lamp_x + 30, 62), Vector2(lamp_x - 6, 62)], Color(1.0, 0.8, 0.4, 0.05))
		c.rect(lamp_x, 8, 2, 56, Color("#2c2f38"))
		c.rect(lamp_x, 8, 13, 2, Color("#2c2f38"))
		c.rect(lamp_x + 8, 10, 8, 2, Color("#ffcf73"))
	c.rect(0, 62, W, 14, Color("#3a3d46"))
	c.hline(0, 62, W, Color("#5a5e68"))
	c.hline(0, 70, W, Color("#2c2e35"))
	for rx: int in range(8, W, 20):
		c.px(rx, 66, Color("#f2c230"))


func _autobahn_road() -> void:
	c.rect(0, 0, W, 50, Color("#23252c"))
	c.rect(0, 0, W, 2, Color("#34373f"))
	for x: int in range(0, W, 40):
		c.rect(x, 19, 20, 1, Color("#d8dce4"))
	c.hline(0, 41, W, Color("#d8dce4"))
	c.rect(0, 42, W, 8, Color("#1c1d22"))
	for i: int in 90:
		c.hline(rng.randi_range(0, W - 12), rng.randi_range(3, 40), rng.randi_range(3, 12), Color(0.6, 0.7, 0.9, 0.07))
	for column: int in [52, 132, 212, 292]:
		for y: int in range(3, 40, 2):
			if rng.randf() < 0.55:
				c.hline(column + rng.randi_range(-2, 2), y, rng.randi_range(2, 5), Color(1.0, 0.7, 0.3, 0.14))


func _autobahn_rail() -> void:
	for x: int in range(0, W, 40):
		c.rect(x, 4, 3, 10, Color("#2a2c33"))
	c.rect(0, 2, W, 4, Color("#8a9099"))
	c.hline(0, 2, W, Color("#c9ced6"))
	c.hline(0, 5, W, Color("#5a5f68"))
	for i: int in 40:
		c.px(rng.randi_range(0, W - 1), rng.randi_range(2, 4), WHITE)


# --- City traffic -----------------------------------------------------------------


func _city_sky() -> void:
	c.gradient(0, 0, W, 130, Color("#9fbfe0"), Color("#e4ecf2"), 8)
	c.rect(0, 130, W, 50, Color("#e4ecf2"))
	_cloud(60, 30, 44, Color(1, 1, 1, 0.8))
	_cloud(220, 22, 60, Color(1, 1, 1, 0.7))


func _city_far() -> void:
	var widths: Array[int] = [34, 22, 40, 28, 46, 30, 38, 26, 56]
	var x: int = 0
	for index: int in widths.size():
		var bw: int = widths[index]
		var bh: int = rng.randi_range(40, 86)
		var color: Color = [Color("#a9b7c6"), Color("#96a6b8"), Color("#b6c2cf"), Color("#8c9bb0")][index % 4]
		c.rect(x, 90 - bh, bw, bh, color)
		c.vline(x + bw - 1, 90 - bh, bh, Palette.shade(color, 0.08))
		for wy: int in range(90 - bh + 4, 88, 5):
			for wx: int in range(x + 2, x + bw - 2, 4):
				c.rect(wx, wy, 2, 3, Palette.light(color, 0.1) if rng.randf() < 0.7 else Color("#dfe8f0"))
		if index == 4:
			_obj(x + 12, 90 - bh - 14, 22, 12, WHITE)
			_mark(x + 18, 90 - bh - 13, 10, 10, RED)
		elif rng.randf() < 0.5:
			c.vline(x + bw / 2, 90 - bh - 8, 8, Palette.shade(color, 0.2))
		x += bw


func _city_near() -> void:
	var widths: Array[int] = [84, 72, 88, 76]
	var facades: Array[Color] = [Color("#c9785a"), Color("#e3d5bb"), Color("#9aa3ad"), Color("#a9cdb8")]
	var x: int = 0
	for index: int in widths.size():
		var bw: int = widths[index]
		var top: int = rng.randi_range(4, 22)
		var facade: Color = facades[index]
		c.rect(x, top, bw, 92 - top, facade)
		c.hline(x, top, bw, Palette.shade(facade, 0.2))
		for row_y: int in range(top + 6, 42, 16):
			for wx: int in range(x + 6, x + bw - 12, 16):
				_obj(wx, row_y, 10, 11, Color("#f4f1ec"))
				c.gradient(wx + 1, row_y + 1, 8, 9, Color("#8fb6d6"), Color("#5a7a96"), 3)
				c.rect(wx - 1, row_y + 11, 12, 1, Palette.shade(facade, 0.2))
		# Sign board, awning and shop window.
		var sign_colors: Array[Color] = [Color("#6b4a36"), Color("#3f9e5a"), RED, Color("#d95c9a")]
		_obj(x + 8, 46, bw - 16, 9, sign_colors[index])
		match index:
			0:
				c.rect(x + 14, 48, 5, 5, WHITE)
				c.rect(x + 19, 49, 2, 2, WHITE)
				for k: int in 5:
					c.rect(x + 26 + k * 8, 50, 5, 2, Color("#f4e3c8"))
			1:
				c.rect(x + bw / 2 - 1, 47, 3, 7, WHITE)
				c.rect(x + bw / 2 - 3, 49, 7, 3, WHITE)
			2:
				_mark(x + 14, 47, 7, 7, WHITE)
				for k: int in 5:
					c.rect(x + 26 + k * 9, 50, 6, 2, WHITE)
			3:
				c.ellipse(x + 16, 50, 3, 3, Color("#ffe08a"))
				c.ellipse(x + 24, 50, 3, 3, WHITE)
		for sx: int in range(x + 4, x + bw - 4, 6):
			var stripe: Color = sign_colors[index] if (sx / 6) % 2 == 0 else WHITE
			_poly([Vector2(sx, 56), Vector2(sx + 6, 56), Vector2(sx + 7, 62), Vector2(sx - 1, 62)], stripe)
		c.rect(x + 6, 64, bw - 12, 24, Color("#2f3d4a"))
		c.rect(x + 8, 66, bw - 34, 20, Color("#3f5566"))
		c.line(x + 10, 84, x + 22, 67, Color(1, 1, 1, 0.2))
		_obj(x + bw - 22, 66, 12, 22, Color("#5a4a3a"))
		if index == 2:
			_obj(x + 12, 70, 12, 16, Color("#d0d4da"))
			c.rect(x + 14, 72, 8, 5, Color("#3a5a8a"))
			_mark(x + 15, 79, 6, 6, RED)
		c.rect(x, 88, bw, 4, Color("#bdb6ab"))
		x += bw
	_tree(84, 90, 52)
	# Street lamp and traffic light.
	c.rect(236, 20, 2, 70, Color("#3a3f46"))
	c.rect(230, 20, 8, 2, Color("#3a3f46"))
	c.rect(228, 22, 5, 2, Color("#fff4cf"))
	c.rect(300, 26, 2, 64, Color("#2a2c33"))
	_obj(296, 26, 10, 22, Color("#24242a"))
	c.ellipse(301, 31, 2.5, 2.5, Color("#ff3b30"))
	c.ellipse(301, 37, 2.5, 2.5, Color("#4a3a10"))
	c.ellipse(301, 43, 2.5, 2.5, Color("#0f3a1a"))
	_wrap_ellipse(301, 31, 6, 6, Color(1.0, 0.25, 0.2, 0.2))


func _city_road() -> void:
	c.rect(0, 0, W, 7, Color("#cfc9bf"))
	for jx: int in range(0, W, 16):
		c.vline(jx, 0, 7, Color("#b9b3a9"))
	c.hline(0, 3, W, Color("#c4beb4"))
	c.rect(0, 7, W, 2, Color("#8f8a83"))
	c.rect(0, 9, W, 27, Color("#4f5259"))
	for i: int in 120:
		c.px(rng.randi_range(0, W - 1), rng.randi_range(9, 35), Color("#5a5d64") if i % 2 else Color("#45484f"))
	for x: int in range(0, W, 40):
		c.rect(x, 20, 16, 1, Color("#e8e8e8"))
	c.ellipse(180, 29, 7, 1.5, Color("#35373c"))
	c.line(40, 30, 60, 33, Color("#3f4248"))


# --- Alfa-Bank office exterior ---------------------------------------------------


func _office_exterior() -> void:
	c.gradient(0, 0, W, 140, Color("#8cc4ee"), Color("#e0f0fa"), 8)
	_cloud(50, 26, 40, Color(1, 1, 1, 0.85))
	_cloud(40, 46, 26, Color(1, 1, 1, 0.7))
	var x: int = 0
	while x < 90:
		var bw: int = rng.randi_range(14, 26)
		var bh: int = rng.randi_range(30, 80)
		c.rect(x, 138 - bh, bw, bh, Color("#b9c7d4"))
		x += bw + 2
	# Neighbouring brick building and trees.
	_obj(0, 72, 62, 66, Color("#c98a6a"))
	for wy: int in range(78, 130, 14):
		for wx: int in range(6, 56, 14):
			_obj(wx, wy, 8, 9, Color("#8fb6d6"))
	_tree(72, 138, 46)
	# Office tower: glass curtain wall.
	c.rect(86, 10, 234, 90, Color("#f5f6f8"))
	for gx: int in range(92, W, 14):
		c.gradient(gx + 1, 16, 12, 76, Color("#9fc6de"), Color("#6f9ab8"), 5)
		c.vline(gx, 16, 76, Color("#e9ecef"))
	for sy: int in range(16, 92, 19):
		c.hline(92, sy, W - 92, Color("#dfe3e8"))
	for i: int in 6:
		c.ellipse(rng.randf_range(100, 310), rng.randf_range(20, 80), rng.randf_range(8, 16), 3, Color(1, 1, 1, 0.22))
	_obj(118, 24, 132, 46, WHITE)
	_mark(124, 28, 32, 38, RED)
	c.rect(86, 94, 234, 6, RED)
	# Lobby, entrance, canopy and planters.
	c.rect(86, 100, 234, 38, Color("#2f3d4a"))
	for lx: int in range(92, W, 22):
		c.vline(lx, 100, 38, Color("#e9ecef"))
		c.rect(lx + 6, 104, 10, 2, Color(1.0, 0.9, 0.66, 0.7))
	c.rect(262, 126, 28, 8, RED)
	c.rect(192, 98, 46, 40, Color("#e9ecef"))
	c.rect(196, 101, 38, 37, Color("#1f2a33"))
	c.rect(206, 104, 18, 3, Color(1.0, 0.9, 0.66, 0.8))
	_obj(184, 91, 64, 5, Color("#c4251b"))
	c.rect(186, 96, 60, 2, Color(0, 0, 0, 0.25))
	for planter_x: int in [164, 248]:
		_obj(planter_x, 124, 20, 14, Color("#6e737b"))
		for k: int in 5:
			c.ellipse(planter_x + 3 + k * 3.5, 121 - (k % 2) * 2, 4, 4, Color("#4f9a4a"))
	c.rect(300, 20, 2, 118, Color("#9aa0a8"))
	c.ellipse(301, 19, 2, 2, Color("#d9dde2"))
	# Sidewalk, curb, parking.
	c.rect(0, 138, W, 9, Color("#d3cec6"))
	for jx: int in range(0, W, 18):
		c.vline(jx, 138, 9, Color("#c0bab1"))
	c.rect(0, 147, W, 2, Color("#e9e5de"))
	c.rect(0, 149, W, 31, Color("#5d6068"))
	for i: int in 120:
		c.px(rng.randi_range(0, W - 1), rng.randi_range(149, 179), Color("#686b73"))
	for lx: int in [22, 172]:
		c.line(lx, 164, lx + 5, 150, WHITE)
		c.line(lx + 1, 164, lx + 6, 150, WHITE)
	c.rect(12, 104, 2, 34, Color("#6e737b"))
	_obj(7, 96, 12, 12, Color("#3a6fb5"))
	c.rect(11, 99, 2, 7, WHITE)
	c.rect(11, 99, 5, 2, WHITE)
	c.rect(14, 101, 2, 2, WHITE)
