class_name BackendRaffle
extends Node
## Server API of the parking draw (Backend.raffle): its state and ticket purchase.

var _backend: BackendService
var _impl: MockRaffle


func _init(backend: BackendService, impl: MockRaffle) -> void:
	name = "Raffle"
	_backend = backend
	_impl = impl


func get_raffle() -> BackendModels.RaffleState:
	await _backend.latency()
	_backend.get_mock().tick()
	var state: BackendModels.RaffleState = _impl.get_raffle()
	_backend.inbox_may_have_changed.emit()
	return state


func buy_ticket() -> BackendModels.PurchaseResult:
	await _backend.latency()
	var result: BackendModels.PurchaseResult = _impl.buy_ticket(_backend.operation_key())
	_backend.apply_balance(result.balance)
	return result
