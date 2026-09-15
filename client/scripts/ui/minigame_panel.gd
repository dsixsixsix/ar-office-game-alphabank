class_name MinigamePanel
extends CanvasLayer
## Modal host for a task minigame. run() resolves with the outcome once the player finishes, closes
## or skips it. Hard tasks show their difficulty tag; skippable ones get a "Skip" button.

signal _resolved(outcome: Outcome)

enum Outcome { SUCCESS, FAILED, CANCELLED, SKIPPED }

const RESULT_DELAY: float = 0.9

var _panel: PanelContainer
var _title: Label
var _host: Control
var _result: Label
var _close: Button
var _footer: HBoxContainer
var _badge_slot: HBoxContainer
var _skip: Button
var _game: Minigame


func _ready() -> void:
	layer = 30
	visible = false
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(UiStyle.make_dimmer())

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.PAPER, 8, 10))
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	_title = UiStyle.make_label("", 14)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_close = UiStyle.make_button("✕", false, 12)
	_close.pressed.connect(func() -> void: _resolved.emit(Outcome.CANCELLED))
	header.add_child(_close)

	_host = Control.new()
	_host.custom_minimum_size = Minigame.AREA_SIZE
	column.add_child(_host)
	_result = UiStyle.make_label("", 22, UiStyle.RED)
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result.label_settings.outline_size = 6
	_result.label_settings.outline_color = Color.WHITE
	_host.add_child(_result)

	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 6)
	column.add_child(_footer)
	_badge_slot = HBoxContainer.new()
	_badge_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badge_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.add_child(_badge_slot)
	_skip = UiStyle.make_button(tr("TASK_SKIP"), false, 11)
	_skip.custom_minimum_size = Vector2(0, 28)
	_skip.pressed.connect(func() -> void: _resolved.emit(Outcome.SKIPPED))
	_footer.add_child(_skip)


func is_open() -> bool:
	return visible


func run(task: BackendModels.TaskInfo) -> Outcome:
	_title.text = task.title
	_result.visible = false
	_close.disabled = false
	_skip.disabled = false
	for child: Node in _badge_slot.get_children():
		child.queue_free()
	if task.difficulty != "normal":
		var badge: PanelContainer = UiStyle.make_difficulty_badge(task.difficulty, task.difficulty_multiplier)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_badge_slot.add_child(badge)
	_skip.visible = task.skippable
	_footer.visible = task.difficulty != "normal" or task.skippable
	_game = Minigame.create(task.minigame)
	_game.finished.connect(_on_game_finished)
	_host.add_child(_game)
	_host.move_child(_game, 0)
	visible = true
	var outcome: Outcome = await _resolved
	_game.queue_free()
	_game = null
	visible = false
	return outcome


func show_reward(amount: int) -> void:
	_result.text = tr("MG_SUCCESS") % amount


func _on_game_finished(success: bool) -> void:
	_close.disabled = true
	_skip.disabled = true
	_result.visible = true
	_result.text = tr("MG_DONE") if success else tr("MG_FAIL")
	await get_tree().create_timer(RESULT_DELAY).timeout
	_resolved.emit(Outcome.SUCCESS if success else Outcome.FAILED)
