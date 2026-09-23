class_name MockStore
extends RefCounted
## DEV-ONLY state and content shared by the mock server modules (MockBackend, MockSocial,
## MockAccount, MockRaffle): the save file, the content from res://data, the clock, the ledger and
## the inbox. Stands in for the Nakama storage, wallet and notification APIs.
## State lives in user://mock_backend.json (delete it to reset).

const SAVE_PATH: String = "user://mock_backend.json"
const TASKS_PATH: String = "res://data/tasks.json"
const RULES_PATH: String = "res://data/game_rules.json"
const COLLEAGUES_PATH: String = "res://data/colleagues.json"
const PLAYER_ID: String = "player"
const DAILY_COIN_CAP: int = 700
const MAX_MULTIPLIER: float = 2.0
const MULTIPLIER_STEP: float = 0.1
const INT_KEYS: Array[String] = [
	"balance", "last_login_day", "first_day", "processed_day", "best_streak", "next_inbox_id", "dev_day_shift", "dev_raffle_at",
]
const DICT_KEYS: Array[String] = [
	"completed", "skipped", "purchases", "earned", "outfit", "colleagues", "presence_days", "excused_days",
	"assignments", "pending", "checkin_at", "incoming_sent", "task_log", "raffles", "profile", "morning_report",
]
const ARRAY_KEYS: Array[String] = ["used_keys", "ledger", "owned_items", "used_presence_tokens", "suspicious", "inbox", "photo_requests"]

var state: Dictionary = {}
var tasks: Array = []
var rules: Dictionary = {}
## Other players, see res://data/colleagues.json.
var colleagues: Array = []
var player_department: String = ""


func _init() -> void:
	tasks = load_json(TASKS_PATH).get("tasks", [])
	rules = load_json(RULES_PATH)
	var directory: Dictionary = load_json(COLLEAGUES_PATH)
	colleagues = directory.get("players", [])
	player_department = str(directory.get("player_department", ""))
	state = load_json(SAVE_PATH)
	for key: String in INT_KEYS:
		if not state.has(key):
			state[key] = 0
	for key: String in DICT_KEYS:
		if not state.has(key):
			state[key] = {}
	for key: String in ARRAY_KEYS:
		if not state.has(key):
			state[key] = []
	# Saves from before the attendance calendar kept only the last check-in day.
	if int(state.get("presence_day", 0)) > 0:
		(state["presence_days"] as Dictionary)[str(int(state["presence_day"]))] = true
		state.erase("presence_day")
	state.erase("streak")


## Server clock; the dev day skip moves it forward.
func now() -> int:
	return int(Time.get_unix_time_from_system()) + int(state.get("dev_day_shift", 0)) * WorkCalendar.SECONDS_PER_DAY


func today() -> int:
	return WorkCalendar.day_of(now(), utc_offset())


func utc_offset() -> int:
	return WorkCalendar.local_offset()


## Every balance change goes through here and into the ledger. The balance never goes below zero.
func credit(amount: int, reason: String, reference: String) -> void:
	var balance: int = int(state["balance"])
	var applied: int = maxi(amount, -balance)
	state["balance"] = balance + applied
	(state["ledger"] as Array).append({"t": now(), "amount": applied, "reason": reason, "ref": reference})
	save()


## Idempotency: false when the operation key was already used.
func claim_key(operation_key: String) -> bool:
	var keys: Array = state["used_keys"]
	if operation_key.is_empty() or keys.has(operation_key):
		return false
	keys.append(operation_key)
	return true


## Adds a message to the player's inbox (the real server also sends a push notification).
func notify(kind: String, params: Dictionary, item_state: String = "") -> void:
	(state["inbox"] as Array).append({"id": next_id(), "kind": kind, "t": now(), "params": params, "read": false, "state": item_state})
	save()


func next_id() -> int:
	state["next_inbox_id"] = int(state["next_inbox_id"]) + 1
	return int(state["next_inbox_id"])


## Closes a task for `day` with its reward: completed list, daily earnings, history and ledger.
func grant_task(task: Dictionary, day: int, reward: int) -> void:
	var done: Array = list_of("completed", day)
	if not done.has(task["id"]):
		done.append(task["id"])
	list_of("pending", day).erase(task["id"])
	(state["earned"] as Dictionary)[str(day)] = int((state["earned"] as Dictionary).get(str(day), 0)) + reward
	list_of("task_log", day).append({"id": task["id"], "title": task["title"], "reward": reward})
	credit(reward, "task_reward", str(task["id"]))


## Coins the player can still earn on `day` before the daily cap.
func cap_left(day: int) -> int:
	return DAILY_COIN_CAP - int((state["earned"] as Dictionary).get(str(day), 0))


func log_suspicious(task_id: String, reason: String) -> void:
	(state["suspicious"] as Array).append({"t": now(), "task": task_id, "reason": reason})
	save()


## Per-day list of `key` (e.g. "completed") for `day`, created on first use.
func list_of(key: String, day: int) -> Array:
	var by_day: Dictionary = state[key]
	var day_key: String = str(day)
	if not by_day.has(day_key):
		by_day[day_key] = []
	return by_day[day_key]


func day_list(key: String) -> Array:
	return list_of(key, today())


## Per-day dictionary of `key` for today, created on first use.
func day_dict(key: String) -> Dictionary:
	var by_day: Dictionary = state[key]
	var day_key: String = str(today())
	if not by_day.has(day_key):
		by_day[day_key] = {}
	return by_day[day_key]


func is_present(day: int) -> bool:
	return (state["presence_days"] as Dictionary).has(str(day))


func streak() -> int:
	return Attendance.streak(state["presence_days"], state["excused_days"], today(), int(state["first_day"]))


## Reward multiplier of the streak as it will be once the player is in the office today.
func multiplier() -> float:
	var projected: int = streak() + (0 if is_present(today()) else 1)
	return clampf(1.0 + MULTIPLIER_STEP * (projected - 1), 1.0, MAX_MULTIPLIER)


func save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s: %s" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(state, "\t"))


static func find(items: Array, id: String) -> Dictionary:
	for item: Variant in items:
		if item is Dictionary and (item as Dictionary).get("id") == id:
			return item
	return {}


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
