extends WorldScene
## The player's apartment after breakfast: walk around, hear remarks near objects, change the outfit
## in the wardrobe, pick a car by the key hook and leave for the office from the laptop or the door.

const COMMUTE_SCENE: String = "res://scenes/intro/commute_intro.tscn"
const REMARKS_PATH: String = "res://data/home_remarks.json"
const REMARK_COOLDOWN: float = 9.0
const LAPTOP_LINES: int = 2
const FADE_TIME: float = 0.4

var _remarks: Dictionary = {}
var _cooldowns: Dictionary[String, float] = {}
var _pending_use: HomeLayout.Interactable
var _near_id: String = ""
var _busy: bool = false
var _leaving: bool = false

@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _wardrobe: WardrobePanel = $WardrobePanel
@onready var _shop_panel: ShopPanel = $ShopPanel
@onready var _choice: ChoicePrompt = $ChoicePrompt
@onready var _fade: ColorRect = $Fade/Rect


func _ready() -> void:
	var layout: HomeLayout = HomeLayout.new()
	_setup_world(layout)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REMARKS_PATH))
	_remarks = parsed if parsed is Dictionary else {}
	for use: HomeLayout.Interactable in layout.interactables:
		_cooldowns[use.id] = 0.0
		if not _remarks.has(use.id):
			push_warning("No home remarks for '%s'" % use.id)
	# The player starts next to the breakfast table.
	_cooldowns["table"] = REMARK_COOLDOWN
	_hud.set_title(tr("HUD_HOME_TITLE"))
	_hud.set_hint(tr("HUD_HOME_HINT"))
	_player.face(Vector2.UP)
	_fade.color.a = 1.0
	if Backend.profile == null:
		await Backend.login()
	_update_room()
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await tween.finished
	_player.say(_pick("greeting"))


func _process(delta: float) -> void:
	super(delta)
	for id: String in _cooldowns:
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
	_check_proximity()


func _is_modal_open() -> bool:
	return _busy or _leaving or _dialogue.is_open() or _wardrobe.is_open() or _shop_panel.is_open() or _choice.is_open()


func _on_tap(world_position: Vector2) -> void:
	_pending_use = null
	var use: HomeLayout.Interactable = _find_interactable_at(world_position)
	if use == null:
		_walk_to(world_position)
		return
	if _player_cell() == use.stand_cell:
		_stop_player()
		_use(use)
	elif _walk_to_cell(use.stand_cell):
		_pending_use = use


func _cancel_pending_actions() -> void:
	_pending_use = null


func _on_player_arrived() -> void:
	super()
	if _pending_use != null and _player_cell() == _pending_use.stand_cell:
		var use: HomeLayout.Interactable = _pending_use
		_pending_use = null
		_use(use)


## Remarks when the player steps onto an object's spot, at most once per cooldown.
func _check_proximity() -> void:
	if _is_modal_open():
		return
	var cell: Vector2i = _player_cell()
	var near: HomeLayout.Interactable = null
	for use: HomeLayout.Interactable in (_map.layout as HomeLayout).interactables:
		if use.stand_cell == cell:
			near = use
			break
	var near_id: String = near.id if near != null else ""
	if near != null and near_id != _near_id and _pending_use != near and _cooldowns.get(near_id, 0.0) <= 0.0 and not _player.is_talking():
		_player.say(_pick(near_id))
		_cooldowns[near_id] = REMARK_COOLDOWN
	_near_id = near_id


## Front-most object sprite under the tap.
func _find_interactable_at(world_position: Vector2) -> HomeLayout.Interactable:
	var best: HomeLayout.Interactable = null
	var best_bottom: float = -INF
	for use: HomeLayout.Interactable in (_map.layout as HomeLayout).interactables:
		var rect: Rect2 = _map.get_prop_rect(use.prop_id, use.prop_cell)
		if rect.has_area() and rect.has_point(world_position) and rect.end.y > best_bottom:
			best = use
			best_bottom = rect.end.y
	return best


func _use(use: HomeLayout.Interactable) -> void:
	var target: Vector2 = _map.cell_to_world(use.prop_cell)
	_player.face(target - _player.global_position if target.distance_to(_player.global_position) > 1.0 else Vector2.UP)
	_cooldowns[use.id] = REMARK_COOLDOWN
	_near_id = use.id
	match use.kind:
		HomeLayout.Kind.REMARK:
			_player.say(_pick(use.id))
		HomeLayout.Kind.WARDROBE:
			_busy = true
			_wardrobe.open()
			await _wardrobe.closed
			_busy = false
			_player.say(_pick("mirror"))
		HomeLayout.Kind.GARAGE:
			_player.say(_pick("keys"))
			_shop_panel.open(ShopPanel.Tab.GARAGE)
		HomeLayout.Kind.LAPTOP:
			await _use_laptop()
		HomeLayout.Kind.DOOR:
			_player.say(_pick("door"))
			if await _choice.ask(tr("HOME_DOOR_QUESTION"), tr("CHOICE_GO_OFFICE"), tr("CHOICE_STAY")):
				_leave()


func _use_laptop() -> void:
	_busy = true
	var pool: Array = (_remarks.get("laptop", []) as Array).duplicate()
	pool.shuffle()
	var lines: Array[DialogueRepository.Line] = []
	for i: int in mini(LAPTOP_LINES, pool.size()):
		lines.append(DialogueRepository.Line.new(true, str(pool[i])))
	_dialogue.open("", "", lines)
	await _dialogue.finished
	_busy = false
	if await _choice.ask(tr("HOME_LAPTOP_QUESTION"), tr("CHOICE_GO_OFFICE"), tr("CHOICE_STAY")):
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_stop_player()
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	get_tree().change_scene_to_file(COMMUTE_SCENE)


func _pick(id: String) -> String:
	var lines: Array = _remarks.get(id, [])
	return str(lines.pick_random()) if not lines.is_empty() else ""
