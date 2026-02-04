# cs80_lead.gd
# CS-80 solo lead - expressive, singing, solo voice
# Character: Vocal, crying, bending, highly expressive
# Source: Yamaha CS-80 with ribbon controller
# Processing: Portamento, vibrato, filter expression

# Technical anatomy:
# - Single voice (or unison for power)
# - Heavy use of ribbon for pitch bends
# - Aftertouch -> filter + vibrato
# - Ring mod for overtones
# - The "singing" quality from slow attack + expression

class_name CS80Lead
extends RefCounted

const SAMPLE_RATE = 44100.0

# Lead parameters
const DETUNE_CENTS = 5.0
const RING_MOD_AMOUNT = 0.1
const LPF_CUTOFF_HZ = 1800.0
const LPF_ENV_DEPTH_HZ = 4000.0
const RESONANCE = 0.4  # More resonance for lead
const ATTACK_MS = 50.0  # Faster than brass for articulation
const DECAY_MS = 150.0
const SUSTAIN = 0.75
const RELEASE_MS = 300.0
const VIBRATO_RATE_HZ = 5.5
const VIBRATO_DELAY_MS = 200.0  # Vibrato kicks in after note start
const PORTAMENTO_TIME_MS = 80.0


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var expression = params.get("expression", 0.8)
	var vibrato_amount = params.get("vibrato", 0.6)
	var brightness = params.get("brightness", 0.7)
	var bend = params.get("pitch_bend", 0.0)  # -1 to 1, semitones
	
	# Apply pitch bend
	var bent_freq = freq * pow(2.0, bend / 12.0)
	
	# Vibrato (delayed onset, increases with time)
	var vib_onset = max(0.0, t - VIBRATO_DELAY_MS/1000.0) * 5.0
	var vib_env = min(1.0, vib_onset) * vibrato_amount
	var vibrato = sin(TAU * VIBRATO_RATE_HZ * t) * vib_env * 0.015
	bent_freq *= (1.0 + vibrato)
	
	# Dual oscillators with detune
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var osc1 = _saw(t, bent_freq)
	var osc2 = _saw(t, bent_freq * detune_ratio)
	
	# Ring mod
	var ring = osc1 * osc2
	var mix = (osc1 + osc2) * 0.5 * (1.0 - RING_MOD_AMOUNT) + ring * RING_MOD_AMOUNT
	
	# Filter with envelope and expression
	var filter_env = _filter_envelope(t, 0.02, 0.3)
	var cutoff = LPF_CUTOFF_HZ + filter_env * LPF_ENV_DEPTH_HZ * brightness * expression
	var filtered = _resonant_lpf(mix, cutoff, RESONANCE)
	
	# Amplitude envelope
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 1.5)
	
	return clamp(filtered * env * expression, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _filter_envelope(t: float, attack: float, decay: float) -> float:
	if t < attack:
		return t / attack
	else:
		return exp(-(t - attack) / decay)


static func _resonant_lpf(input: float, cutoff_hz: float, reso: float) -> float:
	# Simplified resonant filter approximation
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	var feedback = reso * 3.5
	return input * alpha * (1.0 + feedback * (1.0 - alpha))


static func _adsr_envelope(t: float, a: float, d: float, s: float, r: float, gate_time: float) -> float:
	if t < a:
		return t / a
	elif t < a + d:
		return 1.0 - (1.0 - s) * ((t - a) / d)
	elif t < gate_time:
		return s
	else:
		var release_t = t - gate_time
		return s * max(0.0, 1.0 - release_t / r)


static func get_duration() -> float:
	return 2.0


static func get_description() -> String:
	return "CS-80 Lead - Singing, expressive solo voice with delayed vibrato, pitch bend response, and resonant filter."
