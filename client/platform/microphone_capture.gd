class_name MicrophoneCapture
extends Node
## Raw microphone samples through the Godot core: AudioStreamMicrophone plays into a silent bus
## with an AudioEffectCapture. Requires `audio/driver/enable_input`; audio never leaves the device.

const BUS_NAME: StringName = &"Microphone"
const SILENT_DB: float = -80.0
const BUFFER_SECONDS: float = 0.5

var _player: AudioStreamPlayer
var _capture: AudioEffectCapture


func start() -> void:
	if _player != null:
		return
	_capture = _ensure_bus()
	_capture.clear_buffer()
	_player = AudioStreamPlayer.new()
	_player.stream = AudioStreamMicrophone.new()
	_player.bus = BUS_NAME
	add_child(_player)
	_player.play()


func stop() -> void:
	if _player == null:
		return
	_player.stop()
	_player.queue_free()
	_player = null


func is_running() -> bool:
	return _player != null


func get_sample_rate() -> float:
	return AudioServer.get_mix_rate()


## Mono samples captured since the last call, at most `max_frames`.
func read(max_frames: int) -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	if _capture == null:
		return result
	var frames: int = mini(_capture.get_frames_available(), max_frames)
	if frames <= 0:
		return result
	var stereo: PackedVector2Array = _capture.get_buffer(frames)
	result.resize(stereo.size())
	for i: int in stereo.size():
		result[i] = (stereo[i].x + stereo[i].y) * 0.5
	return result


static func _ensure_bus() -> AudioEffectCapture:
	var index: int = AudioServer.get_bus_index(BUS_NAME)
	if index < 0:
		index = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, BUS_NAME)
		# Effects run before the bus volume, so the capture still sees the full signal.
		AudioServer.set_bus_volume_db(index, SILENT_DB)
		var effect: AudioEffectCapture = AudioEffectCapture.new()
		effect.buffer_length = BUFFER_SECONDS
		AudioServer.add_bus_effect(index, effect)
	return AudioServer.get_bus_effect(index, 0) as AudioEffectCapture
