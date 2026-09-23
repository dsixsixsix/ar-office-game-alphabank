class_name DevQrCodes
extends RefCounted
## DEV-ONLY: codes the desktop sensor emulator can "show" to the camera, and the settings the mock
## backend and the office screen share. The real presence secret exists only on the server.

const OFFICE_ID: String = "hq"
const SECRET_ENV: String = "OFFICE_GAME_PRESENCE_SECRET"
## Used only when the environment variable is not set. Never used by a real server.
const FALLBACK_DEV_SECRET: String = "local-dev-presence-secret"


static func presence_secret() -> String:
	var secret: String = OS.get_environment(SECRET_ENV)
	return secret if not secret.is_empty() else FALLBACK_DEV_SECRET


static func current_presence_code() -> String:
	var step: int = PresenceToken.step_at(Time.get_unix_time_from_system())
	return QrPayload.presence(PresenceToken.generate(presence_secret(), OFFICE_ID, step))


## [label, QR text] pairs. The presence code is generated on each call so it is always fresh.
static func suggestions() -> Array[Array]:
	var result: Array[Array] = [["office screen", current_presence_code()]]
	for floor_id: StringName in OfficeFloors.ORDER:
		for room: MapLayout.Room in OfficeFloors.layout(floor_id).rooms:
			result.append(["room " + room.id, QrPayload.room(room.id)])
	# Colleagues' "My QR" codes; "*" marks who is in the office today in the mock.
	var mock: MockBackend = Backend.get_mock()
	for colleague: BackendModels.Colleague in mock.social.list_colleagues():
		result.append([colleague.user_id.trim_prefix("colleague-") + ("*" if colleague.present else ""), QrPayload.user(colleague.user_id)])
	result.append(["expired", QrPayload.presence(PresenceToken.generate(presence_secret(), OFFICE_ID, 1))])
	result.append(["wifi", "WIFI:S:Guest;T:WPA;P:example;;"])
	return result
