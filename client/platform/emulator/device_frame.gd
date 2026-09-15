class_name DeviceFrame
extends Node2D
## Draws the emulated phone's rounded corners, camera cutout, home indicator and safe-area outline.

const MASK_COLOR: Color = Color.BLACK
const SAFE_AREA_COLOR: Color = Color(0.36, 0.88, 0.9, 0.8)
const HOME_INDICATOR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.55)
const CORNER_SEGMENTS: int = 12

var show_safe_area: bool = false:
	set(value):
		show_safe_area = value
		queue_redraw()

var _profile: DeviceProfile
var _game_scale: float = 1.0
var _size: Vector2 = Vector2.ZERO


func configure(profile: DeviceProfile, game_scale: int, logical_size: Vector2i) -> void:
	_profile = profile
	_game_scale = float(game_scale)
	_size = Vector2(logical_size)
	queue_redraw()


func _ready() -> void:
	PlatformServices.safe_rect_changed.connect(func(_rect: Rect2) -> void: queue_redraw())


## Converts physical device pixels to viewport units.
func _u(device_pixels: float) -> float:
	return device_pixels / _game_scale


func _draw() -> void:
	if _profile == null:
		return
	_draw_corners(_u(_profile.corner_radius))
	var center_x: float = _size.x * 0.5
	match _profile.cutout:
		DeviceProfile.Cutout.PUNCH_HOLE:
			draw_circle(Vector2(center_x, _u(64)), _u(24), MASK_COLOR)
		DeviceProfile.Cutout.WATERDROP:
			draw_circle(Vector2(center_x, 0.0), _u(40), MASK_COLOR)
		DeviceProfile.Cutout.DYNAMIC_ISLAND:
			_draw_horizontal_pill(Vector2(center_x, _u(33 + 55)), _u(378), _u(111))
	if _profile.home_indicator:
		var bar_size: Vector2 = Vector2(_u(420), maxf(_u(15), 1.0))
		var bar_position: Vector2 = Vector2((_size.x - bar_size.x) * 0.5, _size.y - _u(24) - bar_size.y)
		draw_rect(Rect2(bar_position, bar_size), HOME_INDICATOR_COLOR)
	if show_safe_area:
		draw_rect(PlatformServices.get_safe_rect().grow(-0.5), SAFE_AREA_COLOR, false, 1.0)


func _draw_corners(radius: float) -> void:
	if radius <= 0.0:
		return
	var arc: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	for i: int in CORNER_SEGMENTS + 1:
		var angle: float = lerpf(PI * 1.5, PI, float(i) / CORNER_SEGMENTS)
		arc.append(Vector2(radius, radius) + Vector2(cos(angle), sin(angle)) * radius)
	var flips: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for flip: Vector2 in flips:
		var corner: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in arc:
			var x: float = point.x if flip.x > 0.0 else _size.x - point.x
			var y: float = point.y if flip.y > 0.0 else _size.y - point.y
			corner.append(Vector2(x, y))
		draw_colored_polygon(corner, MASK_COLOR)


func _draw_horizontal_pill(center: Vector2, width: float, height: float) -> void:
	var radius: float = height * 0.5
	var body: Rect2 = Rect2(center.x - width * 0.5 + radius, center.y - radius, width - height, height)
	draw_rect(body, MASK_COLOR)
	draw_circle(Vector2(body.position.x, center.y), radius, MASK_COLOR)
	draw_circle(Vector2(body.end.x, center.y), radius, MASK_COLOR)
