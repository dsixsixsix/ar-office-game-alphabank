class_name PresenceQrMinigame
extends Minigame
## Check-in: scan the rotating code on the office screen. The token goes to the server as proof of
## presence; the client does not judge whether it is valid.


func _ready() -> void:
	var payload: QrPayload = await scan_qr(tr("MG_PRESENCE_HINT"), QrPayload.Kind.PRESENCE)
	proof["presence_token"] = payload.value
	set_score(1.0)
	finish(true)
