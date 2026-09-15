class_name Player
extends Node2D
## Player avatar that walks along a list of world points and can say short remarks.

signal arrived

const LOOK_ID: String = CharacterSprite.PLAYER_ID

@export var move_speed: float = 96.0

var _path: PackedVector2Array = PackedVector2Array()
var _body: CharacterSprite
var _bubble: SpeechBubble


func _ready() -> void:
	_body = CharacterSprite.new()
	add_child(_body)
	_body.setup(LOOK_ID)
	_bubble = SpeechBubble.new()
	add_child(_bubble)


func walk_path(path: PackedVector2Array) -> void:
	_path = path
	# The first point is the centre of the current cell; skip it when already heading past it.
	if _path.size() > 1 and global_position.distance_to(_path[1]) <= _path[0].distance_to(_path[1]):
		_path.remove_at(0)
	if _path.is_empty():
		_body.set_walking(false)


func face(direction: Vector2) -> void:
	_body.face(direction)


func say(text: String, duration: float = 3.2) -> void:
	if not text.is_empty():
		_bubble.say(text, duration)


func is_talking() -> bool:
	return _bubble.is_talking()


func get_remaining_path() -> PackedVector2Array:
	return _path


func is_walking() -> bool:
	return not _path.is_empty()


func _process(delta: float) -> void:
	if _path.is_empty():
		return
	var to_target: Vector2 = _path[0] - global_position
	var step: float = move_speed * delta
	if to_target.length() <= step:
		global_position = _path[0]
		_path.remove_at(0)
		if _path.is_empty():
			_body.set_walking(false)
			arrived.emit()
			return
		to_target = _path[0] - global_position
	else:
		global_position += to_target.normalized() * step
	_body.set_walking(true, to_target)
