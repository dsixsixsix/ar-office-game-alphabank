class_name WakeScene
extends IntroScene
## Bedroom: alarm rings, the player wakes up, throws the blanket off and heads out.

## Head of the side-facing idle frame inside the 48x64 sheet cell.
const HEAD_REGION: Rect2 = Rect2(CharacterPainter.BODY_OFFSET.x + 7, 2 * CharacterPainter.FRAME.y + CharacterPainter.BODY_OFFSET.y + 1, 18, 19)
const HEAD_POS: Vector2 = Vector2(133, 104)
const ALARM_START: float = 0.3
const ALARM_STOP: float = 1.8
const STAND: Vector2 = Vector2(192, 146)

var _blanket: Sprite2D
var _head: Sprite2D
var _player: CharacterSprite
var _alarm_started: bool = false
var _woke: bool = false


func get_duration() -> float:
	return 4.6


func get_caption_key() -> String:
	return "INTRO_WAKE"


func begin() -> void:
	sprite("bedroom")
	layer(_draw_clock)
	_head = Sprite2D.new()
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = CharacterSprite.sheet_texture(CharacterSprite.PLAYER_ID)
	atlas.region = HEAD_REGION
	_head.texture = atlas
	_head.rotation = -PI / 2.0
	_head.position = HEAD_POS
	add_child(_head)
	_blanket = sprite("bedroom_blanket")
	_blanket.region_enabled = true
	_blanket.region_rect = Rect2(0, 0, 320, 180)
	_player = character(CharacterSprite.PLAYER_ID, STAND, Vector2.DOWN)
	_player.visible = false
	layer(_draw_overlay)


func update(_delta: float) -> void:
	if time >= ALARM_START and not _alarm_started:
		_alarm_started = true
		intro.audio.play_loop("alarm", -8.0)
	var ringing: bool = time >= ALARM_START and time < ALARM_STOP
	intro.shake = 0.6 if ringing else 0.0
	if time >= ALARM_STOP and not _woke:
		_woke = true
		intro.audio.stop_loop("alarm", 0.05)
		intro.audio.play_one("whoosh", -12.0, 1.6)
		_blanket.region_rect = Rect2(0, 180, 320, 180)
		_head.visible = false
		_player.visible = true
	if _woke:
		walk(_player, STAND, Vector2(350, 146), 2.8, 4.6)


func finish() -> void:
	intro.shake = 0.0


func _draw_clock(canvas: CanvasItem) -> void:
	var blinking: bool = time >= ALARM_START and time < ALARM_STOP
	var lit: bool = not blinking or fmod(time * 4.0, 1.0) < 0.6
	draw_digits(canvas, "7:30", Vector2(108, 103), Color("#ff3b30") if lit else Color("#5a1010"))


func _draw_overlay(canvas: CanvasItem) -> void:
	var font: Font = ThemeDB.fallback_font
	if time < 1.2:
		for i: int in 3:
			var k: float = fmod(time * 0.8 + i / 3.0, 1.0)
			canvas.draw_string(font, HEAD_POS + Vector2(6 + k * 12, -8 - k * 20), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 7 + int(k * 5), Color(INK, 1.0 - k))
	if time > 1.0 and time < 1.9:
		draw_bubble(canvas, HEAD_POS + Vector2(2, -12), "!", RED)
	if time > 1.9 and time < 2.8:
		draw_bubble(canvas, _player.position + Vector2(0, -52), "...")
