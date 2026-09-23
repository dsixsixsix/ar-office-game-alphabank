class_name WorkCalendar
extends RefCounted
## Office days. A day number is a local calendar day counted from 1970-01-01 (a Thursday).
## Monday to Friday are workdays; weekends never break a streak and are never fined.

const SECONDS_PER_DAY: int = 86400


## 0 = Monday ... 6 = Sunday.
static func weekday(day: int) -> int:
	return posmod(day + 3, 7)


static func is_workday(day: int) -> bool:
	return weekday(day) < 5


static func previous_workday(day: int) -> int:
	var result: int = day - 1
	while not is_workday(result):
		result -= 1
	return result


static func next_workday(day: int) -> int:
	var result: int = day + 1
	while not is_workday(result):
		result += 1
	return result


## Local day of a unix time for a time zone `utc_offset` seconds east of UTC.
static func day_of(unix_time: int, utc_offset: int) -> int:
	return floori(float(unix_time + utc_offset) / SECONDS_PER_DAY)


## Unix time of a local wall-clock time on `day`.
static func unix_at(day: int, hour: int, minute: int, utc_offset: int) -> int:
	return day * SECONDS_PER_DAY - utc_offset + hour * 3600 + minute * 60


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


## Last day number of the month that contains `day`.
static func last_day_of_month(day: int) -> int:
	var date: Dictionary = date_of(day)
	var year: int = int(date["year"])
	var month: int = int(date["month"])
	if month == 12:
		return day_from_date(year + 1, 1, 1) - 1
	return day_from_date(year, month + 1, 1) - 1


## Last Friday of the month that contains `day`.
static func last_friday_of_month(day: int) -> int:
	var result: int = last_day_of_month(day)
	while weekday(result) != 4:
		result -= 1
	return result


## Local offset of this device from UTC, in seconds.
static func local_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## "19.09 14:05" in the device's time zone.
static func stamp(unix_time: int) -> String:
	var offset: int = local_offset()
	var local: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + offset)
	return "%02d.%02d %02d:%02d" % [int(local["day"]), int(local["month"]), int(local["hour"]), int(local["minute"])]
