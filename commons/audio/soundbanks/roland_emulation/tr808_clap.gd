# TR-808 Hand Clap
# Multiple staggered noise bursts create the "spread" effect
extends RefCounted
class_name TR808Clap

const SAMPLE_RATE = 44100.0

# The 808 clap is 4 noise bursts in quick succession
const BURST_COUNT = 4
var burst_spacing: float = 0.012  # 12ms between bursts
var burst_decay: float = 0.008  # Each burst is very short

# Overall envelope
var body_decay: float = 0.25  # The reverb tail
var reverb_level: float = 0.5

# Filter
var bandpass_freq: float = 1200.0
var bandpass_q: float = 1.5
var highpass_freq: float = 800.0

# Internal state
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var bp_state: Array = [0.0, 0.0]
var hp_state: float = 0.0

# Simple reverb
var reverb_buffer: PackedFloat32Array
var reverb_pos: int = 0
const REVERB_SIZE = 22050  # 0.5 seconds


func _init():
	reverb_buffer.resize(REVERB_SIZE)
	reverb_buffer.fill(0.0)


func trigger(vel: float = 1.0):
	trigger_time = 0.0
	is_playing = true
	velocity = vel
	bp_state = [0.0, 0.0]
	hp_state = 0.0


func generate_sample(_time: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Overall body envelope
	var body_env = pow(max(0.0, 1.0 - trigger_time / body_decay), 1.5)
	
	if body_env < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Generate burst envelope (4 staggered bursts)
	var burst_env = 0.0
	for i in BURST_COUNT:
		var burst_time = trigger_time - i * burst_spacing
		if burst_time > 0.0 and burst_time < burst_decay * 3.0:
			burst_env += pow(max(0.0, 1.0 - burst_time / burst_decay), 2.0)
	burst_env = min(burst_env, 1.5)  # Limit overlap
	
	# Noise source
	var noise = randf() * 2.0 - 1.0
	
	# Bandpass filter (gives clap its focused character)
	var filtered = _bandpass(noise)
	
	# High-pass to remove low rumble
	hp_state += (filtered - hp_state) * (highpass_freq / SAMPLE_RATE)
	filtered = filtered - hp_state
	
	# Apply burst envelope
	var dry = filtered * burst_env
	
	# Simple reverb tail
	var wet = _reverb(dry)
	
	var output = (dry + wet * reverb_level) * body_env * velocity * 0.7
	
	# Slight stereo spread
	var spread = (randf() - 0.5) * 0.15
	return {"left": output * (1.0 - spread), "right": output * (1.0 + spread)}


func _bandpass(input: float) -> float:
	var f = bandpass_freq / SAMPLE_RATE
	var q = bandpass_q
	
	bp_state[0] += f * (input - bp_state[0] - q * bp_state[1])
	bp_state[1] += f * bp_state[0]
	
	return bp_state[0] * 2.0


func _reverb(input: float) -> float:
	reverb_buffer[reverb_pos] = input
	
	# Multiple delay taps for diffuse reverb
	var output = 0.0
	var taps = [0.1, 0.23, 0.37, 0.53, 0.71, 0.89]
	for tap in taps:
		var read_pos = reverb_pos - int(REVERB_SIZE * tap)
		if read_pos < 0:
			read_pos += REVERB_SIZE
		output += reverb_buffer[read_pos] * (1.0 - tap) * 0.15
	
	reverb_pos = (reverb_pos + 1) % REVERB_SIZE
	return output


func set_preset(preset_name: String):
	match preset_name:
		"classic":
			burst_spacing = 0.012
			body_decay = 0.25
			reverb_level = 0.5
		"tight":
			burst_spacing = 0.008
			body_decay = 0.15
			reverb_level = 0.3
		"big":
			burst_spacing = 0.015
			body_decay = 0.4
			reverb_level = 0.7
