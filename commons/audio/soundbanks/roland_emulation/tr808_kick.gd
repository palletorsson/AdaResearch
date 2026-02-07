# TR-808 Bass Drum
# The sine wave that launched hip-hop, trap, and modern bass music
extends RefCounted
class_name TR808Kick

const SAMPLE_RATE = 44100.0

# Pitch envelope — the 808 kick's defining characteristic
var pitch_start: float = 160.0  # Starting frequency (the "click")
var pitch_end: float = 48.0  # Ending frequency (the sub)
var pitch_decay: float = 0.055  # Seconds — how fast it drops

# Amplitude envelope
var amp_attack: float = 0.002  # Very fast attack
var amp_decay: float = 0.6  # Long decay for that sustained boom
var amp_click: float = 0.15  # Short click transient amount

# Tone shaping
var drive: float = 0.2  # Subtle saturation for punch
var sub_boost: float = 1.2  # Boost the fundamental
var click_freq: float = 2200.0  # High-frequency click component

# Internal state
var phase: float = 0.0
var click_phase: float = 0.0
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0


func trigger(vel: float = 1.0):
	phase = 0.0
	click_phase = 0.0
	trigger_time = 0.0
	is_playing = true
	velocity = vel


func generate_sample(time_since_trigger: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Pitch envelope (exponential decay)
	var pitch_t = clamp(trigger_time / pitch_decay, 0.0, 1.0)
	# Exponential curve for natural pitch drop
	var current_pitch = pitch_end + (pitch_start - pitch_end) * pow(1.0 - pitch_t, 2.0)
	
	# Main sine oscillator
	phase += current_pitch / SAMPLE_RATE
	phase = fmod(phase, 1.0)
	var main_osc = sin(phase * TAU)
	
	# Click transient (short high-frequency burst)
	var click = 0.0
	if trigger_time < 0.01:
		click_phase += click_freq / SAMPLE_RATE
		click = sin(click_phase * TAU) * (1.0 - trigger_time / 0.01) * amp_click
	
	# Amplitude envelope
	var amp = 0.0
	if trigger_time < amp_attack:
		amp = trigger_time / amp_attack
	else:
		var decay_t = (trigger_time - amp_attack) / amp_decay
		amp = pow(max(0.0, 1.0 - decay_t), 1.5)  # Curved decay
	
	if amp < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Combine and shape
	var output = (main_osc * sub_boost + click) * amp * velocity
	
	# Soft saturation for punch
	if drive > 0.0:
		output = _soft_clip(output, drive)
	
	# 808 is mono, centered
	return {"left": output * 0.8, "right": output * 0.8}


func _soft_clip(x: float, amount: float) -> float:
	# Tube-style soft clipping
	var threshold = 1.0 - amount * 0.5
	if abs(x) < threshold:
		return x
	var sign_x = sign(x)
	var excess = abs(x) - threshold
	var compressed = threshold + (1.0 - threshold) * tanh(excess / (1.0 - threshold))
	return sign_x * compressed


# Preset variations
func set_preset(preset_name: String):
	match preset_name:
		"classic":
			pitch_start = 160.0
			pitch_end = 48.0
			pitch_decay = 0.055
			amp_decay = 0.6
			drive = 0.2
		"sub_heavy":
			pitch_start = 120.0
			pitch_end = 38.0
			pitch_decay = 0.04
			amp_decay = 0.9
			drive = 0.1
			sub_boost = 1.5
		"punchy":
			pitch_start = 220.0
			pitch_end = 55.0
			pitch_decay = 0.035
			amp_decay = 0.4
			drive = 0.35
			amp_click = 0.25
		"trap":
			pitch_start = 140.0
			pitch_end = 32.0
			pitch_decay = 0.06
			amp_decay = 1.2
			drive = 0.15
			sub_boost = 1.8
