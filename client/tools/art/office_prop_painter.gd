class_name OfficePropPainter
extends PropPainterBase
## Office furniture, meeting room and generic wall decor.


func paint(id: String, w: int, h: int) -> bool:
	match id:
		"desk":
			_desk(w, h)
		"office_chair":
			ground_shadow(12, h - 2, 10)
			for x: int in [3, 11, 19]:
				c.rect(x, h - 4, 3, 2, INK)
			c.hline(4, h - 5, 17, METAL)
			c.rect(11, 22, 3, 7, METAL)
			box(3, 17, 18, 5, 3, Color("#343a48"))
			c.rect(4, 1, 16, 16, Color("#2c313d"))
			c.hline(5, 2, 14, Color("#4a5264"))
			c.vline(19, 2, 14, Color("#222631"))
			c.rect(1, 14, 2, 7, INK)
			c.rect(21, 14, 2, 7, INK)
		"chair":
			ground_shadow(10, h - 2, 8)
			c.vline(3, 16, h - 17, WALNUT)
			c.vline(16, 16, h - 17, WALNUT)
			box(2, 13, 16, 4, 3, OAK)
			c.rect(3, 1, 14, 12, Palette.shade(OAK, 0.05))
			for x: int in range(5, 16, 3):
				c.vline(x, 3, 8, Palette.shade(OAK, 0.15))
		"bookshelf":
			ground_shadow(16, h - 2, 14)
			box(1, 2, 30, 4, h - 8, WALNUT)
			c.rect(3, 8, 26, h - 14, Palette.shade(WALNUT, 0.25))
			for shelf: int in 4:
				var base_y: int = 8 + (shelf + 1) * 13
				c.hline(3, base_y, 26, WALNUT)
				var x: int = 4
				while x < 27:
					var book_w: int = rng.randi_range(2, 4)
					var book_h: int = rng.randi_range(7, 11)
					var hue: Color = Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.7), rng.randf_range(0.5, 0.85))
					if rng.randf() < 0.15:
						hue = Palette.ALFA_RED
					c.rect(x, base_y - book_h, mini(book_w, 28 - x), book_h, hue)
					c.hline(x, base_y - book_h + 2, mini(book_w, 28 - x), Palette.light(hue, 0.2))
					x += book_w + (1 if rng.randf() < 0.2 else 0)
		"filing_cabinet":
			ground_shadow(14, h - 2, 13)
			box(1, 6, 26, 6, h - 14, Color("#b9bdc5"))
			for drawer: int in 3:
				var dy: int = 13 + drawer * 9
				c.hline(2, dy + 8, 24, Color("#8f949c"))
				c.rect(11, dy + 3, 6, 2, Color("#6e737b"))
		"printer":
			ground_shadow(16, h - 2, 15)
			box(2, 18, 28, 6, h - 26, Color("#d6d2cb"))
			box(4, 6, 24, 8, 8, Color("#eeeeee"))
			c.rect(9, 2, 14, 5, Palette.WHITE)
			c.rect(20, 15, 5, 2, Color("#39424e"))
			c.px(21, 15, Color("#4cd964"))
			c.rect(8, 13, 16, 2, Color("#fdfdfd"))
		"water_cooler":
			ground_shadow(10, h - 2, 9)
			box(3, 20, 14, 4, h - 26, Palette.WHITE)
			c.ellipse(10, 11, 6.5, 9.0, Color(0.62, 0.82, 0.93, 0.85))
			c.vline(7, 5, 10, Color(1, 1, 1, 0.7))
			c.px(7, 27, Color("#3a7bd5"))
			c.px(12, 27, Palette.ALFA_RED)
			c.rect(6, 34, 8, 2, Color("#c9ced6"))
		"plant_big":
			plant(w, h, Color("#efebe4"), 26)
		"plant_small":
			plant(w, h, Color("#c9754a"), 12)
		"director_desk":
			_director_desk(w, h)
		"armchair_leather":
			sofa(w, h, Color("#7a4a2e"), 1)
		"sofa_leather":
			sofa(w, h, Color("#6e4129"), 3)
		"meeting_table":
			_meeting_table(w, h)
		"window":
			_window(w, h)
		"window_small":
			_window(w, h)
		"poster_alfa":
			c.rect(0, 0, w, h, INK)
			c.rect(1, 1, w - 2, h - 2, Palette.WHITE)
			mark(7, 6, 12, 14, Palette.ALFA_RED)
			c.rect(4, 24, w - 8, 2, Palette.ALFA_RED)
			c.hline(4, 28, w - 12, Color("#c9c4bc"))
		"clock":
			c.ellipse(8, 8, 8, 8, INK)
			c.ellipse(8, 8, 6.5, 6.5, Palette.WHITE)
			c.vline(8, 3, 5, INK)
			c.hline(8, 8, 4, Palette.ALFA_RED)
		"whiteboard":
			c.rect(0, 0, w, h - 4, Color("#aeb3ba"))
			c.rect(2, 2, w - 4, h - 8, Palette.WHITE)
			for i: int in 4:
				c.rect(6 + i * 7, 22 - i * 4, 5, 8 + i * 4, Palette.ALFA_RED if i == 3 else Color("#8fa3bf"))
			c.line(36, 24, 42, 12, Color("#3a7bd5"))
			c.line(42, 12, 48, 18, Color("#3a7bd5"))
			c.line(48, 18, 54, 8, Color("#3a7bd5"))
			c.rect(2, h - 4, w - 4, 3, Color("#8f949c"))
			c.rect(8, h - 5, 6, 1, Palette.ALFA_RED)
			c.rect(16, h - 5, 6, 1, Color("#3a7bd5"))
		"tv":
			screen(0, 0, w, h - 4, true)
			c.rect(w / 2 - 6, h - 4, 12, 3, INK)
		"frame_picture":
			c.rect(0, 0, w, h, Color("#8a5a36"))
			c.gradient(2, 2, w - 4, h - 4, Color("#9fd2ea"), Color("#f2d7a8"), 4)
			c.polygon(PackedVector2Array([Vector2(2, h - 2), Vector2(9, 8), Vector2(15, h - 2)]), Color("#6f9e6a"))
			c.polygon(PackedVector2Array([Vector2(10, h - 2), Vector2(16, 10), Vector2(w - 2, h - 2)]), Color("#4f7a4a"))
		"fire_extinguisher":
			c.rect(1, 2, 10, 3, Color("#8f949c"))
			c.rect(3, 4, 6, h - 5, Palette.ALFA_RED)
			c.vline(4, 6, h - 9, Palette.light(Palette.ALFA_RED, 0.25))
			c.rect(4, 1, 4, 3, INK)
		"rug_office":
			c.rect(0, 0, w, h, Color("#6f7f96"))
			c.rect(4, 4, w - 8, h - 8, Color("#8898ae"))
			c.rect(10, 10, w - 20, h - 20, Color("#7a8aa1"))
			for x: int in range(10, w - 10, 8):
				c.px(x, 7, Palette.ALFA_RED)
				c.px(x, h - 8, Palette.ALFA_RED)
		_:
			return false
	return true


func _desk(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
	c.rect(3, 36, 3, h - 37, METAL)
	c.rect(w - 6, 36, 3, h - 37, METAL)
	c.rect(8, 36, w - 16, 8, Color("#d9d5ce"))
	box(1, 20, w - 2, 14, 4, WHITE_DESK)
	c.rect(26, 12, 8, 10, METAL)
	c.rect(22, 20, 16, 3, Color("#6e737b"))
	screen(12, 0, 38, 16)
	c.rect(19, 25, 22, 5, Color("#d3cfc8"))
	for kx: int in range(20, 40, 2):
		c.px(kx, 26, Color("#b5b0a8"))
		c.px(kx + 1, 28, Color("#b5b0a8"))
	c.rect(44, 26, 4, 5, Color("#cfcac2"))
	c.rect(5, 22, 6, 7, Palette.ALFA_RED)
	c.rect(6, 22, 4, 2, Color("#5a3a22"))
	c.vline(11, 24, 3, Palette.ALFA_RED)
	c.rect(51, 22, 10, 9, Palette.WHITE)
	c.hline(53, 25, 6, Color("#b9b4ac"))
	c.hline(53, 27, 5, Color("#b9b4ac"))


func _director_desk(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
	box(2, 22, w - 4, 18, h - 42, Color("#6b4428"))
	c.rect(8, 42, w - 16, h - 46, Color("#5a3820"))
	for x: int in [30, 64]:
		c.vline(x, 44, h - 48, Color("#4a2e1a"))
	c.rect(30, 26, 36, 10, Color("#2f3b2f"))
	c.rect(38, 10, 24, 15, INK)
	c.rect(40, 12, 20, 11, Color("#dde3ea"))
	c.rect(40, 12, 20, 2, Palette.ALFA_RED)
	c.rect(36, 25, 28, 3, Color("#8f949c"))
	c.rect(8, 16, 3, 12, Color("#c9a24a"))
	c.ellipse(10, 14, 7, 4, Color("#2f6b3f"))
	c.hline(5, 13, 10, Color("#4f9a5f"))
	c.rect(74, 26, 12, 3, Color("#d9b04a"))
	c.rect(70, 30, 16, 6, Palette.WHITE)
	c.rect(16, 28, 8, 5, INK)


func _meeting_table(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 4, 4)
	for x: int in [12, w - 16]:
		c.rect(x, h - 18, 4, 16, Color("#4a2e1a"))
	box(4, 10, w - 8, 36, 8, Color("#8a5a36"))
	c.line(12, 14, 40, 14, Color(1, 1, 1, 0.25))
	for i: int in 5:
		var x: int = 18 + i * 34
		c.rect(x, 16, 16, 10, Color("#c9ced6"))
		c.rect(x + 1, 13, 14, 4, INK)
		c.rect(x + 18, 32, 8, 10, Palette.WHITE)
		c.rect(x + 4, 34, 3, 6, Color(0.7, 0.85, 0.95, 0.8))
	c.rect(w / 2 - 6, 26, 12, 8, Color("#2f3b48"))
	c.px(w / 2, 29, Color("#4cd964"))


func _window(w: int, h: int) -> void:
	c.rect(0, 0, w, h, Color("#d9d4cc"))
	var glass: Rect2i = Rect2i(3, 3, w - 6, h - 10)
	c.gradient(glass.position.x, glass.position.y, glass.size.x, glass.size.y, Color("#a9d6ee"), Color("#e6f4fa"), 5)
	var x: int = glass.position.x
	while x < glass.end.x:
		var bw: int = rng.randi_range(4, 9)
		var bh: int = rng.randi_range(glass.size.y / 5, glass.size.y / 2)
		c.rect(x, glass.end.y - bh, mini(bw, glass.end.x - x), bh, Color("#b7c9d3"))
		for wy: int in range(glass.end.y - bh + 2, glass.end.y - 1, 3):
			c.px(x + 1, wy, Color("#d8e6ee"))
		x += bw
	if w > 30:
		c.vline(w / 2, 3, h - 10, Color("#d9d4cc"))
	c.line(glass.position.x + 2, glass.end.y - 4, glass.position.x + 10, glass.position.y + 2, Color(1, 1, 1, 0.45))
	box(0, h - 7, w, 3, 4, Color("#e8e3db"))
