class_name BathroomScene
extends IntroScene
## Bathroom: the player brushes teeth, the mirror shows a sleepy face and foam.

const PLAYER_FEET: Vector2 = Vector2(168, 146)
const REFLECTION: Vector2 = Vector2(156, 60)
## Head and shoulders of the front idle frame inside the 48x64 sheet cell.
const FACE_REGION: Rect2 = Rect2(CharacterPainter.BODY_OFFSET.x + 4, CharacterPainter.BODY_OFFSET.y, 24, 34)
const BRUSH_START: float = 0.4
const BRUSH_END: float = 2.8

var _player: CharacterSprite
var _body_texture: Texture2D
var _skin: Color


func get_duration() -> float:
	return 3.4


func get_caption_key() -> String:
	return "INTRO_TEETH"


func begin() -> void:
	_body_texture = CharacterSprite.sheet_texture(CharacterSprite.PLAYER_ID)
	_skin = Appearance.get_skin_color()
	sprite("bathroom")
	layer(_draw_reflection)
	_player = character(CharacterSprite.PLAYER_ID, PLAYER_FEET, Vector2.UP)
	layer(_draw_water)
	intro.audio.play_loop("brush_loop", -8.0)


func update(_delta: float) -> void:
	_player.position.x = PLAYER_FEET.x + (1.0 if _is_brushing() and _stroke() else 0.0)
	if time >= BRUSH_END:
		intro.audio.stop_loop("brush_loop", 0.1)


func finish() -> void:
	intro.audio.stop_loop("brush_loop", 0.05)


func _is_brushing() -> bool:
	return time >= BRUSH_START and time < BRUSH_END


func _stroke() -> bool:
	return fmod(time * 8.0, 1.0) < 0.5


func _draw_reflection(canvas: CanvasItem) -> void:
	var shift: float = -1.0 if _is_brushing() and _stroke() else 0.0
	var base: Vector2 = REFLECTION + Vector2(shift, 0)
	canvas.draw_texture_rect_region(_body_texture, Rect2(base, FACE_REGION.size), FACE_REGION, Color(0.9, 0.95, 1.0))
	if time < 2.3:
		canvas.draw_rect(Rect2(base + Vector2(8, 10), Vector2(2, 1)), _skin)
		canvas.draw_rect(Rect2(base + Vector2(14, 10), Vector2(2, 1)), _skin)
	if _is_brushing():
		var brush_x: float = base.x + 13.0 + (2.0 if _stroke() else 0.0)
		canvas.draw_rect(Rect2(brush_x, base.y + 15, 7, 1), WHITE)
		canvas.draw_rect(Rect2(brush_x + 5, base.y + 15, 2, 1), RED)
		var foam: int = int(clampf((time - BRUSH_START) * 3.0, 0.0, 6.0))
		for i: int in foam:
			canvas.draw_rect(Rect2(base.x + 9 + (i * 3) % 7, base.y + 14 + (i % 3), 1, 1), WHITE)
	canvas.draw_line(Vector2(146, 98), Vector2(170, 52), Color(1, 1, 1, 0.16), 2.0)


func _draw_water(canvas: CanvasItem) -> void:
	if time >= BRUSH_END and time < 3.3:
		for i: int in 3:
			var y: float = 96.0 + fmod(time * 40.0 + i * 3.0, 8.0)
			canvas.draw_rect(Rect2(171, y, 1, 2), Color(0.6, 0.85, 1.0, 0.8))
	if time > 2.9:
		draw_bubble(canvas, _player.position + Vector2(0, -52), ":)")
