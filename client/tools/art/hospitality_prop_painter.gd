class_name HospitalityPropPainter
extends PropPainterBase
## Kitchen, reception and lounge props plus brand decor.


func paint(id: String, w: int, h: int) -> bool:
	match id:
		"fridge":
			ground_shadow(16, h - 2, 14)
			box(2, 4, 28, 5, h - 10, Color("#e9eaec"))
			c.hline(3, 30, 26, Color("#b9bcc2"))
			c.rect(24, 14, 2, 10, Color("#9aa0a8"))
			c.rect(24, 36, 2, 14, Color("#9aa0a8"))
			c.rect(6, 38, 6, 8, Palette.WHITE)
			c.rect(7, 39, 4, 2, Palette.ALFA_RED)
			c.rect(14, 16, 5, 5, Color("#f7c948"))
		"counter":
			_counter(w, h)
			c.rect(6, 8, 8, 6, Color("#e9c46a"))
			c.ellipse(21, 11, 5, 3, Color("#efe8dc"))
			c.px(20, 10, Palette.ALFA_RED)
			c.px(23, 11, Color("#8bc34a"))
		"counter_sink":
			_counter(w, h)
			c.rect(6, 6, 20, 9, Color("#c9d3d6"))
			c.rect(8, 8, 16, 5, Color("#aab6ba"))
			c.rect(15, 2, 2, 5, METAL)
			c.hline(15, 2, 5, METAL)
		"coffee_machine":
			_counter(w, h)
			box(5, 0, 22, 5, 16, Color("#2f3238"))
			c.rect(8, 7, 16, 4, Color("#1a1c20"))
			c.px(10, 8, Color("#4cd964"))
			c.px(12, 8, Palette.ALFA_RED)
			c.rect(12, 16, 8, 3, METAL)
			c.rect(13, 18, 6, 4, Palette.WHITE)
			for i: int in 3:
				c.px(14 + i * 2, 1 - i % 2, Color(1, 1, 1, 0.5))
		"microwave":
			_counter(w, h)
			box(3, 2, 26, 4, 14, Color("#d7d9dc"))
			c.rect(5, 8, 16, 9, Color("#2a2f36"))
			c.line(6, 16, 12, 9, Color(1, 1, 1, 0.15))
			c.rect(23, 8, 4, 9, Color("#b9bcc2"))
			c.rect(24, 9, 2, 2, Color("#4cd964"))
		"vending":
			ground_shadow(16, h - 2, 14)
			box(1, 2, 30, 4, h - 8, Palette.ALFA_RED)
			c.rect(4, 10, 17, 44, Color("#1d2433"))
			for row: int in 5:
				for col: int in 3:
					var hue: Color = [Color("#f7c948"), Color("#3a7bd5"), Color("#8bc34a"), Palette.WHITE][(row + col) % 4]
					c.rect(5 + col * 5, 12 + row * 8, 4, 5, hue)
				c.hline(4, 18 + row * 8, 17, METAL)
			c.rect(23, 12, 6, 10, Color("#2a2f36"))
			c.rect(24, 24, 4, 4, Palette.WHITE)
			c.rect(4, 57, 17, 6, INK)
			mark(24, 42, 5, 6, Palette.WHITE)
		"cafe_table":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 4)
			c.rect(w / 2 - 2, 20, 4, h - 22, METAL)
			c.rect(w / 2 - 10, h - 4, 20, 2, METAL)
			c.ellipse(w / 2.0, 14, w / 2.0 - 2, 10, Palette.shade(WHITE_DESK, 0.1))
			c.ellipse(w / 2.0, 12, w / 2.0 - 2, 9, WHITE_DESK)
			c.rect(14, 8, 6, 6, Palette.ALFA_RED)
			c.rect(32, 9, 10, 6, Color("#e9c46a"))
			c.ellipse(37, 11, 3, 2, Color("#c9754a"))
		"reception_desk":
			_reception_desk(w, h)
		"sofa_red":
			sofa(w, h, Palette.ALFA_RED, 3)
			c.rect(12, 6, 10, 9, Palette.WHITE)
			mark(14, 7, 6, 7, Palette.ALFA_RED)
		"coffee_table":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 3)
			for x: int in [5, w - 8]:
				c.rect(x, 16, 3, h - 18, WALNUT)
			box(2, 6, w - 4, 12, 4, OAK)
			c.rect(10, 8, 12, 8, Color("#3a7bd5"))
			c.rect(12, 9, 8, 1, Palette.WHITE)
			c.rect(40, 9, 5, 6, Palette.WHITE)
			c.rect(41, 10, 3, 3, Color("#7a4a2a"))
		"ping_pong":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 3, 4)
			for x: int in [8, w - 11]:
				c.rect(x, 40, 3, h - 42, METAL)
			box(2, 6, w - 4, 34, 6, Color("#2f6b8f"))
			c.rect(3, 22, w - 6, 1, Palette.WHITE)
			c.rect(w / 2, 7, 1, 33, Palette.WHITE)
			c.rect(1, 20, w - 2, 5, Color(0.1, 0.1, 0.1, 0.5))
			c.hline(1, 20, w - 2, Palette.WHITE)
			c.ellipse(20, 12, 4, 3, Palette.ALFA_RED)
			c.ellipse(74, 32, 4, 3, INK)
			c.px(60, 14, Palette.WHITE)
		"armchair":
			sofa(w, h, Color("#d8c3a5"), 1)
		"bean_bag":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
			c.ellipse(w / 2.0, h / 2.0 + 2, w / 2.0 - 1, h / 2.0 - 3, Color("#e07a3f"))
			c.ellipse(w / 2.0 - 3, h / 2.0, w / 2.0 - 7, h / 2.0 - 7, Color("#ee9a62"))
			c.line(8, 8, 14, 12, Color("#c9652e"))
		"floor_lamp":
			ground_shadow(10, h - 2, 8)
			c.ellipse(10, h - 3, 6, 2, INK)
			c.vline(10, 18, h - 20, Color("#3a3a3a"))
			c.polygon(PackedVector2Array([Vector2(3, 18), Vector2(6, 2), Vector2(14, 2), Vector2(17, 18)]), Color("#f6ead0"))
			c.hline(3, 17, 15, Color("#e3cfa6"))
			c.ellipse(10, 20, 9, 3, Color(1.0, 0.9, 0.6, 0.35))
		"logo_sign":
			c.rect(0, 0, w, h, Palette.WHITE)
			c.rect(0, h - 6, w, 6, Palette.ALFA_RED)
			mark(8, 6, 32, 38, Palette.ALFA_RED)
			for row: int in 2:
				c.rect(48, 14 + row * 14, 64 - row * 18, 7, Palette.ALFA_RED if row == 0 else Color("#c9c4bc"))
			c.hline(0, 0, w, Color("#ffffff"))
		"logo_small":
			c.rect(0, 0, w, h, Palette.WHITE)
			mark(4, 3, 16, 19, Palette.ALFA_RED)
		"kitchen_cabinets":
			box(0, 0, w, 3, h - 5, Color("#f4f1ec"))
			c.vline(w / 2, 4, h - 8, Color("#d3cec6"))
			c.rect(w / 2 - 4, h - 10, 2, 4, METAL)
			c.rect(w / 2 + 2, h - 10, 2, 4, METAL)
		"menu_board":
			c.rect(0, 0, w, h, WALNUT)
			c.rect(2, 2, w - 4, h - 4, Color("#2e3a33"))
			for row: int in 4:
				c.hline(6, 8 + row * 6, rng.randi_range(18, 30), Color("#e8e3d8"))
				c.hline(40, 8 + row * 6, 3, Color("#f7c948"))
		"world_clocks":
			for i: int in 3:
				var cx: float = 11.0 + i * 21.0
				c.ellipse(cx, 10, 9, 9, INK)
				c.ellipse(cx, 10, 7.5, 7.5, Palette.WHITE)
				c.vline(roundi(cx), 4, 6, INK)
				c.line(roundi(cx), 10, roundi(cx) + 3 - i * 3, 13, Palette.ALFA_RED)
		"rug_lounge":
			c.rect(0, 0, w, h, Color("#b9573a"))
			c.rect(5, 5, w - 10, h - 10, Color("#e8d2b0"))
			for y: int in range(12, h - 12, 12):
				for x: int in range(12, w - 12, 12):
					c.polygon(PackedVector2Array([Vector2(x, y - 4), Vector2(x + 4, y), Vector2(x, y + 4), Vector2(x - 4, y)]), Color("#d08a5e"))
		"logo_floor":
			c.ellipse(w / 2.0, h / 2.0, w / 2.0, h / 2.0, Color(1, 1, 1, 0.55))
			mark(8, 8, w - 16, h - 16, Color(0.94, 0.19, 0.14, 0.9))
		_:
			return false
	return true


func _counter(w: int, h: int) -> void:
	box(0, h - 30, w, 8, 22, Color("#f4f1ec"))
	c.hline(0, h - 30, w, Color("#8a8f96"))
	c.rect(0, h - 30, w, 3, Color("#b9b4ac"))
	c.vline(w / 2, h - 20, 18, Color("#d3cec6"))
	c.rect(w / 2 - 4, h - 16, 2, 4, METAL)
	c.rect(w / 2 + 2, h - 16, 2, 4, METAL)
	c.hline(0, h - 1, w, Color("#6e6860"))


func _reception_desk(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 4)
	box(0, 4, w, 16, h - 22, Palette.WHITE)
	c.rect(0, 20, w, 4, Color("#e3ddd4"))
	c.rect(0, h - 14, w, 10, Palette.ALFA_RED)
	c.hline(0, h - 14, w, Palette.light(Palette.ALFA_RED, 0.2))
	mark(w / 2 - 10, 26, 20, 22, Palette.ALFA_RED)
	screen(24, 0, 26, 14)
	screen(w - 52, 0, 26, 14)
	c.rect(70, 8, 16, 8, Color("#e9c46a"))
	c.rect(110, 9, 6, 6, Color("#4f9a4a"))
	c.rect(111, 6, 4, 4, Color("#6fbf6a"))
