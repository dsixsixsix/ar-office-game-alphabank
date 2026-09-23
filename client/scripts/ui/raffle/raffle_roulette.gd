class_name RaffleRoulette
extends CanvasLayer
## The draw replay: a strip of entrant cards spins under a marker, slows down and stops on the
## winner the server already picked. The animation only shows the result; it does not decide it.

signal finished

const CARD_WIDTH: float = 56.0
const CARD_GAP: float = 4.0
const STRIP_HEIGHT: float = 78.0
const CARDS_BEFORE_WINNER: int = 34
const SPIN_TIME: float = 6.5
const BACKDROP: Color = Color(0.06, 0.05, 0.08, 0.92)

var _strip: Control
var _cards: HBoxContainer
var _title: Label
var _result: Label
var _close: Button
var _state: BackendModels.RaffleState
var _flash: float = 0.0


func _init() -> void:
	layer = 35


func play(state: BackendModels.RaffleState) -> void:
	_state = state
	_build()
	if state.entrants.is_empty():
		_result.text = tr("RAFFLE_NO_ENTRANTS")
		_close.visible = true
		return
	var winner_index: int = _fill_cards()
	await get_tree().process_frame
	var step: float = CARD_WIDTH + CARD_GAP
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(state.draw_id)
	var jitter: float = rng.randf_range(-CARD_WIDTH * 0.35, CARD_WIDTH * 0.35)
	var target: float = _strip.size.x / 2.0 - (winner_index * step + CARD_WIDTH / 2.0) + jitter
	_cards.position.x = _strip.size.x / 2.0 - CARD_WIDTH / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_cards, "position:x", target, SPIN_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	var settle: Tween = create_tween()
	settle.tween_property(_cards, "position:x", target - jitter, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await settle.finished
	_flash = 1.0
	_result.text = tr("RAFFLE_YOU_WON") if state.is_winner else tr("RAFFLE_WINNER") % state.winner_name
	_result.label_settings.font_color = UiStyle.GOLD if state.is_winner else Color.WHITE
	_close.visible = true


## Entrants repeated in a shuffled order long enough to spin, with the winner at a fixed place.
func _fill_cards() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(_state.draw_id + "|strip")
	var winner: BackendModels.RaffleEntrant = null
	for entrant: BackendModels.RaffleEntrant in _state.entrants:
		if entrant.user_id == _state.winner_id:
			winner = entrant
	var sequence: Array[BackendModels.RaffleEntrant] = []
	while sequence.size() < CARDS_BEFORE_WINNER:
		sequence.append(_state.entrants[rng.randi_range(0, _state.entrants.size() - 1)])
	sequence.append(winner if winner != null else _state.entrants[0])
	for i: int in 6:
		sequence.append(_state.entrants[rng.randi_range(0, _state.entrants.size() - 1)])
	for entrant: BackendModels.RaffleEntrant in sequence:
		_cards.add_child(_make_card(entrant))
	return CARDS_BEFORE_WINNER


func _make_card(entrant: BackendModels.RaffleEntrant) -> Control:
	var card: PanelContainer = PanelContainer.new()
	var is_me: bool = entrant.user_id == Backend.get_user_id()
	card.add_theme_stylebox_override("panel", UiStyle.panel(Color("#fff3ea") if is_me else UiStyle.PAPER, 4, 3))
	card.custom_minimum_size = Vector2(CARD_WIDTH, STRIP_HEIGHT - 8.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var avatar: AvatarView = AvatarView.new(CARD_WIDTH - 8.0)
	column.add_child(avatar)
	avatar.show_avatar(entrant.avatar, entrant.user_id)
	var name_label: Label = UiStyle.make_label(entrant.name, 7, UiStyle.RED if is_me else UiStyle.INK)
	name_label.clip_text = true
	name_label.custom_minimum_size = Vector2(CARD_WIDTH - 8.0, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	return card


func _build() -> void:
	var safe: Rect2 = PlatformServices.get_safe_rect()
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.position = Vector2(safe.position.x, safe.position.y + safe.size.y * 0.22)
	column.size = Vector2(safe.size.x, 0)
	root.add_child(column)
	_title = UiStyle.make_label(tr("RAFFLE_ROULETTE_TITLE"), 14, Color.WHITE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	var prize: Label = UiStyle.make_label(_state.prize_name, 10, UiStyle.GOLD)
	prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prize)
	_strip = Control.new()
	_strip.custom_minimum_size = Vector2(safe.size.x, STRIP_HEIGHT)
	_strip.clip_contents = true
	_strip.draw.connect(_draw_strip)
	column.add_child(_strip)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", int(CARD_GAP))
	_cards.position = Vector2(0, 4)
	_strip.add_child(_cards)
	var marker: Control = Control.new()
	marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.draw.connect(_draw_marker.bind(marker))
	_strip.add_child(marker)
	_result = UiStyle.make_label("", 16, Color.WHITE)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size = Vector2(safe.size.x - 24.0, 0)
	column.add_child(_result)
	_close = UiStyle.make_button(tr("RAFFLE_CLOSE"), true, 12)
	_close.custom_minimum_size = Vector2(140, 34)
	_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close.visible = false
	_close.pressed.connect(func() -> void:
		finished.emit()
		queue_free()
	)
	column.add_child(_close)


func _draw_strip() -> void:
	_strip.draw_rect(Rect2(Vector2.ZERO, _strip.size), Color(1, 1, 1, 0.06))


func _draw_marker(marker: Control) -> void:
	var x: float = roundf(marker.size.x / 2.0)
	var glow: Color = UiStyle.GOLD.lerp(Color.WHITE, _flash)
	marker.draw_rect(Rect2(x - 1, 0, 2, marker.size.y), glow)
	marker.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x, 7)]), glow)
	marker.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, marker.size.y), Vector2(x + 6, marker.size.y), Vector2(x, marker.size.y - 7)]), glow)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 0.8)
	if _strip != null:
		_strip.queue_redraw()
		for child: Node in _strip.get_children():
			if child != _cards:
				(child as CanvasItem).queue_redraw()
