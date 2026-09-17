class_name CameraView
extends Control
## Shows PlatformServices camera frames, cropped to fill the control, with the camera shader.
## Overlays (face boxes, pose points, the probe square) are drawn by the owner through `overlay`.

const SHADER: Shader = preload("res://shaders/camera_feed.gdshader")
const FRAME_COLOR: Color = Color("#1d1d1f")
const WAITING_COLOR: Color = Color("#2b2730")

## Called with (view, image_rect) after the frame is drawn; image_rect maps normalized frame coordinates.
var overlay: Callable

var _texture: ImageTexture
var _frame_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = SHADER
	PlatformServices.camera_frame.connect(_on_frame)


func _exit_tree() -> void:
	if PlatformServices.camera_frame.is_connected(_on_frame):
		PlatformServices.camera_frame.disconnect(_on_frame)


func has_frame() -> bool:
	return _texture != null


## Rectangle the whole frame occupies inside the control (it overflows to fill the control).
func get_image_rect() -> Rect2:
	if _frame_size == Vector2.ZERO:
		return Rect2(Vector2.ZERO, size)
	var scale_factor: float = maxf(size.x / _frame_size.x, size.y / _frame_size.y)
	var image_size: Vector2 = _frame_size * scale_factor
	return Rect2((size - image_size) / 2.0, image_size)


func _on_frame(frame: Image) -> void:
	if _texture == null or Vector2(frame.get_size()) != _frame_size:
		_texture = ImageTexture.create_from_image(frame)
		_frame_size = Vector2(frame.get_size())
	else:
		_texture.update(frame)
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		draw_rect(Rect2(Vector2.ZERO, size), WAITING_COLOR)
	else:
		draw_texture_rect(_texture, get_image_rect(), false)
	if overlay.is_valid():
		overlay.call(self, get_image_rect())
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 3.0)
