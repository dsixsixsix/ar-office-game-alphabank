class_name CheckInMinigame
extends Minigame
## Screen-only check-in from the first prototype: a button instead of the office QR code.
## Kept as the default minigame for unknown kinds; the server grants nothing without a presence token.


func _ready() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.size = AREA_SIZE
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var hint: Label = UiStyle.make_label(tr("MG_CHECKIN_HINT"), 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var button: Button = UiStyle.make_button(tr("MG_CHECKIN_BUTTON"), true, 14)
	button.pressed.connect(func() -> void: finish(true))
	box.add_child(button)
