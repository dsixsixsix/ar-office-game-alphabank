class_name PixelCanvas
extends RefCounted
## Drawing primitives for procedural pixel art. All coordinates are local to `origin` and clipped to `clip`.

var image: Image
var origin: Vector2i = Vector2i.ZERO
var clip: Rect2i


func _init(p_image: Image) -> void:
	image = p_image
	clip = Rect2i(Vector2i.ZERO, image.get_size())


static func create(size: Vector2i) -> PixelCanvas:
	return PixelCanvas.new(Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8))


## Restricts drawing to a cell of the image; local (0, 0) becomes the cell's top-left corner.
func set_cell(rect: Rect2i) -> void:
	origin = rect.position
	clip = rect


func px(x: int, y: int, color: Color) -> void:
	var p: Vector2i = origin + Vector2i(x, y)
	if not clip.has_point(p):
		return
	if color.a >= 1.0:
		image.set_pixelv(p, color)
	elif color.a > 0.0:
		image.set_pixelv(p, image.get_pixelv(p).blend(color))


func get_px(x: int, y: int) -> Color:
	var p: Vector2i = origin + Vector2i(x, y)
	return image.get_pixelv(p) if clip.has_point(p) else Color(0, 0, 0, 0)


func rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			px(xx, yy, color)


func hline(x: int, y: int, w: int, color: Color) -> void:
	rect(x, y, w, 1, color)


func vline(x: int, y: int, h: int, color: Color) -> void:
	rect(x, y, 1, h, color)


## Filled axis-aligned ellipse centred between pixels when radii are fractional.
func ellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for yy: int in range(floori(cy - ry), ceili(cy + ry) + 1):
		for xx: int in range(floori(cx - rx), ceili(cx + rx) + 1):
			var d: Vector2 = Vector2((xx + 0.5 - cx) / rx, (yy + 0.5 - cy) / ry)
			if d.length_squared() <= 1.0:
				px(xx, yy, color)


func polygon(points: PackedVector2Array, color: Color) -> void:
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	for yy: int in range(floori(bounds.position.y), ceili(bounds.end.y) + 1):
		for xx: int in range(floori(bounds.position.x), ceili(bounds.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), points):
				px(xx, yy, color)


func line(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		px(x0, y0, color)
		if x0 == x1 and y0 == y1:
			return
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Checkerboard mix of two colours, handy for soft gradients and fabric texture.
func dither(x: int, y: int, w: int, h: int, a: Color, b: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			px(xx, yy, a if (xx + yy) % 2 == 0 else b)


## Vertical gradient between two colours with ordered dithering between bands.
func gradient(x: int, y: int, w: int, h: int, top: Color, bottom: Color, bands: int = 6) -> void:
	for yy: int in range(y, y + h):
		var t: float = float(yy - y) / maxf(1.0, h - 1.0) * bands
		var band: int = floori(t)
		var frac: float = t - band
		for xx: int in range(x, x + w):
			var bayer: float = [0.0, 0.5, 0.75, 0.25][((yy & 1) << 1) | (xx & 1)]
			var level: int = band + (1 if frac > bayer else 0)
			px(xx, yy, top.lerp(bottom, clampf(float(level) / bands, 0.0, 1.0)))


## Outlines opaque pixels inside the current clip. Outline colour is a dark version of the neighbour.
func outline(strength: float = 0.72, alpha_limit: float = 0.5) -> void:
	var snapshot: Image = image.duplicate() as Image
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for yy: int in range(clip.position.y, clip.end.y):
		for xx: int in range(clip.position.x, clip.end.x):
			if snapshot.get_pixel(xx, yy).a > 0.0:
				continue
			for offset: Vector2i in offsets:
				var n: Vector2i = Vector2i(xx, yy) + offset
				if not clip.has_point(n):
					continue
				var neighbour: Color = snapshot.get_pixelv(n)
				if neighbour.a >= alpha_limit:
					image.set_pixel(xx, yy, Palette.outline_of(neighbour, strength))
					break


## Copies another image region into this canvas (local coordinates), alpha blended.
func stamp(source: Image, source_rect: Rect2i, x: int, y: int, flip_x: bool = false) -> void:
	for yy: int in source_rect.size.y:
		for xx: int in source_rect.size.x:
			var sx: int = source_rect.position.x + (source_rect.size.x - 1 - xx if flip_x else xx)
			var color: Color = source.get_pixel(sx, source_rect.position.y + yy)
			if color.a > 0.0:
				px(x + xx, y + yy, color)
