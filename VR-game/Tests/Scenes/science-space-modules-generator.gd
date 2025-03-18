extends Node3D

# Ada Research: Science Space Modules Generator
# This script procedurally creates all the 3D models needed for the Ada Research project
# and saves them as reusable scenes that can be used with the Wave Function Collapse algorithm

# Configuration
@export_category("Module Settings")
@export var save_modules: bool = true
@export var generate_on_ready: bool = true
@export_dir var modules_path: String = "res://adaresearch/Tests/modules/"

@export_category("Material Settings")
@export var create_materials: bool = true
@export var use_emission: bool = true

# Internal variables
var materials = {}

func _ready():
	if generate_on_ready:
		create_all()

func create_all():
	# Create all materials
	if create_materials:
		create_all_materials()
	
	# Create basic modules
	var empty = create_empty_module()
	empty.position = Vector3(-4, 0, 0)
	
	var cube = create_cube_module()
	cube.position = Vector3(-2, 0, 0)
	
	var cylinder = create_cylinder_module()
	cylinder.position = Vector3(0, 0, 0)
	
	var sphere = create_sphere_module()
	sphere.position = Vector3(2, 0, 0)
	
	# Create science modules
	var dna = create_dna_module()
	dna.position = Vector3(4, 0, 0)
	
	var atom = create_atom_module()
	atom.position = Vector3(6, 0, 0)
	
	var crystal = create_crystal_module()
	crystal.position = Vector3(8, 0, 0)
	
	var neuron = create_neuron_module()
	neuron.position = Vector3(10, 0, 0)
	
	var fractal = create_fractal_module()
	fractal.position = Vector3(12, 0, 0)
	
	# Save all modules if needed
	if save_modules:
		save_module_scene(empty, "empty")
		save_module_scene(cube, "cube")
		save_module_scene(cylinder, "cylinder")
		save_module_scene(sphere, "sphere")
		save_module_scene(dna, "dna")
		save_module_scene(atom, "atom")
		save_module_scene(crystal, "crystal")
		save_module_scene(neuron, "neuron")
		save_module_scene(fractal, "fractal")
	
	print("Ada Research modules created successfully!")

func create_all_materials():
	# Create basic materials
	materials["empty"] = create_material("empty", Color(0.9, 0.9, 0.9), 0.0, 0.5, true)
	materials["cube"] = create_material("cube", Color(0.2, 0.4, 0.8))
	materials["cylinder"] = create_material("cylinder", Color(0.8, 0.2, 0.4))
	materials["sphere"] = create_material("sphere", Color(0.3, 0.8, 0.3))
	
	# Create science materials
	materials["science_blue"] = create_material("science_blue", Color(0.1, 0.3, 0.8), 0.9, 0.1)
	materials["science_green"] = create_material("science_green", Color(0.1, 0.7, 0.3), 0.0, 0.5, use_emission)
	materials["science_red"] = create_material("science_red", Color(0.8, 0.1, 0.1), 0.0, 0.1)
	materials["science_purple"] = create_material("science_purple", Color(0.6, 0.1, 0.8), 0.0, 0.3, use_emission)
	materials["science_gold"] = create_material("science_gold", Color(0.8, 0.7, 0.2), 1.0, 0.1)
	materials["connector"] = create_material("connector", Color(0.8, 0.8, 0.2), 0.5, 0.2)

func create_material(name: String, color: Color, metallic: float = 0.0, roughness: float = 0.5, transparent: bool = false) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.resource_name = name
	
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.alpha_scissor_threshold = 0.5
		color.a = 0.3
		material.albedo_color = color
	
	if use_emission and name in ["science_green", "science_purple"]:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
	
	return material

func add_connection_points(parent_node: Node3D, radius: float = 0.05) -> void:
	# Add connection points at each face of the module
	var directions = {
		"pos_x": Vector3(0.5, 0, 0),
		"neg_x": Vector3(-0.5, 0, 0),
		"pos_y": Vector3(0, 0.5, 0),
		"neg_y": Vector3(0, -0.5, 0),
		"pos_z": Vector3(0, 0, 0.5),
		"neg_z": Vector3(0, 0, -0.5)
	}
	
	for dir in directions:
		var connector = MeshInstance3D.new()
		connector.name = "connector_" + dir
		connector.mesh = SphereMesh.new()
		connector.mesh.radius = radius
		connector.mesh.height = radius * 2
		connector.position = directions[dir]
		
		if "connector" in materials:
			connector.material_override = materials["connector"]
		
		parent_node.add_child(connector)

func create_empty_module() -> Node3D:
	var root = Node3D.new()
	root.name = "empty"
	
	# Create wireframe cube
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "wireframe"
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(0.95, 0.95, 0.95)
	
	if "empty" in materials:
		mesh_instance.material_override = materials["empty"]
	
	root.add_child(mesh_instance)
	add_connection_points(root)
	
	return root

func create_cube_module() -> Node3D:
	var root = Node3D.new()
	root.name = "cube"
	
	# Create cube
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "cube_mesh"
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(0.95, 0.95, 0.95)
	
	if "cube" in materials:
		mesh_instance.material_override = materials["cube"]
	
	root.add_child(mesh_instance)
	add_connection_points(root)
	
	return root

func create_cylinder_module() -> Node3D:
	var root = Node3D.new()
	root.name = "cylinder"
	
	# Create cylinder
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "cylinder_mesh"
	mesh_instance.mesh = CylinderMesh.new()
	mesh_instance.mesh.top_radius = 0.45
	mesh_instance.mesh.bottom_radius = 0.45
	mesh_instance.mesh.height = 0.95
	
	if "cylinder" in materials:
		mesh_instance.material_override = materials["cylinder"]
	
	root.add_child(mesh_instance)
	add_connection_points(root)
	
	return root

func create_sphere_module() -> Node3D:
	var root = Node3D.new()
	root.name = "sphere"
	
	# Create sphere
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "sphere_mesh"
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = 0.45
	mesh_instance.mesh.height = 0.9
	
	if "sphere" in materials:
		mesh_instance.material_override = materials["sphere"]
	
	root.add_child(mesh_instance)
	add_connection_points(root)
	
	return root

func create_dna_module() -> Node3D:
	var root = Node3D.new()
	root.name = "dna"
	
	# Create main axis
	var axis = MeshInstance3D.new()
	axis.name = "main_axis"
	axis.mesh = CylinderMesh.new()
	axis.mesh.top_radius = 0.05
	axis.mesh.bottom_radius = 0.05
	axis.mesh.height = 0.95
	
	if "science_blue" in materials:
		axis.material_override = materials["science_blue"]
	
	root.add_child(axis)
	
	# Create DNA helix
	var helix_points = 20
	var radius = 0.3
	
	for i in range(helix_points):
		# First strand
		var angle1 = (float(i) / helix_points) * 2.0 * PI
		var x1 = radius * cos(angle1)
		var y1 = radius * sin(angle1)
		var z1 = (float(i) / helix_points - 0.5) * 0.95
		
		var sphere1 = MeshInstance3D.new()
		sphere1.name = "nucleotide1_" + str(i)
		sphere1.mesh = SphereMesh.new()
		sphere1.mesh.radius = 0.05
		sphere1.mesh.height = 0.1
		sphere1.position = Vector3(x1, y1, z1)
		
		if "science_red" in materials:
			sphere1.material_override = materials["science_red"]
		
		root.add_child(sphere1)
		
		# Second strand (offset by 180 degrees)
		var angle2 = angle1 + PI
		var x2 = radius * cos(angle2)
		var y2 = radius * sin(angle2)
		
		var sphere2 = MeshInstance3D.new()
		sphere2.name = "nucleotide2_" + str(i)
		sphere2.mesh = SphereMesh.new()
		sphere2.mesh.radius = 0.05
		sphere2.mesh.height = 0.1
		sphere2.position = Vector3(x2, y2, z1)
		
		if "science_green" in materials:
			sphere2.material_override = materials["science_green"]
		
		root.add_child(sphere2)
		
		# Create base pairs (connections between strands)
		if i % 2 == 0:
			var connector = MeshInstance3D.new()
			connector.name = "base_pair_" + str(i)
			connector.mesh = CylinderMesh.new()
			connector.mesh.top_radius = 0.02
			connector.mesh.bottom_radius = 0.02
			connector.mesh.height = radius * 2
			
			# Position at midpoint between nucleotides
			connector.position = Vector3((x1 + x2) / 2, (y1 + y2) / 2, z1)
			
			# Rotate to connect the nucleotides
			var dir = Vector3(x2 - x1, y2 - y1, 0).normalized()
			var up = Vector3(0, 0, 1)
			var axis_rot = up.cross(dir).normalized()
			var angle = acos(up.dot(dir))
			connector.rotation = Vector3(0, 0, angle)
			
			if "science_purple" in materials:
				connector.material_override = materials["science_purple"]
			
			root.add_child(connector)
	
	add_connection_points(root)
	return root

func create_atom_module() -> Node3D:
	var root = Node3D.new()
	root.name = "atom"
	
	# Create nucleus
	var nucleus = MeshInstance3D.new()
	nucleus.name = "nucleus"
	nucleus.mesh = SphereMesh.new()
	nucleus.mesh.radius = 0.15
	nucleus.mesh.height = 0.3
	
	if "science_gold" in materials:
		nucleus.material_override = materials["science_gold"]
	
	root.add_child(nucleus)
	
	# Create electron orbits
	for i in range(3):
		var radius = 0.3 + i * 0.1
		
		# Create orbit path
		var orbit_path = MeshInstance3D.new()
		orbit_path.name = "orbit_" + str(i)
		orbit_path.mesh = TorusMesh.new()
		orbit_path.mesh.inner_radius = 0.005
		orbit_path.mesh.outer_radius = radius
		
		# Rotate orbit to different plane
		orbit_path.rotation = Vector3(i * PI/3, i * PI/4, 0)
		
		if "science_blue" in materials:
			orbit_path.material_override = materials["science_blue"]
		
		root.add_child(orbit_path)
		
		# Add electrons along orbit
		for j in range(3 + i):
			var angle = (float(j) / (3 + i)) * 2.0 * PI
			var electron_pos = Vector3(
				radius * cos(angle),
				radius * sin(angle),
				0
			)
			
			# Rotate according to orbit's rotation
			electron_pos = electron_pos.rotated(Vector3(1, 0, 0), orbit_path.rotation.x)
			electron_pos = electron_pos.rotated(Vector3(0, 1, 0), orbit_path.rotation.y)
			
			var electron = MeshInstance3D.new()
			electron.name = "electron_" + str(i) + "_" + str(j)
			electron.mesh = SphereMesh.new()
			electron.mesh.radius = 0.03
			electron.mesh.height = 0.06
			electron.position = electron_pos
			
			if "science_green" in materials:
				electron.material_override = materials["science_green"]
			
			root.add_child(electron)
	
	add_connection_points(root)
	return root

func create_crystal_module() -> Node3D:
	var root = Node3D.new()
	root.name = "crystal"
	
	# Create center node
	var center = MeshInstance3D.new()
	center.name = "center"
	center.mesh = BoxMesh.new()
	center.mesh.size = Vector3(0.05, 0.05, 0.05)
	
	if "science_blue" in materials:
		center.material_override = materials["science_blue"]
	
	root.add_child(center)
	
	# Create lattice points
	var points = []
	var positions = []
	
	for x in [-0.35, 0, 0.35]:
		for y in [-0.35, 0, 0.35]:
			for z in [-0.35, 0, 0.35]:
				# Skip center (already created)
				if x == 0 and y == 0 and z == 0:
					continue
				
				var point = MeshInstance3D.new()
				point.name = "point_" + str(x) + "_" + str(y) + "_" + str(z)
				point.mesh = BoxMesh.new()
				point.mesh.size = Vector3(0.05, 0.05, 0.05)
				point.position = Vector3(x, y, z)
				
				if "science_blue" in materials:
					point.material_override = materials["science_blue"]
				
				root.add_child(point)
				points.append(point)
				positions.append(Vector3(x, y, z))
	
	# Create connections between adjacent points
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var pos1 = positions[i]
			var pos2 = positions[j]
			
			# Calculate distance
			var dist = pos1.distance_to(pos2)
			
			# Connect if points are adjacent (approximately 0.35 units apart)
			if dist >= 0.34 and dist <= 0.36:
				var midpoint = (pos1 + pos2) / 2
				
				var connector = MeshInstance3D.new()
				connector.name = "connection_" + str(i) + "_" + str(j)
				connector.mesh = CylinderMesh.new()
				connector.mesh.top_radius = 0.02
				connector.mesh.bottom_radius = 0.02
				connector.mesh.height = dist
				connector.position = midpoint
				
				# Calculate direction to align cylinder
				var direction = (pos2 - pos1).normalized()
				
				# Find rotation to align cylinder with direction
				var up_vector = Vector3(0, 0, 1)
				if abs(direction.dot(up_vector)) > 0.99:
					# Special case when direction is parallel to up vector
					up_vector = Vector3(0, 1, 0)
				
				var axis = up_vector.cross(direction).normalized()
				var angle = acos(up_vector.dot(direction))
				
				if axis.length() > 0:
					connector.rotation = Vector3(
						axis.x * angle,
						axis.y * angle,
						axis.z * angle
					)
				
				if "science_red" in materials:
					connector.material_override = materials["science_red"]
				
				root.add_child(connector)
	
	add_connection_points(root)
	return root

func create_neuron_module() -> Node3D:
	var root = Node3D.new()
	root.name = "neuron"
	
	# Create soma (cell body)
	var soma = MeshInstance3D.new()
	soma.name = "soma"
	soma.mesh = SphereMesh.new()
	soma.mesh.radius = 0.2
	soma.mesh.height = 0.4
	
	if "science_purple" in materials:
		soma.material_override = materials["science_purple"]
	
	root.add_child(soma)
	
	# Create dendrites
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # For reproducible results
	
	for i in range(6):
		# Calculate random direction
		var theta = rng.randf_range(0, PI)
		var phi = rng.randf_range(0, 2 * PI)
		
		var dir = Vector3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta)
		).normalized()
		
		# Create dendrite branch
		var branch_length = rng.randf_range(0.2, 0.4)
		
		var branch = MeshInstance3D.new()
		branch.name = "dendrite_" + str(i)
		branch.mesh = CylinderMesh.new()
		branch.mesh.top_radius = 0.03
		branch.mesh.bottom_radius = 0.03
		branch.mesh.height = branch_length
		
		# Position branch starting at soma surface
		branch.position = dir * 0.2
		
		# Rotate branch to point outward from soma
		var up_vector = Vector3(0, 0, 1)
		var axis = up_vector.cross(dir).normalized()
		var angle = acos(up_vector.dot(dir))
		
		if axis.length() > 0:
			branch.rotation = Vector3(
				axis.x * angle,
				axis.y * angle,
				axis.z * angle
			)
		
		if "science_green" in materials:
			branch.material_override = materials["science_green"]
		
		root.add_child(branch)
		
		# Add terminal bulb to some dendrites
		if rng.randf() > 0.3:
			var end_pos = dir * (0.2 + branch_length)
			
			var terminal = MeshInstance3D.new()
			terminal.name = "terminal_" + str(i)
			terminal.mesh = SphereMesh.new()
			terminal.mesh.radius = 0.05
			terminal.mesh.height = 0.1
			terminal.position = end_pos
			
			if "science_red" in materials:
				terminal.material_override = materials["science_red"]
			
			root.add_child(terminal)
	
	# Create axon
	var axon = MeshInstance3D.new()
	axon.name = "axon"
	axon.mesh = CylinderMesh.new()
	axon.mesh.top_radius = 0.04
	axon.mesh.bottom_radius = 0.04
	axon.mesh.height = 0.6
	axon.position = Vector3(0, 0, -0.3)
	axon.rotation = Vector3(PI/2, 0, 0)
	
	if "science_blue" in materials:
		axon.material_override = materials["science_blue"]
	
	root.add_child(axon)
	
	# Add axon terminal branches
	for i in range(3):
		var angle = (float(i) / 3) * 2.0 * PI
		
		var term_branch = MeshInstance3D.new()
		term_branch.name = "axon_terminal_" + str(i)
		term_branch.mesh = CylinderMesh.new()
		term_branch.mesh.top_radius = 0.02
		term_branch.mesh.bottom_radius = 0.02
		term_branch.mesh.height = 0.15
		term_branch.position = Vector3(0.1 * cos(angle), 0.1 * sin(angle), -0.6)
		term_branch.rotation = Vector3(0, PI/4, angle)
		
		if "science_blue" in materials:
			term_branch.material_override = materials["science_blue"]
		
		root.add_child(term_branch)
		
		# Add terminal bulb
		var end_x = 0.1 * cos(angle) + 0.15 * sin(angle) * sin(angle)
		var end_y = 0.1 * sin(angle) + 0.15 * cos(angle) * sin(angle)
		var end_z = -0.6 - 0.15 * cos(PI/4)
		
		var bulb = MeshInstance3D.new()
		bulb.name = "terminal_bulb_" + str(i)
		bulb.mesh = SphereMesh.new()
		bulb.mesh.radius = 0.04
		bulb.mesh.height = 0.08
		bulb.position = Vector3(end_x, end_y, end_z)
		
		if "science_red" in materials:
			bulb.material_override = materials["science_red"]
		
		root.add_child(bulb)
	
	add_connection_points(root)
	return root

func create_fractal_module() -> Node3D:
	var root = Node3D.new()
	root.name = "fractal"
	
	# Build a simplified Menger sponge (level 1)
	var cube_size = 0.9
	var subcube_size = cube_size / 3.0
	
	# Create all the small cubes except the ones that should be removed
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				# Skip center cube and center of each face
				if (x == 0 and y == 0 and z == 0) or \
				   (x == 0 and y == 0) or \
				   (x == 0 and z == 0) or \
				   (y == 0 and z == 0):
					continue
				
				var subcube = MeshInstance3D.new()
				subcube.name = "subcube_" + str(x) + "_" + str(y) + "_" + str(z)
				subcube.mesh = BoxMesh.new()
				subcube.mesh.size = Vector3(subcube_size, subcube_size, subcube_size)
				subcube.position = Vector3(
					x * subcube_size,
					y * subcube_size,
					z * subcube_size
				)
				
				if "science_gold" in materials:
					subcube.material_override = materials["science_gold"]
				
				root.add_child(subcube)
	
	add_connection_points(root)
	return root

func save_module_scene(module: Node3D, name: String) -> void:
	# Create a new scene with this module
	var scene = PackedScene.new()
	var result = scene.pack(module)
	
	if result == OK:
		# Make sure the directory exists
		var dir = DirAccess.open("res://")
		if not dir.dir_exists(modules_path):
			dir.make_dir(modules_path)
		
		# Save the scene
		var path = modules_path + "/" + name + ".tscn"
		result = ResourceSaver.save(scene, path)
		
		if result == OK:
			print("Successfully saved module: " + path)
		else:
			push_error("Failed to save module: " + path)
	else:
		push_error("Failed to pack module scene: " + name)
