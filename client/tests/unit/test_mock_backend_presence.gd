extends GdUnitTestSuite
## Server rules for presence, checked on the mock that mirrors the planned Nakama module.
## The mock keeps its state in user://mock_backend.json; the suite saves and restores that file.

var _saved: String = ""
var _had_save: bool = false


func before_test() -> void:
	_had_save = FileAccess.file_exists(MockBackend.SAVE_PATH)
	_saved = FileAccess.get_file_as_string(MockBackend.SAVE_PATH) if _had_save else ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MockBackend.SAVE_PATH))


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MockBackend.SAVE_PATH))
	if _had_save:
		var file: FileAccess = FileAccess.open(MockBackend.SAVE_PATH, FileAccess.WRITE)
		file.store_string(_saved)


func _backend() -> MockBackend:
	var backend: MockBackend = MockBackend.new()
	backend.login()
	return backend


func _token() -> String:
	var step: int = PresenceToken.step_at(Time.get_unix_time_from_system())
	return PresenceToken.generate(DevQrCodes.presence_secret(), DevQrCodes.OFFICE_ID, step)


func test_tasks_need_check_in_first() -> void:
	var backend: MockBackend = _backend()
	var result: BackendModels.TaskResult = backend.complete_task("stairs", true, "k1", {"score": 1.0})
	assert_str(result.error).is_equal("presence_required")


func test_check_in_needs_a_valid_token() -> void:
	var backend: MockBackend = _backend()
	assert_str(backend.complete_task("check_in", true, "k1", {}).error).is_equal("presence_token_invalid")
	var forged: String = "%s.%d.%s" % [DevQrCodes.OFFICE_ID, PresenceToken.step_at(Time.get_unix_time_from_system()), "00".repeat(10)]
	assert_str(backend.complete_task("check_in", true, "k2", {"presence_token": forged}).error).is_equal("presence_token_invalid")
	var ok: BackendModels.TaskResult = backend.complete_task("check_in", true, "k3", {"presence_token": _token()})
	assert_bool(ok.ok).is_true()
	assert_bool(backend.complete_task("stairs", true, "k4", {}).ok).is_true()


func test_token_cannot_be_reused() -> void:
	var backend: MockBackend = _backend()
	var token: String = _token()
	assert_str(backend._verify_presence_token(token)).is_empty()
	assert_str(backend._verify_presence_token(token)).is_equal("presence_token_reused")


func test_score_bonus_is_capped() -> void:
	var backend: MockBackend = _backend()
	backend.complete_task("check_in", true, "k1", {"presence_token": _token()})
	var base: int = 0
	for task: BackendModels.TaskInfo in backend.list_tasks():
		if task.id == "stairs":
			base = task.reward
	var result: BackendModels.TaskResult = backend.complete_task("stairs", true, "k2", {"score": 50.0})
	assert_int(result.reward).is_equal(roundi(base * (1.0 + MockBackend.MAX_SCORE_BONUS)))


func test_check_in_marks_the_calendar() -> void:
	var backend: MockBackend = _backend()
	assert_bool(backend.login().present_today).is_false()
	backend.complete_task("check_in", true, "k1", {"presence_token": _token()})
	var page: BackendModels.ProfilePage = backend.account.get_profile_page()
	assert_bool(page.profile.present_today).is_true()
	assert_int(page.profile.streak_days).is_equal(1)
	assert_bool(page.days[page.days.size() - 1].present).is_true()
	assert_int(page.days[page.days.size() - 1].tasks.size()).is_equal(1)
