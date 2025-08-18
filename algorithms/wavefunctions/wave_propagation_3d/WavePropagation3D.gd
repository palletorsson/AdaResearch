extends Node3D

var time = 0.0
var surface_nodes = []
var wave_rings = []
var grid_size = 20
var surface_scale = 8.0
var frequency = 1.5
var amplitude = 1.0
var wave_speed = 3.0

func _ready():
	create_wave_surface()
	create_wave_rings()
	setup_materials()

func create_wave_surface():
	var surface_parent = $WaveSurface
	
	for x in range(grid_size):
		surface_nodes.append([])
		for z in range(grid_size):
			var node_sphere = CSGSphere3D.new()
			node_sphere.radius = 0.08
			
			var x_pos = (x - grid_size/2.0) * surface_scale / grid_size
			var z_pos = (z - grid_size/2.0) * surface_scale / grid_size
			
			node_sphere.position = Vector3(x_pos, 0, z_pos)
			surface_parent.add_child(node_sphere)
			surface_nodes[x].append(node_sphere)

func create_wave_rings():
	var rings_parent = $WaveRings
	
	for i in range(5):
		var ring = CSGCylinder3D.new()
		ring.radius = 1.0 + i * 0.8
		 + i * 0.8
		ring.height = 0.05
		ring.position.y = -0.5
		rings_parent.add_child(ring)
		wave_rings.append(ring)

func setup_materials():
	# Wave source material
	var source_material = StandardMaterial3D.new()
	source_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	source_material.emission_enabled = true
	source_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$WaveSource.material_override = source_material
	
	# Surface node materials
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
	surface_material.emission_enabled = true
	surface_material.emission = Color(0.1, 0.2, 0.3, 1.0)
	
	for row in surface_nodes:
		for node in row:
			node.material_override = surface_material
	
	# Wave ring materials
	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.8, 0.8, 1.0, 0.3)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.2, 0.2, 0.4, 1.0)
	
	for ring in wave_rings:
		ring.material_override = ring_material
	
	# Control materials
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$FrequencyControl.material_override = freq_material
	
	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.8, 1.0, 0.2, 1.0)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.2, 0.3, 0.05, 1.0)
	$AmplitudeControl.material_override = amp_material

func _process(delta):
	time += delta
	animate_3d_wave_propagation()
	animate_wave_rings()
	animate_controls()

func animate_3d_wave_propagation():
	var source_pos = Vector3.ZERO
	
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			var node_pos = node.position
			
			# Calculate distance from wave source
			var distance = Vector2(node_pos.x, node_pos.z).length()
			
			# Wave equation: A * sin(k*r - ω*t)
			var wave_phase = distance * frequency - wave_speed * time
			var displacement = amplitude * sin(wave_phase) * exp(-distance * 0.1)
			
			# Apply displacement
			node.position.y = displacement * 0.5
			
			# Color based on wave phase
			var wave_intensity = (sin(wave_phase) + 1.0) * 0.5
			var node_material = node.material_override as StandardMaterial3D
			if node_material:
				var emission_strength = 0.1 + wave_intensity * 0.3
				node_material.emission = Color(0.1 * emission_strength, 0.2 * emission_strength, 
											   0.3 * emission_strength, 1.0)

func animate_wave_rings():
	# Animate expanding wave rings
	for i in range(wave_rings.size()):
		var ring = wave_rings[i]
		var ring_time = time - i * 0.5
		
		if ring_time > 0:
			var ring_radius = wave_speed * ring_time
			ring.radius = ring_radius
			
			# Fade out as ring expands
			var fade_factor = max(0.0, 1.0 - ring_time * 0.2)
			var ring_material = ring.material_override as StandardMaterial3D
			if ring_material:
				ring_material.albedo_color.a = fade_factor * 0.3
				ring_material.emission = Color(0.2 * fade_factor, 0.2 * fade_factor, 
											   0.4 * fade_factor, 1.0)
			
			# Reset ring when it gets too large
			if ring_radius > 6.0:
				ring.radius = 0.1
				
		else:
			ring.radius = 0.1
			

func animate_controls():
	# Frequency control
	var freq_height = frequency * 0.8
	$FrequencyControl.height = freq_height
	$FrequencyControl.position.y = -3 + freq_height/2
	
	# Amplitude control
	var amp_height = amplitude * 1.2
	$AmplitudeControl.height = amp_height
	$AmplitudeControl.position.y = -3 + amp_height/2
	
	# Vary parameters for demonstration
	frequency = 1.5 + sin(time * 0.2) * 0.8
	amplitude = 1.0 + cos(time * 0.15) * 0.5
	
	# Pulsing wave source
	$WaveSource.radius = 0.3 + sin(time * frequency * 3.0) * 0.1
