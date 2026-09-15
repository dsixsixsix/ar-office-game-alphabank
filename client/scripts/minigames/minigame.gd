class_name Minigame
extends Control
## Base class for short task minigames. Subclasses call finish() exactly once.

signal finished(success: bool)

## Portrait play area.
const AREA_SIZE: Vector2 = Vector2(320, 340)
const STATUS_Y: float = AREA_SIZE.y - 22.0

var _is_done: bool = false


func _init() -> void:
	custom_minimum_size = AREA_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func finish(success: bool) -> void:
	if _is_done:
		return
	_is_done = true
	finished.emit(success)


func is_done() -> bool:
	return _is_done


## Hint at the top of the play area, wrapped to its width.
func add_hint(text: String) -> Label:
	var hint: Label = UiStyle.make_label(text, 11, UiStyle.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(8, 2)
	hint.size = Vector2(AREA_SIZE.x - 16.0, 30)
	add_child(hint)
	return hint


func add_status() -> Label:
	var status: Label = UiStyle.make_label("", 12)
	status.position = Vector2(8, STATUS_Y)
	add_child(status)
	return status


## Position of a primary press inside this control, or null when event is not a press.
static func press_position(event: InputEvent) -> Variant:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		return mouse.position
	return null


static func is_release(event: InputEvent) -> bool:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	return mouse != null and not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT


static func create(kind: String) -> Minigame:
	match kind:
		"coffee":
			return CoffeeMinigame.new()
		"bubble_wrap":
			return BubbleWrapMinigame.new()
		"paper_sort":
			return PaperSortMinigame.new()
		"alfa_red":
			return AlfaRedMinigame.new()
		_:
			return CheckInMinigame.new()
