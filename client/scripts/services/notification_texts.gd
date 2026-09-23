class_name NotificationTexts
extends RefCounted
## Player-facing text of inbox messages and scheduled notifications. The server sends kinds and
## parameters; wording and language live on the client.


static func inbox_text(item: BackendModels.InboxItem) -> String:
	var p: Dictionary = item.params
	match item.kind:
		"penalty":
			return _tr("INBOX_PENALTY") % [int(p.get("amount", 0)), int(p.get("missed", 0)), int(p.get("percent", 0)), str(p.get("date", ""))]
		"streak_reset":
			return _tr("INBOX_STREAK_RESET") % [int(p.get("streak", 0)), str(p.get("date", ""))]
		"photo_request":
			return _tr("INBOX_PHOTO_REQUEST") % str(p.get("name", ""))
		"photo_confirmed":
			return _tr("INBOX_PHOTO_CONFIRMED") % [str(p.get("name", "")), int(p.get("reward", 0))]
		"photo_declined":
			return _tr("INBOX_PHOTO_DECLINED") % str(p.get("name", ""))
		"raffle_win":
			return _tr("INBOX_RAFFLE_WIN") % str(p.get("prize", ""))
		"raffle_lost":
			return _tr("INBOX_RAFFLE_LOST") % str(p.get("name", ""))
	return item.kind


## Body of a notification planned by the server (NotificationPlanner kinds).
static func planned_text(kind: String, params: Dictionary) -> String:
	match kind:
		"streak_reminder":
			return _tr("NOTIF_STREAK_REMINDER") % [int(params.get("streak", 0)), str(params.get("deadline", ""))]
		"check_in_reminder":
			return _tr("NOTIF_CHECK_IN_REMINDER") % str(params.get("deadline", ""))
		"raffle_day":
			return _tr("NOTIF_RAFFLE_DAY") % str(params.get("time", ""))
		"raffle_hour":
			return _tr("NOTIF_RAFFLE_HOUR")
		"fun":
			return str(params.get("text", ""))
	return ""


static func title() -> String:
	return _tr("NOTIF_TITLE")


static func department(department_id: String) -> String:
	return _tr("DEPT_" + department_id.to_upper()) if not department_id.is_empty() else ""


static func _tr(key: String) -> String:
	return String(TranslationServer.translate(key))
