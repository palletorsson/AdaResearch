# Dark Wave Clap - Dry Tight Layered
# Research: dark_wave_cathedral.json sound_design.drums.clap
#
# Character: 4 noise bursts spread across 8ms — "multiple hands" effect.
#   TIGHT spread (not loose 15-20ms of house claps). Short, sharp "crack"
#   that layers with the snare. Noise center at 2200Hz fills the mid-frequency
#   gap between snare (4500Hz) and toms (85-145Hz).
# Source: TR-606 style hand clap synthesis
# Processing: Dry, slight reverb send only

class_name DarkWaveClap
extends RefCounted

const SAMPLE_RATE = 44100.0

const NUM_LAYERS = 4              # Multiple "hands"
const LAYER_SPREAD_S = 0.008      # 8ms spread — TIGHT
const NOISE_CENTER_HZ = 2200.0    # Mid-frequency body
const NOISE_BW_HZ = 1800.0        # Bandwidth
const DECAY_S = 0.045             # 45ms — short, sharp
const REVERB_TAIL_LEVEL = 0.12    # Slight room tail
const REVERB_DECAY_S = 0.08       # Very short reverb
const LEVEL = 0.3

# Pseudo-random noise from position
static func _noise(pos: float) -> float:
	var x = sin(pos * 12345.6789) * 43758.5453
	return fmod(x, 1.0) * 2.0 - 1.0


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	var output = 0.0
	
	# Layer multiple noise bursts
	for layer in range(NUM_LAYERS):
		var layer_offset = float(layer) / NUM_LAYERS * LAYER_SPREAD_S
		var layer_t = dt - layer_offset
		if layer_t < 0.0:
			continue
		
		# Band-filtered noise around 2200Hz
		var noise_sample = _noise(layer_t * NOISE_CENTER_HZ)
		# Simple bandpass approximation: multiply by resonant sine
		noise_sample *= sin(2.0 * PI * NOISE_CENTER_HZ * layer_t)
		
		# Each layer has its own short envelope
		var layer_env = exp(-layer_t / DECAY_S)
		output += noise_sample * layer_env / NUM_LAYERS
	
	# Slight reverb tail
	var reverb = _noise(dt * 1500.0) * sin(2.0 * PI * 1800.0 * dt)
	reverb *= exp(-dt / REVERB_DECAY_S) * REVERB_TAIL_LEVEL
	output += reverb
	
	return clampf(output * LEVEL, -1.0, 1.0)


static func get_duration() -> float:
	return 0.2
