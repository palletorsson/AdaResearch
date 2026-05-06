# prophet_pad.gd
# Sequential Prophet-5 pad - warm, rich, quintessential analog poly
# Character: Fat, warm, smooth, slightly dark
# Source: Prophet-5 Rev 3 (SSM chips)
# Processing: Subtle chorus, reverb

# Technical anatomy:
# - 2 VCOs per voice (saw + pulse typical)
# - CEM/SSM filter - warmer than CS-80
# - 5 voices (thinner than CS-80's 8)
# - Poly-mod for subtle FM effects
# - No aftertouch (less expressive than CS-80)

class_name ProphetPad
extends RefCounted

const SAMPLE_RATE = 44100.0

# Prophet-5 pad parameters
const PULSE_WIDTH = 0.45  # Slightly off 50% for movement
const PWM_DEPTH = 0.15
const PWM_RATE_HZ = 0.4
const DETUNE_CENTS = 6.0
const LPF_CUTOFF_HZ = 2200.0
const LPF_ENV_DEPTH_HZ = 1500.0
const RESONANCE = 0.2
const ATTACK_MS = 250.0
const DECAY_MS = 400.0
const SUSTAIN = 0.7
const RELEASE_MS = 600.0
const POLY_MOD_AMOUNT = 0.02  # Subtle FM for animation


static func generate(t: float, freq: float, params: Dictionary = {}) -> float:
	var warmth = params.get("warmth", 0.6)
	var movement = params.get("movement", 0.5)
	
	# PWM on pulse oscillator
	var pwm = sin(TAU * PWM_RATE_HZ * t) * PWM_DEPTH * movement
	var pulse_width = PULSE_WIDTH + pwm
	
	# Oscillator 1: Sawtooth
	var osc1 = _saw(t, freq)
	
	# Oscillator 2: Pulse with PWM
	var detune_ratio = pow(2.0, DETUNE_CENTS / 1200.0)
	var osc2 = _pulse(t, freq * detune_ratio, pulse_width)
	
	# Poly-mod: OSC1 modulates OSC2 frequency slightly (subtle FM)
	var poly_mod = osc1 * POLY_MOD_AMOUNT
	osc2 = _pulse(t, freq * detune_ratio * (1.0 + poly_mod), pulse_width)
	
	# Mix
	var mix = (osc1 * 0.6 + osc2 * 0.4)
	
	# Filter envelope
	var filter_env = _filter_envelope(t, 0.05, 0.5)
	var cutoff = LPF_CUTOFF_HZ + filter_env * LPF_ENV_DEPTH_HZ * warmth
	var filtered = _lpf(mix, cutoff, RESONANCE)
	
	# Amplitude envelope
	var env = _adsr_envelope(t, ATTACK_MS/1000.0, DECAY_MS/1000.0, SUSTAIN, RELEASE_MS/1000.0, 2.0)
	
	return clamp(filtered * env * 0.7, -1.0, 1.0)


static func _saw(t: float, freq: float) -> float:
	return fmod(freq * t, 1.0) * 2.0 - 1.0


static func _pulse(t: float, freq: float, width: float) -> float:
	return 1.0 if fmod(freq * t, 1.0) < width else -1.0


static func _filter_envelope(t: float, attack: float, decay: float) -> float:
	if t < attack:
		return t / attack
	else:
		return exp(-(t - attack) / decay)


static func _lpf(input: float, cutoff_hz: float, reso: float) -> float:
	var alpha = cutoff_hz / (cutoff_hz + SAMPLE_RATE / TAU)
	return input * alpha * (1.0 + reso * 2.0 * (1.0 - alpha))


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
	return 2.5


static func get_description() -> String:
	return "Prophet-5 Pad - Warm analog poly pad with saw + PWM pulse, poly-mod animation, classic SSM filter warmth."
