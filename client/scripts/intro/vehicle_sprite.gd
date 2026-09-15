class_name VehicleSprite
extends Node2D
## Side-view vehicle from the intro atlas with spinning wheels and lights.
## Origin is on the ground under the rear bumper; the vehicle faces +X.

const HEAD_GLOW: Color = Color(1.0, 0.95, 0.75, 0.55)
const TAIL_GLOW: Color = Color(1.0, 0.1, 0.08, 0.5)
const WHEEL_STEP: float = 3.0

static var _texture: Texture2D
static var _regions: Dictionary = {}

var vehicle_id: String = ""
var lights_on: bool = false
var brake: bool = false
var beam: bool = false
var bob: float = 0.0

var _distance: float = 0.0
var _last_x: float = 0.0


func setup(id: String) -> void:
	_ensure_loaded()
	vehicle_id = id
	_last_x = position.x
	queue_redraw()


## Spins the wheels when the world scrolls instead of the vehicle moving.
func add_distance(amount: float) -> void:
	_distance += absf(amount)


func _process(_delta: float) -> void:
	_distance += absf(position.x - _last_x)
	_last_x = position.x
	queue_redraw()


func _draw() -> void:
	if not _regions.has(vehicle_id):
		return
	var size: Vector2 = Vector2(VehicleCatalog.body_size(vehicle_id))
	var axles: Vector3i = VehicleCatalog.axles(vehicle_id)
	var wheel: String = VehicleCatalog.wheel_id(vehicle_id)
	var diameter: float = float(VehicleCatalog.WHEELS[wheel])
	var ground: float = axles.z + diameter / 2.0

	draw_set_transform(Vector2(size.x / 2.0, 0.0), 0.0, Vector2(1.0, 0.1))
	draw_circle(Vector2.ZERO, size.x / 2.0 + 3.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var top: float = roundf(-ground - bob)
	var body: Array = _regions[vehicle_id]
	draw_texture_rect_region(_texture, Rect2(0.0, top, size.x, size.y), Rect2(body[0], body[1], body[2], body[3]))
	var strip: Array = _regions[wheel]
	var frame: int = int(_distance / WHEEL_STEP) % VehicleCatalog.WHEEL_FRAMES
	for axle_x: int in [axles.x, axles.y]:
		var source: Rect2 = Rect2(strip[0] + frame * diameter, strip[1], diameter, diameter)
		draw_texture_rect_region(_texture, Rect2(axle_x - diameter / 2.0, -diameter, diameter, diameter), source)

	var tall: bool = size.y > 70.0
	var head: Vector2 = Vector2(size.x - 2.0, top + size.y * (0.73 if tall else 0.55))
	var tail: Vector2 = Vector2(1.0, top + size.y * (0.72 if tall else 0.5))
	if lights_on:
		if beam:
			draw_colored_polygon(PackedVector2Array([head, head + Vector2(110, 10), head + Vector2(110, -14)]), Color(1.0, 0.95, 0.7, 0.1))
		for i: int in 3:
			draw_circle(head, 2.0 + i * 3.0, Color(HEAD_GLOW, HEAD_GLOW.a / (i + 1)))
	if lights_on or brake:
		var strength: float = 1.0 if brake else 0.5
		for i: int in 3:
			draw_circle(tail, 1.5 + i * 2.5, Color(TAIL_GLOW, TAIL_GLOW.a * strength / (i + 1)))


static func _ensure_loaded() -> void:
	if _texture != null:
		return
	_texture = load(VehicleCatalog.TEXTURE_PATH)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VehicleCatalog.MANIFEST_PATH))
	_regions = parsed if parsed is Dictionary else {}
