extends Node
## Where the player physically is (autoload "Presence"). The zone is a room id of the office.
## Today it changes only when the player scans the static QR code at a room door and the server
## accepts it (inside the office interval); BLE beacons will feed the same signal later. A zone is
## navigation only, never proof of presence for rewards; the server keeps only the last room of today.

signal zone_changed(room_id: StringName)

var zone: StringName = &""


func set_zone_from_qr(room_id: StringName) -> void:
	if room_id == zone:
		return
	zone = room_id
	zone_changed.emit(room_id)


func clear() -> void:
	zone = &""
