class_name AlfaRedMinigame
extends Minigame
## Find the one swatch that is exactly the brand red. Shades get closer every round.

const ROUNDS: int = 5
const MAX_MISTAKES: int = 3
const COLUMNS: int = 4
const ROWS: int = 4
const SWATCH: float = 56.0
const GAP: float = 10.0
const ORIGIN: Vector2 = Vector2(33, 46)
const START_SPREAD: float = 0.12
const END_SPREAD: float = 0.045

var _round: int = 0
var _mistakes: int = 0
var _correct_index: int = 0
var _colors: Array[Color] = []
var _wrong_flash: int = -1
var _flash_left: float = 0.0

var _status: Label


func _ready() -> void:
	add_hint(tr("MG_RED_HINT"))
	_status = add_status()
	_new_round()


func _new_round() -> void:
	var spread: float = lerpf(START_SPREAD, END_SPREAD, float(_round) / (ROUNDS - 1))
	_colors.clear()
	_correct_index = randi_range(0, COLUMNS * ROWS - 1)
	for i: int in COLUMNS * ROWS:
		if i == _correct_index:
			_colors.append(UiStyle.RED)
			continue
		var shade: Color = UiStyle.RED
		shade.h = wrapf(shade.h + randf_range(-spread, spread) * 0.4, 0.0, 1.0)
		shade.v = clampf(shade.v + randf_range(-spread, spread), 0.0, 1.0)
		shade.s = clampf(shade.s + randf_range(-spread, spread), 0.0, 1.0)
		if shade.is_equal_approx(UiStyle.RED):
			shade.v -= spread
		_colors.append(shade)
	_update_status()


func _gui_input(event: InputEvent) -> void:
	var position: Variant = Minigame.press_position(event)
	if is_done() or position == null:
		return
	var local: Vector2 = (position as Vector2) - ORIGIN
	var cell: Vector2i = Vector2i(local / (SWATCH + GAP))
	var inside_cell: bool = fmod(local.x, SWATCH + GAP) < SWATCH and fmod(local.y, SWATCH + GAP) < SWATCH
	if local.x < 0 or local.y < 0 or cell.x >= COLUMNS or cell.y >= ROWS or not inside_cell:
		return
	var index: int = cell.y * COLUMNS + cell.x
	if index == _correct_index:
		_round += 1
		if _round >= ROUNDS:
			finish(true)
			return
		_new_round()
	else:
		_mistakes += 1
		_wrong_flash = index
		_flash_left = 0.3
		_update_status()
		if _mistakes >= MAX_MISTAKES:
			finish(false)


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	queue_redraw()


func _update_status() -> void:
	_status.text = "%s   %s" % [tr("MG_ROUND") % [mini(_round + 1, ROUNDS), ROUNDS], tr("MG_MISTAKES") % [_mistakes, MAX_MISTAKES]]


func _draw() -> void:
	for i: int in _colors.size():
		var cell: Vector2 = Vector2(i % COLUMNS, i / COLUMNS)
		var rect: Rect2 = Rect2(ORIGIN + cell * (SWATCH + GAP), Vector2(SWATCH, SWATCH))
		draw_rect(rect.grow(2), UiStyle.INK)
		draw_rect(rect, _colors[i])
		if i == _wrong_flash and _flash_left > 0.0:
			draw_line(rect.position, rect.end, Color.WHITE, 3.0)
			draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color.WHITE, 3.0)
