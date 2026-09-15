class_name BubbleWrapMinigame
extends Minigame
## Pop bubble wrap before time runs out. Popping most of it counts as success.

const COLUMNS: int = 7
const ROWS: int = 7
const CELL: float = 40.0
const ORIGIN: Vector2 = Vector2(20, 34)
const TIME_LIMIT: float = 15.0
const SUCCESS_SHARE: float = 0.8

var _popped: Array[bool] = []
var _pop_time: Array[float] = []
var _time_left: float = TIME_LIMIT
var _count: int = 0

var _status: Label


func _ready() -> void:
	_popped.resize(COLUMNS * ROWS)
	_pop_time.resize(COLUMNS * ROWS)
	add_hint(tr("MG_BUBBLE_HINT"))
	_status = add_status()


func _gui_input(event: InputEvent) -> void:
	var position: Variant = Minigame.press_position(event)
	if is_done() or position == null:
		return
	var local: Vector2 = (position as Vector2) - ORIGIN
	if local.x < 0.0 or local.y < 0.0:
		return
	var cell: Vector2i = Vector2i(local / CELL)
	if cell.x >= COLUMNS or cell.y >= ROWS:
		return
	var index: int = cell.y * COLUMNS + cell.x
	if _popped[index]:
		return
	_popped[index] = true
	_pop_time[index] = 0.25
	_count += 1
	if _count == _popped.size():
		finish(true)


func _process(delta: float) -> void:
	if not is_done():
		_time_left -= delta
		if _time_left <= 0.0:
			finish(_count >= roundi(_popped.size() * SUCCESS_SHARE))
	for index: int in _pop_time.size():
		_pop_time[index] = maxf(0.0, _pop_time[index] - delta)
	_status.text = "%s   %s" % [tr("MG_TIME") % ceili(maxf(_time_left, 0.0)), "%d/%d" % [_count, _popped.size()]]
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(ORIGIN - Vector2(6, 6), Vector2(COLUMNS, ROWS) * CELL + Vector2(12, 12)), Color("#dfeef2"))
	for y: int in ROWS:
		for x: int in COLUMNS:
			var index: int = y * COLUMNS + x
			var center: Vector2 = ORIGIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * CELL
			if _popped[index]:
				var burst: float = _pop_time[index] * 40.0
				draw_circle(center, 12.0 + burst, Color(1, 1, 1, 0.25 + _pop_time[index]))
				draw_arc(center, 9.0, 0.0, TAU, 12, Color("#a9c7cf"), 1.0)
			else:
				draw_circle(center + Vector2(1, 2), 15.0, Color("#b9d5dc"))
				draw_circle(center, 15.0, Color("#f4fbfd"))
				draw_circle(center - Vector2(5, 5), 3.5, Color.WHITE)
