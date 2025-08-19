extends Node

# Endless Techno-Noir Ambient Generator
# Creates a continuous ambient soundscape with modulated drones and random sound elements

# Audio buses setup
const NUM_BUSES = 4
var bus_names = ["Master", "Reverb", "Delay", "LowPass"]

# Sound generators and audio players
var rng = RandomNumberGenerator.new()
var sample_rate = 44100
var buffer_size = 4096

# Main sound stream players
var drone_player = null
var ambient_player = null
var effect_players = []
var num_effect_players = 5  # Pool of players for random effects

# Pre-generated sound streams
var precreated_sounds = {}
var sound_types = [
	"distant_siren", 
	"static_burst", 
	"rain_segment", 
	"mechanical_whir", 
	"typing_segment", 
	"electric_hum", 
	"heartbeat_segment"
]

# Time tracking
var elapsed_time = 0.0
var last_effect_time = 0.0
var is_initialized = false

func _ready():
	rng.randomize()
	setup_audio_buses()
	setup_players()
	
	# Create a loading screen or message
	print("Pre-generating soundscape, please wait...")
	
	# Defer sound generation to next frame to allow UI to update
	call_deferred("initialize_sounds")

func initialize_sounds():
	# Pre-generate all sounds to avoid runtime generation
	generate_all_sounds()
	start_ambient()
	is_initialized = true
	print("Sound generation complete!")
	
func _process(delta):
	if not is_initialized:
		return
		
	elapsed_time += delta
	
	# Check if we should trigger a random sound effect
	if elapsed_time - last_effect_time > rng.randf_range(3.0, 15.0):
		play_random_effect()
		last_effect_time = elapsed_time
		
func generate_all_sounds():
	# Pre-generate the drone and ambient sounds
	precreated_sounds["drone"] = create_endless_drone()
	precreated_sounds["city_ambience"] = create_city_ambience()
	
	# Pre-generate variations of each effect sound
	for sound_type in sound_types:
		precreated_sounds[sound_type] = []
		
		# Create 3 variations of each sound type
		for i in range(3):
			var stream = null
			
			match sound_type:
				"distant_siren": stream = create_distant_siren()
				"static_burst": stream = create_static_burst()
				"rain_segment": stream = create_rain_segment()
				"mechanical_whir": stream = create_mechanical_whir()
				"typing_segment": stream = create_typing_segment()
				"electric_hum": stream = create_electric_hum()
				"heartbeat_segment": stream = create_heartbeat_segment()
			
			precreated_sounds[sound_type].append(stream)

func setup_audio_buses():
	# Create audio buses for effects
	for i in range(1, NUM_BUSES):
		var bus_idx = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, bus_names[i])
		
		# Connect to master
		AudioServer.set_bus_send(bus_idx, "Master")
		
		# Add effects based on bus type
		match bus_names[i]:
			"Reverb":
				var reverb = AudioEffectReverb.new()
				reverb.room_size = 0.9
				reverb.damping = 0.1
				reverb.wet = 0.4
				AudioServer.add_bus_effect(bus_idx, reverb)
			"Delay":
				var delay = AudioEffectDelay.new()
				delay.feedback_delay_ms = 400
				delay.dry = 0.6
				delay.tap1_delay_ms = 300
				delay.tap2_delay_ms = 600
				AudioServer.add_bus_effect(bus_idx, delay)
			"LowPass":
				var lowpass = AudioEffectLowPassFilter.new()
				lowpass.cutoff_hz = 2000
				AudioServer.add_bus_effect(bus_idx, lowpass)

func setup_players():
	# Create main players for continuous sounds
	drone_player = AudioStreamPlayer.new()
	drone_player.bus = "Reverb"
	drone_player.volume_db = -10
	add_child(drone_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "LowPass"
	ambient_player.volume_db = -15
	add_child(ambient_player)
	
	# Create pool of players for random effects
	for i in range(num_effect_players):
		var player = AudioStreamPlayer.new()
		player.volume_db = -12
		if i % 2 == 0:
			player.bus = "Delay"
		else:
			player.bus = "Reverb"
		add_child(player)
		effect_players.append(player)

func start_ambient():
	# Start the continuous drone using pre-generated stream
	drone_player.stream = precreated_sounds["drone"]
	drone_player.play()
	
	# Start city ambience using pre-generated stream
	ambient_player.stream = precreated_sounds["city_ambience"]
	ambient_player.play()

func play_random_effect():
	# Find an available player
	var available_players = []
	for player in effect_players:
		if not player.playing:
			available_players.append(player)
	
	if available_players.size() > 0:
		var player = available_players[rng.randi() % available_players.size()]
		
		# Choose a random effect type from our pre-generated sounds
		var sound_type = sound_types[rng.randi() % sound_types.size()]
		
		# Get a random variation of this sound type
		var variation_index = rng.randi() % precreated_sounds[sound_type].size()
		var stream = precreated_sounds[sound_type][variation_index]
		
		player.stream = stream
		player.volume_db = -15 - rng.randf_range(0, 10)  # Random volume for variation
		player.play()

# Sound Generators

func create_endless_drone():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	# Create a long looping drone (30 seconds)
	var buffer_length = 30.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)  # 4 bytes per frame (16-bit stereo)
	
	# Parameters for procedural generation
	var base_freq = 55.0  # Bass A
	var harmonics = [1.0, 2.0, 2.5, 3.0, 5.0, 8.0]
	var harmonic_volumes = [0.4, 0.3, 0.2, 0.15, 0.1, 0.05]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Create the harmonic structure
		for j in range(harmonics.size()):
			var freq = base_freq * harmonics[j]
			var volume = harmonic_volumes[j] * (0.9 + 0.1 * sin(2.0 * PI * 0.05 * t))
			sample += sin(2.0 * PI * freq * t) * volume
		
		# Add slow LFO modulation
		var lfo1 = 0.15 * sin(2.0 * PI * 0.01 * t)
		var lfo2 = 0.1 * sin(2.0 * PI * 0.02 * t)
		
		# Add "movement" to the drone
		sample = sample * (0.85 + lfo1 + lfo2)
		
		# Add subtle noise texture
		sample += rng.randf_range(-0.05, 0.05)
		
		# Clamp the sample
		sample = clamp(sample * 0.4, -1.0, 1.0)  # Overall volume reduction
		
		# Create stereo output with slight variations
		var left = sample * (1.0 + 0.02 * sin(2.0 * PI * 0.03 * t))
		var right = sample * (1.0 - 0.02 * sin(2.0 * PI * 0.03 * t))
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	return stream

func create_city_ambience():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 10.0  # 10 seconds loop
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)  # 4 bytes per frame (16-bit stereo)
	
	# Parameters
	var traffic_volume = 0.1
	var rumble_volume = 0.2
	var ambient_volume = 0.15
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		
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
		
		# Convert to 16-bit PCM and store in buffer
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)  # Left channel
		data.encode_s16(i * 4 + 2, frame_value)  # Right channel
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	return stream

func create_distant_siren():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 6.0  # 6 seconds
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)  # 4 bytes per frame (16-bit stereo)
	
	# Siren parameters
	var base_freq = 500.0 + rng.randf_range(-100, 100)
	var freq_range = 250.0
	var cycle_time = 2.0  # Time for one up-down cycle
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		
		# Calculate frequency with sinusoidal modulation
		var freq = base_freq + freq_range * sin(2.0 * PI * (1.0/cycle_time) * t)
		
		# Generate siren tone
		var siren = sin(2.0 * PI * freq * t)
		
		# Distance effect (lowpass filter approximation and reverb)
		siren *= 0.2  # Lower volume for distance
		
		# Add some echo/reflection
		var echo_time = 0.3  # Echo delay in seconds
		var echo_volume = 0.15
		if t > echo_time:
			var echo_freq = base_freq + freq_range * sin(2.0 * PI * (1.0/cycle_time) * (t - echo_time))
			var echo = sin(2.0 * PI * echo_freq * (t - echo_time)) * echo_volume
			siren += echo
		
		# Add city ambience noise
		var ambient = rng.randf_range(-1.0, 1.0) * 0.05
		
		var sample = siren + ambient
		sample = clamp(sample, -1.0, 1.0)
		
		# Stereo output - siren pans across stereo field
		var pan = sin(2.0 * PI * 0.1 * t) * 0.7 # -0.7 to 0.7
		var left = sample * (1.0 - max(0, pan))
		var right = sample * (1.0 + min(0, pan))
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_static_burst():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 3.0  # 3 seconds
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Parameters for filtered noise
	var static_volume = 0.25
	var crackle_chance = 0.03
	var crackle_volume = 0.5
	
	# Envelope for the static burst
	var attack_time = 0.1
	var decay_time = 2.5
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		
		# Calculate envelope
		var envelope = 0.0
		if t < attack_time:
			envelope = t / attack_time  # Linear attack
		else:
			envelope = (1.0 - ((t - attack_time) / decay_time))
			envelope = max(0.0, envelope)
		
		# Base static (shaped noise)
		var noise = rng.randf_range(-1.0, 1.0)
		noise = noise * noise * sign(noise)  # Shape the noise
		var static_sound = noise * static_volume
		
		# Add random crackles
		var crackle = 0.0
		if rng.randf() < crackle_chance:
			crackle = rng.randf_range(-1.0, 1.0) * crackle_volume
		
		# Modulate with LFO
		var lfo_mod = 0.8 + 0.2 * sin(2.0 * PI * 4.0 * t)
		
		var sample = (static_sound + crackle) * envelope * lfo_mod
		sample = clamp(sample, -1.0, 1.0)
		
		# Stereo output with slight variation
		var left = sample
		var right = sample * 0.9 + rng.randf_range(-0.05, 0.05)
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_rain_segment():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 5.0  # 5 seconds
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Rain parameters
	var raindrops = []
	var intensity = 0.2 + rng.randf() * 0.2  # Random intensity
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Continuous light rain (filtered noise)
		var noise = rng.randf_range(-1.0, 1.0)
		noise = noise * noise * noise  # Shape the noise
		sample += noise * 0.1
		
		# Envelope for the rain segment
		var envelope = 0.0
		if t < 1.0:
			envelope = t  # Linear fade in
		elif t > buffer_length - 1.0:
			envelope = (buffer_length - t)  # Linear fade out
		else:
			envelope = 1.0
		
		# Random individual raindrops
		if rng.randf() < intensity * 0.01:
			raindrops.append({
				"time": t,
				"pan": rng.randf_range(-0.8, 0.8),
				"volume": rng.randf_range(0.05, 0.2)
			})
		
		# Process active raindrops
		var i_drop = 0
		while i_drop < raindrops.size():
			var drop = raindrops[i_drop]
			var age = t - drop["time"]
			if age < 0.1:
				var env = exp(-age * 50.0) * drop["volume"]
				var drop_sound = sin(2.0 * PI * 3000.0 * age) * env
				sample += drop_sound
				i_drop += 1
			else:
				raindrops.remove_at(i_drop)
		
		sample = clamp(sample * envelope, -1.0, 1.0)
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(sample * 32767.0)
		var right_value = int(sample * 0.9 * 32767.0)  # Slight stereo variation
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_mechanical_whir():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 4.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Parameters
	var motor_freq = 80.0 + rng.randf_range(-20, 20)  # Base motor frequency
	var gear_ratios = [1.0, 2.0, 3.5, 7.0]  # Different gear components
	var volumes = [0.3, 0.2, 0.15, 0.1]
	
	# Envelope
	var attack = 0.5
	var release = 1.0
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Calculate envelope
		var env = 1.0
		if t < attack:
			env = t / attack
		elif t > buffer_length - release:
			env = (buffer_length - t) / release
		
		# Motor base sound
		var motor = sin(2.0 * PI * motor_freq * t) * 0.2
		
		# Gear and mechanical components
		for j in range(gear_ratios.size()):
			var freq = motor_freq * gear_ratios[j]
			var component = sin(2.0 * PI * freq * t) * volumes[j]
			
			# Add slight frequency instability
			component *= (1.0 + 0.03 * sin(2.0 * PI * (0.3 + j * 0.2) * t))
			
			motor += component
		
		# Add some noise for friction/air
		motor += rng.randf_range(-0.1, 0.1) * 0.05
		
		# Speed variations
		var speed_mod = 1.0 + 0.1 * sin(2.0 * PI * 0.25 * t)
		motor *= speed_mod * env
		
		sample = clamp(motor, -1.0, 1.0)
		
		# Stereo effect
		var left = sample
		var right = sample * (1.0 + 0.05 * sin(2.0 * PI * 1.5 * t))
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_typing_segment():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 4.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Generate keypress timings
	var keypresses = []
	var typing_speed = 0.15  # Average time between keypresses
	var time = 0.5  # Start after a small delay
	
	while time < buffer_length - 0.5:
		time += typing_speed * (0.7 + 0.6 * rng.randf())
		keypresses.append({
			"time": time,
			"volume": 0.15 + 0.2 * rng.randf(),
			"tone": 1500 + rng.randf_range(-400, 400)
		})
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
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
		
		# Background mechanical noise (the typewriter carriage)
		var bg_noise = rng.randf_range(-1.0, 1.0) * 0.01
		sample += bg_noise
		
		sample = clamp(sample, -1.0, 1.0)
		
		# Stereo output
		var left = sample
		var right = sample * 0.95
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_electric_hum():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 5.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Parameters
	var hum_freq = 60.0  # 60Hz power line frequency
	var harmonics = [1.0, 2.0, 3.0, 5.0]
	var harmonic_volumes = [0.25, 0.12, 0.08, 0.04]
	
	# Envelope
	var attack = 0.8
	var release = 1.5
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
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
		
		# Add some noise
		sample += rng.randf_range(-0.05, 0.05)
		
		# Occasional power surge
		if rng.randf() < 0.001:
			sample *= 1.3
		
		sample = clamp(sample * env, -1.0, 1.0)
		
		# Convert to 16-bit PCM and store in buffer
		var left_value = int(sample * 32767.0)
		var right_value = int(sample * 0.97 * 32767.0)  # Slight stereo variation
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_heartbeat_segment():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 7.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Heartbeat parameters
	var bpm = 65.0 + rng.randf_range(-5, 15)  # Heart rate
	var beat_interval = 60.0 / bpm
	
	# Envelope
	var attack = 1.0
	var sustain = 4.0
	var release = 2.0
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Calculate envelope
		var env = 0.0
		if t < attack:
			env = t / attack
		elif t < attack + sustain:
			env = 1.0
		else:
			env = 1.0 - min(1.0, (t - attack - sustain) / release)
		
		# Calculate beat timing (two pulses per beat - lub-dub)
		var beat_phase = fmod(t, beat_interval) / beat_interval
		
		# First pulse (lub)
		if beat_phase < 0.15:
			var pulse_env = exp(-beat_phase * 40.0) * 0.6
			sample += sin(2.0 * PI * 60.0 * beat_phase) * pulse_env
		
		# Second pulse (dub)
		if beat_phase > 0.2 and beat_phase < 0.35:
			var pulse2_phase = beat_phase - 0.2
			var pulse_env = exp(-pulse2_phase * 40.0) * 0.5  # Slightly quieter
			sample += sin(2.0 * PI * 50.0 * pulse2_phase) * pulse_env  # Slightly lower pitch
		
		# Add some body cavity resonance
		sample = sample * (1.0 + 0.1 * sin(2.0 * PI * 2.0 * t))
		
		# Add very quiet background noise (bloodflow)
		sample += rng.randf_range(-0.1, 0.1) * 0.02
		
		sample = clamp(sample * env, -1.0, 1.0)
		
		# Convert to 16-bit PCM and store in buffer
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)  # Left channel
		data.encode_s16(i * 4 + 2, frame_value)  # Right channel
	
	stream.data = data
	return stream
