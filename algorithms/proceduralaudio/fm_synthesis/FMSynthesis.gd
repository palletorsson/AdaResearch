extends Node3D

var time = 0.0
var carrier_freq = 440.0
var modulator_freq = 220.0
var modulation_index = 5.0
var fm_ratio = 1.0
var spectrum_nodes = []
var modulation_path_nodes = []
var spectrum_resolution = 32

func _ready():
	create_modulation_path()
	create_output_spectrum()
	setup_materials()

func create_modulation_path():
	var path_parent = $ModulationPath
	
	# Create visual connection between modulator and carrier
	for i in range(20):
		var path_node = CSGSphere3D.new()
		path_node.radius = 0.05
		path_node.position = Vector3(
			lerp(3.0, -3.0, i / 19.0),
			1.5,
			0
		)
		path_parent.add_child(path_node)
		modulation_path_nodes.append(path_node)

func create_output_spectrum():
	var spectrum_parent = $OutputSpectrum
	
	for i in range(spectrum_resolution):
		var spectrum_bar = CSGBox3D.new()
		spectrum_bar.size = Vector3(0.2, 0.1, 0.2)
		spectrum_bar.position = Vector3(
			-6 + i * 0.4,
			-1,
			2
		)
		spectrum_parent.add_child(spectrum_bar)
		spectrum_nodes.append(spectrum_bar)

func setup_materials():
	# Carrier material
	var carrier_material = StandardMaterial3D.new()
	carrier_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	carrier_material.emission_enabled = true
	carrier_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$Carrier.material_override = carrier_material
	
	# Modulator material
	var modulator_material = StandardMaterial3D.new()
	modulator_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	modulator_material.emission_enabled = true
	modulator_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$Modulator.material_override = modulator_material
	
	# Modulation path materials
	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	path_material.emission_enabled = true
	path_material.emission = Color(0.3, 0.3, 0.1, 1.0)
	
	for node in modulation_path_nodes:
		node.material_override = path_material
	
	# Spectrum materials
	var spectrum_material = StandardMaterial3D.new()
	spectrum_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	spectrum_material.emission_enabled = true
	spectrum_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	
	for bar in spectrum_nodes:
		bar.material_override = spectrum_material
	
	# Control materials
	var carrier_freq_material = StandardMaterial3D.new()
	carrier_freq_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
	carrier_freq_material.emission_enabled = true
	carrier_freq_material.emission = Color(0.3, 0.15, 0.05, 1.0)
	$CarrierFreq.material_override = carrier_freq_material
	
	var mod_freq_material = StandardMaterial3D.new()
	mod_freq_material.albedo_color = Color(0.6, 0.2, 1.0, 1.0)
	mod_freq_material.emission_enabled = true
	mod_freq_material.emission = Color(0.15, 0.05, 0.3, 1.0)
	$ModulatorFreq.material_override = mod_freq_material
	
	var mod_index_material = StandardMaterial3D.new()
	mod_index_material.albedo_color = Color(0.2, 1.0, 0.6, 1.0)
	mod_index_material.emission_enabled = true
	mod_index_material.emission = Color(0.05, 0.3, 0.15, 1.0)
	$ModulationIndex.material_override = mod_index_material
	
	var ratio_material = StandardMaterial3D.new()
	ratio_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	ratio_material.emission_enabled = true
	ratio_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$FMRatio.material_override = ratio_material

func _process(delta):
	time += delta
	
	# Update FM parameters
	carrier_freq = 440.0 + sin(time * 0.2) * 200.0
	modulator_freq = carrier_freq * fm_ratio
	modulation_index = 3.0 + sin(time * 0.3) * 4.0
	fm_ratio = 1.0 + sin(time * 0.15) * 1.5
	
	animate_fm_synthesis()
	animate_controls()

func animate_fm_synthesis():
	# Animate carrier oscillator
	var carrier_phase = time * carrier_freq * 2.0 * PI
	var carrier_scale = 1.0 + sin(carrier_phase) * 0.3
	$Carrier.scale = Vector3.ONE * carrier_scale
	
	# Animate modulator oscillator
	var modulator_phase = time * modulator_freq * 2.0 * PI
	var modulator_scale = 1.0 + sin(modulator_phase) * 0.4
	$Modulator.scale = Vector3.ONE * modulator_scale
	
	# Animate modulation path
	animate_modulation_path()
	
	# Calculate and display FM spectrum
	calculate_fm_spectrum()

func animate_modulation_path():
	# Show modulation signal traveling from modulator to carrier
	var wave_position = fmod(time * 2.0, 1.0)
	
	for i in range(modulation_path_nodes.size()):
		var node = modulation_path_nodes[i]
		var node_position = i / float(modulation_path_nodes.size() - 1)
		
		# Calculate distance from traveling wave
		var distance = abs(node_position - wave_position)
		var intensity = max(0.0, 1.0 - distance * 5.0)
		
		# Scale and animate based on modulation signal
		var modulation_value = sin(time * modulator_freq * 2.0 * PI) * modulation_index * 0.1
		var scale = 0.5 + intensity * (1.0 + modulation_value)
		node.scale = Vector3.ONE * scale
		
		# Update material
		var material = node.material_override as StandardMaterial3D
		if material:
			material.emission = Color(
				0.3 + intensity * 0.5,
				0.3 + intensity * 0.5,
				0.1 + intensity * 0.3,
				1.0
			)

func calculate_fm_spectrum():
	# Calculate FM spectrum using Bessel functions approximation
	for i in range(spectrum_nodes.size()):
		var bar = spectrum_nodes[i]
		var frequency_ratio = i / float(spectrum_resolution) * 8.0  # 0 to 8 times carrier frequency
		
		# Calculate sidebands using simplified Bessel function approximation
		var amplitude = calculate_fm_sideband_amplitude(frequency_ratio)
		
		# Add some dynamics
		amplitude *= (1.0 + sin(time * 3.0 + i * 0.2) * 0.3)
		
		# Update spectrum bar
		var height = 0.1 + amplitude * 2.0
		bar.size.y = height
		bar.position.y = -1 + height/2
		
		# Update color based on amplitude
		var material = bar.material_override as StandardMaterial3D
		if material:
			var intensity = amplitude
			material.albedo_color = Color(
				0.2 + intensity * 0.8,
				1.0 - intensity * 0.5,
				0.8 - intensity * 0.3,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func calculate_fm_sideband_amplitude(frequency_ratio: float) -> float:
	# Simplified FM spectrum calculation
	# In real FM synthesis, this would use Bessel functions
	
	var carrier_ratio = 1.0
	var sideband_distance = abs(frequency_ratio - carrier_ratio)
	
	# Approximate sideband amplitudes
	var amplitude = 0.0
	
	# Carrier
	if sideband_distance < 0.1:
		amplitude = bessel_j0_approx(modulation_index)
	
	# First sidebands
	elif abs(sideband_distance - fm_ratio) < 0.1:
		amplitude = abs(bessel_j1_approx(modulation_index))
	
	# Second sidebands
	elif abs(sideband_distance - 2.0 * fm_ratio) < 0.1:
		amplitude = abs(bessel_j2_approx(modulation_index)) * 0.5
	
	# Higher order sidebands with decay
	else:
		var order = round(sideband_distance / fm_ratio)
		if order <= 6:
			amplitude = exp(-order * 0.5) * sin(modulation_index) / (order + 1)
	
	return clamp(amplitude, 0.0, 1.0)

# Simplified Bessel function approximations
func bessel_j0_approx(x: float) -> float:
	if abs(x) < 0.1:
		return 1.0 - x*x/4.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - PI/4.0)

func bessel_j1_approx(x: float) -> float:
	if abs(x) < 0.1:
		return x/2.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - 3.0*PI/4.0) * sign(x)

func bessel_j2_approx(x: float) -> float:
	if abs(x) < 0.1:
		return x*x/8.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - 5.0*PI/4.0)

func animate_controls():
	# Carrier frequency control
	var carrier_height = (carrier_freq / 800.0) * 1.5 + 0.5
	$CarrierFreq.height = carrier_height
	$CarrierFreq.position.y = -3 + carrier_height/2
	
	# Modulator frequency control
	var mod_height = (modulator_freq / 800.0) * 1.5 + 0.5
	$ModulatorFreq.height = mod_height
	$ModulatorFreq.position.y = -3 + mod_height/2
	
	# Modulation index control
	var index_height = (modulation_index / 10.0) * 1.5 + 0.5
	$ModulationIndex.height = index_height
	$ModulationIndex.position.y = -3 + index_height/2
	
	# FM ratio indicator
	var ratio_height = fm_ratio * 0.8 + 0.5
	$FMRatio.height = ratio_height
	$FMRatio.position.y = -3 + ratio_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$CarrierFreq.scale.x = pulse
	$ModulatorFreq.scale.x = pulse
	$ModulationIndex.scale.x = pulse
	$FMRatio.scale.x = pulse
	
	# Update carrier and modulator emission based on their signals
	var carrier_material = $Carrier.material_override as StandardMaterial3D
	if carrier_material:
		var carrier_intensity = (sin(time * carrier_freq * 2.0 * PI) + 1.0) * 0.5
		carrier_material.emission = Color(0.5, 0.1, 0.1, 1.0) * (0.5 + carrier_intensity)
	
	var modulator_material = $Modulator.material_override as StandardMaterial3D
	if modulator_material:
		var mod_intensity = (sin(time * modulator_freq * 2.0 * PI) + 1.0) * 0.5
		modulator_material.emission = Color(0.1, 0.1, 0.5, 1.0) * (0.5 + mod_intensity)
