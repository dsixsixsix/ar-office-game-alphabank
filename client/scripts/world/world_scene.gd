class_name WorldScene
extends Node2D
## Shared tap-to-move gameplay on a 3/4 map: player, camera, path line, tap marker and HUD.
## A tap walks to the point; holding and dragging steers the player after the finger continuously.
## Expects children WorldMap, PathLine, TapMarker, Entities/Player, GameCamera, Hud and CrtOverlay.

const SNAP_RADIUS_CELLS: int = 2
const CAMERA_MARGIN: float = 48.0
const PATH_LINE_COLOR: Color = Color(0.94, 0.19, 0.14, 0.55)
## Finger travel in viewport pixels that turns a tap into a drag.
const DRAG_THRESHOLD: float = 12.0
## Minimum time between path updates while dragging.
const DRAG_REPATH_INTERVAL: float = 0.1

var _current_room_id: StringName = &""
var _touch_down: bool = false
var _dragging: bool = false
var _touch_start: Vector2 = Vector2.ZERO
var _touch_position: Vector2 = Vector2.ZERO
var _drag_cell: Vector2i = WorldMap.INVALID_CELL
var _repath_left: float = 0.0

@onready var _map: WorldMap = $WorldMap
@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _camera: GameCamera = $GameCamera
@onready var _path_line: Line2D = $PathLine
@onready var _marker: TapMarker = $TapMarker
@onready var _hud: Hud = $Hud
@onready var _crt: CanvasLayer = $CrtOverlay


func _setup_world(layout: MapLayout) -> void:
	_map.build(layout)
	_player.global_position = _map.cell_to_world(layout.spawn_cell)
	_player.arrived.connect(_on_player_arrived)
	_camera.set_bounds(_map.get_bounds(), CAMERA_MARGIN)
	_camera.snap_to_target()
	_path_line.default_color = PATH_LINE_COLOR
	_map.populate_props(_entities)


func _unhandled_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.index == 0:
		if touch.pressed:
			if not _is_ui_blocking():
				_touch_down = true
				_dragging = false
				_touch_start = touch.position
				_touch_position = touch.position
				_on_tap(_screen_to_world(touch.position))
				# The tap may have opened a panel; the rest of this touch belongs to it.
				_touch_down = not _is_modal_open()
		else:
			_end_drag()
		get_viewport().set_input_as_handled()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == 0 and _touch_down:
		_touch_position = drag.position
		if not _dragging and _touch_position.distance_to(_touch_start) >= DRAG_THRESHOLD:
			_begin_drag()
		get_viewport().set_input_as_handled()
		return
	var key: InputEventKey = event as InputEventKey
	if OS.is_debug_build() and key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		_crt.visible = not _crt.visible


func _process(delta: float) -> void:
	_update_drag(delta)
	_update_path_line()
	_update_room()


## Overridden by scenes with modal UI; input to the map is ignored while it returns true.
func _is_modal_open() -> bool:
	return false


func _is_ui_blocking() -> bool:
	return _is_modal_open() or get_viewport().gui_get_hovered_control() != null


func _on_tap(world_position: Vector2) -> void:
	_walk_to(world_position)


## Overridden by scenes that queue an action on arrival (talk, use an object); a drag cancels it.
func _cancel_pending_actions() -> void:
	pass


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _begin_drag() -> void:
	_dragging = true
	_drag_cell = WorldMap.INVALID_CELL
	_repath_left = 0.0
	_cancel_pending_actions()
	_marker.hide_marker()
	_hud.hide_hint()


func _end_drag() -> void:
	_touch_down = false
	_dragging = false
	_drag_cell = WorldMap.INVALID_CELL


## While the finger is held, the player keeps walking towards the point under it. The camera follows
## the player, so a finger resting ahead of the character keeps it moving.
func _update_drag(delta: float) -> void:
	if not _dragging:
		return
	if _is_modal_open():
		_end_drag()
		return
	_repath_left -= delta
	if _repath_left > 0.0:
		return
	var cell: Vector2i = _map.find_nearest_walkable(_screen_to_world(_touch_position), SNAP_RADIUS_CELLS)
	if cell == WorldMap.INVALID_CELL:
		return
	if cell == _drag_cell and (_player.is_walking() or _player_cell() == cell):
		return
	var path: PackedVector2Array = _map.find_path(_player.global_position, cell)
	if path.is_empty():
		return
	_player.walk_path(path)
	_drag_cell = cell
	_repath_left = DRAG_REPATH_INTERVAL


func _walk_to(world_position: Vector2) -> bool:
	var target_cell: Vector2i = _map.find_nearest_walkable(world_position, SNAP_RADIUS_CELLS)
	if target_cell == WorldMap.INVALID_CELL:
		_show_blocked(world_position)
		return false
	return _walk_to_cell(target_cell, world_position)


func _walk_to_cell(cell: Vector2i, tapped_position: Vector2 = Vector2.INF) -> bool:
	var path: PackedVector2Array = _map.find_path(_player.global_position, cell)
	if path.is_empty():
		_show_blocked(tapped_position if tapped_position != Vector2.INF else _map.cell_to_world(cell))
		return false
	_player.walk_path(path)
	_marker.show_target(_map.cell_to_world(cell))
	_camera.shake(1.0)
	_hud.hide_hint()
	return true


func _show_blocked(world_position: Vector2) -> void:
	_marker.show_blocked(world_position)
	_camera.shake(2.0)
	_hud.flash_message(tr("HUD_BLOCKED"))


func _player_cell() -> Vector2i:
	return _map.world_to_cell(_player.global_position)


func _stop_player() -> void:
	_player.walk_path(PackedVector2Array())
	_marker.hide_marker()


func _on_player_arrived() -> void:
	_marker.hide_marker()


func _update_path_line() -> void:
	var remaining: PackedVector2Array = _player.get_remaining_path()
	if remaining.is_empty():
		_path_line.clear_points()
		return
	var points: PackedVector2Array = PackedVector2Array([_player.global_position])
	points.append_array(remaining)
	_path_line.points = points


func _update_room() -> void:
	var room: MapLayout.Room = _map.get_room_at(_player_cell())
	if room == null or room.id == _current_room_id:
		return
	_current_room_id = room.id
	_hud.show_room(tr(room.name_key))


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
