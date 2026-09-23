class_name BackendAccount
extends Node
## Server API about the player's own account (Backend.account): the profile page with the
## attendance calendar and history, the status and the avatar.

var _backend: BackendService
var _impl: MockAccount
var _avatar_cache: Dictionary[String, Texture2D] = {}


func _init(backend: BackendService, impl: MockAccount) -> void:
	name = "Account"
	_backend = backend
	_impl = impl


func get_profile_page() -> BackendModels.ProfilePage:
	await _backend.latency()
	_backend.get_mock().tick()
	var page: BackendModels.ProfilePage = _impl.get_profile_page()
	_backend.refresh_profile()
	return page


func set_status(text: String) -> BackendModels.ActionResult:
	await _backend.latency()
	return _after(_impl.set_status(text))


func set_avatar(avatar_id: String) -> BackendModels.ActionResult:
	await _backend.latency()
	return _after(_impl.set_avatar(avatar_id))


## Uploads a picture from the gallery: cropped to a square and scaled down on the phone first.
func upload_avatar(image: Image) -> BackendModels.ActionResult:
	await _backend.latency()
	var result: BackendModels.ActionResult = _impl.upload_avatar(AvatarCatalog.prepare_upload(image))
	if result.ok:
		_avatar_cache.erase(_backend.get_user_id())
	return _after(result)


## Uploaded picture of a player, or null when they use a template.
func get_custom_avatar(user_id: String) -> Texture2D:
	if _avatar_cache.has(user_id):
		return _avatar_cache[user_id]
	var png: PackedByteArray = _impl.get_avatar_png(user_id)
	var texture: Texture2D = null
	if not png.is_empty():
		var image: Image = Image.new()
		if image.load_png_from_buffer(png) == OK:
			texture = ImageTexture.create_from_image(image)
	_avatar_cache[user_id] = texture
	return texture


func _after(result: BackendModels.ActionResult) -> BackendModels.ActionResult:
	if result.ok:
		_backend.refresh_profile()
	return result
