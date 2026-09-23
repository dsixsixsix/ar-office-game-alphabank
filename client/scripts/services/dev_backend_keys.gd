extends Node
## DEV-ONLY keys for the mock server on a desktop debug build (added by Backend):
##   F8   the parking draw starts in one minute
##   F9   a colleague asks to confirm a joint photo
##   F10  one day passes (absence fines, lost streak); the office reloads to show the result


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var mock: MockBackend = Backend.get_mock()
	match key.keycode:
		KEY_F8:
			mock.raffle.dev_schedule(60)
			print("[dev] parking draw in 60 s")
		KEY_F9:
			if not mock.social.dev_incoming_photo_request():
				print("[dev] nobody is in the office to ask for a photo")
			Backend.inbox_may_have_changed.emit()
		KEY_F10:
			mock.dev_skip_days(1)
			print("[dev] skipped a day")
			Backend.profile = null
			get_tree().reload_current_scene()
		_:
			return
	get_viewport().set_input_as_handled()
