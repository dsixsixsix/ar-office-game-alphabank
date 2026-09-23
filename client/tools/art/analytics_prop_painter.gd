class_name AnalyticsPropPainter
extends PropPainterBase
## Product analytics floor: standing desks, phone booths, poufs, the dashboard wall, boards with
## sticky notes and a funnel, a neon chart, and the lift doors used on every floor.

const TEAL: Color = Color("#2fb3a6")
const NEON_CYAN: Color = Color("#5ce1e6")
const GRAPHITE: Color = Color("#2b2f38")
const STICKY: Array[Color] = [Color("#f7c948"), Color("#ff8fa3"), Color("#8fd6ff"), Color("#9be38f")]


func paint(id: String, w: int, h: int) -> bool:
	match id:
		"standing_desk":
			_standing_desk(w, h)
		"phone_booth":
			_phone_booth(w, h)
		"cube_pouf":
			ground_shadow(w / 2.0, h - 2, w / 2.0 - 2, 2)
			box(1, 4, w - 2, 5, h - 10, TEAL)
			c.hline(3, 6, w - 6, Palette.light(TEAL, 0.2))
			c.rect(w / 2 - 1, 11, 2, 2, Palette.shade(TEAL, 0.25))
		"data_wall":
			_data_wall(w, h)
		"kanban_board":
			_kanban(w, h)
		"funnel_board":
			_funnel(w, h)
		"neon_chart":
			c.rect(0, 0, w, h, Color(0.1, 0.1, 0.14, 0.85))
			var bars: Array[int] = [10, 16, 13, 24, 30]
			for i: int in bars.size():
				var bar_h: int = bars[i]
				var color: Color = Palette.ALFA_RED if i == bars.size() - 1 else NEON_CYAN
				c.rect(3 + i * 5, h - 5 - bar_h, 3, bar_h, color)
				c.vline(3 + i * 5, h - 5 - bar_h, bar_h, Palette.light(color, 0.3))
			c.hline(2, h - 4, w - 4, Color(NEON_CYAN, 0.6))
		"elevator":
			_elevator(w, h)
		_:
			return false
	return true


func _standing_desk(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 3)
	for leg_x: int in [6, w - 9]:
		c.rect(leg_x, 26, 3, h - 30, METAL)
		c.rect(leg_x - 3, h - 5, 9, 2, INK)
	box(0, 22, w, 6, 3, WHITE_DESK)
	c.hline(0, 22, w, Palette.light(WHITE_DESK, 0.2))
	screen(6, 2, 22, 17, true)
	screen(w - 28, 2, 22, 17, false)
	c.rect(15, 19, 4, 3, INK)
	c.rect(w - 19, 19, 4, 3, INK)
	c.rect(w / 2 - 6, 24, 12, 2, INK)
	c.rect(w / 2 + 9, 23, 5, 3, Palette.ALFA_RED)


func _phone_booth(w: int, h: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 1)
	c.rect(0, 0, w, h - 3, GRAPHITE)
	c.rect(0, 0, w, 5, Palette.shade(GRAPHITE, 0.2))
	c.hline(2, 2, w - 4, TEAL)
	c.rect(3, 8, w - 6, h - 16, Color(0.72, 0.88, 0.95, 0.55))
	c.line(5, 12, 12, 8, Color(1, 1, 1, 0.35))
	c.line(5, 22, 18, 10, Color(1, 1, 1, 0.2))
	c.rect(w / 2 - 5, h - 26, 10, 4, TEAL)
	c.rect(w / 2 - 1, h - 22, 2, 12, METAL)
	c.rect(w - 6, h / 2, 2, 8, METAL)
	c.rect(2, h - 8, w - 4, 5, Palette.shade(GRAPHITE, 0.1))


func _data_wall(w: int, h: int) -> void:
	c.rect(0, 0, w, h, INK)
	var tiles: Array[Rect2i] = [Rect2i(2, 2, 40, 26), Rect2i(43, 2, 40, 26), Rect2i(84, 2, 38, 26), Rect2i(2, 29, 60, 27), Rect2i(63, 29, 59, 27)]
	for index: int in tiles.size():
		var tile: Rect2i = tiles[index]
		c.rect(tile.position.x, tile.position.y, tile.size.x, tile.size.y, Color("#141a26"))
		c.hline(tile.position.x, tile.position.y, tile.size.x, Color("#2b3550"))
		var x: int = tile.position.x + 3
		var bottom: int = tile.end.y - 3
		match index:
			0:
				for i: int in 7:
					var bar_h: int = 4 + (i * 5 + 3) % 15
					c.rect(x + i * 5, bottom - bar_h, 3, bar_h, NEON_CYAN if i != 5 else Palette.ALFA_RED)
			1:
				var points: Array[int] = [16, 14, 15, 10, 11, 7, 5, 6]
				for i: int in range(1, points.size()):
					c.line(x + (i - 1) * 5, tile.position.y + points[i - 1], x + i * 5, tile.position.y + points[i], Color("#9be38f"))
				c.px(x + 35, tile.position.y + 6, Palette.ALFA_RED)
			2:
				c.ellipse(tile.position.x + 19, tile.position.y + 13, 9, 9, Color("#3a4560"))
				c.polygon(PackedVector2Array([Vector2(tile.position.x + 19, tile.position.y + 13), Vector2(tile.position.x + 19, tile.position.y + 4), Vector2(tile.position.x + 28, tile.position.y + 12)]), Palette.ALFA_RED)
				c.polygon(PackedVector2Array([Vector2(tile.position.x + 19, tile.position.y + 13), Vector2(tile.position.x + 28, tile.position.y + 13), Vector2(tile.position.x + 21, tile.position.y + 22)]), NEON_CYAN)
			3:
				for row: int in 5:
					c.hline(x, tile.position.y + 5 + row * 4, 20, Color("#3a4560"))
					c.hline(x + 24, tile.position.y + 5 + row * 4, 8 + (row * 7) % 22, Color("#f7c948") if row == 1 else Color("#8fa3bf"))
			4:
				c.hline(x, bottom - 1, tile.size.x - 6, Color("#3a4560"))
				for i: int in 10:
					var height: int = 3 + int(abs(sin(i * 0.9)) * 16.0)
					c.rect(x + i * 5, bottom - 1 - height, 3, height, TEAL if i % 3 else Palette.ALFA_RED)
	c.rect(w / 2 - 8, h - 2, 16, 2, METAL)


func _kanban(w: int, h: int) -> void:
	c.rect(0, 0, w, h - 3, Color("#aeb3ba"))
	c.rect(2, 2, w - 4, h - 7, Palette.WHITE)
	var columns: int = 3
	var column_w: int = (w - 4) / columns
	for column: int in columns:
		var x: int = 2 + column * column_w
		if column > 0:
			c.vline(x, 3, h - 9, Color("#c9ced6"))
		c.rect(x + 3, 4, column_w - 6, 3, [Color("#8fa3bf"), Color("#f7c948"), Color("#9be38f")][column])
		var notes: int = 3 - column + (1 if column == 2 else 0)
		for note: int in notes:
			var color: Color = STICKY[(column * 2 + note) % STICKY.size()]
			var nx: int = x + 3 + (note % 2) * 8
			var ny: int = 10 + (note / 2) * 11 + note * 3
			c.rect(nx, ny, 8, 8, color)
			c.hline(nx + 1, ny + 2, 5, Palette.shade(color, 0.3))
			c.hline(nx + 1, ny + 4, 4, Palette.shade(color, 0.3))
	c.rect(4, h - 3, w - 8, 2, METAL)


func _funnel(w: int, h: int) -> void:
	c.rect(0, 0, w, h - 3, Color("#aeb3ba"))
	c.rect(2, 2, w - 4, h - 7, Palette.WHITE)
	var widths: Array[int] = [44, 34, 24, 14]
	var colors: Array[Color] = [Color("#8fa3bf"), Color("#6f8fc0"), Color("#3a7bd5"), Palette.ALFA_RED]
	for i: int in widths.size():
		var bar_w: int = widths[i]
		c.rect((w - bar_w) / 2, 6 + i * 8, bar_w, 6, colors[i])
		c.hline((w - bar_w) / 2, 6 + i * 8, bar_w, Palette.light(colors[i], 0.2))
	c.line(w - 10, 8, w - 6, 34, Color("#24222a"))
	c.rect(4, h - 3, w - 8, 2, METAL)


## Brushed-steel lift doors with a red frame and a floor indicator.
func _elevator(w: int, h: int) -> void:
	var steel: Color = Color("#b9bec6")
	c.rect(0, 0, w, h, Palette.shade(Palette.ALFA_RED, 0.1))
	c.rect(0, 0, w, 10, Color("#23232a"))
	for i: int in 3:
		c.rect(w / 2 - 10 + i * 8, 3, 5, 4, Palette.ALFA_RED if i == 1 else Color("#3a3a44"))
	c.rect(4, 12, w - 8, h - 12, steel)
	c.vline(w / 2, 12, h - 12, Palette.shade(steel, 0.3))
	for x: int in range(6, w - 6, 4):
		c.vline(x, 14, h - 16, Palette.light(steel, 0.06) if x % 8 else Palette.shade(steel, 0.04))
	c.line(8, h - 6, 22, 16, Color(1, 1, 1, 0.25))
	c.line(w / 2 + 4, h - 10, w / 2 + 16, 18, Color(1, 1, 1, 0.18))
	c.rect(w - 3, h / 2 - 4, 3, 8, INK)
	c.px(w - 2, h / 2 - 2, Palette.ALFA_RED)
	c.px(w - 2, h / 2 + 1, Palette.WHITE)
