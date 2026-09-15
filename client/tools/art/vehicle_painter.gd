class_name VehiclePainter
extends RefCounted
## Paints side-view vehicles (facing right) and rotating wheel frames for VehicleCatalog.

const GLASS: Color = Color("#2a3444")
const GLASS_LIGHT: Color = Color("#5d7088")
const TRIM: Color = Color("#1c1c22")
const TIRE: Color = Color("#1e1e22")
const TAIL: Color = Color("#d0202a")
const HEAD: Color = Color("#fff4cf")
const AMBER: Color = Color("#f2a33a")

var c: PixelCanvas


func paint(id: String) -> void:
	match id:
		"vaz2104":
			_vaz2104(false)
		"vaz2104_driver":
			_vaz2104(true)
		"bmw5":
			_bmw5(false)
		"bmw5_driver":
			_bmw5(true)
		"audi_rs6":
			_audi_rs6(false)
		"audi_rs6_driver":
			_audi_rs6(true)
		"bmw850":
			_bmw850(false)
		"bmw850_driver":
			_bmw850(true)
		"sedan_blue":
			_sedan(Color("#3a64a8"), false)
		"sedan_white":
			_sedan(Color("#e8e8ea"), false)
		"sedan_black":
			_sedan(Color("#2a2c33"), false)
		"taxi":
			_sedan(Color("#f2c230"), true)
		"hatch_green":
			_hatch(Color("#4f8f5a"))
		"hatch_orange":
			_hatch(Color("#e0782f"))
		"suv_grey":
			_suv(Color("#7d838c"))
		"van_white":
			_van(Color("#eceef0"))
		"bus":
			_bus(Palette.ALFA_RED)
		"wheel_bmw", "wheel_steel", "wheel_alloy", "wheel_bus", "wheel_vaz", "wheel_bmw5", "wheel_rs6":
			_wheel_strip(id)
		_:
			push_warning("Unknown vehicle '%s'" % id)


# --- Shared body shading -----------------------------------------------------


## Fills a body polygon with a vertical light-to-dark ramp, a sky reflection band and a crisp sill.
func _body(points: PackedVector2Array, color: Color, reflection_y: int, sill_y: int) -> void:
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	for y: int in range(floori(bounds.position.y), ceili(bounds.end.y) + 1):
		var t: float = (y - bounds.position.y) / maxf(1.0, bounds.size.y)
		var row_color: Color = Palette.light(color, 0.12) if t < 0.2 else (color if t < 0.55 else Palette.shade(color, 0.12))
		if y >= sill_y:
			row_color = Palette.shade(color, 0.26)
		for x: int in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				c.px(x, y, row_color)
	for x: int in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
		if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, reflection_y + 0.5), points):
			c.px(x, reflection_y, Palette.light(color, 0.28))


func _glass(points: PackedVector2Array) -> void:
	c.polygon(points, GLASS)
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	# Diagonal highlight, kept strictly inside the glass shape.
	var x0: int = floori(bounds.position.x + bounds.size.x * 0.3)
	for i: int in 3:
		for step: int in ceili(bounds.size.y) + 1:
			var x: int = x0 + i + step
			var y: int = ceili(bounds.end.y) - step
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				c.px(x, y, GLASS_LIGHT)


## Dark semicircular cut-out above an axle so the wheel sits inside the body.
func _arch(cx: int, cy: int, radius: float) -> void:
	for y: int in range(cy - ceili(radius), cy + 1):
		for x: int in range(cx - ceili(radius), cx + ceili(radius) + 1):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= radius and c.get_px(x, y).a > 0.0:
				c.px(x, y, TRIM)


## Driver silhouette, painted only over glass pixels so it never pokes through the roof.
func _driver(x: int, y: int) -> void:
	var silhouette: Color = Color("#141820")
	for yy: int in range(y - 5, y + 8):
		for xx: int in range(x - 5, x + 6):
			var in_head: bool = Vector2((xx + 0.5 - x) / 3.5, (yy + 0.5 - y) / 4.0).length_squared() <= 1.0
			var in_shoulders: bool = yy >= y + 3 and xx >= x - 4 and xx <= x + 4
			var current: Color = c.get_px(xx, yy)
			if (in_head or in_shoulders) and (current == GLASS or current == GLASS_LIGHT):
				c.px(xx, yy, silhouette)


func _door_line(x: int, top: int, bottom: int, color: Color) -> void:
	c.vline(x, top, bottom - top, Palette.shade(color, 0.3))


# --- BMW 850 CSi --------------------------------------------------------------


func _bmw850(with_driver: bool) -> void:
	var red: Color = Color("#c3161f")
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 18), Vector2(8, 15), Vector2(22, 14), Vector2(34, 13), Vector2(46, 5), Vector2(52, 4),
		Vector2(64, 4), Vector2(70, 6), Vector2(82, 15), Vector2(100, 16.5), Vector2(118, 18.5), Vector2(128, 21),
		Vector2(131, 24), Vector2(130, 30), Vector2(126, 33), Vector2(4, 33), Vector2(1, 29),
	])
	_body(body, red, 19, 30)
	_glass(PackedVector2Array([Vector2(36, 13.5), Vector2(47, 6.5), Vector2(63, 6), Vector2(68, 7.5), Vector2(78, 14.5)]))
	c.line(47, 7, 44, 13, Color("#3c4658"))
	if with_driver:
		_driver(62, 10)
	c.line(46, 5, 34, 13, Palette.shade(red, 0.3))
	c.line(70, 6, 82, 15, Palette.shade(red, 0.3))
	# Black window surround and pop-up headlight cover seam.
	c.line(36, 14, 78, 15, TRIM)
	c.line(47, 6, 63, 5, TRIM)
	c.line(104, 17, 118, 18, Palette.shade(red, 0.25))
	c.vline(104, 17, 2, Palette.shade(red, 0.25))
	c.vline(118, 18, 2, Palette.shade(red, 0.25))
	# Body details: rubbing strip, door, handle, mirror, sill, lights, kidney grille edge.
	c.hline(6, 23, 120, TRIM)
	c.hline(6, 24, 120, Palette.shade(red, 0.35))
	_door_line(56, 14, 30, red)
	_door_line(83, 15, 30, red)
	c.rect(60, 17, 5, 1, TRIM)
	c.polygon(PackedVector2Array([Vector2(76, 12), Vector2(82, 11), Vector2(82, 15), Vector2(77, 15)]), Palette.shade(red, 0.1))
	c.px(81, 12, TRIM)
	c.hline(10, 31, 112, Palette.shade(red, 0.4))
	c.rect(125, 21, 5, 3, HEAD)
	c.rect(127, 25, 4, 2, AMBER)
	c.rect(129, 27, 2, 3, TRIM)
	c.line(118, 18, 127, 21, Palette.light(red, 0.25))
	c.rect(1, 18, 4, 5, TAIL)
	c.px(2, 19, Color("#ff6a5c"))
	c.rect(1, 24, 3, 2, AMBER)
	c.rect(4, 31, 6, 2, Color("#6a6a70"))
	# Hood vents and badge.
	c.hline(96, 17, 6, Palette.shade(red, 0.2))
	c.px(124, 22, Color("#3a7bd5"))
	_arch(31, 31, 10.5)
	_arch(101, 31, 10.5)


# --- Player cars -----------------------------------------------------------------


## Matte paint: a flat ramp with only a faint top light, no glossy reflection band.
func _matte_body(points: PackedVector2Array, color: Color, sill_y: int) -> void:
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	for y: int in range(floori(bounds.position.y), ceili(bounds.end.y) + 1):
		var t: float = (y - bounds.position.y) / maxf(1.0, bounds.size.y)
		var row_color: Color = Palette.light(color, 0.05) if t < 0.25 else (color if t < 0.7 else Palette.shade(color, 0.06))
		if y >= sill_y:
			row_color = Palette.shade(color, 0.2)
		for x: int in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				c.px(x, y, row_color)


## Soft highlight arc over a wheel arch, for flared fenders.
func _fender(cx: int, top_y: int, color: Color) -> void:
	c.line(cx - 12, top_y + 3, cx - 5, top_y, color)
	c.line(cx - 5, top_y, cx + 6, top_y, color)
	c.line(cx + 6, top_y, cx + 12, top_y + 3, color)


func _vaz2104(with_driver: bool) -> void:
	var white: Color = Color("#eeece6")
	var chrome: Color = Color("#a3a8b0")
	var bumper: Color = Color("#3a3a40")
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 31), Vector2(0, 28), Vector2(1, 25), Vector2(2, 22), Vector2(3, 4), Vector2(5, 2),
		Vector2(68, 2), Vector2(71, 3), Vector2(84, 14), Vector2(88, 15), Vector2(104, 16), Vector2(107, 18),
		Vector2(107, 27), Vector2(106, 31),
	])
	_body(body, white, 18, 29)
	_glass(PackedVector2Array([Vector2(6, 5), Vector2(68, 5), Vector2(79, 14.5), Vector2(6, 14.5)]))
	if with_driver:
		_driver(66, 9)
	# Pillars: body-coloured C pillar of the wagon, black B pillar, chrome window surround.
	c.rect(34, 5, 2, 10, white)
	c.vline(35, 5, 10, Palette.shade(white, 0.1))
	c.rect(57, 4, 2, 11, TRIM)
	c.hline(6, 4, 63, chrome)
	c.line(68, 4, 80, 14, chrome)
	c.hline(6, 15, 76, chrome)
	c.hline(6, 3, 62, Palette.shade(white, 0.12))
	# Doors, handles, fuel cap, rubbing strip.
	_door_line(35, 15, 29, white)
	_door_line(58, 15, 29, white)
	_door_line(82, 15, 28, white)
	c.rect(38, 17, 4, 1, chrome)
	c.rect(61, 17, 4, 1, chrome)
	c.rect(11, 17, 3, 3, Palette.shade(white, 0.14))
	c.rect(4, 23, 101, 2, TRIM)
	c.hline(4, 22, 101, Color("#c7cbd0"))
	# Lights, bumpers with an aluminium strip, mirror, mudflaps.
	c.rect(0, 12, 3, 9, TAIL)
	c.px(1, 13, Color("#ff6a5c"))
	c.rect(0, 21, 3, 2, AMBER)
	c.rect(104, 18, 4, 4, HEAD)
	c.px(105, 19, Palette.WHITE)
	c.rect(104, 22, 3, 2, AMBER)
	c.rect(106, 24, 2, 3, TRIM)
	c.rect(0, 26, 9, 4, bumper)
	c.hline(0, 27, 9, Color("#b9bdc3"))
	c.rect(97, 26, 11, 4, bumper)
	c.hline(97, 27, 11, Color("#b9bdc3"))
	c.rect(81, 11, 3, 3, TRIM)
	_arch(23, 30, 9.0)
	_arch(86, 30, 9.0)
	c.rect(12, 27, 2, 7, TRIM)
	c.rect(75, 27, 2, 6, TRIM)


func _bmw5(with_driver: bool) -> void:
	var silver: Color = Color("#c3c7cc")
	var chrome: Color = Color("#eef0f2")
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(3, 32), Vector2(0, 27), Vector2(1, 20), Vector2(3, 16), Vector2(22, 14), Vector2(38, 5),
		Vector2(48, 3), Vector2(70, 3), Vector2(78, 5), Vector2(95, 14), Vector2(110, 16), Vector2(122, 18),
		Vector2(126, 20), Vector2(127, 26), Vector2(125, 32),
	])
	_body(body, silver, 17, 30)
	_glass(PackedVector2Array([
		Vector2(32, 14), Vector2(31, 11), Vector2(40, 6.5), Vector2(49, 5.5), Vector2(70, 5.5), Vector2(77, 7), Vector2(91, 14.5),
	]))
	if with_driver:
		_driver(76, 10)
	c.rect(59, 5, 2, 10, TRIM)
	c.vline(43, 7, 8, TRIM)
	# Chrome window line, rear window edge, character line.
	c.line(39, 5, 48, 4, chrome)
	c.hline(48, 4, 22, chrome)
	c.line(70, 4, 78, 6, chrome)
	c.line(31, 15, 92, 15, chrome)
	c.line(22, 14, 37, 6, Palette.shade(silver, 0.2))
	c.line(30, 20, 118, 19, Palette.light(silver, 0.3))
	c.line(30, 21, 118, 20, Palette.shade(silver, 0.12))
	_door_line(37, 15, 29, silver)
	_door_line(61, 15, 30, silver)
	_door_line(89, 15, 28, silver)
	c.rect(41, 17, 5, 1, chrome)
	c.rect(65, 17, 5, 1, chrome)
	c.rect(91, 22, 5, 1, chrome)
	c.polygon(PackedVector2Array([Vector2(87, 11), Vector2(93, 10), Vector2(93, 14), Vector2(88, 14)]), Palette.light(silver, 0.1))
	c.hline(88, 14, 5, TRIM)
	# Lights, kidney grille edge, trunk lip, exhaust.
	c.rect(120, 18, 6, 3, HEAD)
	c.px(121, 19, Color("#bfe3ff"))
	c.px(124, 19, Color("#bfe3ff"))
	c.rect(125, 21, 2, 4, TRIM)
	c.px(126, 21, chrome)
	c.rect(0, 16, 4, 5, TAIL)
	c.hline(1, 17, 3, Color("#ff6a5c"))
	c.hline(4, 15, 17, Palette.light(silver, 0.25))
	c.rect(3, 31, 5, 2, Color("#6a6a70"))
	c.hline(8, 28, 112, Palette.shade(silver, 0.3))
	_arch(28, 30, 10.0)
	_arch(105, 30, 10.0)


func _audi_rs6(with_driver: bool) -> void:
	var matte: Color = Color("#5c5f63")
	var aluminium: Color = Color("#b9bcc0")
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(3, 34), Vector2(0, 30), Vector2(1, 22), Vector2(2, 16), Vector2(5, 8), Vector2(9, 5),
		Vector2(14, 4), Vector2(66, 3), Vector2(74, 4), Vector2(93, 15), Vector2(112, 18), Vector2(125, 20),
		Vector2(129, 23), Vector2(129, 30), Vector2(126, 34),
	])
	_matte_body(body, matte, 31)
	_glass(PackedVector2Array([
		Vector2(11, 9), Vector2(18, 6.5), Vector2(66, 5.5), Vector2(73, 6.5), Vector2(89, 15.5), Vector2(13, 14),
	]))
	if with_driver:
		_driver(78, 10)
	c.rect(38, 6, 2, 9, TRIM)
	c.rect(62, 5, 2, 11, TRIM)
	# Roof rails, aluminium window surround and belt line, roof spoiler.
	c.hline(18, 2, 46, aluminium)
	c.px(18, 3, aluminium)
	c.px(63, 3, aluminium)
	c.line(11, 8, 18, 5, aluminium)
	c.line(18, 5, 66, 4, aluminium)
	c.line(66, 4, 74, 5, aluminium)
	c.line(13, 15, 89, 16, aluminium)
	c.rect(4, 4, 7, 2, TRIM)
	# Flared arches, doors, flush handles, black mirror.
	_fender(27, 18, Palette.light(matte, 0.12))
	_fender(103, 19, Palette.light(matte, 0.12))
	_door_line(39, 16, 30, matte)
	_door_line(63, 16, 30, matte)
	_door_line(90, 17, 29, matte)
	c.rect(43, 19, 5, 1, Palette.shade(matte, 0.2))
	c.rect(67, 19, 5, 1, Palette.shade(matte, 0.2))
	c.polygon(PackedVector2Array([Vector2(86, 12), Vector2(92, 11), Vector2(92, 15), Vector2(87, 15)]), TRIM)
	# Aluminium side blade, LED lights, big intake, diffuser and oval exhaust.
	c.hline(38, 31, 54, aluminium)
	c.hline(38, 32, 54, Palette.shade(aluminium, 0.3))
	c.rect(1, 17, 4, 3, TAIL)
	c.hline(1, 18, 4, Color("#ff5a4c"))
	c.rect(121, 19, 7, 2, HEAD)
	c.hline(121, 21, 6, Color("#bfe3ff"))
	c.rect(126, 23, 3, 8, TRIM)
	for hx: int in [126, 128]:
		c.px(hx, 25, Color("#3a3a44"))
		c.px(hx, 28, Color("#3a3a44"))
	c.rect(0, 31, 11, 3, TRIM)
	c.rect(2, 32, 5, 2, Color("#9aa0a8"))
	c.px(3, 32, TRIM)
	_arch(27, 30, 11.0)
	_arch(103, 30, 11.0)


# --- Generic traffic ----------------------------------------------------------


func _sedan(color: Color, taxi: bool) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 22), Vector2(10, 19), Vector2(26, 18), Vector2(38, 9), Vector2(48, 7), Vector2(76, 7),
		Vector2(86, 10), Vector2(96, 18), Vector2(116, 20), Vector2(122, 24), Vector2(122, 34), Vector2(118, 36),
		Vector2(4, 36), Vector2(1, 32),
	])
	_body(body, color, 22, 33)
	_glass(PackedVector2Array([Vector2(28, 18), Vector2(40, 10), Vector2(60, 9.5), Vector2(60, 18)]))
	_glass(PackedVector2Array([Vector2(62, 9.5), Vector2(76, 9.5), Vector2(85, 11), Vector2(93, 18), Vector2(62, 18)]))
	_door_line(60, 18, 33, color)
	_door_line(92, 18, 33, color)
	c.rect(64, 21, 5, 1, TRIM)
	c.rect(40, 21, 5, 1, TRIM)
	c.rect(118, 22, 4, 3, HEAD)
	c.rect(2, 22, 3, 4, TAIL)
	c.hline(4, 34, 116, TRIM)
	if taxi:
		c.rect(52, 1, 16, 6, Color("#2a2a2a"))
		c.rect(53, 2, 14, 4, Color("#fff4cf"))
		for x: int in range(10, 116, 4):
			c.rect(x, 26, 2, 2, TRIM)
			c.rect(x + 2, 28, 2, 2, TRIM)
	_arch(30, 33, 10)
	_arch(96, 33, 10)


func _hatch(color: Color) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(3, 12), Vector2(10, 7), Vector2(58, 6), Vector2(70, 10), Vector2(80, 18), Vector2(98, 21),
		Vector2(104, 25), Vector2(104, 34), Vector2(100, 36), Vector2(4, 36), Vector2(2, 32),
	])
	_body(body, color, 22, 33)
	_glass(PackedVector2Array([Vector2(8, 10), Vector2(12, 8.5), Vector2(36, 8.5), Vector2(36, 18), Vector2(6, 18)]))
	_glass(PackedVector2Array([Vector2(38, 8.5), Vector2(58, 8.5), Vector2(68, 11), Vector2(77, 18), Vector2(38, 18)]))
	_door_line(37, 18, 33, color)
	_door_line(76, 18, 33, color)
	c.rect(42, 21, 5, 1, TRIM)
	c.rect(100, 23, 4, 3, HEAD)
	c.rect(2, 14, 3, 6, TAIL)
	c.hline(4, 34, 96, TRIM)
	_arch(22, 33, 10)
	_arch(84, 33, 10)


func _suv(color: Color) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 10), Vector2(8, 5), Vector2(80, 4), Vector2(90, 8), Vector2(100, 19), Vector2(122, 22),
		Vector2(126, 27), Vector2(126, 42), Vector2(122, 44), Vector2(4, 44), Vector2(1, 40),
	])
	_body(body, color, 25, 40)
	_glass(PackedVector2Array([Vector2(8, 8), Vector2(12, 7), Vector2(44, 7), Vector2(44, 20), Vector2(6, 20)]))
	_glass(PackedVector2Array([Vector2(46, 7), Vector2(80, 7), Vector2(88, 10), Vector2(97, 20), Vector2(46, 20)]))
	_door_line(45, 20, 40, color)
	_door_line(96, 20, 40, color)
	c.rect(50, 24, 6, 1, TRIM)
	c.rect(10, 1, 70, 2, Color("#3a3a40"))
	c.rect(121, 24, 5, 3, HEAD)
	c.rect(2, 12, 3, 7, TAIL)
	c.rect(4, 38, 118, 4, Color("#3a3a40"))
	_arch(30, 40, 11)
	_arch(100, 40, 11)


func _van(color: Color) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 3), Vector2(104, 2), Vector2(114, 8), Vector2(124, 24), Vector2(136, 28), Vector2(138, 34),
		Vector2(138, 50), Vector2(134, 52), Vector2(4, 52), Vector2(1, 48),
	])
	_body(body, color, 30, 48)
	_glass(PackedVector2Array([Vector2(106, 6), Vector2(112, 9), Vector2(121, 24), Vector2(104, 24)]))
	_door_line(100, 4, 48, color)
	c.rect(10, 16, 80, 16, Palette.shade(color, 0.04))
	c.rect(14, 20, 12, 8, Palette.ALFA_RED)
	c.rect(30, 22, 50, 3, Color("#9aa0a8"))
	c.rect(30, 27, 36, 2, Color("#9aa0a8"))
	c.rect(134, 30, 4, 4, HEAD)
	c.rect(1, 8, 3, 12, TAIL)
	c.hline(4, 50, 132, TRIM)
	_arch(30, 48, 10)
	_arch(108, 48, 10)


func _bus(color: Color) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(2, 4), Vector2(292, 2), Vector2(298, 8), Vector2(298, 74), Vector2(294, 78), Vector2(4, 78), Vector2(1, 74),
	])
	_body(body, color, 36, 72)
	for x: int in range(12, 270, 30):
		_glass(PackedVector2Array([Vector2(x, 10), Vector2(x + 26, 10), Vector2(x + 26, 34), Vector2(x, 34)]))
	_glass(PackedVector2Array([Vector2(276, 8), Vector2(294, 8), Vector2(296, 46), Vector2(276, 46)]))
	c.rect(250, 38, 22, 36, GLASS)
	c.vline(261, 38, 36, TRIM)
	c.rect(8, 2, 284, 3, Palette.WHITE)
	c.rect(20, 44, 120, 12, Palette.WHITE)
	c.rect(24, 47, 12, 7, color)
	c.rect(40, 48, 90, 4, Palette.shade(color, 0.1))
	c.rect(294, 60, 4, 6, HEAD)
	c.rect(1, 58, 3, 10, TAIL)
	c.hline(4, 76, 290, TRIM)
	_arch(62, 72, 15)
	_arch(232, 72, 15)


# --- Wheels ---------------------------------------------------------------------


func _wheel_strip(id: String) -> void:
	var diameter: int = VehicleCatalog.WHEELS[id]
	var radius: float = diameter / 2.0
	var rim_colors: Dictionary[String, Color] = {
		"wheel_bmw": Color("#c9bfa6"), "wheel_steel": Color("#6e737b"), "wheel_alloy": Color("#b9bec6"), "wheel_bus": Color("#9aa0a8"),
		"wheel_vaz": Color("#c3c7cc"), "wheel_bmw5": Color("#d9dbdd"), "wheel_rs6": Color("#8a8e94"),
	}
	var spoke_counts: Dictionary[String, int] = {"wheel_bmw": 5, "wheel_steel": 8, "wheel_vaz": 6, "wheel_bmw5": 10, "wheel_rs6": 10}
	var rim_color: Color = rim_colors[id]
	var spokes: int = spoke_counts.get(id, 6)
	var cell_origin: Vector2i = c.origin
	var cell_clip: Rect2i = c.clip
	for frame: int in VehicleCatalog.WHEEL_FRAMES:
		c.origin = cell_origin + Vector2i(frame * diameter, 0)
		c.clip = Rect2i(c.origin, Vector2i(diameter, diameter))
		c.ellipse(radius, radius, radius, radius, TIRE)
		c.ellipse(radius, radius, radius - 0.8, radius - 0.8, Color("#2a2a30"))
		var rotation: float = TAU / spokes * frame / VehicleCatalog.WHEEL_FRAMES
		match id:
			"wheel_vaz":
				# Stamped steel rim with round slots and a small chrome cap.
				c.ellipse(radius, radius, radius * 0.72, radius * 0.72, rim_color)
				for hole: int in spokes:
					var angle: float = rotation + TAU * hole / spokes
					var at: Vector2 = Vector2(radius, radius) + Vector2(cos(angle), sin(angle)) * radius * 0.45
					c.px(floori(at.x), floori(at.y), Palette.shade(rim_color, 0.45))
				c.ellipse(radius, radius, 2.2, 2.2, Palette.light(rim_color, 0.25))
				c.px(floori(radius), floori(radius), Palette.shade(rim_color, 0.3))
			"wheel_rs6":
				# Dark multi-spoke rim with a red brake caliper that does not rotate.
				c.ellipse(radius, radius, radius * 0.74, radius * 0.74, Color("#2e3034"))
				c.rect(roundi(radius) + 2, roundi(radius) - 5, 3, 5, Color("#d01f25"))
				for spoke: int in spokes:
					var angle: float = rotation + TAU * spoke / spokes
					var tip: Vector2 = Vector2(radius, radius) + Vector2(cos(angle), sin(angle)) * radius * 0.7
					c.line(floori(radius), floori(radius), roundi(tip.x - 0.5), roundi(tip.y - 0.5), rim_color if spoke % 2 == 0 else Color("#4a4d52"))
				c.ellipse(radius, radius, 1.8, 1.8, Color("#3a3c40"))
			_:
				c.ellipse(radius, radius, radius * 0.66, radius * 0.66, Palette.shade(rim_color, 0.3))
				for spoke: int in spokes:
					var angle: float = rotation + TAU * spoke / spokes
					var tip: Vector2 = Vector2(radius, radius) + Vector2(cos(angle), sin(angle)) * radius * 0.62
					c.line(floori(radius), floori(radius), roundi(tip.x - 0.5), roundi(tip.y - 0.5), rim_color)
					if id == "wheel_bmw":
						var side: Vector2 = Vector2(cos(angle + 0.25), sin(angle + 0.25)) * radius * 0.55
						c.line(floori(radius), floori(radius), roundi(radius + side.x - 0.5), roundi(radius + side.y - 0.5), rim_color)
				c.ellipse(radius, radius, 1.6, 1.6, Palette.light(rim_color, 0.2))
		c.px(floori(radius) - 2, floori(radius * 0.35), Color(1, 1, 1, 0.25))
	c.origin = cell_origin
	c.clip = cell_clip
