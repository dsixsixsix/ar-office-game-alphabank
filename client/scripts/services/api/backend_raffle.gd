class_name BackendRaffle
extends Node
## Server API of the parking draw (Backend.raffle): its state and ticket purchase.

var _backend: BackendService


func _init(backend: BackendService) -> void:
	name = "Raffle"
	_backend = backend


func get_raffle() -> BackendModels.RaffleState:
	var response: ServerSession.RpcResult = await _backend.call_rpc("get_raffle")
	# A finished draw adds a message to the inbox.
	_backend.inbox_may_have_changed.emit()
	return BackendParser.raffle(response.data)


func buy_ticket() -> BackendModels.PurchaseResult:
	var payload: Dictionary = {"operation_key": _backend.operation_key()}
	var response: ServerSession.RpcResult = await _backend.call_rpc("buy_raffle_ticket", payload)
	var result: BackendModels.PurchaseResult = BackendParser.purchase(response.data, response.error)
	_backend.apply_balance(result.balance)
	return result
