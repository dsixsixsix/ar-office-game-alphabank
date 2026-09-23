class_name CalendarHeatmap
extends Control
## Office attendance as a contribution-style grid: one column per week, Monday on top. Office days
## are red, days with three or more tasks are bright red. Tapping a day selects it.

signal day_selected(record: BackendModels.DayRecord)

const CELL: float = 11.0
const GAP: float = 2.0
const LEFT: float = 18.0
const TOP: float = 12.0
const BUSY_TASKS: int = 3
const OFFICE: Color = Color("#f5a39d")
const EMPTY: Color = Color("#e6e1da")
const WEEKEND: Color = Color("#f1ede7")

var days: Array[BackendModels.DayRecord] = []
var today: int = 0
var selected_day: int = -1


func setup(records: Array[BackendModels.DayRecord], p_today: int) -> void:
	days = records
	today = p_today
	selected_day = today
	var weeks: int = ceili(days.size() / 7.0)
	custom_minimum_size = Vector2(LEFT + weeks * (CELL + GAP), TOP + 7.0 * (CELL + GAP))
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


static func day_color(record: BackendModels.DayRecord) -> Color:
	if record.present:
		return UiStyle.RED if record.tasks.size() >= BUSY_TASKS else OFFICE
	return EMPTY if WorkCalendar.is_workday(record.day) else WEEKEND


func _cell_rect(index: int) -> Rect2:
	@warning_ignore("integer_division")
	var week: int = index / 7
	return Rect2(LEFT + week * (CELL + GAP), TOP + (index % 7) * (CELL + GAP), CELL, CELL)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var weekdays: PackedStringArray = tr("CAL_WEEKDAYS").split(",")
	var months: PackedStringArray = tr("CAL_MONTHS").split(",")
	for row: int in [0, 2, 4]:
		if row < weekdays.size():
			draw_string(font, Vector2(0, TOP + row * (CELL + GAP) + CELL - 2), weekdays[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiStyle.MUTED)
	for index: int in days.size():
		var record: BackendModels.DayRecord = days[index]
		var rect: Rect2 = _cell_rect(index)
		var date: Dictionary = WorkCalendar.date_of(record.day)
		if index % 7 == 0 and int(date["day"]) <= 7 and months.size() == 12:
			draw_string(font, Vector2(rect.position.x, TOP - 3), months[int(date["month"]) - 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiStyle.MUTED)
		draw_rect(rect, day_color(record))
		if record.day == today:
			draw_rect(rect.grow(-0.5), UiStyle.INK, false, 1.0)
		if record.day == selected_day:
			draw_rect(rect.grow(1.0), UiStyle.RED_DARK, false, 1.0)


func _gui_input(event: InputEvent) -> void:
	var press: Variant = Minigame.press_position(event)
	if press == null:
		return
	for index: int in days.size():
		if _cell_rect(index).grow(GAP / 2.0).has_point(press as Vector2):
			selected_day = days[index].day
			queue_redraw()
			day_selected.emit(days[index])
			accept_event()
			return
