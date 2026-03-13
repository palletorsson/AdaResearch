extends Node3D

# Psychoacoustics Visualization
# Demonstrates perception-based audio design principles

var time := 0.0
var masking_timer := 0.0

# Psychoacoustic parameters
var masker_frequency := 1000.0
var masker_amplitude := 0.8
var probe_frequency := 1200.0
var probe_amplitude := 0.3

# Audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var audio_masker_freq := 800.0
var audio_masker_level := 0.6
var audio_probe_offset := 200.0
var audio_probe_level := 0.3
var audio_noise_amount := 0.1
var audio_binaural_offset := 3.0
var audio_probe_interval := 0.6
var audio_probe_duration := 0.12
var audio_probe_cycle := 0.0
var audio_probe_envelope := 0.0
var audio_probe_attack_step := 0.01
var audio_probe_release_step := 0.005
var audio_mod_depth := 0.3
var audio_mod_rate := 0.4
var audio_pad_phase := 0.0
var masker_phase := 0.0
var probe_phase_left := 0.0
var probe_phase_right := 0.0
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := ""
var theme_cycle_duration := 18.0
var theme_timer := 0.0
var current_theme_profile := {}
var theme_profiles := {
	"queer": {
		"masker_freq": 380.0,
		"masker_amp": 0.55,
		"probe_offset": 180.0,
		"probe_amp": 0.38,
		"noise": 0.12,
		"binaural_offset": 4.5,
		"probe_interval": 0.7,
		"probe_duration": 0.18,
		"mod_depth": 0.35,
		"mod_rate": 0.5,
		"attack": 0.01,
		"release": 0.04,
		"sparkle": 0.32
	},
	"sci_fi": {
		"masker_freq": 720.0,
		"masker_amp": 0.48,
		"probe_offset": 280.0,
		"probe_amp": 0.3,
		"noise": 0.08,
		"binaural_offset": 6.0,
		"probe_interval": 0.9,
		"probe_duration": 0.12,
		"mod_depth": 0.5,
		"mod_rate": 0.65,
		"attack": 0.008,
		"release": 0.03,
		"sparkle": 0.4
	},
	"cyberpunk": {
		"masker_freq": 220.0,
		"masker_amp": 0.7,
		"probe_offset": 120.0,
		"probe_amp": 0.35,
		"noise": 0.18,
		"binaural_offset": 2.0,
		"probe_interval": 0.5,
		"probe_duration": 0.1,
		"mod_depth": 0.45,
		"mod_rate": 0.3,
		"attack": 0.006,
		"release": 0.035,
		"sparkle": 0.25
	},
	"epic": {
		"masker_freq": 540.0,
		"masker_amp": 0.6,
		"probe_offset": 210.0,
		"probe_amp": 0.32,
		"noise": 0.1,
		"binaural_offset": 3.5,
		"probe_interval": 0.8,
		"probe_duration": 0.16,
		"mod_depth": 0.38,
		"mod_rate": 0.45,
		"attack": 0.009,
		"release": 0.04,
		"sparkle": 0.33
	}
}

# Critical band data (Bark scale)
var critical_bands := [
	20, 100, 200, 300, 400, 510, 630, 770, 920, 1080,
	1270, 1480, 1720, 2000, 2320, 2700, 3150, 3700, 4400, 5300,
	6400, 7700, 9500, 12000, 15500
]

func _ready() -> void:
	randomize()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func _process(delta: float) -> void:
	time += delta
	masking_timer += delta
	
	update_masking_parameters()
	visualize_frequency_masking()
	visualize_temporal_masking()
	show_critical_bands()
	demonstrate_loudness_perception()
	update_theme_cycle(delta)
	generate_audio_samples()

func update_masking_parameters() -> void:
	# Animate psychoacoustic parameters
	if current_theme_profile.is_empty():
		masker_frequency = 800 + sin(time * 0.3) * 400
		masker_amplitude = 0.6 + cos(time * 0.4) * 0.3
		probe_frequency = masker_frequency + 200 + sin(time * 0.7) * 300
		probe_amplitude = 0.2 + sin(time * 0.9) * 0.2
		return

	var profile: Dictionary = current_theme_profile
	audio_masker_freq = profile.get("masker_freq", audio_masker_freq)
	audio_masker_level = profile.get("masker_amp", audio_masker_level)
	audio_probe_offset = profile.get("probe_offset", audio_probe_offset)
	audio_probe_level = profile.get("probe_amp", audio_probe_level)
	audio_noise_amount = profile.get("noise", audio_noise_amount)
	audio_binaural_offset = profile.get("binaural_offset", audio_binaural_offset)
	audio_probe_interval = profile.get("probe_interval", audio_probe_interval)
	audio_probe_duration = profile.get("probe_duration", audio_probe_duration)
	audio_mod_depth = profile.get("mod_depth", audio_mod_depth)
	audio_mod_rate = profile.get("mod_rate", audio_mod_rate)
	var attack_seconds = max(0.001, profile.get("attack", 0.01))
	var release_seconds = max(0.001, profile.get("release", 0.04))
	audio_probe_attack_step = 1.0 / max(1.0, attack_seconds * sample_rate)
	audio_probe_release_step = 1.0 / max(1.0, release_seconds * sample_rate)

	masker_frequency = audio_masker_freq + sin(time * audio_mod_rate) * audio_masker_freq * 0.15
	masker_amplitude = clamp(audio_masker_level, 0.05, 1.0)
	probe_frequency = masker_frequency + audio_probe_offset + sin(time * 0.6) * audio_probe_offset * 0.2
	probe_amplitude = clamp(audio_probe_level, 0.05, 1.0)

func visualize_frequency_masking() -> void:
	var container = $FrequencyMasking
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show frequency spectrum with masking
	var num_frequencies = 24
	
	for i in range(num_frequencies):
		var frequency = 200.0 * pow(2, float(i) / 4.0)  # Logarithmic scale
		var distance_from_masker = abs(log(frequency) - log(masker_frequency))
		
		# Calculate masking threshold
		var masking_threshold = calculate_masking_threshold(frequency, masker_frequency, masker_amplitude)
		
		# Frequency component
		var freq_bar = CSGBox3D.new()
		var amplitude = 0.5
		
		# Apply masking effect
		if amplitude < masking_threshold:
			amplitude = 0.1  # Masked
		
		freq_bar.size = Vector3(0.3, amplitude * 4, 0.3)
		freq_bar.position = Vector3(i * 0.4 - num_frequencies * 0.2, amplitude * 2, 0)
		
		var material = StandardMaterial3D.new()
		
		if abs(frequency - masker_frequency) < 50:
			# Masker frequency
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.8
		elif amplitude <= 0.1:
			# Masked frequency
			material.albedo_color = Color(0.3, 0.3, 0.3)
		else:
			# Audible frequency
			material.albedo_color = Color(0.2, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.2, 1.0, 0.2) * 0.4
		
		freq_bar.material_override = material
		container.add_child(freq_bar)
		
		# Masking threshold curve
		var threshold_marker = CSGSphere3D.new()
		threshold_marker.radius = 0.05
		threshold_marker.position = Vector3(i * 0.4 - num_frequencies * 0.2, masking_threshold * 4, 0.5)
		
		var threshold_material = StandardMaterial3D.new()
		threshold_material.albedo_color = Color(1.0, 1.0, 0.0)
		threshold_material.emission_enabled = true
		threshold_material.emission = Color(1.0, 1.0, 0.0) * 0.6
		threshold_marker.material_override = threshold_material
		
		container.add_child(threshold_marker)

func calculate_masking_threshold(probe_freq: float, masker_freq: float, masker_amp: float) -> float:
	# Simplified frequency masking calculation
	var frequency_ratio = probe_freq / masker_freq
	var bark_distance = frequency_to_bark(probe_freq) - frequency_to_bark(masker_freq)
	
	# Masking function (simplified)
	var masking_level = masker_amp * exp(-abs(bark_distance) * 0.5)
	
	return masking_level

func frequency_to_bark(frequency: float) -> float:
	# Convert frequency to Bark scale
	return 13.0 * atan(0.00076 * frequency) + 3.5 * atan(pow(frequency / 7500.0, 2))

func visualize_temporal_masking() -> void:
	var container = $TemporalMasking
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show temporal masking effect
	var time_samples = 32
	var masker_time = 0.5  # Masker occurs at t=0.5
	
	for i in range(time_samples):
		var t = float(i) / time_samples
		var time_offset = t - masker_time
		
		# Calculate temporal masking
		var pre_masking = 0.0
		var post_masking = 0.0
		
		if time_offset < 0:
			# Pre-masking (backward masking)
			pre_masking = masker_amplitude * exp(time_offset * 10) if time_offset > -0.1 else 0.0
		else:
			# Post-masking (forward masking)
			post_masking = masker_amplitude * exp(-time_offset * 5) if time_offset < 0.2 else 0.0
		
		var masking_level = max(pre_masking, post_masking)
		
		# Time sample visualization
		var time_bar = CSGBox3D.new()
		var signal_amplitude = 0.3
		
		# Show masker at masker_time
		if abs(time_offset) < 0.02:
			signal_amplitude = masker_amplitude
		
		# Apply temporal masking
		var effective_amplitude = signal_amplitude
		if signal_amplitude < masking_level:
			effective_amplitude = 0.05  # Masked
		
		time_bar.size = Vector3(0.2, effective_amplitude * 3, 0.2)
		time_bar.position = Vector3(t * 8 - 4, effective_amplitude * 1.5, 0)
		
		var material = StandardMaterial3D.new()
		
		if abs(time_offset) < 0.02:
			# Masker signal
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.8
		elif effective_amplitude <= 0.05:
			# Masked signal
			material.albedo_color = Color(0.3, 0.3, 0.3)
		else:
			# Audible signal
			material.albedo_color = Color(0.2, 1.0, 0.2)
		
		time_bar.material_override = material
		container.add_child(time_bar)
		
		# Masking threshold curve
		if masking_level > 0.01:
			var threshold_curve = CSGSphere3D.new()
			threshold_curve.radius = 0.03
			threshold_curve.position = Vector3(t * 8 - 4, masking_level * 3, 0.3)
			
			var curve_material = StandardMaterial3D.new()
			curve_material.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
			curve_material.flags_transparent = true
			threshold_curve.material_override = curve_material
			
			container.add_child(threshold_curve)

func show_critical_bands() -> void:
	var container = $CriticalBands
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize critical bands (Bark scale)
	for i in range(critical_bands.size() - 1):
		var band_start = critical_bands[i]
		var band_end = critical_bands[i + 1]
		var band_center = (band_start + band_end) / 2.0
		var band_width = band_end - band_start
		
		# Critical band visualization
		var band_box = CSGBox3D.new()
		band_box.size = Vector3(0.8, 2.0, 0.4)
		band_box.position = Vector3(i * 0.9 - critical_bands.size() * 0.45, 1.0, 0)
		
		var material = StandardMaterial3D.new()
		var band_hue = float(i) / critical_bands.size()
		material.albedo_color = Color.from_hsv(band_hue, 0.6, 0.9, 0.7)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color.from_hsv(band_hue, 0.6, 0.9) * 0.3
		band_box.material_override = material
		
		container.add_child(band_box)
		
		# Band frequency label (height represents frequency)
		var freq_indicator = CSGCylinder3D.new()
		freq_indicator.radius = 0.1
		
		freq_indicator.height = log(band_center) * 0.3
		freq_indicator.position = Vector3(i * 0.9 - critical_bands.size() * 0.45, freq_indicator.height * 0.5 + 2.5, 0)
		
		var freq_material = StandardMaterial3D.new()
		freq_material.albedo_color = Color(1.0, 0.5, 0.0)
		freq_indicator.material_override = freq_material
		
		container.add_child(freq_indicator)
		
		# Show overlapping between adjacent bands
		if i > 0:
			var overlap = CSGSphere3D.new()
			overlap.radius = 0.15
			overlap.position = Vector3(i * 0.9 - critical_bands.size() * 0.45 - 0.45, 1.0, 0.5)
			
			var overlap_material = StandardMaterial3D.new()
			overlap_material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
			overlap_material.flags_transparent = true
			overlap_material.emission_enabled = true
			overlap_material.emission = Color(1.0, 1.0, 1.0) * 0.4
			overlap.material_override = overlap_material
			
			container.add_child(overlap)

func demonstrate_loudness_perception() -> void:
	var container = $LoudnessPerception
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show equal-loudness contours (Fletcher-Munson curves)
	var frequencies = [100, 200, 400, 800, 1000, 2000, 4000, 8000]
	var loudness_levels = [20, 40, 60, 80]  # Phons
	
	for level_idx in range(loudness_levels.size()):
		var phon_level = loudness_levels[level_idx]
		
		for freq_idx in range(frequencies.size()):
			var frequency = frequencies[freq_idx]
			var spl_required = calculate_equal_loudness_spl(frequency, phon_level)
			
			# Loudness contour point
			var loudness_sphere = CSGSphere3D.new()
			loudness_sphere.radius = 0.15
			loudness_sphere.position = Vector3(
				freq_idx * 1.0 - frequencies.size() * 0.5,
				spl_required * 0.05,
				level_idx * 0.8 - loudness_levels.size() * 0.4
			)
			
			var material = StandardMaterial3D.new()
			var level_color = float(level_idx) / loudness_levels.size()
			material.albedo_color = Color.from_hsv(level_color * 0.8, 0.8, 1.0)
			material.emission_enabled = true
			material.emission = Color.from_hsv(level_color * 0.8, 0.8, 1.0) * 0.5
			loudness_sphere.material_override = material
			
			container.add_child(loudness_sphere)
			
			# Connect points in same contour
			if freq_idx > 0:
				var prev_sphere = container.get_child(container.get_child_count() - 2)
				var connection = create_contour_connection(prev_sphere.position, loudness_sphere.position)
				container.add_child(connection)
	
	# Show A-weighting filter response
	show_a_weighting_filter(container)

func calculate_equal_loudness_spl(frequency: float, phon_level: float) -> float:
	# Simplified equal-loudness calculation based on ISO 226:2003
	var f = frequency
	var Ln = phon_level
	
	# Reference frequency (1 kHz)
	if abs(f - 1000.0) < 50.0:
		return Ln
	
	# Simplified approximation
	var low_freq_boost = 0.0
	if f < 1000.0:
		low_freq_boost = 20.0 * log(1000.0 / f) / log(10.0)
	
	var high_freq_reduction = 0.0
	if f > 4000.0:
		high_freq_reduction = -10.0 * log(f / 4000.0) / log(10.0)
	
	return Ln + low_freq_boost + high_freq_reduction

func show_a_weighting_filter(container: Node3D) -> void:
	# Show A-weighting frequency response
	var filter_frequencies = [63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
	var a_weighting_values = [-26.2, -16.1, -8.6, -3.2, 0.0, 1.2, 1.0, -1.1, -6.6]
	
	for i in range(filter_frequencies.size()):
		var weighting_db = a_weighting_values[i]
		
		var filter_bar = CSGBox3D.new()
		filter_bar.size = Vector3(0.2, abs(weighting_db) * 0.1 + 0.1, 0.2)
		filter_bar.position = Vector3(
			i * 0.8 - filter_frequencies.size() * 0.4,
			weighting_db * 0.05,
			2.5
		)
		
		var material = StandardMaterial3D.new()
		if weighting_db < 0:
			material.albedo_color = Color(1.0, 0.3, 0.3)  # Attenuation
		else:
			material.albedo_color = Color(0.3, 1.0, 0.3)  # Boost
		
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.4
		filter_bar.material_override = material
		
		container.add_child(filter_bar)

func create_contour_connection(from: Vector3, to: Vector3) -> CSGCylinder3D:
	var connection = CSGCylinder3D.new()
	connection.radius = 0.02
	
	connection.height = from.distance_to(to)
	
	connection.position = (from + to) * 0.5
	connection.look_at_from_position(connection.position, to, Vector3.UP)
	connection.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8, 0.6)
	material.flags_transparent = true
	connection.material_override = material
	
	return connection

func setup_audio_synthesis() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -5.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()
	reset_audio_state()

func ensure_playback() -> bool:
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

func reset_audio_state() -> void:
	audio_probe_cycle = 0.0
	audio_probe_envelope = 0.0
	masker_phase = 0.0
	probe_phase_left = 0.0
	probe_phase_right = 0.0
	audio_pad_phase = 0.0

func apply_theme_profile(theme_name: String) -> void:
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	update_masking_parameters()
	reset_audio_state()
	theme_timer = 0.0
	print("Psychoacoustics: activated %s theme" % theme_name)

func update_theme_cycle(delta: float) -> void:
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme() -> void:
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func generate_audio_samples() -> void:
	if not audio_player or not audio_player.playing:
		return
	if current_theme_profile.is_empty():
		return
	if not ensure_playback():
		return

	var available = audio_playback.get_frames_available()
	if available < audio_buffer_size:
		return

	var frames = min(audio_buffer_size, available)
	var sparkle = current_theme_profile.get("sparkle", 0.3)

	for _i in range(frames):
		audio_probe_cycle += 1.0 / sample_rate
		if audio_probe_cycle >= audio_probe_interval:
			audio_probe_cycle -= audio_probe_interval
		var gated = 1.0 if audio_probe_cycle < audio_probe_duration else 0.0
		if gated > 0.0:
			audio_probe_envelope = min(1.0, audio_probe_envelope + audio_probe_attack_step)
		else:
			audio_probe_envelope = max(0.0, audio_probe_envelope - audio_probe_release_step)

		var mod_factor = 1.0 + sin(audio_pad_phase) * audio_mod_depth
		audio_pad_phase = wrapf(audio_pad_phase + audio_mod_rate * TAU / sample_rate, 0.0, TAU)

		masker_phase = wrapf(masker_phase + audio_masker_freq * mod_factor * TAU / sample_rate, 0.0, TAU)
		var masker_sample = sin(masker_phase) * audio_masker_level

		probe_phase_left = wrapf(probe_phase_left + (audio_masker_freq + audio_probe_offset) * TAU / sample_rate, 0.0, TAU)
		probe_phase_right = wrapf(probe_phase_right + (audio_masker_freq + audio_probe_offset + audio_binaural_offset) * TAU / sample_rate, 0.0, TAU)
		var probe_env = audio_probe_envelope * audio_probe_level
		var probe_left = sin(probe_phase_left) * probe_env
		var probe_right = sin(probe_phase_right) * probe_env

		var shimmer = sin(masker_phase * 2.0 + time * 1.5) * sparkle * 0.1
		var noise = randf_range(-1.0, 1.0) * audio_noise_amount * 0.35
		var left = clamp(masker_sample + probe_left + shimmer + noise, -1.0, 1.0)
		var right = clamp(masker_sample + probe_right - shimmer + noise, -1.0, 1.0)
		audio_playback.push_frame(Vector2(left, right))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

