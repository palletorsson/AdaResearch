extends Node
class_name CinematicMusicGenerator

# CinematicMusicGenerator - EPIC SOUND DESIGN
# Implements the 5 principles of epic sound:
# 1. MOVEMENT - pitch drift, evolving filters, LFO modulation
# 2. LAYERING - core + halo + sub + modulation layers
# 3. TEXTURE - noise, harmonics, reverb architecture
# 4. SCALE ARCHITECTURE - octaves, fifths, detuning, microtonality
# 5. DYNAMIC RANGE - breathing envelopes, attack/release shaping

const SAMPLE_RATE: int = 44100
const MIX_RATE: int = 44100

# ----- GENERATION FUNCTIONS -----

static func generate_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	match sound_name:
		"blade_runner_pad":
			return _generate_blade_runner_pad(params)
		"vangelis_brass_lead":
			return _generate_vangelis_brass_lead(params)
		"cyber_rain_texture":
			return _generate_cyber_rain_texture(params)
		"tears_in_rain_pad":
			return _generate_tears_in_rain_pad(params)
		"tears_in_rain_melody":
			return _generate_tears_in_rain_melody(params)
		"neon_glint":
			return _generate_neon_glint(params)
		# RAIN_SOAKED_METROPOLIS - All new epic sounds
		"oceanic_sub_drone":
			return _generate_oceanic_sub_drone(params)
		"dystopian_foundation_pad":
			return _generate_dystopian_foundation_pad(params)
		"neon_shimmer_wash":
			return _generate_neon_shimmer_wash(params)
		"crying_brass_melody":
			return _generate_crying_brass_melody(params)
		"distant_memory_lead":
			return _generate_distant_memory_lead(params)
		"glass_harmonic_voice":
			return _generate_glass_harmonic_voice(params)
		"heavy_rain_cascade":
			return _generate_heavy_rain_cascade(params)
		"wind_through_towers":
			return _generate_wind_through_towers(params)
		"electric_rain_static":
			return _generate_electric_rain_static(params)
		"neon_reflection_pulse":
			return _generate_neon_reflection_pulse(params)
		"memory_fragment_swell":
			return _generate_memory_fragment_swell(params)
		"distant_thunder_rumble":
			return _generate_distant_thunder_rumble(params)
		"glass_droplet_chime":
			return _generate_glass_droplet_chime(params)
		"deep_dark_cello_drone":
			return _generate_deep_dark_cello_drone(params)
		"hans_zimmer_cello_drone":
			return _generate_deep_dark_cello_drone(params)  # Alias
		_:
			push_warning("CinematicMusicGenerator: Unknown sound '%s'" % sound_name)
			return null

# ============================================================================
# HYBRID EPIC: Blade Runner Pad
# Principle: Layering (SuperSaw stack) + Movement (filter sweep) + Texture
# ============================================================================
static func _generate_blade_runner_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0)
	var base_freq = params.get("freq", 110.0)
	var attack_time = params.get("attack", 4.0)  # Epic = slow attack
	var drift_amount = params.get("drift", 0.003)  # Pitch drift

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Pitch drift LFO (0.2 Hz)
		var drift = sin(t * 0.2 * 2.0 * PI) * drift_amount * base_freq
		var freq_drifted = base_freq + drift

		# LAYERING: SuperSaw stack (7 voices for thickness)
		var core_l = _super_saw_epic(freq_drifted, t, 0.0)
		var core_r = _super_saw_epic(freq_drifted, t, 1.0)

		# LAYERING: Add sub octave for depth
		var sub = _saw_wave(freq_drifted * 0.5, t) * 0.3

		# LAYERING: Add harmonic halo (octave up, quieter)
		var halo = _super_saw_epic(freq_drifted * 2.0, t, 0.5) * 0.15

		# MOVEMENT: Filter sweep (400Hz to 2500Hz sine wave)
		var sweep = sin(progress * PI)
		var cutoff = lerp(400.0, 2500.0, sweep)
		var filter_env = cutoff / 3000.0

		var sig_l = (core_l + sub + halo) * filter_env
		var sig_r = (core_r + sub + halo) * filter_env

		# DYNAMIC RANGE: Slow breathing envelope
		var env = 1.0
		var attack_ratio = attack_time / duration
		if progress < attack_ratio:
			env = progress / attack_ratio  # Slow attack
		elif progress > 0.85:
			env = (1.0 - progress) / 0.15  # Release

		_write_sample16_stereo(data, i, sig_l * env * 0.35, sig_r * env * 0.35)

	return _create_stream(data)

# ============================================================================
# ANALOG EPIC: Vangelis Brass Lead
# Principle: Movement (vibrato) + Texture (PWM/saw mix) + Dynamic Range
# ============================================================================
static func _generate_vangelis_brass_lead(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 15.0)
	var root_freq = params.get("freq", 220.0)
	var attack_time = params.get("attack", 1.5)
	var vibrato_depth = params.get("vibrato_depth", 0.015)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Vibrato (6 Hz LFO)
		var vibrato = sin(t * 6.0 * 2.0 * PI) * vibrato_depth * root_freq
		var freq = root_freq + vibrato

		# LAYERING: Mix of sine (smooth) and saw (harmonic richness)
		var sine = sin(2.0 * PI * freq * t) * 0.7
		var saw = _saw_wave(freq, t) * 0.3
		var core = sine + saw

		# LAYERING: Add fifth harmonic for brass character
		var fifth = sin(2.0 * PI * freq * 1.5 * t) * 0.2

		# TEXTURE: Slight stereo detune for width
		var sig_l = core + fifth
		var sig_r = (sin(2.0 * PI * freq * 1.002 * t) * 0.7 + _saw_wave(freq * 1.002, t) * 0.3) + fifth

		# DYNAMIC RANGE: Envelope with slow attack
		var env = 1.0
		var attack_ratio = attack_time / duration
		if progress < attack_ratio:
			env = progress / attack_ratio
		elif progress > 0.9:
			env = (1.0 - progress) / 0.1

		_write_sample16_stereo(data, i, sig_l * env * 0.4, sig_r * env * 0.4)

	return _create_stream(data)

# ============================================================================
# METALLIC / ALIEN: Cyber Rain Texture
# Principle: Texture (noise + ring mod) + Movement (random events)
# ============================================================================
static func _generate_cyber_rain_texture(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 10.0)
	var density = params.get("density", 0.02)  # Rain density

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	# Use seeded random for deterministic "rain"
	var rng_seed = int(duration * 1000.0) % 10000
	seed(rng_seed)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE

		var sig_l = 0.0
		var sig_r = 0.0

		# TEXTURE: Random rain droplet events
		if randf() < density / 100.0:
			var pan = randf()
			var droplet_freq = randf_range(2000.0, 8000.0)

			# METALLIC: Ring modulation for bell-like tone
			var carrier = sin(2.0 * PI * droplet_freq * t)
			var modulator = sin(2.0 * PI * (droplet_freq * 1.414) * t)  # Inharmonic ratio
			var ring_mod = carrier * modulator

			# Short envelope for droplet
			var env = exp(-((t * 50.0 - floor(t * 50.0)) * 30.0))
			var droplet = ring_mod * env

			sig_l += droplet * (1.0 - pan)
			sig_r += droplet * pan

		# TEXTURE: Continuous noise bed (filtered)
		var noise = (randf() * 2.0 - 1.0) * 0.05

		# High-pass filter simulation for rain hiss
		var hiss = noise * 0.3

		sig_l += hiss
		sig_r += hiss

		_write_sample16_stereo(data, i, sig_l * 0.35, sig_r * 0.35)

	return _create_stream(data)

# ============================================================================
# ETHEREAL EPIC: Tears in Rain Pad
# Principle: ALL 5 - Ultimate epic pad
# ============================================================================
static func _generate_tears_in_rain_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 16.0)
	var base_freq = params.get("freq", 261.63)  # C4
	var attack_time = params.get("attack", 5.0)  # Very slow attack

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# 1. MOVEMENT: Slow pitch drift (0.15 Hz)
		var drift1 = sin(t * 0.15 * 2.0 * PI) * 0.004 * base_freq
		var drift2 = sin(t * 0.23 * 2.0 * PI) * 0.003 * base_freq  # Polyrhythmic drift
		var freq = base_freq + drift1 + drift2

		# 2. LAYERING: Core - detuned triangle waves (softer than saw)
		var triangle_core = _triangle_wave(freq, t)
		var triangle_detune1 = _triangle_wave(freq * 0.998, t)
		var triangle_detune2 = _triangle_wave(freq * 1.003, t)
		var core = (triangle_core + triangle_detune1 + triangle_detune2) * 0.33

		# 2. LAYERING: Sub octave (depth)
		var sub = _triangle_wave(freq * 0.5, t) * 0.25

		# 2. LAYERING: Harmonic halo (octave + fifth)
		var halo_oct = _triangle_wave(freq * 2.0, t) * 0.12
		var halo_fifth = _triangle_wave(freq * 3.0, t) * 0.08

		# 4. SCALE ARCHITECTURE: Add microtonal shimmer (10 cents sharp)
		var micro = _triangle_wave(freq * 1.006, t) * 0.1

		# Stereo positioning
		var sig_l = core + sub + halo_oct + halo_fifth + micro
		var sig_r = _triangle_wave(freq * 1.001, t) + sub + halo_oct + micro

		# 1. MOVEMENT: Slow filter modulation
		var filter_lfo = sin(t * 0.3 * 2.0 * PI)
		var cutoff = lerp(300.0, 2000.0, (filter_lfo + 1.0) * 0.5)
		var filter_env = cutoff / 2500.0

		sig_l *= filter_env
		sig_r *= filter_env

		# 5. DYNAMIC RANGE: Very slow breathing envelope
		var env = 1.0
		var attack_ratio = attack_time / duration
		if progress < attack_ratio:
			env = smoothstep(0.0, 1.0, progress / attack_ratio)  # Smooth curve
		elif progress > 0.88:
			env = smoothstep(1.0, 0.0, (progress - 0.88) / 0.12)

		# 3. TEXTURE: Add subtle noise halo
		var noise = (sin(t * 5000.0) + sin(t * 7123.0)) * 0.01  # Deterministic noise

		_write_sample16_stereo(data, i, (sig_l + noise) * env * 0.28, (sig_r + noise) * env * 0.28)

	return _create_stream(data)

# ============================================================================
# EMOTIONAL EPIC: Tears in Rain Melody
# Principle: Movement + Dynamic Range + Harmonic richness
# ============================================================================
static func _generate_tears_in_rain_melody(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 16.0)
	var root_freq = params.get("freq", 523.25)  # C5
	var attack_time = params.get("attack", 2.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	# Iconic descending melodic phrase (simplified)
	var melody_ratios = [1.0, 0.891, 0.794, 0.707, 0.841, 0.749, 0.667]  # C -> Bb -> Ab -> G -> A -> F# -> E
	var note_duration = duration / float(melody_ratios.size())

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# Determine current note
		var note_index = int(t / note_duration)
		if note_index >= melody_ratios.size():
			note_index = melody_ratios.size() - 1

		var local_t = fmod(t, note_duration)
		var freq = root_freq * melody_ratios[note_index]

		# MOVEMENT: Expressive vibrato (increases over note)
		var vibrato_depth = (local_t / note_duration) * 0.02  # Grows over note
		var vibrato = sin(local_t * 5.5 * 2.0 * PI) * vibrato_depth * freq
		freq += vibrato

		# LAYERING: Rich harmonic content (brass-like)
		var h1 = sin(2.0 * PI * freq * t) * 0.6  # Fundamental
		var h2 = sin(2.0 * PI * freq * 2.0 * t) * 0.15  # 2nd harmonic
		var h3 = sin(2.0 * PI * freq * 3.0 * t) * 0.1   # 3rd harmonic
		var h4 = _saw_wave(freq, t) * 0.15  # Sawtooth for richness
		var core = h1 + h2 + h3 + h4

		# Stereo width (slight detune)
		var sig_l = core
		var sig_r = sin(2.0 * PI * freq * 1.002 * t) * 0.6 + h2 + h3 + h4

		# DYNAMIC RANGE: Per-note envelope
		var note_env = 1.0
		var note_attack = 0.3
		var note_release = 0.5
		if local_t < note_attack:
			note_env = local_t / note_attack
		elif local_t > note_duration - note_release:
			note_env = (note_duration - local_t) / note_release

		# Overall envelope
		var overall_env = 1.0
		if progress < 0.1:
			overall_env = progress / 0.1
		elif progress > 0.9:
			overall_env = (1.0 - progress) / 0.1

		var env = note_env * overall_env

		_write_sample16_stereo(data, i, sig_l * env * 0.38, sig_r * env * 0.38)

	return _create_stream(data)

# ============================================================================
# TEXTURE: Neon Glint
# High frequency sparkles with stereo positioning
# ============================================================================
static func _generate_neon_glint(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 10.0)
	var density = params.get("density", 0.0002)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	seed(int(duration * 1000.0) % 10000)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE

		var sig_l = 0.0
		var sig_r = 0.0

		if randf() < density:
			var pan = randf()
			var freq = randf_range(3000.0, 6000.0)

			# Bell-like FM tone
			var mod_index = 2.5
			var carrier = sin(2.0 * PI * freq * t + mod_index * sin(2.0 * PI * freq * 2.0 * t))

			var env = exp(-fmod(t * 50.0, 1.0) * 20.0)
			var blip = carrier * env

			sig_l = blip * (1.0 - pan)
			sig_r = blip * pan

		_write_sample16_stereo(data, i, sig_l * 0.25, sig_r * 0.25)

	return _create_stream(data)

# ============================================================================
# RAIN SOAKED METROPOLIS - 13 Custom Epic Sounds
# ============================================================================

# 1. OCEANIC SUB DRONE - Deep urban ocean, massive sub presence
static func _generate_oceanic_sub_drone(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 40.0)
	var base_freq = params.get("freq", 55.0)  # A1

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Ultra-slow modulation (whale song-like)
		var mod1 = sin(t * 0.08 * 2.0 * PI) * 0.002 * base_freq
		var mod2 = sin(t * 0.13 * 2.0 * PI) * 0.0015 * base_freq
		var freq = base_freq + mod1 + mod2

		# LAYERING: Multiple sub harmonics
		var h1 = sin(2.0 * PI * freq * t) * 0.5  # Fundamental
		var h2 = sin(2.0 * PI * freq * 0.5 * t) * 0.3  # Sub-octave
		var h3 = _triangle_wave(freq * 1.5, t) * 0.2  # Fifth for richness

		# TEXTURE: Very subtle rumble noise
		var rumble = (sin(t * 30.0) + sin(t * 43.7)) * 0.02

		var core = h1 + h2 + h3 + rumble

		# Stereo: Slightly different phase for width
		var sig_l = core
		var sig_r = sin(2.0 * PI * freq * t + 0.05) * 0.5 + h2 + h3 + rumble

		# DYNAMIC RANGE: Breathing over very long time
		var breath = sin(progress * PI * 0.5) * 0.15 + 0.85

		_write_sample16_stereo(data, i, sig_l * breath * 0.25, sig_r * breath * 0.25)

	return _create_stream(data)

# 2. DYSTOPIAN FOUNDATION PAD - Dark evolving pad, low-mid range
static func _generate_dystopian_foundation_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 32.0)
	var base_freq = params.get("freq", 82.41)  # E2

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Slow drift + filter sweep
		var drift = sin(t * 0.18 * 2.0 * PI) * 0.004 * base_freq
		var freq = base_freq + drift

		# LAYERING: Detuned saw stack (darker than supersaw)
		var saw1 = _saw_wave(freq, t) * 0.3
		var saw2 = _saw_wave(freq * 0.996, t) * 0.25
		var saw3 = _saw_wave(freq * 1.004, t) * 0.25
		var saw4 = _triangle_wave(freq * 0.5, t) * 0.2  # Sub

		var core = saw1 + saw2 + saw3 + saw4

		# MOVEMENT: Filter modulation (dark to slightly brighter)
		var filter_lfo = sin(t * 0.25 * 2.0 * PI)
		var cutoff = lerp(200.0, 800.0, (filter_lfo + 1.0) * 0.5)
		var filter_env = cutoff / 1000.0

		var sig_l = core * filter_env
		var sig_r = (saw1 * 1.001 + saw2 + saw3 + saw4) * filter_env

		# DYNAMIC RANGE: Long attack
		var env = 1.0
		if progress < 0.15:
			env = smoothstep(0.0, 1.0, progress / 0.15)
		elif progress > 0.85:
			env = smoothstep(1.0, 0.0, (progress - 0.85) / 0.15)

		_write_sample16_stereo(data, i, sig_l * env * 0.3, sig_r * env * 0.3)

	return _create_stream(data)

# 3. NEON SHIMMER WASH - Mid-range pad with chorus movement
static func _generate_neon_shimmer_wash(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 28.0)
	var base_freq = params.get("freq", 164.81)  # E3

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Chorus-like pitch modulation
		var chorus1 = sin(t * 0.7 * 2.0 * PI) * 0.008 * base_freq
		var chorus2 = sin(t * 1.1 * 2.0 * PI) * 0.006 * base_freq
		var freq_l = base_freq + chorus1
		var freq_r = base_freq + chorus2

		# LAYERING: Multiple sine waves (glassy)
		var h1_l = sin(2.0 * PI * freq_l * t) * 0.4
		var h2_l = sin(2.0 * PI * freq_l * 2.0 * t) * 0.2
		var h3_l = sin(2.0 * PI * freq_l * 3.0 * t) * 0.15

		var h1_r = sin(2.0 * PI * freq_r * t) * 0.4
		var h2_r = sin(2.0 * PI * freq_r * 2.0 * t) * 0.2
		var h3_r = sin(2.0 * PI * freq_r * 3.0 * t) * 0.15

		var sig_l = h1_l + h2_l + h3_l
		var sig_r = h1_r + h2_r + h3_r

		# MOVEMENT: Tremolo for shimmer
		var tremolo = sin(t * 4.0 * 2.0 * PI) * 0.12 + 0.88

		# DYNAMIC RANGE
		var env = 1.0
		if progress < 0.2:
			env = smoothstep(0.0, 1.0, progress / 0.2)
		elif progress > 0.8:
			env = smoothstep(1.0, 0.0, (progress - 0.8) / 0.2)

		_write_sample16_stereo(data, i, sig_l * tremolo * env * 0.28, sig_r * tremolo * env * 0.28)

	return _create_stream(data)

# 4. CRYING BRASS MELODY - Main emotional lead (CS-80 style)
static func _generate_crying_brass_melody(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 30.0)
	var root_freq = params.get("freq", 523.25)  # C5

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	# Emotional descending phrase
	var melody = [1.0, 0.943, 0.841, 0.794, 0.707, 0.630, 0.749, 0.667]  # C->Bb->A->Ab->G->F->F#->E
	var note_dur = duration / float(melody.size())

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var note_idx = int(t / note_dur)
		if note_idx >= melody.size(): note_idx = melody.size() - 1

		var local_t = fmod(t, note_dur)
		var freq = root_freq * melody[note_idx]

		# MOVEMENT: Expressive vibrato (grows and varies)
		var vib_depth = (local_t / note_dur) * 0.025
		var vib_rate = 5.5 + sin(t * 0.5) * 0.8  # Varying vibrato rate
		var vibrato = sin(local_t * vib_rate * 2.0 * PI) * vib_depth * freq
		freq += vibrato

		# LAYERING: PWM + saw for brass character
		var pulse_width = 0.5 + sin(t * 2.0 * 2.0 * PI) * 0.2  # PWM
		var pwm = 1.0 if fmod(t * freq, 1.0) < pulse_width else -1.0
		var saw = _saw_wave(freq, t)
		var core = pwm * 0.5 + saw * 0.5

		# LAYERING: Harmonics for warmth
		var h2 = sin(2.0 * PI * freq * 2.0 * t) * 0.2
		var h3 = sin(2.0 * PI * freq * 3.0 * t) * 0.12

		var sig = (core + h2 + h3) * 0.7

		# DYNAMIC RANGE: Per-note envelope with expression
		var attack = 0.4
		var release = 0.6
		var note_env = 1.0
		if local_t < attack:
			note_env = smoothstep(0.0, 1.0, local_t / attack)
		elif local_t > note_dur - release:
			note_env = smoothstep(1.0, 0.0, (local_t - (note_dur - release)) / release)

		# Stereo width (slight detune)
		var sig_l = sig
		var sig_r = (pwm * 0.5 + _saw_wave(freq * 1.002, t) * 0.5 + h2 + h3) * 0.7

		_write_sample16_stereo(data, i, sig_l * note_env * 0.35, sig_r * note_env * 0.35)

	return _create_stream(data)

# 5. DISTANT MEMORY LEAD - Secondary melody, echo-like
static func _generate_distant_memory_lead(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 26.0)
	var root_freq = params.get("freq", 293.66)  # D4

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Slow vibrato
		var vibrato = sin(t * 4.5 * 2.0 * PI) * 0.012 * root_freq
		var freq = root_freq + vibrato

		# TEXTURE: Sine-dominant for distance/ethereal quality
		var h1 = sin(2.0 * PI * freq * t) * 0.7
		var h2 = sin(2.0 * PI * freq * 2.0 * t) * 0.2
		var triangle = _triangle_wave(freq, t) * 0.1

		var core = h1 + h2 + triangle

		# Stereo: Wide positioning
		var sig_l = core * 0.7  # Quieter left
		var sig_r = core * 1.0  # Louder right (distant, to the side)

		# DYNAMIC RANGE: Slow swell
		var env = sin(progress * PI) * 0.8 + 0.2

		_write_sample16_stereo(data, i, sig_l * env * 0.25, sig_r * env * 0.25)

	return _create_stream(data)

# 6. GLASS HARMONIC VOICE - High crystalline tones
static func _generate_glass_harmonic_voice(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 24.0)
	var base_freq = params.get("freq", 659.25)  # E5

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Delicate vibrato
		var vibrato = sin(t * 5.0 * 2.0 * PI) * 0.008 * base_freq
		var freq = base_freq + vibrato

		# TEXTURE: Bell-like FM synthesis
		var mod_index = 3.0 * sin(progress * PI)  # Varying timbre
		var carrier = sin(2.0 * PI * freq * t)
		var modulator = sin(2.0 * PI * freq * 2.1 * t)  # Inharmonic
		var fm = carrier * (1.0 + mod_index * modulator)

		# LAYERING: Add pure harmonics for glass quality
		var h3 = sin(2.0 * PI * freq * 3.0 * t) * 0.15
		var h5 = sin(2.0 * PI * freq * 5.0 * t) * 0.08

		var core = fm * 0.7 + h3 + h5

		# Stereo: Subtle width
		var sig_l = core
		var sig_r = carrier * (1.0 + mod_index * sin(2.0 * PI * freq * 2.1 * t + 0.1)) * 0.7 + h3 + h5

		# DYNAMIC RANGE: Gentle breathing
		var env = 1.0
		if progress < 0.25:
			env = smoothstep(0.0, 1.0, progress / 0.25)
		elif progress > 0.75:
			env = smoothstep(1.0, 0.0, (progress - 0.75) / 0.25)

		_write_sample16_stereo(data, i, sig_l * env * 0.22, sig_r * env * 0.22)

	return _create_stream(data)

# 7. HEAVY RAIN CASCADE - Rich multi-layered rain
static func _generate_heavy_rain_cascade(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 18.0)
	var density = params.get("density", 0.05)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	seed(int(duration * 1000.0) % 10000)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE

		var sig_l = 0.0
		var sig_r = 0.0

		# TEXTURE: Multiple rain layers
		# Layer 1: High frequency rain
		if randf() < density / 50.0:
			var freq = randf_range(4000.0, 9000.0)
			var droplet = sin(2.0 * PI * freq * t) * exp(-fmod(t * 60.0, 1.0) * 25.0)
			var pan = randf()
			sig_l += droplet * (1.0 - pan) * 0.3
			sig_r += droplet * pan * 0.3

		# Layer 2: Mid frequency impacts
		if randf() < density / 80.0:
			var freq = randf_range(1500.0, 3500.0)
			var impact = _saw_wave(freq, t) * exp(-fmod(t * 40.0, 1.0) * 20.0)
			var pan = randf()
			sig_l += impact * (1.0 - pan) * 0.2
			sig_r += impact * pan * 0.2

		# Continuous: Rain hiss (filtered noise)
		var noise = (sin(t * 8234.5) + sin(t * 12943.7) + sin(t * 6721.3)) * 0.33
		var hiss = noise * 0.15

		sig_l += hiss
		sig_r += hiss

		_write_sample16_stereo(data, i, sig_l * 0.4, sig_r * 0.4)

	return _create_stream(data)

# 8. WIND THROUGH TOWERS - Urban wind texture
static func _generate_wind_through_towers(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 22.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# MOVEMENT: Slow wind gusts
		var gust = sin(t * 0.3 * 2.0 * PI) * 0.5 + 0.5

		# TEXTURE: Multi-frequency noise (deterministic)
		var wind = 0.0
		wind += sin(t * 234.5) * 0.2
		wind += sin(t * 567.8) * 0.15
		wind += sin(t * 891.2) * 0.12
		wind += sin(t * 1234.6) * 0.1
		wind += sin(t * 1876.3) * 0.08
		wind *= gust

		# Band-pass filter simulation (mid-frequency emphasis)
		var filtered = wind * 0.6

		# Stereo: Wind moving left to right slowly
		var pan = sin(t * 0.15 * 2.0 * PI) * 0.5 + 0.5
		var sig_l = filtered * (1.0 - pan)
		var sig_r = filtered * pan

		_write_sample16_stereo(data, i, sig_l * 0.25, sig_r * 0.25)

	return _create_stream(data)

# 9. ELECTRIC RAIN STATIC - Electrical interference
static func _generate_electric_rain_static(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 20.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	seed(int(duration * 1234.0) % 10000)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# TEXTURE: Crackling electrical noise
		var crackle = 0.0
		if randf() < 0.001:
			crackle = (randf() * 2.0 - 1.0) * 0.4

		# Base static (high frequency)
		var static_noise = (sin(t * 9234.0) + sin(t * 15672.0)) * 0.5
		static_noise *= 0.08

		# MOVEMENT: Modulated by low frequency
		var mod = sin(t * 0.5 * 2.0 * PI) * 0.3 + 0.7

		var sig = (static_noise + crackle) * mod

		# Stereo: Random positioning
		var pan = sin(t * 3.7) * 0.5 + 0.5
		var sig_l = sig * (1.0 - pan)
		var sig_r = sig * pan

		_write_sample16_stereo(data, i, sig_l * 0.18, sig_r * 0.18)

	return _create_stream(data)

# 10. NEON REFLECTION PULSE - Short neon pulses (for random events)
static func _generate_neon_reflection_pulse(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 3.0)
	var freq = params.get("freq", 880.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# FM pulse (neon buzz)
		var mod_index = 4.0 * (1.0 - progress)
		var carrier = sin(2.0 * PI * freq * t)
		var modulator = sin(2.0 * PI * freq * 3.14 * t)
		var pulse = carrier + mod_index * modulator

		# Quick envelope
		var env = exp(-progress * 6.0)

		# Stereo: centered with width
		var sig_l = pulse * env * 0.9
		var sig_r = pulse * env * 1.0

		_write_sample16_stereo(data, i, sig_l * 0.3, sig_r * 0.3)

	return _create_stream(data)

# 11. MEMORY FRAGMENT SWELL - Emotional pad swells (for random events)
static func _generate_memory_fragment_swell(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 8.0)
	var freq = params.get("freq", 392.0)  # G4

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# Detuned pad swell
		var h1 = sin(2.0 * PI * freq * t) * 0.4
		var h2 = sin(2.0 * PI * freq * 0.998 * t) * 0.3
		var h3 = sin(2.0 * PI * freq * 1.003 * t) * 0.3

		var core = h1 + h2 + h3

		# Swell envelope
		var env = sin(progress * PI) * sin(progress * PI)  # Smooth swell

		var sig_l = core * env
		var sig_r = (h1 + h2 * 1.001 + h3) * env

		_write_sample16_stereo(data, i, sig_l * 0.32, sig_r * 0.32)

	return _create_stream(data)

# 12. DISTANT THUNDER RUMBLE - Low frequency rumble (for random events)
static func _generate_distant_thunder_rumble(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 6.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# Low frequency rumble (40-80 Hz)
		var rumble_freq = 50.0 + sin(t * 2.0 * 2.0 * PI) * 20.0
		var rumble = sin(2.0 * PI * rumble_freq * t) * 0.6

		# Add sub harmonic
		var sub = sin(2.0 * PI * rumble_freq * 0.5 * t) * 0.4

		# Noise texture
		var noise = (sin(t * 234.0) + sin(t * 456.7)) * 0.5 * 0.2

		var core = rumble + sub + noise

		# Envelope: slow attack, long decay
		var env = 1.0
		if progress < 0.2:
			env = progress / 0.2
		else:
			env = exp(-(progress - 0.2) * 3.0)

		var sig = core * env

		_write_sample16_stereo(data, i, sig * 0.28, sig * 0.28)

	return _create_stream(data)

# 14. DEEP DARK CELLO DRONE - Hans Zimmer style cello drone
# Principle: Deep resonant cello tones with rich harmonics, slow movement, epic sub-bass
static func _generate_deep_dark_cello_drone(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 15.0)  # Reasonable length for catalog playback
	var base_freq = params.get("freq", 65.41)  # C2 - deep cello range
	var attack_time = params.get("attack", 6.0)  # Very slow attack for cinematic feel
	var vibrato_depth = params.get("vibrato_depth", 0.01)  # Subtle vibrato
	var vibrato_rate = params.get("vibrato_rate", 4.5)  # Slow, expressive vibrato
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# MOVEMENT: Slow pitch drift (breathing, evolving)
		var drift1 = sin(t * 0.12 * 2.0 * PI) * 0.003 * base_freq  # Very slow drift
		var drift2 = sin(t * 0.18 * 2.0 * PI) * 0.002 * base_freq  # Polyrhythmic
		var freq = base_freq + drift1 + drift2
		
		# MOVEMENT: Expressive vibrato (cello-like, grows over time)
		var vibrato_growth = smoothstep(0.0, 0.3, progress)  # Vibrato increases over first 30%
		var vibrato = sin(t * vibrato_rate * 2.0 * PI) * vibrato_depth * vibrato_growth * freq
		freq += vibrato
		
		# LAYERING: Cello fundamental - rich sine with saw character
		# Cello has strong fundamental with rich harmonics
		var fundamental = sin(2.0 * PI * freq * t) * 0.5
		var saw_char = _saw_wave(freq, t) * 0.15  # Add sawtooth for cello character
		
		# LAYERING: Strong 2nd harmonic (octave) - cello characteristic
		var h2 = sin(2.0 * PI * freq * 2.0 * t) * 0.25
		
		# LAYERING: 3rd harmonic (fifth) for warmth
		var h3 = sin(2.0 * PI * freq * 3.0 * t) * 0.12
		
		# LAYERING: 4th harmonic (octave up) for presence
		var h4 = sin(2.0 * PI * freq * 4.0 * t) * 0.08
		
		# LAYERING: Epic sub-bass (Zimmer signature) - octave below
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.35  # Strong sub for depth
		
		# LAYERING: Detuned layer for width and richness
		var detune1 = sin(2.0 * PI * freq * 0.998 * t) * 0.15
		var detune2 = sin(2.0 * PI * freq * 1.002 * t) * 0.15
		
		var core = fundamental + saw_char + h2 + h3 + h4 + sub + detune1 + detune2
		
		# MOVEMENT: Slow filter sweep (dark to slightly brighter, then back)
		var filter_lfo = sin(t * 0.08 * 2.0 * PI)  # Very slow filter movement
		var cutoff = lerp(150.0, 600.0, (filter_lfo + 1.0) * 0.5)  # Low-mid range
		var filter_env = cutoff / 800.0
		
		# TEXTURE: Subtle bow noise (cello string texture)
		var bow_noise = (sin(t * 234.5) + sin(t * 456.7)) * 0.02  # Very subtle
		
		# Stereo: Wide, immersive
		var sig_l = (core + bow_noise) * filter_env
		var sig_r = (fundamental * 1.001 + saw_char + h2 + h3 + h4 + sub + detune1 * 1.001 + detune2 + bow_noise) * filter_env
		
		# DYNAMIC RANGE: Very slow breathing envelope (cinematic)
		var env = 1.0
		var attack_ratio = attack_time / duration
		if progress < attack_ratio:
			env = smoothstep(0.0, 1.0, progress / attack_ratio)  # Smooth cinematic attack
		elif progress > 0.9:
			env = smoothstep(1.0, 0.0, (progress - 0.9) / 0.1)  # Gentle release
		
		# MOVEMENT: Subtle tremolo for life (very slow)
		var tremolo = sin(t * 0.5 * 2.0 * PI) * 0.05 + 0.95  # Very subtle breathing
		
		_write_sample16_stereo(data, i, sig_l * env * tremolo * 0.32, sig_r * env * tremolo * 0.32)
	
	return _create_stream(data)

# 13. GLASS DROPLET CHIME - High frequency rain impacts (for random events)
static func _generate_glass_droplet_chime(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 2.0)

	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)

	seed(int(duration * 2345.0) % 10000)

	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration

		# Multiple glass-like FM tones
		var chime = 0.0
		for n in range(3):
			var freq = randf_range(2500.0, 5500.0)
			var mod_ratio = 2.0 + randf() * 2.0
			var carrier = sin(2.0 * PI * freq * t)
			var modulator = sin(2.0 * PI * freq * mod_ratio * t)
			chime += carrier * (1.0 + 2.0 * modulator) * 0.33

		# Fast decay
		var env = exp(-progress * 12.0)

		# Random stereo
		var pan = randf()
		var sig_l = chime * env * (1.0 - pan)
		var sig_r = chime * env * pan

		_write_sample16_stereo(data, i, sig_l * 0.25, sig_r * 0.25)

	return _create_stream(data)

# ============================================================================
# HELPER FUNCTIONS - Waveforms and Utilities
# ============================================================================

static func _saw_wave(freq: float, t: float) -> float:
	return 2.0 * (t * freq - floor(t * freq + 0.5))

static func _triangle_wave(freq: float, t: float) -> float:
	var phase = fmod(t * freq, 1.0)
	return abs(4.0 * phase - 2.0) - 1.0

# SuperSaw EPIC: 7 voices for maximum width
static func _super_saw_epic(freq: float, t: float, pan_bias: float) -> float:
	var v1 = _saw_wave(freq, t)
	var v2 = _saw_wave(freq * 0.990, t)  # -10 cents
	var v3 = _saw_wave(freq * 0.995, t)  # -5 cents
	var v4 = _saw_wave(freq * 1.005, t)  # +5 cents
	var v5 = _saw_wave(freq * 1.010, t)  # +10 cents
	var v6 = _saw_wave(freq * 0.998, t)  # -2 cents (micro)
	var v7 = _saw_wave(freq * 1.003, t)  # +3 cents (micro)

	return (v1 + v2 + v3 + v4 + v5 + v6 + v7) * 0.143  # Mix 7 voices

static func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _write_sample16_stereo(data: PackedByteArray, index: int, l: float, r: float):
	var l_int = int(clamp(l * 32767.0, -32768.0, 32767.0))
	var r_int = int(clamp(r * 32767.0, -32768.0, 32767.0))

	var offset = index * 4
	data[offset] = l_int & 0xFF
	data[offset + 1] = (l_int >> 8) & 0xFF
	data[offset + 2] = r_int & 0xFF
	data[offset + 3] = (r_int >> 8) & 0xFF

static func _create_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = true
	stream.data = data
	return stream
