# cr5000_hihat.gd
# Roland CR-5000 CompuRhythm hi-hat
# Character: Crisp, metallic, classic analog hi-hat
# Source: Roland CR-5000 (1980)
# Processing: High-pass filtered noise

# Technical anatomy:
# - Filtered noise (high-pass)
# - Short decay for closed, longer for open
# - Metallic shimmer from bandpass resonance
# - Cleaner than 808, less dark

class_name CR5000Hihat
extends RefCounted

const SAMPLE_RATE = 44100.0

# CR-5000 hi-hat parameters
const HPF_CUTOFF_HZ = 7000.0
const RESONANCE_FREQ_HZ = 8500.0
const RESONANCE_Q = 4.0
const CLOSED_DECAY_MS = 40.0
const OPEN_DECAY_MS = 250.0


static func generate(t: float, freq: float = 0.0, params: Dictionary = {}) -> float:
	var open = params.get("open", 0.0)  # 0 = closed, 1 = open
	var tone = params.get("tone", 0.5)
	
	# Decay time interpolated between closed and open
	var decay = lerp(CLOSED_DECAY_MS, OPEN_DECAY_MS, open) / 1000.0
	
	# Noise source
	var noise = randf() * 2.0 - 1.0
	
	# Metallic component (high frequency squares like 909)
	# But CR-5000 is more noise-based
	var metallic = sin(TAU * RESONANCE_FREQ_HZ * t) * 0.3
	metallic += sin(TAU * RESONANCE_FREQ_HZ * 1.34 * t) * 0.2
	metallic += sin(TAU * RESONANCE_FREQ_HZ * 1.67 * t) * 0.15
	
	# Mix noise and metallic based on tone
	var output = noise * (1.0 - tone * 0.5) + metallic * tone
	
	# Envelope
	var env = exp(-t / decay)
	
	return clamp(output * env * 0.5, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3


static func get_description() -> String:
	return "CR-5000 Hi-Hat - Crisp metallic hi-hat with adjustable open/closed decay and tonal character."
