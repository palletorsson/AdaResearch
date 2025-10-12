extends Node3D

# Hans Zimmer Liturgical Ambient Generator (Audio Only)
# Creates solemn, sacred soundscapes with flowing choral textures, modal harmonies,
# and patient crescendos that evoke prophecy and divine presence

# Audio buses setup
const NUM_BUSES = 6
var bus_names = ["Master", "Cathedral_Reverb", "Choir_Hall", "Strings_Chamber", "Organ_Pipes", "Dark_Industrial"]

# Sound generators and audio players
var rng = RandomNumberGenerator.new()
var sample_rate: float = 44100.0
var buffer_size = 8192

# Threading and progress tracking
var generation_thread: Thread
var mutex: Mutex
var generation_progress = 0.0
var current_sound_name = ""
var total_sounds = 0
var sounds_completed = 0
var is_generating = false
var generation_complete = false
var stop_requested = false

func _ensure_rng() -> RandomNumberGenerator:
	if rng == null or not is_instance_valid(rng):
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return rng

func _randf_range(min_value: float, max_value: float) -> float:
	return _ensure_rng().randf_range(min_value, max_value)

func _randf() -> float:
	return _ensure_rng().randf()

func _randi() -> int:
	return _ensure_rng().randi()

# Main sound stream players
var choral_drone_player = null
var organ_foundation_player = null
var string_ensemble_player = null
var effect_players = []
var num_effect_players = 8

# Pre-generated sound streams
var precreated_sounds = {}
var sacred_sound_types = [
	"gregorian_phrase",
	"cathedral_bell", 
	"pipe_organ_swell",
	"sacred_whisper",
	"hymnal_fragment",
	"divine_breath",
	"prophetic_thunder",
	"angelic_texture"
]


# Time and spiritual atmosphere tracking
var elapsed_time = 0.0
var last_sacred_event_time = 0.0
var spiritual_intensity = 0.3
var is_initialized = false

# Progress visualization
var progress_visualizer = null

# Liturgical parameters
var current_liturgical_mode = "dorian"
var choral_voices = 16
var cathedral_size = "large"

# Signals
signal sacred_generation_started
signal divine_sound_created(sound_name: String)
signal liturgical_progress_updated(progress: float)
signal sacred_generation_complete

func _ready():
	_ensure_rng()
	mutex = Mutex.new()
	generation_thread = Thread.new()
	stop_requested = false
	
	# Calculate total sounds for liturgical collection
	total_sounds = 3 + (sacred_sound_types.size() * 2)
	
	setup_sacred_audio_buses()
	setup_liturgical_players()
	setup_progress_visualization()
	
	# Connect signals
	sacred_generation_started.connect(_on_sacred_generation_started)
	divine_sound_created.connect(_on_divine_sound_created)
	liturgical_progress_updated.connect(_on_liturgical_progress_updated)
	sacred_generation_complete.connect(_on_sacred_generation_complete)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -10.0)
	# Begin non-blocking sacred sound creation
	start_liturgical_generation()

func _exit_tree():
	# Stop generation and clean up when leaving the scene tree
	stop_requested = true
	
	# Wait for generation thread to finish if it's running
	if generation_thread and generation_thread.is_alive():
		generation_thread.wait_to_finish()
	
	# Stop all audio players
	if choral_drone_player and is_instance_valid(choral_drone_player):
		choral_drone_player.stop()
	if organ_foundation_player and is_instance_valid(organ_foundation_player):
		organ_foundation_player.stop()
	if string_ensemble_player and is_instance_valid(string_ensemble_player):
		string_ensemble_player.stop()
	
	for player in effect_players:
		if player and is_instance_valid(player):
			player.stop()

func _process(delta):
	_ensure_rng()
	if stop_requested:
		return
	if not is_initialized:
		return
	
	# Check if we're still in the scene tree
	if not is_inside_tree():
		return
		
	elapsed_time += delta
	
	# Update spiritual intensity with slow breathing rhythm
	spiritual_intensity = 0.4 + 0.3 * sin(elapsed_time * 0.1)
	
	# Trigger sacred events at irregular, contemplative intervals
	if elapsed_time - last_sacred_event_time > _randf_range(8.0, 25.0):
		trigger_sacred_event()
		last_sacred_event_time = elapsed_time

func setup_progress_visualization():
	# Create and setup the progress visualizer
	var ProgressVisualizer = preload("res://algorithms/wavefunctions/liturgicalambientgenerator/progressvisualizer.gd")
	progress_visualizer = ProgressVisualizer.new()
	get_tree().current_scene.add_child(progress_visualizer)
	progress_visualizer.connect_to_generator(self)
	progress_visualizer.visualization_complete.connect(_on_visualization_complete)

func _on_visualization_complete():
	if progress_visualizer:
		progress_visualizer.queue_free()
		progress_visualizer = null

func start_liturgical_generation():
	is_generating = true
	sacred_generation_started.emit()
	
	if generation_thread.start(_thread_generate_sacred_sounds) != OK:
		print("Failed to start sacred sound generation")
		return

func _thread_generate_sacred_sounds():
	_ensure_rng()
	if stop_requested:
		return
		
	# Generate foundational choral drone
	mutex.lock()
	current_sound_name = "choral_foundation"
	mutex.unlock()
	
	if stop_requested:
		return
	
	var choral_stream = create_choral_foundation()
	mutex.lock()
	precreated_sounds["choral_foundation"] = choral_stream
	sounds_completed += 1
	generation_progress = float(sounds_completed) / total_sounds
	mutex.unlock()
	
	call_deferred("_emit_divine_sound_created", "choral_foundation")
	call_deferred("_emit_liturgical_progress_updated")
	OS.delay_msec(200)
	
	if stop_requested:
		return
	
	# Generate organ foundation
	mutex.lock()
	current_sound_name = "organ_foundation"
	mutex.unlock()
	
	if stop_requested:
		return
	
	var organ_stream = create_organ_foundation()
	mutex.lock()
	precreated_sounds["organ_foundation"] = organ_stream
	sounds_completed += 1
	generation_progress = float(sounds_completed) / total_sounds
	mutex.unlock()
	
	call_deferred("_emit_divine_sound_created", "organ_foundation")
	call_deferred("_emit_liturgical_progress_updated")
	OS.delay_msec(200)
	
	if stop_requested:
		return
	
	# Generate string ensemble atmosphere
	mutex.lock()
	current_sound_name = "string_atmosphere"
	mutex.unlock()
	
	if stop_requested:
		return
	
	var strings_stream = create_string_atmosphere()
	mutex.lock()
	precreated_sounds["string_atmosphere"] = strings_stream
	sounds_completed += 1
	generation_progress = float(sounds_completed) / total_sounds
	mutex.unlock()
	
	call_deferred("_emit_divine_sound_created", "string_atmosphere")
	call_deferred("_emit_liturgical_progress_updated")
	OS.delay_msec(200)
	
	if stop_requested:
		return
	
	# Generate sacred effect sounds
	for sound_type in sacred_sound_types:
		if stop_requested:
			return
			
		mutex.lock()
		current_sound_name = sound_type
		precreated_sounds[sound_type] = []
		mutex.unlock()
		
		# Create 2 variations of each sacred sound
		for i in range(2):
			if stop_requested:
				return
				
			var stream = null
			
			match sound_type:
				"gregorian_phrase": stream = create_gregorian_phrase()
				"cathedral_bell": stream = create_cathedral_bell()
				"pipe_organ_swell": stream = create_pipe_organ_swell()
				"sacred_whisper": stream = create_sacred_whisper()
				"hymnal_fragment": stream = create_hymnal_fragment()
				"divine_breath": stream = create_divine_breath()
				"prophetic_thunder": stream = create_prophetic_thunder()
				"angelic_texture": stream = create_angelic_texture()
			
			mutex.lock()
			precreated_sounds[sound_type].append(stream)
			sounds_completed += 1
			generation_progress = float(sounds_completed) / total_sounds
			mutex.unlock()
			
			if i == 0:
				call_deferred("_emit_divine_sound_created", sound_type)
			call_deferred("_emit_liturgical_progress_updated")
			
			OS.delay_msec(150)
	
	# Sacred generation complete
	mutex.lock()
	generation_complete = true
	mutex.unlock()
	
	call_deferred("_emit_sacred_generation_complete")

func _emit_divine_sound_created(sound_name: String):
	divine_sound_created.emit(sound_name)

func _emit_liturgical_progress_updated():
	mutex.lock()
	var progress = generation_progress
	mutex.unlock()
	liturgical_progress_updated.emit(progress)

func _emit_sacred_generation_complete():
	sacred_generation_complete.emit()

func setup_sacred_audio_buses():
	# Create sacred audio buses
	for i in range(1, NUM_BUSES):
		var bus_idx = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, bus_names[i])
		AudioServer.set_bus_send(bus_idx, "Master")
		
		match bus_names[i]:
			"Cathedral_Reverb":
				var cathedral_reverb = AudioEffectReverb.new()
				cathedral_reverb.room_size = 1.0
				cathedral_reverb.damping = 0.05
				cathedral_reverb.wet = 0.7
				cathedral_reverb.dry = 0.4
				AudioServer.add_bus_effect(bus_idx, cathedral_reverb)
			"Choir_Hall":
				var choir_reverb = AudioEffectReverb.new()
				choir_reverb.room_size = 0.9
				choir_reverb.damping = 0.2
				choir_reverb.wet = 0.5
				AudioServer.add_bus_effect(bus_idx, choir_reverb)
			"Strings_Chamber":
				var chamber_reverb = AudioEffectReverb.new()
				chamber_reverb.room_size = 0.6
				chamber_reverb.damping = 0.3
				chamber_reverb.wet = 0.4
				AudioServer.add_bus_effect(bus_idx, chamber_reverb)
			"Organ_Pipes":
				var organ_reverb = AudioEffectReverb.new()
				organ_reverb.room_size = 0.95
				organ_reverb.damping = 0.1
				organ_reverb.wet = 0.6
				var lowpass = AudioEffectLowPassFilter.new()
				lowpass.cutoff_hz = 8000
				AudioServer.add_bus_effect(bus_idx, organ_reverb)
				AudioServer.add_bus_effect(bus_idx, lowpass)
			"Dark_Industrial":
				var dark_reverb = AudioEffectReverb.new()
				dark_reverb.room_size = 0.8
				dark_reverb.damping = 0.6
				dark_reverb.wet = 0.3
				var distortion = AudioEffectDistortion.new()
				distortion.mode = AudioEffectDistortion.MODE_OVERDRIVE
				distortion.drive = 0.3
				AudioServer.add_bus_effect(bus_idx, dark_reverb)
				AudioServer.add_bus_effect(bus_idx, distortion)

func setup_liturgical_players():
	# Main choral drone player
	choral_drone_player = AudioStreamPlayer.new()
	choral_drone_player.bus = "Choir_Hall"
	choral_drone_player.volume_db = -8
	add_child(choral_drone_player)
	
	# Organ foundation player
	organ_foundation_player = AudioStreamPlayer.new()
	organ_foundation_player.bus = "Organ_Pipes"
	organ_foundation_player.volume_db = -12
	add_child(organ_foundation_player)
	
	# String ensemble player
	string_ensemble_player = AudioStreamPlayer.new()
	string_ensemble_player.bus = "Strings_Chamber"
	string_ensemble_player.volume_db = -10
	add_child(string_ensemble_player)
	
	# Sacred effect players
	for i in range(num_effect_players):
		var player = AudioStreamPlayer.new()
		player.volume_db = -15
		
		# Distribute across sacred buses
		match i % 4:
			0: player.bus = "Cathedral_Reverb"
			1: player.bus = "Choir_Hall"
			2: player.bus = "Strings_Chamber"
			3: player.bus = "Dark_Industrial"
		
		add_child(player)
		effect_players.append(player)

func start_sacred_ambient():
	# Begin the sacred foundations
	choral_drone_player.stream = precreated_sounds["choral_foundation"]
	choral_drone_player.play()
	
	organ_foundation_player.stream = precreated_sounds["organ_foundation"]
	organ_foundation_player.play()
	
	string_ensemble_player.stream = precreated_sounds["string_atmosphere"]
	string_ensemble_player.play()

func trigger_sacred_event():
	_ensure_rng()
	if stop_requested:
		return
	# Check if we're still in the scene tree
	if not is_inside_tree():
		return
	
	# Find available sacred player
	var available_players = []
	for player in effect_players:
		if player != null and is_instance_valid(player) and not player.playing:
			available_players.append(player)
	
	if available_players.size() > 0:
		var player = available_players[_randi() % available_players.size()]
		if player == null or not is_instance_valid(player):
			return
			
		var sound_type = sacred_sound_types[_randi() % sacred_sound_types.size()]
		var variation_index = _randi() % precreated_sounds[sound_type].size()
		var stream = precreated_sounds[sound_type][variation_index]
		
		player.stream = stream
		player.volume_db = -18 + (spiritual_intensity * 8)
		player.play()

# Sacred Sound Generators

func create_choral_foundation():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 45.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	# Modal harmony - Dorian mode frequencies
	var dorian_ratios = [1.0, 9.0/8.0, 32.0/27.0, 4.0/3.0, 3.0/2.0, 27.0/16.0, 16.0/9.0, 2.0]
	var base_freq = 73.42
	
	# Virtual choir voices
	var voice_frequencies = []
	for i in range(choral_voices):
		var octave_shift = rng.randi_range(0, 3)
		var modal_degree = rng.randi() % dorian_ratios.size()
		var freq = base_freq * dorian_ratios[modal_degree] * pow(2, octave_shift)
		voice_frequencies.append(freq)
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		# Generate choral texture
		for j in range(voice_frequencies.size()):
			var voice_freq = voice_frequencies[j]
			var voice_volume = 0.8 / choral_voices
			
			var vibrato = 1.0 + 0.02 * sin(2.0 * PI * (4.5 + j * 0.1) * t)
			var breathing = 0.9 + 0.1 * sin(2.0 * PI * (0.08 + j * 0.01) * t)
			
			var voice = 0.0
			voice += sin(2.0 * PI * voice_freq * vibrato * t) * 0.6
			voice += sin(2.0 * PI * voice_freq * 2.0 * vibrato * t) * 0.3
			voice += sin(2.0 * PI * voice_freq * 3.0 * vibrato * t) * 0.1
			
			sample += voice * voice_volume * breathing
		
		var global_swell = 0.7 + 0.3 * sin(2.0 * PI * 0.03 * t)
		sample *= global_swell
		
		sample = sample + sample * 0.1 * sin(2.0 * PI * 800 * t) * 0.1
		sample = clamp(sample * 0.6, -1.0, 1.0)
		
		var left = sample * (1.0 + 0.05 * sin(2.0 * PI * 0.07 * t))
		var right = sample * (1.0 - 0.05 * sin(2.0 * PI * 0.07 * t))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	return stream

func create_organ_foundation():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 60.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var fundamental = 32.7
	var pipe_harmonics = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]
	var harmonic_volumes = [0.8, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		for j in range(pipe_harmonics.size()):
			var freq = fundamental * pipe_harmonics[j]
			var volume = harmonic_volumes[j]
			
			var tremulant = 1.0 + 0.03 * sin(2.0 * PI * 5.8 * t)
			var wind_variation = 1.0 + 0.001 * sin(2.0 * PI * 0.2 * t)
			
			sample += sin(2.0 * PI * freq * wind_variation * t) * volume * tremulant
		
		var middle_c = fundamental * 8
		sample += sin(2.0 * PI * middle_c * t) * 0.15
		sample += sin(2.0 * PI * middle_c * 2 * t) * 0.08
		
		sample += rng.randf_range(-0.02, 0.02)
		
		var registration_swell = 0.8 + 0.2 * sin(2.0 * PI * 0.01 * t)
		sample *= registration_swell
		
		sample = clamp(sample * 0.4, -1.0, 1.0)
		
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	return stream

func create_string_atmosphere():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 40.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var string_frequencies = [146.83, 196.00, 293.66, 440.00, 659.25]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		for j in range(string_frequencies.size()):
			var freq = string_frequencies[j]
			var volume = 0.15 / string_frequencies.size()
			
			var vibrato = 1.0 + 0.008 * sin(2.0 * PI * (6.2 + j * 0.3) * t)
			var expression = 0.8 + 0.2 * sin(2.0 * PI * 0.05 * t + j)
			
			var string_sound = 0.0
			string_sound += sin(2.0 * PI * freq * vibrato * t) * 0.7
			string_sound += sin(2.0 * PI * freq * 2.0 * vibrato * t) * 0.2
			string_sound += sin(2.0 * PI * freq * 3.0 * vibrato * t) * 0.1
			
			string_sound += rng.randf_range(-0.05, 0.05) * 0.3
			
			sample += string_sound * volume * expression
		
		var ensemble_swell = 0.7 + 0.3 * sin(2.0 * PI * 0.02 * t)
		sample *= ensemble_swell
		
		sample = clamp(sample, -1.0, 1.0)
		
		var left = sample * (1.0 + 0.1 * sin(2.0 * PI * 0.03 * t))
		var right = sample * (1.0 - 0.1 * sin(2.0 * PI * 0.03 * t))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	return stream

func create_gregorian_phrase():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 12.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var phrase_notes = [146.83, 164.81, 174.61, 196.00, 220.00, 246.94, 261.63, 293.66]
	var note_durations = [1.5, 2.0, 1.0, 2.5, 1.8, 2.2, 3.0, 2.0]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		var accumulated_time = 0.0
		var current_note_freq = phrase_notes[0]
		
		for j in range(phrase_notes.size()):
			if t >= accumulated_time and t < accumulated_time + note_durations[j]:
				current_note_freq = phrase_notes[j]
				break
			accumulated_time += note_durations[j]
		
		var vibrato = 1.0 + 0.01 * sin(2.0 * PI * 5.0 * t)
		sample = sin(2.0 * PI * current_note_freq * vibrato * t) * 0.3
		sample += sin(2.0 * PI * current_note_freq * 2.0 * vibrato * t) * 0.1
		
		var phrase_envelope = 0.5 + 0.5 * sin(2.0 * PI * 0.08 * t)
		sample *= phrase_envelope
		
		sample = clamp(sample, -1.0, 1.0)
		
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)
	
	stream.data = data
	return stream

func create_cathedral_bell():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 15.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var fundamental = 220.0
	var bell_partials = [1.0, 2.4, 3.56, 4.07, 5.0, 5.93, 7.0, 8.14]
	var partial_volumes = [1.0, 0.4, 0.3, 0.25, 0.2, 0.15, 0.1, 0.08]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		for j in range(bell_partials.size()):
			var freq = fundamental * bell_partials[j]
			var volume = partial_volumes[j]
			
			var decay_rate = 0.3 + j * 0.1
			var envelope = exp(-t * decay_rate)
			var beating = 1.0 + 0.02 * sin(2.0 * PI * (j * 0.3) * t)
			
			sample += sin(2.0 * PI * freq * t) * volume * envelope * beating
		
		if t < 0.1:
			var strike_envelope = exp(-t * 30.0)
			var strike_noise = rng.randf_range(-1.0, 1.0) * strike_envelope * 0.3
			sample += strike_noise
		
		sample = clamp(sample * 0.6, -1.0, 1.0)
		
		var delay_time = 0.8
		var delayed_sample = sample
		if t > delay_time:
			delayed_sample = sample + sample * 0.2
		
		var left = delayed_sample
		var right = delayed_sample * 0.9
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_pipe_organ_swell():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 20.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var chord_frequencies = [73.42, 98.00, 146.83, 196.00, 293.66, 392.00]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		var swell_envelope = 0.0
		var attack_time = 8.0
		var sustain_time = 6.0
		var release_time = 6.0
		
		if t < attack_time:
			swell_envelope = (t / attack_time) * (t / attack_time)
		elif t < attack_time + sustain_time:
			swell_envelope = 1.0
		else:
			var release_phase = (t - attack_time - sustain_time) / release_time
			swell_envelope = 1.0 - (release_phase * release_phase)
		
		for j in range(chord_frequencies.size()):
			var freq = chord_frequencies[j]
			var pipe_volume = 0.8 / chord_frequencies.size()
			
			var wind_variation = 1.0 + 0.003 * sin(2.0 * PI * 0.15 * t)
			var tremulant = 1.0 + 0.02 * sin(2.0 * PI * 6.0 * t)
			
			var pipe_sound = 0.0
			pipe_sound += sin(2.0 * PI * freq * wind_variation * t) * 0.8
			pipe_sound += sin(2.0 * PI * freq * 2.0 * wind_variation * t) * 0.4
			pipe_sound += sin(2.0 * PI * freq * 3.0 * wind_variation * t) * 0.2
			pipe_sound += sin(2.0 * PI * freq * 4.0 * wind_variation * t) * 0.1
			
			sample += pipe_sound * pipe_volume * tremulant
		
		sample *= swell_envelope
		
		if t > 4.0 and t < 12.0:
			var mixture_freq = 587.33
			var mixture_volume = (swell_envelope - 0.5) * 0.3
			if mixture_volume > 0:
				sample += sin(2.0 * PI * mixture_freq * t) * mixture_volume
		
		sample = clamp(sample * 0.5, -1.0, 1.0)
		
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)
	
	stream.data = data
	return stream

func create_sacred_whisper():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 8.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		var whisper_noise = rng.randf_range(-1.0, 1.0)
		
		var formant1 = 800.0
		var formant2 = 1200.0
		
		var resonance1 = sin(2.0 * PI * formant1 * t) * 0.3
		var resonance2 = sin(2.0 * PI * formant2 * t) * 0.2
		
		sample = whisper_noise * (0.5 + resonance1 + resonance2) * 0.2
		
		var breath_envelope = 0.3 + 0.7 * sin(2.0 * PI * 0.2 * t)
		sample *= breath_envelope
		
		sample += sin(2.0 * PI * 440.0 * t) * 0.02
		
		sample = clamp(sample, -1.0, 1.0)
		
		var pan = sin(2.0 * PI * 0.1 * t) * 0.7
		var left = sample * (1.0 - max(0, pan))
		var right = sample * (1.0 + min(0, pan))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_hymnal_fragment():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 10.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var hymn_notes = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
	var note_pattern = [0, 2, 4, 3, 5, 4, 2, 0]
	var beats_per_note = 1.0
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		var beat = int(t / beats_per_note) % note_pattern.size()
		var current_freq = hymn_notes[note_pattern[beat]]
		
		var vibrato = 1.0 + 0.005 * sin(2.0 * PI * 4.5 * t)
		sample = sin(2.0 * PI * current_freq * vibrato * t) * 0.4
		
		var harmony_freq = current_freq * 5.0/4.0
		sample += sin(2.0 * PI * harmony_freq * vibrato * t) * 0.3
		
		var phrase_envelope = 0.7 + 0.3 * sin(2.0 * PI * 0.1 * t)
		sample *= phrase_envelope
		
		sample = clamp(sample, -1.0, 1.0)
		
		var frame_value = int(sample * 32767.0)
		data.encode_s16(i * 4, frame_value)
		data.encode_s16(i * 4 + 2, frame_value)
	
	stream.data = data
	return stream

func create_divine_breath():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 12.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		var wind_base = rng.randf_range(-1.0, 1.0) * 0.1
		
		sample += sin(2.0 * PI * 60.0 * t) * 0.2
		sample += sin(2.0 * PI * 90.0 * t) * 0.15
		sample += sin(2.0 * PI * 120.0 * t) * 0.1
		
		var wind_swell = sin(2.0 * PI * 0.08 * t) * 0.5 + 0.5
		sample = (sample + wind_base) * wind_swell
		
		sample += sin(2.0 * PI * 1760.0 * t) * 0.03 * wind_swell
		
		sample = clamp(sample * 0.6, -1.0, 1.0)
		
		var left = sample * (1.0 + 0.2 * sin(2.0 * PI * 0.05 * t))
		var right = sample * (1.0 - 0.2 * sin(2.0 * PI * 0.05 * t))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_prophetic_thunder():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 18.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		sample += sin(2.0 * PI * 40.0 * t) * 0.4
		sample += sin(2.0 * PI * 60.0 * t) * 0.3
		sample += sin(2.0 * PI * 80.0 * t) * 0.2
		
		var rumble_noise = rng.randf_range(-1.0, 1.0) * 0.3
		sample += rumble_noise
		
		var envelope = 0.0
		envelope += exp(-(t - 3.0) * (t - 3.0) * 0.5) * 0.8
		envelope += exp(-(t - 8.0) * (t - 8.0) * 0.3) * 1.0
		envelope += exp(-(t - 13.0) * (t - 13.0) * 0.8) * 0.6
		
		sample *= envelope
		
		if t > 7.5 and t < 8.5:
			var crack_noise = rng.randf_range(-1.0, 1.0) * exp(-(t - 8.0) * (t - 8.0) * 50.0)
			sample += crack_noise * 0.8
		
		sample = clamp(sample * 0.7, -1.0, 1.0)
		
		var thunder_pan = sin(2.0 * PI * 0.02 * t)
		var left = sample * (1.0 - max(0, thunder_pan * 0.3))
		var right = sample * (1.0 + min(0, thunder_pan * 0.3))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

func create_angelic_texture():
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	
	var buffer_length = 14.0
	var frame_count = int(sample_rate * buffer_length)
	var data = PackedByteArray()
	data.resize(frame_count * 4)
	
	var angelic_frequencies = [1760.0, 2217.46, 2637.02, 3136.0, 3520.0]
	
	for i in range(frame_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		for j in range(angelic_frequencies.size()):
			var freq = angelic_frequencies[j]
			var volume = 0.2 / angelic_frequencies.size()
			
			var shimmer = 1.0 + 0.003 * sin(2.0 * PI * (3.0 + j * 0.2) * t)
			
			var phase_offset = j * PI / 3.0
			sample += sin(2.0 * PI * freq * shimmer * t + phase_offset) * volume
		
		var angelic_envelope = 0.0
		var attack = 3.0
		var release = 4.0
		
		if t < attack:
			angelic_envelope = (t / attack) * (t / attack) * (3.0 - 2.0 * t / attack)
		elif t > buffer_length - release:
			var release_phase = (buffer_length - t) / release
			angelic_envelope = release_phase * release_phase * (3.0 - 2.0 * release_phase)
		else:
			angelic_envelope = 1.0
		
		sample *= angelic_envelope
		
		sample += sin(2.0 * PI * 4186.0 * t) * 0.05 * angelic_envelope
		
		sample = clamp(sample * 0.5, -1.0, 1.0)
		
		var left = sample * (1.0 + 0.1 * sin(2.0 * PI * 0.07 * t))
		var right = sample * (1.0 - 0.1 * sin(2.0 * PI * 0.07 * t))
		
		var left_value = int(left * 32767.0)
		var right_value = int(right * 32767.0)
		data.encode_s16(i * 4, left_value)
		data.encode_s16(i * 4 + 2, right_value)
	
	stream.data = data
	return stream

# Event handlers
func _on_sacred_generation_started():
	print("Sacred sound generation has begun...")

func _on_divine_sound_created(sound_name: String):
	print("Divine sound created: " + sound_name.replace("_", " ").capitalize())

func _on_liturgical_progress_updated(progress: float):
	var percentage = int(progress * 100)
	print("Sacred generation progress: " + str(percentage) + "%")

func _on_sacred_generation_complete():
	print("Sacred sound generation complete. Entering divine presence...")
	start_sacred_ambient()
	is_initialized = true
	is_generating = false
	print("The liturgical atmosphere now surrounds you...")
