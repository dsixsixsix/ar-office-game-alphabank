extends Node
## Dev check: walks through home, commute intro and office, driving the scenes directly and saving
## screenshots. The mock backend save is restored afterwards.
## Run (GUI): godot --path client res://tools/dev_tour.tscn -- --device=pixel_8 --out=<dir> [--shot-scale=2]
## --shot-scale below 1 shrinks screenshots smoothly, 1 and above enlarges them with crisp pixels.

const SAVE: String = "user://mock_backend.json"
const BACKUP: String = "user://mock_backend.tour_backup.json"

var _out: String = ""
var _shot_scale: float = 0.5


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out = argument.trim_prefix("--out=")
		elif argument.begins_with("--shot-scale="):
			_shot_scale = maxf(0.1, argument.trim_prefix("--shot-scale=").to_float())
	# The emulator's key help would end up in the screenshots.
	var emulator: Node = get_node_or_null("/root/DeviceEmulator")
	if emulator != null and emulator.get("_help") is Label:
		(emulator.get("_help") as Label).visible = false
	# So would the desktop sensor emulator panel; the tour drives the emulated sensors itself.
	var sensor_emulator: CanvasLayer = PlatformServices.get_node("Backend").get("_emulator") as CanvasLayer
	if sensor_emulator != null:
		sensor_emulator.layer = -100
		sensor_emulator.visible = false
	_start.call_deferred()


func _start() -> void:
	# Survive scene changes: move to the root and leave an empty placeholder as the current scene.
	var tree: SceneTree = get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	var placeholder: Node = Node.new()
	tree.root.add_child(placeholder)
	tree.current_scene = placeholder
	if FileAccess.file_exists(SAVE):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	await _wait(0.5)
	await _morning_tour()
	await _home_tour()
	await _commute_tour()
	await _office_tour()
	await _evening_tour()
	await _office_screen_tour()
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	tree.quit()


func _morning_tour() -> void:
	get_tree().change_scene_to_file("res://scenes/intro/morning_intro.tscn")
	await _wait(2.6)
	await _shot("m1_wake")
	await _wait(8.2)
	await _shot("m2_bath")


func _home_tour() -> void:
	get_tree().change_scene_to_file("res://scenes/home/home.tscn")
	await _wait(2.5)
	await _shot("h1_start")
	var home: Node = get_tree().current_scene
	var layout: HomeLayout = (home.get("_map") as WorldMap).layout
	await _teleport(home, _find(layout, "wardrobe").stand_cell)
	await _wait(1.2)
	await _shot("h2_bedroom")
	home.call("_use", _find(layout, "wardrobe"))
	await _wait(1.5)
	await _shot("h3_wardrobe")
	var wardrobe: WardrobePanel = home.get("_wardrobe")
	wardrobe.call("_select_slot", "hat")
	await _wait(0.6)
	await _shot("h4_wardrobe_hats")
	var state: BackendModels.WardrobeState = wardrobe.get("_state")
	var wanted: Array[String] = ["hat:cowboy", "back:angel_wings", "hand:balloon", "top:hawaiian"]
	for item: BackendModels.WardrobeItem in state.items:
		if wanted.has(item.slot + ":" + item.id):
			wardrobe.call("_on_item_pressed", item)
	wardrobe.call("_select_slot", "back")
	await _wait(0.8)
	await _shot("h5_wardrobe_back")
	wardrobe.call("_save_and_close")
	await _wait(1.2)
	await _shot("h6_new_look")
	await _teleport(home, _find(layout, "laptop").stand_cell)
	home.call("_use", _find(layout, "laptop"))
	await _wait(1.6)
	await _shot("h7_laptop")
	var dialogue: DialogueBox = home.get("_dialogue")
	for i: int in 6:
		if dialogue.is_open():
			dialogue.call("_advance")
			await _wait(0.4)
	await _wait(0.8)
	await _shot("h8_laptop_choice")
	(home.get("_choice") as ChoicePrompt).emit_signal("_answered", false)
	await _wait(0.5)
	await _teleport(home, _find(layout, "keys").stand_cell)
	home.call("_use", _find(layout, "keys"))
	await _wait(1.5)
	await _shot("h9_garage")
	(home.get("_shop_panel") as ShopPanel).visible = false
	await _teleport(home, _find(layout, "sink").stand_cell)
	await _wait(1.0)
	await _shot("h10_bathroom_remark")


func _commute_tour() -> void:
	get_tree().change_scene_to_file("res://scenes/intro/commute_intro.tscn")
	await _wait(4.0)
	await _shot("c1_parking_retry")
	await _wait(5.0)
	await _shot("c2_autobahn")
	await _wait(4.4)
	await _shot("c3_traffic")
	await _wait(4.5)
	await _shot("c4_arrival")
	(Backend.get("_impl") as MockBackend).call("_credit", 6000, "dev_tour", "tour")
	var result: BackendModels.PurchaseResult = await Backend.buy_car("audi_rs6")
	if result.status == BackendModels.PurchaseResult.Status.GRANTED:
		await Backend.select_car("audi_rs6")
	get_tree().change_scene_to_file("res://scenes/intro/commute_intro.tscn")
	await _wait(4.2)
	await _shot("c5_rs6_parking")
	await _wait(5.6)
	await _shot("c6_rs6_autobahn")


func _office_tour() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _wait(2.5)
	await _shot("o1_start")
	var office: Node = get_tree().current_scene
	await _teleport(office, Vector2i(24, 23))
	await _wait(1.0)
	await _shot("o2_reception_pins")
	await _drag_check(office)
	for child: Node in (office.get("_entities") as Node).get_children():
		var npc: Npc = child as Npc
		if npc != null and npc.definition.id == "reception":
			office.call("_approach", npc)
	await _wait(3.0)
	await _shot("o3_reception_talk")
	var dialogue: DialogueBox = office.get("_dialogue")
	for i: int in 8:
		if dialogue.is_open():
			dialogue.call("_advance")
			await _wait(0.4)
	await _wait(0.8)
	office.call("_open_tasks")
	await _wait(1.0)
	await _shot("o4_tasks")
	(office.get("_task_panel") as TaskPanel).close_panel()
	await _minigame_tour(office)
	office.call("_open_shop")
	await _wait(1.2)
	await _shot("o6_shop")
	(office.get("_shop_panel") as ShopPanel).visible = false
	office.call("_open_tasks")
	await _wait(1.0)
	await _shot("o8_tasks_difficulty")
	(office.get("_task_panel") as TaskPanel).close_panel()
	# Close every task on the mock server so the "Go home" button appears.
	# Check-in goes first: the server accepts other tasks only after a valid presence token.
	var mock: MockBackend = Backend.get("_impl")
	var token: String = QrPayload.parse(DevQrCodes.current_presence_code()).value
	mock.complete_task("check_in", true, "tour-check-in-%d" % Time.get_ticks_usec(), {"presence_token": token})
	for task: BackendModels.TaskInfo in office.get("_tasks"):
		if task.skippable:
			mock.skip_task(task.id)
		else:
			mock.complete_task(task.id, true, "tour-%s-%d" % [task.id, Time.get_ticks_usec()])
	office.call("_refresh_tasks")
	await _wait(1.0)
	await _teleport(office, Vector2i(24, 23))
	await _shot("o9_go_home_button")
	office.call("_go_home")
	await _wait(1.5)
	await _shot("o10_walking_out")


## Opens every task minigame, feeds the emulated sensors and takes a screenshot of each.
func _minigame_tour(office: Node) -> void:
	var desktop: Node = PlatformServices.get_node("Backend")
	var panel: MinigamePanel = office.get("_minigame_panel")
	var setups: Dictionary[String, Callable] = {
		"carry_coffee": func() -> void: desktop.set("tilt", Vector2(14, -8)),
		"find_object": func() -> void: desktop.set("label_id", OfficeObjects.all_labels()[0]),
		"squats": func() -> void: desktop.set("squat_depth", 0.8),
		"selfie": func() -> void:
			desktop.set("face_count", 2)
			desktop.set("smiling", false),
		"scavenger_hunt": func() -> void: desktop.set("marker_id", 2),
		"stairs": func() -> void: desktop.call("add_steps", 47),
	}
	var index: int = 0
	for task: BackendModels.TaskInfo in office.get("_tasks"):
		index += 1
		await _teleport(office, task.spot)
		office.call("_go_to_task", task)
		await _wait(0.8)
		if setups.has(task.minigame):
			setups[task.minigame].call()
		await _wait(0.9)
		await _shot("g%d_%s" % [index, task.minigame])
		if task.minigame == "tongue_twister":
			var game: Minigame = panel.get("_game")
			game.call("_listen")
			await _wait(0.3)
			desktop.call("emit_speech", "Шла Саша по шоссе")
			await _wait(0.1)
			await _shot("g%d_%s_listening" % [index, task.minigame])
		if panel.is_open():
			panel.emit_signal("_resolved", MinigamePanel.Outcome.CANCELLED)
		desktop.set("tilt", Vector2.ZERO)
		await _wait(0.5)
	office.call("_scan_code")
	await _wait(1.0)
	await _shot("g_scan_qr")
	var scanner: Minigame = panel.get("_game")
	scanner.call("_toggle_profile")
	await _wait(0.4)
	await _shot("g_profile_qr")
	panel.emit_signal("_resolved", MinigamePanel.Outcome.CANCELLED)
	await _wait(0.5)


func _evening_tour() -> void:
	await _wait(3.0)
	await _shot("e1_leave_office")
	await _wait(3.4)
	await _shot("e2_night_city")
	await _wait(4.4)
	await _shot("e3_home_arrival")
	await _wait(5.6)
	await _shot("e4_sleep")
	await _wait(3.0)
	await _shot("e5_lights_out")


## Holds a finger to the left of the player and keeps it there: the player should keep walking left.
## The reception screen with the rotating presence code, normally shown on a TV in the office.
func _office_screen_tour() -> void:
	get_tree().change_scene_to_file("res://scenes/kiosk/office_screen.tscn")
	await _wait(1.2)
	await _shot("k1_office_screen")


func _drag_check(scene: Node) -> void:
	var viewport: Viewport = get_viewport()
	var player: Player = scene.get("_player")
	var start_x: float = player.global_position.x
	var center: Vector2 = viewport.get_visible_rect().size / 2.0
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.pressed = true
	press.position = center + Vector2(-20, 0)
	viewport.push_input(press, true)
	for i: int in 6:
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.position = center + Vector2(-20 - i * 20, 0)
		drag.relative = Vector2(-20, 0)
		viewport.push_input(drag, true)
		await get_tree().process_frame
	await _wait(1.5)
	await _shot("o2b_drag")
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.pressed = false
	release.position = center + Vector2(-120, 0)
	viewport.push_input(release, true)
	print("drag check: player moved %.0f px, still walking=%s" % [player.global_position.x - start_x, player.is_walking()])
	await _wait(1.0)


func _find(layout: HomeLayout, id: String) -> HomeLayout.Interactable:
	for use: HomeLayout.Interactable in layout.interactables:
		if use.id == id:
			return use
	return null


func _teleport(scene: Node, cell: Vector2i) -> void:
	var map: WorldMap = scene.get("_map")
	var player: Player = scene.get("_player")
	player.walk_path(PackedVector2Array())
	player.global_position = map.cell_to_world(cell)
	(scene.get("_camera") as GameCamera).snap_to_target()
	await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image: Image = get_tree().root.get_texture().get_image()
	var interpolation: Image.Interpolation = Image.INTERPOLATE_NEAREST if _shot_scale >= 1.0 else Image.INTERPOLATE_BILINEAR
	image.resize(roundi(image.get_width() * _shot_scale), roundi(image.get_height() * _shot_scale), interpolation)
	image.save_png("%s/t-%s.png" % [_out, shot_name])
	print("shot ", shot_name)
