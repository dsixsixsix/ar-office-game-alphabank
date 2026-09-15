class_name DiscoLights
extends Node2D
## Slowly drifting additive colour spots over the design department floor.

@export var area: Rect2 = Rect2(0, 0, 240, 416)

const COLORS: Array[Color] = [Color(0.94, 0.19, 0.14, 0.22), Color(0.6, 0.2, 0.9, 0.2), Color(0.36, 0.88, 0.9, 0.16)]
const RADIUS: float = 42.0

var _time: float = 0.0


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for i: int in COLORS.size():
		var phase: float = _time * (0.35 + i * 0.12) + i * 2.1
		var point: Vector2 = area.get_center() + Vector2(cos(phase), sin(phase * 1.3)) * area.size * Vector2(0.35, 0.4)
		for ring: int in 3:
			draw_circle(point, RADIUS * (1.0 - ring * 0.3), COLORS[i])
