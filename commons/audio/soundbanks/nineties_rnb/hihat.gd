# 90s R&B Hi-Hat - Swung 16ths with Velocity Variation
# Character: Crispy, tight closed hats with dynamic velocity for groove
# Reference: New Jack Swing shuffle — the pocket lives here

class_name NinetiesRnBHiHat
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.42
const DECAY_CLOSED = 0.045
const DECAY_OPEN = 0.22


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	if dt < 0.0:
		return 0.0
	
	var decay = DECAY_OPEN if open else DECAY_CLOSED
	if dt > decay * 4.0:
		return 0.0
	
	# High-frequency metallic noise (6-12kHz character)
	# Multiple noise sources for shimmer
	var noise1 = fmod(sin(t * 98765.4321) * 43758.5453, 1.0) * 2.0 - 1.0
	var noise2 = fmod(sin(t * 76543.21) * 12345.6789, 1.0) * 2.0 - 1.0
	var noise = (noise1 + noise2 * 0.5) / 1.5
	
	# Metallic ring components (simulates cymbal modes)
	var ring1 = sin(2.0 * PI * 7500.0 * dt) * exp(-dt * 40.0) * 0.15
	var ring2 = sin(2.0 * PI * 9200.0 * dt) * exp(-dt * 50.0) * 0.1
	
	# Envelope with sharp attack
	var attack = 1.0
	if dt < 0.001:
		attack = dt / 0.001
	var amp = attack * pow(max(0.0, 1.0 - dt / decay), 2.2)
	
	# For open hat, add sustained ring
	var sustain = 0.0
	if open and dt < 0.15:
		sustain = sin(2.0 * PI * 5500.0 * dt) * exp(-dt * 10.0) * 0.2
	
	return clampf((noise + ring1 + ring2 + sustain) * amp * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)


# Velocity-aware generation for groove dynamics
static func generate_velocity(t: float, trigger_time: float = 0.0, velocity: float = 1.0, open: bool = false) -> float:
	# Velocity affects both volume and brightness
	var base = generate(t, trigger_time, open)
	
	# Lower velocity = slightly darker, shorter
	var vel_factor = 0.4 + velocity * 0.6
	
	return base * vel_factor
