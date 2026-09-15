class_name NightCityScene
extends IntroScene
## Evening drive home through the city: a moon and stars, street lamps sliding past and a few cars
## with their lights on in the far lane.

const NIGHT: Color = Color(0.3, 0.32, 0.55)
const CAR_TINT: Color = Color(0.6, 0.62, 0.82)
const LAMP_LIGHT: Color = Color(1.0, 0.82, 0.45)
const NEAR_GROUND: float = TrafficScene.NEAR_GROUND
const FAR_GROUND: float = TrafficScene.FAR_GROUND
const SIDEWALK: float = TrafficScene.SIDEWALK
const CAR_X: float = 96.0
const SPEED: float = 170.0
const FAR_SPEED: float = 90.0
const FAR_WRAP: float = 760.0
const LAMP_SPACING: float = 120.0
const LAMP_TOP: float = 92.0
const STARS: int = 40

var _scroll: float = 0.0
var _car: VehicleSprite
var _car_id: String
var _far: Array[VehicleSprite] = []
var _far_x: Array[float] = []
var _stars: PackedVector3Array = PackedVector3Array()


func get_duration() -> float:
	return 4.4


func get_caption_key() -> String:
	return "INTRO_NIGHT_DRIVE"


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	layer(_draw_background)
	var x: float = 40.0
	for id: String in ["taxi", "sedan_white"]:
		var other: VehicleSprite = vehicle(id, Vector2(x, FAR_GROUND))
		other.lights_on = true
		other.modulate = CAR_TINT
		_far.append(other)
		_far_x.append(x)
		x += 380.0
	_car = vehicle(VehicleCatalog.with_driver(_car_id), Vector2(CAR_X, NEAR_GROUND))
	_car.lights_on = true
	_car.beam = true
	_car.modulate = CAR_TINT
	layer(_draw_foreground)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in STARS:
		_stars.append(Vector3(rng.randf_range(0, IntroArt.STAGE.x), rng.randf_range(IntroArt.BAR_TOP, 60), rng.randf_range(0, TAU)))
	intro.audio.play_loop("city_loop", -12.0)
	intro.audio.play_loop("engine_loop", -9.0, 1.2 * VehicleCatalog.engine_pitch(_car_id))


func update(delta: float) -> void:
	_scroll += SPEED * delta
	_car.add_distance(SPEED * delta)
	_car.bob = 1.0 if fmod(time * 7.0, 1.0) < 0.5 else 0.0
	for i: int in _far.size():
		_far_x[i] -= (SPEED - FAR_SPEED) * delta
		_far[i].position.x = roundf(fposmod(_far_x[i] + 200.0, FAR_WRAP) - 200.0)
		_far[i].add_distance(FAR_SPEED * delta)


func _draw_background(canvas: CanvasItem) -> void:
	canvas.draw_texture(tex("city_sky"), Vector2.ZERO, NIGHT)
	for star: Vector3 in _stars:
		var twinkle: float = 0.45 + 0.35 * sin(time * 3.0 + star.z)
		canvas.draw_rect(Rect2(roundf(star.x), roundf(star.y), 1, 1), Color(1, 1, 0.9, twinkle))
	canvas.draw_circle(Vector2(268, 34), 9.0, Color(1.0, 0.97, 0.85, 0.12))
	canvas.draw_circle(Vector2(268, 34), 6.0, Color("#f4eed8"))
	canvas.draw_circle(Vector2(271, 32), 5.0, Color(NIGHT.darkened(0.3), 0.9))
	draw_strip(canvas, tex("city_far"), IntroArt.CITY_FAR_Y, _scroll * 0.15, NIGHT.darkened(0.2))
	draw_strip(canvas, tex("city_near"), IntroArt.CITY_NEAR_Y, _scroll * 0.6, NIGHT)
	draw_strip(canvas, tex("city_road"), IntroArt.CITY_ROAD_Y, _scroll, NIGHT.lightened(0.15))


func _draw_foreground(canvas: CanvasItem) -> void:
	var x: float = -fposmod(_scroll, LAMP_SPACING)
	while x < IntroArt.STAGE.x + 20.0:
		var lamp_x: float = roundf(x)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(lamp_x + 4, LAMP_TOP + 2), Vector2(lamp_x - 14, SIDEWALK + 26), Vector2(lamp_x + 24, SIDEWALK + 26),
		]), Color(LAMP_LIGHT, 0.08))
		canvas.draw_rect(Rect2(lamp_x, LAMP_TOP, 2, SIDEWALK - LAMP_TOP), Color("#1b1a24"))
		canvas.draw_rect(Rect2(lamp_x, LAMP_TOP, 7, 2), Color("#1b1a24"))
		canvas.draw_circle(Vector2(lamp_x + 6, LAMP_TOP + 3), 5.0, Color(LAMP_LIGHT, 0.25))
		canvas.draw_rect(Rect2(lamp_x + 5, LAMP_TOP + 2, 3, 2), LAMP_LIGHT)
		x += LAMP_SPACING
	var size: Vector2i = VehicleCatalog.body_size(_car_id)
	var head: Vector2 = Vector2(CAR_X + size.x - 2.0, NEAR_GROUND - size.y * 0.45 - _car.bob)
	canvas.draw_colored_polygon(PackedVector2Array([head, head + Vector2(120, 12), head + Vector2(120, -12)]), Color(1.0, 0.95, 0.7, 0.12))
	canvas.draw_circle(head, 3.0, Color(1.0, 0.97, 0.8, 0.8))
	for other: VehicleSprite in _far:
		var tail: Vector2 = other.position + Vector2(1, -VehicleCatalog.body_size(other.vehicle_id).y * 0.5)
		canvas.draw_circle(tail, 2.0, Color(1.0, 0.15, 0.1, 0.6))
