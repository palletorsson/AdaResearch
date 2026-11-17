extends RefCounted
## A channel vocoder. Each band tracks the voice envelope and applies it to
## the same band of a saw carrier following the singer's note and vibrato.

const CENTERS := [225.0, 390.0, 670.0, 1100.0, 1790.0, 2880.0, 4550.0, 7100.0]
const Q := 1.5

var _band_gain := PackedFloat64Array()
var _feedback_one := PackedFloat64Array()
var _feedback_two := PackedFloat64Array()
var _voice_one := PackedFloat64Array()
var _voice_two := PackedFloat64Array()
var _carrier_one := PackedFloat64Array()
var _carrier_two := PackedFloat64Array()
var _envelope := PackedFloat64Array()
var _attack: float
var _release: float


func _init(rate: float) -> void:
	_attack = 1.0 - exp(-1.0 / (rate * 0.0025))
	_release = 1.0 - exp(-1.0 / (rate * 0.016))
	for frequency: float in CENTERS:
		var omega := TAU * frequency / rate
		var alpha := sin(omega) / (2.0 * Q)
		var scale := 1.0 / (1.0 + alpha)
		_band_gain.append(alpha * scale)
		_feedback_one.append(2.0 * cos(omega) * scale)
		_feedback_two.append(-(1.0 - alpha) * scale)
	for state in [_voice_one, _voice_two, _carrier_one, _carrier_two, _envelope]:
		state.resize(CENTERS.size())


func step(voice: float, phase: float, phase_step: float) -> float:
	var saw := 2.0 * phase - 1.0
	# Smooth the discontinuity across its two neighboring samples (polyBLEP).
	if phase < phase_step:
		var edge := phase / phase_step - 1.0
		saw += edge * edge
	elif phase > 1.0 - phase_step:
		var edge := (phase - 1.0) / phase_step + 1.0
		saw -= edge * edge
	var sum := 0.0
	for band in CENTERS.size():
		var b := _band_gain[band]
		var a1 := _feedback_one[band]
		var a2 := _feedback_two[band]
		var detected := b * voice + _voice_one[band]
		_voice_one[band] = a1 * detected + _voice_two[band]
		_voice_two[band] = a2 * detected - b * voice
		var carrier := b * saw + _carrier_one[band]
		_carrier_one[band] = a1 * carrier + _carrier_two[band]
		_carrier_two[band] = a2 * carrier - b * saw
		var level := absf(detected)
		var envelope := _envelope[band]
		envelope += (_attack if level > envelope else _release) * (level - envelope)
		_envelope[band] = envelope
		sum += carrier * envelope
	# Each carrier band has less than unity RMS. Bring the parallel wet path
	# closer to the level of the dry voice without affecting the dry consonants.
	return 1.9 * sum
