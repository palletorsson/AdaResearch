# TR-909 Kick Drum
# Punchier and tighter than the 808 â€” the heartbeat of house and techno
extends RefCounted
class_name TR909Kick

const SAMPLE_RATE = 44100.0

# Pitch envelope â€” faster and punchier than 808
var pitch_start: float = 280.0  # Higher start = more attack
var pitch_end: float = 58.0  # Slightly higher end than 808
var pitch_decay: float = 0.028  # Faster pitch drop

# Amplitude envelope â€” tighter than 808
var amp_attack: float = 0.001  # Instant attack
var amp_decay: float = 0.35  # Shorter decay = punchier

# Noise click (909 has a distinct noise transient)
var click_level: float = 0.25
var click_decay: float = 0.008  # Very short noise burst
var click_filter: float = 3500.0  # Filtered noise

# Compression/punch character
var punch: float = 0.4  # Attack emphasis
var drive: float = 0.25

# Internal state
var phase: float = 0.0
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var noise_state: float = 0.0


func trigger(vel: float = 1.0):
	phase = 0.0
	trigger_time = 0.0
	is_playing = true
	velocity = vel


func generate_sample(_time_since_trigger: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Faster exponential pitch envelope
	var pitch_t = clamp(trigger_time / pitch_decay, 0.0, 1.0)
	var current_pitch = pitch_end + (pitch_start - pitch_end) * pow(1.0 - pitch_t, 3.0)
	
	# Main sine body
	phase += current_pitch / SAMPLE_RATE
	phase = fmod(phase, 1.0)
	var body = sin(phase * TAU)
	
	# Noise click (909 characteristic)
	var click = 0.0
	if trigger_time < click_decay:
		var noise = randf() * 2.0 - 1.0
		# Simple lowpass on noise
		noise_state += (noise - noise_state) * (click_filter / SAMPLE_RATE)
		click = noise_state * click_level * (1.0 - trigger_time / click_decay)
	
	# Amp envelope with punch emphasis
	var amp = 0.0
	if trigger_time < amp_attack:
		amp = trigger_time / amp_attack
	else:
		var decay_t = (trigger_time - amp_attack) / amp_decay
		amp = pow(max(0.0, 1.0 - decay_t), 1.8)
	
	# Punch transient (boost the attack)
	var punch_env = 0.0
	if trigger_time < 0.015:
		punch_env = (1.0 - trigger_time / 0.015) * punch
	
	if amp < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Mix body and click
	var output = (body + click) * (amp + punch_env) * velocity
	
	# Drive for that 909 crunch
	if drive > 0.0:
		output = _hard_clip(output, drive)
	
	return {"left": output * 0.8, "right": output * 0.8}


func _hard_clip(x: float, amount: float) -> float:
	# 909 has a harder, crunchier clip than 808
	var ceiling = 1.0 - amount * 0.3
	return clamp(x, -ceiling, ceiling) / ceiling


func set_preset(preset_name: String):
	match preset_name:
		"classic":
			pitch_start = 280.0
			pitch_end = 58.0
			pitch_decay = 0.028
			amp_decay = 0.35
			click_level = 0.25
		"hard":
			pitch_start = 350.0
			pitch_end = 62.0
			pitch_decay = 0.02
			amp_decay = 0.25
			click_level = 0.35
			drive = 0.4
		"deep_house":
			pitch_start = 200.0
			pitch_end = 50.0
			pitch_decay = 0.04
			amp_decay = 0.5
			click_level = 0.15
			punch = 0.25
		"gabber":
			pitch_start = 400.0
			pitch_end = 70.0
			pitch_decay = 0.015
			amp_decay = 0.2
			drive = 0.6
			punch = 0.6
