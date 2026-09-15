class_name SpeechBubble
extends Node2D
## Short comic speech bubble above a character's head, drawn in world space.

const MAX_WIDTH: float = 156.0
const FONT_SIZE: int = 10
const HEAD_Y: float = -72.0
const FADE_TIME: float = 0.3
const LAYOUT_SETTLE_FRAMES: int = 2

var _panel: PanelContainer
var _label: Label
var _left: float = 0.0
var _hidden_frames: int = 0


func _ready() -> void:
	z_index = 40
	visible = false
	_panel = PanelContainer.new()
	var style: StyleBoxFlat = UiStyle.panel(UiStyle.PAPER, 4, 5)
	style.set_border_width_all(1)
	style.border_color = UiStyle.INK
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = UiStyle.make_label("", FONT_SIZE, UiStyle.INK)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)


func say(text: String, duration: float = 3.2) -> void:
	var text_width: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var width: float = minf(ceilf(text_width) + 2.0, MAX_WIDTH)
	_label.custom_minimum_size = Vector2(width, 0)
	_label.text = text
	# An autowrapped label measures its height at its current width, and only after a layout pass.
	# Before the first layout that width is zero, so every word would get its own line and the
	# bubble would be screen-tall. The panel is re-fitted every frame and hidden until it settles.
	_label.size = Vector2(width, 0)
	_panel.reset_size()
	_hidden_frames = LAYOUT_SETTLE_FRAMES
	_left = duration
	visible = true
	modulate.a = 0.0


func is_talking() -> bool:
	return visible and _left > FADE_TIME


func hide_bubble() -> void:
	_left = minf(_left, FADE_TIME)


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	_hidden_frames = maxi(0, _hidden_frames - 1)
	modulate.a = 0.0 if _hidden_frames > 0 else clampf(_left / FADE_TIME, 0.0, 1.0)
	if _left <= 0.0:
		visible = false
		return
	_panel.reset_size()
	_panel.position = Vector2(roundf(-_panel.size.x / 2.0), roundf(HEAD_Y - _panel.size.y))
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-4, HEAD_Y - 1), Vector2(4, HEAD_Y - 1), Vector2(0, HEAD_Y + 6)]), UiStyle.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, HEAD_Y - 2), Vector2(3, HEAD_Y - 2), Vector2(0, HEAD_Y + 4)]), UiStyle.PAPER)
