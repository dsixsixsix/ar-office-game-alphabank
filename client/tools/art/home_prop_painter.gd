class_name HomePropPainter
extends PropPainterBase
## The player's apartment: bedroom, bathroom, hallway, living room and kitchen props.

const PORCELAIN: Color = Color("#f4f3ef")
const CARDBOARD: Color = Color("#c9a26b")
const DENIM: Color = Color("#6f8fb8")
const TEAL_SOFA: Color = Color("#5f7f86")


func paint(id: String, w: int, h: int) -> bool:
	match id:
		"bed_double":
			_bed(w, h)
		"nightstand":
			ground_shadow(12, h - 2, 11)
			box(1, 18, 22, 5, 17, WALNUT)
			c.hline(3, 30, 18, Palette.shade(WALNUT, 0.25))
			c.px(12, 27, Color("#d9b77a"))
			c.px(12, 34, Color("#d9b77a"))
			c.rect(9, 14, 6, 4, INK)
			c.vline(12, 7, 8, Color("#3a3a3a"))
			c.polygon(PackedVector2Array([Vector2(5, 9), Vector2(8, 1), Vector2(16, 1), Vector2(19, 9)]), Color("#f6ead0"))
			c.hline(5, 8, 15, Color("#e3cfa6"))
			c.ellipse(12, 11, 9, 3, Color(1.0, 0.9, 0.6, 0.3))
			c.rect(2, 14, 6, 4, INK)
			c.hline(3, 15, 4, Color("#ff3b30"))
		"wardrobe":
			_wardrobe(w, h)
		"dumbbells":
			for i: int in 2:
				var y: int = 4 + i * 6
				var x: int = 3 + i * 4
				c.rect(x + 4, y + 2, 12, 2, METAL)
				for plate_x: int in [x, x + 16]:
					c.rect(plate_x, y, 4, 6, INK)
					c.vline(plate_x + 1, y + 1, 4, Color("#4a4d55"))
			c.ellipse(24, 12, 2.5, 2, Color(0.85, 0.82, 0.78, 0.8))
			c.px(23, 11, Color(1, 1, 1, 0.6))
		"bathtub":
			_bathtub(w, h)
		"toilet":
			ground_shadow(11, h - 2, 9)
			box(3, 0, 16, 4, 10, PORCELAIN)
			c.rect(9, 1, 4, 2, Color("#c9ced6"))
			c.rect(7, 22, 8, 12, Palette.shade(PORCELAIN, 0.06))
			c.ellipse(11, 20, 9, 7, Palette.shade(PORCELAIN, 0.04))
			c.ellipse(11, 19.5, 8, 6, PORCELAIN)
			c.ellipse(11, 19.5, 5, 3.5, Color("#bfe0ea"))
			c.hline(4, 13, 14, Color("#d9d7d2"))
			c.rect(18, 8, 4, 5, Palette.WHITE)
			c.vline(21, 8, 5, Color("#d9d7d2"))
		"bath_sink":
			ground_shadow(16, h - 2, 14)
			box(2, 16, 28, 8, 22, Color("#e9e4da"))
			c.ellipse(16, 20, 9, 3.5, Color("#c9d3d6"))
			c.ellipse(16, 20, 7, 2.5, Color("#dfeaee"))
			c.rect(15, 12, 2, 6, METAL)
			c.hline(15, 12, 4, METAL)
			c.vline(16, 26, 12, Color("#cfc8bb"))
			c.px(13, 32, METAL)
			c.px(19, 32, METAL)
			c.rect(24, 10, 4, 7, Color("#5ac8d8"))
			c.vline(25, 6, 5, Palette.ALFA_RED)
			c.vline(27, 7, 4, Color("#3a7bd5"))
			c.rect(4, 17, 7, 2, Palette.WHITE)
			c.rect(4, 17, 2, 2, Palette.ALFA_RED)
		"washing_machine":
			ground_shadow(15, h - 2, 14)
			box(1, 6, 28, 5, 31, PORCELAIN)
			c.rect(3, 12, 24, 4, Color("#d7d9dc"))
			c.ellipse(7, 14, 2, 1.5, METAL)
			c.rect(14, 13, 8, 2, Color("#2a2f36"))
			c.hline(15, 13, 5, Color("#4cd964"))
			c.ellipse(15, 27, 9, 9, METAL)
			c.ellipse(15, 27, 7, 7, Color("#2d4a66"))
			c.ellipse(13, 29, 3, 2, Palette.ALFA_RED)
			c.ellipse(17, 25, 3, 2, Color("#6f8fb8"))
			c.line(10, 24, 13, 21, Color(1, 1, 1, 0.4))
			c.rect(6, 2, 6, 5, Color("#e07a3f"))
			c.rect(14, 3, 5, 4, Color("#f4f3ef"))
			c.px(15, 4, Palette.ALFA_RED)
		"shoe_rack":
			ground_shadow(16, h - 2, 15)
			box(1, 10, 30, 4, 12, OAK)
			c.hline(2, 18, 28, Palette.shade(OAK, 0.2))
			for pair: int in 3:
				var color: Color = [Palette.ALFA_RED, Palette.WHITE, Color("#3a3a44")][pair]
				var x: int = 3 + pair * 9
				c.rect(x, 6, 4, 5, color)
				c.rect(x + 4, 7, 4, 4, Palette.shade(color, 0.08))
				c.hline(x, 10, 8, Palette.WHITE if pair != 1 else Color("#c9ced6"))
			c.rect(20, 23, 9, 3, Color("#f6eef2"))
			c.px(21, 22, Color("#f59ab0"))
			c.px(26, 22, Color("#f59ab0"))
		"hall_mirror":
			ground_shadow(11, h - 2, 10)
			c.line(4, h - 2, 8, h - 12, WALNUT)
			c.line(18, h - 2, 14, h - 12, WALNUT)
			c.ellipse(11, 24, 10, 23, WALNUT)
			c.ellipse(11, 24, 8, 21, Color("#a9c7d4"))
			c.gradient(5, 8, 12, 30, Color("#cfe4ee"), Color("#9ab8c6"), 4)
			c.ellipse(11, 24, 8, 21, Color(0.66, 0.78, 0.83, 0.35))
			c.line(6, 30, 12, 10, Color(1, 1, 1, 0.55))
			c.line(8, 34, 14, 14, Color(1, 1, 1, 0.3))
		"tv_console":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 3)
			box(2, 8, w - 4, 6, h - 12, WALNUT)
			for x: int in [32, 64]:
				c.vline(x, 15, h - 20, Palette.shade(WALNUT, 0.25))
			c.rect(10, 17, 20, 8, Palette.shade(WALNUT, 0.3))
			c.rect(12, 18, 8, 6, Color("#2a2f36"))
			c.px(18, 19, Color("#4fb3ff"))
			c.rect(12, 2, 16, 7, Palette.WHITE)
			c.hline(12, 5, 16, Color("#2a2f36"))
			c.px(26, 3, Color("#4fb3ff"))
			c.rect(38, 5, 11, 4, INK)
			c.px(40, 6, Palette.ALFA_RED)
			c.px(46, 6, Color("#3a7bd5"))
			c.rect(56, 4, 30, 4, INK)
			c.hline(58, 5, 26, Color("#3a3a44"))
			c.line(70, h - 4, 76, h - 1, INK)
		"sofa_back":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
			var back: Color = TEAL_SOFA
			for i: int in 3:
				c.rect(8 + i * 27, 1, 26, 10, Palette.light(back, 0.12))
				c.hline(9 + i * 27, 1, 24, Palette.light(back, 0.22))
			c.rect(3, 9, w - 6, 26, back)
			c.hline(3, 9, w - 6, Palette.light(back, 0.15))
			c.rect(3, 30, w - 6, 5, Palette.shade(back, 0.12))
			for arm_x: int in [0, w - 8]:
				box(arm_x, 4, 8, 5, 30, Palette.shade(back, 0.04))
			c.rect(60, 8, 20, 16, Palette.ALFA_RED)
			for x: int in range(60, 80, 2):
				c.vline(x, 24, 3, Palette.shade(Palette.ALFA_RED, 0.2))
			c.hline(60, 14, 20, Palette.WHITE)
			c.rect(6, h - 5, 3, 3, INK)
			c.rect(w - 9, h - 5, 3, 3, INK)
		"pizza_table":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 3)
			for x: int in [5, w - 8]:
				c.rect(x, 20, 3, h - 22, WALNUT)
			box(2, 9, w - 4, 12, 5, OAK)
			c.rect(7, 3, 24, 8, Palette.shade(CARDBOARD, 0.1))
			c.rect(7, 11, 24, 10, CARDBOARD)
			c.ellipse(19, 15, 9, 4, Color("#e9b44c"))
			c.polygon(PackedVector2Array([Vector2(19, 15), Vector2(28, 13), Vector2(28, 17)]), CARDBOARD)
			c.px(15, 14, Palette.ALFA_RED)
			c.px(20, 16, Palette.ALFA_RED)
			c.px(13, 16, Palette.ALFA_RED)
			c.rect(38, 7, 5, 8, Palette.ALFA_RED)
			c.hline(38, 8, 5, Palette.WHITE)
			c.rect(48, 11, 10, 4, INK)
			c.px(50, 12, Palette.ALFA_RED)
			c.px(56, 12, Color("#3a7bd5"))
		"laptop_desk":
			_laptop_desk(w, h)
		"gaming_chair":
			ground_shadow(13, h - 2, 11)
			for x: int in [3, 12, 21]:
				c.rect(x, h - 4, 3, 2, INK)
			c.hline(4, h - 5, 19, METAL)
			c.rect(12, 26, 3, 8, METAL)
			box(3, 21, 20, 5, 3, Color("#2a2a30"))
			c.rect(5, 1, 16, 22, INK)
			c.rect(7, 2, 3, 20, Palette.ALFA_RED)
			c.rect(16, 2, 3, 20, Palette.ALFA_RED)
			c.rect(9, 5, 8, 5, Color("#3a3a44"))
			c.rect(1, 16, 3, 8, INK)
			c.rect(22, 16, 3, 8, INK)
		"guitar":
			ground_shadow(10, h - 2, 8)
			c.line(3, h - 2, 9, h - 16, METAL)
			c.line(17, h - 2, 11, h - 16, METAL)
			var wood: Color = Color("#c07a3a")
			c.rect(9, 2, 3, 20, Color("#4a2c18"))
			c.rect(8, 0, 5, 4, Color("#3a2010"))
			c.ellipse(10, 34, 8, 8, wood)
			c.ellipse(10, 24, 6, 6, wood)
			c.ellipse(10, 27, 2.5, 2.5, INK)
			c.hline(6, 36, 9, Color("#4a2c18"))
			c.vline(10, 4, 32, Color(1, 1, 1, 0.35))
			c.ellipse(7, 31, 2, 4, Palette.light(wood, 0.2))
		"pizza_boxes":
			ground_shadow(16, h - 2, 15)
			for i: int in 6:
				var y: int = h - 8 - i * 5
				var x: int = 2 + (i * 3) % 5 - 1
				box(x, y, 28, 2, 4, CARDBOARD if i % 2 == 0 else Palette.shade(CARDBOARD, 0.06))
				c.hline(x + 3, y + 4, 10, Palette.shade(CARDBOARD, 0.2))
			c.ellipse(12, 11, 3, 2, Color(0.55, 0.35, 0.15, 0.4))
			c.polygon(PackedVector2Array([Vector2(16, 11), Vector2(25, 9), Vector2(24, 13)]), Color("#e9b44c"))
			c.px(21, 11, Palette.ALFA_RED)
		"stove":
			_home_counter(w, h, Color("#e9eaec"))
			for burner: Vector2i in [Vector2i(9, 21), Vector2i(23, 21)]:
				c.ellipse(burner.x, burner.y, 5, 2.5, INK)
				c.ellipse(burner.x, burner.y, 3, 1.5, Color("#3a3a44"))
			c.ellipse(23, 21, 3, 1.5, Color("#ff5a2a"))
			c.ellipse(9, 18, 7, 3, Color("#2a2a30"))
			c.rect(15, 17, 8, 2, INK)
			c.ellipse(9, 18, 5, 2, Color("#3a3a44"))
			c.ellipse(9, 18, 3, 1.5, Palette.WHITE)
			c.px(9, 18, Color("#ffc233"))
			c.rect(5, 34, 22, 10, Color("#2a2f36"))
			c.hline(6, 35, 20, METAL)
			for knob: int in 4:
				c.px(6 + knob * 6, 30, INK)
		"counter_kettle":
			_home_counter(w, h, Color("#f4f1ec"))
			c.rect(5, 12, 9, 10, Palette.ALFA_RED)
			c.rect(4, 11, 11, 2, Palette.shade(Palette.ALFA_RED, 0.2))
			c.rect(14, 14, 2, 5, INK)
			c.vline(6, 13, 7, Palette.light(Palette.ALFA_RED, 0.25))
			for i: int in 3:
				c.px(9 + i, 8 - i * 3, Color(1, 1, 1, 0.55))
			c.rect(19, 15, 10, 7, METAL)
			c.rect(20, 14, 3, 1, INK)
			c.rect(25, 14, 3, 1, INK)
			c.rect(21, 12, 2, 2, Color("#d9a060"))
		"trash_bin":
			ground_shadow(10, h - 2, 8)
			box(2, 8, 16, 3, 19, METAL)
			c.rect(4, 2, 11, 8, CARDBOARD)
			c.hline(4, 2, 11, Palette.light(CARDBOARD, 0.15))
			c.rect(1, 8, 18, 2, Palette.shade(METAL, 0.2))
			c.rect(7, h - 4, 6, 2, INK)
			c.line(14, 7, 17, 4, Color("#f2c230"))
			c.px(17, 5, Color("#8a6a2a"))
		"poster_band":
			c.rect(0, 0, w, h, INK)
			c.rect(1, 1, w - 2, h - 2, Color("#1f1a2e"))
			c.polygon(PackedVector2Array([Vector2(15, 4), Vector2(7, 19), Vector2(13, 19), Vector2(9, 32), Vector2(19, 15), Vector2(13, 15), Vector2(17, 4)]), Palette.ALFA_RED)
			for star: Vector2i in [Vector2i(4, 6), Vector2i(21, 9), Vector2i(5, 27), Vector2i(20, 29)]:
				c.px(star.x, star.y, Palette.WHITE)
			c.hline(4, h - 5, w - 8, Color("#f7c948"))
		"mirror_bath":
			c.rect(0, 2, w, h - 2, METAL)
			c.gradient(2, 4, w - 4, h - 6, Color("#dcecf2"), Color("#a9c7d4"), 4)
			c.line(4, h - 5, 12, 6, Color(1, 1, 1, 0.55))
			for bulb: int in 4:
				c.ellipse(4 + bulb * 5.5, 2, 1.5, 1.5, Color("#fff4cf"))
		"towel_rail":
			c.hline(1, 3, w - 2, METAL)
			c.px(1, 2, METAL)
			c.px(w - 2, 2, METAL)
			c.rect(3, 4, 9, h - 6, Palette.ALFA_RED)
			c.hline(3, h - 8, 9, Palette.WHITE)
			c.vline(4, 5, h - 12, Palette.light(Palette.ALFA_RED, 0.2))
			c.rect(14, 4, 9, h - 10, Palette.WHITE)
			c.vline(22, 4, h - 10, Color("#d9d7d2"))
		"coat_rack":
			c.rect(1, 3, w - 2, 3, WALNUT)
			for hook: int in 3:
				c.px(5 + hook * 11, 6, METAL)
			c.rect(2, 7, 11, 24, Palette.ALFA_RED)
			c.rect(4, 7, 7, 3, Palette.shade(Palette.ALFA_RED, 0.2))
			c.rect(6, 14, 3, 4, Palette.WHITE)
			c.rect(14, 7, 8, 30, Color("#6e737b"))
			c.vline(18, 9, 26, Color("#5a5f66"))
			c.rect(24, 7, 5, 22, Color("#f7c948"))
			for stripe_y: int in range(9, 29, 4):
				c.hline(24, stripe_y, 5, Color("#3a7bd5"))
			c.rect(22, 0, 9, 4, Palette.ALFA_RED)
		"front_door":
			c.rect(0, 0, w, h, Color("#3a2a20"))
			c.rect(4, 4, w - 8, h - 4, Color("#6b4630"))
			for panel: Rect2i in [Rect2i(8, 9, 12, 20), Rect2i(24, 9, 12, 20), Rect2i(8, 34, 12, 22), Rect2i(24, 34, 12, 22)]:
				c.rect(panel.position.x, panel.position.y, panel.size.x, panel.size.y, Palette.shade(Color("#6b4630"), 0.08))
				c.hline(panel.position.x, panel.position.y, panel.size.x, Palette.light(Color("#6b4630"), 0.1))
			c.rect(33, 31, 5, 2, METAL)
			c.rect(34, 35, 2, 3, Color("#d9b77a"))
			c.px(22, 16, INK)
			c.rect(19, 5, 6, 3, Color("#d9b77a"))
		"key_hook":
			c.rect(0, 2, w, 5, OAK)
			c.hline(0, 2, w, Palette.light(OAK, 0.2))
			for hook: int in 3:
				c.px(4 + hook * 7, 7, METAL)
			c.rect(9, 8, 4, 7, INK)
			c.px(10, 10, Palette.ALFA_RED)
			c.ellipse(11, 8, 2, 1.5, METAL)
			c.rect(3, 9, 3, 4, Palette.ALFA_RED)
		"calendar_alfa":
			c.rect(0, 0, w, h, Palette.WHITE)
			c.rect(0, 0, w, 8, Palette.ALFA_RED)
			mark(8, 1, 6, 6, Palette.WHITE)
			for row: int in 4:
				for col: int in 5:
					c.px(2 + col * 4, 11 + row * 4, Color("#c9c4bc"))
			c.ellipse(14, 19, 2.5, 2.5, Color(0.94, 0.19, 0.14, 0.0))
			c.line(12, 17, 16, 21, Palette.ALFA_RED)
			c.line(16, 17, 12, 21, Palette.ALFA_RED)
		"rug_bedroom":
			c.ellipse(w / 2.0, h / 2.0, w / 2.0 - 1, h / 2.0 - 1, Color("#c98f88"))
			c.ellipse(w / 2.0, h / 2.0, w / 2.0 - 6, h / 2.0 - 5, Color("#e5b7ae"))
			c.ellipse(w / 2.0, h / 2.0, w / 2.0 - 14, h / 2.0 - 11, Color("#d9a39a"))
			c.ellipse(w / 2.0, h / 2.0, w / 2.0 - 20, h / 2.0 - 15, Color("#efd3c7"))
		"bath_mat":
			c.rect(2, 2, w - 4, h - 4, Color("#7fb3c9"))
			for x: int in range(5, w - 5, 4):
				c.vline(x, 4, h - 8, Color("#9fc9da"))
			c.hline(2, 2, w - 4, Palette.light(Color("#7fb3c9"), 0.15))
		"doormat":
			c.rect(2, 2, w - 4, h - 4, Color("#a07a4a"))
			c.rect(4, 4, w - 8, h - 8, Color("#b58c58"))
			for x: int in range(8, w - 8, 3):
				c.vline(x, 8, h - 16, Color("#8a6a3a"))
			c.hline(6, h / 2, w - 12, Palette.ALFA_RED)
		"rug_living":
			c.rect(0, 0, w, h, Color("#b9573a"))
			c.rect(4, 4, w - 8, h - 8, Color("#e8c9a0"))
			c.rect(10, 10, w - 20, h - 20, Color("#c96d4a"))
			for y: int in range(18, h - 16, 16):
				for x: int in range(18, w - 16, 16):
					c.polygon(PackedVector2Array([Vector2(x, y - 5), Vector2(x + 5, y), Vector2(x, y + 5), Vector2(x - 5, y)]), Color("#e8c9a0"))
					c.px(x, y, Color("#2f6b8f"))
			for x: int in range(0, w, 3):
				c.px(x, 0, Color("#e8c9a0"))
				c.px(x, h - 1, Color("#e8c9a0"))
		_:
			return false
	return true


func _bed(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 4)
	box(2, 0, w - 4, 4, 16, WALNUT)
	c.rect(6, 6, w - 12, 10, Palette.shade(WALNUT, 0.15))
	c.rect(4, 18, w - 8, 54, Color("#f2efe9"))
	for pillow_x: int in [7, 33]:
		c.rect(pillow_x, 20, 24, 12, Palette.WHITE)
		c.hline(pillow_x, 31, 24, Color("#d9d4cc"))
		c.hline(pillow_x + 2, 21, 12, Color("#ffffff"))
	c.rect(3, 36, w - 6, 36, DENIM)
	c.rect(3, 36, w - 6, 5, Palette.light(DENIM, 0.18))
	c.polygon(PackedVector2Array([Vector2(3, 41), Vector2(24, 41), Vector2(10, 52), Vector2(3, 52)]), Color("#f2efe9"))
	for y: int in range(46, 70, 6):
		for x: int in range(8 + (y / 6) % 2 * 4, w - 6, 8):
			c.px(x, y, Palette.light(DENIM, 0.25))
	c.line(30, 44, 50, 60, Palette.shade(DENIM, 0.12))
	c.line(14, 58, 26, 66, Palette.shade(DENIM, 0.12))
	c.rect(44, 46, 4, 7, INK)
	c.rect(45, 47, 2, 4, Color("#7fe3ea"))
	c.rect(3, 72, w - 6, 5, Palette.shade(DENIM, 0.15))
	box(2, 76, w - 4, 2, 6, WALNUT)
	c.rect(4, h - 2, 3, 2, INK)
	c.rect(w - 7, h - 2, 3, 2, INK)


func _wardrobe(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
	c.rect(8, 0, 18, 10, CARDBOARD)
	c.hline(8, 4, 18, Palette.shade(CARDBOARD, 0.2))
	c.rect(30, 3, 12, 7, Palette.shade(CARDBOARD, 0.08))
	box(2, 9, w - 4, 5, h - 12, OAK)
	var mirror: Rect2i = Rect2i(6, 18, 20, h - 30)
	c.gradient(mirror.position.x, mirror.position.y, mirror.size.x, mirror.size.y, Color("#dcecf2"), Color("#9ab8c6"), 5)
	c.line(8, mirror.end.y - 6, 18, mirror.position.y + 4, Color(1, 1, 1, 0.5))
	c.line(12, mirror.end.y - 4, 22, mirror.position.y + 8, Color(1, 1, 1, 0.25))
	c.rect(34, 18, 20, h - 30, Palette.shade(OAK, 0.06))
	c.hline(34, 18, 20, Palette.light(OAK, 0.1))
	c.vline(30, 15, h - 18, Palette.shade(OAK, 0.25))
	c.vline(55, 15, h - 18, INK)
	c.rect(54, 34, 3, 14, Palette.ALFA_RED)
	c.px(55, 40, Palette.WHITE)
	c.rect(27, 40, 2, 6, METAL)
	c.rect(32, 40, 2, 6, METAL)
	c.hline(2, h - 4, w - 4, Palette.shade(OAK, 0.3))


func _bathtub(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 4)
	c.rect(2, 6, w - 4, 26, PORCELAIN)
	c.hline(2, 6, w - 4, Palette.WHITE)
	c.rect(7, 10, w - 14, 18, Color("#bfe0ea"))
	c.gradient(7, 10, w - 14, 18, Color("#d7eef4"), Color("#a9d2df"), 4)
	for bubble: Vector2i in [Vector2i(58, 14), Vector2i(64, 18), Vector2i(70, 13), Vector2i(76, 20), Vector2i(82, 15), Vector2i(68, 23)]:
		c.ellipse(bubble.x, bubble.y, 3, 2.5, Palette.WHITE)
	c.rect(30, 14, 6, 5, Color("#f6d44a"))
	c.rect(33, 12, 4, 3, Color("#f6d44a"))
	c.px(37, 13, Color("#f28a1a"))
	c.px(34, 12, INK)
	c.rect(8, 2, 8, 5, METAL)
	c.hline(8, 2, 3, Palette.light(METAL, 0.3))
	c.rect(2, 32, w - 4, 10, Palette.shade(PORCELAIN, 0.06))
	c.hline(2, 32, w - 4, Color("#d9d7d2"))
	c.rect(4, h - 3, 4, 2, METAL)
	c.rect(w - 8, h - 3, 4, 2, METAL)


func _laptop_desk(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
	for x: int in [4, w - 7]:
		c.rect(x, 32, 3, h - 34, METAL)
	box(2, 22, w - 4, 11, 4, WHITE_DESK)
	c.rect(20, 27, 24, 6, Color("#b9bec6"))
	for key_row: int in 2:
		c.hline(22, 28 + key_row * 2, 20, Color("#8f949c"))
	c.rect(22, 8, 20, 18, INK)
	c.gradient(24, 10, 16, 14, Color("#243049"), Color("#1a2236"), 3)
	c.rect(24, 10, 16, 3, Palette.ALFA_RED)
	for bubble: int in 3:
		c.rect(26 + (bubble % 2) * 5, 15 + bubble * 3, 9, 2, Color("#e8ecf2") if bubble % 2 == 0 else Color("#7fe3ea"))
	c.ellipse(32, 18, 14, 8, Color(0.5, 0.9, 1.0, 0.08))
	c.rect(48, 22, 5, 6, Palette.WHITE)
	c.rect(48, 24, 5, 2, Palette.ALFA_RED)
	c.px(53, 24, Palette.WHITE)
	c.rect(6, 26, 5, 4, Color("#f7c948"))
	c.rect(12, 27, 4, 4, Color("#8bc34a"))
	c.vline(9, 10, 14, Color("#3a3a3a"))
	c.polygon(PackedVector2Array([Vector2(4, 12), Vector2(7, 6), Vector2(14, 6), Vector2(16, 12)]), Palette.ALFA_RED)
	c.rect(56, 16, 4, 6, Color("#4f9a4a"))
	c.px(55, 18, Color("#4f9a4a"))
	c.rect(55, 22, 6, 3, Color("#c9754a"))


func _home_counter(w: int, h: int, color: Color) -> void:
	box(0, h - 30, w, 8, 22, color)
	c.hline(0, h - 30, w, Color("#8a8f96"))
	c.rect(0, h - 30, w, 3, Color("#a88a6a"))
	c.hline(0, h - 1, w, Color("#6e6860"))
