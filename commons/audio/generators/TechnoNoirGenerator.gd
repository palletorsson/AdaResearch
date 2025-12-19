extends Node

# TechnoNoirGenerator - Procedural tech-noir ambient sound generator
# Extracted from john_cage_tech_noir.gd for centralized audio system integration
#
# Generates atmospheric sounds inspired by John Cage's experimental composition techniques
# All methods are static for easy integration with SoundBankSingleton

class_name TechnoNoirGenerator

# Audio constants
const SAMPLE_RATE = 44100
const FORMAT = AudioStreamWAV.FORMAT_16_BITS

# ===== UTILITY METHODS =====

static func _create_rng(seed_value: int = -1) -> RandomNumberGenerator:
	"""Create a RandomNumberGenerator with optional seed"""
	var rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	return rng

static func _create_stream_base(stereo: bool = true) -> AudioStreamWAV:
	"""Create a basic AudioStreamWAV with standard settings"""
	var stream = AudioStreamWAV.new()
	stream.format = FORMAT
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = stereo
	return stream

# ===== DRONE SOUNDS =====

static func create_endless_drone(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate an endless looping drone with harmonic structure

	Parameters:
	- base_freq: float (default: 55.0) - Base frequency in Hz
	- buffer_length: float (default: 30.0) - Loop length in seconds
	- volume: float (default: 0.4) - Overall volume multiplier
	- seed: int (default: -1) - Random seed for reproducibility
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var base_freq = params.get("base_freq", 55.0)
	var buffer_length = params.get("buffer_length", 30.0)
	var volume = params.get("volume", 0.4)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)  # 4 bytes per frame (16-bit stereo)

	# Harmonic structure
	var harmonics = [1.0, 2.0, 2.5, 3.0, 5.0, 8.0]
	var harmonic_volumes = [0.4, 0.3, 0.2, 0.15, 0.1, 0.05]

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Create the harmonic structure
		for j in range(harmonics.size()):
			var freq = base_freq * harmonics[j]
			var vol = harmonic_volumes[j] * (0.9 + 0.1 * sin(2.0 * PI * 0.05 * t))
			sample += sin(2.0 * PI * freq * t) * vol

		# Add slow LFO modulation
		var lfo1 = 0.15 * sin(2.0 * PI * 0.01 * t)
		var lfo2 = 0.1 * sin(2.0 * PI * 0.02 * t)
		sample = sample * (0.85 + lfo1 + lfo2)

		# Add subtle noise texture
		sample += rng.randf_range(-0.05, 0.05)

		# Clamp and apply volume
		sample = clamp(sample * volume, -1.0, 1.0)

		# Create stereo output with slight variations
		var left = sample * (1.0 + 0.02 * sin(2.0 * PI * 0.03 * t))
		var right = sample * (1.0 - 0.02 * sin(2.0 * PI * 0.03 * t))

		# Convert to 16-bit PCM
		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count

	return stream

# ===== AMBIENT SOUNDS =====

static func create_city_ambience(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate urban ambient atmosphere with traffic and rumble

	Parameters:
	- buffer_length: float (default: 10.0) - Loop length in seconds
	- traffic_volume: float (default: 0.1) - Traffic noise level
	- rumble_volume: float (default: 0.2) - Low frequency rumble level
	- ambient_volume: float (default: 0.15) - Background noise level
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 10.0)
	var traffic_volume = params.get("traffic_volume", 0.1)
	var rumble_volume = params.get("rumble_volume", 0.2)
	var ambient_volume = params.get("ambient_volume", 0.15)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Low frequency rumble (background city noise)
		var rumble = sin(2.0 * PI * 30.0 * t) * 0.3 + sin(2.0 * PI * 55.0 * t) * 0.2
		rumble *= rumble_volume * (0.8 + 0.2 * sin(2.0 * PI * 0.07 * t))

		# Traffic sounds (filtered noise)
		var traffic = rng.randf_range(-1.0, 1.0)
		traffic = traffic * traffic * traffic  # Shape the noise
		traffic = traffic * traffic_volume * (0.7 + 0.3 * sin(2.0 * PI * 0.2 * t))

		# Ambient noise
		var ambient = (rng.randf_range(-1.0, 1.0) * 0.1) * ambient_volume

		# Mix together
		var sample = clamp(rumble + traffic + ambient, -0.8, 0.8)

		# Convert to 16-bit PCM
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)

	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count

	return stream

# ===== EVENT SOUNDS =====

static func create_distant_siren(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate distant police/ambulance siren with doppler effect

	Parameters:
	- buffer_length: float (default: 6.0) - Duration in seconds
	- base_freq: float (default: 500.0) - Base siren frequency
	- freq_range: float (default: 250.0) - Frequency modulation range
	- cycle_time: float (default: 2.0) - Time for one up-down cycle
	- volume: float (default: 0.2) - Distance effect volume
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 6.0)
	var base_freq = params.get("base_freq", 500.0) + rng.randf_range(-100, 100)
	var freq_range = params.get("freq_range", 250.0)
	var cycle_time = params.get("cycle_time", 2.0)
	var volume = params.get("volume", 0.2)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Calculate frequency with sinusoidal modulation
		var freq = base_freq + freq_range * sin(2.0 * PI * (1.0/cycle_time) * t)

		# Generate siren tone
		var siren = sin(2.0 * PI * freq * t) * volume

		# Add echo/reflection
		var echo_time = 0.3
		var echo_volume = 0.15
		if t > echo_time:
			var echo_freq = base_freq + freq_range * sin(2.0 * PI * (1.0/cycle_time) * (t - echo_time))
			var echo = sin(2.0 * PI * echo_freq * (t - echo_time)) * echo_volume
			siren += echo

		# Add city ambience noise
		var ambient = rng.randf_range(-1.0, 1.0) * 0.05
		var sample = clamp(siren + ambient, -1.0, 1.0)

		# Stereo panning - siren moves across field
		var pan = sin(2.0 * PI * 0.1 * t) * 0.7
		var left = sample * (1.0 - max(0, pan))
		var right = sample * (1.0 + min(0, pan))

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

static func create_static_burst(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate electronic static burst with crackles

	Parameters:
	- buffer_length: float (default: 3.0) - Duration in seconds
	- static_volume: float (default: 0.25) - Base static level
	- crackle_chance: float (default: 0.03) - Probability of crackle per sample
	- crackle_volume: float (default: 0.5) - Crackle intensity
	- attack_time: float (default: 0.1) - Attack envelope duration
	- decay_time: float (default: 2.5) - Decay envelope duration
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 3.0)
	var static_volume = params.get("static_volume", 0.25)
	var crackle_chance = params.get("crackle_chance", 0.03)
	var crackle_volume = params.get("crackle_volume", 0.5)
	var attack_time = params.get("attack_time", 0.1)
	var decay_time = params.get("decay_time", 2.5)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE

		# Calculate envelope
		var envelope = 0.0
		if t < attack_time:
			envelope = t / attack_time
		else:
			envelope = max(0.0, 1.0 - ((t - attack_time) / decay_time))

		# Base static (shaped noise)
		var noise = rng.randf_range(-1.0, 1.0)
		noise = noise * noise * sign(noise)
		var static_sound = noise * static_volume

		# Add random crackles
		var crackle = 0.0
		if rng.randf() < crackle_chance:
			crackle = rng.randf_range(-1.0, 1.0) * crackle_volume

		# Modulate with LFO
		var lfo_mod = 0.8 + 0.2 * sin(2.0 * PI * 4.0 * t)

		var sample = clamp((static_sound + crackle) * envelope * lfo_mod, -1.0, 1.0)

		# Stereo output with slight variation
		var left = sample
		var right = sample * 0.9 + rng.randf_range(-0.05, 0.05)

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

static func create_rain_segment(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate atmospheric rain with individual droplets

	Parameters:
	- buffer_length: float (default: 5.0) - Duration in seconds
	- intensity: float (default: 0.3) - Rain intensity (0.0 - 1.0)
	- base_noise: float (default: 0.1) - Continuous rain noise level
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 5.0)
	var intensity = params.get("intensity", 0.2) + rng.randf() * 0.2
	var base_noise = params.get("base_noise", 0.1)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	var raindrops = []

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Continuous light rain (filtered noise)
		var noise = rng.randf_range(-1.0, 1.0)
		noise = noise * noise * noise
		sample += noise * base_noise

		# Envelope for fade in/out
		var envelope = 1.0
		if t < 1.0:
			envelope = t
		elif t > buffer_length - 1.0:
			envelope = buffer_length - t

		# Random individual raindrops
		if rng.randf() < intensity * 0.01:
			raindrops.append({
				"time": t,
				"pan": rng.randf_range(-0.8, 0.8),
				"volume": rng.randf_range(0.05, 0.2)
			})

		# Process active raindrops
		var drop_idx = 0
		while drop_idx < raindrops.size():
			var drop = raindrops[drop_idx]
			var age = t - drop["time"]
			if age < 0.1:
				var env = exp(-age * 50.0) * drop["volume"]
				var drop_sound = sin(2.0 * PI * 3000.0 * age) * env
				sample += drop_sound
				drop_idx += 1
			else:
				raindrops.remove_at(drop_idx)

		sample = clamp(sample * envelope, -1.0, 1.0)

		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 0.9 * 32767.0))

	stream.data = data
	return stream

static func create_mechanical_whir(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate mechanical machinery sound with gears

	Parameters:
	- buffer_length: float (default: 4.0) - Duration in seconds
	- motor_freq: float (default: 80.0) - Base motor frequency
	- attack: float (default: 0.5) - Attack time
	- release: float (default: 1.0) - Release time
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 4.0)
	var motor_freq = params.get("motor_freq", 80.0) + rng.randf_range(-20, 20)
	var attack = params.get("attack", 0.5)
	var release = params.get("release", 1.0)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	var gear_ratios = [1.0, 2.0, 3.5, 7.0]
	var volumes = [0.3, 0.2, 0.15, 0.1]

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Calculate envelope
		var env = 1.0
		if t < attack:
			env = t / attack
		elif t > buffer_length - release:
			env = (buffer_length - t) / release

		# Motor base sound
		var motor = sin(2.0 * PI * motor_freq * t) * 0.2

		# Gear components
		for j in range(gear_ratios.size()):
			var freq = motor_freq * gear_ratios[j]
			var component = sin(2.0 * PI * freq * t) * volumes[j]
			component *= (1.0 + 0.03 * sin(2.0 * PI * (0.3 + j * 0.2) * t))
			motor += component

		# Add noise for friction/air
		motor += rng.randf_range(-0.1, 0.1) * 0.05

		# Speed variations
		var speed_mod = 1.0 + 0.1 * sin(2.0 * PI * 0.25 * t)
		sample = clamp(motor * speed_mod * env, -1.0, 1.0)

		# Stereo effect
		var left = sample
		var right = sample * (1.0 + 0.05 * sin(2.0 * PI * 1.5 * t))

		data.encode_s16(i * 4, int(left * 32767.0))
		data.encode_s16(i * 4 + 2, int(right * 32767.0))

	stream.data = data
	return stream

static func create_typing_segment(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate keyboard typing sounds

	Parameters:
	- buffer_length: float (default: 4.0) - Duration in seconds
	- typing_speed: float (default: 0.15) - Average time between keypresses
	- key_volume_min: float (default: 0.15) - Minimum key volume
	- key_volume_max: float (default: 0.35) - Maximum key volume
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 4.0)
	var typing_speed = params.get("typing_speed", 0.15)
	var key_volume_min = params.get("key_volume_min", 0.15)
	var key_volume_max = params.get("key_volume_max", 0.35)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	# Generate keypress timings
	var keypresses = []
	var time = 0.5
	while time < buffer_length - 0.5:
		time += typing_speed * (0.7 + 0.6 * rng.randf())
		keypresses.append({
			"time": time,
			"volume": rng.randf_range(key_volume_min, key_volume_max),
			"tone": 1500 + rng.randf_range(-400, 400)
		})

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Process each keypress
		for press in keypresses:
			if abs(t - press["time"]) < 0.05:
				var key_age = t - press["time"]
				if key_age >= 0:
					var env = press["volume"] * exp(-key_age * 100.0)
					var click = sin(2.0 * PI * press["tone"] * key_age) * env
					var noise = rng.randf_range(-1.0, 1.0) * env * 0.7
					sample += click + noise

		# Background mechanical noise
		sample += rng.randf_range(-1.0, 1.0) * 0.01
		sample = clamp(sample, -1.0, 1.0)

		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 0.95 * 32767.0))

	stream.data = data
	return stream

static func create_electric_hum(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate electrical power line hum with harmonics

	Parameters:
	- buffer_length: float (default: 5.0) - Duration in seconds
	- hum_freq: float (default: 60.0) - Base hum frequency (50Hz EU, 60Hz US)
	- attack: float (default: 0.8) - Attack time
	- release: float (default: 1.5) - Release time
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 5.0)
	var hum_freq = params.get("hum_freq", 60.0)
	var attack = params.get("attack", 0.8)
	var release = params.get("release", 1.5)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	var harmonics = [1.0, 2.0, 3.0, 5.0]
	var harmonic_volumes = [0.25, 0.12, 0.08, 0.04]

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Calculate envelope
		var env = 1.0
		if t < attack:
			env = t / attack
		elif t > buffer_length - release:
			env = (buffer_length - t) / release

		# Main hum frequency and harmonics
		for j in range(harmonics.size()):
			var freq = hum_freq * harmonics[j]
			sample += sin(2.0 * PI * freq * t) * harmonic_volumes[j]

		# Add fluctuations
		var fluctuation = 0.1 * sin(2.0 * PI * 0.5 * t) + 0.05 * sin(2.0 * PI * 0.3 * t)
		sample *= (1.0 + fluctuation)

		# Add noise
		sample += rng.randf_range(-0.05, 0.05)

		# Occasional power surge
		if rng.randf() < 0.001:
			sample *= 1.3

		sample = clamp(sample * env, -1.0, 1.0)

		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 0.97 * 32767.0))

	stream.data = data
	return stream

static func create_heartbeat_segment(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate heartbeat sound with lub-dub rhythm

	Parameters:
	- buffer_length: float (default: 7.0) - Duration in seconds
	- bpm: float (default: 70.0) - Beats per minute
	- attack: float (default: 1.0) - Attack time
	- sustain: float (default: 4.0) - Sustain time
	- release: float (default: 2.0) - Release time
	- seed: int (default: -1) - Random seed
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)

	var buffer_length = params.get("buffer_length", 7.0)
	var bpm = params.get("bpm", 65.0) + rng.randf_range(-5, 15)
	var attack = params.get("attack", 1.0)
	var sustain = params.get("sustain", 4.0)
	var release = params.get("release", 2.0)

	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)

	var beat_interval = 60.0 / bpm

	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0

		# Calculate envelope
		var env = 0.0
		if t < attack:
			env = t / attack
		elif t < attack + sustain:
			env = 1.0
		else:
			env = max(0.0, 1.0 - ((t - attack - sustain) / release))

		# Calculate beat timing (two pulses per beat - lub-dub)
		var beat_phase = fmod(t, beat_interval) / beat_interval

		# First pulse (lub)
		if beat_phase < 0.15:
			var pulse_env = exp(-beat_phase * 40.0) * 0.6
			sample += sin(2.0 * PI * 60.0 * beat_phase) * pulse_env

		# Second pulse (dub)
		if beat_phase > 0.2 and beat_phase < 0.35:
			var pulse2_phase = beat_phase - 0.2
			var pulse_env = exp(-pulse2_phase * 40.0) * 0.5
			sample += sin(2.0 * PI * 50.0 * pulse2_phase) * pulse_env

		# Add body cavity resonance
		sample = sample * (1.0 + 0.1 * sin(2.0 * PI * 2.0 * t))

		# Add quiet background noise (bloodflow)
		sample += rng.randf_range(-0.1, 0.1) * 0.02

		sample = clamp(sample * env, -1.0, 1.0)

		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)

	stream.data = data
	return stream

static func create_hydraulic_hiss(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate a pressurized hydraulic release sound
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)
	
	var buffer_length = params.get("buffer_length", 2.0)
	var volume = params.get("volume", 0.4)
	
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		
		# Envelope: sharp attack, curved decay
		var env = exp(-t * 6.0)
		
		# Filtered noise
		var noise = rng.randf_range(-1.0, 1.0)
		var sample = noise * env * volume
		
		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 32767.0))
		
	stream.data = data
	return stream

static func create_data_chirp(params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate short high-pitched digital data chirps
	"""
	var rng = _create_rng(params.get("seed", -1))
	var stream = _create_stream_base(true)
	
	var buffer_length = params.get("buffer_length", 1.5)
	var volume = params.get("volume", 0.3)
	
	var frame_count = int(SAMPLE_RATE * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		# 3 short bursts
		for b in range(3):
			var start = 0.2 + b * 0.4
			if t >= start and t < start + 0.1:
				var bt = t - start
				var freq = 2000.0 + sin(bt * 100.0) * 500.0
				sample += sin(2.0 * PI * freq * t) * 0.5 * exp(-bt * 30.0)
		
		sample = clamp(sample * volume, -1.0, 1.0)
		data.encode_s16(i * 4, int(sample * 32767.0))
		data.encode_s16(i * 4 + 2, int(sample * 32767.0))
		
	stream.data = data
	return stream

# ===== GENERATION ROUTER =====

static func generate_sound(sound_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	"""
	Generate a tech noir sound by name

	Available sounds:
	- drone, endless_drone
	- city_ambience, city, urban
	- distant_siren, siren
	- static_burst, static
	- rain_segment, rain
	- mechanical_whir, machinery, mechanical
	- typing_segment, typing, keyboard
	- electric_hum, hum, power
	- heartbeat_segment, heartbeat, pulse
	"""
	var normalized_name = sound_name.to_lower().strip_edges()

	match normalized_name:
		"drone", "endless_drone":
			return create_endless_drone(params)
		"city_ambience", "city", "urban", "city_hum":
			return create_city_ambience(params)
		"distant_siren", "siren":
			return create_distant_siren(params)
		"static_burst", "static":
			return create_static_burst(params)
		"rain_segment", "rain":
			return create_rain_segment(params)
		"mechanical_whir", "machinery", "mechanical", "motor_whir":
			return create_mechanical_whir(params)
		"typing_segment", "typing", "keyboard":
			return create_typing_segment(params)
		"electric_hum", "hum", "power":
			return create_electric_hum(params)
		"heartbeat_segment", "heartbeat", "pulse":
			return create_heartbeat_segment(params)
		"hydraulic_hiss":
			return create_hydraulic_hiss(params)
		"data_chirp":
			return create_data_chirp(params)
		_:
			push_warning("TechnoNoirGenerator: Unknown sound name: " + sound_name)
			return null
