class_name BackendSocial
extends Node
## Server API about other players (Backend.social): colleagues picked for tasks, profile-code
## lookups, joint photo confirmations and the inbox.

var _backend: BackendService
var _impl: MockSocial


func _init(backend: BackendService, impl: MockSocial) -> void:
	name = "Social"
	_backend = backend
	_impl = impl


## Colleague the server picked for a task (joint photo, blind coffee). Only players who checked in today.
func assign_colleague(task_id: String) -> BackendModels.ColleagueResult:
	await _backend.latency()
	_backend.get_mock().tick()
	return _impl.assign_colleague(task_id)


## Public card of the player behind a scanned profile code; null when unknown.
func lookup_colleague(user_id: String) -> BackendModels.Colleague:
	await _backend.latency()
	return _impl.lookup_colleague(user_id)


## Newest first.
func get_inbox() -> Array[BackendModels.InboxItem]:
	await _backend.latency()
	_backend.get_mock().tick()
	var items: Array[BackendModels.InboxItem] = _impl.get_inbox()
	_backend.apply_balance(_backend.get_mock().get_balance())
	return items


func mark_inbox_read() -> void:
	await _backend.latency()
	_impl.mark_inbox_read()


## Answer to "<colleague> took a photo with you. Is it true?".
func respond_photo_request(item_id: int, confirm: bool) -> BackendModels.ActionResult:
	await _backend.latency()
	var result: BackendModels.ActionResult = _impl.respond_photo_request(item_id, confirm, _backend.operation_key())
	_backend.apply_balance(_backend.get_mock().get_balance())
	return result
