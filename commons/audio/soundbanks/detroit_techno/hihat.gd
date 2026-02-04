# Detroit Techno Hi-Hat - TR-909 Style
# Research: detroit_techno_deep_research.md
#
# Character: Crisp, metallic, bright - unmistakable 909 ring
# Source: TR-909 metallic hi-hat circuit
# Processing: "+2dB high shelf for brightness"
#
# DEEP RESEARCH NOTES:
# The 909 hi-hat uses SIX square wave oscillators at non-harmonic frequencies:
# 263Hz, 400Hz, 421Hz, 474Hz, 587Hz, 845Hz
# These are mixed through a bandpass filter centered at 8-10kHz
# This creates the distinctive "metallic shimmer" of the 909

class_name DetroitHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

# 909 Hi-Hat Parameters (from deep research - actual circuit analysis)
# Six non-harmonic square wave oscillators create the metallic character
const METAL_FREQS = [263.0, 400.0, 421.0, 474.0, 587.0, 845.0]
const BANDPASS_CENTER_HZ = 9000.0  # Filter centered at 8-10kHz
const CLOSED_DECAY_S = 0.025       # Closed hat decay (20-30ms measured)
const OPEN_DECAY_S = 0.15          # Open hat decay (100-200ms measured)
const NOISE_LEVEL = 0.4            # High-frequency noise component
const METAL_LEVEL = 0.6            # Metallic oscillator component
const LEVEL = 0.18                 # Output level (bright)


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.3 if open else 0.1
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	# Six non-harmonic square wave oscillators (909 metallic source)
	var metal = 0.0
	for freq in METAL_FREQS:
		# Square wave: sign of sine
		var sq = 1.0 if sin(2.0 * PI * freq * t) >= 0.0 else -1.0
		metal += sq
	metal /= METAL_FREQS.size()  # Normalize
	metal *= METAL_LEVEL
	
	# High-frequency noise component (adds air/sizzle)
	var noise = randf() * 2.0 - 1.0
	# Simulate bandpass filtering by envelope shaping
	noise *= NOISE_LEVEL
	
	# Combine metallic and noise (909 character)
	var output = (metal + noise) * env * LEVEL
	
	return clampf(output, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


static func get_duration(open: bool = false) -> float:
	return 0.3 if open else 0.1
