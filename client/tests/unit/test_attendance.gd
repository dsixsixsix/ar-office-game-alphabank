extends GdUnitTestSuite
## Office streak and progressive absence fines.

## 2026-09-14 is a Monday.
var _monday: int = WorkCalendar.day_from_date(2026, 9, 14)


func _days(offsets: Array) -> Dictionary:
	var result: Dictionary = {}
	for offset: Variant in offsets:
		result[str(_monday + int(offset))] = true
	return result


func test_calendar_weekdays() -> void:
	assert_int(WorkCalendar.weekday(_monday)).is_equal(0)
	assert_int(WorkCalendar.weekday(WorkCalendar.day_from_date(2026, 9, 19))).is_equal(5)
	assert_bool(WorkCalendar.is_workday(_monday + 4)).is_true()
	assert_bool(WorkCalendar.is_workday(_monday + 5)).is_false()
	assert_int(WorkCalendar.previous_workday(_monday)).is_equal(_monday - 3)
	assert_int(WorkCalendar.last_friday_of_month(_monday)).is_equal(WorkCalendar.day_from_date(2026, 9, 25))
	assert_int(WorkCalendar.last_friday_of_month(WorkCalendar.day_from_date(2026, 10, 1))).is_equal(WorkCalendar.day_from_date(2026, 10, 30))


func test_streak_skips_weekends_and_waits_for_today() -> void:
	var presence: Dictionary = _days([-3, 0, 1, 2])
	# Friday before, then Monday to Wednesday: weekends do not break the streak.
	assert_int(Attendance.streak(presence, {}, _monday + 2, _monday - 30)).is_equal(4)
	# Thursday without a check-in yet: the streak is still alive.
	assert_int(Attendance.streak(presence, {}, _monday + 3, _monday - 30)).is_equal(4)
	# Friday: Thursday was missed.
	assert_int(Attendance.streak(presence, {}, _monday + 4, _monday - 30)).is_equal(0)


func test_excused_days_do_not_break_the_streak() -> void:
	var presence: Dictionary = _days([0, 2])
	assert_int(Attendance.streak(presence, _days([1]), _monday + 2, _monday - 30)).is_equal(2)
	assert_int(Attendance.missed_in_row(presence, _days([1]), _monday + 1, _monday - 30)).is_equal(0)


func test_missed_days_in_a_row() -> void:
	var presence: Dictionary = _days([0])
	assert_int(Attendance.missed_in_row(presence, {}, _monday + 3, _monday - 30)).is_equal(3)
	# Weekend days are not counted.
	assert_int(Attendance.missed_in_row(presence, {}, _monday + 7, _monday - 30)).is_equal(5)
	# Nothing before registration counts.
	assert_int(Attendance.missed_in_row({}, {}, _monday + 1, _monday)).is_equal(2)


func test_fine_grows_with_missed_days() -> void:
	var tiers: Array = [{"days": 2, "percent": 3}, {"days": 3, "percent": 5}, {"days": 5, "percent": 10}, {"days": 10, "percent": 15}]
	assert_int(Attendance.fine_percent(1, tiers)).is_equal(0)
	assert_int(Attendance.fine_percent(2, tiers)).is_equal(3)
	assert_int(Attendance.fine_percent(4, tiers)).is_equal(5)
	assert_int(Attendance.fine_percent(9, tiers)).is_equal(10)
	assert_int(Attendance.fine_percent(30, tiers)).is_equal(15)


func test_fine_rounds_up_and_never_goes_below_zero() -> void:
	assert_int(Attendance.fine_amount(1000, 3)).is_equal(30)
	assert_int(Attendance.fine_amount(970, 5)).is_equal(49)
	assert_int(Attendance.fine_amount(1, 3)).is_equal(1)
	assert_int(Attendance.fine_amount(0, 15)).is_equal(0)
	assert_int(Attendance.fine_amount(10, 100)).is_equal(10)
	assert_int(Attendance.fine_amount(500, 0)).is_equal(0)
