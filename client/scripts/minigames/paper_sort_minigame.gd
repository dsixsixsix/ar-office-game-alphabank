class_name PaperSortMinigame
extends Minigame
## Tap the left half for red-stamped documents and the right half for white ones.

const DOCUMENTS: int = 10
const MAX_MISTAKES: int = 2
const CARD_SIZE: Vector2 = Vector2(96, 124)
const CARD_CENTER_Y: float = 118.0
const TRAY_Y: float = 206.0
const TRAY_SIZE: Vector2 = Vector2(120, 100)
const FLY_TIME: float = 0.18

var _is_red: Array[bool] = []
var _index: int = 0
var _mistakes: int = 0
var _fly: float = 0.0
var _fly_to_left: bool = true
var _fly_red: bool = true
var _shake: float = 0.0

var _status: Label


func _ready() -> void:
	for i: int in DOCUMENTS:
		_is_red.append(randf() < 0.5)
	add_hint(tr("MG_SORT_HINT"))
	_status = add_status()


func _gui_input(event: InputEvent) -> void:
	var position: Variant = Minigame.press_position(event)
	if is_done() or position == null or _index >= DOCUMENTS:
		return
	var to_left: bool = (position as Vector2).x < size.x * 0.5
	var red: bool = _is_red[_index]
	if to_left != red:
		_mistakes += 1
		_shake = 0.3
	_fly = FLY_TIME
	_fly_to_left = to_left
	_fly_red = red
	_index += 1
	if _mistakes > MAX_MISTAKES:
		finish(false)
	elif _index >= DOCUMENTS:
		finish(true)


func _process(delta: float) -> void:
	_fly = maxf(0.0, _fly - delta)
	_shake = maxf(0.0, _shake - delta)
	_status.text = "%s   %s" % [tr("MG_SORT_PROGRESS") % [_index, DOCUMENTS], tr("MG_MISTAKES") % [_mistakes, MAX_MISTAKES]]
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = Vector2(size.x * 0.5, CARD_CENTER_Y)
	var left_tray: Rect2 = Rect2(Vector2(20, TRAY_Y), TRAY_SIZE)
	var right_tray: Rect2 = Rect2(Vector2(size.x - 20 - TRAY_SIZE.x, TRAY_Y), TRAY_SIZE)
	_draw_tray(left_tray, UiStyle.RED)
	_draw_tray(right_tray, UiStyle.PAPER)
	draw_line(Vector2(size.x * 0.5, TRAY_Y - 10), Vector2(size.x * 0.5, STATUS_Y - 6), Color(UiStyle.INK, 0.15), 1.0)
	if _index < DOCUMENTS:
		var jitter: Vector2 = Vector2(sin(_shake * 80.0) * 6.0 * _shake / 0.3, 0)
		_draw_card(center + jitter, _is_red[_index], 1.0)
	if _fly > 0.0:
		var t: float = 1.0 - _fly / FLY_TIME
		var target: Vector2 = (left_tray if _fly_to_left else right_tray).get_center()
		_draw_card(center.lerp(target, t), _fly_red, 1.0 - t * 0.5)


func _draw_tray(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(2), UiStyle.INK)
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16)), Color(0, 0, 0, 0.12))


func _draw_card(center: Vector2, red: bool, card_scale: float) -> void:
	var card_size: Vector2 = CARD_SIZE * card_scale
	var rect: Rect2 = Rect2(center - card_size * 0.5, card_size)
	draw_rect(rect.grow(1), UiStyle.INK)
	draw_rect(rect, Color.WHITE)
	draw_rect(Rect2(rect.position, Vector2(card_size.x, 20 * card_scale)), UiStyle.RED if red else UiStyle.PAPER_EDGE)
	for line: int in 5:
		var y: float = rect.position.y + (32 + line * 16) * card_scale
		draw_rect(Rect2(rect.position.x + 10 * card_scale, y, card_size.x - 20 * card_scale, 4 * card_scale), UiStyle.PAPER_EDGE)
