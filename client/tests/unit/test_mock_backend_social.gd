extends GdUnitTestSuite
## Server rules of the mock: absence fines, joint photos, meeting tasks, the parking draw and the
## profile. The mock keeps its state in user://mock_backend.json; the suite saves and restores it.

const COLLEAGUES: Array[Dictionary] = [
	{"id": "colleague-a", "name": "A", "department": "digital", "look": "anna", "presence": 1.0},
	{"id": "colleague-b", "name": "B", "department": "hr", "look": "olga", "presence": 1.0},
	{"id": "colleague-c", "name": "C", "department": "design", "look": "fox", "presence": 1.0},
	{"id": "colleague-d", "name": "D", "department": "product_analytics", "look": "masha", "presence": 1.0},
	{"id": "colleague-e", "name": "E", "department": "design", "look": "cat", "presence": 1.0},
	{"id": "colleague-away", "name": "Away", "department": "admin", "look": "igor", "presence": 0.0},
]

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
	backend.store.colleagues = COLLEAGUES.duplicate(true)
	backend.store.player_department = "digital"
	backend.login()
	return backend


func _check_in(backend: MockBackend) -> void:
	var step: int = PresenceToken.step_at(Time.get_unix_time_from_system())
	var token: String = PresenceToken.generate(DevQrCodes.presence_secret(), DevQrCodes.OFFICE_ID, step)
	assert_bool(backend.complete_task("check_in", true, "check-in-%d" % randi(), {"presence_token": token}).ok).is_true()


func _inbox_kinds(backend: MockBackend) -> Array[String]:
	backend.tick()
	var kinds: Array[String] = []
	for item: BackendModels.InboxItem in backend.social.get_inbox():
		kinds.append(item.kind)
	return kinds


# --- Absence fines ---------------------------------------------------------------


func test_missed_workdays_break_the_streak_and_fine_progressively() -> void:
	var backend: MockBackend = _backend()
	var today: int = backend.store.today()
	# Put "today" on a Monday; the player was in the office Monday and Tuesday of last week.
	var monday: int = today - WorkCalendar.weekday(today)
	backend.store.state["dev_day_shift"] = monday - today
	backend.store.state["first_day"] = monday - 7
	backend.store.state["presence_days"] = {str(monday - 7): true, str(monday - 6): true}
	backend.store.state["processed_day"] = monday - 6
	backend.store.state["balance"] = 1000
	var profile: BackendModels.Profile = backend.login()
	# Wednesday: streak lost, no fine. Thursday: 3% of 1000 = 30. Friday: 5% of 970 = 48.5 -> 49.
	assert_int(profile.balance).is_equal(921)
	assert_int(profile.fined_coins).is_equal(79)
	assert_int(profile.lost_streak).is_equal(2)
	assert_int(profile.streak_days).is_equal(0)
	var kinds: Array[String] = _inbox_kinds(backend)
	assert_int(kinds.count("penalty")).is_equal(2)
	assert_int(kinds.count("streak_reset")).is_equal(1)
	# Processing is idempotent.
	assert_int(backend.login().balance).is_equal(921)


func test_fines_never_make_the_balance_negative() -> void:
	var backend: MockBackend = _backend()
	var today: int = backend.store.today()
	backend.store.state["first_day"] = today - 60
	backend.store.state["processed_day"] = today - 60
	backend.store.state["balance"] = 3
	# Two months without the office: every fine rounds up, so the balance runs out, but stops at zero.
	assert_int(backend.login().balance).is_equal(0)
	backend.store.credit(-50, "test", "test")
	assert_int(backend.get_balance()).is_equal(0)


# --- Joint photo -----------------------------------------------------------------


func test_photo_partner_must_be_assigned_and_confirm() -> void:
	var backend: MockBackend = _backend()
	assert_str(backend.social.assign_colleague("selfie").error).is_equal("presence_required")
	_check_in(backend)
	var assigned: BackendModels.ColleagueResult = backend.social.assign_colleague("selfie")
	assert_bool(assigned.ok).is_true()
	assert_bool(assigned.colleague.present).is_true()
	assert_str(assigned.colleague.user_id).is_not_equal("colleague-away")
	var partner: String = assigned.colleague.user_id
	var other: String = "colleague-b" if partner != "colleague-b" else "colleague-c"
	assert_str(backend.complete_task("selfie", true, "p1", {"partner_id": other, "faces": 2}).error).is_equal("colleague_not_assigned")
	assert_str(backend.complete_task("selfie", true, "p2", {"partner_id": partner, "faces": 1}).error).is_equal("not_enough_faces")
	var balance: int = backend.get_balance()
	var result: BackendModels.TaskResult = backend.complete_task("selfie", true, "p3", {"partner_id": partner, "faces": 2})
	assert_bool(result.ok).is_true()
	assert_bool(result.pending).is_true()
	assert_int(backend.get_balance()).is_equal(balance)
	assert_str(backend.complete_task("selfie", true, "p4", {"partner_id": partner, "faces": 2}).error).is_equal("pending_confirmation")
	# The colleague answers after a while.
	for request: Variant in backend.store.state["photo_requests"]:
		(request as Dictionary)["t"] = backend.store.now() - 3600
	var selfie: BackendModels.TaskInfo = null
	for task: BackendModels.TaskInfo in backend.list_tasks():
		if task.id == "selfie":
			selfie = task
	assert_bool(selfie.completed).is_true()
	assert_bool(selfie.pending).is_false()
	assert_int(backend.get_balance()).is_greater(balance)
	assert_array(_inbox_kinds(backend)).contains(["photo_confirmed"])


func test_incoming_photo_request_is_confirmed_by_the_player() -> void:
	var backend: MockBackend = _backend()
	_check_in(backend)
	assert_bool(backend.social.dev_incoming_photo_request()).is_true()
	var request: BackendModels.InboxItem = backend.social.get_inbox()[0]
	assert_bool(request.needs_answer()).is_true()
	var balance: int = backend.get_balance()
	assert_bool(backend.social.respond_photo_request(request.id, true, "r1").ok).is_true()
	assert_int(backend.get_balance()).is_greater(balance)
	assert_str(backend.social.respond_photo_request(request.id, false, "r2").error).is_equal("request_closed")


# --- Meeting colleagues ------------------------------------------------------------


func test_meeting_needs_the_assigned_colleague_from_another_department() -> void:
	var backend: MockBackend = _backend()
	_check_in(backend)
	var assigned: BackendModels.ColleagueResult = backend.social.assign_colleague("blind_coffee")
	assert_bool(assigned.ok).is_true()
	assert_str(assigned.colleague.department).is_not_equal("digital")
	assert_str(backend.complete_task("blind_coffee", true, "m1", {"colleague_id": "colleague-a"}).error).is_equal("colleague_not_assigned")
	assert_bool(backend.complete_task("blind_coffee", true, "m2", {"colleague_id": assigned.colleague.user_id}).ok).is_true()


func test_bingo_needs_different_departments_in_the_office() -> void:
	var backend: MockBackend = _backend()
	_check_in(backend)
	var same_team: Dictionary = {"colleague_ids": ["colleague-a", "colleague-b", "colleague-c"]}
	assert_str(backend.complete_task("colleague_bingo", true, "b1", same_team).error).is_equal("same_department")
	var twice: Dictionary = {"colleague_ids": ["colleague-b", "colleague-c", "colleague-e"]}
	assert_str(backend.complete_task("colleague_bingo", true, "b2", twice).error).is_equal("same_department_twice")
	var away: Dictionary = {"colleague_ids": ["colleague-b", "colleague-c", "colleague-away"]}
	assert_str(backend.complete_task("colleague_bingo", true, "b3", away).error).is_equal("colleague_not_present")
	var good: Dictionary = {"colleague_ids": ["colleague-b", "colleague-c", "colleague-d"]}
	assert_bool(backend.complete_task("colleague_bingo", true, "b4", good).ok).is_true()


# --- Parking draw ----------------------------------------------------------------


func test_raffle_ticket_needs_office_days_and_coins() -> void:
	var backend: MockBackend = _backend()
	backend.raffle.dev_schedule(3600)
	var state: BackendModels.RaffleState = backend.raffle.get_raffle()
	assert_int(state.phase).is_equal(BackendModels.RaffleState.Phase.OPEN)
	assert_int(state.seconds_to_draw).is_between(3590, 3600)
	assert_str(state.buy_error).is_equal("raffle_not_eligible")
	var today: int = backend.store.today()
	for day: int in state.min_office_days:
		(backend.store.state["presence_days"] as Dictionary)[str(today - day)] = true
	backend.store.state["balance"] = state.ticket_price - 1
	assert_str(backend.raffle.get_raffle().buy_error).is_equal("not_enough_coins")
	backend.store.state["balance"] = state.ticket_price + 100
	var bought: BackendModels.PurchaseResult = backend.raffle.buy_ticket("t1")
	assert_int(bought.status).is_equal(BackendModels.PurchaseResult.Status.GRANTED)
	assert_int(bought.balance).is_equal(100)
	assert_bool(backend.raffle.get_raffle().has_ticket).is_true()
	assert_str(backend.raffle.buy_ticket("t2").error).is_equal("raffle_already_joined")


func test_raffle_draws_a_verifiable_winner() -> void:
	var backend: MockBackend = _backend()
	backend.raffle.dev_schedule(3600)
	var state: BackendModels.RaffleState = backend.raffle.get_raffle()
	assert_str(state.revealed_seed).is_empty()
	var draw: Dictionary = (backend.store.state["raffles"] as Dictionary)[state.draw_id]
	(draw["tickets"] as Array).append(MockBackend.PLAYER_ID)
	draw["draw_at"] = backend.store.now() - 1
	backend.tick()
	var result: BackendModels.RaffleState = backend.raffle.get_raffle()
	assert_int(result.phase).is_equal(BackendModels.RaffleState.Phase.DRAWN)
	assert_str(RaffleDraw.commitment(result.revealed_seed)).is_equal(state.commitment)
	assert_str(result.winner_id).is_equal(RaffleDraw.winner(result.revealed_seed, result.draw_id, draw["tickets"]))
	assert_str(result.buy_error).is_equal("raffle_closed")
	var kinds: Array[String] = _inbox_kinds(backend)
	assert_bool(kinds.has("raffle_win") or kinds.has("raffle_lost")).is_true()


# --- Profile ---------------------------------------------------------------------


func test_status_is_cleaned_and_limited() -> void:
	var backend: MockBackend = _backend()
	assert_bool(backend.account.set_status("  На созвоне\n до 15:00 ").ok).is_true()
	assert_str(backend.account.get_profile_page().profile.status).is_equal("На созвоне до 15:00")
	assert_str(backend.account.set_status("x".repeat(MockAccount.MAX_STATUS_LENGTH + 1)).error).is_equal("status_too_long")


func test_avatar_templates_and_upload() -> void:
	var backend: MockBackend = _backend()
	assert_str(backend.account.set_avatar("nobody").error).is_equal("unknown_avatar")
	assert_str(backend.account.set_avatar(AvatarCatalog.CUSTOM).error).is_equal("avatar_missing")
	assert_bool(backend.account.set_avatar("fox").ok).is_true()
	assert_str(backend.account.get_profile_page().profile.avatar).is_equal("fox")
	var picture: Image = Image.create_empty(300, 200, false, Image.FORMAT_RGBA8)
	picture.fill(Color.RED)
	assert_bool(backend.account.upload_avatar(AvatarCatalog.prepare_upload(picture)).ok).is_true()
	assert_str(backend.account.get_profile_page().profile.avatar).is_equal(AvatarCatalog.CUSTOM)
	assert_bool(backend.account.get_avatar_png(MockBackend.PLAYER_ID).is_empty()).is_false()
	assert_str(backend.account.upload_avatar(picture.save_png_to_buffer()).error).is_equal("avatar_invalid")


func test_notification_plan_is_in_the_future() -> void:
	var backend: MockBackend = _backend()
	for item: BackendModels.PlannedNotification in backend.get_notification_plan():
		assert_int(item.delay_seconds).is_greater(0)
		assert_str(NotificationTexts.planned_text(item.kind, item.params)).is_not_empty()
