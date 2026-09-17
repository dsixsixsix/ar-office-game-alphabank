class_name MockBackend
extends RefCounted
## DEV-ONLY stand-in for the Nakama Go module. Simulates server-side rules locally so the client
## can be built before the server exists. Replace with NakamaBackend; never ship this in a release.
## State lives in user://mock_backend.json (delete it to reset).

const SAVE_PATH: String = "user://mock_backend.json"
const TASKS_PATH: String = "res://data/tasks.json"
const CATALOG_PATH: String = "res://data/shop_catalog.json"
const WARDROBE_PATH: String = "res://data/wardrobe.json"
const CARS_PATH: String = "res://data/cars.json"
const WELCOME_BONUS: int = 500
const DAILY_COIN_CAP: int = 700
const DIFFICULTY_MULTIPLIERS: Dictionary[String, float] = {"normal": 1.0, "hard": 2.0, "very_hard": 3.0}
const MAX_MULTIPLIER: float = 2.0
const MULTIPLIER_STEP: float = 0.1
const SHOP_SLOTS: int = 6
const DISCOUNT_CHANCE: float = 0.4
const DISCOUNTS: Array[int] = [10, 15, 20, 25, 30, 50]
const RARITY_WEIGHTS: Dictionary[String, int] = {"common": 58, "rare": 28, "epic": 11, "legendary": 3}
const RARITY_ORDER: Array[String] = ["legendary", "epic", "rare", "common"]
const APPROVAL_RARITIES: Array[String] = ["epic", "legendary"]
const STARTER_CAR: String = "vaz2104"
## Minigame whose proof is the rotating office token; completing it marks the player present today.
const PRESENCE_MINIGAME: String = "presence_qr"
const PLAYER_ID: String = "player"
## Minigame score (0..1) adds at most this share of the reward.
const MAX_SCORE_BONUS: float = 0.2

var _state: Dictionary = {}
var _tasks: Array = []
var _catalog: Array = []
var _wardrobe: Array = []
var _cars: Array = []


func _init() -> void:
	_tasks = _load_json(TASKS_PATH).get("tasks", [])
	_catalog = _load_json(CATALOG_PATH).get("items", [])
	_wardrobe = _load_json(WARDROBE_PATH).get("items", [])
	_cars = _load_json(CARS_PATH).get("cars", [])
	_state = _load_json(SAVE_PATH)
	for key: String in ["balance", "streak", "last_login_day"]:
		if not _state.has(key):
			_state[key] = 0
	for key: String in ["completed", "skipped", "purchases", "earned", "outfit", "colleagues"]:
		if not _state.has(key):
			_state[key] = {}
	for key: String in ["used_keys", "ledger", "owned_items", "used_presence_tokens", "suspicious"]:
		if not _state.has(key):
			_state[key] = []
	if not _state.has("cars"):
		_state["cars"] = [STARTER_CAR]
	if not _state.has("car"):
		_state["car"] = STARTER_CAR
	if not _state.has("presence_day"):
		_state["presence_day"] = 0


func login() -> BackendModels.Profile:
	var today: int = _today()
	var profile: BackendModels.Profile = BackendModels.Profile.new()
	var last_day: int = int(_state["last_login_day"])
	if last_day == 0:
		_credit(WELCOME_BONUS, "welcome_bonus", "welcome")
		profile.welcome_bonus = WELCOME_BONUS
	if last_day != today:
		_state["streak"] = int(_state["streak"]) + 1 if last_day == today - 1 else 1
		_state["last_login_day"] = today
		_save()
	profile.user_id = PLAYER_ID
	profile.streak_days = int(_state["streak"])
	profile.multiplier = _multiplier()
	profile.balance = int(_state["balance"])
	profile.car_id = str(_state["car"])
	var car: Dictionary = _find(_cars, profile.car_id)
	profile.car_name = str(car.get("name", profile.car_id))
	profile.car_speed_kmh = int(car.get("speed_kmh", 110))
	profile.outfit = get_outfit()
	return profile


func list_tasks() -> Array[BackendModels.TaskInfo]:
	var result: Array[BackendModels.TaskInfo] = []
	var done: Array = _day_list("completed")
	var skipped: Array = _day_list("skipped")
	for entry: Variant in _tasks:
		var data: Dictionary = entry
		var info: BackendModels.TaskInfo = BackendModels.TaskInfo.new()
		info.id = data["id"]
		info.title = data["title"]
		info.description = data["description"]
		info.room = StringName(data["room"])
		var spot: Array = data.get("spot", [0, 0])
		info.spot = Vector2i(int(spot[0]), int(spot[1]))
		info.minigame = data["minigame"]
		info.fallback_minigame = str(data.get("fallback", ""))
		info.params = data.get("params", {})
		info.base_reward = int(data["reward"])
		info.difficulty = _difficulty(data)
		info.difficulty_multiplier = DIFFICULTY_MULTIPLIERS[info.difficulty]
		info.reward = _task_reward(data)
		info.skippable = bool(data.get("skippable", false))
		info.completed = done.has(info.id)
		info.skipped = skipped.has(info.id)
		result.append(info)
	return result


## Marks a skippable task as closed for today without a reward.
func skip_task(task_id: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var task: Dictionary = _find(_tasks, task_id)
	if task.is_empty():
		result.error = "unknown_task"
		return result
	if not bool(task.get("skippable", false)):
		result.error = "task_not_skippable"
		return result
	if _day_list("completed").has(task_id):
		result.error = "already_completed"
		return result
	var skipped: Array = _day_list("skipped")
	if not skipped.has(task_id):
		skipped.append(task_id)
		_save()
	result.ok = true
	return result


func complete_task(task_id: String, success: bool, operation_key: String, proof: Dictionary = {}) -> BackendModels.TaskResult:
	var result: BackendModels.TaskResult = BackendModels.TaskResult.new()
	result.balance = int(_state["balance"])
	if not _claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var task: Dictionary = _find(_tasks, task_id)
	result.error = _task_error(task, task_id, success, proof)
	if not result.error.is_empty():
		return result
	var is_check_in: bool = task["minigame"] == PRESENCE_MINIGAME
	if is_check_in:
		# Presence counts even when the daily coin cap is already reached.
		_state["presence_day"] = _today()
		_save()
	var earned_today: int = int((_state["earned"] as Dictionary).get(str(_today()), 0))
	var score: float = clampf(float(proof.get("score", 0.0)), 0.0, 1.0)
	var reward: int = mini(roundi(_task_reward(task) * (1.0 + MAX_SCORE_BONUS * score)), DAILY_COIN_CAP - earned_today)
	if reward <= 0:
		result.error = "daily_cap_reached"
		return result
	if task["minigame"] == "selfie":
		_day_list("colleagues").append(str(proof["colleague_id"]))
	_day_list("completed").append(task_id)
	(_state["earned"] as Dictionary)[str(_today())] = earned_today + reward
	_credit(reward, "task_reward", task_id)
	result.ok = true
	result.reward = reward
	result.balance = int(_state["balance"])
	return result


## Why the task can't be completed now, or "" when it can. Bad tokens and colleague codes are logged as suspicious.
func _task_error(task: Dictionary, task_id: String, success: bool, proof: Dictionary) -> String:
	if task.is_empty():
		return "unknown_task"
	if not success:
		return "task_failed"
	if _day_list("completed").has(task_id):
		return "already_completed"
	if _day_list("skipped").has(task_id):
		return "task_skipped"
	# The real server also checks the office IP on every task call.
	var error: String = ""
	if task["minigame"] == PRESENCE_MINIGAME:
		error = _verify_presence_token(str(proof.get("presence_token", "")))
	else:
		error = _verify_present_today()
	if error.is_empty() and task["minigame"] == "selfie":
		error = _verify_colleague(str(proof.get("colleague_id", "")))
	if not error.is_empty() and error != "presence_required":
		_log_suspicious(task_id, error)
	return error


## Rotating office token: valid signature, current time step, office known, never used before.
func _verify_presence_token(token: String) -> String:
	if token.is_empty():
		return "presence_token_invalid"
	if PresenceToken.verify(DevQrCodes.presence_secret(), token, Time.get_unix_time_from_system()) < 0:
		return "presence_token_invalid"
	if PresenceToken.office_of(token) != DevQrCodes.OFFICE_ID:
		return "presence_token_invalid"
	var used: Array = _state["used_presence_tokens"]
	if used.has(token):
		return "presence_token_reused"
	used.append(token)
	return ""


func _verify_present_today() -> String:
	return "" if int(_state["presence_day"]) == _today() else "presence_required"


func _verify_colleague(colleague_id: String) -> String:
	var payload: QrPayload = QrPayload.parse(QrPayload.user(colleague_id))
	if not payload.is_valid() or colleague_id == PLAYER_ID:
		return "colleague_invalid"
	if _day_list("colleagues").has(colleague_id):
		return "colleague_already_used"
	return ""


func _log_suspicious(task_id: String, reason: String) -> void:
	(_state["suspicious"] as Array).append({"t": Time.get_unix_time_from_system(), "task": task_id, "reason": reason})
	_save()


func get_shop() -> BackendModels.ShopState:
	var shop: BackendModels.ShopState = BackendModels.ShopState.new()
	var today: int = _today()
	shop.refresh_at = (today + 1) * 86400 - _utc_offset_seconds()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("alfa-shop-%d" % today)
	var picked: Array[String] = []
	var bought: Array = _day_list("purchases")
	for slot: int in SHOP_SLOTS:
		var item: Dictionary = _roll_item(rng, picked)
		if item.is_empty():
			break
		picked.append(item["id"])
		var offer: BackendModels.ShopOffer = BackendModels.ShopOffer.new()
		offer.offer_id = "%d-%s" % [today, item["id"]]
		offer.item_id = item["id"]
		offer.name = item["name"]
		offer.description = item["description"]
		offer.rarity = item["rarity"]
		offer.icon = int(item["icon"])
		offer.base_price = int(item["price"])
		offer.price = offer.base_price
		offer.purchased = bought.has(offer.offer_id)
		shop.offers.append(offer)
	if not shop.offers.is_empty() and rng.randf() < DISCOUNT_CHANCE:
		var discounted: BackendModels.ShopOffer = shop.offers[rng.randi_range(0, shop.offers.size() - 1)]
		discounted.discount_percent = DISCOUNTS[rng.randi_range(0, DISCOUNTS.size() - 1)]
		discounted.price = roundi(discounted.base_price * (100 - discounted.discount_percent) / 100.0)
	return shop


func buy(offer_id: String, operation_key: String) -> BackendModels.PurchaseResult:
	var result: BackendModels.PurchaseResult = BackendModels.PurchaseResult.new()
	result.balance = int(_state["balance"])
	if not _claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var offer: BackendModels.ShopOffer = null
	for candidate: BackendModels.ShopOffer in get_shop().offers:
		if candidate.offer_id == offer_id:
			offer = candidate
	if offer == null:
		result.error = "offer_expired"
		return result
	if offer.purchased:
		result.error = "already_purchased"
		return result
	if int(_state["balance"]) < offer.price:
		result.error = "not_enough_coins"
		return result
	_day_list("purchases").append(offer_id)
	var owned: Array = _state["owned_items"]
	if not owned.has(offer.item_id):
		owned.append(offer.item_id)
	_credit(-offer.price, "shop_purchase", offer.item_id)
	result.balance = int(_state["balance"])
	if APPROVAL_RARITIES.has(offer.rarity):
		result.status = BackendModels.PurchaseResult.Status.PENDING_APPROVAL
	else:
		result.status = BackendModels.PurchaseResult.Status.GRANTED
		if offer.item_id.begins_with("promo_"):
			result.voucher = "ALFA-%04X-%04X" % [randi() % 0x10000, randi() % 0x10000]
	return result


# --- Wardrobe --------------------------------------------------------------------


func get_wardrobe() -> BackendModels.WardrobeState:
	var state: BackendModels.WardrobeState = BackendModels.WardrobeState.new()
	state.outfit = get_outfit()
	state.streak_days = int(_state["streak"])
	for entry: Variant in _wardrobe:
		var data: Dictionary = entry
		var item: BackendModels.WardrobeItem = BackendModels.WardrobeItem.new()
		item.slot = data["slot"]
		item.id = data["id"]
		item.name = data["name"]
		var unlock: Dictionary = data.get("unlock", {})
		item.unlock_type = str(unlock.get("type", "free"))
		match item.unlock_type:
			"shop":
				item.unlock_value = str(unlock.get("item", ""))
			"streak":
				item.unlock_value = str(int(unlock.get("days", 0)))
		item.unlocked = _is_unlocked(data)
		state.items.append(item)
	return state


func get_outfit() -> Dictionary:
	var outfit: Dictionary = Outfit.default_outfit()
	outfit.merge(_state["outfit"], true)
	return outfit


func save_outfit(outfit: Dictionary) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var clean: Dictionary = {}
	for slot: String in Outfit.SLOTS:
		var item_id: String = str(outfit.get(slot, ""))
		var item: Dictionary = _find_wardrobe_item(slot, item_id)
		if item.is_empty():
			result.error = "unknown_item"
			return result
		if not _is_unlocked(item):
			result.error = "item_locked"
			return result
		clean[slot] = item_id
	for slot: String in Outfit.COLOR_KEYS:
		var key: String = Outfit.COLOR_KEYS[slot]
		var color: String = str(outfit.get(key, ""))
		if not Outfit.is_valid_color(color):
			result.error = "invalid_color"
			return result
		clean[key] = color.to_lower()
	_state["outfit"] = clean
	_save()
	result.ok = true
	return result


func _find_wardrobe_item(slot: String, item_id: String) -> Dictionary:
	for entry: Variant in _wardrobe:
		var data: Dictionary = entry
		if data["slot"] == slot and data["id"] == item_id:
			return data
	return {}


func _is_unlocked(item: Dictionary) -> bool:
	var unlock: Dictionary = item.get("unlock", {})
	match str(unlock.get("type", "free")):
		"shop":
			return (_state["owned_items"] as Array).has(str(unlock.get("item", "")))
		"streak":
			return int(_state["streak"]) >= int(unlock.get("days", 0))
	return true


# --- Garage ----------------------------------------------------------------------


func get_garage() -> BackendModels.GarageState:
	var garage: BackendModels.GarageState = BackendModels.GarageState.new()
	var owned: Array = _state["cars"]
	for entry: Variant in _cars:
		var data: Dictionary = entry
		var car: BackendModels.CarInfo = BackendModels.CarInfo.new()
		car.id = data["id"]
		car.name = data["name"]
		car.description = data.get("description", "")
		car.price = int(data["price"])
		car.speed_kmh = int(data["speed_kmh"])
		car.owned = owned.has(car.id) or car.price == 0
		car.selected = str(_state["car"]) == car.id
		garage.cars.append(car)
	return garage


func get_car(car_id: String) -> Dictionary:
	return _find(_cars, car_id)


func buy_car(car_id: String, operation_key: String) -> BackendModels.PurchaseResult:
	var result: BackendModels.PurchaseResult = BackendModels.PurchaseResult.new()
	result.balance = int(_state["balance"])
	if not _claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var car: Dictionary = _find(_cars, car_id)
	if car.is_empty():
		result.error = "unknown_car"
		return result
	var owned: Array = _state["cars"]
	if owned.has(car_id):
		result.error = "already_owned"
		return result
	if int(_state["balance"]) < int(car["price"]):
		result.error = "not_enough_coins"
		return result
	owned.append(car_id)
	_credit(-int(car["price"]), "car_purchase", car_id)
	result.balance = int(_state["balance"])
	result.status = BackendModels.PurchaseResult.Status.GRANTED
	return result


func select_car(car_id: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var car: Dictionary = _find(_cars, car_id)
	if car.is_empty():
		result.error = "unknown_car"
	elif not (_state["cars"] as Array).has(car_id) and int(car["price"]) != 0:
		result.error = "car_not_owned"
	else:
		_state["car"] = car_id
		_save()
		result.ok = true
	return result


# --- Helpers ----------------------------------------------------------------------


func _roll_item(rng: RandomNumberGenerator, exclude: Array[String]) -> Dictionary:
	var total: int = 0
	for weight: int in RARITY_WEIGHTS.values():
		total += weight
	var roll: int = rng.randi_range(1, total)
	var rarity: String = "common"
	for key: String in RARITY_WEIGHTS:
		roll -= RARITY_WEIGHTS[key]
		if roll <= 0:
			rarity = key
			break
	# Fall back to more common rarities when the rolled pool is exhausted.
	for index: int in range(RARITY_ORDER.find(rarity), RARITY_ORDER.size()):
		var pool: Array = _catalog.filter(
			func(item: Dictionary) -> bool: return item["rarity"] == RARITY_ORDER[index] and not exclude.has(item["id"])
		)
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
	return {}


func _credit(amount: int, reason: String, reference: String) -> void:
	_state["balance"] = int(_state["balance"]) + amount
	(_state["ledger"] as Array).append({"t": Time.get_unix_time_from_system(), "amount": amount, "reason": reason, "ref": reference})
	_save()


func _claim_key(operation_key: String) -> bool:
	var keys: Array = _state["used_keys"]
	if operation_key.is_empty() or keys.has(operation_key):
		return false
	keys.append(operation_key)
	return true


func _difficulty(task: Dictionary) -> String:
	var difficulty: String = str(task.get("difficulty", "normal"))
	return difficulty if DIFFICULTY_MULTIPLIERS.has(difficulty) else "normal"


func _task_reward(task: Dictionary) -> int:
	return roundi(int(task["reward"]) * DIFFICULTY_MULTIPLIERS[_difficulty(task)] * _multiplier())


func _multiplier() -> float:
	return minf(1.0 + MULTIPLIER_STEP * (int(_state["streak"]) - 1), MAX_MULTIPLIER)


func _day_list(key: String) -> Array:
	var by_day: Dictionary = _state[key]
	var day_key: String = str(_today())
	if not by_day.has(day_key):
		by_day[day_key] = []
	return by_day[day_key]


func _today() -> int:
	return floori((Time.get_unix_time_from_system() + _utc_offset_seconds()) / 86400.0)


func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _find(items: Array, id: String) -> Dictionary:
	for item: Variant in items:
		if item is Dictionary and (item as Dictionary).get("id") == id:
			return item
	return {}


func _save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s: %s" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(_state, "\t"))


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
