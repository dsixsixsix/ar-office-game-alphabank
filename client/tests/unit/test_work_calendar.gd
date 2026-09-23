extends GdUnitTestSuite
## Formatting of the server's day numbers.

## 2026-09-14 is a Monday.
var _monday: int = WorkCalendar.day_from_date(2026, 9, 14)


func test_weekdays() -> void:
	assert_int(WorkCalendar.weekday(_monday)).is_equal(0)
	assert_int(WorkCalendar.weekday(WorkCalendar.day_from_date(2026, 9, 19))).is_equal(5)
	assert_bool(WorkCalendar.is_workday(_monday + 4)).is_true()
	assert_bool(WorkCalendar.is_workday(_monday + 5)).is_false()


func test_dates() -> void:
	assert_str(WorkCalendar.short_date(_monday)).is_equal("14.09")
	var date: Dictionary = WorkCalendar.date_of(_monday + 17)
	assert_int(int(date["month"])).is_equal(10)
	assert_int(int(date["day"])).is_equal(1)
