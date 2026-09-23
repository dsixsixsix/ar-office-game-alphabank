class_name BackendSocial
extends Node
## Server API about other players (Backend.social): colleagues picked for tasks, profile-code
## lookups, joint photo confirmations and the inbox.

var _backend: BackendService


func _init(backend: BackendService) -> void:
	name = "Social"
	_backend = backend


## Colleague the server picked for a task (joint photo, blind coffee). Only players in the office now.
func assign_colleague(task_id: String) -> BackendModels.ColleagueResult:
	var response: ServerSession.RpcResult = await _backend.call_rpc("assign_colleague", {"task_id": task_id})
	return BackendParser.colleague_result(response.data, response.error)


## Public card of the player behind a scanned profile code; null when unknown.
func lookup_colleague(user_id: String) -> BackendModels.Colleague:
	var response: ServerSession.RpcResult = await _backend.call_rpc("lookup_colleague", {"user_id": user_id})
	if not bool(response.data.get("found", false)) or not response.data.get("colleague") is Dictionary:
		return null
	return BackendParser.colleague(response.data["colleague"])


## Newest first. Other players' actions (a confirmed photo, a draw) may have changed the balance.
func get_inbox() -> Array[BackendModels.InboxItem]:
	var response: ServerSession.RpcResult = await _backend.call_rpc("get_inbox")
	if response.ok:
		_backend.apply_balance(int(response.data.get("balance", -1)))
	return BackendParser.inbox(response.data)


func mark_inbox_read() -> void:
	await _backend.call_rpc("mark_inbox_read")


## Answer to "<colleague> took a photo with you. Is it true?".
func respond_photo_request(item_id: int, confirm: bool) -> BackendModels.ActionResult:
	var payload: Dictionary = {"item_id": item_id, "confirm": confirm, "operation_key": _backend.operation_key()}
	var response: ServerSession.RpcResult = await _backend.call_rpc("respond_photo_request", payload)
	_backend.apply_balance(int(response.data.get("balance", -1)))
	return BackendParser.action(response.data, response.error)
