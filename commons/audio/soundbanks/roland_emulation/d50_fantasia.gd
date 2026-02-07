# D-50 Fantasia
# The quintessential D-50 sound: bell attack + string sustain
# Used on countless 80s/90s ballads and film scores
extends RefCounted
class_name D50Fantasia

const SAMPLE_RATE = 44100.0
const VOICE_COUNT = 4

# Layer 1: Bell attack (short PCM-style transient)
var bell_decay: float = 0.3
var bell_brightness: float = 0.8
var bell_inharmonicity: float = 0.02  # Slight detuning for bell character
var bell_level: float = 0.5

# Layer 2: String sustain
var string_attack: float = 0.25
var string_release: float = 1.5
var string_detune: float = 6.0  # Cents
var string_voices: int = 4  # Ensemble size
var string_level: float = 0.7
var string_filter_cutoff: float = 3500.0

# Reverb (D-50 had built-in lush reverb)
var reverb_mix: float = 0.4
var reverb_decay: float = 2.5
var reverb_predelay: float = 0.03

# Internal state
var bell_phases: Array = []
var string_phases: Array = []
var trigger_time: float = 0.0
var is_playing: bool = false
var amp_env_phase: String = "off"
var amp_env_value: float = 0.0
var velocity: float = 1.0
var current_freq: float = 440.0

# Simple reverb buffer
var reverb_buffer: PackedFloat32Array
var reverb_pos: int = 0
const REVERB_SIZE = 44100  # 1 second buffer


func _init():
	bell_phases.resize(8)  # Multiple partials for bell
	string_phases.resize(string_voices)
	reverb_buffer.resize(REVERB_SIZE)
	reverb_buffer.fill(0.0)
	
	for i in 8:
		bell_phases[i] = randf()
	for i in string_voices:
		string_phases[i] = randf()


func trigger(freq: float, vel: float = 1.0):
	trigger_time = 0.0
	is_playing = true
	amp_env_phase = "attack"
	amp_env_value = 0.0
	velocity = vel
	current_freq = freq
	
	# Reset bell phases for consistent attack
	for i in 8:
		bell_phases[i] = randf() * 0.1


func release():
	amp_env_phase = "release"


func generate_sample(time: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Update amplitude envelope
	_update_amp_envelope(dt)
	
	if amp_env_value < 0.001 and amp_env_phase == "release":
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	var output_l = 0.0
	var output_r = 0.0
	
	# Layer 1: Bell attack (FM-style inharmonic partials)
	var bell = _generate_bell(dt)
	var bell_env = pow(max(0.0, 1.0 - trigger_time / bell_decay), 2.0)
	bell *= bell_env * bell_level
	
	# Layer 2: String sustain (detuned saws with slow attack)
	var string_result = _generate_strings(dt)
	var string_env = 0.0
	if trigger_time < string_attack:
		string_env = trigger_time / string_attack
	else:
		string_env = 1.0
	string_env *= amp_env_value
	
	# Combine layers
	output_l = (bell + string_result["left"] * string_env * string_level) * velocity
	output_r = (bell + string_result["right"] * string_env * string_level) * velocity
	
	# Apply reverb (D-50 signature)
	var reverbed = _apply_reverb((output_l + output_r) * 0.5)
	output_l = output_l * (1.0 - reverb_mix) + reverbed * reverb_mix
	output_r = output_r * (1.0 - reverb_mix) + reverbed * reverb_mix
	
	return {"left": output_l * 0.6, "right": output_r * 0.6}


func _generate_bell(dt: float) -> float:
	# FM-style bell: multiple inharmonic partials
	var output = 0.0
	var partials = [1.0, 2.0, 2.4, 3.0, 4.2, 5.0, 6.3, 7.1]  # Inharmonic series
	var amps = [1.0, 0.7, 0.5, 0.4, 0.3, 0.2, 0.15, 0.1]
	
	for i in 8:
		var partial_freq = current_freq * partials[i]
		partial_freq *= 1.0 + (randf() - 0.5) * bell_inharmonicity  # Slight random detune
		
		bell_phases[i] += partial_freq / SAMPLE_RATE
		bell_phases[i] = fmod(bell_phases[i], 1.0)
		
		# Sine waves for clean bell tone
		output += sin(bell_phases[i] * TAU) * amps[i]
	
	return output * bell_brightness * 0.15


func _generate_strings(dt: float) -> Dictionary:
	# Detuned saw ensemble for string character
	var left = 0.0
	var right = 0.0
	
	for i in string_voices:
		# Spread detune across voices
		var detune_cents = (float(i) / float(string_voices - 1) - 0.5) * string_detune * 2.0
		var freq = current_freq * pow(2.0, detune_cents / 1200.0)
		
		string_phases[i] += freq / SAMPLE_RATE
		string_phases[i] = fmod(string_phases[i], 1.0)
		
		# Saw wave
		var saw = string_phases[i] * 2.0 - 1.0
		
		# Pan voices for width
		var pan = float(i) / float(string_voices - 1)  # 0 to 1
		left += saw * (1.0 - pan) / float(string_voices)
		right += saw * pan / float(string_voices)
	
	# Simple lowpass filter
	left = _simple_lowpass(left, string_filter_cutoff)
	
	return {"left": left, "right": right}


var lp_state: float = 0.0
func _simple_lowpass(input: float, cutoff: float) -> float:
	var f = cutoff / SAMPLE_RATE
	lp_state += (input - lp_state) * f
	return lp_state


func _update_amp_envelope(dt: float):
	match amp_env_phase:
		"attack":
			amp_env_value += dt / string_attack
			if amp_env_value >= 1.0:
				amp_env_value = 1.0
				amp_env_phase = "sustain"
		"sustain":
			pass  # Hold at 1.0
		"release":
			amp_env_value -= dt / string_release
			if amp_env_value <= 0.0:
				amp_env_value = 0.0
				amp_env_phase = "off"


func _apply_reverb(input: float) -> float:
	# Simple comb filter reverb approximation
	var predelay_samples = int(reverb_predelay * SAMPLE_RATE)
	var decay_samples = int(reverb_decay * SAMPLE_RATE * 0.3)
	
	# Write to buffer
	reverb_buffer[reverb_pos] = input
	
	# Read from multiple taps
	var output = 0.0
	var taps = [0.3, 0.5, 0.7, 0.9]  # Tap positions as fraction of decay
	for tap in taps:
		var read_pos = reverb_pos - int(decay_samples * tap) - predelay_samples
		if read_pos < 0:
			read_pos += REVERB_SIZE
		output += reverb_buffer[read_pos % REVERB_SIZE] * (1.0 - tap) * 0.25
	
	reverb_pos = (reverb_pos + 1) % REVERB_SIZE
	
	return output
