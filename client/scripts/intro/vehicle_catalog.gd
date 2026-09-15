class_name VehicleCatalog
extends RefCounted
## Side-view vehicle sprites (facing right) shared by the art generator and the intro scenes.
## Scale matches characters: 1 m is about 26 px, so a 1.8 m person is 48 px tall.

const TEXTURE_PATH: String = "res://assets/intro/vehicles.png"
const MANIFEST_PATH: String = "res://assets/intro/vehicles.json"
const WHEEL_FRAMES: int = 4
const DRIVER_SUFFIX: String = "_driver"
const DEFAULT_CAR: String = "vaz2104"

## id: [body size, wheel sprite id, rear axle x, front axle x, axle y]
const BODIES: Dictionary[String, Array] = {
	"vaz2104": [Vector2i(108, 38), "wheel_vaz", 23, 86, 30],
	"vaz2104_driver": [Vector2i(108, 38), "wheel_vaz", 23, 86, 30],
	"bmw5": [Vector2i(128, 39), "wheel_bmw5", 28, 105, 30],
	"bmw5_driver": [Vector2i(128, 39), "wheel_bmw5", 28, 105, 30],
	"audi_rs6": [Vector2i(130, 40), "wheel_rs6", 27, 103, 30],
	"audi_rs6_driver": [Vector2i(130, 40), "wheel_rs6", 27, 103, 30],
	"bmw850": [Vector2i(132, 40), "wheel_bmw", 31, 101, 31],
	"sedan_blue": [Vector2i(124, 42), "wheel_steel", 30, 96, 33],
	"sedan_white": [Vector2i(124, 42), "wheel_steel", 30, 96, 33],
	"sedan_black": [Vector2i(124, 42), "wheel_alloy", 30, 96, 33],
	"taxi": [Vector2i(124, 42), "wheel_steel", 30, 96, 33],
	"hatch_green": [Vector2i(106, 42), "wheel_steel", 22, 84, 33],
	"hatch_orange": [Vector2i(106, 42), "wheel_steel", 22, 84, 33],
	"suv_grey": [Vector2i(128, 50), "wheel_alloy", 30, 100, 40],
	"van_white": [Vector2i(140, 58), "wheel_steel", 30, 108, 48],
	"bus": [Vector2i(300, 86), "wheel_bus", 62, 232, 72],
}

## id: diameter in px
const WHEELS: Dictionary[String, int] = {
	"wheel_vaz": 16,
	"wheel_bmw5": 18,
	"wheel_rs6": 20,
	"wheel_bmw": 18,
	"wheel_steel": 17,
	"wheel_alloy": 18,
	"wheel_bus": 26,
}

## Player cars: id -> [driver door x from the rear bumper, engine sound pitch]
const PLAYER_CARS: Dictionary[String, Array] = {
	"vaz2104": [68, 0.72],
	"bmw5": [80, 1.0],
	"audi_rs6": [82, 1.15],
}


static func body_size(id: String) -> Vector2i:
	return BODIES[id][0]


static func wheel_id(id: String) -> String:
	return BODIES[id][1]


static func axles(id: String) -> Vector3i:
	return Vector3i(BODIES[id][2], BODIES[id][3], BODIES[id][4])


## Known player car id, falling back to the starter car.
static func player_car(car_id: String) -> String:
	return car_id if PLAYER_CARS.has(car_id) else DEFAULT_CAR


static func with_driver(car_id: String) -> String:
	return player_car(car_id) + DRIVER_SUFFIX


static func door_x(car_id: String) -> int:
	return PLAYER_CARS[player_car(car_id)][0]


static func engine_pitch(car_id: String) -> float:
	return PLAYER_CARS[player_car(car_id)][1]
