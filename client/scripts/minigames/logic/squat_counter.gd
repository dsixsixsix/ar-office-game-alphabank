class_name SquatCounter
extends RefCounted
## Counts squats from body pose landmarks. A repetition is a knee angle drop below DOWN_ANGLE
## followed by a rise above UP_ANGLE. The leg the camera sees better is used.

const DOWN_ANGLE: float = 100.0
const UP_ANGLE: float = 155.0
## Landmarks less likely than this to be in frame are ignored.
const MIN_LIKELIHOOD: float = 0.5
const LEGS: Array = [
	[&"left_hip", &"left_knee", &"left_ankle"],
	[&"right_hip", &"right_knee", &"right_ankle"],
]

var reps: int = 0
var is_down: bool = false
## Last measured knee angle in degrees, or -1 when the legs are not visible.
var knee_angle: float = -1.0


## `landmarks` maps a landmark name to Vector3(x, y, in-frame likelihood).
func update(landmarks: Dictionary) -> void:
	knee_angle = best_knee_angle(landmarks)
	if knee_angle < 0.0:
		return
	if not is_down and knee_angle <= DOWN_ANGLE:
		is_down = true
	elif is_down and knee_angle >= UP_ANGLE:
		is_down = false
		reps += 1


static func best_knee_angle(landmarks: Dictionary) -> float:
	var best_likelihood: float = 0.0
	var angle: float = -1.0
	for leg: Array in LEGS:
		if not (landmarks.has(leg[0]) and landmarks.has(leg[1]) and landmarks.has(leg[2])):
			continue
		var hip: Vector3 = landmarks[leg[0]]
		var knee: Vector3 = landmarks[leg[1]]
		var ankle: Vector3 = landmarks[leg[2]]
		var likelihood: float = minf(hip.z, minf(knee.z, ankle.z))
		if likelihood < MIN_LIKELIHOOD or likelihood <= best_likelihood:
			continue
		best_likelihood = likelihood
		angle = joint_angle(Vector2(hip.x, hip.y), Vector2(knee.x, knee.y), Vector2(ankle.x, ankle.y))
	return angle


## Angle at `vertex` between the two segments, in degrees.
static func joint_angle(a: Vector2, vertex: Vector2, b: Vector2) -> float:
	var first: Vector2 = a - vertex
	var second: Vector2 = b - vertex
	if first.is_zero_approx() or second.is_zero_approx():
		return -1.0
	return rad_to_deg(absf(first.angle_to(second)))
