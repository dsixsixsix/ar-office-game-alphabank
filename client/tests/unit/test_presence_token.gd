extends GdUnitTestSuite

const SECRET: String = "test-secret"
const NOW: float = 1_800_000_015.0


func test_fresh_token_is_valid() -> void:
	var step: int = PresenceToken.step_at(NOW)
	var token: String = PresenceToken.generate(SECRET, "hq", step)
	assert_int(PresenceToken.verify(SECRET, token, NOW)).is_equal(step)
	assert_str(PresenceToken.office_of(token)).is_equal("hq")


func test_previous_step_is_accepted_older_is_not() -> void:
	var step: int = PresenceToken.step_at(NOW)
	var previous: String = PresenceToken.generate(SECRET, "hq", step - 1)
	var old: String = PresenceToken.generate(SECRET, "hq", step - 2)
	assert_int(PresenceToken.verify(SECRET, previous, NOW)).is_equal(step - 1)
	assert_int(PresenceToken.verify(SECRET, old, NOW)).is_equal(-1)


func test_future_token_is_rejected() -> void:
	var token: String = PresenceToken.generate(SECRET, "hq", PresenceToken.step_at(NOW) + 1)
	assert_int(PresenceToken.verify(SECRET, token, NOW)).is_equal(-1)


func test_wrong_secret_or_tampered_token_is_rejected() -> void:
	var step: int = PresenceToken.step_at(NOW)
	var token: String = PresenceToken.generate(SECRET, "hq", step)
	assert_int(PresenceToken.verify("other-secret", token, NOW)).is_equal(-1)
	assert_int(PresenceToken.verify(SECRET, token.replace("hq.", "branch."), NOW)).is_equal(-1)
	assert_int(PresenceToken.verify(SECRET, "hq.%d.00" % step, NOW)).is_equal(-1)
	assert_int(PresenceToken.verify(SECRET, "garbage", NOW)).is_equal(-1)


func test_seconds_left_counts_down_within_period() -> void:
	assert_float(PresenceToken.seconds_left(60.0)).is_equal(30.0)
	assert_float(PresenceToken.seconds_left(89.0)).is_equal(1.0)
