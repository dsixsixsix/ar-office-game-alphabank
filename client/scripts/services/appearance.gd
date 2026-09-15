extends Node
## Player appearance (autoload "Appearance"). Keeps the outfit confirmed by Backend and paints the
## player's sprite sheet from it on demand.

signal changed

var outfit: Dictionary = Outfit.default_outfit()

var _sheet: ImageTexture
var _outfit_key: String = ""


func _ready() -> void:
	Backend.outfit_changed.connect(set_outfit)


func set_outfit(new_outfit: Dictionary) -> void:
	var new_key: String = Outfit.key(new_outfit)
	if new_key == _outfit_key and _sheet != null:
		return
	outfit = Outfit.normalized(new_outfit)
	_outfit_key = new_key
	_sheet = null
	changed.emit()


func get_sheet() -> Texture2D:
	if _sheet == null:
		_sheet = ImageTexture.create_from_image(paint_sheet(outfit))
		_outfit_key = Outfit.key(outfit)
	return _sheet


func get_skin_color() -> Color:
	return Palette.SKIN_TONES[clampi(int(outfit["skin"]), 0, Palette.SKIN_TONES.size() - 1)]


static func paint_sheet(p_outfit: Dictionary) -> Image:
	var canvas: PixelCanvas = PixelCanvas.create(CharacterPainter.sheet_size())
	CharacterPainter.new(Outfit.to_look(p_outfit)).paint_sheet(canvas)
	return canvas.image


## One 48x64 frame, e.g. for wardrobe thumbnails and the preview.
static func paint_frame(p_outfit: Dictionary, direction: int, column: int = 0) -> Image:
	var canvas: PixelCanvas = PixelCanvas.create(CharacterPainter.FRAME)
	CharacterPainter.new(Outfit.to_look(p_outfit)).paint_frame(canvas, direction, column)
	return canvas.image
