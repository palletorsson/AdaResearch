# Dark Wave Atmosphere - Cavernous Reverb Tails and Distant Echoes
# Research: dark_wave brief
#
# Character: The SPACE of dark wave. Not a musical element — it's the room itself.
#   Cavernous reverb tails, distant echoes, the feeling of being in a vast dark space.
#   Subtle, continuous, almost subliminal. Creates the "cathedral" feeling.
#   Think of the reverb tails in Bauhaus recordings, the spaces between notes
#   in Lebanon Hanover, the cavernous depth in She Past Away.
#   NOT vinyl crackle (that's Burial). This is REVERB SPACE — tonal, deep, cold.
# Source: Hall reverb with long pre-delay, fed by sine drones and filtered noise
# Processing: Very low sine drones (sub-harmonics of key), filtered noise
#   representing reverb diffusion, slow evolving filter
#
# Key specs:
#   Drone: Low sine at root frequency (1-2 octaves below), very quiet
#   Diffusion: Filtered noise (LP 800Hz) — the "air" of the cathedral
#   Movement: Very slow LFO (0.05 Hz) modulating level — breathing room
#   Level: Very low — felt more than heard
#   Always present — continuous element

class_name DarkWaveAtmosphere
extends RefCounted

const SAMPLE_RATE = 44100.0

# Cathedral atmosphere
const DRONE_LEVEL = 0.06           # Very quiet sub-drone
const DIFFUSION_LEVEL = 0.03      # Barely audible "air"
const DIFFUSION_CUTOFF_HZ = 800.0 # Dark filtered noise
const MOVEMENT_LFO_HZ = 0.05     # Glacially slow breathing
const MOVEMENT_DEPTH = 0.3        # Moderate modulation depth
const ECHO_RATE_HZ = 0.12         # Slow rhythmic echo illusion
const ECHO_DEPTH = 0.15           # Subtle
const LEVEL = 0.10


static func generate(t: float, chord_freqs: Array, note_duration: float = 8.0, note_time: float = 0.0) -> float:
	var dt = t - note_time
	if dt < 0.0:
		return 0.0
	
	# Very slow fade in/out
	var env = 1.0
	if dt < 2.0:
		env = dt / 2.0
	elif dt > note_duration - 2.0 and dt < note_duration:
		env = (note_duration - dt) / 2.0
	elif dt >= note_duration:
		env = maxf(0.0, 1.0 - (dt - note_duration) / 4.0)  # Very long tail
	
	# Breathing room — slow level modulation
	var breathing = 0.7 + sin(2.0 * PI * MOVEMENT_LFO_HZ * t) * MOVEMENT_DEPTH
	
	# Low drone — root frequencies, octave(s) down
	var drone = 0.0
	for freq in chord_freqs:
		# Two octaves down
		drone += sin(2.0 * PI * freq * 0.25 * t) * 0.5
		# One octave down with slight detune
		drone += sin(2.0 * PI * freq * 0.505 * t) * 0.3
	drone /= maxf(chord_freqs.size(), 1)
	drone *= DRONE_LEVEL
	
	# Cathedral diffusion — dark filtered noise
	var noise = randf() * 2.0 - 1.0
	# Simulate LP filter effect by mixing with slow sine (very crude but effective)
	noise = noise * 0.3 + sin(2.0 * PI * 120.0 * t + noise * 2.0) * 0.7
	var diffusion = noise * DIFFUSION_LEVEL
	
	# Distant echo illusion — slow modulated tones
	var echo = sin(2.0 * PI * ECHO_RATE_HZ * t) * ECHO_DEPTH
	var distant = 0.0
	if chord_freqs.size() > 0:
		var root = chord_freqs[0]
		distant = sin(2.0 * PI * root * 2.0 * t) * 0.02 * (0.5 + echo * 0.5)
	
	var output = (drone + diffusion + distant) * breathing
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
	return generate(t, chord_freqs, 999999.0, 0.0)
