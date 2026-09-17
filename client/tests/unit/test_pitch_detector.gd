extends GdUnitTestSuite

const RATE: float = 12000.0


func _tone(frequency: float, count: int = 512, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for i: int in count:
		var t: float = i / RATE
		# A second harmonic makes it closer to a real voice.
		samples[i] = amplitude * (sin(TAU * frequency * t) + 0.4 * sin(TAU * 2.0 * frequency * t))
	return samples


func test_detects_frequencies() -> void:
	for frequency: float in [110.0, 220.0, 261.63, 440.0, 660.0]:
		var detected: float = PitchDetector.detect(_tone(frequency), RATE)
		assert_float(detected).override_failure_message("%f -> %f" % [frequency, detected]).is_equal_approx(frequency, frequency * 0.02)


func test_silence_gives_zero() -> void:
	assert_float(PitchDetector.detect(_tone(220.0, 512, 0.001), RATE)).is_equal(0.0)


func test_noise_is_not_a_note() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var noise: PackedFloat32Array = PackedFloat32Array()
	for i: int in 512:
		noise.append(rng.randf_range(-0.5, 0.5))
	assert_float(PitchDetector.detect(noise, RATE)).is_equal(0.0)


func test_cents_ignore_octave() -> void:
	for frequency: float in [110.0, 220.0, 880.0]:
		assert_float(PitchDetector.cents_off_pitch_class(frequency, 9)).is_equal_approx(0.0, 0.01)
	var sharp_c: float = PitchDetector.midi_to_frequency(60.3)
	assert_float(PitchDetector.cents_off_pitch_class(sharp_c, 0)).is_equal_approx(30.0, 0.01)
	# B is a semitone below C: -100 cents, not +1100.
	assert_float(PitchDetector.cents_off_pitch_class(PitchDetector.midi_to_frequency(59.0), 0)).is_equal_approx(-100.0, 0.01)


func test_note_keys() -> void:
	assert_str(PitchDetector.note_key(0)).is_equal("NOTE_C")
	assert_str(PitchDetector.note_key(7)).is_equal("NOTE_G")
	assert_str(PitchDetector.note_key(-1)).is_equal("NOTE_B")
