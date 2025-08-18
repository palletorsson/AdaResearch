extends Node3D

var time = 0.0
var harmonic_count = 16
var fundamental_freq = 220.0
var harmonic_oscillators = []
var summation_nodes = []
var output_waveform = []
var waveform_resolution = 64

func _ready():
	create_harmonic_oscillators()
	create_summation_stage()
	create_output_waveform()
	setup_materials()

func create_harmonic_oscillators():
	var osc_parent = $HarmonicOscillators
	
	for i in range(harmonic_count):
		var harmonic_group = Node3D.new()
		osc_parent.add_child(harmonic_group)
		
		# Oscillator sphere
		var oscillator = CSGSphere3D.new()
		oscillator.radius = 0.15
		oscillator.position = Vector3(
			-7 + i * 0.9,
			2,
			0
		)
		harmonic_group.add_child(oscillator)
		
		# Amplitude control
		var amplitude_control = CSGCylinder3D.new()
		amplitude_control.radius = 0.05
		
		amplitude_control.height = 1.0
		amplitude_control.position = Vector3(
			-7 + i * 0.9,
			1,
			0
		)
		harmonic_group.add_child(amplitude_control)
		
		# Frequency indicator
		var freq_indicator = CSGBox3D.new()
		freq_indicator.size = Vector3(0.1, 0.3, 0.1)
		freq_indicator.position = Vector3(
			-7 + i * 0.9,
			2.5,
			0
		)
		harmonic_group.add_child(freq_indicator)
		
		harmonic_oscillators.append({
			"oscillator": oscillator,
			"amplitude_control": amplitude_control,
			"freq_indicator": freq_indicator,
			"harmonic_number": i + 1,
			"amplitude": calculate_initial_amplitude(i + 1),
			"phase": 0.0
		})

func create_summation_stage():
	var sum_parent = $SummationStage
	
	# Create nodes showing the summation process
	for i in range(harmonic_count):
		var sum_node = CSGSphere3D.new()
		sum_node.radius = 0.08
		sum_node.position = Vector3(
			-7 + i * 0.9,
			0,
			0
		)
		sum_parent.add_child(sum_node)
		summation_nodes.append(sum_node)

func create_output_waveform():
	var wave_parent = $OutputWaveform
	
	for i in range(waveform_resolution):
		var wave_point = CSGSphere3D.new()
		wave_point.radius = 0.05
		wave_point.position = Vector3(
			-6 + i * 0.2,
			-2,
			0
		)
		wave_parent.add_child(wave_point)
		output_waveform.append(wave_point)

func calculate_initial_amplitude(harmonic_number: int) -> float:
	# Default to harmonic series (1/n)
	return 1.0 / harmonic_number

func setup_materials():
	# Harmonic oscillator materials
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		var color_intensity = i / float(harmonic_count)
		
		# Oscillator material
		var osc_material = StandardMaterial3D.new()
		osc_material.albedo_color = Color(
			1.0 - color_intensity * 0.5,
			0.3 + color_intensity * 0.7,
			0.8,
			1.0
		)
		osc_material.emission_enabled = true
		osc_material.emission = osc_material.albedo_color * 0.4
		harmonic.oscillator.material_override = osc_material
		
		# Amplitude control material
		var amp_material = StandardMaterial3D.new()
		amp_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
		amp_material.emission_enabled = true
		amp_material.emission = Color(0.3, 0.3, 0.1, 1.0)
		harmonic.amplitude_control.material_override = amp_material
		
		# Frequency indicator material
		var freq_material = StandardMaterial3D.new()
		freq_material.albedo_color = Color(1.0, 0.4, 0.2, 1.0)
		freq_material.emission_enabled = true
		freq_material.emission = Color(0.4, 0.1, 0.05, 1.0)
		harmonic.freq_indicator.material_override = freq_material
	
	# Summation node materials
	var sum_material = StandardMaterial3D.new()
	sum_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	sum_material.emission_enabled = true
	sum_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	
	for node in summation_nodes:
		node.material_override = sum_material
	
	# Output waveform materials
	var wave_material = StandardMaterial3D.new()
	wave_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	wave_material.emission_enabled = true
	wave_material.emission = Color(0.4, 0.3, 0.1, 1.0)
	
	for point in output_waveform:
		point.material_override = wave_material
	
	# Control materials
	var fund_material = StandardMaterial3D.new()
	fund_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	fund_material.emission_enabled = true
	fund_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FundamentalFreq.material_override = fund_material
	
	var count_material = StandardMaterial3D.new()
	count_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	count_material.emission_enabled = true
	count_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$HarmonicCount.material_override = count_material

func _process(delta):
	time += delta
	
	# Update fundamental frequency
	fundamental_freq = 220.0 + sin(time * 0.3) * 100.0
	
	animate_harmonic_oscillators()
	animate_summation()
	animate_output_waveform()
	animate_controls()

func animate_harmonic_oscillators():
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		var harmonic_freq = fundamental_freq * harmonic.harmonic_number
		
		# Update phase
		harmonic.phase += harmonic_freq * 2.0 * PI * get_process_delta_time()
		
		# Calculate current amplitude (with envelope)
		var envelope = 1.0 + sin(time * 0.5 + i * 0.2) * 0.3
		var current_amplitude = harmonic.amplitude * envelope
		
		# Animate oscillator
		var osc_scale = 0.8 + current_amplitude * sin(harmonic.phase) * 0.5
		harmonic.oscillator.scale = Vector3.ONE * osc_scale
		
		# Update amplitude control height
		var amp_height = current_amplitude * 1.5 + 0.3
		harmonic.amplitude_control.height = amp_height
		harmonic.amplitude_control.position.y = 1 + amp_height/2
		
		# Update frequency indicator
		var freq_scale = 1.0 + (harmonic_freq / 2000.0) * 0.8
		harmonic.freq_indicator.scale = Vector3.ONE * freq_scale
		
		# Update materials based on activity
		var osc_material = harmonic.oscillator.material_override as StandardMaterial3D
		if osc_material:
			var intensity = (current_amplitude * sin(harmonic.phase) + 1.0) * 0.5
			osc_material.emission = osc_material.albedo_color * (0.2 + intensity * 0.8)

func animate_summation():
	# Show progressive summation
	for i in range(summation_nodes.size()):
		var sum_node = summation_nodes[i]
		
		# Calculate partial sum up to this harmonic
		var partial_sum = 0.0
		for j in range(i + 1):
			var harmonic = harmonic_oscillators[j]
			var harmonic_freq = fundamental_freq * harmonic.harmonic_number
			var envelope = 1.0 + sin(time * 0.5 + j * 0.2) * 0.3
			var current_amplitude = harmonic.amplitude * envelope
			
			partial_sum += current_amplitude * sin(harmonic.phase)
		
		# Scale and position based on partial sum
		var scale = 0.5 + abs(partial_sum) * 0.8
		sum_node.scale = Vector3.ONE * scale
		sum_node.position.y = partial_sum * 0.3
		
		# Update color
		var material = sum_node.material_override as StandardMaterial3D
		if material:
			var intensity = (partial_sum + 2.0) / 4.0  # Normalize to 0-1
			material.emission = Color(
				0.05 + intensity * 0.3,
				0.3,
				0.2 + (1.0 - intensity) * 0.3,
				1.0
			)

func animate_output_waveform():
	# Generate final waveform
	for i in range(output_waveform.size()):
		var wave_point = output_waveform[i]
		var x_position = i / float(waveform_resolution)
		
		# Calculate waveform value at this position
		var waveform_value = 0.0
		for j in range(harmonic_oscillators.size()):
			var harmonic = harmonic_oscillators[j]
			var harmonic_freq = fundamental_freq * harmonic.harmonic_number
			var envelope = 1.0 + sin(time * 0.5 + j * 0.2) * 0.3
			var current_amplitude = harmonic.amplitude * envelope
			
			# Phase at this position
			var position_phase = x_position * 4.0 * PI + time * harmonic_freq * 0.01
			waveform_value += current_amplitude * sin(position_phase)
		
		# Position waveform point
		wave_point.position.y = -2 + waveform_value * 0.8
		
		# Scale based on amplitude
		var scale = 0.3 + abs(waveform_value) * 0.5
		wave_point.scale = Vector3.ONE * scale
		
		# Update color
		var material = wave_point.material_override as StandardMaterial3D
		if material:
			var intensity = (waveform_value + 2.0) / 4.0
			material.albedo_color = Color(
				1.0,
				0.8 - intensity * 0.4,
				0.2 + intensity * 0.6,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func animate_controls():
	# Fundamental frequency control
	var fund_height = (fundamental_freq / 400.0) * 1.5 + 0.5
	$FundamentalFreq.height = fund_height
	$FundamentalFreq.position.y = -3 + fund_height/2
	
	# Harmonic count indicator
	var active_harmonics = count_active_harmonics()
	var count_height = (active_harmonics / float(harmonic_count)) * 1.5 + 0.5
	$HarmonicCount.height = count_height
	$HarmonicCount.position.y = -3 + count_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FundamentalFreq.scale.x = pulse
	$HarmonicCount.scale.x = pulse

func count_active_harmonics() -> int:
	var count = 0
	for harmonic in harmonic_oscillators:
		if harmonic.amplitude > 0.1:
			count += 1
	return count

func set_harmonic_series(series_type: String):
	# Set different harmonic series
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		
		match series_type:
			"harmonic":
				harmonic.amplitude = 1.0 / harmonic.harmonic_number
			"square":
				if harmonic.harmonic_number % 2 == 1:
					harmonic.amplitude = 1.0 / harmonic.harmonic_number
				else:
					harmonic.amplitude = 0.0
			"sawtooth":
				harmonic.amplitude = 1.0 / harmonic.harmonic_number
			"triangle":
				if harmonic.harmonic_number % 2 == 1:
					harmonic.amplitude = 1.0 / (harmonic.harmonic_number * harmonic.harmonic_number)
				else:
					harmonic.amplitude = 0.0
			_:
				harmonic.amplitude = 1.0 / harmonic.harmonic_number
