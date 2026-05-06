# TR-808 Snare Drum
# Noise burst + two sine tones for that punchy synthetic snare
extends RefCounted
class_name TR808Snare

const SAMPLE_RATE = 44100.0

# Two tone oscillators (808 snare uses two tuned resonators)
var tone1_freq: float = 185.0  # Lower body tone
var tone2_freq: float = 330.0  # Upper body tone
var tone_decay: float = 0.15
var tone_level: float = 0.5

# Noise component
var noise_color: float = 0.7  # 0 = dark, 1 = bright
var noise_decay: float = 0.18
var noise_level: float = 0.6

# Envelope
var snap: float = 0.4  # Attack transient emphasis

# Internal state
var phase1: float = 0.0
var phase2: float = 0.0
var trigger_time: float = 0.0
var is_playing: bool = false
var velocity: float = 1.0
var noise_hp_state: float = 0.0


func trigger(vel: float = 1.0):
	phase1 = 0.0
	phase2 = 0.0
	trigger_time = 0.0
	is_playing = true
	velocity = vel


func generate_sample(_time: float) -> Dictionary:
	if not is_playing:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	trigger_time += dt
	
	# Tone envelope (exponential decay)
	var tone_env = pow(max(0.0, 1.0 - trigger_time / tone_decay), 2.0)
	
	# Noise envelope (slightly longer)
	var noise_env = pow(max(0.0, 1.0 - trigger_time / noise_decay), 1.5)
	
	if tone_env < 0.001 and noise_env < 0.001:
		is_playing = false
		return {"left": 0.0, "right": 0.0}
	
	# Two sine tones
	phase1 += tone1_freq / SAMPLE_RATE
	phase2 += tone2_freq / SAMPLE_RATE
	phase1 = fmod(phase1, 1.0)
	phase2 = fmod(phase2, 1.0)
	
	var tones = (sin(phase1 * TAU) + sin(phase2 * TAU) * 0.7) * tone_env * tone_level
	
	# Noise (filtered)
	var noise = randf() * 2.0 - 1.0
	
	# High-pass filter for noise brightness
	var hp_freq = 1000.0 + noise_color * 4000.0
	noise_hp_state += (noise - noise_hp_state) * (hp_freq / SAMPLE_RATE)
	var filtered_noise = noise - noise_hp_state
	filtered_noise *= noise_env * noise_level
	
	# Snap transient
	var snap_env = 0.0
	if trigger_time < 0.01:
		snap_env = (1.0 - trigger_time / 0.01) * snap
	
	var output = (tones + filtered_noise) * (1.0 + snap_env) * velocity * 0.6
	
	return {"left": output, "right": output}


func set_preset(preset_name: String):
	match preset_name:
		"classic":
			tone1_freq = 185.0
			tone2_freq = 330.0
			noise_color = 0.7
			snap = 0.4
		"tight":
			tone_decay = 0.1
			noise_decay = 0.12
			snap = 0.6
		"fat":
			tone1_freq = 160.0
			tone2_freq = 280.0
			tone_level = 0.6
			noise_level = 0.4
			tone_decay = 0.2
