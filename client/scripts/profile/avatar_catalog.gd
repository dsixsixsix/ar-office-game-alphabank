class_name AvatarCatalog
extends RefCounted
## Ready-made profile pictures (portraits of the game's characters, like Steam's avatar gallery) and
## the rules for an uploaded picture. "me" is the player's own character in the current outfit.

const DEFAULT: String = "me"
const CUSTOM: String = "custom"
## Uploaded pictures are cropped to a square and scaled to this size before upload.
const CUSTOM_SIZE: int = 64
const TEMPLATES: Array[String] = [
	"me", "anna", "sergey", "olga", "igor", "reception", "masha", "timur", "vera", "kostya", "fox", "raccoon", "deer", "cat",
]
const BACKGROUNDS: Array[Color] = [
	Color("#ef3124"), Color("#2fb3a6"), Color("#3a7bd5"), Color("#9b3fd1"), Color("#e89a10"), Color("#3f9e4a"), Color("#2b2f38"),
]


## Head-and-shoulders picture of a template; null for unknown ids.
static func template_texture(avatar_id: String) -> Texture2D:
	if avatar_id == DEFAULT:
		return CharacterSprite.portrait_texture(CharacterSprite.PLAYER_ID)
	if TEMPLATES.has(avatar_id):
		return CharacterSprite.portrait_texture(avatar_id)
	return null


static func background(avatar_id: String) -> Color:
	return BACKGROUNDS[absi(hash(avatar_id)) % BACKGROUNDS.size()]


## Centre square of any picture, scaled down to CUSTOM_SIZE, as PNG bytes ready for upload.
static func prepare_upload(image: Image) -> PackedByteArray:
	var picture: Image = image.duplicate() as Image
	picture.convert(Image.FORMAT_RGBA8)
	var side: int = mini(picture.get_width(), picture.get_height())
	@warning_ignore("integer_division")
	var square: Image = picture.get_region(Rect2i((picture.get_width() - side) / 2, (picture.get_height() - side) / 2, side, side))
	square.resize(CUSTOM_SIZE, CUSTOM_SIZE, Image.INTERPOLATE_LANCZOS)
	return square.save_png_to_buffer()
