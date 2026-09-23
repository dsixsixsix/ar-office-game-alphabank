class_name StreakScene
extends IntroScene
## Big office-streak number with the points multiplier, the first-login bonus, and the bad news from
## the days the player missed: a lost streak and absence fines.

const COIN: Texture2D = preload("res://assets/ui/alfa_coin.png")
const VIEW: Rect2i = Rect2i(0, 0, 320, 230)

var _chimed: bool = false


func get_duration() -> float:
	return 3.2


func get_view() -> Rect2i:
	return VIEW


func is_ready_to_advance() -> bool:
	return intro.profile != null


func begin() -> void:
	layer(_draw_card)
	intro.audio.play_one("whoosh", -6.0, 1.3)


func update(_delta: float) -> void:
	if intro.profile != null and time > 0.25 and not _chimed:
		_chimed = true
		intro.audio.play_one("chime", -4.0)


func _draw_card(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(VIEW), Color("#1a0a0c"))
	var shift: float = fmod(time * 30.0, 20.0)
	for i: int in range(-1, 18):
		canvas.draw_rect(Rect2(i * 20 - shift, 0, 8, VIEW.size.y), Color(RED, 0.08))
	if intro.profile == null:
		draw_centered(canvas, "...", 120, 16, WHITE)
		return
	var font: Font = ThemeDB.fallback_font
	var pop: float = clampf(time / 0.35, 0.0, 1.0)
	var number_size: int = 8 + int(64.0 * ease(pop, -2.5))
	var number: String = str(intro.profile.streak_days)
	var width: float = font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var jitter: Vector2 = Vector2(randi_range(-2, 2), 0) if time < 0.5 else Vector2.ZERO
	var origin: Vector2 = Vector2(roundf(160.0 - width / 2.0), 112.0) + jitter
	canvas.draw_string(font, origin + Vector2(4, 4), number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, RED)
	canvas.draw_string(font, origin, number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, WHITE)
	if time > 0.4:
		draw_centered(canvas, tr("INTRO_STREAK_DAYS"), 140, 12, RED)
	if time > 0.8:
		draw_centered(canvas, tr("INTRO_MULTIPLIER") % ("%.1f" % intro.profile.multiplier), 170, 15, WHITE)
	if time > 1.0 and intro.profile.lost_streak > 0:
		draw_centered(canvas, tr("INTRO_STREAK_LOST") % intro.profile.lost_streak, 188, 9, Color("#ff8a80"))
	if time > 1.2 and intro.profile.fined_coins > 0:
		draw_centered(canvas, tr("INTRO_FINED") % intro.profile.fined_coins, 214, 10, RED)
	if time > 1.2 and intro.profile.welcome_bonus > 0:
		var text: String = tr("INTRO_WELCOME") % intro.profile.welcome_bonus
		draw_centered(canvas, text, 202, 10, Color("#f7c948"))
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var frame: int = int(time * 10.0) % 6
		canvas.draw_texture_rect_region(COIN, Rect2(roundf(160.0 - text_width / 2.0) - 19.0, 190, 16, 16), Rect2(frame * 16, 0, 16, 16))
