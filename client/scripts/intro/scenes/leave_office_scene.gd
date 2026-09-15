class_name LeaveOfficeScene
extends IntroScene
## Dusk at the Alfa-Bank office: the player walks out through the sliding doors, gets into the car
## parked by the entrance and drives home.

const DUSK: Color = Color(0.62, 0.55, 0.8)
const PEOPLE_DUSK: Color = Color(0.8, 0.74, 0.92)
const LOBBY_LIGHT: Color = Color(1.0, 0.85, 0.5, 0.14)
const CAR_X: float = ArrivalScene.CAR_TO
const GROUND: float = ArrivalScene.GROUND
const DOOR_OPEN: float = 0.2
const DOOR_CLOSE: float = 1.5
const APPEAR_TIME: float = 0.4
const OUT_TIME: float = 1.1
const ENTER_TIME: float = 3.0
const START_TIME: float = 3.5
const DRIVE_TIME: float = 4.1
const ACCELERATION: float = 380.0

var _car: VehicleSprite
var _car_id: String
var _car_side: Vector2
var _player: CharacterSprite
var _door_sound: bool = false
var _entered: bool = false
var _started: bool = false


func get_duration() -> float:
	return 5.6


func get_caption_key() -> String:
	return "INTRO_LEAVE_OFFICE"


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	_car_side = Vector2(CAR_X + VehicleCatalog.door_x(_car_id), 146)
	sprite("office_exterior").modulate = DUSK
	layer(_draw_building)
	_player = character(CharacterSprite.PLAYER_ID, ArrivalScene.LOBBY, Vector2.DOWN)
	_player.modulate = Color(PEOPLE_DUSK, 0.0)
	_car = vehicle(_car_id, Vector2(CAR_X, GROUND))
	_car.modulate = PEOPLE_DUSK
	intro.audio.play_loop("city_loop", -14.0)


func update(_delta: float) -> void:
	var pitch: float = VehicleCatalog.engine_pitch(_car_id)
	if time >= DOOR_OPEN and not _door_sound:
		_door_sound = true
		intro.audio.play_one("door_slide", -4.0)
	if not _entered:
		if time < OUT_TIME:
			walk(_player, ArrivalScene.LOBBY, ArrivalScene.DOORS, APPEAR_TIME, OUT_TIME)
			_player.modulate.a = clampf((time - APPEAR_TIME) / 0.3, 0.0, 1.0)
		else:
			walk(_player, ArrivalScene.DOORS, _car_side, OUT_TIME, ENTER_TIME - 0.1)
	if time >= ENTER_TIME and not _entered:
		_entered = true
		_player.visible = false
		_car.setup(VehicleCatalog.with_driver(_car_id))
		intro.audio.play_one("car_door", -2.0)
	if time >= START_TIME and not _started:
		_started = true
		_car.lights_on = true
		intro.audio.play_one("engine_start", -2.0, pitch)
		intro.audio.play_loop("engine_loop", -10.0, 0.8 * pitch)
	if time >= DRIVE_TIME:
		var t: float = time - DRIVE_TIME
		_car.position.x = roundf(CAR_X + 0.5 * ACCELERATION * t * t)
		intro.audio.play_loop("engine_loop", -8.0, (0.8 + t * 0.6) * pitch)


func _draw_building(canvas: CanvasItem) -> void:
	var open: float = clampf((time - DOOR_OPEN) / 0.4, 0.0, 1.0) - clampf((time - DOOR_CLOSE) / 0.4, 0.0, 1.0)
	ArrivalScene.draw_entrance(canvas, time, open)
	canvas.draw_rect(Rect2(186, 138, 60, 14), LOBBY_LIGHT)
	canvas.draw_rect(Rect2(196, 140, 40, 8), LOBBY_LIGHT)
