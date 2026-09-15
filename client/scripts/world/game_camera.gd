class_name GameCamera
extends Camera2D
## Follows a target with smoothing, clamps to map bounds and supports screen shake.

@export var target: Node2D
@export var shake_decay: float = 8.0

var _shake_strength: float = 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


func set_bounds(bounds: Rect2, margin: float) -> void:
	var grown: Rect2 = bounds.grow(margin)
	limit_left = int(grown.position.x)
	limit_top = int(grown.position.y)
	limit_right = int(grown.end.x)
	limit_bottom = int(grown.end.y)


func snap_to_target() -> void:
	if target != null:
		global_position = target.global_position
	reset_smoothing()


func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


func _process(delta: float) -> void:
	if target != null:
		global_position = target.global_position
	if _shake_strength > 0.2:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).round() * _shake_strength
		_shake_strength = lerpf(_shake_strength, 0.0, 1.0 - exp(-shake_decay * delta))
	else:
		_shake_strength = 0.0
		offset = Vector2.ZERO
