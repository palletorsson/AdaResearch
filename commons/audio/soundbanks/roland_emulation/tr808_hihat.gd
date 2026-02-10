# TR-808 Hi-Hat (Closed and Open)
# Pure noise character â€” "shhh" rather than metallic ring
extends RefCounted
class_name TR808HiHat

const SAMPLE_RATE = 44100.0

# Filter parameters
var highpass_freq: float = 8000.0  # High-pass for brightness
var lowpass_freq: float = 14000.0  # Slight rolloff at top
var bandpass_q: float = 0.7  # Filter resonance

# Envelope
var closed_decay: float = 0.045  # Short, tight
var open_decay: float = 0.35  # Long, sustained
var is_open: bool = false

# Tone shaping
var brightness: float = 0.7  # Mix of noise bands
var body: float = 0.3  # Lower frequency content

# Internal state
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var hp_state: Array = [0.0, 0.0]
var lp_state: float = 0.0


func trigger(vel: float = 1.0, open: bool = false):
	trigger_time = 0.0
	is_playing = true
	velocity = vel
	is_open = open


func trigger_closed(vel: float = 1.0):
	trigger(vel, false)


func trigger_open(vel: float = 1.0):
	trigger(vel, true)


func choke():
	# Open hat choked by closed hat
	is_playing = false


func generate_sample(_time_since_trigger: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	var decay = open_decay if is_open else closed_decay
	
	# Envelope
	var amp = pow(max(0.0, 1.0 - trigger_time / decay), 2.0)
	
	if amp < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# White noise source
	var noise = randf() * 2.0 - 1.0
	
	# High-pass filter (removes low rumble)
	var hp_output = _highpass(noise)
	
	# Low-pass filter (slight smoothing)
	lp_state += (hp_output - lp_state) * (lowpass_freq * 2.0 / SAMPLE_RATE)
	
	# Mix filtered and raw for character
	var output = lp_state * brightness + hp_output * body * 0.3
	output *= amp * velocity * 0.6
	
	# Slight stereo spread
	var stereo_offset = (randf() - 0.5) * 0.1
	return {"left": output * (1.0 - stereo_offset), "right": output * (1.0 + stereo_offset)}


func _highpass(input: float) -> float:
	# 2-pole highpass
	var f = highpass_freq / SAMPLE_RATE
	var output = input - hp_state[0]
	hp_state[0] += f * output
	output = output - hp_state[1]
	hp_state[1] += f * output
	return output * 2.0  # Gain compensation
