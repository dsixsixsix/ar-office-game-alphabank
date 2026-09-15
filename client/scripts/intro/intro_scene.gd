class_name IntroScene
extends Node2D
## One shot of an intro sequence, drawn in 320x180 stage coordinates. Children draw in creation order.

const INK: Color = Color("#1d1d1f")
const WHITE: Color = Color("#fbfaf8")
const RED: Color = Color("#ef3124")
const GLYPHS: Dictionary[String, String] = {
	"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
	"4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001001001001",
	"8": "111101111101111", "9": "111101111001111",
}

## Strong references: a texture loaded only inside _draw would be freed before it is rendered.
static var _textures: Dictionary[String, Texture2D] = {}

var time: float = 0.0
var intro: IntroContext


func get_duration() -> float:
	return 3.0


func get_caption_key() -> String:
	return ""


## Caption under the panel; scenes with dynamic text override this instead of get_caption_key().
func get_caption() -> String:
	var key: String = get_caption_key()
	return tr(key) if not key.is_empty() else ""


## Part of the 320x180 stage shown in the panel.
func get_view() -> Rect2i:
	return Rect2i(0, IntroArt.BAR_TOP, IntroArt.STAGE.x, IntroArt.STAGE.y - IntroArt.BAR_TOP - IntroArt.BAR_BOTTOM)


func is_ready_to_advance() -> bool:
	return true


func begin() -> void:
	pass


func finish() -> void:
	pass


func update(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	time += delta
	update(delta)


# --- Building blocks -------------------------------------------------------------


func layer(painter: Callable) -> DrawLayer:
	var draw_layer: DrawLayer = DrawLayer.new()
	draw_layer.painter = painter
	add_child(draw_layer)
	return draw_layer


func sprite(id: String, position_on_stage: Vector2 = Vector2.ZERO) -> Sprite2D:
	var node: Sprite2D = Sprite2D.new()
	node.texture = tex(id)
	node.centered = false
	node.position = position_on_stage
	add_child(node)
	return node


func character(look_id: String, feet: Vector2, facing: Vector2 = Vector2.DOWN) -> CharacterSprite:
	var body: CharacterSprite = CharacterSprite.new()
	add_child(body)
	body.setup(look_id)
	body.position = feet
	body.face(facing)
	return body


func vehicle(id: String, ground: Vector2) -> VehicleSprite:
	var node: VehicleSprite = VehicleSprite.new()
	node.position = ground
	add_child(node)
	node.setup(id)
	return node


## Moves a character between two points during [t0, t1], animating the walk.
func walk(body: CharacterSprite, from: Vector2, to: Vector2, t0: float, t1: float) -> void:
	var k: float = clampf((time - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
	body.position = from.lerp(to, k).round()
	body.set_walking(time >= t0 and k < 1.0, to - from)


static func tex(id: String) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load(IntroArt.path(id))
	return _textures[id]


## Draws a horizontally repeating layer scrolled by `offset` pixels.
static func draw_strip(canvas: CanvasItem, texture: Texture2D, y: float, offset: float, tint: Color = Color.WHITE) -> void:
	var width: float = texture.get_width()
	var x: float = -fposmod(offset, width)
	while x < IntroArt.STAGE.x:
		canvas.draw_texture(texture, Vector2(roundf(x), y), tint)
		x += width


static func draw_bubble(canvas: CanvasItem, anchor: Vector2, text: String, color: Color = INK) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 6.0
	var rect: Rect2 = Rect2(roundf(anchor.x - width / 2.0), roundf(anchor.y - 13.0), roundf(width), 12.0)
	canvas.draw_rect(rect.grow(1.0), INK)
	canvas.draw_rect(rect, WHITE)
	canvas.draw_rect(Rect2(roundf(anchor.x) - 1.0, rect.end.y + 1.0, 2.0, 2.0), INK)
	canvas.draw_string(font, rect.position + Vector2(3, 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


static func draw_centered(canvas: CanvasItem, text: String, y: float, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, Vector2(roundf(IntroArt.STAGE.x / 2.0 - width / 2.0), y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## 3x5 pixel digits, e.g. for the alarm clock.
static func draw_digits(canvas: CanvasItem, text: String, origin: Vector2, color: Color) -> void:
	var x: float = origin.x
	for character_text: String in text:
		if character_text == ":":
			canvas.draw_rect(Rect2(x, origin.y + 1, 1, 1), color)
			canvas.draw_rect(Rect2(x, origin.y + 3, 1, 1), color)
			x += 2.0
			continue
		var glyph: String = GLYPHS.get(character_text, "")
		for i: int in glyph.length():
			if glyph[i] == "1":
				canvas.draw_rect(Rect2(x + i % 3, origin.y + i / 3, 1, 1), color)
		x += 4.0
