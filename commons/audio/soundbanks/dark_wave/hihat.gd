# Dark Wave Hi-Hat - Thin Metallic Closed
# Research: dark_wave brief
#
# Character: Thin, metallic, predominantly closed. Relentless 8th or 16th note pulse.
#   Think She Past Away's mechanical hi-hat pattern — it's a MACHINE, not a drummer.
#   Very thin, almost all high-frequency content. Sits on top of the mix like a
#   cold metallic whisper.
# Source: TR-606 / CR-78 character — cheaper, thinner than 808/909
# Processing: High-pass filtered, very short decay, minimal body
#
# Key specs:
#   Metal frequencies: 6500 Hz + 9200 Hz (thin, metallic)
#   Closed decay: 20ms (very tight)
#   Open decay: 80ms (still short for dark wave)
#   Noise character: high-passed, thin
#   Level: low — it's a texture element, not a lead percussion

class_name DarkWaveHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

# Thin metallic hi-hat
const METAL_FREQ_1_HZ = 6500.0    # Primary metallic tone
const METAL_FREQ_2_HZ = 9200.0    # Secondary — inharmonic for realism
const CLOSED_DECAY_S = 0.020      # Very tight closed hat
const OPEN_DECAY_S = 0.080        # Short open hat
const NOISE_MIX = 0.55            # Noise vs metallic balance
const METAL_MIX = 0.45
const LEVEL = 0.12                 # Quiet — texture, not dominant


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.15 if open else 0.06
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	# High-frequency noise (thin character)
	var noise = (randf() * 2.0 - 1.0) * NOISE_MIX
	
	# Metallic tones — two inharmonic frequencies for realistic cymbal
	var metal = (sin(2.0 * PI * METAL_FREQ_1_HZ * dt) * 0.6 +
				 sin(2.0 * PI * METAL_FREQ_2_HZ * dt) * 0.4) * METAL_MIX
	
	return clampf((noise + metal) * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


static func get_duration(open: bool = false) -> float:
	return 0.15 if open else 0.06
