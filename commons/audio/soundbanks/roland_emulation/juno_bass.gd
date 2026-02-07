# Juno-106 Bass
# Punchy, round, sits perfectly in a mix
extends RefCounted
class_name JunoBass

const SAMPLE_RATE = 44100.0

# Oscillator
var waveform: String = "square"  # "square" or "saw"
var sub_osc_level: float = 0.5  # Square -1 octave
var pulse_width: float = 0.5  # For square wave

# Filter
var filter_cutoff: float = 800.0  # Lower for bass
var filter_resonance: float = 0.3  # Slight bump
var filter_env_amount: float = 1200.0  # Envelope opens filter
var filter_env_decay: float = 0.15  # Quick decay for punch

# Amp envelope (punchy)
var amp_attack: float = 0.003
var amp_decay: float = 0.2
var amp_sustain: float = 0.7
var amp_release: float = 0.15

# Character
var drive: float = 0.15  # Subtle saturation
var glide: float = 0.0  # Portamento in seconds

# Internal state
var phase: float = 0.0
var sub_phase: float = 0.0
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var current_freq: float = 110.0
var target_freq: float = 110.0
var filter_state: Array = [0.0, 0.0]
var amp_env: float = 0.0
var amp_env_phase: String = "off"


func trigger(freq: float, vel: float = 1.0):
	target_freq = freq
	if glide <= 0.0:
		current_freq = freq
	trigger_time = 0.0
	is_playing = true
	amp_env_phase = "attack"
	amp_env = 0.0
	velocity = vel


func release():
	amp_env_phase = "release"


func generate_sample(time: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Glide
	if glide > 0.0:
		var glide_rate = 1.0 - exp(-dt / glide)
		current_freq = lerp(current_freq, target_freq, glide_rate)
	
	# Update amp envelope
	_update_amp_env(dt)
	
	if amp_env < 0.001 and amp_env_phase == "off":
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Main oscillator
	phase += current_freq / SAMPLE_RATE
	phase = fmod(phase, 1.0)
	
	var osc = 0.0
	if waveform == "square":
		osc = 1.0 if phase < pulse_width else -1.0
	else:  # saw
		osc = phase * 2.0 - 1.0
	
	# Sub oscillator (square, -1 octave)
	sub_phase += (current_freq * 0.5) / SAMPLE_RATE
	sub_phase = fmod(sub_phase, 1.0)
	var sub = (1.0 if sub_phase < 0.5 else -1.0) * sub_osc_level
	
	var mixed = osc * 0.7 + sub
	
	# Filter with envelope
	var filter_env = pow(max(0.0, 1.0 - trigger_time / filter_env_decay), 2.0)
	var cutoff = filter_cutoff + filter_env * filter_env_amount
	var filtered = _lowpass(mixed, cutoff)
	
	# Drive
	if drive > 0.0:
		filtered = tanh(filtered * (1.0 + drive * 3.0)) / (1.0 + drive)
	
	var output = filtered * amp_env * velocity * 0.7
	
	return {"left": output, "right": output}


func _update_amp_env(dt: float):
	match amp_env_phase:
		"attack":
			amp_env += dt / amp_attack
			if amp_env >= 1.0:
				amp_env = 1.0
				amp_env_phase = "decay"
		"decay":
			amp_env -= dt / amp_decay * (1.0 - amp_sustain)
			if amp_env <= amp_sustain:
				amp_env = amp_sustain
				amp_env_phase = "sustain"
		"sustain":
			amp_env = amp_sustain
		"release":
			amp_env -= dt / amp_release
			if amp_env <= 0.0:
				amp_env = 0.0
				amp_env_phase = "off"


func _lowpass(input: float, cutoff: float) -> float:
	var f = clamp(cutoff / SAMPLE_RATE, 0.01, 0.49)
	var fb = filter_resonance + filter_resonance / (1.0 - f)
	
	filter_state[0] += f * (input - filter_state[0] + fb * (filter_state[0] - filter_state[1]))
	filter_state[1] += f * (filter_state[0] - filter_state[1])
	
	return filter_state[1]


func set_preset(preset_name: String):
	match preset_name:
		"classic":
			waveform = "square"
			sub_osc_level = 0.5
			filter_cutoff = 800.0
			filter_env_amount = 1200.0
		"acid":
			waveform = "saw"
			sub_osc_level = 0.3
			filter_cutoff = 400.0
			filter_resonance = 0.6
			filter_env_amount = 2000.0
			filter_env_decay = 0.1
		"sub":
			waveform = "square"
			sub_osc_level = 0.8
			filter_cutoff = 500.0
			filter_env_amount = 600.0
			drive = 0.05
