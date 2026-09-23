class_name MockSocial
extends RefCounted
## DEV-ONLY part of the mock server about other players: who is in the office today (rolled per
## day from res://data/colleagues.json), colleagues picked for tasks, checks of the meet-a-colleague
## tasks, joint photo confirmations in both directions, and the inbox.

const PHOTO_MINIGAME: String = "selfie"
const MEET_MINIGAME: String = "meet_colleague"
const BINGO_MINIGAME: String = "colleague_bingo"
const MIN_PHOTO_FACES: int = 2

var _store: MockStore


func _init(store: MockStore) -> void:
	_store = store


# --- Colleagues ------------------------------------------------------------------


## Picks the colleague for a task that needs one: someone in the office today (and from another
## department when the task says so) whom the player has not met in a task today. The choice is kept
## for the day while that colleague stays in the office.
func assign_colleague(task_id: String) -> BackendModels.ColleagueResult:
	var result: BackendModels.ColleagueResult = BackendModels.ColleagueResult.new()
	var task: Dictionary = MockStore.find(_store.tasks, task_id)
	var kind: String = str(task.get("assignment", ""))
	if task.is_empty() or kind.is_empty():
		result.error = "unknown_task"
		return result
	if not _store.is_present(_store.today()):
		result.error = "presence_required"
		return result
	var today: int = _store.today()
	var assignments: Dictionary = _store.day_dict("assignments")
	var current: Dictionary = find_colleague(str(assignments.get(task_id, "")))
	if current.is_empty() or not colleague_present(current, today):
		var candidates: Array = _store.colleagues.filter(func(colleague: Dictionary) -> bool:
			return (
				colleague_present(colleague, today) and not _store.day_list("colleagues").has(colleague["id"])
				and (kind != "other_department" or str(colleague["department"]) != _store.player_department)
			)
		)
		if candidates.is_empty():
			result.error = "no_colleague_available"
			return result
		current = candidates[randi() % candidates.size()]
		assignments[task_id] = current["id"]
		_store.save()
	result.ok = true
	result.colleague = colleague_info(current)
	return result


## Public card of another player, e.g. after scanning their profile code. Null when unknown.
func lookup_colleague(user_id: String) -> BackendModels.Colleague:
	var colleague: Dictionary = find_colleague(user_id)
	return null if colleague.is_empty() else colleague_info(colleague)


## DEV: every simulated colleague, for the desktop QR emulator.
func list_colleagues() -> Array[BackendModels.Colleague]:
	var result: Array[BackendModels.Colleague] = []
	for colleague: Variant in _store.colleagues:
		result.append(colleague_info(colleague))
	return result


func find_colleague(user_id: String) -> Dictionary:
	return MockStore.find(_store.colleagues, user_id)


## Simulated check-in of another player: rolled once per day from their `presence` chance.
func colleague_present(colleague: Dictionary, day: int) -> bool:
	if colleague.is_empty():
		return false
	return absi(hash("%s|%d" % [colleague["id"], day])) % 100 < roundi(float(colleague.get("presence", 0.0)) * 100.0)


func colleague_info(data: Dictionary) -> BackendModels.Colleague:
	var info: BackendModels.Colleague = BackendModels.Colleague.new()
	info.user_id = data["id"]
	info.name = data["name"]
	info.department = data["department"]
	info.avatar = str(data.get("look", ""))
	info.status = str(data.get("status", ""))
	info.floor_id = StringName(str(data.get("floor", OfficeFloors.HQ)))
	info.room = StringName(str(data.get("room", "")))
	info.present = colleague_present(data, _store.today())
	return info


# --- Task checks -----------------------------------------------------------------


## Why a social task can't be completed with this proof, or "" when it can.
func verify(task: Dictionary, proof: Dictionary) -> String:
	match str(task["minigame"]):
		PHOTO_MINIGAME:
			return _verify_photo(task, proof)
		MEET_MINIGAME:
			return _verify_meeting(task, proof)
		BINGO_MINIGAME:
			return _verify_bingo(task, proof)
	return ""


## Colleagues met in a completed task; each can be met in one task a day.
func remember_met(task: Dictionary, proof: Dictionary) -> void:
	var met: Array = _store.day_list("colleagues")
	match str(task["minigame"]):
		MEET_MINIGAME:
			met.append(str(proof.get("colleague_id", "")))
		BINGO_MINIGAME:
			for entry: Variant in proof.get("colleague_ids", []):
				met.append(str(entry))


## Joint photo: the colleague the server assigned, still in the office, and two faces in the frame.
func _verify_photo(task: Dictionary, proof: Dictionary) -> String:
	var partner_id: String = str(proof.get("partner_id", ""))
	if partner_id.is_empty() or partner_id != _assigned(str(task["id"])):
		return "colleague_not_assigned"
	if not colleague_present(find_colleague(partner_id), _store.today()):
		return "colleague_not_present"
	if int(proof.get("faces", 0)) < MIN_PHOTO_FACES:
		return "not_enough_faces"
	return ""


## Meeting a colleague: their profile code was scanned. An assigned colleague must match; otherwise
## anyone present from another department who has not been met today, within the task's hours.
func _verify_meeting(task: Dictionary, proof: Dictionary) -> String:
	var colleague_id: String = str(proof.get("colleague_id", ""))
	var kind: String = str(task.get("assignment", ""))
	if not kind.is_empty() and colleague_id != _assigned(str(task["id"])):
		return "colleague_not_assigned"
	var error: String = _verify_colleague(colleague_id, kind != "present_colleague")
	if not error.is_empty():
		return error
	var window: Array = (task.get("params", {}) as Dictionary).get("window", [])
	if window.size() == 2 and not _in_window(window):
		return "outside_time_window"
	return ""


## Bingo: `count` different colleagues, each from another department and each department once.
func _verify_bingo(task: Dictionary, proof: Dictionary) -> String:
	var needed: int = int((task.get("params", {}) as Dictionary).get("count", 3))
	var departments: Array[String] = []
	var seen: Array[String] = []
	for entry: Variant in proof.get("colleague_ids", []):
		var colleague_id: String = str(entry)
		var error: String = "colleague_already_used" if seen.has(colleague_id) else _verify_colleague(colleague_id, true)
		if error.is_empty() and departments.has(str(find_colleague(colleague_id)["department"])):
			error = "same_department_twice"
		if not error.is_empty():
			return error
		seen.append(colleague_id)
		departments.append(str(find_colleague(colleague_id)["department"]))
	return "" if seen.size() >= needed else "not_enough_colleagues"


func _verify_colleague(colleague_id: String, other_department: bool) -> String:
	var payload: QrPayload = QrPayload.parse(QrPayload.user(colleague_id))
	var colleague: Dictionary = find_colleague(colleague_id)
	var error: String = ""
	if not payload.is_valid() or colleague_id == MockStore.PLAYER_ID or colleague.is_empty():
		error = "colleague_invalid"
	elif other_department and str(colleague["department"]) == _store.player_department:
		error = "same_department"
	elif not colleague_present(colleague, _store.today()):
		error = "colleague_not_present"
	elif _store.day_list("colleagues").has(colleague_id):
		error = "colleague_already_used"
	return error


func _assigned(task_id: String) -> String:
	return str(_store.day_dict("assignments").get(task_id, ""))


func _in_window(window: Array) -> bool:
	var start: Vector2i = NotificationPlanner.parse_clock(str(window[0]))
	var end: Vector2i = NotificationPlanner.parse_clock(str(window[1]))
	var now: int = _store.now()
	var today: int = _store.today()
	var offset: int = _store.utc_offset()
	return now >= WorkCalendar.unix_at(today, start.x, start.y, offset) and now < WorkCalendar.unix_at(today, end.x, end.y, offset)


# --- Joint photo confirmations ------------------------------------------------------


## The player's photo waits for the colleague: the task is pending until they answer.
## Returns the colleague's name.
func submit_photo(task: Dictionary, proof: Dictionary, reward: int) -> String:
	var partner: Dictionary = find_colleague(str(proof["partner_id"]))
	var today: int = _store.today()
	_store.day_list("colleagues").append(str(partner["id"]))
	_store.day_list("pending").append(task["id"])
	(_store.state["photo_requests"] as Array).append({
		"id": _store.next_id(), "day": today, "task": task["id"], "partner": partner["id"], "t": _store.now(),
		"state": "pending", "reward": reward,
	})
	_store.save()
	return str(partner["name"])


## Simulates the other phones: the colleague answers the player's photo request after a delay
## (always "yes" in the mock), and once a day a present colleague asks the player to confirm a photo.
## Unanswered requests expire at the end of the day.
func simulate() -> void:
	var photo: Dictionary = _store.rules.get("photo", {})
	var now: int = _store.now()
	var today: int = _store.today()
	for entry: Variant in _store.state["photo_requests"]:
		var request: Dictionary = entry
		if request["state"] != "pending":
			continue
		if int(request["day"]) != today:
			request["state"] = "expired"
			_store.list_of("pending", int(request["day"])).erase(request["task"])
		elif now - int(request["t"]) >= int(photo.get("mock_confirm_seconds", 20)):
			_resolve_photo_request(request, true)
	var checked_in: int = int((_store.state["checkin_at"] as Dictionary).get(str(today), 0))
	if checked_in > 0 and not (_store.state["incoming_sent"] as Dictionary).has(str(today)):
		if now - checked_in >= int(photo.get("mock_incoming_after_seconds", 90)):
			dev_incoming_photo_request()
	for entry: Variant in _store.state["inbox"]:
		var item: Dictionary = entry
		if item["kind"] == "photo_request" and item["state"] == "pending" and int((item["params"] as Dictionary).get("day", today)) != today:
			item["state"] = "expired"
	_store.save()


func _resolve_photo_request(request: Dictionary, confirmed: bool) -> void:
	var task: Dictionary = MockStore.find(_store.tasks, str(request["task"]))
	var partner: Dictionary = find_colleague(str(request["partner"]))
	var day: int = int(request["day"])
	request["state"] = "confirmed" if confirmed else "declined"
	if not confirmed:
		_store.list_of("pending", day).erase(task["id"])
		_store.notify("photo_declined", {"name": partner.get("name", "")})
		_store.log_suspicious(str(task["id"]), "photo_declined_by_partner")
		return
	var reward: int = maxi(0, mini(int(request["reward"]), _store.cap_left(day)))
	_store.grant_task(task, day, reward)
	_store.notify("photo_confirmed", {"name": partner.get("name", ""), "reward": reward})


## Answer to "<colleague> took a photo with you, is it true?". Confirming pays a small bonus; declining
## marks the colleague's attempt as suspicious for the admin.
func respond_photo_request(item_id: int, confirm: bool, operation_key: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	if not _store.claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var item: Dictionary = {}
	for entry: Variant in _store.state["inbox"]:
		if int((entry as Dictionary)["id"]) == item_id:
			item = entry
	if item.is_empty() or item["kind"] != "photo_request":
		result.error = "unknown_request"
		return result
	if item["state"] != "pending":
		result.error = "request_closed"
		return result
	item["state"] = "confirmed" if confirm else "declined"
	item["read"] = true
	var from_id: String = str((item["params"] as Dictionary).get("from_id", ""))
	if confirm:
		var today: int = _store.today()
		var bonus: int = mini(int((_store.rules.get("photo", {}) as Dictionary).get("partner_bonus", 10)), maxi(0, _store.cap_left(today)))
		if bonus > 0:
			(_store.state["earned"] as Dictionary)[str(today)] = int((_store.state["earned"] as Dictionary).get(str(today), 0)) + bonus
			_store.credit(bonus, "photo_partner_bonus", from_id)
	else:
		_store.log_suspicious(PHOTO_MINIGAME, "photo_denied:" + from_id)
	_store.save()
	result.ok = true
	return result


## DEV: a present colleague "took a photo with the player" and asks to confirm it. False when nobody
## is in the office.
func dev_incoming_photo_request() -> bool:
	var today: int = _store.today()
	(_store.state["incoming_sent"] as Dictionary)[str(today)] = true
	var present: Array = _store.colleagues.filter(func(colleague: Dictionary) -> bool: return colleague_present(colleague, today))
	if present.is_empty():
		_store.save()
		return false
	var colleague: Dictionary = present[randi() % present.size()]
	_store.notify("photo_request", {"from_id": colleague["id"], "name": colleague["name"], "avatar": colleague.get("look", ""), "day": today}, "pending")
	return true


# --- Inbox -----------------------------------------------------------------------


## Newest first.
func get_inbox() -> Array[BackendModels.InboxItem]:
	var result: Array[BackendModels.InboxItem] = []
	var items: Array = _store.state["inbox"]
	for index: int in range(items.size() - 1, -1, -1):
		var data: Dictionary = items[index]
		var item: BackendModels.InboxItem = BackendModels.InboxItem.new()
		item.id = int(data["id"])
		item.kind = data["kind"]
		item.created_at = int(data["t"])
		item.params = data["params"]
		item.read = bool(data["read"])
		item.state = str(data.get("state", ""))
		result.append(item)
	return result


## Everything except unanswered photo requests.
func mark_inbox_read() -> void:
	for entry: Variant in _store.state["inbox"]:
		var item: Dictionary = entry
		if item["kind"] != "photo_request" or item["state"] != "pending":
			item["read"] = true
	_store.save()
