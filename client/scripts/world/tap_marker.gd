class_name TapMarker
extends Node2D
## Neon target marker shown where the player tapped.

const COLOR_TARGET: Color = Color("#ff4a3d")
const COLOR_CORE: Color = Color("#f4f4f4")
const BLOCKED_LIFETIME: float = 0.6
const FADE_SPEED: float = 4.0

var _time: float = 0.0
var _blocked: bool = false
var _blocked_left: float = 0.0
var _alpha: float = 0.0
var _fading: bool = true


func show_target(world_position: Vector2) -> void:
	_show(world_position, false)


func show_blocked(world_position: Vector2) -> void:
	_show(world_position, true)
	_blocked_left = BLOCKED_LIFETIME


func hide_marker() -> void:
	_fading = true


func _show(world_position: Vector2, blocked: bool) -> void:
	global_position = world_position.floor()
	_blocked = blocked
	_time = 0.0
	_alpha = 1.0
	_fading = false


func _process(delta: float) -> void:
	_time += delta
	if _blocked:
		_blocked_left -= delta
		if _blocked_left <= 0.0:
			_fading = true
	if _fading:
		_alpha = move_toward(_alpha, 0.0, FADE_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.0:
		return
	var target: Color = Color(COLOR_TARGET, _alpha)
	if _blocked:
		draw_line(Vector2(-4, -4), Vector2(4, 4), target, 2.0)
		draw_line(Vector2(-4, 4), Vector2(4, -4), target, 2.0)
		return
	var pulse: float = fmod(_time * 1.6, 1.0)
	draw_arc(Vector2.ZERO, 3.0 + pulse * 6.0, 0.0, TAU, 20, Color(target, _alpha * (1.0 - pulse)), 1.0)
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, target, 1.0)
	draw_rect(Rect2(-1, -1, 2, 2), Color(COLOR_CORE, _alpha))
