extends WorldScene
## Office gameplay: tap-to-move, NPC conversations, task markers with minigames and the reward shop.
## Once every task is completed or skipped, the player can go home through the entrance.
## "QR" scans a room door code (the character walks to that room), the office screen code
## (starts the check-in) or a colleague's profile code.

const TALK_DISTANCE: float = 40.0
## NPCs can be talked to from this many cells away, e.g. across the reception desk.
const TALK_REACH_CELLS: int = 2
const NPC_SCRIPT: GDScript = preload("res://scripts/npc/npc.gd")
const EVENING_SCENE: String = "res://scenes/intro/evening_outro.tscn"
const FADE_TIME: float = 0.5
## The player fades out over this time while stepping through the entrance.
const EXIT_FADE: float = 0.45
## The walk to the exit can cross the whole floor, so the player hurries.
const EXIT_SPEED_FACTOR: float = 1.8
## Task minigame that reads the office screen code.
const CHECK_IN_MINIGAME: String = "presence_qr"

var _pending_npc: Npc
var _pending_task: BackendModels.TaskInfo
var _talking: bool = false
var _busy: bool = false
var _leaving: bool = false
var _dialogues: DialogueRepository = DialogueRepository.new()
var _tasks: Array[BackendModels.TaskInfo] = []
var _pins: Dictionary[String, TaskPin] = {}
var _home_button: Button
## Room reached physically while a modal was open; the character walks there once it closes.
var _pending_room: StringName = &""

@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _task_panel: TaskPanel = $TaskPanel
@onready var _shop_panel: ShopPanel = $ShopPanel
@onready var _minigame_panel: MinigamePanel = $MinigamePanel
@onready var _choice: ChoicePrompt = $ChoicePrompt
@onready var _fade: ColorRect = $Fade/Rect


func _ready() -> void:
	_setup_world(OfficeLayout.new())
	for definition: NpcRoster.Definition in NpcRoster.all():
		var npc: Npc = NPC_SCRIPT.new()
		_entities.add_child(npc)
		npc.setup(definition, _map)
	_hud.set_title(tr("HUD_TITLE"))
	_hud.set_hint(tr("HUD_HINT"))
	_hud.add_action(tr("HUD_TASKS"), true).pressed.connect(_open_tasks)
	_hud.add_action(tr("HUD_SCAN"), false).pressed.connect(_scan_code)
	_hud.add_action(tr("HUD_SHOP"), false).pressed.connect(_open_shop)
	Presence.zone_changed.connect(_on_zone_changed)
	_task_panel.layout = _map.layout
	_task_panel.go_requested.connect(_go_to_task)
	_task_panel.skip_requested.connect(_skip_task)
	if Backend.profile == null:
		await Backend.login()
	await _refresh_tasks()
	_update_room()


func _process(delta: float) -> void:
	super(delta)
	if _pending_room != &"" and not _is_modal_open():
		var room_id: StringName = _pending_room
		_pending_room = &""
		_walk_to_room(room_id)
	if _pending_npc != null and not _talking and _player.global_position.distance_to(_pending_npc.global_position) <= TALK_DISTANCE:
		_talk_to(_pending_npc)


func _is_modal_open() -> bool:
	return (
		_talking or _busy or _leaving or _dialogue.is_open() or _task_panel.is_open() or _shop_panel.is_open()
		or _minigame_panel.is_open() or _choice.is_open()
	)


func _on_tap(world_position: Vector2) -> void:
	_cancel_pending_actions()
	for child: Node in _entities.get_children():
		var npc: Npc = child as Npc
		if npc != null and npc.is_hit(world_position):
			_approach(npc)
			return
	for pin: TaskPin in _pins.values():
		if pin.visible and pin.is_hit(world_position):
			_go_to_task(pin.task)
			return
	_walk_to(world_position)


func _cancel_pending_actions() -> void:
	_pending_npc = null
	_pending_task = null


func _refresh_tasks() -> void:
	_tasks = await Backend.list_tasks()
	for task: BackendModels.TaskInfo in _tasks:
		if not _map.is_walkable(task.spot):
			push_error("Task '%s' spot %s is not walkable" % [task.id, task.spot])
		var pin: TaskPin = _pins.get(task.id)
		if pin == null:
			pin = TaskPin.new()
			_entities.add_child(pin)
			_pins[task.id] = pin
		pin.setup(task, _map.cell_to_world(task.spot))
	_update_go_home()


# --- NPCs ------------------------------------------------------------------------


func _approach(npc: Npc) -> void:
	_pending_npc = npc
	_hud.hide_hint()
	var npc_cell: Vector2i = _map.world_to_cell(npc.global_position)
	if _player.global_position.distance_to(npc.global_position) <= TALK_DISTANCE or WorldScene.chebyshev(_player_cell(), npc_cell) <= 1:
		return
	# Pick the closest reachable cell near the NPC. Cells right next to it are preferred, but a cell
	# two steps away is fine when furniture such as the reception desk is in between.
	var best_path: PackedVector2Array = PackedVector2Array()
	var best_score: int = 1 << 30
	for dy: int in range(-TALK_REACH_CELLS, TALK_REACH_CELLS + 1):
		for dx: int in range(-TALK_REACH_CELLS, TALK_REACH_CELLS + 1):
			var cell: Vector2i = npc_cell + Vector2i(dx, dy)
			if cell == npc_cell or not _map.is_walkable(cell):
				continue
			var path: PackedVector2Array = _map.find_path(_player.global_position, cell)
			if path.is_empty():
				continue
			var score: int = path.size() + 4 * (WorldScene.chebyshev(cell, npc_cell) - 1) + (0 if dx == 0 or dy == 0 else 1)
			if score < best_score:
				best_score = score
				best_path = path
	if best_path.is_empty():
		_pending_npc = null
		_hud.flash_message(tr("HUD_BLOCKED"))
		return
	_player.walk_path(best_path)
	_marker.show_target(best_path[best_path.size() - 1])


func _talk_to(npc: Npc) -> void:
	_pending_npc = null
	_talking = true
	_stop_player()
	_player.face(npc.global_position - _player.global_position)
	npc.begin_talk(_player.global_position)
	_dialogue.open(npc.definition.display_name, npc.definition.id, _dialogues.next_conversation(npc.definition.id))
	await _dialogue.finished
	npc.end_talk()
	_talking = false


func _on_player_arrived() -> void:
	super()
	if _pending_npc != null and not _talking:
		var npc_cell: Vector2i = _map.world_to_cell(_pending_npc.global_position)
		if WorldScene.chebyshev(_player_cell(), npc_cell) <= TALK_REACH_CELLS:
			_talk_to(_pending_npc)
		else:
			_pending_npc = null
	if _pending_task != null:
		var task: BackendModels.TaskInfo = _pending_task
		_pending_task = null
		if _player_cell() == task.spot:
			_start_task(task)


# --- Tasks and shop --------------------------------------------------------------


func _open_tasks() -> void:
	if _is_modal_open():
		return
	_busy = true
	await _refresh_tasks()
	_busy = false
	_task_panel.open(_tasks, _player_cell(), Backend.profile)


func _open_shop() -> void:
	if _is_modal_open():
		return
	_shop_panel.open()


func _go_to_task(task: BackendModels.TaskInfo) -> void:
	_task_panel.close_panel()
	_pending_npc = null
	if task.completed:
		_hud.flash_message(tr("ERROR_ALREADY_COMPLETED"))
		return
	if task.skipped:
		_hud.flash_message(tr("ERROR_TASK_SKIPPED"))
		return
	if _player_cell() == task.spot:
		_stop_player()
		_start_task(task)
		return
	if _walk_to_cell(task.spot):
		_pending_task = task


func _start_task(task: BackendModels.TaskInfo) -> void:
	_player.face(Vector2.UP)
	_busy = true
	var outcome: MinigamePanel.Outcome = await _minigame_panel.run(task)
	_busy = false
	if outcome == MinigamePanel.Outcome.UNAVAILABLE:
		_hud.flash_message(tr("MG_UNAVAILABLE"))
		return
	if outcome == MinigamePanel.Outcome.SKIPPED:
		await _skip_task(task)
		return
	if outcome != MinigamePanel.Outcome.SUCCESS:
		return
	_busy = true
	var result: BackendModels.TaskResult = await Backend.complete_task(task.id, true, _minigame_panel.last_proof)
	_busy = false
	if result.ok:
		_hud.play_reward(get_canvas_transform() * _player.global_position, result.reward)
		_hud.flash_message(tr("TASK_REWARD") % result.reward)
		_camera.shake(3.0)
	else:
		_hud.flash_message(tr("ERROR_" + result.error.to_upper()))
	await _refresh_tasks()


## Asks for confirmation, then lets the server close the task for today without a reward.
func _skip_task(task: BackendModels.TaskInfo) -> void:
	_task_panel.close_panel()
	if not task.skippable or task.is_closed() or _choice.is_open():
		return
	if not await _choice.ask(tr("TASK_SKIP_QUESTION"), tr("TASK_SKIP_CONFIRM"), tr("TASK_SKIP_CANCEL")):
		return
	_busy = true
	var result: BackendModels.ActionResult = await Backend.skip_task(task.id)
	_busy = false
	_hud.flash_message(tr("TASK_SKIP_DONE") if result.ok else tr("ERROR_" + result.error.to_upper()))
	await _refresh_tasks()


# --- QR codes and rooms ---------------------------------------------------------


func _scan_code() -> void:
	if _is_modal_open():
		return
	_cancel_pending_actions()
	_busy = true
	var payload: QrPayload = await _minigame_panel.scan_code()
	_busy = false
	if payload == null:
		return
	match payload.kind:
		QrPayload.Kind.ROOM:
			if _map.layout.find_room(StringName(payload.value)) == null:
				_hud.flash_message(tr("QR_UNKNOWN_ROOM"))
				return
			Presence.set_zone_from_qr(StringName(payload.value))
			_walk_to_room(StringName(payload.value))
		QrPayload.Kind.PRESENCE:
			_start_check_in()
		QrPayload.Kind.USER:
			_hud.flash_message(tr("QR_COLLEAGUE_HINT"))


## The office screen code was scanned outside the task: walk to the check-in task and start it.
func _start_check_in() -> void:
	for task: BackendModels.TaskInfo in _tasks:
		if task.minigame == CHECK_IN_MINIGAME and not task.is_closed():
			_go_to_task(task)
			return
	_hud.flash_message(tr("QR_ALREADY_CHECKED_IN"))


func _on_zone_changed(room_id: StringName) -> void:
	if _is_modal_open():
		_pending_room = room_id


## The character walks to the walkable cell closest to the room centre.
func _walk_to_room(room_id: StringName) -> void:
	var room: MapLayout.Room = _map.layout.find_room(room_id)
	if room == null:
		return
	var current: MapLayout.Room = _map.get_room_at(_player_cell())
	if current != null and current.id == room_id:
		return
	var floor_rect: Rect2i = room.floor_rect()
	var center: Vector2 = _map.cell_to_world(floor_rect.position + floor_rect.size / 2)
	var cell: Vector2i = _map.find_nearest_walkable(center, maxi(floor_rect.size.x, floor_rect.size.y))
	if cell == WorldMap.INVALID_CELL:
		return
	_hud.flash_message(tr("QR_GOING_TO_ROOM") % tr(room.name_key))
	_walk_to_cell(cell)


# --- End of the day --------------------------------------------------------------


func _update_go_home() -> void:
	if _home_button != null or _tasks.is_empty():
		return
	if not _tasks.all(func(task: BackendModels.TaskInfo) -> bool: return task.is_closed()):
		return
	_home_button = _hud.add_wide_action(tr("HUD_GO_HOME"))
	_home_button.pressed.connect(_go_home)
	_hud.flash_message(tr("HUD_ALL_DONE"))


## Walks the player out through the entrance, then plays the evening cutscene.
func _go_home() -> void:
	if _is_modal_open():
		return
	_leaving = true
	_end_drag()
	_cancel_pending_actions()
	_marker.hide_marker()
	_home_button.visible = false
	_hud.hide_hint()
	_player.say(tr("HUD_GO_HOME_REMARK"))
	var path: PackedVector2Array = _exit_path()
	if not path.is_empty():
		_player.move_speed *= EXIT_SPEED_FACTOR
		_player.walk_path(path)
		var length: float = 0.0
		for i: int in range(1, path.size()):
			length += path[i - 1].distance_to(path[i])
		length += _player.global_position.distance_to(path[0])
		var fade_out: Tween = create_tween()
		fade_out.tween_interval(maxf(0.0, length / _player.move_speed - EXIT_FADE))
		fade_out.tween_property(_player, "modulate:a", 0.0, EXIT_FADE)
		await _player.arrived
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	get_tree().change_scene_to_file(EVENING_SCENE)


## Path to the floor cell in front of the entrance and on through the glass doors.
func _exit_path() -> PackedVector2Array:
	var layout: MapLayout = _map.layout
	if layout.entrances.is_empty():
		return PackedVector2Array()
	var entrance: Rect2i = layout.entrances[0]
	var tile: float = MapLayout.TILE_SIZE
	var doorway: Vector2 = _map.to_global(Vector2(entrance.position.x + entrance.size.x / 2.0, entrance.position.y + 0.5) * tile)
	var inside: Vector2i = _map.find_nearest_walkable(doorway + Vector2(0, -tile), 1)
	if inside == WorldMap.INVALID_CELL:
		return PackedVector2Array()
	var path: PackedVector2Array = _map.find_path(_player.global_position, inside)
	if path.is_empty():
		return path
	path.append(Vector2(doorway.x, _map.cell_to_world(inside).y))
	path.append(doorway)
	path.append(doorway + Vector2(0, tile))
	return path
