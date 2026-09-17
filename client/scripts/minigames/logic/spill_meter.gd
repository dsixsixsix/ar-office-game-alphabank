class_name SpillMeter
extends RefCounted
## Coffee carried on a phone held flat. Tilting past SAFE_TILT or jerking the phone spills coffee;
## the cup is lost once the level drops below FAIL_LEVEL.

const GRAVITY: float = 9.81
const SAFE_TILT_DEGREES: float = 22.0
## Acceleration change (m/s^2 per update) that counts as a jerk.
const JERK_LIMIT: float = 6.0
## Level lost per second per degree over the safe tilt.
const TILT_SPILL_RATE: float = 0.004
const JERK_SPILL: float = 0.04
const FAIL_LEVEL: float = 0.5

var level: float = 1.0
var tilt_degrees: float = 0.0
## Direction of the tilt in screen space, for drawing the coffee surface.
var tilt_direction: Vector2 = Vector2.ZERO
var spilled_this_update: bool = false

var _previous: Vector3 = Vector3.ZERO
var _has_previous: bool = false


## `acceleration` is the device accelerometer in m/s^2, gravity included (Godot axes).
func update(acceleration: Vector3, delta: float) -> void:
	spilled_this_update = false
	if acceleration.is_zero_approx():
		return
	tilt_degrees = tilt_of(acceleration)
	tilt_direction = Vector2(acceleration.x, -acceleration.y).limit_length(GRAVITY) / GRAVITY
	if tilt_degrees > SAFE_TILT_DEGREES:
		level -= (tilt_degrees - SAFE_TILT_DEGREES) * TILT_SPILL_RATE * delta * 60.0
		spilled_this_update = true
	if _has_previous and acceleration.distance_to(_previous) > JERK_LIMIT:
		level -= JERK_SPILL
		spilled_this_update = true
	level = maxf(level, 0.0)
	_previous = acceleration
	_has_previous = true


func is_failed() -> bool:
	return level < FAIL_LEVEL


## Angle between the screen normal and gravity: 0 when the phone lies flat.
static func tilt_of(acceleration: Vector3) -> float:
	if acceleration.is_zero_approx():
		return 0.0
	return rad_to_deg(acos(clampf(absf(acceleration.z) / acceleration.length(), 0.0, 1.0)))
