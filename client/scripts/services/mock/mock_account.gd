class_name MockAccount
extends RefCounted
## DEV-ONLY part of the mock server about the player's account: absence fines and the office
## streak, the profile (name, department, status, avatar) and the profile page with the attendance
## calendar and task history.

const MAX_STATUS_LENGTH: int = 60
const AVATAR_MAX_BYTES: int = 64 * 1024
## Attendance calendar on the profile page: whole weeks, Monday first.
const CALENDAR_WEEKS: int = 18
## The account name comes from the corporate directory on the real server.
const DEFAULT_NAME: String = "Сотрудник Альфы"

var _store: MockStore


func _init(store: MockStore) -> void:
	_store = store


## Fines every workday missed in a row since the last run: the first missed day only breaks the
## streak, later ones take a growing share of the balance (Attendance.fine_percent). The real
## server runs this as a nightly job.
func process_absences() -> void:
	var state: Dictionary = _store.state
	var today: int = _store.today()
	var first_day: int = int(state["first_day"])
	var attendance: Dictionary = _store.rules.get("attendance", {})
	var start: int = maxi(maxi(int(state["processed_day"]) + 1, first_day), today - int(attendance.get("max_catch_up_days", 60)))
	var presence: Dictionary = state["presence_days"]
	var excused: Dictionary = state["excused_days"]
	var report: Dictionary = state["morning_report"]
	for day: int in range(start, today):
		var key: String = str(day)
		if not WorkCalendar.is_workday(day) or presence.has(key) or excused.has(key):
			continue
		var missed: int = Attendance.missed_in_row(presence, excused, day, first_day)
		if missed == 1:
			var lost: int = Attendance.streak(presence, excused, day - 1, first_day)
			if lost > 0:
				_store.notify("streak_reset", {"streak": lost, "date": WorkCalendar.short_date(day)})
				report["lost_streak"] = maxi(int(report.get("lost_streak", 0)), lost)
		var percent: int = Attendance.fine_percent(missed, attendance.get("fine_tiers", []))
		var amount: int = Attendance.fine_amount(int(state["balance"]), percent)
		if amount > 0:
			_store.credit(-amount, "absence_fine", "day:%d" % day)
			_store.notify("penalty", {"amount": amount, "missed": missed, "percent": percent, "date": WorkCalendar.short_date(day)})
			report["fined"] = int(report.get("fined", 0)) + amount
	if start < today:
		state["processed_day"] = today - 1
		_store.save()


## Called on check-in: remembers the best streak for the profile and streak-locked wardrobe items.
func record_check_in() -> void:
	var today: int = _store.today()
	(_store.state["presence_days"] as Dictionary)[str(today)] = true
	(_store.state["checkin_at"] as Dictionary)[str(today)] = _store.now()
	_store.state["best_streak"] = maxi(int(_store.state["best_streak"]), _store.streak())
	_store.save()


func best_streak() -> int:
	return maxi(int(_store.state["best_streak"]), _store.streak())


func profile() -> BackendModels.Profile:
	var result: BackendModels.Profile = BackendModels.Profile.new()
	var settings: Dictionary = _store.state["profile"]
	result.user_id = MockStore.PLAYER_ID
	result.display_name = str(settings.get("name", DEFAULT_NAME))
	result.department = _store.player_department
	result.status = str(settings.get("status", ""))
	result.avatar = str(settings.get("avatar", AvatarCatalog.DEFAULT))
	result.streak_days = _store.streak()
	result.present_today = _store.is_present(_store.today())
	result.multiplier = _store.multiplier()
	result.balance = int(_store.state["balance"])
	return result


func get_profile_page() -> BackendModels.ProfilePage:
	var state: Dictionary = _store.state
	var page: BackendModels.ProfilePage = BackendModels.ProfilePage.new()
	page.profile = profile()
	var today: int = _store.today()
	page.today = today
	var presence: Dictionary = state["presence_days"]
	page.office_days_total = presence.size()
	page.best_streak = best_streak()
	for day_key: Variant in state["completed"]:
		page.tasks_total += ((state["completed"] as Dictionary)[day_key] as Array).size()
	for entry: Variant in state["ledger"]:
		var line: Dictionary = entry
		if line["reason"] == "task_reward" and int(line["amount"]) > 0:
			page.coins_earned_total += int(line["amount"])
	var start: int = today - WorkCalendar.weekday(today) - (CALENDAR_WEEKS - 1) * 7
	for day: int in range(start, today + 1):
		page.days.append(_day_record(day))
	return page


func _day_record(day: int) -> BackendModels.DayRecord:
	var record: BackendModels.DayRecord = BackendModels.DayRecord.new()
	record.day = day
	record.present = _store.is_present(day)
	var logged: Array = (_store.state["task_log"] as Dictionary).get(str(day), [])
	for entry: Variant in logged:
		var line: Dictionary = entry
		record.tasks.append({"title": str(line["title"]), "reward": int(line["reward"])})
		record.earned += int(line["reward"])
	if logged.is_empty():
		# Days from before the task log: titles only.
		for task_id: Variant in (_store.state["completed"] as Dictionary).get(str(day), []):
			record.tasks.append({"title": str(MockStore.find(_store.tasks, str(task_id)).get("title", task_id)), "reward": 0})
	return record


func set_status(text: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var clean: String = ""
	for character: String in text.strip_edges():
		# Control characters and line breaks would break the one-line status.
		if character.unicode_at(0) >= 0x20:
			clean += character
	if clean.length() > MAX_STATUS_LENGTH:
		result.error = "status_too_long"
		return result
	(_store.state["profile"] as Dictionary)["status"] = clean
	_store.save()
	result.ok = true
	return result


func set_avatar(avatar_id: String) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	if avatar_id == AvatarCatalog.CUSTOM:
		if str(_store.state.get("custom_avatar", "")).is_empty():
			result.error = "avatar_missing"
			return result
	elif not AvatarCatalog.TEMPLATES.has(avatar_id):
		result.error = "unknown_avatar"
		return result
	(_store.state["profile"] as Dictionary)["avatar"] = avatar_id
	_store.save()
	result.ok = true
	return result


## Own picture: a small square PNG. The server re-checks size and format; the real one also queues it
## for moderation before other players can see it.
func upload_avatar(png: PackedByteArray) -> BackendModels.ActionResult:
	var result: BackendModels.ActionResult = BackendModels.ActionResult.new()
	var image: Image = Image.new()
	if png.is_empty() or png.size() > AVATAR_MAX_BYTES:
		result.error = "avatar_too_big"
	elif image.load_png_from_buffer(png) != OK:
		result.error = "avatar_invalid"
	elif image.get_width() != AvatarCatalog.CUSTOM_SIZE or image.get_height() != AvatarCatalog.CUSTOM_SIZE:
		result.error = "avatar_invalid"
	if not result.error.is_empty():
		return result
	_store.state["custom_avatar"] = Marshalls.raw_to_base64(png)
	(_store.state["profile"] as Dictionary)["avatar"] = AvatarCatalog.CUSTOM
	_store.save()
	result.ok = true
	return result


## PNG of a player's uploaded picture; empty when there is none.
func get_avatar_png(user_id: String) -> PackedByteArray:
	if user_id != MockStore.PLAYER_ID:
		return PackedByteArray()
	var encoded: String = str(_store.state.get("custom_avatar", ""))
	return PackedByteArray() if encoded.is_empty() else Marshalls.base64_to_raw(encoded)
