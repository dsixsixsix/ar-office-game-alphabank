class_name BackendAccount
extends Node
## Server API about the player's own account (Backend.account): the profile page with the
## attendance calendar and history, the status and the avatar. Uploaded pictures of any player are
## fetched once and cached.

## An uploaded picture arrived; views showing that player redraw.
signal custom_avatar_loaded(user_id: String)

var _backend: BackendService
var _avatar_cache: Dictionary[String, Texture2D] = {}
var _avatar_requests: Dictionary[String, bool] = {}


func _init(backend: BackendService) -> void:
	name = "Account"
	_backend = backend


func get_profile_page() -> BackendModels.ProfilePage:
	var response: ServerSession.RpcResult = await _backend.call_rpc("get_profile_page")
	var page: BackendModels.ProfilePage = BackendParser.profile_page(response.data)
	if response.ok:
		_backend.refresh_profile()
	return page


func set_status(text: String) -> BackendModels.ActionResult:
	return _after(await _action("set_status", {"text": text}))


func set_avatar(avatar_id: String) -> BackendModels.ActionResult:
	return _after(await _action("set_avatar", {"avatar_id": avatar_id}))


## Uploads a picture from the gallery: cropped to a square and scaled down on the phone first.
func upload_avatar(image: Image) -> BackendModels.ActionResult:
	var png: PackedByteArray = AvatarCatalog.prepare_upload(image)
	var result: BackendModels.ActionResult = await _action("upload_avatar", {"png": Marshalls.raw_to_base64(png)})
	if result.ok:
		var picture: Image = Image.new()
		if picture.load_png_from_buffer(png) == OK:
			_avatar_cache[_backend.get_user_id()] = ImageTexture.create_from_image(picture)
			custom_avatar_loaded.emit(_backend.get_user_id())
	return _after(result)


## Cached uploaded picture of a player, or null. A miss starts a download and emits
## custom_avatar_loaded when it arrives.
func get_custom_avatar(user_id: String) -> Texture2D:
	if _avatar_cache.has(user_id):
		return _avatar_cache[user_id]
	if not user_id.is_empty() and not _avatar_requests.has(user_id):
		_avatar_requests[user_id] = true
		_download_avatar(user_id)
	return null


func _download_avatar(user_id: String) -> void:
	var response: ServerSession.RpcResult = await _backend.call_rpc("get_avatar", {"user_id": user_id})
	_avatar_requests.erase(user_id)
	var encoded: String = str(response.data.get("png", ""))
	if not response.ok or encoded.is_empty():
		return
	var picture: Image = Image.new()
	if picture.load_png_from_buffer(Marshalls.base64_to_raw(encoded)) != OK:
		return
	_avatar_cache[user_id] = ImageTexture.create_from_image(picture)
	custom_avatar_loaded.emit(user_id)


func _action(id: String, payload: Dictionary) -> BackendModels.ActionResult:
	var response: ServerSession.RpcResult = await _backend.call_rpc(id, payload)
	return BackendParser.action(response.data, response.error)


func _after(result: BackendModels.ActionResult) -> BackendModels.ActionResult:
	if result.ok:
		_backend.refresh_profile()
	return result
