# Dark Wave Snare - Sharp Gated Crack
# Research: dark_wave brief
#
# Character: Sharp, cracking, gated. The defining rhythmic element of dark wave.
#   Think She Past Away "Ritüel" — the snare CRACKS on 2 and 4, tight reverb tail
#   that dies fast. NOT a booming 80s gated reverb (that's synthwave/Phil Collins).
#   This is SHORTER, drier, more aggressive.
# Source: Simmons SDS-V / LinnDrum hybrid, short plate reverb with gate
# Processing: Short reverb (plate, ~0.8s), gated at 80ms. Pre-delay 15ms.
#
# Key specs:
#   Body: 180 Hz sine, 15ms decay
#   Noise: bandpassed white noise (1kHz-6kHz), 25ms decay
#   Reverb: plate-style, 80ms gate length (short!), 0.3 mix
#   Total duration: ~200ms including reverb tail
#   Character: CRACK, not boom. Snappy, not washy.

class_name DarkWaveSnare
extends RefCounted

const SAMPLE_RATE = 44100.0

# Gated crack snare
const BODY_FREQ_HZ = 180.0        # Snare body fundamental
const BODY_DECAY_S = 0.015        # Very fast body decay
const NOISE_DECAY_S = 0.025       # Short noise — crack, not wash
const REVERB_GATE_S = 0.08        # Gate cuts at 80ms — short tail
const REVERB_PREDELAY_S = 0.015   # 15ms pre-delay for clarity
const REVERB_MIX = 0.3            # Less reverb than synthwave
const TRANSIENT_LEVEL = 0.6       # Strong initial transient
const LEVEL = 0.38


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.3:
		return 0.0
	
	# Body — pitched sine component
	var body = sin(2.0 * PI * BODY_FREQ_HZ * dt) * exp(-dt / BODY_DECAY_S)
	
	# Noise — bandpass character via mixing two noise bands
	var noise_raw = randf() * 2.0 - 1.0
	# Simulate bandpass by mixing high-freq sine components with noise
	var noise_shaped = noise_raw * 0.6 + sin(2.0 * PI * 4200.0 * dt) * noise_raw * 0.4
	var noise = noise_shaped * exp(-dt / NOISE_DECAY_S) * 0.5
	
	# Hard transient — initial crack
	var transient = 0.0
	if dt < 0.003:
		transient = (randf() * 2.0 - 1.0) * TRANSIENT_LEVEL * (1.0 - dt / 0.003)
	
	# Dry signal
	var dry = body * 0.3 + noise + transient
	
	# Gated reverb — starts after pre-delay, hard cut at gate length
	var reverb = 0.0
	var rev_dt = dt - REVERB_PREDELAY_S
	if rev_dt > 0.0 and rev_dt < REVERB_GATE_S:
		# Reverb builds then the gate kills it
		var rev_env = (1.0 - exp(-rev_dt * 20.0)) * (1.0 - rev_dt / REVERB_GATE_S)
		reverb = (randf() * 2.0 - 1.0) * rev_env * REVERB_MIX
	
	return clampf((dry + reverb) * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.3
