class_name NotificationPlanner
extends RefCounted
## Server rules for scheduled notifications (reminders, draw announcements, light-hearted nudges).
## Returns a plan for the next days; the client hands it to the OS scheduler and replaces it on every
## sync, so a stale plan never outlives the next launch. Event notifications (a won draw, a photo to
## confirm, a lost streak) are not planned: the server pushes them when they happen.
##
## `facts` keys:
##   now, utc_offset, today            clock of the player
##   streak, present_today             attendance
##   reminder_times                    ["09:30", "14:00"] local times of streak reminders
##   raffle_draw_at, raffle_joined     next draw (0 = none) and whether the player has a ticket
##   fun_texts, fun_window, fun_max    nudges: texts, ["12:00", "19:00"], at most this many a day
##   seed                              per-player salt so nudges do not arrive at the same minute for everyone
##
## Plan item: {"id": int, "at": unix time, "kind": String, "params": Dictionary}.

const HORIZON_DAYS: int = 2
const DAY_END_HOUR: int = 23
const DAY_END_MINUTE: int = 59
## Nudges keep this distance from other notifications of the plan.
const MIN_GAP_SECONDS: int = 3600


static func plan(facts: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var today: int = int(facts["today"])
	for offset: int in HORIZON_DAYS:
		_plan_streak(facts, today + offset, result)
	_plan_raffle(facts, result)
	for offset: int in HORIZON_DAYS:
		_plan_fun(facts, today + offset, result)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["at"]) < int(b["at"]))
	return result


## Workday reminders to check in before the day ends. Tomorrow's reminder is planned only when the
## streak is already safe today; otherwise the next sync (or the "streak lost" push) replaces it.
## `streak` already counts today once the player has checked in.
static func _plan_streak(facts: Dictionary, day: int, result: Array[Dictionary]) -> void:
	if not WorkCalendar.is_workday(day):
		return
	var today: int = int(facts["today"])
	var present_today: bool = bool(facts.get("present_today", false))
	var streak: int = int(facts.get("streak", 0))
	if day == today and present_today:
		return
	if day > today and not present_today and WorkCalendar.is_workday(today):
		return
	var offset: int = int(facts["utc_offset"])
	var deadline: int = WorkCalendar.unix_at(day, DAY_END_HOUR, DAY_END_MINUTE, offset)
	var deadline_text: String = "%02d:%02d %s" % [DAY_END_HOUR, DAY_END_MINUTE, WorkCalendar.short_date(day)]
	var times: Array = facts.get("reminder_times", [])
	for index: int in times.size():
		var clock: Vector2i = parse_clock(str(times[index]))
		var at: int = WorkCalendar.unix_at(day, clock.x, clock.y, offset)
		if at <= int(facts["now"]) or at >= deadline:
			continue
		if streak > 0:
			_add(result, "streak_reminder", day, index, at, {"streak": streak, "deadline": deadline_text})
		elif index == 0:
			# Without a streak one gentle reminder a day is enough.
			_add(result, "check_in_reminder", day, index, at, {"deadline": deadline_text})


static func _plan_raffle(facts: Dictionary, result: Array[Dictionary]) -> void:
	var draw_at: int = int(facts.get("raffle_draw_at", 0))
	if draw_at <= 0:
		return
	var offset: int = int(facts["utc_offset"])
	var draw_day: int = WorkCalendar.day_of(draw_at, offset)
	var local_seconds: int = posmod(draw_at + offset, WorkCalendar.SECONDS_PER_DAY)
	@warning_ignore("integer_division")
	var time_text: String = "%02d:%02d" % [local_seconds / 3600, local_seconds / 60 % 60]
	var params: Dictionary = {"time": time_text, "date": WorkCalendar.short_date(draw_day), "joined": bool(facts.get("raffle_joined", false))}
	for entry: Array in [["raffle_day", 86400], ["raffle_hour", 3600]]:
		var at: int = draw_at - int(entry[1])
		if at > int(facts["now"]):
			_add(result, str(entry[0]), draw_day, 0, at, params)


## One or two light-hearted messages a day at random minutes inside the window, away from the
## other notifications of the plan.
static func _plan_fun(facts: Dictionary, day: int, result: Array[Dictionary]) -> void:
	var texts: Array = facts.get("fun_texts", [])
	var window: Array = facts.get("fun_window", ["12:00", "19:00"])
	var max_count: int = int(facts.get("fun_max", 2))
	if texts.is_empty() or max_count <= 0 or window.size() != 2:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("fun|%s|%d" % [str(facts.get("seed", "")), day])
	var offset: int = int(facts["utc_offset"])
	var start_clock: Vector2i = parse_clock(str(window[0]))
	var end_clock: Vector2i = parse_clock(str(window[1]))
	var start: int = WorkCalendar.unix_at(day, start_clock.x, start_clock.y, offset)
	var end: int = WorkCalendar.unix_at(day, end_clock.x, end_clock.y, offset)
	@warning_ignore("integer_division")
	var minutes: int = maxi(0, (end - start) / 60)
	var count: int = rng.randi_range(1, max_count)
	var used: Array[int] = []
	for index: int in count:
		var at: int = start + rng.randi_range(0, minutes) * 60
		var text_index: int = rng.randi_range(0, texts.size() - 1)
		if used.has(text_index):
			text_index = (text_index + 1) % texts.size()
		used.append(text_index)
		if at <= int(facts["now"]) or not _is_free(result, at):
			continue
		_add(result, "fun", day, index, at, {"text": str(texts[text_index])})


static func _is_free(result: Array[Dictionary], at: int) -> bool:
	for item: Dictionary in result:
		if absi(int(item["at"]) - at) < MIN_GAP_SECONDS:
			return false
	return true


static func _add(result: Array[Dictionary], kind: String, day: int, index: int, at: int, params: Dictionary) -> void:
	result.append({"id": notification_id(kind, day, index), "at": at, "kind": kind, "params": params})


## Stable positive id, so rescheduling replaces a notification instead of duplicating it.
static func notification_id(kind: String, day: int, index: int) -> int:
	return hash("%s|%d|%d" % [kind, day, index]) & 0x7fffffff


## "09:30" -> Vector2i(9, 30).
static func parse_clock(text: String) -> Vector2i:
	var parts: PackedStringArray = text.split(":")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(clampi(parts[0].to_int(), 0, 23), clampi(parts[1].to_int(), 0, 59))
