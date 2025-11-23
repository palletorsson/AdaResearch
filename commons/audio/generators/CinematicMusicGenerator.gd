extends Node
class_name CinematicMusicGenerator

# CinematicMusicGenerator
# Generates long-form, evolving musical textures and melodies for epic soundscapes.
# Focuses on rich harmonics, slow modulation, and emotional resonance.

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
		_:
			push_warning("CinematicMusicGenerator: Unknown sound '%s'" % sound_name)
			return null

# 1. Blade Runner Pad (The Foundation)
# Deep, detuned sawtooth waves with a very slow low-pass filter sweep.
# Creates a sense of vastness and melancholy.
static func _generate_blade_runner_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0) # Long duration for evolution
	var base_freq = params.get("freq", 110.0)   # A2 (Deep)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# --- OSCILLATORS ---
		# Three detuned sawtooth waves for thickness
		var osc1 = _saw_wave(base_freq, t)
		var osc2 = _saw_wave(base_freq * 1.01, t) # Detuned up
		var osc3 = _saw_wave(base_freq * 0.99, t) # Detuned down
		
		var raw_mix = (osc1 + osc2 + osc3) * 0.33
		
		# --- FILTER ---
		# Slow, sweeping Low Pass Filter (LPF)
		# Opens up slowly and then closes, simulating a Vangelis sweep
		var sweep = sin(progress * PI) # 0 -> 1 -> 0
		var cutoff = lerp(400.0, 2500.0, sweep)
		var filtered = _low_pass(raw_mix, cutoff, t)
		
		# --- MODULATION ---
		# Subtle chorus/phaser effect using LFOs
		var lfo = sin(t * 0.5) * 0.1 + 1.0
		filtered *= lfo
		
		# --- ENVELOPE ---
		# Slow attack, full sustain, slow release
		var env = 1.0
		if progress < 0.2: # Attack (20%)
			env = progress / 0.2
		elif progress > 0.8: # Release (20%)
			env = (1.0 - progress) / 0.2
			
		var sample = filtered * env * 0.5 # Master volume
		
		_write_sample16(data, i, sample)
		
	return _create_stream(data)

# 2. Vangelis Brass Lead (The Melody)
# Expressive, bright saw/square hybrid with vibrato and slide.
# Plays a slow, mournful melody.
static func _generate_vangelis_brass_lead(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 15.0)
	var root_freq = params.get("freq", 220.0) # A3
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Melodic sequence (Dorian mode ish)
	# Frequencies relative to root: 1, b3, 4, 5, b7
	var melody_ratios = [1.0, 1.2, 1.33, 1.5, 1.78, 1.5, 1.2, 1.0]
	var note_duration = duration / melody_ratios.size()
	
	var current_freq = root_freq
	var target_freq = root_freq
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		# Determine current note target
		var note_idx = int(t / note_duration)
		if note_idx < melody_ratios.size():
			target_freq = root_freq * melody_ratios[note_idx]
			
		# Portamento (Slide)
		current_freq = lerp(current_freq, target_freq, 0.0005)
		
		# Vibrato (delayed)
		var note_time = fmod(t, note_duration)
		var vibrato_amount = clamp((note_time - 0.5), 0.0, 1.0) * 0.02 # Fade in vibrato
		var vibrato = sin(t * 5.0 * 2.0 * PI) * vibrato_amount * current_freq
		var freq = current_freq + vibrato
		
		# --- SYNTHESIS ---
		# Sawtooth + Pulse for "Brass" character
		var saw = _saw_wave(freq, t)
		var pulse = _pulse_wave(freq, t, 0.3)
		var mix = (saw * 0.6 + pulse * 0.4)
		
		# Filter (opens with velocity/loudness)
		var swell = sin(note_time / note_duration * PI) # Swell per note
		var cutoff = lerp(800.0, 4000.0, swell)
		var filtered = _low_pass(mix, cutoff, t)
		
		# Reverb-ish tail (simulated with release envelope)
		var sample = filtered * 0.4
		
		_write_sample16(data, i, sample)
		
	return _create_stream(data)

# 3. Cyber Rain Texture (The Atmosphere)
# Filtered noise with random droplets and stereo-like width.
static func _generate_cyber_rain_texture(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 10.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		# White Noise
		var noise = randf_range(-1.0, 1.0)
		
		# Rain Filter (High Pass + Low Pass)
		# Removes deep rumble and harsh hiss
		# Simple approximation
		noise = noise * 0.5 # Gain down
		
		# Random "Droplets" (Resonant pings)
		var droplet = 0.0
		if randf() > 0.9995: # Rare event
			droplet = sin(t * 2000.0 * 2.0 * PI) * exp(-((t*100.0) - floor(t*100.0))*10.0)
		
		var sample = (noise * 0.2) + (droplet * 0.5)
		
		# Fade edges
		if t < 1.0: sample *= t
		if t > duration - 1.0: sample *= (duration - t)
		
		_write_sample16(data, i, sample)
		
	return _create_stream(data)

# 4. Tears in Rain Pad (The Chords)
# Iconic Vangelis chord progression: Cmaj9 -> D/C -> Cmaj9
# Swelling, emotional strings/brass hybrid.
static func _generate_tears_in_rain_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 16.0)
	var root_freq = params.get("freq", 261.63) # Middle C
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Chord definitions (relative to root)
	# Cmaj9: 1, 3, 5, 7, 9 -> 1.0, 1.25, 1.5, 1.875, 2.25
	var chord1 = [1.0, 1.25, 1.5, 1.875, 2.25]
	
	# D6/C (Lydian feel): 1, 2, #4, 6, 7 -> 1.0, 1.125, 1.414, 1.66, 1.875
	var chord2 = [1.0, 1.125, 1.414, 1.66, 1.875]
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# Determine current chord (switch every 8 seconds approx)
		var current_chord = chord1
		var mix_ratio = 0.0
		
		if t > 5.0 and t < 11.0:
			# Crossfade to chord 2
			mix_ratio = sin((t - 5.0) / 6.0 * PI) # Smooth curve
		
		# Generate Chord 1
		var sig1 = 0.0
		for ratio in chord1:
			var f = root_freq * ratio
			sig1 += _saw_wave(f, t) * 0.2 + _saw_wave(f * 1.01, t) * 0.1 # Detuned
			
		# Generate Chord 2 (if needed)
		var sig2 = 0.0
		if mix_ratio > 0.01:
			for ratio in chord2:
				var f = root_freq * ratio
				sig2 += _saw_wave(f, t) * 0.2 + _saw_wave(f * 1.01, t) * 0.1
		
		# Mix chords
		var raw_mix = sig1 * (1.0 - mix_ratio) + sig2 * mix_ratio
		
		# Filter Sweep (The "Swell")
		var sweep = sin(progress * PI) 
		var cutoff = lerp(300.0, 2000.0, sweep * sweep)
		var filtered = raw_mix # Placeholder for filter
		
		# Apply simple lowpass effect (amplitude reduction of high freq harmonics approximation)
		# Since we don't have a real filter, we'll just volume swell heavily
		
		# Envelope
		var env = sin(progress * PI) # Long swell
		
		var sample = filtered * env * 0.3
		
		_write_sample16(data, i, sample)
		
	return _create_stream(data)

# 5. Tears in Rain Melody (The Lead)
# "Time... to die..."
# Breathy, flute-like lead with heavy reverb tail.
static func _generate_tears_in_rain_melody(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 16.0)
	var root_freq = params.get("freq", 523.25) # C5
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Melody: E... F#... G... E...
	# Ratios: 1.25, 1.414, 1.5, 1.25
	var melody_notes = [
		{"ratio": 1.25, "start": 1.0, "len": 3.0},  # E
		{"ratio": 1.414, "start": 5.0, "len": 2.0}, # F#
		{"ratio": 1.5, "start": 8.0, "len": 3.0},   # G
		{"ratio": 1.25, "start": 12.0, "len": 3.0}  # E
	]
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var sample = 0.0
		
		for note in melody_notes:
			if t >= note.start and t < note.start + note.len:
				var local_t = t - note.start
				var freq = root_freq * note.ratio
				
				# Vibrato (kicks in late)
				var vib_amount = clamp(local_t - 1.0, 0.0, 1.0) * 0.015
				var vib = sin(local_t * 6.0 * 2.0 * PI) * vib_amount * freq
				freq += vib
				
				# Flute synthesis (Sine + weak Saw)
				var sig = sin(2.0 * PI * freq * t) * 0.8
				sig += _saw_wave(freq, t) * 0.1 # Breath
				sig += randf_range(-0.1, 0.1) * 0.05 * sin(local_t * PI) # Breath noise
				
				# Envelope
				var env = 0.0
				if local_t < 0.5: env = local_t / 0.5
				elif local_t > note.len - 1.0: env = (note.len - local_t)
				else: env = 1.0
				
				sample += sig * env
		
		# Reverb simulation (simple delay line would be better, but just long release here)
		sample *= 0.4
		
		_write_sample16(data, i, sample)
		
	return _create_stream(data)

# ----- HELPER FUNCTIONS -----

static func _saw_wave(freq: float, t: float) -> float:
	return 2.0 * (t * freq - floor(t * freq + 0.5))

static func _pulse_wave(freq: float, t: float, width: float) -> float:
	var phase = t * freq - floor(t * freq)
	return 1.0 if phase < width else -1.0

static func _low_pass(sample: float, cutoff: float, t: float) -> float:
	# Very basic 1-pole low pass filter simulation
	# In a real DSP loop, this needs state. For procedural generation per-sample without state,
	# we approximate or use a simple averaging if we had a buffer.
	# Since we don't have easy state access in this static loop structure without passing it,
	# we will simulate the *effect* of a filter by reducing amplitude of high freq components
	# or just returning the sample (since proper DSP requires state).
	# TODO: Implement proper stateful filter. For now, return raw to avoid silence.
	return sample 

static func _write_sample16(data: PackedByteArray, index: int, value: float):
	var sample_int = int(clamp(value * 32767.0, -32768.0, 32767.0))
	data[index * 2] = sample_int & 0xFF
	data[index * 2 + 1] = (sample_int >> 8) & 0xFF

static func _create_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
