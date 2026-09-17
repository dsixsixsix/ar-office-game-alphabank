extends Node
## Game-facing server API (autoload "Backend"). Every call is async so the mock can be swapped for
## Nakama RPCs without touching callers. The client never changes balance, unlocks or ownership itself.

signal balance_changed(balance: int)
signal outfit_changed(outfit: Dictionary)
signal car_changed(car_id: String)

const SIMULATED_LATENCY: float = 0.12

var profile: BackendModels.Profile

var _impl: MockBackend = MockBackend.new()


func login() -> BackendModels.Profile:
	await _latency()
	profile = _impl.login()
	balance_changed.emit(profile.balance)
	outfit_changed.emit(profile.outfit)
	car_changed.emit(profile.car_id)
	return profile


func list_tasks() -> Array[BackendModels.TaskInfo]:
	await _latency()
	return _impl.list_tasks()


## `proof` carries the minigame evidence (presence token, colleague id, score); the server validates it.
func complete_task(task_id: String, success: bool, proof: Dictionary = {}) -> BackendModels.TaskResult:
	await _latency()
	var result: BackendModels.TaskResult = _impl.complete_task(task_id, success, _operation_key(), proof)
	_set_balance(result.balance)
	return result


func skip_task(task_id: String) -> BackendModels.ActionResult:
	await _latency()
	return _impl.skip_task(task_id)


func get_shop() -> BackendModels.ShopState:
	await _latency()
	return _impl.get_shop()


func buy(offer_id: String) -> BackendModels.PurchaseResult:
	await _latency()
	var result: BackendModels.PurchaseResult = _impl.buy(offer_id, _operation_key())
	_set_balance(result.balance)
	return result


func get_wardrobe() -> BackendModels.WardrobeState:
	await _latency()
	return _impl.get_wardrobe()


func save_outfit(outfit: Dictionary) -> BackendModels.ActionResult:
	await _latency()
	var result: BackendModels.ActionResult = _impl.save_outfit(outfit)
	if result.ok:
		_ensure_profile()
		profile.outfit = _impl.get_outfit()
		outfit_changed.emit(profile.outfit)
	return result


func get_garage() -> BackendModels.GarageState:
	await _latency()
	return _impl.get_garage()


func buy_car(car_id: String) -> BackendModels.PurchaseResult:
	await _latency()
	var result: BackendModels.PurchaseResult = _impl.buy_car(car_id, _operation_key())
	_set_balance(result.balance)
	return result


func select_car(car_id: String) -> BackendModels.ActionResult:
	await _latency()
	var result: BackendModels.ActionResult = _impl.select_car(car_id)
	if result.ok:
		_ensure_profile()
		profile.car_id = car_id
		var car: Dictionary = _impl.get_car(car_id)
		profile.car_name = str(car.get("name", car_id))
		profile.car_speed_kmh = int(car.get("speed_kmh", 110))
		car_changed.emit(car_id)
	return result


func get_balance() -> int:
	return profile.balance if profile != null else 0


func get_car_id() -> String:
	return profile.car_id if profile != null else VehicleCatalog.DEFAULT_CAR


func _ensure_profile() -> void:
	if profile == null:
		profile = BackendModels.Profile.new()


func _set_balance(balance: int) -> void:
	_ensure_profile()
	if profile.balance != balance:
		profile.balance = balance
		balance_changed.emit(balance)


## Idempotency key for balance-changing calls.
func _operation_key() -> String:
	return "%d-%08x" % [Time.get_ticks_usec(), randi()]


func _latency() -> void:
	await get_tree().create_timer(SIMULATED_LATENCY).timeout
