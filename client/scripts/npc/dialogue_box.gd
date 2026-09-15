class_name DialogueBox
extends CanvasLayer
## Cinematic dialogue for portrait screens: letterbox bars, slanted portrait panel above the text,
## wavy typewriter text. Tap to advance.

signal finished

const PORTRAIT_SIZE: Vector2 = Vector2(24, 26)
const PORTRAIT_SCALE: int = 5
const TOP_BAR: float = 26.0
const BOTTOM_BAR: float = 128.0
const CHARS_PER_SECOND: float = 45.0
const PANEL_COLOR: Color = Color("#7a2a8c")
const PANEL_STRIPE: Color = Color("#ef3124")
const NPC_TEXT: Color = Color("#fbfaf8")
const PLAYER_TEXT: Color = Color("#7fe3ea")

var _lines: Array[DialogueRepository.Line] = []
var _index: int = 0
var _npc_name: String = ""
var _reveal: float = 0.0
var _open_amount: float = 0.0
var _closing: bool = false

var _root: Control
var _top: ColorRect
var _bottom: ColorRect
var _panel: Panel
var _portrait: TextureRect
var _name_label: Label
var _text: RichTextLabel
var _next_marker: Label


func _ready() -> void:
	layer = 40
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_top = _make_bar()
	_bottom = _make_bar()

	_panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_width_left = 4
	style.border_color = PANEL_STRIPE
	style.skew = Vector2(0.25, 0.0)
	style.anti_aliasing = false
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size = PORTRAIT_SIZE * PORTRAIT_SCALE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait)

	_name_label = UiStyle.make_label("", 11, UiStyle.RED)
	_root.add_child(_name_label)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 14)
	_root.add_child(_text)

	_next_marker = UiStyle.make_label("▼", 11, UiStyle.RED)
	_root.add_child(_next_marker)


## look_id may be empty for lines without a portrait.
func open(npc_name: String, look_id: String, lines: Array[DialogueRepository.Line]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_npc_name = npc_name
	_lines = lines
	_index = 0
	_closing = false
	_portrait.texture = CharacterSprite.portrait_texture(look_id) if not look_id.is_empty() else null
	visible = true
	_show_line()


func is_open() -> bool:
	return visible


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.pressed:
		_advance()
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _closing:
		return
	if _text.visible_ratio < 1.0:
		_reveal = float(_text.get_total_character_count())
		return
	_index += 1
	if _index >= _lines.size():
		_closing = true
		return
	_show_line()


func _show_line() -> void:
	var line: DialogueRepository.Line = _lines[_index]
	_name_label.text = (tr("DIALOGUE_YOU") if line.is_player else _npc_name).to_upper()
	var color: Color = PLAYER_TEXT if line.is_player else NPC_TEXT
	_text.text = "[wave amp=18 freq=3][color=#%s]%s[/color][/wave]" % [color.to_html(false), line.text.to_upper()]
	_reveal = 0.0
	_text.visible_characters = 0
	_panel.visible = not line.is_player and _portrait.texture != null


func _process(delta: float) -> void:
	if not visible:
		return
	_open_amount = move_toward(_open_amount, 0.0 if _closing else 1.0, delta * 5.0)
	if _closing and _open_amount <= 0.0:
		visible = false
		finished.emit()
		return
	_reveal += delta * CHARS_PER_SECOND
	_text.visible_characters = int(_reveal)
	_next_marker.visible = _text.visible_ratio >= 1.0 and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.0
	_layout()


func _layout() -> void:
	var viewport: Vector2 = _root.size
	var safe: Rect2 = PlatformServices.get_safe_rect()
	var ease_amount: float = ease(_open_amount, -2.0)
	var top_height: float = TOP_BAR + safe.position.y
	var bottom_height: float = BOTTOM_BAR + viewport.y - safe.end.y
	_top.position = Vector2(0, -top_height * (1.0 - ease_amount))
	_top.size = Vector2(viewport.x, top_height)
	_bottom.size = Vector2(viewport.x, bottom_height)
	_bottom.position = Vector2(0, viewport.y - bottom_height * ease_amount)

	var portrait_px: Vector2 = PORTRAIT_SIZE * PORTRAIT_SCALE
	var panel_size: Vector2 = Vector2(portrait_px.x + 40.0, portrait_px.y + 18.0)
	_panel.size = panel_size
	_panel.position = Vector2(safe.end.x - panel_size.x * ease_amount + 20.0, _bottom.position.y - panel_size.y + 6.0)
	_portrait.position = Vector2(14.0, panel_size.y - portrait_px.y)

	var text_left: float = safe.position.x + 14.0
	_name_label.position = Vector2(text_left, _bottom.position.y + 10.0)
	_text.position = Vector2(text_left, _bottom.position.y + 28.0)
	_text.size = Vector2(safe.size.x - 36.0, BOTTOM_BAR - 40.0)
	_next_marker.position = Vector2(safe.end.x - 22.0, _bottom.position.y + BOTTOM_BAR - 22.0)


func _make_bar() -> ColorRect:
	var bar: ColorRect = ColorRect.new()
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	return bar
