# Detroit Techno Hi-Hat - TR-909 Style
# Research: detroit_techno.md
#
# Character: Crisp, metallic, bright
# Source: TR-909 metallic hi-hat circuit
# Processing: "+2dB high shelf for brightness"

class_name DetroitHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Hi-Hat Parameters (from research)
# "Crisp hi-hats"
# "High shelf boost +2dB for brightness"
const METAL_FREQ_HZ = 9000.0      # Metallic tone
const METAL_FREQ_2_HZ = 7500.0    # Second metallic partial
const CLOSED_DECAY_S = 0.025      # Closed hat decay
const OPEN_DECAY_S = 0.15         # Open hat decay
const NOISE_LEVEL = 0.7           # Noise component
const METAL_LEVEL = 0.3           # Metallic component
const LEVEL = 0.18                # Output level (bright)


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.3 if open else 0.1
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	# Noise component (filtered high)
	var noise = randf() * 2.0 - 1.0
	noise *= NOISE_LEVEL
	
	# Metallic ring (909 characteristic)
	var metal = sin(2.0 * PI * METAL_FREQ_HZ * dt) * 0.6
	metal += sin(2.0 * PI * METAL_FREQ_2_HZ * dt) * 0.4
	metal *= METAL_LEVEL
	
	var output = (noise + metal) * env * LEVEL
	
	return clampf(output, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


static func get_duration(open: bool = false) -> float:
	return 0.3 if open else 0.1
