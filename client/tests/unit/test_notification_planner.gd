extends GdUnitTestSuite
## Server plan of reminders, draw announcements and nudges.

## 2026-09-14 is a Monday; UTC+5 like Yekaterinburg.
const OFFSET: int = 5 * 3600
var _monday: int = WorkCalendar.day_from_date(2026, 9, 14)


func _facts(now_hour: int, present: bool, streak: int) -> Dictionary:
	return {
		"now": WorkCalendar.unix_at(_monday, now_hour, 0, OFFSET), "utc_offset": OFFSET, "today": _monday,
		"streak": streak, "present_today": present, "reminder_times": ["09:30", "14:00", "18:30"],
		"raffle_draw_at": 0, "fun_texts": [], "seed": "player",
	}


func _kinds(plan: Array[Dictionary], kind: String) -> Array[Dictionary]:
	return plan.filter(func(item: Dictionary) -> bool: return item["kind"] == kind)


func test_streak_reminders_until_check_in() -> void:
	var plan: Array[Dictionary] = NotificationPlanner.plan(_facts(12, false, 4))
	var today: Array[Dictionary] = _kinds(plan, "streak_reminder").filter(func(item: Dictionary) -> bool: return int(item["at"]) < WorkCalendar.unix_at(_monday + 1, 0, 0, OFFSET))
	# 09:30 is already past; 14:00 and 18:30 remain.
	assert_int(today.size()).is_equal(2)
	assert_int(int(today[0]["params"]["streak"])).is_equal(4)
	assert_str(str(today[0]["params"]["deadline"])).is_equal("23:59 14.09")


func test_no_reminder_after_check_in_but_tomorrow_is_planned() -> void:
	var plan: Array[Dictionary] = NotificationPlanner.plan(_facts(12, true, 5))
	var reminders: Array[Dictionary] = _kinds(plan, "streak_reminder")
	assert_bool(reminders.all(func(item: Dictionary) -> bool: return int(item["at"]) >= WorkCalendar.unix_at(_monday + 1, 0, 0, OFFSET))).is_true()
	assert_int(reminders.size()).is_equal(3)
	assert_int(int(reminders[0]["params"]["streak"])).is_equal(5)


func test_no_streak_gets_one_gentle_reminder() -> void:
	var plan: Array[Dictionary] = NotificationPlanner.plan(_facts(8, false, 0))
	assert_int(_kinds(plan, "streak_reminder").size()).is_equal(0)
	assert_int(_kinds(plan, "check_in_reminder").size()).is_equal(1)


func test_draw_is_announced_a_day_and_an_hour_before() -> void:
	var facts: Dictionary = _facts(12, true, 1)
	facts["raffle_draw_at"] = WorkCalendar.unix_at(_monday + 1, 18, 0, OFFSET)
	var plan: Array[Dictionary] = NotificationPlanner.plan(facts)
	var day: Array[Dictionary] = _kinds(plan, "raffle_day")
	var hour: Array[Dictionary] = _kinds(plan, "raffle_hour")
	assert_int(day.size()).is_equal(1)
	assert_int(hour.size()).is_equal(1)
	assert_int(int(day[0]["at"])).is_equal(WorkCalendar.unix_at(_monday, 18, 0, OFFSET))
	assert_str(str(day[0]["params"]["time"])).is_equal("18:00")


func test_one_or_two_nudges_a_day_inside_the_window() -> void:
	var facts: Dictionary = _facts(0, true, 1)
	facts["fun_texts"] = ["a", "b", "c"]
	facts["fun_window"] = ["11:00", "19:30"]
	var plan: Array[Dictionary] = NotificationPlanner.plan(facts)
	for day: int in [_monday, _monday + 1]:
		var nudges: Array[Dictionary] = _kinds(plan, "fun").filter(func(item: Dictionary) -> bool: return WorkCalendar.day_of(int(item["at"]), OFFSET) == day)
		assert_int(nudges.size()).is_between(0, 2)
		for item: Dictionary in nudges:
			assert_int(int(item["at"])).is_between(WorkCalendar.unix_at(day, 11, 0, OFFSET), WorkCalendar.unix_at(day, 19, 30, OFFSET))


func test_ids_are_stable_between_syncs() -> void:
	var first: Array[Dictionary] = NotificationPlanner.plan(_facts(8, false, 3))
	var second: Array[Dictionary] = NotificationPlanner.plan(_facts(8, false, 3))
	assert_int(first.size()).is_equal(second.size())
	for i: int in first.size():
		assert_int(int(first[i]["id"])).is_equal(int(second[i]["id"]))
