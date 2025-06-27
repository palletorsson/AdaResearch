# MarchingCubesTestController.gd
# Test controller for verifying marching cubes algorithm functionality
# Creates simple test shapes to validate mesh generation

extends Node3D

func _ready():
	print("🧪 Marching Cubes Test: Starting tests...")
	test_basic_sphere()
	test_voxel_chunk()
	test_rhizome_generation()

func test_basic_sphere():
	"""Test basic marching cubes with a simple sphere"""
	print("Testing basic sphere generation...")
	
	# Create a simple voxel chunk
	var chunk = VoxelChunk.new(Vector3i(16, 16, 16), Vector3(-8, -8, -8), 1.0)
	
	# Fill with sphere density field
	for x in range(17):
		for y in range(17):
			for z in range(17):
				var world_pos = chunk.local_to_world(Vector3i(x, y, z))
				var distance = world_pos.length()
				var density = 1.0 - (distance / 6.0)  # Sphere radius = 6
				chunk.set_density(Vector3i(x, y, z), density)
	
	# Generate mesh
	var generator = MarchingCubesGenerator.new()
	var mesh = generator.generate_mesh_from_chunk(chunk)
	
	if mesh != null and mesh.get_surface_count() > 0:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.name = "TestSphere"
		mesh_instance.position = Vector3(-15, 0, 0)
		
		# Create vibrant, lush material with queer aesthetic
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(0.8, 0.9, 1.0)  # Bright magenta
		material.metallic = 0.3
		material.roughness = 0.2
		material.emission_enabled = true
		material.emission = Color.from_hsv(0.5, 0.6, 0.4)  # Cyan glow
		material.emission_energy = 0.8
		material.rim_enabled = true
		material.rim_tint = 0.3
		material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Make double-sided
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		print("✅ Sphere test passed - mesh generated")
	else:
		print("❌ Sphere test failed - no mesh generated")

func test_voxel_chunk():
	"""Test voxel chunk functionality"""
	print("Testing voxel chunk operations...")
	
	var chunk = VoxelChunk.new(Vector3i(8, 8, 8), Vector3.ZERO, 1.0)
	
	# Test basic operations
	chunk.set_density(Vector3i(4, 4, 4), 0.5)
	var density = chunk.get_density(Vector3i(4, 4, 4))
	
	if abs(density - 0.5) < 0.001:
		print("✅ Voxel chunk basic operations test passed")
	else:
		print("❌ Voxel chunk test failed - density mismatch")
	
	# Test sphere carving
	chunk.fill_sphere(Vector3(4, 4, 4), 3.0, 0.0)
	var carved_density = chunk.get_density(Vector3i(4, 4, 4))
	
	if carved_density < 0.1:
		print("✅ Sphere carving test passed")
	else:
		print("❌ Sphere carving test failed")

func test_rhizome_generation():
	"""Test basic rhizome pattern generation"""
	print("Testing rhizome growth pattern...")
	
	var rhizome = RhizomeGrowthPattern.new(42)
	rhizome.add_growth_node(Vector3.ZERO, 2.0)
	
	rhizome.set_growth_rules({
		"branch_probability": 0.5,
		"merge_distance": 5.0,
		"max_depth": 3
	})
	
	var network = rhizome.generate_rhizome_network(10)
	
	if network.all_nodes.size() > 1:
		print("✅ Rhizome generation test passed - %d nodes created" % network.all_nodes.size())
		
		# Create a simple visualization
		create_rhizome_visualization(network)
	else:
		print("❌ Rhizome generation test failed")

func create_rhizome_visualization(network: Dictionary):
	"""Create a vibrant visualization of the rhizome network"""
	print("Creating rhizome visualization...")
	
	# Create node spheres with rainbow colors
	for i in range(network.all_nodes.size()):
		var node = network.all_nodes[i]
		var hue = float(i) / float(network.all_nodes.size())  # Rainbow progression
		var node_color = Color.from_hsv(hue, 0.8, 1.0)  # Bright rainbow colors
		var chamber_color = Color.from_hsv(hue, 1.0, 1.0) if node.is_chamber else node_color
		
		var sphere = create_debug_sphere(node.position, node.radius * 0.15, chamber_color)  # Slightly larger
		sphere.name = "RhizomeNode_%d" % i
		sphere.position.x += 15  # Offset from other tests
		add_child(sphere)
	
	# Create connection lines with gradient colors
	for i in range(network.connections.size()):
		var connection = network.connections[i]
		var connection_hue = float(i) / float(network.connections.size())
		var line_color = Color.from_hsv(connection_hue, 0.6, 1.0)  # Bright connection colors
		var line = create_debug_line(connection.start, connection.end, line_color)
		line.name = "RhizomeConnection_%d" % i
		line.position.x += 15  # Match node offset
		add_child(line)
	
	print("✅ Vibrant rhizome visualization created")

func create_debug_sphere(position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	"""Create a vibrant debug sphere for visualization"""
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = max(radius, 0.1)
	sphere_mesh.height = max(radius * 2, 0.2)
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.3
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = color * 0.5  # Glowing effect
	material.emission_energy = 0.8
	material.rim_enabled = true
	material.rim_tint = 0.3
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func create_debug_line(start: Vector3, end: Vector3, color: Color) -> MeshInstance3D:
	"""Create a vibrant debug line for visualization"""
	var mesh_instance = MeshInstance3D.new()
	var line_mesh = ArrayMesh.new()
	
	var vertices = PackedVector3Array()
	vertices.append(start)
	vertices.append(end)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = line_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.8  # Strong glow for lines
	material.emission_energy = 1.2
	material.flags_unshaded = true
	material.flags_transparent = false
	material.vertex_color_use_as_albedo = false
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance 
