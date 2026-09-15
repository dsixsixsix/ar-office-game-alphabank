class_name PropPainterBase
extends RefCounted
## Shared 3/4-view helpers for prop painters. Subclasses implement paint(id, w, h) -> bool.

const MARK_OUTER: PackedVector2Array = [Vector2(0.36, 0.0), Vector2(0.64, 0.0), Vector2(0.95, 0.72), Vector2(0.05, 0.72)]
const MARK_COUNTER: PackedVector2Array = [Vector2(0.5, 0.2), Vector2(0.6, 0.45), Vector2(0.4, 0.45)]
const MARK_GAP: PackedVector2Array = [Vector2(0.36, 0.58), Vector2(0.64, 0.58), Vector2(0.70, 0.72), Vector2(0.30, 0.72)]
const MARK_BAR: Rect2 = Rect2(0.05, 0.82, 0.9, 0.18)

const INK: Color = Color("#24222a")
const METAL: Color = Color("#8f949c")
const WALNUT: Color = Color("#7a5234")
const OAK: Color = Color("#c9a071")
const WHITE_DESK: Color = Color("#f2efe9")
const LEAF: Color = Color("#4f9a4a")

var c: PixelCanvas
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func paint(_id: String, _w: int, _h: int) -> bool:
	return false


## Box seen from above and in front: top face of `top_h` rows, then front face of `front_h` rows.
func box(x: int, y: int, w: int, top_h: int, front_h: int, color: Color) -> void:
	c.rect(x, y, w, top_h, Palette.light(color, 0.05))
	c.hline(x, y, w, Palette.light(color, 0.15))
	c.rect(x, y + top_h, w, front_h, Palette.shade(color, 0.1))
	c.hline(x, y + top_h, w, Palette.shade(color, 0.2))
	c.vline(x + w - 1, y + top_h, front_h, Palette.shade(color, 0.2))


func ground_shadow(cx: float, y: float, rx: float, ry: float = 3.0) -> void:
	c.ellipse(cx, y, rx, ry, Color(0.2, 0.12, 0.1, 0.18))


func mark(x: int, y: int, w: int, h: int, color: Color) -> void:
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


## Upholstered sofa or armchair seen from the front.
func sofa(w: int, h: int, color: Color, seats: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 2)
	var back: Color = Palette.shade(color, 0.08)
	c.rect(4, 2, w - 8, 18, back)
	c.hline(5, 1, w - 10, back)
	c.hline(5, 2, w - 10, Palette.light(back, 0.12))
	box(3, 16, w - 6, 12, h - 32, color)
	var seat_w: int = (w - 16) / seats
	for i: int in seats:
		var sx: int = 8 + i * seat_w
		c.rect(sx + 1, 4, seat_w - 2, 13, Palette.light(back, 0.04))
		c.vline(sx, 17, 11, Palette.shade(color, 0.08))
	for arm_x: int in [0, w - 9]:
		box(arm_x, 10, 9, 5, h - 16, Palette.shade(color, 0.03))
	c.rect(6, h - 3, 3, 2, INK)
	c.rect(w - 9, h - 3, 3, 2, INK)


func plant(w: int, h: int, pot: Color, leaves: int) -> void:
	ground_shadow(w / 2.0, h - 2, w / 2.0 - 3)
	var pot_w: int = maxi(10, w - 12)
	var pot_x: int = (w - pot_w) / 2
	var pot_h: int = maxi(10, h / 4)
	box(pot_x, h - pot_h - 2, pot_w, 3, pot_h - 1, pot)
	c.rect(pot_x + 2, h - pot_h - 2, pot_w - 4, 2, Color("#4a3322"))
	var top_y: int = h - pot_h - 2
	for i: int in leaves:
		var angle: float = rng.randf_range(-2.6, -0.5)
		var length: float = rng.randf_range(0.45, 1.0) * (top_y - 1)
		var tip: Vector2 = Vector2(w / 2.0, top_y) + Vector2(cos(angle) * w * 0.45, sin(angle) * length)
		var shade_amount: float = rng.randf_range(-0.12, 0.12)
		var leaf: Color = Palette.shade(LEAF, shade_amount) if shade_amount > 0 else Palette.light(LEAF, -shade_amount)
		c.line(w / 2, top_y, roundi(tip.x), roundi(tip.y), Palette.shade(LEAF, 0.2))
		c.ellipse(tip.x, tip.y, rng.randf_range(2.5, 4.5), rng.randf_range(1.5, 2.8), leaf)
		c.px(roundi(tip.x) - 1, roundi(tip.y) - 1, Palette.light(LEAF, 0.25))


func screen(x: int, y: int, w: int, h: int, dark: bool = false) -> void:
	c.rect(x, y, w, h, INK)
	var sx: int = x + 2
	var sy: int = y + 2
	var sw: int = w - 4
	var sh: int = h - 4
	c.rect(sx, sy, sw, sh, Color("#1d2433") if dark else Color("#f4f6f8"))
	c.rect(sx, sy, sw, maxi(2, sh / 6), Palette.ALFA_RED)
	for row: int in range(sy + sh / 6 + 2, sy + sh - 2, 3):
		c.hline(sx + 2, row, rng.randi_range(sw / 3, sw - 4), Color("#c9ced6") if not dark else Color("#3a4560"))
	c.rect(sx + sw - sw / 3, sy + sh - sh / 3, sw / 4, sh / 4, Palette.ALFA_RED)
	c.line(sx, sy + sh - 1, sx + sw / 3, sy, Color(1, 1, 1, 0.12))
