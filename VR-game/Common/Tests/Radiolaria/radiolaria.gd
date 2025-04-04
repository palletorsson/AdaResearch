extends Node3D

# Radiolaria and Pollen Form Generator
# Creates a variety of symmetric geometric biological forms inspired by Ernst Haeckel illustrations

@export_category("Generation Settings")
@export var number_of_forms: int = 9
@export var grid_size: int = 3
@export var spacing: float = 2.5

@export_category("Form Variation")
@export_range(0.0, 1.0) var spikiness_probability: float = 0.7
@export_range(0.5, 3.0) var max_spike_length: float = 1.5
@export_range(5, 50) var detail_level: int = 20

# Materials
var base_materials = []
var spike_materials = []

func _ready():
	randomize()
	
	# Create materials
	create_materials()
	
	# Generate a grid of biological forms
	generate_grid()
	
	# Add camera and lighting
	setup_environment()

func create_materials():
	# Create several base materials with different colors
	var colors = [
		Color(0.9, 0.9, 0.7),  # Cream
		Color(0.8, 0.8, 0.8),  # Light gray
		Color(0.9, 0.8, 0.6),  # Light tan
		Color(0.95, 0.95, 0.95),  # Off-white
		Color(0.7, 0.8, 0.7),  # Light green
	]
	
	for color in colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.1
		material.roughness = 0.8
		base_materials.append(material)
	
	# Create several spike materials with different colors
	var spike_colors = [
		Color(0.8, 0.3, 0.3),  # Reddish
		Color(0.9, 0.7, 0.2),  # Yellow
		Color(0.6, 0.6, 0.6),  # Gray
		Color(0.3, 0.5, 0.2),  # Green
		Color(0.8, 0.8, 0.9),  # Light blue
	]
	
	for color in spike_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.2
		material.roughness = 0.7
		spike_materials.append(material)

func generate_grid():
	var forms_container = Node3D.new()
	forms_container.name = "BiologicalForms"
	add_child(forms_container)
	
	# Calculate grid bounds
	var start_pos = -Vector3(spacing, 0, spacing) * (grid_size - 1) / 2
	
	# Create forms in a grid pattern
	var form_count = 0
	for z in range(grid_size):
		for x in range(grid_size):
			if form_count >= number_of_forms:
				return
				
			var position = start_pos + Vector3(x * spacing, 0, z * spacing)
			
			# Choose a random form type
			var form_type = randi() % 6  # 6 different form types
			
			match form_type:
				0: create_basic_radiolaria(forms_container, position)
				1: create_spiky_radiolaria(forms_container, position)
				2: create_polyhedral_form(forms_container, position)
				3: create_lattice_sphere(forms_container, position)
				4: create_ringed_form(forms_container, position)
				5: create_pollen_form(forms_container, position)
			
			form_count += 1

func create_basic_radiolaria(parent, position):
	var form = Node3D.new()
	form.name = "BasicRadiolaria_" + str(parent.get_child_count())
	form.position = position
	
	# Core sphere
	var core = CSGSphere3D.new()
	core.name = "Core"
	core.radius = 0.5
	core.material = base_materials[randi() % base_materials.size()]
	form.add_child(core)
	
	# Add some random bumps
	var num_bumps = randi() % 15 + 5
	
	for i in range(num_bumps):
		var bump = CSGSphere3D.new()
		bump.name = "Bump_" + str(i)
		bump.radius = randf_range(0.05, 0.2)
		
		# Position on sphere surface
		var phi = randf() * PI * 2
		var theta = randf() * PI
		var r = 0.5 - bump.radius * 0.5  # Slightly embedded in the core
		
		var x = r * sin(theta) * cos(phi)
		var y = r * sin(theta) * sin(phi)
		var z = r * cos(theta)
		
		bump.position = Vector3(x, y, z)
		bump.operation = CSGShape3D.OPERATION_UNION
		
		if randf() < 0.3:  # 30% chance of different color
			bump.material = spike_materials[randi() % spike_materials.size()]
		
		core.add_child(bump)
	
	parent.add_child(form)
	return form

func create_spiky_radiolaria(parent, position):
	var form = Node3D.new()
	form.name = "SpikyRadiolaria_" + str(parent.get_child_count())
	form.position = position
	
	# Core sphere
	var core = CSGSphere3D.new()
	core.name = "Core"
	core.radius = 0.4
	core.material = base_materials[randi() % base_materials.size()]
	form.add_child(core)
	
	# Choose a spike material
	var spike_material = spike_materials[randi() % spike_materials.size()]
	
	# Determine spike pattern - regular or random
	var regular_pattern = randf() < 0.5
	var num_spikes = 0
	
	if regular_pattern:
		# Regular pattern based on icosahedron vertices
		var vertices = generate_icosahedron_vertices(0.5)
		num_spikes = vertices.size()
		
		for i in range(vertices.size()):
			add_spike(core, vertices[i], spike_material)
	else:
		# Random pattern
		num_spikes = randi() % 40 + 20
		
		for i in range(num_spikes):
			var phi = randf() * PI * 2
			var theta = randf() * PI
			var r = 0.4  # Core radius
			
			var direction = Vector3(
				sin(theta) * cos(phi),
				sin(theta) * sin(phi),
				cos(theta)
			).normalized()
			
			add_spike(core, direction, spike_material)
	
	parent.add_child(form)
	return form

func add_spike(parent, direction, material):
	var spike = CSGCylinder3D.new()
	spike.name = "Spike"
	#spike.radius_bottom = randf_range(0.03, 0.08)
	#spike.radius_top = 0.01
	spike.height = randf_range(0.2, max_spike_length)
	
	# Position and orient
	spike.position = direction * parent.radius
	
	# Rotate to point outward
	var up_vector = Vector3(0, 1, 0)
	if direction.is_equal_approx(up_vector) or direction.is_equal_approx(-up_vector):
		spike.rotation = Vector3(PI if direction.y < 0 else 0, 0, 0)
	else:
		var axis = up_vector.cross(direction).normalized()
		var angle = acos(up_vector.dot(direction))
		spike.transform.basis = Basis(axis, angle)
	
	spike.operation = CSGShape3D.OPERATION_UNION
	spike.material = material
	parent.add_child(spike)

func create_polyhedral_form(parent, position):
	var form = Node3D.new()
	form.name = "PolyhedralForm_" + str(parent.get_child_count())
	form.position = position
	
	# Choose a polyhedron type
	var poly_type = randi() % 3  # 0 = icosahedron, 1 = dodecahedron approximation, 2 = custom
	var complexity = randf_range(0.3, 1.0)  # Affects number of faces/details
	
	var base_material = base_materials[randi() % base_materials.size()]
	
	match poly_type:
		0: # Icosahedron-based
			var core = create_approximate_icosahedron(0.5, detail_level * complexity)
			core.material = base_material
			form.add_child(core)
			
			# Add ornaments at vertices
			if randf() < 0.6:  # 60% chance
				var vertices = generate_icosahedron_vertices(0.5)
				for vertex in vertices:
					if randf() < 0.7:  # Not all vertices
						var ornament = CSGSphere3D.new()
						ornament.radius = randf_range(0.05, 0.1)
						ornament.position = vertex
						ornament.operation = CSGShape3D.OPERATION_UNION
						
						if randf() < 0.5:  # 50% chance of different color
							ornament.material = spike_materials[randi() % spike_materials.size()]
							
						core.add_child(ornament)
		
		1: # Dodecahedron-like
			var core = CSGSphere3D.new()
			core.radius = 0.5
			core.material = base_material
			form.add_child(core)
			
			# Create facets by cutting planes
			var vertices = generate_dodecahedron_vertices(0.6)
			for vertex in vertices:
				var cutter = CSGBox3D.new()
				cutter.size = Vector3(0.4, 0.4, 0.4)
				cutter.position = vertex
				cutter.look_at(Vector3.ZERO, Vector3.UP)
				cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
				core.add_child(cutter)
		
		2: # Custom polyhedral
			var core = CSGSphere3D.new()
			core.radius = 0.5
			core.material = base_material
			form.add_child(core)
			
			# Create random facets
			var num_facets = int(10 * complexity) + 5
			for i in range(num_facets):
				var phi = randf() * PI * 2
				var theta = randf() * PI
				var direction = Vector3(
					sin(theta) * cos(phi),
					sin(theta) * sin(phi),
					cos(theta)
				).normalized()
				
				var distance = randf_range(0.3, 0.5)
				var size = randf_range(0.2, 0.4)
				
				var cutter = CSGBox3D.new()
				cutter.size = Vector3(size, size, size)
				cutter.position = direction * distance
				cutter.look_at(Vector3.ZERO, Vector3.UP)
				cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
				core.add_child(cutter)
	
	# Add spikes if needed
	if randf() < spikiness_probability:
		var spike_count = int(randi() % 12 + 6)
		var spike_material = spike_materials[randi() % spike_materials.size()]
		
		for i in range(spike_count):
			var phi = randf() * PI * 2
			var theta = randf() * PI
			var direction = Vector3(
				sin(theta) * cos(phi),
				sin(theta) * sin(phi),
				cos(theta)
			).normalized()
			
			add_spike(form.get_child(0), direction, spike_material)
	
	parent.add_child(form)
	return form

func create_lattice_sphere(parent, position):
	var form = Node3D.new()
	form.name = "LatticeSphere_" + str(parent.get_child_count())
	form.position = position
	
	# Create the structure using a series of rings
	var base_material = base_materials[randi() % base_materials.size()]
	var num_rings = randi() % 8 + 3
	var radius = 0.5
	
	# Create rings around different axes
	var axes = [
		Vector3.UP,
		Vector3.RIGHT,
		Vector3.FORWARD
	]
	
	for axis_idx in range(axes.size()):
		var axis = axes[axis_idx]
		var perpendicular = axis.cross(axis.cross(Vector3.ONE).normalized())
		
		for i in range(num_rings):
			var ring_radius = radius * sin(PI * (i + 1) / (num_rings + 1))
			var ring_offset = radius * cos(PI * (i + 1) / (num_rings + 1))
			
			var ring = CSGTorus3D.new()
			ring.name = "Ring_" + str(axis_idx) + "_" + str(i)
			ring.inner_radius = ring_radius - 0.03
			ring.outer_radius = ring_radius
			
			# Orient the ring
			if axis == Vector3.UP:
				ring.rotation.x = PI/2  # Rotate around X to make it horizontal
			elif axis == Vector3.RIGHT:
				ring.rotation.z = PI/2  # Rotate around Z
			elif axis == Vector3.FORWARD:
				ring.rotation.x = 0  # Default orientation
			
			# Position the ring
			ring.position = axis * ring_offset
			
			ring.material = base_material
			form.add_child(ring)
	
	# Add intersection points/nodes
	if randf() < 0.7:  # 70% chance
		var num_nodes = randi() % 20 + 10
		for i in range(num_nodes):
			var phi = randf() * PI * 2
			var theta = randf() * PI
			var r = radius * 0.95  # Slightly inside the outer surface
			
			var x = r * sin(theta) * cos(phi)
			var y = r * sin(theta) * sin(phi)
			var z = r * cos(theta)
			
			var node_sphere = CSGSphere3D.new()
			node_sphere.name = "Node_" + str(i)
			node_sphere.radius = randf_range(0.02, 0.05)
			node_sphere.position = Vector3(x, y, z)
			
			if randf() < 0.3:  # 30% different color
				node_sphere.material = spike_materials[randi() % spike_materials.size()]
			else:
				node_sphere.material = base_material
				
			form.add_child(node_sphere)
	
	parent.add_child(form)
	return form

func create_ringed_form(parent, position):
	var form = Node3D.new()
	form.name = "RingedForm_" + str(parent.get_child_count())
	form.position = position
	
	# Create central sphere
	var core = CSGSphere3D.new()
	core.name = "Core"
	core.radius = 0.3
	core.material = base_materials[randi() % base_materials.size()]
	form.add_child(core)
	
	# Create concentric rings
	var num_rings = randi() % 3 + 1
	var ring_material = base_materials[randi() % base_materials.size()]
	
	# If we want different ring material
	if randf() < 0.5:
		ring_material = spike_materials[randi() % spike_materials.size()]
	
	for i in range(num_rings):
		var ring_radius = 0.4 + i * 0.15
		var thickness = randf_range(0.02, 0.05)
		
		var ring = CSGTorus3D.new()
		ring.name = "Ring_" + str(i)
		ring.inner_radius = ring_radius - thickness
		ring.outer_radius = ring_radius
		ring.material = ring_material
		
		# Random rotation for the ring
		ring.rotation = Vector3(
			randf() * PI,
			randf() * PI,
			randf() * PI
		)
		
		form.add_child(ring)
	
	# Add spokes connecting core to rings
	if randf() < 0.7 and num_rings > 0:  # 70% chance if has rings
		var num_spokes = randi() % 8 + 4
		var spoke_material = ring_material
		
		for i in range(num_spokes):
			var phi = 2 * PI * i / num_spokes
			var theta = PI * 0.5  # Equatorial
			
			var spoke = CSGCylinder3D.new()
			spoke.name = "Spoke_" + str(i)
			spoke.radius = 0.02
			
			# Determine the outermost ring radius
			var max_radius = 0.4 + (num_rings - 1) * 0.15
			spoke.height = max_radius - 0.1  # Subtract to account for core
			
			# Position at the edge of the core, pointing outward
			spoke.position = Vector3(
				0.3 * cos(phi),
				0.3 * sin(phi),
				0
			)
			
			# Point outward
			spoke.rotation.z = phi
			spoke.rotation.y = PI * 0.5
			
			# Offset to start at edge of core
			spoke.position.x += spoke.height * 0.5 * cos(phi)
			spoke.position.y += spoke.height * 0.5 * sin(phi)
			
			spoke.material = spoke_material
			form.add_child(spoke)
	
	parent.add_child(form)
	return form

func create_pollen_form(parent, form_position):
	var form = Node3D.new()
	form.name = "PollenForm_" + str(parent.get_child_count())
	form.position = form_position
	
	# Create the base sphere
	var core = CSGSphere3D.new()
	core.name = "Core"
	core.radius = 0.4
	
	var base_material = base_materials[randi() % base_materials.size()]
	core.material = base_material
	form.add_child(core)
	
	# Choose pattern type
	var pattern_type = randi() % 3  # 0 = bumps, 1 = short spikes, 2 = mixed
	var pattern_material = base_material
	
	# Sometimes use a different material for the pattern
	if randf() < 0.6:
		pattern_material = spike_materials[randi() % spike_materials.size()]
	
	match pattern_type:
		0:  # Bumps pattern
			var num_bumps = randi() % 50 + 30
			
			for i in range(num_bumps):
				var bump = CSGSphere3D.new()
				bump.name = "Bump_" + str(i)
				bump.radius = randf_range(0.05, 0.1)
				
				var phi = randf() * PI * 2
				var theta = randf() * PI
				var r = core.radius - bump.radius * 0.5
				
				var x = r * sin(theta) * cos(phi)
				var y = r * sin(theta) * sin(phi)
				var z = r * cos(theta)
				
				bump.position = Vector3(x, y, z)
				bump.operation = CSGShape3D.OPERATION_UNION
				bump.material = pattern_material
				
				core.add_child(bump)
		
		1:  # Short spikes pattern
			var num_spikes = randi() % 40 + 20
			
			for i in range(num_spikes):
				var phi = randf() * PI * 2
				var theta = randf() * PI
				var direction = Vector3(
					sin(theta) * cos(phi),
					sin(theta) * sin(phi),
					cos(theta)
				).normalized()
				
				var spike = CSGCylinder3D.new()
				spike.name = "Spike_" + str(i)
				#spike.radius_bottom = randf_range(0.03, 0.06)
				#spike.radius_top = spike.radius_bottom * 0.5
				spike.height = randf_range(0.1, 0.25)
				spike.material = pattern_material
				
				# Position at surface
				spike.position = direction * core.radius
				
				# Rotate to point outward
				var up_vector = Vector3(0, 1, 0)
				if direction.is_equal_approx(up_vector) or direction.is_equal_approx(-up_vector):
					spike.rotation = Vector3(PI if direction.y < 0 else 0, 0, 0)
				else:
					var axis = up_vector.cross(direction).normalized()
					var angle = acos(up_vector.dot(direction))
					spike.transform.basis = Basis(axis, angle)
				
				spike.operation = CSGShape3D.OPERATION_UNION
				core.add_child(spike)
		
		2:  # Mixed pattern (bumps and holes)
			var num_features = randi() % 40 + 20
			
			for i in range(num_features):
				var phi = randf() * PI * 2
				var theta = randf() * PI
				var r = core.radius
				
				var x = r * sin(theta) * cos(phi)
				var y = r * sin(theta) * sin(phi)
				var z = r * cos(theta)
				var position = Vector3(x, y, z)
				
				if randf() < 0.7:  # 70% bumps, 30% indentations
					var bump = CSGSphere3D.new()
					bump.name = "Bump_" + str(i)
					bump.radius = randf_range(0.04, 0.08)
					bump.position = position
					bump.operation = CSGShape3D.OPERATION_UNION
					bump.material = pattern_material
					core.add_child(bump)
				else:
					var indent = CSGSphere3D.new()
					indent.name = "Indent_" + str(i)
					indent.radius = randf_range(0.05, 0.09)
					indent.position = position
					indent.operation = CSGShape3D.OPERATION_SUBTRACTION
					core.add_child(indent)
	
	# Add germ pores (openings) for some pollen types
	if randf() < 0.4:  # 40% chance
		var num_pores = randi() % 3 + 1
		var pore_angles = []
		
		# Generate evenly spaced angles
		for i in range(num_pores):
			pore_angles.append(2 * PI * i / num_pores)
		
		for angle in pore_angles:
			var pore = CSGSphere3D.new()
			pore.name = "Pore"
			pore.radius = randf_range(0.12, 0.18)
			
			# Position on equator
			var pore_pos = Vector3(
				core.radius * cos(angle),
				core.radius * sin(angle),
				0
			)
			
			pore.position = pore_pos
			pore.operation = CSGShape3D.OPERATION_SUBTRACTION
			core.add_child(pore)
			
			# Add rim around pore
			var rim = CSGTorus3D.new()
			rim.name = "PoreRim"
			rim.inner_radius = pore.radius - 0.03
			rim.outer_radius = pore.radius + 0.02
			rim.position = pore_pos
			
			# Rotate to align with pore
			rim.rotation.x = PI * 0.5
			rim.rotation.z = angle
			
			rim.operation = CSGShape3D.OPERATION_UNION
			rim.material = pattern_material
			core.add_child(rim)
	
	parent.add_child(form)
	return form

# Utility functions

func create_approximate_icosahedron(radius, detail):
	# We'll use a sphere with facets to approximate
	var mesh = CSGSphere3D.new()
	mesh.name = "IcosahedronMesh"
	mesh.radius = radius
	mesh.radial_segments = detail
	mesh.rings = detail
	return mesh

func generate_icosahedron_vertices(radius):
	# Golden ratio
	var phi = (1.0 + sqrt(5.0)) / 2.0
	var vertices = []
	
	# 12 vertices of icosahedron
	vertices.append(Vector3(0, phi, 1).normalized() * radius)
	vertices.append(Vector3(0, phi, -1).normalized() * radius)
	vertices.append(Vector3(0, -phi, 1).normalized() * radius)
	vertices.append(Vector3(0, -phi, -1).normalized() * radius)
	
	vertices.append(Vector3(1, 0, phi).normalized() * radius)
	vertices.append(Vector3(-1, 0, phi).normalized() * radius)
	vertices.append(Vector3(1, 0, -phi).normalized() * radius)
	vertices.append(Vector3(-1, 0, -phi).normalized() * radius)
	
	vertices.append(Vector3(phi, 1, 0).normalized() * radius)
	vertices.append(Vector3(phi, -1, 0).normalized() * radius)
	vertices.append(Vector3(-phi, 1, 0).normalized() * radius)
	vertices.append(Vector3(-phi, -1, 0).normalized() * radius)
	
	return vertices

func generate_dodecahedron_vertices(radius):
	# Golden ratio
	var phi = (1.0 + sqrt(5.0)) / 2.0
	var vertices = []
	
	# 20 vertices of dodecahedron
	vertices.append(Vector3(1, 1, 1).normalized() * radius)
	vertices.append(Vector3(1, 1, -1).normalized() * radius)
	vertices.append(Vector3(1, -1, 1).normalized() * radius)
	vertices.append(Vector3(1, -1, -1).normalized() * radius)
	vertices.append(Vector3(-1, 1, 1).normalized() * radius)
	vertices.append(Vector3(-1, 1, -1).normalized() * radius)
	vertices.append(Vector3(-1, -1, 1).normalized() * radius)
	vertices.append(Vector3(-1, -1, -1).normalized() * radius)
	
	vertices.append(Vector3(0, phi, 1/phi).normalized() * radius)
	vertices.append(Vector3(0, phi, -1/phi).normalized() * radius)
	vertices.append(Vector3(0, -phi, 1/phi).normalized() * radius)
	vertices.append(Vector3(0, -phi, -1/phi).normalized() * radius)
	
	vertices.append(Vector3(1/phi, 0, phi).normalized() * radius)
	vertices.append(Vector3(-1/phi, 0, phi).normalized() * radius)
	vertices.append(Vector3(1/phi, 0, -phi).normalized() * radius)
	vertices.append(Vector3(-1/phi, 0, -phi).normalized() * radius)
	
	vertices.append(Vector3(phi, 1/phi, 0).normalized() * radius)
	vertices.append(Vector3(phi, -1/phi, 0).normalized() * radius)
	vertices.append(Vector3(-phi, 1/phi, 0).normalized() * radius)
	vertices.append(Vector3(-phi, -1/phi, 0).normalized() * radius)
	
	return vertices

func setup_environment():
	# Create a camera for viewing
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 3, 5)
	camera.look_at(Vector3(0, 0, 0))
	add_child(camera)
	
	# Create directional light
	var light = DirectionalLight3D.new()
	light.name = "MainLight"
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3(0, 0, 0))
	add_child(light)
	
	# Add secondary light for better visibility
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-3, 2, -3)
	fill_light.look_at(Vector3(0, 0, 0))
	fill_light.light_energy = 0.5
	add_child(fill_light)
	
	# Create environment
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_energy = 0.5
	
	var world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
