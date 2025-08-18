extends Node3D

var time = 0.0
var grid_size = 25
var surface_nodes = []
var frequency = 1.0
var amplitude = 1.5
var phase = 0.0
var topology_timer = 0.0
var topology_interval = 5.0

# Topology modes
enum TopologyMode {
	FLAT_SINE,
	CYLINDRICAL,
	SPHERICAL,
	TOROIDAL,
	MOBIUS_STRIP
}

var current_topology = TopologyMode.FLAT_SINE

func _ready():
	create_sine_surface()
	setup_materials()

func create_sine_surface():
	var surface_parent = $SineSurface
	
	for x in range(grid_size):
		surface_nodes.append([])
		for z in range(grid_size):
			var node_sphere = CSGSphere3D.new()
			node_sphere.radius = 0.08
			
			# Initial position
			var x_pos = (x - grid_size/2.0) * 0.4
			var z_pos = (z - grid_size/2.0) * 0.4
			node_sphere.position = Vector3(x_pos, 0, z_pos)
			
			surface_parent.add_child(node_sphere)
			surface_nodes[x].append(node_sphere)

func setup_materials():
	# Surface node materials
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
	surface_material.emission_enabled = true
	surface_material.emission = Color(0.1, 0.2, 0.3, 1.0)
	
	for row in surface_nodes:
		for node in row:
			node.material_override = surface_material
	
	# Control materials
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FrequencyControl.material_override = freq_material
	
	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.1, 0.5, 0.1, 1.0)
	$AmplitudeControl.material_override = amp_material
	
	var phase_material = StandardMaterial3D.new()
	phase_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	phase_material.emission_enabled = true
	phase_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$PhaseControl.material_override = phase_material
	
	var topology_material = StandardMaterial3D.new()
	topology_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	topology_material.emission_enabled = true
	topology_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$TopologyMode.material_override = topology_material

func _process(delta):
	time += delta
	topology_timer += delta
	
	# Switch topology modes
	if topology_timer >= topology_interval:
		topology_timer = 0.0
		current_topology = (current_topology + 1) % TopologyMode.size()
	
	# Update parameters
	frequency = 1.0 + sin(time * 0.3) * 0.5
	amplitude = 1.5 + cos(time * 0.2) * 0.8
	phase = time * 2.0
	
	update_sine_surface()
	animate_controls()

func update_sine_surface():
	match current_topology:
		TopologyMode.FLAT_SINE:
			update_flat_sine_surface()
		TopologyMode.CYLINDRICAL:
			update_cylindrical_surface()
		TopologyMode.SPHERICAL:
			update_spherical_surface()
		TopologyMode.TOROIDAL:
			update_toroidal_surface()
		TopologyMode.MOBIUS_STRIP:
			update_mobius_surface()

func update_flat_sine_surface():
	# Standard sine wave surface z = A*sin(fx + fy + phase)
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			
			var x_normalized = (x - grid_size/2.0) / (grid_size/2.0)
			var z_normalized = (z - grid_size/2.0) / (grid_size/2.0)
			
			var x_pos = x_normalized * 5.0
			var z_pos = z_normalized * 5.0
			
			var height = amplitude * sin(frequency * x_normalized * PI + phase) * sin(frequency * z_normalized * PI + phase * 0.7)
			
			node.position = Vector3(x_pos, height, z_pos)
			update_node_color(node, height)

func update_cylindrical_surface():
	# Map to cylindrical coordinates and apply sine waves
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			
			var u = (x / float(grid_size)) * 2.0 * PI  # Angle
			var v = (z - grid_size/2.0) / (grid_size/2.0) * 3.0  # Height
			
			var radius = 3.0 + amplitude * sin(frequency * u + phase) * sin(frequency * v * 0.5 + phase)
			
			node.position = Vector3(
				radius * cos(u),
				v,
				radius * sin(u)
			)
			update_node_color(node, radius - 3.0)

func update_spherical_surface():
	# Map to spherical coordinates with sine wave modulation
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			
			var theta = (x / float(grid_size)) * 2.0 * PI  # Azimuthal angle
			var phi = (z / float(grid_size)) * PI  # Polar angle
			
			var radius = 3.0 + amplitude * sin(frequency * theta + phase) * sin(frequency * phi + phase * 0.8)
			
			node.position = Vector3(
				radius * sin(phi) * cos(theta),
				radius * cos(phi),
				radius * sin(phi) * sin(theta)
			)
			update_node_color(node, radius - 3.0)

func update_toroidal_surface():
	# Torus with sine wave modulation
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			
			var u = (x / float(grid_size)) * 2.0 * PI  # Major angle
			var v = (z / float(grid_size)) * 2.0 * PI  # Minor angle
			
			var major_radius = 3.0
			var minor_radius = 1.0 + amplitude * sin(frequency * u + phase) * sin(frequency * v + phase * 0.6)
			
			node.position = Vector3(
				(major_radius + minor_radius * cos(v)) * cos(u),
				minor_radius * sin(v),
				(major_radius + minor_radius * cos(v)) * sin(u)
			)
			update_node_color(node, minor_radius - 1.0)

func update_mobius_surface():
	# Möbius strip with sine wave modulation
	for x in range(grid_size):
		for z in range(grid_size):
			var node = surface_nodes[x][z]
			
			var u = (x / float(grid_size)) * 2.0 * PI  # Parameter along the strip
			var v = (z - grid_size/2.0) / (grid_size/2.0) * 0.5  # Width parameter
			
			# Möbius strip parametric equations with sine modulation
			var radius = 2.0 + amplitude * sin(frequency * u * 2.0 + phase) * 0.5
			var twist_factor = 1.0 + amplitude * sin(frequency * u + phase) * 0.3
			
			node.position = Vector3(
				(radius + v * cos(u/2.0) * twist_factor) * cos(u),
				v * sin(u/2.0) * twist_factor,
				(radius + v * cos(u/2.0) * twist_factor) * sin(u)
			)
			update_node_color(node, v * twist_factor)

func update_node_color(node: CSGSphere3D, height_value: float):
	var material = node.material_override as StandardMaterial3D
	if material:
		# Color based on height/displacement
		var intensity = (height_value + amplitude) / (2.0 * amplitude)
		intensity = clamp(intensity, 0.0, 1.0)
		
		material.albedo_color = Color(
			0.3 + intensity * 0.7,
			0.7 - intensity * 0.4,
			1.0 - intensity * 0.7,
			1.0
		)
		material.emission = material.albedo_color * (0.2 + intensity * 0.3)

func animate_controls():
	# Frequency control
	var freq_height = frequency * 0.8 + 0.5
	$FrequencyControl.size.y = freq_height
	$FrequencyControl.position.y = -3 + freq_height/2
	
	# Amplitude control
	var amp_height = amplitude * 0.6 + 0.5
	$AmplitudeControl.size.y = amp_height
	$AmplitudeControl.position.y = -3 + amp_height/2
	
	# Phase control (rotating)
	var phase_height = 1.0 + sin(phase) * 0.3
	$PhaseControl.size.y = phase_height
	$PhaseControl.position.y = -3 + phase_height/2
	$PhaseControl.rotation_degrees.y = phase * 180.0 / PI
	
	# Topology mode indicator
	var topology_height = (current_topology + 1) * 0.3 + 0.5
	$TopologyMode.size.y = topology_height
	$TopologyMode.position.y = -3 + topology_height/2
	
	# Update topology indicator color
	var topology_material = $TopologyMode.material_override as StandardMaterial3D
	if topology_material:
		match current_topology:
			TopologyMode.FLAT_SINE:
				topology_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			TopologyMode.CYLINDRICAL:
				topology_material.albedo_color = Color(0.8, 1.0, 0.2, 1.0)
			TopologyMode.SPHERICAL:
				topology_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			TopologyMode.TOROIDAL:
				topology_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
			TopologyMode.MOBIUS_STRIP:
				topology_material.albedo_color = Color(1.0, 0.2, 0.8, 1.0)
		
		topology_material.emission = topology_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FrequencyControl.scale.x = pulse
	$AmplitudeControl.scale.x = pulse
	$PhaseControl.scale.x = pulse
	$TopologyMode.scale.x = pulse

func get_topology_name() -> String:
	match current_topology:
		TopologyMode.FLAT_SINE:
			return "Flat Sine Surface"
		TopologyMode.CYLINDRICAL:
			return "Cylindrical"
		TopologyMode.SPHERICAL:
			return "Spherical"
		TopologyMode.TOROIDAL:
			return "Toroidal"
		TopologyMode.MOBIUS_STRIP:
			return "Möbius Strip"
		_:
			return "Unknown"

func get_topology_equation() -> String:
	match current_topology:
		TopologyMode.FLAT_SINE:
			return "z = A*sin(fx)*sin(fz)"
		TopologyMode.CYLINDRICAL:
			return "r = R + A*sin(fu)*sin(fv)"
		TopologyMode.SPHERICAL:
			return "r = R + A*sin(fθ)*sin(fφ)"
		TopologyMode.TOROIDAL:
			return "r_minor = R + A*sin(fu)*sin(fv)"
		TopologyMode.MOBIUS_STRIP:
			return "Möbius with sine modulation"
		_:
			return "Unknown"
