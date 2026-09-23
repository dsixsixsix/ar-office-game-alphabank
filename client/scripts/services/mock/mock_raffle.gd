class_name MockRaffle
extends RefCounted
## DEV-ONLY part of the mock server: the monthly parking draw (last Friday, see game_rules.json).
## Each draw gets a secret seed and its published commitment when it is created; simulated
## colleagues buy tickets; the draw runs once its time has passed (RaffleDraw).

var _store: MockStore
var _social: MockSocial


func _init(store: MockStore, social: MockSocial) -> void:
	_store = store
	_social = social


func get_raffle() -> BackendModels.RaffleState:
	var draw: Dictionary = current_draw()
	var config: Dictionary = _store.rules.get("raffle", {})
	var state: BackendModels.RaffleState = BackendModels.RaffleState.new()
	state.draw_id = draw["id"]
	state.prize_name = str(config.get("prize_name", ""))
	state.prize_description = str(config.get("prize_description", ""))
	state.ticket_price = int(config.get("ticket_price", 0))
	state.draw_at = int(draw["draw_at"])
	state.seconds_to_draw = maxi(0, state.draw_at - _store.now())
	state.min_office_days = int(config.get("min_office_days", 0))
	state.window_days = int(config.get("window_days", 30))
	state.office_days = _office_days_in_window(state.window_days)
	state.commitment = draw["commitment"]
	var tickets: Array = draw["tickets"]
	for user_id: String in RaffleDraw.canonical_entries(tickets):
		state.entrants.append(_entrant(user_id))
	state.has_ticket = tickets.has(MockStore.PLAYER_ID)
	if bool(draw["drawn"]):
		state.phase = BackendModels.RaffleState.Phase.DRAWN
		state.revealed_seed = draw["seed"]
		state.winner_id = draw["winner"]
		state.is_winner = state.winner_id == MockStore.PLAYER_ID
		for entrant: BackendModels.RaffleEntrant in state.entrants:
			if entrant.user_id == state.winner_id:
				state.winner_name = entrant.name
	state.buy_error = _buy_error(draw, state)
	return state


func buy_ticket(operation_key: String) -> BackendModels.PurchaseResult:
	var result: BackendModels.PurchaseResult = BackendModels.PurchaseResult.new()
	result.balance = int(_store.state["balance"])
	if not _store.claim_key(operation_key):
		result.error = "duplicate_operation"
		return result
	var state: BackendModels.RaffleState = get_raffle()
	if not state.buy_error.is_empty():
		result.error = state.buy_error
		return result
	(current_draw()["tickets"] as Array).append(MockStore.PLAYER_ID)
	_store.credit(-state.ticket_price, "raffle_ticket", state.draw_id)
	result.status = BackendModels.PurchaseResult.Status.GRANTED
	result.balance = int(_store.state["balance"])
	return result


## The draw of this month (last Friday); after its day is over, next month's. A dev draw set with
## dev_schedule() replaces it for a day.
func current_draw() -> Dictionary:
	var config: Dictionary = _store.rules.get("raffle", {})
	var dev_at: int = int(_store.state["dev_raffle_at"])
	if dev_at > 0 and _store.now() < dev_at + WorkCalendar.SECONDS_PER_DAY:
		return _draw_record("parking-dev-%d" % dev_at, dev_at)
	var today: int = _store.today()
	var draw_day: int = WorkCalendar.last_friday_of_month(today)
	if today > draw_day:
		draw_day = WorkCalendar.last_friday_of_month(WorkCalendar.last_day_of_month(today) + 1)
	var date: Dictionary = WorkCalendar.date_of(draw_day)
	var draw_at: int = WorkCalendar.unix_at(draw_day, int(config.get("draw_hour", 18)), int(config.get("draw_minute", 0)), _store.utc_offset())
	return _draw_record("parking-%04d-%02d" % [int(date["year"]), int(date["month"])], draw_at)


## Draws every draw whose time has passed and tells its entrants.
func run_due_draws() -> void:
	for draw_id: Variant in _store.state["raffles"]:
		var draw: Dictionary = (_store.state["raffles"] as Dictionary)[draw_id]
		if bool(draw["drawn"]) or _store.now() < int(draw["draw_at"]):
			continue
		draw["drawn"] = true
		draw["winner"] = RaffleDraw.winner(draw["seed"], draw["id"], draw["tickets"])
		var prize: String = str((_store.rules.get("raffle", {}) as Dictionary).get("prize_name", ""))
		if (draw["tickets"] as Array).has(MockStore.PLAYER_ID):
			if draw["winner"] == MockStore.PLAYER_ID:
				_store.notify("raffle_win", {"prize": prize})
			else:
				_store.notify("raffle_lost", {"prize": prize, "name": _social.find_colleague(str(draw["winner"])).get("name", "")})
		_store.save()


## DEV: moves the parking draw to `seconds` from now.
func dev_schedule(seconds: int) -> void:
	_store.state["dev_raffle_at"] = _store.now() + seconds
	_store.save()


## Creates the draw on first use: secret seed, its published commitment, and the tickets simulated
## colleagues bought.
func _draw_record(draw_id: String, draw_at: int) -> Dictionary:
	var raffles: Dictionary = _store.state["raffles"]
	if not raffles.has(draw_id):
		var seed_hex: String = RaffleDraw.new_seed()
		var tickets: Array = []
		for colleague: Variant in _store.colleagues:
			if bool((colleague as Dictionary).get("raffle", false)):
				tickets.append((colleague as Dictionary)["id"])
		raffles[draw_id] = {
			"id": draw_id, "draw_at": draw_at, "seed": seed_hex, "commitment": RaffleDraw.commitment(seed_hex),
			"tickets": tickets, "drawn": false, "winner": "",
		}
		_store.save()
	return raffles[draw_id]


func _entrant(user_id: String) -> BackendModels.RaffleEntrant:
	var entrant: BackendModels.RaffleEntrant = BackendModels.RaffleEntrant.new()
	entrant.user_id = user_id
	if user_id == MockStore.PLAYER_ID:
		var settings: Dictionary = _store.state["profile"]
		entrant.name = str(settings.get("name", MockAccount.DEFAULT_NAME))
		entrant.avatar = str(settings.get("avatar", AvatarCatalog.DEFAULT))
	else:
		var colleague: Dictionary = _social.find_colleague(user_id)
		entrant.name = str(colleague.get("name", user_id))
		entrant.avatar = str(colleague.get("look", ""))
	return entrant


func _buy_error(draw: Dictionary, state: BackendModels.RaffleState) -> String:
	var error: String = ""
	if bool(draw["drawn"]) or _store.now() >= int(draw["draw_at"]):
		error = "raffle_closed"
	elif state.has_ticket:
		error = "raffle_already_joined"
	elif state.office_days < state.min_office_days:
		error = "raffle_not_eligible"
	elif int(_store.state["balance"]) < state.ticket_price:
		error = "not_enough_coins"
	return error


func _office_days_in_window(window_days: int) -> int:
	var today: int = _store.today()
	var count: int = 0
	for key: Variant in _store.state["presence_days"]:
		var day: int = str(key).to_int()
		if day > today - window_days and day <= today:
			count += 1
	return count
