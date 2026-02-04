# Moroder Disco Sequencer - THE sound of "I Feel Love"
# Character: Hypnotic 16th-note pulse, filter sweeps
# Source: Moog Modular

class_name MoroderSequencer
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.10

# Filter state (static for continuous operation)
static var filter_state: float = 0.0

static func generate(t: float, freq: float, duration: float = 0.1, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.12:
		return 0.0
	
	# Sawtooth oscillator (the motor)
	var saw = fmod(freq * dt, 1.0) * 2.0 - 1.0
	
	# Add slight detune for thickness
	var saw2 = fmod(freq * 1.003 * dt, 1.0) * 2.0 - 1.0
	var output = (saw + saw2) * 0.5
	
	# Resonant lowpass filter with envelope
	var env_pos = dt / 0.12
	var filter_cutoff = 800.0 + 2000.0 * (1.0 - env_pos)  # Filter closes
	var alpha = filter_cutoff / (filter_cutoff + SAMPLE_RATE / TAU)
	filter_state = filter_state + alpha * (output - filter_state)
	output = filter_state
	
	# Amplitude envelope (quick attack, medium release)
	var env = 1.0
	if dt < 0.005:
		env = dt / 0.005
	elif dt > 0.08:
		env = 1.0 - (dt - 0.08) / 0.04
	
	return clampf(output * env * LEVEL, -1.0, 1.0)

static func get_duration() -> float:
	return 0.12
