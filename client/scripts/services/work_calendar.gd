class_name WorkCalendar
extends RefCounted
## Display of office days. A day number is a calendar day counted from 1970-01-01 (a Thursday) in the
## office time zone; the server sends day numbers (profile calendar), the client only formats them.
## Monday to Friday are workdays.

const SECONDS_PER_DAY: int = 86400


## 0 = Monday ... 6 = Sunday.
static func weekday(day: int) -> int:
	return posmod(day + 3, 7)


static func is_workday(day: int) -> bool:
	return weekday(day) < 5


## {"year", "month", "day"} of a day number.
static func date_of(day: int) -> Dictionary:
	return Time.get_date_dict_from_unix_time(day * SECONDS_PER_DAY)


## "19.09".
static func short_date(day: int) -> String:
	var date: Dictionary = date_of(day)
	return "%02d.%02d" % [int(date["day"]), int(date["month"])]


static func day_from_date(year: int, month: int, day_of_month: int) -> int:
	var unix: int = Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day_of_month, "hour": 0, "minute": 0, "second": 0})
	return floori(float(unix) / SECONDS_PER_DAY)


## Local offset of this device from UTC, in seconds.
static func local_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## "19.09 14:05" in the device's time zone.
static func stamp(unix_time: int) -> String:
	var offset: int = local_offset()
	var local: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + offset)
	return "%02d.%02d %02d:%02d" % [int(local["day"]), int(local["month"]), int(local["hour"]), int(local["minute"])]
