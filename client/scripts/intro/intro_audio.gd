class_name IntroAudio
extends Node
## Plays intro one-shots and ambience loops from assets/audio on the SFX bus.

const DIR: String = "res://assets/audio/"

var _loops: Dictionary[String, AudioStreamPlayer] = {}


func play_loop(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(sound)
	if player == null:
		player = _make(sound)
		if player == null:
			return
		var wav: AudioStreamWAV = player.stream as AudioStreamWAV
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
		# Fallback when the imported stream ignores loop points.
		player.finished.connect(player.play)
		_loops[sound] = player
		player.play()
	player.volume_db = volume_db
	player.pitch_scale = pitch


func stop_loop(sound: String, fade: float = 0.2) -> void:
	var player: AudioStreamPlayer = _loops.get(sound)
	if player == null:
		return
	_loops.erase(sound)
	player.finished.disconnect(player.play)
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", -60.0, maxf(fade, 0.01))
	tween.tween_callback(player.queue_free)


func stop_all(fade: float = 0.2) -> void:
	for sound: String in _loops.keys():
		stop_loop(sound, fade)


func play_one(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _make(sound)
	if player == null:
		return
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	player.play()


func _make(sound: String) -> AudioStreamPlayer:
	var path: String = DIR + sound + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("Missing sound " + path)
		return null
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = load(path)
	player.bus = &"SFX"
	add_child(player)
	return player
