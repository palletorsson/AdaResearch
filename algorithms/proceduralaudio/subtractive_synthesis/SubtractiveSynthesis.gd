extends Node3D

var time = 0.0
var oscillator_nodes = []
var filter_nodes = []
var spectrum_nodes = []
var frequency_bands = 32
var filter_frequency = 1000.0
var filter_resonance = 0.5
var filter_timer = 0.0
var filter_interval = 3.0

# Filter types
enum FilterType {
	LOW_PASS,
	HIGH_PASS,
	BAND_PASS,
	NOTCH
}

var current_filter = FilterType.LOW_PASS

# Oscillator types
enum OscillatorType {
	SAWTOOTH,
	SQUARE,
	TRIANGLE,
	NOISE
}

var oscillator_count = 4

func _ready():
	create_oscillators()
	create_filter_stage()
	create_spectrum_display()
	setup_materials()

func create_oscillators():
	var osc_parent = $Oscillators
	
	for i in range(oscillator_count):
		var osc_group = Node3D.new()
		osc_parent.add_child(osc_group)
		
		# Create harmonics for each oscillator
		var harmonic_count = 8
		var osc_data = []
		
		for h in range(harmonic_count):
			var harmonic = CSGSphere3D.new()
			harmonic.radius = 0.1
			harmonic.position = Vector3(
				-6 + i * 3.0,
				2 - h * 0.3,
				0
			)
			osc_group.add_child(harmonic)
			osc_data.append(harmonic)
		
		oscillator_nodes.append(osc_data)

func create_filter_stage():
	var filter_parent = $FilterStage
	
	# Create filter visualization as a 3D surface
	var filter_width = 16
	var filter_height = 8
	
	for x in range(filter_width):
		filter_nodes.append([])
		for y in range(filter_height):
			var filter_node = CSGSphere3D.new()
			filter_node.radius = 0.06
			filter_node.position = Vector3(
				-6 + x * 0.75,
				0.5 - y * 0.15,
				-2
			)
			filter_parent.add_child(filter_node)
			filter_nodes[x].append(filter_node)

func create_spectrum_display():
	var spectrum_parent = $SpectrumOutput
	
	for i in range(frequency_bands):
		var band = CSGBox3D.new()
		band.size = Vector3(0.2, 0.1, 0.2)
		band.position = Vector3(
			-6 + i * 0.4,
			-1.5,
			2
		)
		spectrum_parent.add_child(band)
		spectrum_nodes.append(band)

func setup_materials():
	# Oscillator materials
	for i in range(oscillator_nodes.size()):
		var color_intensity = i / float(oscillator_count)
		var osc_material = StandardMaterial3D.new()
		osc_material.albedo_color = Color(
			1.0 - color_intensity * 0.5,
			0.3 + color_intensity * 0.7,
			0.3,
			1.0
		)
		osc_material.emission_enabled = true
		osc_material.emission = osc_material.albedo_color * 0.4
		
		for harmonic in oscillator_nodes[i]:
			harmonic.material_override = osc_material
	
	# Filter materials
	var filter_material = StandardMaterial3D.new()
	filter_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	filter_material.emission_enabled = true
	filter_material.emission = Color(0.05, 0.2, 0.3, 1.0)
	
	for row in filter_nodes:
		for node in row:
			node.material_override = filter_material
	
	# Spectrum materials
	var spectrum_material = StandardMaterial3D.new()
	spectrum_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	spectrum_material.emission_enabled = true
	spectrum_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	
	for band in spectrum_nodes:
		band.material_override = spectrum_material
	
	# Control materials
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FilterFrequency.material_override = freq_material
	
	var res_material = StandardMaterial3D.new()
	res_material.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
	res_material.emission_enabled = true
	res_material.emission = Color(0.1, 0.5, 0.1, 1.0)
	$FilterResonance.material_override = res_material
	
	var type_material = StandardMaterial3D.new()
	type_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	type_material.emission_enabled = true
	type_material.emission = Color(0.2, 0.05, 0.3, 1.0)
	$FilterType.material_override = type_material

func _process(delta):
	time += delta
	filter_timer += delta
	
	# Switch filter types
	if filter_timer >= filter_interval:
		filter_timer = 0.0
		current_filter = (current_filter + 1) % FilterType.size()
	
	# Update filter parameters
	filter_frequency = 500.0 + sin(time * 0.4) * 400.0
	filter_resonance = 0.3 + cos(time * 0.3) * 0.4
	
	animate_oscillators()
	animate_filter()
	animate_spectrum()
	animate_controls()

func animate_oscillators():
	# Animate each oscillator's harmonics
	for i in range(oscillator_nodes.size()):
		var osc_type = i % 4  # Cycle through oscillator types
		
		for h in range(oscillator_nodes[i].size()):
			var harmonic = oscillator_nodes[i][h]
			var harmonic_freq = (h + 1)  # Harmonic number
			
			# Calculate amplitude based on oscillator type and harmonic
			var amplitude = calculate_harmonic_amplitude(osc_type, harmonic_freq)
			
			# Animate based on amplitude and time
			var scale = 0.5 + amplitude * (1.0 + sin(time * harmonic_freq * 2.0) * 0.5)
			harmonic.scale = Vector3.ONE * scale
			
			# Update material emission
			var material = harmonic.material_override as StandardMaterial3D
			if material:
				material.emission = material.albedo_color * (0.2 + amplitude * 0.8)

func calculate_harmonic_amplitude(osc_type: int, harmonic: int) -> float:
	match osc_type:
		OscillatorType.SAWTOOTH:
			# Sawtooth: all harmonics, 1/n amplitude
			return 1.0 / harmonic
		
		OscillatorType.SQUARE:
			# Square: odd harmonics only, 1/n amplitude
			if harmonic % 2 == 1:
				return 1.0 / harmonic
			else:
				return 0.0
		
		OscillatorType.TRIANGLE:
			# Triangle: odd harmonics, 1/n² amplitude
			if harmonic % 2 == 1:
				return 1.0 / (harmonic * harmonic)
			else:
				return 0.0
		
		OscillatorType.NOISE:
			# Noise: random amplitudes
			return randf()
		
		_:
			return 0.0

func animate_filter():
	# Visualize filter response
	for x in range(filter_nodes.size()):
		for y in range(filter_nodes[x].size()):
			var node = filter_nodes[x][y]
			
			# Calculate frequency for this position
			var freq = (x / float(filter_nodes.size())) * 4000.0  # 0-4kHz range
			var amplitude_pos = y / float(filter_nodes[x].size())
			
			# Calculate filter response
			var response = calculate_filter_response(freq, amplitude_pos)
			
			# Animate based on response
			var scale = 0.3 + response * 1.5
			node.scale = Vector3.ONE * scale
			
			# Update color based on response
			var material = node.material_override as StandardMaterial3D
			if material:
				var intensity = response
				material.albedo_color = Color(
					0.2 + intensity * 0.8,
					0.8 - intensity * 0.4,
					1.0 - intensity * 0.5,
					1.0
				)
				material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func calculate_filter_response(frequency: float, amplitude_level: float) -> float:
	var normalized_freq = frequency / 2000.0  # Normalize to 0-2
	var cutoff = filter_frequency / 2000.0
	var q = filter_resonance * 10.0 + 0.5
	
	var response = 0.0
	
	match current_filter:
		FilterType.LOW_PASS:
			# Simple low-pass response
			if normalized_freq < cutoff:
				response = 1.0 - (normalized_freq / cutoff) * 0.7
			else:
				response = max(0.0, 1.0 - pow((normalized_freq - cutoff) * 2.0, 2.0))
			
			# Add resonance peak
			if abs(normalized_freq - cutoff) < 0.1:
				response += filter_resonance * 0.8
		
		FilterType.HIGH_PASS:
			# High-pass response
			if normalized_freq > cutoff:
				response = 0.3 + (normalized_freq - cutoff) * 0.7
			else:
				response = max(0.0, 0.3 - (cutoff - normalized_freq) * 2.0)
			
			# Add resonance peak
			if abs(normalized_freq - cutoff) < 0.1:
				response += filter_resonance * 0.8
		
		FilterType.BAND_PASS:
			# Band-pass response
			var distance_from_center = abs(normalized_freq - cutoff)
			var bandwidth = 0.2 + filter_resonance * 0.3
			
			if distance_from_center < bandwidth:
				response = 1.0 - (distance_from_center / bandwidth)
			else:
				response = 0.0
		
		FilterType.NOTCH:
			# Notch response (inverse of band-pass)
			var distance_from_center = abs(normalized_freq - cutoff)
			var bandwidth = 0.15 + filter_resonance * 0.2
			
			if distance_from_center < bandwidth:
				response = distance_from_center / bandwidth
			else:
				response = 1.0
	
	return clamp(response, 0.0, 1.0)

func animate_spectrum():
	# Animate output spectrum
	for i in range(spectrum_nodes.size()):
		var band = spectrum_nodes[i]
		var frequency = (i / float(frequency_bands)) * 4000.0
		
		# Calculate final amplitude after filtering
		var base_amplitude = 0.0
		
		# Sum contributions from all oscillators
		for osc_idx in range(oscillator_count):
			for harmonic in range(8):
				var harmonic_freq = 220.0 * (osc_idx + 1) * (harmonic + 1)  # Base frequency * harmonic
				
				if abs(harmonic_freq - frequency) < 100.0:  # If this harmonic affects this frequency band
					var osc_amplitude = calculate_harmonic_amplitude(osc_idx % 4, harmonic + 1)
					base_amplitude += osc_amplitude * 0.2
		
		# Apply filter
		var filter_response = calculate_filter_response(frequency, 0.5)
		var final_amplitude = base_amplitude * filter_response
		
		# Add some dynamics
		final_amplitude *= (1.0 + sin(time * 3.0 + i * 0.2) * 0.3)
		
		# Animate spectrum bar
		var height = 0.1 + final_amplitude * 2.0
		band.size.y = height
		band.position.y = -1.5 + height/2
		
		# Update color
		var material = band.material_override as StandardMaterial3D
		if material:
			var intensity = final_amplitude
			material.albedo_color = Color(
				1.0,
				0.8 - intensity * 0.4,
				0.2 + intensity * 0.6,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func animate_controls():
	# Filter frequency control
	var freq_height = (filter_frequency / 1000.0) * 1.5 + 0.5
	$FilterFrequency.height = freq_height
	$FilterFrequency.position.y = -3 + freq_height/2
	
	# Filter resonance control
	var res_height = filter_resonance * 1.5 + 0.5
	$FilterResonance.height = res_height
	$FilterResonance.position.y = -3 + res_height/2
	
	# Filter type indicator
	var type_height = (current_filter + 1) * 0.3 + 0.5
	$FilterType.height = type_height
	$FilterType.position.y = -3 + type_height/2
	
	# Update filter type color
	var type_material = $FilterType.material_override as StandardMaterial3D
	if type_material:
		match current_filter:
			FilterType.LOW_PASS:
				type_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
			FilterType.HIGH_PASS:
				type_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			FilterType.BAND_PASS:
				type_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			FilterType.NOTCH:
				type_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
		
		type_material.emission = type_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FilterFrequency.scale.x = pulse
	$FilterResonance.scale.x = pulse
	$FilterType.scale.x = pulse

func get_filter_name() -> String:
	match current_filter:
		FilterType.LOW_PASS:
			return "Low Pass"
		FilterType.HIGH_PASS:
			return "High Pass"
		FilterType.BAND_PASS:
			return "Band Pass"
		FilterType.NOTCH:
			return "Notch"
		_:
			return "Unknown"
