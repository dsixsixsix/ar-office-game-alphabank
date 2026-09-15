class_name ParkingScene
extends IntroScene
## Courtyard: the player leaves the building, gets into the chosen car and drives off.
## The starter VAZ needs a second try to start.

const DOOR: Vector2 = Vector2(48, 134)
const CURB: Vector2 = Vector2(72, 148)
const CAR_X: float = 176.0
const GROUND: float = 157.0
const ENTER_TIME: float = 3.0
const START_TIME: float = 3.5
const DRIVE_TIME: float = 4.2
const RETRY_DELAY: float = 0.55
const ACCELERATION: float = 420.0

var _player: CharacterSprite
var _car: VehicleSprite
var _car_id: String
var _car_door: Vector2
var _stubborn: bool = false
var _entered: bool = false
var _tried: bool = false
var _started: bool = false


func get_duration() -> float:
	return 5.3 + (RETRY_DELAY if _stubborn else 0.0)


func get_caption() -> String:
	return tr("INTRO_PARKING") % intro.car_name.to_upper()


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	_stubborn = _car_id == VehicleCatalog.DEFAULT_CAR
	_car_door = Vector2(CAR_X + VehicleCatalog.door_x(_car_id), 148)
	sprite("parking")
	_player = character(CharacterSprite.PLAYER_ID, DOOR, Vector2.DOWN)
	_car = vehicle(_car_id, Vector2(CAR_X, GROUND))
	layer(_draw_exhaust)


func update(_delta: float) -> void:
	var pitch: float = VehicleCatalog.engine_pitch(_car_id)
	var start_time: float = START_TIME + (RETRY_DELAY if _stubborn else 0.0)
	var drive_time: float = DRIVE_TIME + (RETRY_DELAY if _stubborn else 0.0)
	if not _entered:
		if time < 1.0:
			walk(_player, DOOR, CURB, 0.4, 1.0)
		else:
			walk(_player, CURB, _car_door, 1.0, ENTER_TIME - 0.1)
	if time >= ENTER_TIME and not _entered:
		_entered = true
		_player.visible = false
		_car.setup(VehicleCatalog.with_driver(_car_id))
		intro.audio.play_one("car_door", -2.0)
	if _stubborn and time >= START_TIME and not _tried:
		_tried = true
		intro.audio.play_one("engine_start", -4.0, 0.7)
		intro.shake = 0.3
	if time >= start_time and not _started:
		_started = true
		intro.shake = 0.0
		_car.lights_on = true
		intro.audio.play_one("engine_start", -2.0, pitch)
		intro.audio.play_loop("engine_loop", -10.0, 0.8 * pitch)
	if time >= drive_time:
		var t: float = time - drive_time
		var acceleration: float = ACCELERATION * (0.6 if _stubborn else 1.0)
		_car.position.x = roundf(CAR_X + 0.5 * acceleration * t * t)
		intro.audio.play_loop("engine_loop", -8.0, (0.8 + t * 0.6) * pitch)


func finish() -> void:
	intro.shake = 0.0


func _draw_exhaust(canvas: CanvasItem) -> void:
	if _tried and not _started:
		draw_bubble(canvas, _car.position + Vector2(40, -46), tr("INTRO_ENGINE_RETRY"), RED)
	if not _started:
		return
	var puffs: int = 8 if _stubborn else 5
	for i: int in puffs:
		var k: float = fmod(time * 1.4 + float(i) / puffs, 1.0)
		var origin: Vector2 = _car.position + Vector2(-2.0 - k * 16.0, -6.0 - k * 10.0)
		var grey: float = 0.55 if _stubborn else 0.85
		canvas.draw_circle(origin, 1.5 + k * (6.0 if _stubborn else 4.0), Color(grey, grey, grey + 0.03, 0.45 * (1.0 - k)))
