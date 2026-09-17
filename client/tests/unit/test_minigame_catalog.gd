extends GdUnitTestSuite
## Every task in the mock content points at an existing minigame, and fallbacks need no sensors.

const TASKS_PATH: String = "res://data/tasks.json"
const SCREEN_ONLY: Array[String] = ["check_in", "coffee", "bubble_wrap", "paper_sort", "alfa_red"]


func _tasks() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TASKS_PATH))
	return (parsed as Dictionary)["tasks"]


func test_tasks_use_known_minigames() -> void:
	for entry: Variant in _tasks():
		var task: Dictionary = entry
		var kind: String = task["minigame"]
		assert_bool(Minigame.REQUIRED_FEATURES.has(kind) or SCREEN_ONLY.has(kind)).override_failure_message(kind).is_true()
		var fallback: String = str(task.get("fallback", ""))
		if not fallback.is_empty():
			assert_bool(SCREEN_ONLY.has(fallback)).override_failure_message(fallback).is_true()
			assert_array(Minigame.required_features(fallback)).is_empty()


func test_physical_minigames_are_created() -> void:
	for kind: String in Minigame.REQUIRED_FEATURES:
		var game: Minigame = auto_free(Minigame.create(kind))
		assert_bool(game is CheckInMinigame).override_failure_message(kind).is_false()


func test_task_spots_are_on_the_floor() -> void:
	var layout: OfficeLayout = OfficeLayout.new()
	for entry: Variant in _tasks():
		var task: Dictionary = entry
		var spot: Array = task["spot"]
		var cell: Vector2i = Vector2i(int(spot[0]), int(spot[1]))
		assert_bool(layout.is_walkable_cell(cell)).override_failure_message("%s %s" % [task["id"], cell]).is_true()
		var room: MapLayout.Room = layout.get_room_at(cell)
		assert_str(String(room.id) if room != null else "").override_failure_message(task["id"]).is_equal(task["room"])
