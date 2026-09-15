class_name PartyPropPainter
extends PropPainterBase
## Design department party room props: bar, DJ booth, speakers, neon, designer desks.

const NEON_PINK: Color = Color("#ff4fa3")
const NEON_CYAN: Color = Color("#5ce1e6")
const BAR_WOOD: Color = Color("#4a2a1c")


func paint(id: String, w: int, h: int) -> bool:
	match id:
		"bar_counter":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 4)
			box(0, 4, w, 14, h - 18, BAR_WOOD)
			c.rect(0, 4, w, 3, Color("#2a1a12"))
			c.hline(0, h - 8, w, NEON_PINK)
			c.hline(0, h - 7, w, Color(1.0, 0.31, 0.64, 0.4))
			for i: int in 9:
				var x: int = 8 + i * 21
				_bottle(x, rng.randi_range(0, 3))
				c.rect(x + 8, 10, 5, 6, Color(0.8, 0.9, 1.0, 0.6))
		"bar_stool":
			ground_shadow(8, h - 2, 6)
			c.vline(8, 8, h - 10, METAL)
			c.hline(4, h - 3, 9, METAL)
			c.ellipse(8, 6, 7, 4, Color("#2a1a12"))
			c.ellipse(8, 5, 7, 3, Palette.ALFA_RED)
		"dj_booth":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 4)
			box(2, 16, w - 4, 16, h - 34, Color("#1f1c24"))
			for x: int in [22, 62]:
				c.ellipse(x, 24, 11, 6, Color("#3a3a44"))
				c.ellipse(x, 24, 7, 4, INK)
				c.px(x, 24, NEON_PINK)
			c.rect(38, 18, 16, 12, Color("#2c2a33"))
			for i: int in 6:
				c.vline(40 + i * 2, 20 + i % 3, 6, NEON_CYAN if i % 2 else NEON_PINK)
			c.rect(4, 34, w - 8, h - 38, Color("#2a2733"))
			for x: int in range(8, w - 8, 6):
				c.vline(x, 36, h - 42, Color(1.0, 0.31, 0.64, 0.25 + 0.2 * ((x / 6) % 2)))
			c.rect(60, 2, 22, 14, INK)
			c.rect(62, 4, 18, 9, Color("#3a2a5a"))
			c.line(62, 12, 79, 5, NEON_CYAN)
		"speaker":
			ground_shadow(14, h - 2, 12)
			box(1, 2, 26, 4, h - 8, Color("#1c1b20"))
			c.ellipse(14, 20, 9, 9, Color("#34333b"))
			c.ellipse(14, 20, 5, 5, Color("#4a4952"))
			c.ellipse(14, 44, 6, 6, Color("#34333b"))
			c.px(14, 20, NEON_PINK)
		"sofa_green":
			sofa(w, h, Color("#7fbf3a"), 3)
		"party_table":
			ground_shadow(14, h - 2, 11)
			c.rect(12, 18, 4, h - 20, METAL)
			c.ellipse(14, 14, 13, 7, Color("#2a1a2a"))
			c.ellipse(14, 13, 13, 6, Color("#3a2a3a"))
			_bottle(4, 1)
			c.rect(16, 6, 4, 6, Color(0.8, 0.9, 1.0, 0.6))
			c.rect(20, 9, 5, 4, Palette.ALFA_RED)
		"design_desk":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
			c.rect(3, 40, 3, h - 41, INK)
			c.rect(w - 6, 40, 3, h - 41, INK)
			box(1, 26, w - 2, 12, 4, Color("#2c2a33"))
			c.rect(26, 18, 8, 10, METAL)
			c.rect(4, 0, 50, 22, INK)
			c.gradient(6, 2, 46, 18, Color("#ff7a59"), Color("#7a3fd1"), 5)
			c.ellipse(20, 11, 6, 6, Color(1, 1, 1, 0.5))
			c.rect(34, 6, 14, 3, Palette.WHITE)
			c.rect(34, 11, 10, 2, Color(1, 1, 1, 0.6))
			c.rect(10, 29, 18, 7, Color("#1a1a1f"))
			c.line(14, 34, 22, 30, Color("#9a9aa5"))
			c.rect(40, 29, 12, 6, Color("#d3cfc8"))
			c.px(56, 30, NEON_CYAN)
		"shelf_bottles":
			c.rect(0, 0, w, h, Color(0.1, 0.05, 0.1, 0.35))
			for shelf: int in 2:
				var y: int = 18 + shelf * 20
				c.rect(0, y, w, 3, BAR_WOOD)
				c.hline(0, y + 3, w, Color(1.0, 0.31, 0.64, 0.5))
				var x: int = 4
				while x < w - 8:
					_bottle(x, rng.randi_range(0, 3), y - 14)
					x += rng.randi_range(8, 12)
		"neon_sign":
			c.rect(0, 0, w, h, Color(0.1, 0.03, 0.12, 0.6))
			_neon_line(PackedVector2Array([Vector2(10, 32), Vector2(24, 10), Vector2(34, 26), Vector2(48, 8)]), NEON_PINK)
			c.ellipse(70, 22, 12, 12, Color(0.36, 0.88, 0.9, 0.25))
			_neon_ring(70, 22, 11, NEON_CYAN)
			_neon_line(PackedVector2Array([Vector2(88, 34), Vector2(104, 10)]), Color("#f7e04a"))
			c.ellipse(104, 9, 3, 3, Color("#f7e04a"))
		"rug_party":
			c.rect(0, 0, w, h, Color("#f0dcb4"))
			for i: int in 14:
				var x: int = 6 + i * 11 + rng.randi_range(-2, 2)
				var points: PackedVector2Array = PackedVector2Array()
				for step: int in 7:
					var y: float = step * h / 6.0
					points.append(Vector2(x + sin(step * 1.3 + i) * 4.0, y))
				for step: int in 6:
					c.line(roundi(points[step].x), roundi(points[step].y), roundi(points[step + 1].x), roundi(points[step + 1].y), Color("#b0302a"))
					c.line(roundi(points[step].x) + 1, roundi(points[step].y), roundi(points[step + 1].x) + 1, roundi(points[step + 1].y), Color("#b0302a"))
			c.rect(0, 0, w, 3, Color("#7a1f1a"))
			c.rect(0, h - 3, w, 3, Color("#7a1f1a"))
		_:
			return false
	return true


func _bottle(x: int, variant: int, y: int = 2) -> void:
	var colors: Array[Color] = [Color("#2f8f3a"), Color("#8a4a1c"), Color("#d9e8f0"), Color("#5a2a7a")]
	var bottle: Color = colors[variant % colors.size()]
	c.rect(x, y + 5, 5, 9, bottle)
	c.rect(x + 1, y, 3, 5, bottle)
	c.vline(x + 1, y + 6, 6, Palette.light(bottle, 0.3))
	c.rect(x, y + 8, 5, 3, Palette.WHITE if variant != 2 else Palette.ALFA_RED)


func _neon_line(points: PackedVector2Array, color: Color) -> void:
	for i: int in points.size() - 1:
		for offset: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			c.line(roundi(points[i].x) + offset.x, roundi(points[i].y) + offset.y, roundi(points[i + 1].x) + offset.x, roundi(points[i + 1].y) + offset.y, Color(color, 0.3))
		c.line(roundi(points[i].x), roundi(points[i].y), roundi(points[i + 1].x), roundi(points[i + 1].y), Palette.light(color, 0.3))


func _neon_ring(cx: int, cy: int, radius: int, color: Color) -> void:
	for step: int in 48:
		var angle: float = TAU * step / 48.0
		var p: Vector2 = Vector2(cx, cy) + Vector2(cos(angle), sin(angle)) * radius
		c.px(roundi(p.x), roundi(p.y), Palette.light(color, 0.3))
		c.px(roundi(p.x) + 1, roundi(p.y), Color(color, 0.35))
