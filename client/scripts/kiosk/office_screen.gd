extends Control
## Office screen at the reception: a rotating presence QR code that changes every
## PresenceToken.PERIOD_SECONDS. Run it on a PC or TV: `run.ps1 -OfficeScreen`.
## DEV build: the token is signed locally with the dev secret. With the real server the screen will
## fetch each token from an admin-only RPC so the secret never leaves the server.

const QR_SCALE_FRACTION: float = 0.7
const BACKGROUND: Color = Color("#1d1d1f")
const MARGIN: int = 24
const LOGO_HEIGHT: float = 56.0
const MARK: Texture2D = preload("res://assets/brand/alfa_mark_large.png")

var _step: int = -1
var _margin: MarginContainer
var _code: TextureRect
var _countdown: Label
var _bar: ColorRect


func _ready() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_margin = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(_margin)
	# On a phone the screen has a notch; on a TV the safe rect is the whole screen.
	PlatformServices.safe_rect_changed.connect(_fit_safe_rect)
	_fit_safe_rect(PlatformServices.get_safe_rect())
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	_margin.add_child(column)
	var logo: TextureRect = TextureRect.new()
	logo.texture = MARK
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, LOGO_HEIGHT)
	column.add_child(logo)
	var hint: Label = UiStyle.make_label(tr("OFFICE_SCREEN_HINT"), 14, Color.WHITE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	_code = TextureRect.new()
	_code.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_code.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_code.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_code)
	_bar = ColorRect.new()
	_bar.color = UiStyle.RED
	_bar.custom_minimum_size = Vector2(0, 6)
	column.add_child(_bar)
	_countdown = UiStyle.make_label("", 12, UiStyle.PAPER_EDGE)
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_countdown)


func _fit_safe_rect(rect: Rect2) -> void:
	_margin.position = rect.position
	_margin.size = rect.size


func _process(_delta: float) -> void:
	var now: float = Time.get_unix_time_from_system()
	var step: int = PresenceToken.step_at(now)
	if step != _step:
		_step = step
		var text: String = QrPayload.presence(PresenceToken.generate(DevQrCodes.presence_secret(), DevQrCodes.OFFICE_ID, step))
		# Nearest-neighbour scaling keeps the modules sharp.
		_code.texture = ImageTexture.create_from_image(QrEncoder.encode(text).to_image(8, 4))
	var left: float = PresenceToken.seconds_left(now)
	_countdown.text = tr("OFFICE_SCREEN_REFRESH") % ceili(left)
	_bar.custom_minimum_size.x = _margin.size.x * QR_SCALE_FRACTION * left / PresenceToken.PERIOD_SECONDS
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
