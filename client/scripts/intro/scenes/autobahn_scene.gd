class_name AutobahnScene
extends IntroScene
## Night motorway in heavy rain. Fast cars overtake the traffic; the starter VAZ gets overtaken.

## Stage pixels per second per km/h of the player's car.
const PIXELS_PER_KMH: float = 3.6
## Speed of the other cars on the motorway, km/h.
const TRAFFIC_KMH: float = 150.0
const SLOW_KMH: int = 150
const FAR_GROUND: float = 126.0
const NEAR_GROUND: float = 150.0
const CAR_X: float = 90.0
const WRAP_LEFT: float = -170.0
const WRAP_SPAN: float = 780.0
const DROPS: int = 170

var _speed: float = 0.0
var _traffic_speed: float = 0.0
var _scroll: float = 0.0
var _flash: float = 0.0
var _car_id: String
var _car: VehicleSprite
var _traffic: Array[VehicleSprite] = []
var _traffic_x: Array[float] = []
var _drops: PackedVector3Array = PackedVector3Array()
var _flashed: bool = false
var _thundered: bool = false


func get_duration() -> float:
	return 4.2


func get_caption() -> String:
	var key: String = "INTRO_AUTOBAHN_SLOW" if intro.car_speed_kmh < SLOW_KMH else "INTRO_AUTOBAHN"
	return tr(key) % intro.car_speed_kmh


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	_speed = intro.car_speed_kmh * PIXELS_PER_KMH
	_traffic_speed = TRAFFIC_KMH * PIXELS_PER_KMH
	layer(_draw_background)
	var ids: Array[String] = ["sedan_white", "bmw850", "hatch_green"]
	var overtaken: bool = _speed > _traffic_speed
	for i: int in ids.size():
		var x: float = 200.0 + i * 260.0 if overtaken else CAR_X - 200.0 - i * 260.0
		var other: VehicleSprite = vehicle(ids[i], Vector2(x, FAR_GROUND))
		other.lights_on = true
		_traffic.append(other)
		_traffic_x.append(x)
	_car = vehicle(VehicleCatalog.with_driver(_car_id), Vector2(CAR_X, NEAR_GROUND))
	_car.lights_on = true
	_car.beam = true
	layer(_draw_foreground)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in DROPS:
		_drops.append(Vector3(rng.randf_range(0, 340), rng.randf_range(0, 180), rng.randf_range(260, 420)))
	intro.audio.play_loop("rain_loop", -2.0)
	intro.audio.play_loop("engine_loop", -9.0, 1.8 * VehicleCatalog.engine_pitch(_car_id))


func update(delta: float) -> void:
	_scroll += _speed * delta
	_car.add_distance(_speed * delta)
	_car.bob = 1.0 if fmod(time * 9.0, 1.0) < 0.5 else 0.0
	intro.shake = 0.4 if _speed > _traffic_speed else 0.7
	var passing_x: float = CAR_X + VehicleCatalog.body_size(_car_id).x * 0.3
	for i: int in _traffic.size():
		var previous: float = _traffic_x[i]
		_traffic_x[i] -= (_speed - _traffic_speed) * delta
		if signf(previous - passing_x) != signf(_traffic_x[i] - passing_x):
			intro.audio.play_one("whoosh", -4.0, randf_range(0.85, 1.1))
		if _traffic_x[i] < WRAP_LEFT:
			_traffic_x[i] += WRAP_SPAN
		elif _traffic_x[i] > WRAP_LEFT + WRAP_SPAN:
			_traffic_x[i] -= WRAP_SPAN
		_traffic[i].position.x = roundf(_traffic_x[i])
		_traffic[i].add_distance(_traffic_speed * delta)
	if time >= 2.1 and not _flashed:
		_flashed = true
		_flash = 1.0
	if time >= 2.28 and time < 2.32:
		_flash = maxf(_flash, 0.7)
	if time >= 2.5 and not _thundered:
		_thundered = true
		intro.audio.play_one("thunder", 0.0)
	_flash = maxf(0.0, _flash - delta * 2.5)


func finish() -> void:
	intro.shake = 0.0


func _draw_background(canvas: CanvasItem) -> void:
	var length: float = VehicleCatalog.body_size(_car_id).x
	canvas.draw_texture(tex("autobahn_sky"), Vector2.ZERO)
	draw_strip(canvas, tex("autobahn_far"), IntroArt.AUTOBAHN_FAR_Y, _scroll * 0.02)
	draw_strip(canvas, tex("autobahn_mid"), IntroArt.AUTOBAHN_MID_Y, _scroll * 0.3)
	draw_strip(canvas, tex("autobahn_road"), IntroArt.AUTOBAHN_ROAD_Y, _scroll)
	canvas.draw_rect(Rect2(CAR_X + 1, NEAR_GROUND + 1, 3, 7), Color(1.0, 0.15, 0.1, 0.35))
	canvas.draw_rect(Rect2(CAR_X + length, NEAR_GROUND + 1, 70, 2), Color(1.0, 0.95, 0.7, 0.18))
	for other: VehicleSprite in _traffic:
		canvas.draw_rect(Rect2(other.position.x + 1, FAR_GROUND + 1, 3, 5), Color(1.0, 0.15, 0.1, 0.3))


func _draw_foreground(canvas: CanvasItem) -> void:
	draw_strip(canvas, tex("autobahn_rail"), IntroArt.AUTOBAHN_RAIL_Y, _scroll * 1.25)
	var spray_strength: float = clampf(_speed / 800.0, 0.35, 1.0)
	for i: int in 12:
		var k: float = fmod(time * 3.0 + i / 12.0, 1.0)
		var spray: Vector2 = Vector2(CAR_X + 24.0 - k * 64.0 * spray_strength, NEAR_GROUND - 3.0 - k * 10.0 + sin(i * 1.7) * 2.0)
		canvas.draw_circle(spray, 1.0 + k * 4.0, Color(0.75, 0.8, 0.9, 0.28 * (1.0 - k)))
	for drop: Vector3 in _drops:
		var x: float = fposmod(drop.x - time * drop.z * 0.35, 340.0) - 10.0
		var y: float = fposmod(drop.y + time * drop.z, 180.0)
		canvas.draw_line(Vector2(x, y), Vector2(x - 3.0, y + 9.0), Color(0.7, 0.8, 1.0, 0.38), 1.0)
	for i: int in 6:
		var streak_x: float = fposmod(i * 97.0 - _scroll * 1.6, 360.0) - 20.0
		canvas.draw_line(Vector2(streak_x, 100.0 + i * 9.0), Vector2(streak_x + 26.0, 100.0 + i * 9.0), Color(1, 1, 1, 0.07), 1.0)
	if _flash > 0.0:
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(IntroArt.STAGE)), Color(0.85, 0.9, 1.0, _flash * 0.75))
