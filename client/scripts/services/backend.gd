class_name BackendService
extends Node
## Game-facing server API (autoload "Backend"). Every call is async so the mock can be swapped for
## Nakama RPCs without touching callers. The client never changes balance, unlocks or ownership itself.
## Tasks, shop, wardrobe and garage are here; the other groups of RPCs are `social` (colleagues,
## joint photos, inbox), `account` (profile page, status, avatar) and `raffle` (parking draw).

signal balance_changed(balance: int)
signal outfit_changed(outfit: Dictionary)
signal car_changed(car_id: String)
## Status or avatar of the player changed.
signal profile_changed(profile: BackendModels.Profile)
## Something happened that may have added messages to the inbox (a check-in, a finished task).
signal inbox_may_have_changed

const SIMULATED_LATENCY: float = 0.12

var profile: BackendModels.Profile
var social: BackendSocial
var account: BackendAccount
var raffle: BackendRaffle

var _impl: MockBackend = MockBackend.new()


func _ready() -> void:
	social = BackendSocial.new(self, _impl.social)
	account = BackendAccount.new(self, _impl.account)
	raffle = BackendRaffle.new(self, _impl.raffle)
	for api: Node in [social, account, raffle]:
		add_child(api)
	if OS.is_debug_build() and OS.has_feature("pc"):
		var keys: Node = load("res://scripts/services/dev_backend_keys.gd").new()
		add_child(keys)


func login() -> BackendModels.Profile:
	await latency()
	profile = _impl.login()
	balance_changed.emit(profile.balance)
	outfit_changed.emit(profile.outfit)
	car_changed.emit(profile.car_id)
	profile_changed.emit(profile)
	inbox_may_have_changed.emit()
	return profile


func list_tasks() -> Array[BackendModels.TaskInfo]:
	await latency()
	return _impl.list_tasks()


## `proof` carries the minigame evidence (presence token, colleague id, score); the server validates it.
func complete_task(task_id: String, success: bool, proof: Dictionary = {}) -> BackendModels.TaskResult:
	await latency()
	var result: BackendModels.TaskResult = _impl.complete_task(task_id, success, operation_key(), proof)
	apply_balance(result.balance)
	if result.ok:
		refresh_profile()
		inbox_may_have_changed.emit()
	return result


func skip_task(task_id: String) -> BackendModels.ActionResult:
	await latency()
	return _impl.skip_task(task_id)


func get_shop() -> BackendModels.ShopState:
	await latency()
	return _impl.get_shop()


func buy(offer_id: String) -> BackendModels.PurchaseResult:
	await latency()
	var result: BackendModels.PurchaseResult = _impl.buy(offer_id, operation_key())
	apply_balance(result.balance)
	return result


func get_wardrobe() -> BackendModels.WardrobeState:
	await latency()
	return _impl.get_wardrobe()


func save_outfit(outfit: Dictionary) -> BackendModels.ActionResult:
	await latency()
	var result: BackendModels.ActionResult = _impl.save_outfit(outfit)
	if result.ok:
		_ensure_profile()
		profile.outfit = _impl.get_outfit()
		outfit_changed.emit(profile.outfit)
	return result


func get_garage() -> BackendModels.GarageState:
	await latency()
	return _impl.get_garage()


func buy_car(car_id: String) -> BackendModels.PurchaseResult:
	await latency()
	var result: BackendModels.PurchaseResult = _impl.buy_car(car_id, operation_key())
	apply_balance(result.balance)
	return result


func select_car(car_id: String) -> BackendModels.ActionResult:
	await latency()
	var result: BackendModels.ActionResult = _impl.select_car(car_id)
	if result.ok:
		_ensure_profile()
		profile.car_id = car_id
		var car: Dictionary = _impl.get_car(car_id)
		profile.car_name = str(car.get("name", car_id))
		profile.car_speed_kmh = int(car.get("speed_kmh", 110))
		car_changed.emit(car_id)
	return result


# --- Notifications ---------------------------------------------------------------


## Reminders and announcements for the OS scheduler, replacing any earlier plan.
func get_notification_plan() -> Array[BackendModels.PlannedNotification]:
	await latency()
	return _impl.get_notification_plan()


# --- Local state -----------------------------------------------------------------


func get_balance() -> int:
	return profile.balance if profile != null else 0


func get_car_id() -> String:
	return profile.car_id if profile != null else VehicleCatalog.DEFAULT_CAR


func get_user_id() -> String:
	return profile.user_id if profile != null else ""


## DEV-ONLY access to the mock for debug keys and the automated tour.
func get_mock() -> MockBackend:
	return _impl


## Takes the balance the server reported and tells the UI.
func apply_balance(balance: int) -> void:
	_ensure_profile()
	if profile.balance != balance:
		profile.balance = balance
		balance_changed.emit(balance)


## Re-reads the player's profile (status, avatar, streak) after a change.
func refresh_profile() -> void:
	var fresh: BackendModels.Profile = _impl.account.profile()
	_ensure_profile()
	profile.display_name = fresh.display_name
	profile.department = fresh.department
	profile.status = fresh.status
	profile.avatar = fresh.avatar
	profile.streak_days = fresh.streak_days
	profile.present_today = fresh.present_today
	profile.multiplier = fresh.multiplier
	apply_balance(fresh.balance)
	profile_changed.emit(profile)


## Idempotency key for balance-changing calls.
func operation_key() -> String:
	return "%d-%08x" % [Time.get_ticks_usec(), randi()]


func latency() -> void:
	await get_tree().create_timer(SIMULATED_LATENCY).timeout


func _ensure_profile() -> void:
	if profile == null:
		profile = BackendModels.Profile.new()
