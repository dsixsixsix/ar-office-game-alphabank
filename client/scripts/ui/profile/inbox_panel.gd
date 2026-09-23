class_name InboxPanel
extends ModalPanel
## In-game notifications from the server: fines, a lost streak, photo confirmations and draw results.
## A colleague's joint photo is confirmed or declined right here.

const KIND_COLORS: Dictionary[String, Color] = {
	"penalty": UiStyle.RED,
	"streak_reset": UiStyle.HARD,
	"photo_request": Color("#3a7bd5"),
	"photo_confirmed": Color("#3f9e4a"),
	"photo_declined": UiStyle.MUTED,
	"raffle_win": UiStyle.GOLD,
	"raffle_lost": UiStyle.MUTED,
}

var _busy: bool = false


func _init() -> void:
	super("INBOX_TITLE")


func open() -> void:
	show_panel()
	await _reload()
	await Backend.social.mark_inbox_read()
	Notifications.poll()


func _reload() -> void:
	var items: Array[BackendModels.InboxItem] = await Backend.social.get_inbox()
	clear()
	if items.is_empty():
		content.add_child(make_text(tr("INBOX_EMPTY"), 11, UiStyle.MUTED))
	for item: BackendModels.InboxItem in items:
		content.add_child(_make_item(item))


func _make_item(item: BackendModels.InboxItem) -> Control:
	var card: PanelContainer = make_card(UiStyle.SHADE if item.read else Color("#fff3ea"), KIND_COLORS.get(item.kind, UiStyle.MUTED))
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	var avatar_id: String = str(item.params.get("avatar", ""))
	var text_width: float = content_width - 20.0
	if not avatar_id.is_empty():
		var avatar: AvatarView = AvatarView.new(28.0)
		avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(avatar)
		avatar.show_avatar(avatar_id)
		text_width -= 34.0
	row.add_child(make_text(NotificationTexts.inbox_text(item), 11, UiStyle.INK, text_width))
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	var stamp: Label = UiStyle.make_label(WorkCalendar.stamp(item.created_at), 8, UiStyle.MUTED)
	stamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(stamp)
	if item.needs_answer():
		var decline: Button = UiStyle.make_button(tr("INBOX_PHOTO_DECLINE"), false, 10)
		decline.custom_minimum_size = Vector2(0, 26)
		decline.pressed.connect(_answer.bind(item, false))
		footer.add_child(decline)
		var confirm: Button = UiStyle.make_button(tr("INBOX_PHOTO_CONFIRM"), true, 10)
		confirm.custom_minimum_size = Vector2(0, 26)
		confirm.pressed.connect(_answer.bind(item, true))
		footer.add_child(confirm)
	elif item.kind == "photo_request":
		footer.add_child(UiStyle.make_label(tr("INBOX_STATE_" + item.state.to_upper()), 9, UiStyle.MUTED))
	return card


func _answer(item: BackendModels.InboxItem, confirm: bool) -> void:
	if _busy:
		return
	_busy = true
	var result: BackendModels.ActionResult = await Backend.social.respond_photo_request(item.id, confirm)
	_busy = false
	if not result.ok:
		content.add_child(make_text(tr("ERROR_" + result.error.to_upper()), 10, UiStyle.RED))
		return
	await _reload()
	Notifications.poll()
