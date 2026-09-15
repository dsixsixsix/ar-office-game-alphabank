class_name NpcAction
extends RefCounted
## Office activities an NPC can perform and their speech-bubble icons.

enum Kind { TYPING, COFFEE, PAPERS, PHONE, WATERING, MUSIC, DANCE, DRINK, SKETCH }

const INK: Color = Color("#2b2b30")
const RED: Color = Color("#ef3124")
const CYAN: Color = Color("#3fb6c4")
const GREEN: Color = Color("#3f9e4a")
const BROWN: Color = Color("#7a4a2a")


## Draws a 7x7 icon with its top-left corner at origin.
static func draw_icon(canvas: CanvasItem, kind: Kind, origin: Vector2) -> void:
	var r: Callable = func(x: float, y: float, w: float, h: float, color: Color) -> void:
		canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2(w, h)), color)
	match kind:
		Kind.TYPING:
			r.call(0, 0, 7, 4, INK)
			r.call(1, 1, 5, 2, CYAN)
			r.call(0, 5, 7, 2, INK)
		Kind.COFFEE:
			r.call(1, 2, 4, 5, RED)
			r.call(5, 3, 1, 2, RED)
			r.call(2, 0, 1, 1, INK)
			r.call(4, 0, 1, 1, INK)
		Kind.PAPERS:
			r.call(0, 1, 5, 6, INK)
			r.call(2, 0, 5, 6, Color.WHITE)
			r.call(3, 2, 3, 1, INK)
			r.call(3, 4, 3, 1, INK)
		Kind.PHONE:
			r.call(2, 0, 3, 7, INK)
			r.call(3, 1, 1, 4, CYAN)
		Kind.WATERING:
			r.call(0, 3, 5, 4, GREEN)
			r.call(5, 2, 2, 1, GREEN)
			r.call(6, 4, 1, 1, CYAN)
		Kind.MUSIC:
			r.call(2, 0, 4, 1, INK)
			r.call(2, 0, 1, 6, INK)
			r.call(5, 0, 1, 5, INK)
			r.call(0, 5, 3, 2, INK)
			r.call(3, 4, 3, 2, INK)
		Kind.DANCE:
			r.call(0, 0, 2, 2, RED)
			r.call(5, 1, 2, 2, CYAN)
			r.call(2, 4, 2, 2, GREEN)
			r.call(5, 5, 1, 1, RED)
		Kind.DRINK:
			r.call(1, 0, 5, 3, RED)
			r.call(3, 3, 1, 3, INK)
			r.call(1, 6, 5, 1, INK)
		Kind.SKETCH:
			r.call(0, 5, 2, 2, INK)
			r.call(1, 4, 2, 2, BROWN)
			r.call(3, 2, 2, 2, BROWN)
			r.call(5, 0, 2, 2, RED)


## Whether the body should bob instead of standing still.
static func is_bouncy(kind: Kind) -> bool:
	return kind == Kind.DANCE or kind == Kind.MUSIC
