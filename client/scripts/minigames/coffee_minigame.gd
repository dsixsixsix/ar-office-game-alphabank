class_name CoffeeMinigame
extends Minigame
## Hold to pour; release when the coffee reaches the marked band. Three good cups win.

const CUPS_NEEDED: int = 3
const MAX_ATTEMPTS: int = 5
const POUR_SPEED: float = 0.55
const BAND_LOW: float = 0.68
const BAND_HIGH: float = 0.84
const CUP_RECT: Rect2 = Rect2(110, 110, 90, 180)
const COFFEE: Color = Color("#6b3d26")

var _level: float = 0.0
var _pouring: bool = false
var _good: int = 0
var _attempts: int = 0
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE

var _status: Label


func _ready() -> void:
	add_hint(tr("MG_COFFEE_HINT"))
	_status = add_status()
	_update_status()


func _gui_input(event: InputEvent) -> void:
	if is_done():
		return
	if Minigame.press_position(event) != null:
		_pouring = true
		_level = 0.0
	elif Minigame.is_release(event) and _pouring:
		_pouring = false
		_judge()


func _process(delta: float) -> void:
	if _pouring:
		_level += POUR_SPEED * delta
		if _level >= 1.0:
			_pouring = false
			_judge()
	_flash = maxf(0.0, _flash - delta * 3.0)
	queue_redraw()


func _judge() -> void:
	_attempts += 1
	var good: bool = _level >= BAND_LOW and _level <= BAND_HIGH
	if good:
		_good += 1
	_flash = 1.0
	_flash_color = Color("#3f9e4a") if good else UiStyle.RED
	_update_status()
	if _good >= CUPS_NEEDED:
		finish(true)
	elif MAX_ATTEMPTS - _attempts < CUPS_NEEDED - _good:
		finish(false)


func _update_status() -> void:
	_status.text = tr("MG_CUPS") % [_good, CUPS_NEEDED]


func _draw() -> void:
	var cup: Rect2 = CUP_RECT
	# Coffee machine spout above the cup.
	draw_rect(Rect2(cup.get_center().x - 40, 40, 80, 26), UiStyle.INK)
	draw_rect(Rect2(cup.get_center().x - 8, 66, 16, 10), Color("#3a3a44"))
	draw_rect(Rect2(cup.get_center().x - 30, 48, 8, 4), UiStyle.RED)
	draw_rect(cup.grow(3), UiStyle.INK)
	draw_rect(cup, UiStyle.PAPER)
	var fill_height: float = cup.size.y * minf(_level, 1.0)
	draw_rect(Rect2(cup.position.x, cup.end.y - fill_height, cup.size.x, fill_height), COFFEE)
	for band: float in [BAND_LOW, BAND_HIGH]:
		var y: float = cup.end.y - cup.size.y * band
		draw_rect(Rect2(cup.position.x - 10, y, cup.size.x + 20, 1), UiStyle.RED)
	draw_rect(Rect2(cup.end.x + 3, cup.position.y + 40, 16, 6), UiStyle.INK)
	draw_rect(Rect2(cup.end.x + 13, cup.position.y + 40, 6, 60), UiStyle.INK)
	draw_rect(Rect2(cup.end.x + 3, cup.position.y + 94, 16, 6), UiStyle.INK)
	if _pouring:
		draw_rect(Rect2(cup.get_center().x - 2, 76, 4, cup.end.y - fill_height - 76), COFFEE)
	if _flash > 0.0:
		draw_rect(cup.grow(6), Color(_flash_color, _flash), false, 3.0)
