extends Node3D

# Endless Techno-Noir Ambient Generator (Non-Blocking Version)
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
var num_effect_players = 5

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

# Threading and progress tracking
var generation_thread: Thread
var mutex: Mutex
var generation_progress = 0.0
var current_sound_name = ""
var total_sounds = 0
var sounds_completed = 0
var is_generating = false
var generation_complete = false

# Time tracking
var elapsed_time = 0.0
var last_effect_time = 0.0

var playback_started = false
var base_sounds_ready = {
	"drone": false,
	"city_ambience": false
}
var visualizer_root: Node3D
var visualizer_infos: Array = []
var stop_requested = false

# 3D Loading Bar Components
var loading_bar_container: Node3D
var loading_bar_fill: MeshInstance3D
var loading_text: Label3D
var progress_text: Label3D
var loading_particles: Array = []

# Signals
signal sound_generation_started
signal sound_created(sound_name: String)
signal generation_progress_updated(progress: float)
signal sound_generation_complete

func _ready():
	rng.randomize()
	mutex = Mutex.new()
	generation_thread = Thread.new()
	
	# Calculate total sounds to generate
	total_sounds = 2 + (sound_types.size() * 3)  # 2 base sounds + 3 variations per effect
	
	setup_audio_buses()
	setup_players()
	setup_visualizers()
	create_3d_loading_bar()
	add_to_group("audio_emitters")
	stop_requested = false
	
	# Connect signals
	sound_generation_started.connect(_on_generation_started)
	sound_created.connect(_on_sound_created)
	generation_progress_updated.connect(_on_progress_updated)
	sound_generation_complete.connect(_on_generation_complete)
	
	# Start generation in background thread
	start_sound_generation()

func _process(delta):
	if stop_requested:
		return
	if not generation_complete:
		animate_loading_bar(delta)
	update_visualizers(delta)
	
	if not playback_started:
		return
	
	elapsed_time += delta
	
	if elapsed_time - last_effect_time > rng.randf_range(3.0, 15.0):
		play_random_effect()
		last_effect_time = elapsed_time

func start_sound_generation():
	is_generating = true
	sound_generation_started.emit()
	
	# Start generation in background thread
	if generation_thread.start(_thread_generate_sounds) != OK:
		print("Failed to start generation thread")
		return

func _thread_generate_sounds():
	if stop_requested:
		return
	# Thread-safe sound generation
	mutex.lock()
	current_sound_name = "drone"
	mutex.unlock()
	
	# Generate base drone
	var drone_stream = create_endless_drone()
	mutex.lock()
	precreated_sounds["drone"] = drone_stream
	sounds_completed += 1
	generation_progress = float(sounds_completed) / total_sounds
	mutex.unlock()
	
	call_deferred("_emit_sound_created", "drone")
	call_deferred("_emit_progress_updated")
	
	# Small delay to allow UI update
	OS.delay_msec(100)
	if stop_requested:
		return
	# Generate city ambience
	mutex.lock()
	current_sound_name = "city_ambience"
	mutex.unlock()
	
	var ambience_stream = create_city_ambience()
	mutex.lock()
	precreated_sounds["city_ambience"] = ambience_stream
	sounds_completed += 1
	generation_progress = float(sounds_completed) / total_sounds
	mutex.unlock()
	
	call_deferred("_emit_sound_created", "city_ambience")
	call_deferred("_emit_progress_updated")
	
	OS.delay_msec(100)
	if stop_requested:
		return
	# Generate effect sound variations
	for sound_type in sound_types:
		if stop_requested:
			return
		mutex.lock()
		current_sound_name = sound_type
		precreated_sounds[sound_type] = []
		mutex.unlock()
		
		# Create 3 variations of each sound type
		for i in range(3):
			if stop_requested:
				return
			var stream = null
			
			match sound_type:
				"distant_siren": stream = create_distant_siren()
				"static_burst": stream = create_static_burst()
				"rain_segment": stream = create_rain_segment()
				"mechanical_whir": stream = create_mechanical_whir()
				"typing_segment": stream = create_typing_segment()
				"electric_hum": stream = create_electric_hum()
				"heartbeat_segment": stream = create_heartbeat_segment()
			
			mutex.lock()
			precreated_sounds[sound_type].append(stream)
			sounds_completed += 1
			generation_progress = float(sounds_completed) / total_sounds
			mutex.unlock()
			
			# Only emit signal for the first variation to avoid spam
			if i == 0:
				call_deferred("_emit_sound_created", sound_type)
			call_deferred("_emit_progress_updated")
			
			# Small delay between variations
			OS.delay_msec(50)
	
	# Generation complete
	mutex.lock()
	generation_complete = true
	mutex.unlock()
	
	call_deferred("_emit_generation_complete")

func _emit_sound_created(sound_name: String):
	sound_created.emit(sound_name)

func _emit_progress_updated():
	mutex.lock()
	var progress = generation_progress
	mutex.unlock()
	generation_progress_updated.emit(progress)

func _emit_generation_complete():
	sound_generation_complete.emit()

func create_3d_loading_bar():
	# Create container for loading bar
	loading_bar_container = Node3D.new()
	loading_bar_container.name = "LoadingBarContainer"
	add_child(loading_bar_container)
	
	# Create loading bar background
	var bar_bg = MeshInstance3D.new()
	bar_bg.name = "LoadingBarBackground"
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(8.0, 0.5, 0.8)
	bar_bg.mesh = bg_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.1, 0.1, 0.15, 0.8)
	bg_material.emission_enabled = true
	bg_material.emission = Color(0.0, 0.1, 0.2) * 0.3
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bar_bg.material_override = bg_material
	
	loading_bar_container.add_child(bar_bg)
	
	# Create loading bar fill
	loading_bar_fill = MeshInstance3D.new()
	loading_bar_fill.name = "LoadingBarFill"
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(0.1, 0.4, 0.7)  # Start very small
	loading_bar_fill.mesh = fill_mesh
	
	var fill_material = StandardMaterial3D.new()
	fill_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	fill_material.emission_enabled = true
	fill_material.emission = Color(0.2, 0.8, 1.0) * 0.8
	fill_material.metallic = 0.3
	fill_material.roughness = 0.1
	loading_bar_fill.material_override = fill_material
	
	# Position fill at left edge
	loading_bar_fill.position = Vector3(-3.95, 0, 0)
	loading_bar_container.add_child(loading_bar_fill)
	
	# Create main loading text
	loading_text = Label3D.new()
	loading_text.text = "Generating Ambient Soundscape..."
	loading_text.font_size = 48
	loading_text.position = Vector3(0, 1.5, 0)
	loading_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	loading_text.modulate = Color(0.8, 1.0, 1.0, 1.0)
	loading_bar_container.add_child(loading_text)
	
	# Create progress text
	progress_text = Label3D.new()
	progress_text.text = "Initializing..."
	progress_text.font_size = 32
	progress_text.position = Vector3(0, -1.2, 0)
	progress_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	progress_text.modulate = Color(0.6, 0.9, 1.0, 1.0)
	loading_bar_container.add_child(progress_text)
	
	# Create loading particles
	create_loading_particles()
	
	# Position the entire loading bar at a good viewing position
	loading_bar_container.position = Vector3(0, 2, -5)

func create_loading_particles():
	# Create floating particles around the loading bar
	for i in range(20):
		var particle = MeshInstance3D.new()
		particle.name = "LoadingParticle_" + str(i)
		
		var particle_mesh = SphereMesh.new()
		particle_mesh.radius = 0.05 + randf() * 0.03
		particle_mesh.height = particle_mesh.radius * 2
		particle.mesh = particle_mesh
		
		var particle_material = StandardMaterial3D.new()
		var hue = randf()
		particle_material.albedo_color = Color.from_hsv(hue, 0.7, 1.0, 0.8)
		particle_material.emission_enabled = true
		particle_material.emission = Color.from_hsv(hue, 0.7, 1.0) * 0.6
		particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particle.material_override = particle_material
		
		# Random position around loading bar
		var angle = randf() * PI * 2
		var radius = 5 + randf() * 3
		var height = randf_range(-2, 2)
		particle.position = Vector3(
			cos(angle) * radius,
			height,
			sin(angle) * radius
		)
		
		loading_bar_container.add_child(particle)
		loading_particles.append({
			"node": particle,
			"base_pos": particle.position,
			"float_speed": randf_range(0.5, 1.5),
			"float_amplitude": randf_range(0.3, 0.8),
			"rotation_speed": randf_range(1.0, 3.0)
		})

func animate_loading_bar(delta):
	if not loading_bar_container:
		return
	
	# Use unix time for smooth sub-second precision
	var t = fmod(Time.get_unix_time_from_system(), 60.0)
	
	# Animate loading bar glow
	if loading_bar_fill and loading_bar_fill.material_override:
		var pulse = 0.8 + sin(t * 4.0) * 0.3
		loading_bar_fill.material_override.emission = Color(0.2, 0.8, 1.0) * pulse
	
	# Animate particles
	for particle_data in loading_particles:
		var particle = particle_data["node"]
		var base_pos = particle_data["base_pos"]
		var float_speed = particle_data["float_speed"]
		var float_amplitude = particle_data["float_amplitude"]
		var rotation_speed = particle_data["rotation_speed"]
		
		# Floating motion
		var float_offset = sin(t * float_speed) * float_amplitude
		particle.position = base_pos + Vector3(0, float_offset, 0)
		
		# Rotation
		particle.rotation_degrees.y += rotation_speed * delta * 60
		
		# Pulse the emission
		if particle.material_override:
			var pulse = 0.6 + sin(t * 3.0 + particle.position.x) * 0.4
			var base_color = particle.material_override.albedo_color
			particle.material_override.emission = Color(base_color.r, base_color.g, base_color.b) * pulse
	
	# Rotate entire loading bar container slowly
	loading_bar_container.rotation_degrees.y += delta * 5

func _on_generation_started():
	print("Sound generation started...")

func _on_sound_created(sound_name: String):
	print("Created: " + sound_name)
	_maybe_start_stream(sound_name)
	if progress_text:
		progress_text.text = "Created: " + sound_name.replace("_", " ").capitalize()

func _on_progress_updated(progress: float):
	# Update loading bar fill
	if loading_bar_fill:
		var new_width = lerp(0.1, 7.9, progress)
		loading_bar_fill.mesh.size.x = new_width
		loading_bar_fill.position.x = -3.95 + (new_width - 0.1) * 0.5
		
		# Update color based on progress
		var color = Color.from_hsv(progress * 0.3, 0.8, 1.0)  # Red to green transition
		loading_bar_fill.material_override.albedo_color = color
		loading_bar_fill.material_override.emission = color * 0.8
	
	# Update loading text
	if loading_text:
		var percentage = int(progress * 100)
		loading_text.text = "Generating Sounds... " + str(percentage) + "%"

func _on_generation_complete():
	print("Sound generation complete!")
	
	# Hide loading bar with fade effect
	if loading_bar_container:
		var tween = create_tween()
		tween.tween_property(loading_bar_container, "modulate:a", 0.0, 1.0)
		tween.tween_callback(loading_bar_container.queue_free)
	
	# Start ambient sounds
	if not playback_started:
		start_ambient()
		base_sounds_ready["drone"] = true
		base_sounds_ready["city_ambience"] = true
		_try_start_playback()
	is_generating = false

func _try_start_playback():
	if base_sounds_ready["drone"] and base_sounds_ready["city_ambience"] and not playback_started:
		playback_started = true
		elapsed_time = 0.0
		last_effect_time = 0.0
		play_random_effect()

func _ensure_player_stream(player: AudioStreamPlayer, stream: AudioStream):
	if player == null or stream == null:
		return
	if player.stream != stream:
		player.stream = stream
	if not player.playing:
		player.play()

func _maybe_start_stream(sound_name: String):
	if sound_name == "drone" and precreated_sounds.has("drone"):
		_ensure_player_stream(drone_player, precreated_sounds["drone"])
		base_sounds_ready["drone"] = true
		_try_start_playback()
		return
	if sound_name == "city_ambience" and precreated_sounds.has("city_ambience"):
		_ensure_player_stream(ambient_player, precreated_sounds["city_ambience"])
		base_sounds_ready["city_ambience"] = true
		_try_start_playback()
		return
	if precreated_sounds.has(sound_name) and precreated_sounds[sound_name] is Array:
		_play_effect_immediately(sound_name)

func _play_effect_immediately(sound_name: String):
	var available_players = []
	for player in effect_players:
		if not player.playing:
			available_players.append(player)
	if available_players.size() == 0:
		return
	var variations = precreated_sounds.get(sound_name, [])
	if typeof(variations) != TYPE_ARRAY:
		return
	if variations.size() == 0:
		return
	var player = available_players[rng.randi() % available_players.size()]
	var stream = variations[rng.randi() % variations.size()]
	player.stream = stream
	player.volume_db = -15 - rng.randf_range(0, 10)
	player.play()
	last_effect_time = elapsed_time

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

func setup_visualizers():
	# Rebuild small transparent spheres for each audio source.
	if visualizer_root:
		visualizer_root.queue_free()
	visualizer_root = null
	visualizer_infos.clear()
	precreated_sounds.clear()
	precreated_sounds.clear()
	visualizer_root = Node3D.new()
	visualizer_root.name = "AudioVisualizerRoot"
	visualizer_root.position = Vector3.ZERO
	add_child(visualizer_root)
	
	if drone_player:
		add_visualizer_for_player(drone_player, Vector3(-1.5, 0.0, 0.0), Color(0.45, 0.15, 0.8, 0.6))
	if ambient_player:
		add_visualizer_for_player(ambient_player, Vector3(1.5, 0.0, 0.0), Color(0.1, 0.6, 0.95, 0.6))
	
	if effect_players.size() == 0:
		return
	
	var radius = 2.2
	for i in range(effect_players.size()):
		var angle = TAU * float(i) / max(1.0, float(effect_players.size()))
		var pos = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var hue = fposmod(0.55 + float(i) / max(1.0, float(effect_players.size())), 1.0)
		var color = Color.from_hsv(hue, 0.75, 1.0, 0.6)
		add_visualizer_for_player(effect_players[i], pos, color)

func add_visualizer_for_player(player: AudioStreamPlayer, position: Vector3, color: Color):
	if not player:
		return
	if visualizer_root == null:
		return
	var holder = Node3D.new()
	holder.position = position
	visualizer_root.add_child(holder)
	
	var base_radius = 0.45
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = base_radius
	mesh.height = base_radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, base_radius, 0)
	mesh_instance.scale = Vector3.ONE
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	material.emission_enabled = true
	material.emission = color * 1.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.25
	material.metallic = 0.05
	mesh_instance.material_override = material
	
	holder.add_child(mesh_instance)
	
	visualizer_infos.append({
		"player": player,
		"mesh": mesh_instance,
		"color": color,
		"radius": base_radius,
		"level": 0.0
	})

# Smooth amplitude-driven scaling to keep the floating orbs breathing.
func update_visualizers(delta):
	if visualizer_infos.size() == 0:
		return
	for i in range(visualizer_infos.size()):
		var info = visualizer_infos[i]
		var mesh: MeshInstance3D = info.get("mesh")
		var player: AudioStreamPlayer = info.get("player")
		if mesh == null:
			continue
		var amplitude = 0.0
		if player and player.playing and player.stream is AudioStreamWAV:
			amplitude = _get_stream_amplitude(player.stream, player.get_playback_position())
		var level = info.get("level", 0.0)
		level = lerp(level, amplitude, 0.15)
		var base_radius = info.get("radius", 0.45)
		var scale = 1.0 + level * 6.0
		mesh.scale = Vector3.ONE * scale
		mesh.position.y = base_radius * scale
		
		var base_color: Color = info.get("color", Color.WHITE)
		var emission_strength = 0.8 + level * 3.0
		if mesh.material_override:
			mesh.material_override.emission = base_color * emission_strength
			mesh.material_override.albedo_color = Color(base_color.r, base_color.g, base_color.b, clamp(0.35 + level * 0.4, 0.35, 0.9))
		
		info["level"] = level
		visualizer_infos[i] = info
func _get_stream_amplitude(stream: AudioStreamWAV, position: float, sample_window := 256) -> float:
	if stream == null:
		return 0.0
	var data = stream.data
	if data.is_empty():
		return 0.0
	var mix_rate = max(stream.mix_rate, 1)
	var frame_count = data.size() / 4
	if frame_count == 0:
		return 0.0
	var current_frame = int(position * mix_rate)
	if stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and frame_count > 0:
		current_frame = current_frame % frame_count
	else:
		current_frame = clamp(current_frame, 0, frame_count - 1)
	var max_samples = min(sample_window, frame_count)
	var sum = 0.0
	var samples = 0
	for i in range(max_samples):
		var frame_index = current_frame + i
		if stream.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			frame_index = (current_frame + i) % frame_count
		elif frame_index >= frame_count:
			break
		var offset = frame_index * 4
		if offset + 3 >= data.size():
			break
		var left = data.decode_s16(offset) / 32767.0
		var right = data.decode_s16(offset + 2) / 32767.0
		sum += (abs(left) + abs(right)) * 0.5
		samples += 1
	if samples == 0:
		return 0.0
	return sum / float(samples)

func start_ambient():
	# Start the continuous drone using pre-generated stream
	if precreated_sounds.has("drone"):
		_ensure_player_stream(drone_player, precreated_sounds["drone"])
	
	# Start city ambience using pre-generated stream
	if precreated_sounds.has("city_ambience"):
		_ensure_player_stream(ambient_player, precreated_sounds["city_ambience"])

func play_random_effect():
	if stop_requested:
		return
	# Find an available player
	var available_players = []
	for player in effect_players:
		if not player.playing:
			available_players.append(player)
	
	if available_players.size() == 0:
		return
	
	var ready_types = []
	for sound_type in sound_types:
		if precreated_sounds.has(sound_type) and precreated_sounds[sound_type] is Array and precreated_sounds[sound_type].size() > 0:
			ready_types.append(sound_type)
	
	if ready_types.size() == 0:
		return
	
	var player = available_players[rng.randi() % available_players.size()]
	var sound_type = ready_types[rng.randi() % ready_types.size()]
	var variations = precreated_sounds[sound_type]
	var stream = variations[rng.randi() % variations.size()]
	
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

func shutdown_audio():
	if stop_requested:
		return
	stop_requested = true
	playback_started = false
	is_generating = false
	if generation_thread and generation_thread.is_alive():
		generation_thread.wait_to_finish()
	generation_thread = null
	if drone_player:
		drone_player.stop()
	if ambient_player:
		ambient_player.stop()
	for player in effect_players:
		if player:
			player.stop()
	if loading_bar_container:
		loading_bar_container.queue_free()
		loading_bar_container = null
	if visualizer_root:
		visualizer_root.queue_free()
		visualizer_root = null
	visualizer_infos.clear()
