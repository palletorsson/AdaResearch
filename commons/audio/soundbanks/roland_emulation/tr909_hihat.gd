# TR-909 Hi-Hat (Closed and Open)
# Metallic ring character — 6 detuned square waves create the "tssss"
extends RefCounted
class_name TR909HiHat

const SAMPLE_RATE = 44100.0

# The 909's secret: 6 square waves at specific frequencies create metallic ring
# These frequencies are based on analysis of the original
const METAL_FREQS: Array = [205.0, 263.0, 328.0, 390.0, 437.0, 518.0]

# Envelope
var closed_decay: float = 0.035
var open_decay: float = 0.4
var is_open: bool = false

# Tone shaping
var metal_mix: float = 0.7  # Metallic component
var noise_mix: float = 0.3  # Noise component
var highpass_freq: float = 7500.0
var bandpass_freq: float = 9500.0
var bandpass_q: float = 2.0

# Internal state
var phases: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var hp_state: float = 0.0
var bp_states: Array = [0.0, 0.0]


func trigger(vel: float = 1.0, open: bool = false):
	trigger_time = 0.0
	is_playing = true
	velocity = vel
	is_open = open
	# Reset phases for consistent attack
	for i in 6:
		phases[i] = randf() * 0.1  # Slight randomness


func trigger_closed(vel: float = 1.0):
	trigger(vel, false)


func trigger_open(vel: float = 1.0):
	trigger(vel, true)


func choke():
	is_playing = false


func generate_sample(time_since_trigger: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	var decay = open_decay if is_open else closed_decay
	var amp = pow(max(0.0, 1.0 - trigger_time / decay), 1.5)
	
	if amp < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Generate 6 square waves (the metallic component)
	var metal = 0.0
	for i in 6:
		phases[i] += METAL_FREQS[i] / SAMPLE_RATE
		phases[i] = fmod(phases[i], 1.0)
		metal += (1.0 if phases[i] < 0.5 else -1.0) / 6.0
	
	# Noise component
	var noise = randf() * 2.0 - 1.0
	
	# Mix metal and noise
	var mixed = metal * metal_mix + noise * noise_mix
	
	# Bandpass filter (gives the 909 its focused "tsss")
	var filtered = _bandpass(mixed)
	
	# High-pass to remove any low rumble
	hp_state += (filtered - hp_state) * (highpass_freq / SAMPLE_RATE)
	var output = filtered - hp_state
	
	output *= amp * velocity * 0.5
	
	# Slight stereo for interest
	var pan = 0.55 + sin(trigger_time * 100.0) * 0.05
	return {"left": output * (1.0 - pan + 0.5), "right": output * (pan + 0.5)}


func _bandpass(input: float) -> float:
	# Simple 2-pole bandpass
	var f = bandpass_freq / SAMPLE_RATE
	var q = bandpass_q
	
	bp_states[0] += f * (input - bp_states[0] - q * bp_states[1])
	bp_states[1] += f * bp_states[0]
	
	return bp_states[0]
