class_name SleepScene
extends IntroScene
## Bedroom late at night: the player comes in, gets under the blanket, the light goes out and only
## the alarm clock glows.

const EVENING: Color = Color(0.78, 0.7, 0.72)
const DARK: Color = Color(0.02, 0.02, 0.08)
const DOORWAY: Vector2 = Vector2(350, 146)
const WALK_START: float = 0.2
const WALK_END: float = 2.0
const IN_BED: float = 2.3
const LIGHTS_OFF: float = 3.1
const CLOCK_POS: Vector2 = Vector2(108, 103)

var _blanket: Sprite2D
var _head: Sprite2D
var _player: CharacterSprite
var _in_bed: bool = false
var _clicked: bool = false


func get_duration() -> float:
	return 6.0


func get_caption_key() -> String:
	return "INTRO_SLEEP"


func begin() -> void:
	sprite("bedroom").modulate = EVENING
	layer(_draw_clock)
	_head = Sprite2D.new()
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = CharacterSprite.sheet_texture(CharacterSprite.PLAYER_ID)
	atlas.region = WakeScene.HEAD_REGION
	_head.texture = atlas
	_head.rotation = -PI / 2.0
	_head.position = WakeScene.HEAD_POS
	_head.visible = false
	add_child(_head)
	_blanket = sprite("bedroom_blanket")
	_blanket.region_enabled = true
	_blanket.region_rect = Rect2(0, 180, 320, 180)
	_blanket.modulate = EVENING
	_player = character(CharacterSprite.PLAYER_ID, DOORWAY, Vector2.LEFT)
	_player.modulate = EVENING
	layer(_draw_overlay)


func update(_delta: float) -> void:
	if not _in_bed:
		walk(_player, DOORWAY, WakeScene.STAND, WALK_START, WALK_END)
	if time >= IN_BED and not _in_bed:
		_in_bed = true
		_player.visible = false
		_head.visible = true
		_blanket.region_rect = Rect2(0, 0, 320, 180)
		intro.audio.play_one("whoosh", -12.0, 1.3)
	if time >= LIGHTS_OFF and not _clicked:
		_clicked = true
		intro.audio.play_one("clink", -14.0, 1.8)


func _darkness() -> float:
	return clampf((time - LIGHTS_OFF) / 0.2, 0.0, 1.0)


func _draw_clock(canvas: CanvasItem) -> void:
	draw_digits(canvas, "0:00", CLOCK_POS, Color("#ff3b30"))


func _draw_overlay(canvas: CanvasItem) -> void:
	var dark: float = _darkness()
	if time > WALK_END and time < IN_BED + 0.4:
		draw_bubble(canvas, _player.position + Vector2(0, -52) if _player.visible else WakeScene.HEAD_POS + Vector2(2, -12), "...")
	if dark <= 0.0:
		return
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(IntroArt.STAGE)), Color(DARK, 0.78 * dark))
	canvas.draw_rect(Rect2(CLOCK_POS - Vector2(3, 3), Vector2(20, 11)), Color(1.0, 0.2, 0.15, 0.12 * dark))
	draw_digits(canvas, "0:00", CLOCK_POS, Color(Color("#ff3b30"), dark))
	var font: Font = ThemeDB.fallback_font
	for i: int in 3:
		var k: float = fmod((time - LIGHTS_OFF) * 0.7 + i / 3.0, 1.0)
		var color: Color = Color(0.85, 0.88, 1.0, (1.0 - k) * dark)
		canvas.draw_string(font, WakeScene.HEAD_POS + Vector2(6 + k * 12, -8 - k * 20), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 7 + int(k * 5), color)
