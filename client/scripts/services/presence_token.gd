class_name PresenceToken
extends RefCounted
## Rotating office token (TOTP-like): "<office>.<step>.<signature>", where step = unix time / PERIOD and
## signature = HMAC-SHA256(secret, "<office>.<step>") truncated. The secret lives only on the server;
## the mock backend and the office screen use a dev secret from the environment.

const PERIOD_SECONDS: int = 30
## Accept the previous step too, so a code scanned right before rotation still works.
const ACCEPTED_PAST_STEPS: int = 1
const SIGNATURE_BYTES: int = 10


static func step_at(unix_time: float) -> int:
	return floori(unix_time / PERIOD_SECONDS)


static func seconds_left(unix_time: float) -> float:
	return PERIOD_SECONDS - fmod(unix_time, PERIOD_SECONDS)


static func generate(secret: String, office_id: String, step: int) -> String:
	var message: String = "%s.%d" % [office_id, step]
	return "%s.%s" % [message, _signature(secret, message)]


## Returns the token's step when it is valid at `unix_time`, or -1.
static func verify(secret: String, token: String, unix_time: float) -> int:
	var parts: PackedStringArray = token.split(".")
	if parts.size() != 3 or not parts[1].is_valid_int():
		return -1
	var step: int = parts[1].to_int()
	var now_step: int = step_at(unix_time)
	if step > now_step or step < now_step - ACCEPTED_PAST_STEPS:
		return -1
	var expected: String = _signature(secret, "%s.%d" % [parts[0], step])
	return step if _constant_time_equals(expected, parts[2]) else -1


static func office_of(token: String) -> String:
	var parts: PackedStringArray = token.split(".")
	return parts[0] if parts.size() == 3 else ""


static func _signature(secret: String, message: String) -> String:
	var hmac: HMACContext = HMACContext.new()
	hmac.start(HashingContext.HASH_SHA256, secret.to_utf8_buffer())
	hmac.update(message.to_utf8_buffer())
	return hmac.finish().slice(0, SIGNATURE_BYTES).hex_encode()


static func _constant_time_equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var difference: int = 0
	for i: int in a.length():
		difference |= a.unicode_at(i) ^ b.unicode_at(i)
	return difference == 0
