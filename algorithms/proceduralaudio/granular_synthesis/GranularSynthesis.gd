# @identity
# essence: output(t) = sum(grain(t_i, size, pitch, envelope)) -- thousands of micro-fragments into texture
# desire: a cloud of sonic particles -- each grain too short to hear alone, together forming atmosphere
# critical_parameter: grain_density / grain_size -- how many overlap and how long each lives; scatter randomizes
# triggers: theme profiles reshape density, pitch, scatter, pan spread; grains spawn continuously
# emerges: texture without waveform -- statistical accumulation produces sound no oscillator generates
# needs: AudioStreamGenerator [has]; per-grain envelope and phase [has]; pad synthesis layer [has]; VR controls [missing]
# relationships: micro-counterpart to additive (grains vs harmonics); parallels particle systems
# truth: enough fragments of a thing become the thing -- or something it never was. Identity through multiplicity.

extends Node3D

# Granular Synthesis Visualization
# Demonstrates micro-sound manipulation and grain-based audio synthesis

var time := 0.0
var grain_timer := 0.0
var synthesis_timer := 0.0

# Granular synthesis parameters
var grain_size := 0.1  # Duration in seconds
var grain_density := 10.0  # Grains per second
var grain_pitch := 1.0  # Pitch multiplier
var grain_position := 0.0  # Position in source material
var grain_scatter := 0.05  # Random variation

# Visual representation
var active_grains := []
var waveform_data := []
var output_buffer := []

# Audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var audio_grains := []
var audio_grain_accumulator := 0.0
var audio_waveform := PackedFloat32Array()
var audio_master_gain := 0.6
var audio_noise_amount := 0.05
var audio_pad_phase := 0.0
var audio_pad_frequency := 110.0
var audio_grain_density := 12.0
var audio_grain_size := 0.08
var audio_grain_pitch := 1.0
var audio_grain_scatter := 0.03
var audio_grain_position := 0.0
var audio_grain_pan_spread := 0.3
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := ""
var theme_cycle_duration := 16.0
var theme_timer := 0.0
var current_theme_profile := {}
var theme_profiles := {
	"queer": {
		"grain_size": 0.085,
		"density": 18.0,
		"pitch": 1.15,
		"scatter": 0.045,
		"position": 0.2,
		"pan_spread": 0.4,
		"gain": 0.65,
		"noise": 0.06,
		"pad_freq": 160.0,
		"pad_mix": 0.18,
		"sparkle": 0.35
	},
	"sci_fi": {
		"grain_size": 0.06,
		"density": 24.0,
		"pitch": 1.35,
		"scatter": 0.06,
		"position": 0.45,
		"pan_spread": 0.3,
		"gain": 0.55,
		"noise": 0.08,
		"pad_freq": 220.0,
		"pad_mix": 0.22,
		"sparkle": 0.45
	},
	"cyberpunk": {
		"grain_size": 0.05,
		"density": 28.0,
		"pitch": 0.85,
		"scatter": 0.075,
		"position": 0.65,
		"pan_spread": 0.5,
		"gain": 0.7,
		"noise": 0.12,
		"pad_freq": 95.0,
		"pad_mix": 0.15,
		"sparkle": 0.25
	},
	"epic": {
		"grain_size": 0.09,
		"density": 16.0,
		"pitch": 1.05,
		"scatter": 0.05,
		"position": 0.35,
		"pan_spread": 0.35,
		"gain": 0.68,
		"noise": 0.05,
		"pad_freq": 140.0,
		"pad_mix": 0.2,
		"sparkle": 0.4
	}
}

# Grain structure
class Grain:
	var position: Vector3
	var size: float
	var pitch: float
	var age: float
	var lifetime: float
	var amplitude: float
	var source_position: float

func _ready() -> void:
	randomize()
	initialize_waveform_data()
	initialize_synthesis_parameters()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func _process(delta: float) -> void:
	time += delta
	grain_timer += delta
	synthesis_timer += delta
	
	update_grain_parameters()
	spawn_new_grains(delta)
	animate_existing_grains(delta)
	visualize_waveform_source()
	show_granular_parameters()
	demonstrate_output_synthesis()
	update_theme_cycle(delta)
	generate_audio_samples()

func initialize_waveform_data() -> void:
	# Create sample waveform data
	waveform_data.clear()
	for i in range(200):
		var t = float(i) / 200.0
		var sample = sin(t * TAU * 3) + sin(t * TAU * 7) * 0.5 + sin(t * TAU * 11) * 0.25
		waveform_data.append(sample)

func initialize_synthesis_parameters() -> void:
	grain_size = 0.08
	grain_density = 12.0
	grain_pitch = 1.0
	grain_position = 0.0
	grain_scatter = 0.03

func update_grain_parameters() -> void:
	# Animate parameters over time
	grain_size = 0.05 + sin(time * 0.5) * 0.03
	grain_density = 8.0 + cos(time * 0.7) * 4.0
	grain_pitch = 0.8 + sin(time * 0.3) * 0.4
	grain_position = fmod(time * 0.1, 1.0)
	grain_scatter = 0.02 + sin(time * 1.2) * 0.01

func spawn_new_grains(delta: float) -> void:
	# Calculate grain spawn rate
	var spawn_rate = grain_density * delta
	var grains_to_spawn = int(spawn_rate)
	
	# Handle fractional spawning
	if randf() < (spawn_rate - grains_to_spawn):
		grains_to_spawn += 1
	
	# Spawn new grains
	for i in range(grains_to_spawn):
		spawn_grain()

func spawn_grain() -> void:
	var grain = Grain.new()
	
	# Random position in grain cluster
	grain.position = Vector3(
		randf_range(-4, 4),
		randf_range(-2, 2),
		randf_range(-2, 2)
	)
	
	# Grain properties
	grain.size = grain_size * (1.0 + randf_range(-0.3, 0.3))
	grain.pitch = grain_pitch * (1.0 + randf_range(-grain_scatter, grain_scatter))
	grain.lifetime = grain.size
	grain.age = 0.0
	grain.amplitude = randf_range(0.5, 1.0)
	
	# Source position with scatter
	grain.source_position = grain_position + randf_range(-grain_scatter, grain_scatter)
	grain.source_position = fmod(grain.source_position + 1.0, 1.0)  # Wrap around
	
	active_grains.append(grain)

func animate_existing_grains(delta: float) -> void:
	var container = $GrainCluster
	
	# Clear previous grain visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update and visualize active grains
	var i = 0
	while i < active_grains.size():
		var grain = active_grains[i]
		grain.age += delta
		
		if grain.age >= grain.lifetime:
			# Remove expired grain
			active_grains.remove_at(i)
			continue
		
		# Update grain position (movement)
		grain.position.y += delta * 2.0  # Rise upward
		
		# Create visual representation
		var grain_sphere = CSGSphere3D.new()
		var life_ratio = grain.age / grain.lifetime
		var envelope = sin(life_ratio * PI)  # Bell curve envelope
		
		grain_sphere.radius = grain.size * envelope * 2.0
		grain_sphere.position = grain.position
		
		var material = StandardMaterial3D.new()
		# Color based on pitch and amplitude
		var pitch_ratio = (grain.pitch - 0.4) / 0.8  # Normalize pitch range
		material.albedo_color = Color(
			pitch_ratio,
			grain.amplitude,
			1.0 - pitch_ratio,
			envelope * 0.8
		)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		grain_sphere.material_override = material
		
		container.add_child(grain_sphere)
		
		i += 1

func visualize_waveform_source() -> void:
	var container = $WaveformSource
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create waveform visualization
	for i in range(waveform_data.size() - 1):
		var t1 = float(i) / waveform_data.size()
		var t2 = float(i + 1) / waveform_data.size()
		
		var pos1 = Vector3(
			(t1 - 0.5) * 10,
			waveform_data[i] * 2,
			0
		)
		var pos2 = Vector3(
			(t2 - 0.5) * 10,
			waveform_data[i + 1] * 2,
			0
		)
		
		# Create waveform segment
		var segment = CSGCylinder3D.new()
		segment.radius = 0.05
		
		segment.height = pos1.distance_to(pos2)
		
		segment.position = (pos1 + pos2) * 0.5
		segment.look_at_from_position(segment.position, pos2, Vector3.UP)
		segment.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var material = StandardMaterial3D.new()
		
		# Highlight current grain position
		var pos_diff = abs(t1 - grain_position)
		if pos_diff < grain_size or pos_diff > (1.0 - grain_size):
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.6
		else:
			material.albedo_color = Color(0.3, 0.7, 1.0)
		
		segment.material_override = material
		container.add_child(segment)
	
	# Show grain reading position
	var read_head = CSGSphere3D.new()
	read_head.radius = 0.2
	read_head.position = Vector3(
		(grain_position - 0.5) * 10,
		sin(time * 8) * 0.3,
		1.0
	)
	
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(1.0, 1.0, 0.0)
	head_material.emission_enabled = true
	head_material.emission = Color(1.0, 1.0, 0.0) * 0.8
	read_head.material_override = head_material
	
	container.add_child(read_head)

func show_granular_parameters() -> void:
	var container = $GrainParameters
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize parameters as bars
	var parameters = [
		["Size", grain_size * 20],
		["Density", grain_density / 16.0],
		["Pitch", grain_pitch],
		["Scatter", grain_scatter * 50]
	]
	
	for i in range(parameters.size()):
		var param_name = parameters[i][0]
		var param_value = parameters[i][1]
		
		# Parameter bar
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.8, param_value * 3, 0.8)
		bar.position = Vector3(i * 1.2 - parameters.size() * 0.6, param_value * 1.5, 0)
		
		var material = StandardMaterial3D.new()
		var color_hue = float(i) / parameters.size()
		material.albedo_color = Color.from_hsv(color_hue, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(color_hue, 0.8, 1.0) * 0.3
		material.metallic = 0.3
		material.roughness = 0.4
		bar.material_override = material
		
		container.add_child(bar)
		
		# Parameter label (small cube)
		var label = CSGBox3D.new()
		label.size = Vector3(0.3, 0.3, 0.3)
		label.position = Vector3(i * 1.2 - parameters.size() * 0.6, -1, 0)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label.material_override = label_material
		
		container.add_child(label)

func demonstrate_output_synthesis() -> void:
	var container = $OutputSynthesis
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Simulate output buffer
	update_output_buffer()
	
	# Visualize output waveform
	for i in range(output_buffer.size() - 1):
		var t1 = float(i) / output_buffer.size()
		var t2 = float(i + 1) / output_buffer.size()
		
		var pos1 = Vector3(
			(t1 - 0.5) * 8,
			output_buffer[i] * 3,
			0
		)
		var pos2 = Vector3(
			(t2 - 0.5) * 8,
			output_buffer[i + 1] * 3,
			0
		)
		
		# Create output waveform segment
		var segment = CSGCylinder3D.new()
		segment.radius = 0.08
		
		segment.height = pos1.distance_to(pos2)
		
		segment.position = (pos1 + pos2) * 0.5
		segment.look_at_from_position(segment.position, pos2, Vector3.UP)
		segment.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var material = StandardMaterial3D.new()
		var amplitude = abs(output_buffer[i])
		material.albedo_color = Color(0.2 + amplitude, 1.0, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.2 + amplitude, 1.0, 0.2) * 0.4
		segment.material_override = material
		
		container.add_child(segment)
	
	# Show grain contributions
	var grain_contributions = CSGSphere3D.new()
	grain_contributions.radius = max(0.1, float(active_grains.size()) * 0.05)
	grain_contributions.position = Vector3(0, 4, 0)
	
	var contrib_material = StandardMaterial3D.new()
	contrib_material.albedo_color = Color(1.0, 0.5, 0.0)
	contrib_material.emission_enabled = true
	contrib_material.emission = Color(1.0, 0.5, 0.0) * 0.6
	grain_contributions.material_override = contrib_material
	
	container.add_child(grain_contributions)

func update_output_buffer() -> void:
	# Simulate granular synthesis output
	output_buffer.clear()
	
	for i in range(100):
		var sample = 0.0
		var t = float(i) / 100.0
		
		# Sum contributions from all active grains
		for grain in active_grains:
			var grain_phase = grain.age / grain.lifetime
			if grain_phase < 1.0:
				# Apply grain envelope
				var envelope = sin(grain_phase * PI)
				
				# Sample from source material
				var source_index = int(grain.source_position * waveform_data.size()) % waveform_data.size()
				var source_sample = waveform_data[source_index]
				
				# Apply pitch and amplitude
				var grain_contribution = source_sample * envelope * grain.amplitude * 0.1
				sample += grain_contribution
		
		# Add some movement to the output
		sample += sin(time * 4 + t * TAU * 2) * 0.1
		
		output_buffer.append(sample)

func setup_audio_synthesis() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -4.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()
	audio_waveform = PackedFloat32Array()
	var max_amp := 0.001
	for sample in waveform_data:
		max_amp = max(max_amp, abs(sample))
	for sample in waveform_data:
		audio_waveform.append(sample / max_amp)
	reset_audio_state()

func ensure_playback() -> bool:
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

func reset_audio_state() -> void:
	audio_grains.clear()
	audio_grain_accumulator = 0.0
	audio_pad_phase = 0.0

func apply_theme_profile(theme_name: String) -> void:
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	audio_grain_size = current_theme_profile.get("grain_size", audio_grain_size)
	audio_grain_density = current_theme_profile.get("density", audio_grain_density)
	audio_grain_pitch = current_theme_profile.get("pitch", audio_grain_pitch)
	audio_grain_scatter = current_theme_profile.get("scatter", audio_grain_scatter)
	audio_grain_position = current_theme_profile.get("position", audio_grain_position)
	audio_grain_pan_spread = current_theme_profile.get("pan_spread", audio_grain_pan_spread)
	audio_master_gain = current_theme_profile.get("gain", audio_master_gain)
	audio_noise_amount = current_theme_profile.get("noise", audio_noise_amount)
	audio_pad_frequency = current_theme_profile.get("pad_freq", audio_pad_frequency)
	grain_size = audio_grain_size
	grain_density = audio_grain_density
	grain_pitch = audio_grain_pitch
	grain_scatter = audio_grain_scatter
	grain_position = audio_grain_position
	theme_timer = 0.0
	reset_audio_state()
	print("GranularSynthesis: activated %s theme" % theme_name)

func update_theme_cycle(delta: float) -> void:
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme() -> void:
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func spawn_audio_grain_audio() -> void:
	if audio_waveform.is_empty():
		return

	var duration_samples = max(16, int(audio_grain_size * sample_rate))
	var base_pos = fposmod(audio_grain_position + randf_range(-audio_grain_scatter, audio_grain_scatter), 1.0)
	var start_index = base_pos * float(audio_waveform.size() - 1)
	var pitch = audio_grain_pitch * (1.0 + randf_range(-audio_grain_scatter, audio_grain_scatter))
	var increment = max(0.001, pitch * float(audio_waveform.size()) / float(duration_samples))
	var grain = {
		"position": start_index,
		"increment": increment,
		"duration": duration_samples,
		"age": 0,
		"amplitude": randf_range(0.5, 1.0),
		"pan": clamp(randf_range(-audio_grain_pan_spread, audio_grain_pan_spread), -1.0, 1.0)
	}
	audio_grains.append(grain)

func get_waveform_sample(index: float) -> float:
	if audio_waveform.is_empty():
		return 0.0
	var size = audio_waveform.size()
	var wrapped = fposmod(index, size)
	var i0 = int(wrapped)
	var i1 = (i0 + 1) % size
	var frac = wrapped - float(i0)
	return lerp(audio_waveform[i0], audio_waveform[i1], frac)

func generate_audio_samples() -> void:
	if not audio_player or not audio_player.playing:
		return
	if current_theme_profile.is_empty():
		return
	if not ensure_playback():
		return
	if audio_waveform.is_empty():
		return

	var available = audio_playback.get_frames_available()
	if available < audio_buffer_size:
		return

	var frames = min(audio_buffer_size, available)
	var sparkle = current_theme_profile.get("sparkle", 0.3)

	for _i in range(frames):
		audio_grain_accumulator += audio_grain_density / sample_rate
		while audio_grain_accumulator >= 1.0:
			spawn_audio_grain_audio()
			audio_grain_accumulator -= 1.0
		var left = 0.0
		var right = 0.0
		var g = 0
		while g < audio_grains.size():
			var grain = audio_grains[g]
			var env_phase = float(grain.age) / float(grain.duration)
			var envelope = sin(env_phase * PI)
			var sample = get_waveform_sample(grain.position) * envelope * grain.amplitude
			left += sample * (1.0 - grain.pan * 0.5)
			right += sample * (1.0 + grain.pan * 0.5)
			grain.position += grain.increment
			grain.age += 1
			if grain.age >= grain.duration:
				audio_grains.remove_at(g)
				continue
			audio_grains[g] = grain
			g += 1

		audio_pad_phase = wrapf(audio_pad_phase + audio_pad_frequency * TAU / sample_rate, 0.0, TAU)
		var pad = sin(audio_pad_phase) * current_theme_profile.get("pad_mix", 0.18)
		var shimmer = sin(audio_pad_phase * 2.0 + time * 2.5) * sparkle * 0.1
		var noise = randf_range(-1.0, 1.0) * audio_noise_amount * 0.3
		var left_sample = clamp((left + pad + shimmer + noise) * audio_master_gain, -1.0, 1.0)
		var right_sample = clamp((right + pad - shimmer + noise) * audio_master_gain, -1.0, 1.0)
		audio_playback.push_frame(Vector2(left_sample, right_sample))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
