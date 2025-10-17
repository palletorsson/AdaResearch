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

# Critical band data (Bark scale)
var critical_bands := [
	20, 100, 200, 300, 400, 510, 630, 770, 920, 1080,
	1270, 1480, 1720, 2000, 2320, 2700, 3150, 3700, 4400, 5300,
	6400, 7700, 9500, 12000, 15500
]

func _ready():
	pass

func _process(delta):
	time += delta
	masking_timer += delta
	
	update_masking_parameters()
	visualize_frequency_masking()
	visualize_temporal_masking()
	show_critical_bands()
	demonstrate_loudness_perception()

func update_masking_parameters():
	# Animate psychoacoustic parameters
	masker_frequency = 800 + sin(time * 0.3) * 400
	masker_amplitude = 0.6 + cos(time * 0.4) * 0.3
	probe_frequency = masker_frequency + 200 + sin(time * 0.7) * 300
	probe_amplitude = 0.2 + sin(time * 0.9) * 0.2

func visualize_frequency_masking():
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

func visualize_temporal_masking():
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

func show_critical_bands():
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

func demonstrate_loudness_perception():
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

func show_a_weighting_filter(container: Node3D):
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
