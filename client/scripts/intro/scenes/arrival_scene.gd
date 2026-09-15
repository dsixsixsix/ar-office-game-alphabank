class_name ArrivalScene
extends IntroScene
## Alfa-Bank office: the player's car parks, the player walks in through sliding doors.

const CAR_FROM: float = -140.0
const CAR_TO: float = 30.0
const GROUND: float = 157.0
const PARK_TIME: float = 1.6
const EXIT_TIME: float = 1.9
const DOORS: Vector2 = Vector2(216, 146)
const LOBBY: Vector2 = Vector2(216, 139)
const DOOR_OPEN: float = 3.1
const DOOR_CLOSE: float = 4.4

var _car: VehicleSprite
var _car_id: String
var _car_side: Vector2
var _player: CharacterSprite
var _exited: bool = false
var _door_sound: bool = false
var _chimed: bool = false


func get_duration() -> float:
	return 5.4


func get_caption_key() -> String:
	return "INTRO_ARRIVE"


func begin() -> void:
	_car_id = VehicleCatalog.player_car(intro.car_id)
	_car_side = Vector2(CAR_TO + VehicleCatalog.door_x(_car_id), 146)
	sprite("office_exterior")
	layer(_draw_building)
	_player = character(CharacterSprite.PLAYER_ID, _car_side, Vector2.RIGHT)
	_player.visible = false
	_car = vehicle(VehicleCatalog.with_driver(_car_id), Vector2(CAR_FROM, GROUND))
	_car.lights_on = true
	intro.audio.play_loop("engine_loop", -10.0, VehicleCatalog.engine_pitch(_car_id))


func update(_delta: float) -> void:
	var pitch: float = VehicleCatalog.engine_pitch(_car_id)
	var k: float = clampf(time / PARK_TIME, 0.0, 1.0)
	_car.position.x = roundf(lerpf(CAR_FROM, CAR_TO, ease(k, 0.4)))
	_car.brake = time > 1.1 and time < 2.0
	if time < PARK_TIME:
		intro.audio.play_loop("engine_loop", -10.0, lerpf(1.0, 0.6, k) * pitch)
	elif time >= PARK_TIME and _car.lights_on:
		_car.lights_on = false
		intro.audio.stop_loop("engine_loop", 0.4)
	if time >= EXIT_TIME and not _exited:
		_exited = true
		_car.setup(_car_id)
		_player.visible = true
		intro.audio.play_one("car_door", -2.0)
	if _exited:
		if time < 3.6:
			walk(_player, _car_side, DOORS, 2.0, 3.6)
		else:
			walk(_player, DOORS, LOBBY, 3.6, 4.2)
			_player.modulate.a = clampf(1.0 - (time - 3.8) / 0.4, 0.0, 1.0)
	if time >= DOOR_OPEN and not _door_sound:
		_door_sound = true
		intro.audio.play_one("door_slide", -4.0)
	if time >= DOOR_OPEN + 0.2 and not _chimed:
		_chimed = true
		intro.audio.play_one("chime", -6.0)


func _draw_building(canvas: CanvasItem) -> void:
	draw_entrance(canvas, time, clampf((time - DOOR_OPEN) / 0.4, 0.0, 1.0) - clampf((time - DOOR_CLOSE) / 0.4, 0.0, 1.0))


## Brand sign, sliding glass doors (open 0..1) and the waving flag on the office facade.
static func draw_entrance(canvas: CanvasItem, time: float, open: float) -> void:
	canvas.draw_string(ThemeDB.fallback_font, Vector2(162, 52), canvas.tr("BRAND_NAME"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RED)
	var slide: float = roundf(open * 17.0)
	var glass: Color = Color(0.72, 0.86, 0.95, 0.8)
	canvas.draw_rect(Rect2(197.0 - slide, 101, 18, 37), glass)
	canvas.draw_rect(Rect2(215.0 + slide, 101, 18, 37), glass)
	canvas.draw_rect(Rect2(214.0 - slide, 101, 1, 37), Color("#9aa0a8"))
	canvas.draw_rect(Rect2(215.0 + slide, 101, 1, 37), Color("#9aa0a8"))
	canvas.draw_line(Vector2(200.0 - slide, 134), Vector2(208.0 - slide, 104), Color(1, 1, 1, 0.35), 1.0)
	for i: int in 22:
		var wave: float = sin(time * 6.0 - i * 0.45) * 1.5
		var color: Color = RED if i < 20 else Color("#c4251b")
		canvas.draw_rect(Rect2(302 + i, roundf(22.0 + wave), 1, 13), color)
		canvas.draw_rect(Rect2(302 + i, roundf(31.0 + wave), 1, 2), WHITE)
