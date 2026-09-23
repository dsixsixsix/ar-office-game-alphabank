class_name Attendance
extends RefCounted
## Office attendance rules shared by the server and its tests: the streak of office days and the
## progressive fine for workdays missed in a row.
## `presence` and `excused` are sets of day numbers stored as {"<day>": true} (JSON-friendly).
## Excused days (vacation, sick leave, business trip) are set by an admin and count as neither
## present nor missed.


## Consecutive office workdays ending today or, when today is not counted yet, on the previous
## workday. Today without a check-in does not break the streak: the player still has time.
static func streak(presence: Dictionary, excused: Dictionary, today: int, first_day: int) -> int:
	var day: int = today
	if not presence.has(str(today)):
		day = today - 1
	var count: int = 0
	while day >= first_day:
		var key: String = str(day)
		if presence.has(key):
			count += 1
		elif WorkCalendar.is_workday(day) and not excused.has(key):
			break
		day -= 1
	return count


## Number of workdays missed in a row, ending with `day` inclusive. Days before `first_day`
## (registration) never count.
static func missed_in_row(presence: Dictionary, excused: Dictionary, day: int, first_day: int) -> int:
	var count: int = 0
	var current: int = day
	while current >= first_day:
		var key: String = str(current)
		if presence.has(key):
			break
		if WorkCalendar.is_workday(current) and not excused.has(key):
			count += 1
		current -= 1
	return count


## Fine rate for the n-th workday missed in a row. `tiers` = [{"days": 2, "percent": 3}, ...]:
## each tier applies from its number of days; the last matching tier wins.
static func fine_percent(missed: int, tiers: Array) -> int:
	var percent: int = 0
	var best_days: int = 0
	for entry: Variant in tiers:
		var tier: Dictionary = entry
		var days: int = int(tier.get("days", 0))
		if missed >= days and days >= best_days:
			best_days = days
			percent = int(tier.get("percent", 0))
	return clampi(percent, 0, 100)


## Coins to take: `percent` of the balance rounded up, so the balance stays a whole number, and never
## more than the balance, so it cannot go below zero.
static func fine_amount(balance: int, percent: int) -> int:
	if balance <= 0 or percent <= 0:
		return 0
	@warning_ignore("integer_division")
	var amount: int = (balance * percent + 99) / 100
	return mini(amount, balance)
