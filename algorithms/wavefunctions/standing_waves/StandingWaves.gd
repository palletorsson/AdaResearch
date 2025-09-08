extends Node3D

var time = 0.0
var wave_nodes = []
var node_count = 21
var frequency = 2.0
var amplitude = 2.0
var string_length = 10.0

func _ready():
	create_wave_nodes()
	setup_materials()

func create_wave_nodes():
	var wave_nodes_parent = $WaveNodes
	
	for i in range(node_count):
		var node_sphere = CSGSphere3D.new()
		node_sphere.radius = 0.1
		node_sphere.position.x = -string_length/2 + (i * string_length / (node_count - 1))
		node_sphere.position.y = 0
		node_sphere.position.z = 0
		wave_nodes_parent.add_child(node_sphere)
		wave_nodes.append(node_sphere)

func setup_materials():
	# String material
	var string_material = StandardMaterial3D.new()
	string_material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)
	string_material.metallic = 0.3
	string_material.roughness = 0.7
	$WaveString.material_override = string_material
	
	# Anchor materials
	var anchor_material = StandardMaterial3D.new()
	anchor_material.albedo_color = Color(0.8, 0.2, 0.2, 1.0)
	anchor_material.emission_enabled = true
	anchor_material.emission = Color(0.3, 0.1, 0.1, 1.0)
	$LeftAnchor.material_override = anchor_material
	$RightAnchor.material_override = anchor_material
	
	# Node materials
	var node_material = StandardMaterial3D.new()
	node_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	node_material.emission_enabled = true
	node_material.emission = Color(0.1, 0.3, 0.4, 1.0)
	
	for node in wave_nodes:
		node.material_override = node_material
	
	# Indicator materials
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$FrequencyIndicator.material_override = freq_material
	
	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.8, 1.0, 0.2, 1.0)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.2, 0.3, 0.05, 1.0)
	$AmplitudeIndicator.material_override = amp_material

func _process(delta):
	time += delta
	animate_standing_wave()
	animate_indicators()

func animate_standing_wave():
	# Standing wave pattern: A(x) * sin(ωt)
	# where A(x) = 2 * amplitude * sin(kx) and k = nπ/L
	var wave_number = frequency * PI / string_length
	
	for i in range(wave_nodes.size()):
		var x_position = -string_length/2 + (i * string_length / (node_count - 1))
		
		# Skip the anchor points (first and last nodes)
		if i == 0 or i == node_count - 1:
			wave_nodes[i].position.y = 0
			continue
		
		# Standing wave amplitude envelope
		var amplitude_envelope = 2.0 * amplitude * sin(wave_number * (x_position + string_length/2))
		
		# Time-dependent oscillation
		var displacement = amplitude_envelope * sin(frequency * time) * 0.3
		
		wave_nodes[i].position.y = displacement
		
		# Color based on displacement
		var intensity = abs(displacement) / (amplitude * 0.6) + 0.3
		var node_material = wave_nodes[i].material_override as StandardMaterial3D
		if node_material:
			node_material.emission = Color(0.1 * intensity, 0.3 * intensity, 0.4 * intensity, 1.0)

func animate_indicators():
	# Frequency indicator - height represents frequency
	var freq_height = frequency * 0.5
	var frequencyindicator = get_node_or_null("FrequencyIndicator")
	if frequencyindicator and frequencyindicator is CSGCylinder3D:
		frequencyindicator.height = freq_height
		frequencyindicator.position.y = -3 + freq_height/2
	
	# Amplitude indicator - height represents amplitude
	var amp_height = amplitude * 0.3
	var amplitudeindicator = get_node_or_null("AmplitudeIndicator")
	if amplitudeindicator and amplitudeindicator is CSGCylinder3D:
		amplitudeindicator.height = amp_height
		amplitudeindicator.position.y = -3 + amp_height/2
	
	# Slowly vary parameters for demonstration
	frequency = 2.0 + sin(time * 0.3) * 1.0
	amplitude = 2.0 + cos(time * 0.2) * 1.0
