class_name HomeArrivalScene
extends IntroScene
## Night courtyard at home: the car pulls in, the player gets out and goes into the building.

const NIGHT: Color = Color(0.42, 0.44, 0.68)
const PEOPLE_NIGHT: Color = Color(0.7, 0.72, 0.9)
const DOOR_LIGHT: Color = Color(1.0, 0.85, 0.5)
const CAR_FROM: float = -140.0
const CAR_X: float = ParkingScene.CAR_X
const GROUND: float = ParkingScene.GROUND
const PARK_TIME: float = 1.7
const EXIT_TIME: float = 2.1
const CURB_TIME: float = 3.4
const DOOR_TIME: float = 4.1

var _car: VehicleSprite
var _car_id: String
var _car_door: Vector2
var _player: CharacterSprite
var _exited: bool = false


func get_duration() -> float:
	return 5.0


func get_caption_key() -> String:
	return "INTRO_HOME_ARRIVE"


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	_car_door = Vector2(CAR_X + VehicleCatalog.door_x(_car_id), 148)
	sprite("parking").modulate = NIGHT
	layer(_draw_door_light)
	_player = character(CharacterSprite.PLAYER_ID, _car_door, Vector2.LEFT)
	_player.modulate = PEOPLE_NIGHT
	_player.visible = false
	_car = vehicle(VehicleCatalog.with_driver(_car_id), Vector2(CAR_FROM, GROUND))
	_car.modulate = PEOPLE_NIGHT
	_car.lights_on = true
	_car.beam = true
	intro.audio.play_loop("engine_loop", -10.0, VehicleCatalog.engine_pitch(_car_id))


func update(_delta: float) -> void:
	var pitch: float = VehicleCatalog.engine_pitch(_car_id)
	var k: float = clampf(time / PARK_TIME, 0.0, 1.0)
	_car.position.x = roundf(lerpf(CAR_FROM, CAR_X, ease(k, 0.4)))
	_car.brake = time > 1.2 and time < 2.1
	if time < PARK_TIME:
		intro.audio.play_loop("engine_loop", -10.0, lerpf(1.0, 0.6, k) * pitch)
	elif _car.lights_on:
		_car.lights_on = false
		_car.beam = false
		intro.audio.stop_loop("engine_loop", 0.4)
	if time >= EXIT_TIME and not _exited:
		_exited = true
		_car.setup(_car_id)
		_player.visible = true
		intro.audio.play_one("car_door", -2.0)
	if _exited:
		if time < CURB_TIME:
			walk(_player, _car_door, ParkingScene.CURB, EXIT_TIME + 0.2, CURB_TIME)
		else:
			walk(_player, ParkingScene.CURB, ParkingScene.DOOR, CURB_TIME, DOOR_TIME)
			_player.modulate.a = clampf(1.0 - (time - DOOR_TIME + 0.2) / 0.4, 0.0, 1.0)


func _draw_door_light(canvas: CanvasItem) -> void:
	var glow: float = 0.18 + 0.1 * clampf((time - CURB_TIME) / 0.6, 0.0, 1.0)
	var door: Vector2 = ParkingScene.DOOR
	canvas.draw_circle(door + Vector2(0, -34), 12.0, Color(DOOR_LIGHT, glow * 0.6))
	canvas.draw_rect(Rect2(door.x - 16, door.y + 2, 32, 10), Color(DOOR_LIGHT, glow * 0.5))
