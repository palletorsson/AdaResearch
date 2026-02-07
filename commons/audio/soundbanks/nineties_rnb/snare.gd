# 90s R&B Snare - Layered Acoustic + Clap
# Character: Tight acoustic snare body with clap transient, gated reverb tail
# Reference: New Jack Swing snares — punchy but smooth

class_name NinetiesRnBSnare
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.6


static func generate(t: float, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > 0.2:
		return 0.0
	
	# === ACOUSTIC SNARE BODY ===
	# Two-tone resonance (head and shell)
	var tone_head = sin(2.0 * PI * 200.0 * dt)  # Drum head
	var tone_shell = sin(2.0 * PI * 340.0 * dt) * 0.6  # Shell ring
	var tone_env = pow(max(0.0, 1.0 - dt / 0.08), 2.5)  # Tight decay
	
	# === CLAP LAYER ===
	# Multiple micro-delayed claps for realistic clap spread
	var clap = 0.0
	var clap_times = [0.0, 0.002, 0.005, 0.008]  # Slight human spread
	for clap_offset in clap_times:
		var clap_dt = dt - clap_offset
		if clap_dt >= 0.0 and clap_dt < 0.05:
			var clap_env = pow(max(0.0, 1.0 - clap_dt / 0.05), 2.0)
			# Clap is filtered noise
			var clap_noise = fmod(sin((t - clap_offset) * 54321.0) * 43758.5453, 1.0) * 2.0 - 1.0
			clap += clap_noise * clap_env * 0.2
	
	# === SNARE WIRES (noise) ===
	var noise = fmod(sin(t * 12345.6789) * 43758.5453, 1.0) * 2.0 - 1.0
	var noise_env = pow(max(0.0, 1.0 - dt / 0.12), 1.8)
	
	# === TRANSIENT SNAP ===
	var snap = 0.0
	if dt < 0.005:
		snap = (1.0 - dt / 0.005) * 0.5
	
	# Mix layers: body 40%, noise 35%, clap 25%
	var body = (tone_head + tone_shell) * tone_env * 0.4
	var wires = noise * noise_env * 0.35
	var output = (body + wires + clap) * (1.0 + snap)
	
	return clampf(output * LEVEL, -1.0, 1.0)
