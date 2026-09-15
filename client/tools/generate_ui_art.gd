extends SceneTree
## Generates Alfa-coin spin frames and shop item icons.
## Run: godot --headless --path client --script res://tools/generate_ui_art.gd
## Icon column order must match "icon" in data/shop_catalog.json.

const COIN: int = 16
const COIN_FRAMES: int = 6
const ICON: int = 24
const ICON_COUNT: int = 16

const GOLD: Color = Color("#f7c948")
const GOLD_LIGHT: Color = Color("#ffe58a")
const GOLD_DARK: Color = Color("#c9951e")
const RED: Color = Color("#ef3124")
const RED_DARK: Color = Color("#c4251b")
const WHITE: Color = Color("#fbfaf8")
const GREY: Color = Color("#d8d1c6")
const INK: Color = Color("#2b2b30")
const CYAN: Color = Color("#5ac8d8")
const GREEN: Color = Color("#3f9e4a")
const BROWN: Color = Color("#8a5a2a")
const YELLOW: Color = Color("#f2c230")
const OUTLINE: Color = Color("#000000")

const MARK_OUTER: PackedVector2Array = [Vector2(0.36, 0.0), Vector2(0.64, 0.0), Vector2(0.95, 0.72), Vector2(0.05, 0.72)]
const MARK_COUNTER: PackedVector2Array = [Vector2(0.5, 0.2), Vector2(0.6, 0.45), Vector2(0.4, 0.45)]
const MARK_GAP: PackedVector2Array = [Vector2(0.36, 0.58), Vector2(0.64, 0.58), Vector2(0.70, 0.72), Vector2(0.30, 0.72)]
const MARK_BAR: Rect2 = Rect2(0.05, 0.82, 0.9, 0.18)


func _init() -> void:
	_save(_build_coin(), "res://assets/ui/alfa_coin.png")
	_save(_build_icons(), "res://assets/ui/shop_icons.png")
	quit()


func _save(image: Image, path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error: Error = image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])
	else:
		print("Saved ", path)


# --- Coin --------------------------------------------------------------------


func _build_coin() -> Image:
	var image: Image = Image.create_empty(COIN * COIN_FRAMES, COIN, false, Image.FORMAT_RGBA8)
	var widths: Array[float] = [7.0, 5.5, 3.0, 1.0, 3.0, 5.5]
	for frame: int in COIN_FRAMES:
		var o: Vector2i = Vector2i(frame * COIN, 0)
		var half_width: float = widths[frame]
		var center: Vector2 = Vector2(8, 8)
		for y: int in COIN:
			for x: int in COIN:
				var d: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / Vector2(half_width, 7.0)
				var length_sq: float = d.length_squared()
				if length_sq > 1.0:
					continue
				var color: Color = GOLD
				if length_sq > 0.62:
					color = GOLD_DARK
				elif d.x < -0.25 and d.y < -0.1:
					color = GOLD_LIGHT
				image.set_pixel(o.x + x, o.y + y, color)
		if half_width >= 5.0:
			var mark_w: int = 6 if half_width > 6.0 else 4
			_draw_mark(image, Rect2i(o.x + 8 - mark_w / 2, 4, mark_w, 8), RED)
	_add_outline(image, COIN)
	return image


func _draw_mark(image: Image, area: Rect2i, color: Color) -> void:
	for y: int in area.size.y:
		for x: int in area.size.x:
			var p: Vector2 = Vector2((x + 0.5) / area.size.x, (y + 0.5) / area.size.y)
			var in_letter: bool = (
				Geometry2D.is_point_in_polygon(p, MARK_OUTER)
				and not Geometry2D.is_point_in_polygon(p, MARK_COUNTER)
				and not Geometry2D.is_point_in_polygon(p, MARK_GAP)
			)
			if in_letter or MARK_BAR.has_point(p):
				image.set_pixel(area.position.x + x, area.position.y + y, color)


# --- Shop icons --------------------------------------------------------------


func _build_icons() -> Image:
	var image: Image = Image.create_empty(ICON * ICON_COUNT, ICON, false, Image.FORMAT_RGBA8)
	var painters: Array[Callable] = [
		_tshirt, _hoodie, _mug, _stickers, _thermos, _tote, _coffee_voucher,
		_food_voucher, _cinema, _taxi, _day_off, _job_swap, _powerbank, _parking, _cap, _backpack,
	]
	for index: int in painters.size():
		painters[index].call(image, Vector2i(index * ICON, 0))
	_add_outline(image, ICON)
	return image


func _r(image: Image, o: Vector2i, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(o.x + x, o.y + y, w, h), color)


func _tshirt(image: Image, o: Vector2i) -> void:
	_r(image, o, 6, 5, 12, 16, WHITE)
	_r(image, o, 2, 5, 5, 6, WHITE)
	_r(image, o, 17, 5, 5, 6, WHITE)
	_r(image, o, 10, 5, 4, 2, GREY)
	_draw_mark(image, Rect2i(o.x + 9, o.y + 10, 6, 7), RED)


func _hoodie(image: Image, o: Vector2i) -> void:
	_r(image, o, 6, 6, 12, 16, RED)
	_r(image, o, 2, 7, 5, 12, RED_DARK)
	_r(image, o, 17, 7, 5, 12, RED_DARK)
	_r(image, o, 8, 2, 8, 6, RED_DARK)
	_r(image, o, 10, 4, 4, 4, INK)
	_r(image, o, 9, 16, 6, 3, RED_DARK)


func _mug(image: Image, o: Vector2i) -> void:
	_r(image, o, 4, 6, 12, 14, WHITE)
	_r(image, o, 16, 9, 4, 2, WHITE)
	_r(image, o, 18, 9, 2, 7, WHITE)
	_r(image, o, 16, 14, 4, 2, WHITE)
	_r(image, o, 5, 6, 10, 2, BROWN)
	_draw_mark(image, Rect2i(o.x + 7, o.y + 10, 6, 7), RED)


func _stickers(image: Image, o: Vector2i) -> void:
	_r(image, o, 3, 5, 12, 12, CYAN)
	_r(image, o, 8, 9, 13, 12, WHITE)
	_draw_mark(image, Rect2i(o.x + 11, o.y + 11, 7, 8), RED)


func _thermos(image: Image, o: Vector2i) -> void:
	_r(image, o, 8, 3, 8, 3, INK)
	_r(image, o, 7, 6, 10, 16, RED)
	_r(image, o, 7, 12, 10, 3, WHITE)


func _tote(image: Image, o: Vector2i) -> void:
	_r(image, o, 4, 8, 16, 14, Color("#efe2cf"))
	_r(image, o, 7, 3, 2, 6, BROWN)
	_r(image, o, 15, 3, 2, 6, BROWN)
	_r(image, o, 7, 3, 10, 2, BROWN)
	_draw_mark(image, Rect2i(o.x + 8, o.y + 11, 8, 9), RED)


func _voucher(image: Image, o: Vector2i, color: Color) -> void:
	_r(image, o, 2, 6, 20, 13, color)
	_r(image, o, 2, 11, 2, 3, Color(0, 0, 0, 0))
	_r(image, o, 20, 11, 2, 3, Color(0, 0, 0, 0))
	_r(image, o, 15, 7, 1, 11, WHITE)


func _coffee_voucher(image: Image, o: Vector2i) -> void:
	_voucher(image, o, BROWN)
	_r(image, o, 6, 9, 6, 7, WHITE)
	_r(image, o, 12, 11, 2, 2, WHITE)


func _food_voucher(image: Image, o: Vector2i) -> void:
	_voucher(image, o, GREEN)
	_r(image, o, 5, 12, 9, 4, YELLOW)
	_r(image, o, 6, 9, 7, 3, BROWN)


func _cinema(image: Image, o: Vector2i) -> void:
	_voucher(image, o, RED)
	_r(image, o, 6, 9, 7, 7, INK)
	_r(image, o, 8, 11, 3, 3, WHITE)


func _taxi(image: Image, o: Vector2i) -> void:
	_r(image, o, 3, 10, 18, 8, YELLOW)
	_r(image, o, 6, 6, 12, 5, YELLOW)
	_r(image, o, 8, 7, 8, 3, CYAN)
	_r(image, o, 5, 17, 4, 4, INK)
	_r(image, o, 15, 17, 4, 4, INK)
	_r(image, o, 10, 12, 4, 2, INK)


func _day_off(image: Image, o: Vector2i) -> void:
	_r(image, o, 3, 5, 18, 17, WHITE)
	_r(image, o, 3, 5, 18, 5, RED)
	_r(image, o, 7, 2, 2, 5, INK)
	_r(image, o, 15, 2, 2, 5, INK)
	_r(image, o, 11, 12, 2, 8, BROWN)
	_r(image, o, 7, 11, 10, 2, GREEN)
	_r(image, o, 9, 13, 2, 2, GREEN)
	_r(image, o, 14, 13, 2, 2, GREEN)


func _job_swap(image: Image, o: Vector2i) -> void:
	_r(image, o, 5, 3, 14, 19, WHITE)
	_r(image, o, 10, 1, 4, 4, GREY)
	_r(image, o, 8, 7, 8, 6, Color("#e8b48a"))
	_r(image, o, 8, 7, 8, 2, BROWN)
	_r(image, o, 7, 15, 10, 2, RED)
	_r(image, o, 7, 18, 7, 1, INK)
	_r(image, o, 19, 8, 3, 2, YELLOW)
	_r(image, o, 20, 7, 1, 4, YELLOW)


func _powerbank(image: Image, o: Vector2i) -> void:
	_r(image, o, 6, 3, 12, 19, INK)
	_r(image, o, 8, 6, 8, 12, RED)
	_r(image, o, 11, 8, 3, 4, YELLOW)
	_r(image, o, 10, 11, 3, 4, YELLOW)


func _parking(image: Image, o: Vector2i) -> void:
	_r(image, o, 3, 3, 18, 18, Color("#3a7bd5"))
	_r(image, o, 8, 6, 3, 12, WHITE)
	_r(image, o, 8, 6, 8, 3, WHITE)
	_r(image, o, 14, 6, 3, 7, WHITE)
	_r(image, o, 8, 11, 8, 2, WHITE)


func _cap(image: Image, o: Vector2i) -> void:
	_r(image, o, 5, 8, 14, 8, RED)
	_r(image, o, 7, 6, 10, 2, RED)
	_r(image, o, 12, 14, 10, 3, RED_DARK)
	_r(image, o, 11, 5, 2, 1, RED_DARK)
	_draw_mark(image, Rect2i(o.x + 9, o.y + 8, 6, 6), WHITE)


func _backpack(image: Image, o: Vector2i) -> void:
	_r(image, o, 6, 5, 12, 16, RED)
	_r(image, o, 9, 2, 6, 3, INK)
	_r(image, o, 7, 14, 10, 6, RED_DARK)
	_r(image, o, 5, 7, 1, 12, RED_DARK)
	_r(image, o, 18, 7, 1, 12, RED_DARK)
	_draw_mark(image, Rect2i(o.x + 9, o.y + 6, 6, 6), WHITE)


func _add_outline(image: Image, cell: int) -> void:
	var source: Image = image.duplicate() as Image
	var size: Vector2i = source.get_size()
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y: int in size.y:
		for x: int in size.x:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in offsets:
				var n: Vector2i = Vector2i(x, y) + offset
				if not Rect2i(Vector2i.ZERO, size).has_point(n) or n.x / cell != x / cell:
					continue
				if source.get_pixel(n.x, n.y).a > 0.0:
					image.set_pixel(x, y, OUTLINE)
					break
