class_name DrawLayer
extends Node2D
## Redraws every frame by calling `painter` with itself as the canvas. Keeps draw order explicit.

var painter: Callable


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
