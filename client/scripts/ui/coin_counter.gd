class_name CoinCounter
extends PanelContainer
## Animated Alfa-coin balance. Counts up/down smoothly when Backend reports a new balance.

const COIN_SHEET: Texture2D = preload("res://assets/ui/alfa_coin.png")
const COIN_FRAMES: int = 6
const COIN_SIZE: int = 16
const FRAME_TIME: float = 0.1
const COUNT_SPEED: float = 6.0

var _shown: float = 0.0
var _target: int = 0
var _frame_time: float = 0.0
var _frame: int = 0
var _pulse: float = 0.0

var _icon: TextureRect
var _atlas: AtlasTexture
var _label: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.PAPER, 8, 4))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_atlas = AtlasTexture.new()
	_atlas.atlas = COIN_SHEET
	_icon = TextureRect.new()
	_icon.texture = _atlas
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	_label = UiStyle.make_label("0", 14)
	row.add_child(_label)
	Backend.balance_changed.connect(_on_balance_changed)
	_on_balance_changed(Backend.get_balance())
	_shown = _target
	_set_frame(0)


## Screen-space centre of the coin icon, used as the fly-to target for reward effects.
func get_coin_center() -> Vector2:
	return _icon.get_global_rect().get_center()


func _on_balance_changed(balance: int) -> void:
	_target = balance
	_pulse = 1.0


func _process(delta: float) -> void:
	_shown = lerpf(_shown, float(_target), 1.0 - exp(-COUNT_SPEED * delta))
	if absf(_shown - _target) < 0.5:
		_shown = _target
	_label.text = str(roundi(_shown))
	_pulse = maxf(0.0, _pulse - delta * 2.0)
	_label.label_settings.font_color = UiStyle.INK.lerp(UiStyle.RED, _pulse)
	_frame_time += delta * (1.0 + _pulse * 3.0)
	if _frame_time >= FRAME_TIME:
		_frame_time = 0.0
		_set_frame((_frame + 1) % COIN_FRAMES)


func _set_frame(frame: int) -> void:
	_frame = frame
	_atlas.region = Rect2(frame * COIN_SIZE, 0, COIN_SIZE, COIN_SIZE)
