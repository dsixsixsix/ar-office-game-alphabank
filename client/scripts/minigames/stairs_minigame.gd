class_name StairsMinigame
extends Minigame
## "Stairs, not the lift": walk the target number of steps around the office before time runs out.
## Only the step counter is used; floors and the barometer are deliberately ignored.

const DEFAULT_STEPS: int = 120
const DEFAULT_TIME_LIMIT: float = 300.0
const BAR_RECT: Rect2 = Rect2(40, 230, 240, 18)
const STAIR_COUNT: int = 8

var _target: int = DEFAULT_STEPS
var _time_limit: float = DEFAULT_TIME_LIMIT
var _time_left: float = DEFAULT_TIME_LIMIT
var _steps: int = 0
var _bounce: float = 0.0

var _counter: Label
var _status: Label


func _ready() -> void:
	if task != null:
		_target = int(task.params.get("steps", DEFAULT_STEPS))
		_time_limit = float(task.params.get("time_limit", DEFAULT_TIME_LIMIT))
	_time_left = _time_limit
	add_hint(tr("MG_STAIRS_HINT") % _target)
	_counter = add_big_label(186, 26, UiStyle.RED)
	_status = add_status()
	PlatformServices.steps_changed.connect(_on_steps)
	PlatformServices.start_step_counter()


func _exit_tree() -> void:
	super()
	PlatformServices.steps_changed.disconnect(_on_steps)


func _on_steps(steps: int) -> void:
	if is_done():
		return
	if steps > _steps:
		_bounce = 1.0
	_steps = steps
	if _steps >= _target:
		set_score(_time_left / _time_limit)
		proof["steps"] = _steps
		finish(true)


func _process(delta: float) -> void:
	super(delta)
	if not is_done():
		_time_left -= delta
		if _time_left <= 0.0:
			finish(false)
	_bounce = maxf(0.0, _bounce - delta * 4.0)
	_counter.text = "%d / %d" % [mini(_steps, _target), _target]
	_status.text = tr("MG_TIME") % ceili(maxf(_time_left, 0.0))
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(float(_steps) / _target, 0.0, 1.0)
	# Staircase with the runner climbing it.
	var step_size: Vector2 = Vector2(26, 16)
	var base: Vector2 = Vector2(56, 170)
	for i: int in STAIR_COUNT:
		var top_left: Vector2 = base + Vector2(i * step_size.x, -(i + 1) * step_size.y)
		draw_rect(Rect2(top_left, Vector2(step_size.x, (i + 1) * step_size.y)), UiStyle.SHADE)
		draw_rect(Rect2(top_left, Vector2(step_size.x, 3)), UiStyle.INK)
	var position_on_stairs: float = progress * (STAIR_COUNT - 1)
	var runner: Vector2 = base + Vector2(position_on_stairs * step_size.x + 13, -(position_on_stairs + 1) * step_size.y)
	runner.y -= 14.0 + _bounce * 4.0
	draw_rect(Rect2(runner + Vector2(-5, -14), Vector2(10, 14)), UiStyle.RED)
	draw_circle(runner + Vector2(0, -19), 5.0, UiStyle.INK)
	var stride: float = 4.0 if _bounce > 0.5 else -4.0
	draw_line(runner, runner + Vector2(stride, 12), UiStyle.INK, 3.0)
	draw_line(runner, runner + Vector2(-stride, 12), UiStyle.INK, 3.0)
	draw_rect(BAR_RECT.grow(2), UiStyle.INK)
	draw_rect(BAR_RECT, UiStyle.PAPER)
	draw_rect(Rect2(BAR_RECT.position, Vector2(BAR_RECT.size.x * progress, BAR_RECT.size.y)), UiStyle.RED)
