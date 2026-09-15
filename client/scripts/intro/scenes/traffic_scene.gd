class_name TrafficScene
extends IntroScene
## Morning city traffic jam: stop-and-go queue, pedestrians, horns and street noise.

const FAR_GROUND: float = 143.0
const NEAR_GROUND: float = 157.0
const SIDEWALK: float = 131.0
const FAR_WRAP: float = 880.0
const FAR_FLOW: float = 10.0
const PEDESTRIAN_SPEED: float = 26.0
const HONK_TIMES: Array[float] = [1.0, 2.3, 3.5]

var _scroll: float = 0.0
var _speed: float = 0.0
var _pedestrians: Array[CharacterSprite] = []
var _pedestrian_x: Array[float] = []
var _pedestrian_dir: Array[float] = []
var _far: Array[VehicleSprite] = []
var _far_x: Array[float] = []
var _behind: VehicleSprite
var _car: VehicleSprite
var _ahead: VehicleSprite
var _honks: Array[Array] = []
var _honk_index: int = 0


func get_duration() -> float:
	return 4.8


func get_caption_key() -> String:
	return "INTRO_TRAFFIC"


func begin() -> void:
	layer(_draw_background)
	var looks: Array[String] = ["anna", "sergey", "olga", "igor", "reception"]
	for i: int in looks.size():
		var direction: float = 1.0 if i % 2 == 0 else -1.0
		_pedestrians.append(character(looks[i], Vector2(-100, SIDEWALK), Vector2(direction, 0)))
		_pedestrian_x.append(30.0 + i * 80.0)
		_pedestrian_dir.append(direction)
	var x: float = 150.0
	for id: String in ["taxi", "suv_grey", "bus", "hatch_orange", "sedan_blue"]:
		_far.append(vehicle(id, Vector2(x, FAR_GROUND)))
		_far_x.append(x)
		x += VehicleCatalog.body_size(id).x + 14.0
	_behind = vehicle("van_white", Vector2(-50, NEAR_GROUND))
	_car = vehicle(VehicleCatalog.with_driver(intro.car_id), Vector2(94, NEAR_GROUND))
	_ahead = vehicle("sedan_black", Vector2(234, NEAR_GROUND))
	layer(_draw_foreground)
	intro.audio.play_loop("city_loop", -2.0)
	intro.audio.play_loop("engine_loop", -16.0, 0.55 * VehicleCatalog.engine_pitch(intro.car_id))


func update(delta: float) -> void:
	_speed = 34.0 * maxf(0.0, sin(time * 1.25 - 0.9))
	_scroll += _speed * delta
	for queued: VehicleSprite in [_behind, _car, _ahead]:
		queued.add_distance(_speed * delta)
		queued.brake = _speed < 4.0
	_ahead.position.x = roundf(234.0 + sin(time * 1.25) * 4.0)
	_behind.position.x = roundf(-50.0 - sin(time * 1.25 - 0.5) * 5.0)
	for i: int in _far.size():
		_far[i].position.x = roundf(fposmod(_far_x[i] + time * FAR_FLOW - _scroll + 200.0, FAR_WRAP) - 200.0)
		_far[i].add_distance(FAR_FLOW * delta)
	for i: int in _pedestrians.size():
		_pedestrian_x[i] += _pedestrian_dir[i] * PEDESTRIAN_SPEED * delta
		_pedestrians[i].position = Vector2(roundf(fposmod(_pedestrian_x[i] - _scroll + 40.0, 400.0) - 40.0), SIDEWALK)
		_pedestrians[i].set_walking(true, Vector2(_pedestrian_dir[i], 0))
	if _honk_index < HONK_TIMES.size() and time >= HONK_TIMES[_honk_index]:
		var honker: VehicleSprite = [_far[1], _behind, _far[0]][_honk_index]
		intro.audio.play_one("horn" if _honk_index % 2 == 0 else "horn2", -5.0)
		_honks.append([time, honker])
		_honk_index += 1


func _draw_background(canvas: CanvasItem) -> void:
	canvas.draw_texture(tex("city_sky"), Vector2.ZERO)
	draw_strip(canvas, tex("city_far"), IntroArt.CITY_FAR_Y, _scroll * 0.15)
	draw_strip(canvas, tex("city_near"), IntroArt.CITY_NEAR_Y, _scroll * 0.6)
	draw_strip(canvas, tex("city_road"), IntroArt.CITY_ROAD_Y, _scroll)


func _draw_foreground(canvas: CanvasItem) -> void:
	for queued: VehicleSprite in [_behind, _car, _ahead]:
		for i: int in 3:
			var k: float = fmod(time * 0.9 + i / 3.0 + queued.position.x * 0.01, 1.0)
			canvas.draw_circle(queued.position + Vector2(-3.0 - k * 10.0, -6.0 - k * 8.0), 1.5 + k * 3.0, Color(0.8, 0.8, 0.8, 0.35 * (1.0 - k)))
	for honk: Array in _honks:
		var age: float = time - float(honk[0])
		if age < 0.7:
			var honker: VehicleSprite = honk[1]
			var size: Vector2i = VehicleCatalog.body_size(honker.vehicle_id)
			draw_bubble(canvas, honker.position + Vector2(size.x * 0.6, -size.y - 4.0 - age * 6.0), tr("INTRO_HONK"), RED)
