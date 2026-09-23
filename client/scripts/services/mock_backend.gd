class_name MockBackend
extends RefCounted
## DEV-ONLY stand-in for the Nakama Go module. Simulates server-side rules locally so the client
## can be built before the server exists. Replace with NakamaBackend; never ship this in a release.
## This class holds the task, shop, wardrobe and garage rules; the other parts live in `social`
## (colleagues, joint photos, inbox), `account` (fines, streak, profile) and `raffle` (parking draw),
## all sharing one MockStore (state in user://mock_backend.json; delete it to reset).

const SAVE_PATH: String = MockStore.SAVE_PATH
const CATALOG_PATH: String = "res://data/shop_catalog.json"
const WARDROBE_PATH: String = "res://data/wardrobe.json"
const CARS_PATH: String = "res://data/cars.json"
const NOTIFICATIONS_PATH: String = "res://data/notifications.json"
const WELCOME_BONUS: int = 500
const DIFFICULTY_MULTIPLIERS: Dictionary[String, float] = {"normal": 1.0, "hard": 2.0, "very_hard": 3.0}
const SHOP_SLOTS: int = 6
const DISCOUNT_CHANCE: float = 0.4
const DISCOUNTS: Array[int] = [10, 15, 20, 25, 30, 50]
const RARITY_WEIGHTS: Dictionary[String, int] = {"common": 58, "rare": 28, "epic": 11, "legendary": 3}
const RARITY_ORDER: Array[String] = ["legendary", "epic", "rare", "common"]
const APPROVAL_RARITIES: Array[String] = ["epic", "legendary"]
const STARTER_CAR: String = "vaz2104"
## Minigame whose proof is the rotating office token; completing it marks the player present today.
const PRESENCE_MINIGAME: String = "presence_qr"
const PLAYER_ID: String = MockStore.PLAYER_ID
## Minigame score (0..1) adds at most this share of the reward.
const MAX_SCORE_BONUS: float = 0.2

var store: MockStore = MockStore.new()
var social: MockSocial = MockSocial.new(store)
var account: MockAccount = MockAccount.new(store)
var raffle: MockRaffle = MockRaffle.new(store, social)

var _catalog: Array = []
var _wardrobe: Array = []
var _cars: Array = []
var _fun_texts: Array = []


func _init() -> void:
	_catalog = MockStore.load_json(CATALOG_PATH).get("items", [])
	_wardrobe = MockStore.load_json(WARDROBE_PATH).get("items", [])
	_cars = MockStore.load_json(CARS_PATH).get("cars", [])
	_fun_texts = MockStore.load_json(NOTIFICATIONS_PATH).get("fun", [])
	if not store.state.has("cars"):
		store.state["cars"] = [STARTER_CAR]
	if not store.state.has("car"):
		store.state["car"] = STARTER_CAR


func login() -> BackendModels.Profile:
	var state: Dictionary = store.state
	var today: int = store.today()
	var last_day: int = int(state["last_login_day"])
	var welcome: int = 0
	if last_day == 0:
		store.credit(WELCOME_BONUS, "welcome_bonus", "welcome")
		welcome = WELCOME_BONUS
		state["first_day"] = today
		state["processed_day"] = today - 1
	if int(state["first_day"]) == 0:
		state["first_day"] = last_day if last_day > 0 else today
	if int(state["processed_day"]) == 0:
		# Saves from before absence fines start with a clean slate.
		state["processed_day"] = today - 1
	state["last_login_day"] = today
	tick()
	var profile: BackendModels.Profile = account.profile()
	profile.welcome_bonus = welcome
	profile.car_id = str(state["car"])
	var car: Dictionary = MockStore.find(_cars, profile.car_id)
	profile.car_name = str(car.get("name", profile.car_id))
	profile.car_speed_kmh = int(car.get("speed_kmh", 110))
	profile.outfit = get_outfit()
	var report: Dictionary = state["morning_report"]
	profile.fined_coins = int(report.get("fined", 0))
	profile.lost_streak = int(report.get("lost_streak", 0))
	state["morning_report"] = {}
	store.save()
	return profile


func get_balance() -> int:
	return int(store.state["balance"])


## Runs what the real server does on its own schedule: absence fines at the end of each workday,
## colleagues answering photo requests, draws that are due.
func tick() -> void:
	account.process_absences()
	social.simulate()
	raffle.run_due_draws()


# --- Tasks -----------------------------------------------------------------------


func list_tasks() -> Array[BackendModels.TaskInfo]:
	tick()
	var result: Array[BackendModels.TaskInfo] = []
	var done: Array = store.day_list("completed")
	var skipped: Array = store.day_list("skipped")
	var pending: Array = store.day_list("pending")
	for entry: Variant in store.tasks:
		var data: Dictionary = entry
		var info: BackendModels.TaskInfo = BackendModels.TaskInfo.new()
		info.id = data["id"]
		info.title = data["title"]
		info.description = data["description"]
		info.room = StringName(data["room"])
		info.floor_id = StringName(str(data.get("floor", OfficeFloors.HQ)))
		var spot: Array = data.get("spot", [0, 0])
		info.spot = Vector2i(int(spot[0]), int(spot[1]))
		info.minigame = data["minigame"]
		info.fallback_minigame = str(data.get("fallback", ""))
		info.params = data.get("params", {})
		info.assignment = str(data.get("assignment", ""))
		info.base_reward = int(data["reward"])
		info.difficulty = _difficulty(data)
		info.difficulty_multiplier = DIFFICULTY_MULTIPLIERS[info.difficulty]
		info.reward = _task_reward(data)
		info.skippable = bool(data.get("skippable", false))
		info.completed = done.has(info.id)
		info.skipped = skipped.has(info.id)
		info.pending = pending.has(info.id)
		result.append(info)
	return result


## Marks a skippable task as closed for today without a reward.
func skip_task(task_id: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var task: Dictionary = MockStore.find(store.tasks, task_id)
	if task.is_empty():
		result.error = "unknown_task"
	elif not bool(task.get("skippable", false)):
		result.error = "task_not_skippable"
	elif store.day_list("completed").has(task_id):
		result.error = "already_completed"
	elif store.day_list("pending").has(task_id):
		result.error = "pending_confirmation"
	if not result.error.is_empty():
		return result
	var skipped: Array = store.day_list("skipped")
	if not skipped.has(task_id):
		skipped.append(task_id)
		store.save()
	result.ok = true
	return result


func complete_task(task_id: String, success: bool, operation_key: String, proof: Dictionary = {}) -> BackendModels.TaskResult:
	var result: BackendModels.TaskResult = BackendModels.TaskResult.new()
	result.balance = int(store.state["balance"])
	if not store.claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var task: Dictionary = MockStore.find(store.tasks, task_id)
	result.error = _task_error(task, task_id, success, proof)
	if not result.error.is_empty():
		return result
	var today: int = store.today()
	if task["minigame"] == PRESENCE_MINIGAME:
		# Presence counts even when the daily coin cap is already reached.
		account.record_check_in()
	var score: float = clampf(float(proof.get("score", 0.0)), 0.0, 1.0)
	var reward: int = mini(roundi(_task_reward(task) * (1.0 + MAX_SCORE_BONUS * score)), store.cap_left(today))
	if reward <= 0:
		result.error = "daily_cap_reached"
		return result
	result.ok = true
	if task["minigame"] == MockSocial.PHOTO_MINIGAME:
		# The reward waits for the colleague: they confirm the photo on their phone.
		result.pending = true
		result.partner_name = social.submit_photo(task, proof, reward)
		return result
	social.remember_met(task, proof)
	store.grant_task(task, today, reward)
	result.reward = reward
	result.balance = int(store.state["balance"])
	return result


## Why the task can't be completed now, or "" when it can. Bad tokens and colleague proofs are logged as suspicious.
func _task_error(task: Dictionary, task_id: String, success: bool, proof: Dictionary) -> String:
	if task.is_empty():
		return "unknown_task"
	var error: String = ""
	if not success:
		error = "task_failed"
	elif store.day_list("completed").has(task_id):
		error = "already_completed"
	elif store.day_list("skipped").has(task_id):
		error = "task_skipped"
	elif store.day_list("pending").has(task_id):
		error = "pending_confirmation"
	# The real server also checks the office IP on every task call.
	elif task["minigame"] == PRESENCE_MINIGAME:
		error = _verify_presence_token(str(proof.get("presence_token", "")))
	elif not store.is_present(store.today()):
		error = "presence_required"
	else:
		error = social.verify(task, proof)
	if not error.is_empty() and not ["presence_required", "task_failed", "already_completed", "task_skipped", "pending_confirmation"].has(error):
		store.log_suspicious(task_id, error)
	return error


## Rotating office token: valid signature, current time step, office known, never used before.
## Tokens follow the real clock even when the dev clock is shifted.
func _verify_presence_token(token: String) -> String:
	if token.is_empty():
		return "presence_token_invalid"
	if PresenceToken.verify(DevQrCodes.presence_secret(), token, Time.get_unix_time_from_system()) < 0:
		return "presence_token_invalid"
	if PresenceToken.office_of(token) != DevQrCodes.OFFICE_ID:
		return "presence_token_invalid"
	var used: Array = store.state["used_presence_tokens"]
	if used.has(token):
		return "presence_token_reused"
	used.append(token)
	return ""


# --- Notifications ---------------------------------------------------------------


func get_notification_plan() -> Array[BackendModels.PlannedNotification]:
	tick()
	var config: Dictionary = store.rules.get("notifications", {})
	var draw: Dictionary = raffle.current_draw()
	var today: int = store.today()
	var facts: Dictionary = {
		"now": store.now(), "utc_offset": store.utc_offset(), "today": today,
		"streak": store.streak(), "present_today": store.is_present(today),
		"reminder_times": config.get("reminder_times", []),
		"raffle_draw_at": 0 if bool(draw["drawn"]) else int(draw["draw_at"]),
		"raffle_joined": (draw["tickets"] as Array).has(PLAYER_ID),
		"fun_texts": _fun_texts, "fun_window": config.get("fun_window", ["12:00", "19:00"]),
		"fun_max": int(config.get("fun_max", 2)), "seed": PLAYER_ID,
	}
	var result: Array[BackendModels.PlannedNotification] = []
	for entry: Dictionary in NotificationPlanner.plan(facts):
		var item: BackendModels.PlannedNotification = BackendModels.PlannedNotification.new()
		item.id = int(entry["id"])
		item.at = int(entry["at"])
		item.delay_seconds = maxi(0, item.at - int(facts["now"]))
		item.kind = entry["kind"]
		item.params = entry["params"]
		result.append(item)
	return result


## DEV: moves the mock's calendar forward, e.g. to see absence fines. Presence tokens keep using the
## real clock, so the office screen still works.
func dev_skip_days(days: int) -> void:
	store.state["dev_day_shift"] = int(store.state["dev_day_shift"]) + days
	store.save()


# --- Shop ------------------------------------------------------------------------


func get_shop() -> BackendModels.ShopState:
	var shop: BackendModels.ShopState = BackendModels.ShopState.new()
	var today: int = store.today()
	shop.refresh_at = (today + 1) * 86400 - store.utc_offset()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("alfa-shop-%d" % today)
	var picked: Array[String] = []
	var bought: Array = store.day_list("purchases")
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
	result.balance = int(store.state["balance"])
	if not store.claim_key(operation_key):
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
	if int(store.state["balance"]) < offer.price:
		result.error = "not_enough_coins"
		return result
	store.day_list("purchases").append(offer_id)
	var owned: Array = store.state["owned_items"]
	if not owned.has(offer.item_id):
		owned.append(offer.item_id)
	store.credit(-offer.price, "shop_purchase", offer.item_id)
	result.balance = int(store.state["balance"])
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
	state.streak_days = store.streak()
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
	outfit.merge(store.state["outfit"], true)
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
	store.state["outfit"] = clean
	store.save()
	result.ok = true
	return result


func _find_wardrobe_item(slot: String, item_id: String) -> Dictionary:
	for entry: Variant in _wardrobe:
		var data: Dictionary = entry
		if data["slot"] == slot and data["id"] == item_id:
			return data
	return {}


## Streak items stay unlocked once earned (best streak), so a lost streak does not undress the player.
func _is_unlocked(item: Dictionary) -> bool:
	var unlock: Dictionary = item.get("unlock", {})
	match str(unlock.get("type", "free")):
		"shop":
			return (store.state["owned_items"] as Array).has(str(unlock.get("item", "")))
		"streak":
			return maxi(int(store.state["best_streak"]), store.streak()) >= int(unlock.get("days", 0))
	return true


# --- Garage ----------------------------------------------------------------------


func get_garage() -> BackendModels.GarageState:
	var garage: BackendModels.GarageState = BackendModels.GarageState.new()
	var owned: Array = store.state["cars"]
	for entry: Variant in _cars:
		var data: Dictionary = entry
		var car: BackendModels.CarInfo = BackendModels.CarInfo.new()
		car.id = data["id"]
		car.name = data["name"]
		car.description = data.get("description", "")
		car.price = int(data["price"])
		car.speed_kmh = int(data["speed_kmh"])
		car.owned = owned.has(car.id) or car.price == 0
		car.selected = str(store.state["car"]) == car.id
		garage.cars.append(car)
	return garage


func get_car(car_id: String) -> Dictionary:
	return MockStore.find(_cars, car_id)


func buy_car(car_id: String, operation_key: String) -> BackendModels.PurchaseResult:
	var result: BackendModels.PurchaseResult = BackendModels.PurchaseResult.new()
	result.balance = int(store.state["balance"])
	if not store.claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var car: Dictionary = MockStore.find(_cars, car_id)
	if car.is_empty():
		result.error = "unknown_car"
		return result
	var owned: Array = store.state["cars"]
	if owned.has(car_id):
		result.error = "already_owned"
		return result
	if int(store.state["balance"]) < int(car["price"]):
		result.error = "not_enough_coins"
		return result
	owned.append(car_id)
	store.credit(-int(car["price"]), "car_purchase", car_id)
	result.balance = int(store.state["balance"])
	result.status = BackendModels.PurchaseResult.Status.GRANTED
	return result


func select_car(car_id: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var car: Dictionary = MockStore.find(_cars, car_id)
	if car.is_empty():
		result.error = "unknown_car"
	elif not (store.state["cars"] as Array).has(car_id) and int(car["price"]) != 0:
		result.error = "car_not_owned"
	else:
		store.state["car"] = car_id
		store.save()
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


func _difficulty(task: Dictionary) -> String:
	var difficulty: String = str(task.get("difficulty", "normal"))
	return difficulty if DIFFICULTY_MULTIPLIERS.has(difficulty) else "normal"


func _task_reward(task: Dictionary) -> int:
	return roundi(int(task["reward"]) * DIFFICULTY_MULTIPLIERS[_difficulty(task)] * store.multiplier())
