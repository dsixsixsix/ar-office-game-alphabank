class_name BreakfastScene
extends IntroScene
## Home kitchen: the player eats breakfast at the table while the kettle steams.

const PLAYER_FEET: Vector2 = Vector2(236, 150)
const EAT_START: float = 0.5
const BITE_TIME: float = 0.7
const EAT_TIME: float = 2.4

var _player: CharacterSprite
var _last_bite: int = -1
var _skin: Color


func get_duration() -> float:
	return 3.4


func get_caption_key() -> String:
	return "INTRO_BREAKFAST"


func begin() -> void:
	_skin = Appearance.get_skin_color()
	sprite("home_kitchen")
	layer(_draw_steam)
	_player = character(CharacterSprite.PLAYER_ID, PLAYER_FEET, Vector2.DOWN)
	sprite("kitchen_table")
	layer(_draw_table)


func update(_delta: float) -> void:
	var bite: int = int((time - EAT_START) / BITE_TIME)
	if time >= EAT_START and time < EAT_START + EAT_TIME and bite != _last_bite:
		_last_bite = bite
		intro.audio.play_one("clink", -10.0, randf_range(0.9, 1.15))


func _draw_steam(canvas: CanvasItem) -> void:
	for origin: Vector2 in [Vector2(72, 88), Vector2(255, 116)]:
		for i: int in 3:
			var k: float = fmod(time * 0.9 + i / 3.0, 1.0)
			var x: float = origin.x + sin(k * 6.0 + i) * 2.0
			canvas.draw_rect(Rect2(roundf(x), roundf(origin.y - k * 14.0), 1, 3), Color(1, 1, 1, 0.55 * (1.0 - k)))


func _draw_table(canvas: CanvasItem) -> void:
	var left: float = 1.0 - clampf((time - EAT_START) / EAT_TIME, 0.0, 1.0)
	if left > 0.05:
		canvas.draw_circle(Vector2(231, 126), 4.5 * left + 0.5, WHITE)
		canvas.draw_circle(Vector2(231, 126), 1.8 * left + 0.3, Color("#ffc233"))
		canvas.draw_rect(Rect2(237, 124, roundf(7.0 * left) + 1.0, 3), Color("#d9a060"))
		canvas.draw_rect(Rect2(237, 124, roundf(7.0 * left) + 1.0, 1), Color("#8a5a2a"))
	var phase: float = fmod(maxf(time - EAT_START, 0.0) / BITE_TIME, 1.0)
	var lift: float = sin(phase * PI) if time >= EAT_START and time < EAT_START + EAT_TIME else 0.0
	var hand: Vector2 = Vector2(242, roundf(128.0 - lift * 8.0))
	canvas.draw_line(hand, hand + Vector2(-4, -2), Color("#b9bec6"), 1.0)
	canvas.draw_rect(Rect2(hand, Vector2(3, 2)), _skin)
	if time > EAT_START + EAT_TIME + 0.1:
		draw_bubble(canvas, _player.position + Vector2(0, -52), "♪")
