class_name PitchDetector
extends RefCounted
## Fundamental frequency estimation with the YIN algorithm (de Cheveigné & Kawahara, 2002).
## Works on a mono buffer; the caller downsamples microphone input to keep GDScript fast.

const MIN_FREQUENCY: float = 70.0
const MAX_FREQUENCY: float = 1000.0
## Cumulative mean normalized difference threshold; lower = stricter.
const THRESHOLD: float = 0.15
## Buffers quieter than this RMS are treated as silence.
const SILENCE_RMS: float = 0.01
const NOTE_NAMES: Array[String] = [
	"NOTE_C", "NOTE_CS", "NOTE_D", "NOTE_DS", "NOTE_E", "NOTE_F", "NOTE_FS", "NOTE_G", "NOTE_GS", "NOTE_A", "NOTE_AS", "NOTE_B",
]
const A4_FREQUENCY: float = 440.0
const A4_MIDI: int = 69


## Returns the detected frequency in Hz, or 0.0 for silence and unvoiced sound.
static func detect(samples: PackedFloat32Array, sample_rate: float) -> float:
	if rms(samples) < SILENCE_RMS:
		return 0.0
	var min_tau: int = maxi(2, floori(sample_rate / MAX_FREQUENCY))
	@warning_ignore("integer_division")
	var max_tau: int = mini(samples.size() / 2, ceili(sample_rate / MIN_FREQUENCY))
	if max_tau <= min_tau:
		return 0.0
	var window: int = samples.size() - max_tau
	var difference: PackedFloat32Array = PackedFloat32Array()
	difference.resize(max_tau + 1)
	for tau: int in range(1, max_tau + 1):
		var sum: float = 0.0
		for i: int in window:
			var delta: float = samples[i] - samples[i + tau]
			sum += delta * delta
		difference[tau] = sum
	# Cumulative mean normalized difference.
	var running: float = 0.0
	var normalized: PackedFloat32Array = PackedFloat32Array()
	normalized.resize(max_tau + 1)
	normalized[0] = 1.0
	for tau: int in range(1, max_tau + 1):
		running += difference[tau]
		normalized[tau] = difference[tau] * tau / running if running > 0.0 else 1.0
	var best_tau: int = -1
	var tau_index: int = min_tau
	while tau_index <= max_tau:
		if normalized[tau_index] < THRESHOLD:
			while tau_index + 1 <= max_tau and normalized[tau_index + 1] < normalized[tau_index]:
				tau_index += 1
			best_tau = tau_index
			break
		tau_index += 1
	if best_tau < 0:
		return 0.0
	return sample_rate / _refine(normalized, best_tau)


static func rms(samples: PackedFloat32Array) -> float:
	if samples.is_empty():
		return 0.0
	var sum: float = 0.0
	for sample: float in samples:
		sum += sample * sample
	return sqrt(sum / samples.size())


## Parabolic interpolation around the minimum for sub-sample precision.
static func _refine(values: PackedFloat32Array, tau: int) -> float:
	if tau <= 0 or tau >= values.size() - 1:
		return float(tau)
	var left: float = values[tau - 1]
	var center: float = values[tau]
	var right: float = values[tau + 1]
	var denominator: float = left - 2.0 * center + right
	if is_zero_approx(denominator):
		return float(tau)
	return tau + 0.5 * (left - right) / denominator


## Fractional MIDI note number, e.g. 69.0 for A4.
static func frequency_to_midi(frequency: float) -> float:
	return A4_MIDI + 12.0 * log(frequency / A4_FREQUENCY) / log(2.0)


static func midi_to_frequency(midi: float) -> float:
	return A4_FREQUENCY * pow(2.0, (midi - A4_MIDI) / 12.0)


## Distance in cents between the sung pitch and the nearest octave of the target pitch class.
## Singers of any voice range hit the same note this way.
static func cents_off_pitch_class(frequency: float, target_pitch_class: int) -> float:
	var midi: float = frequency_to_midi(frequency)
	var offset: float = fposmod(midi - target_pitch_class, 12.0)
	if offset > 6.0:
		offset -= 12.0
	return offset * 100.0


static func note_key(pitch_class: int) -> String:
	return NOTE_NAMES[posmod(pitch_class, 12)]
