extends Node3D
class_name RhizomaticMazeSpace

## 3D Rhizomatic Maze Generator for Godot 4 VR
## Creates interconnected organic tunnel networks with maze-like properties
## Builds on the existing marching cubes and rhizomatic cave systems

@export var maze_size: Vector3 = Vector3(40, 20, 40)
@export var path_width: float = 2.5
@export var branch_probability: float = 0.7
@export var connection_probability: float = 0.4
@export var vertical_layers: int = 3
@export var organic_distortion: float = 0.8
@export var generation_seed: int = -1

# Rhizomatic growth parameters
@export var growth_iterations: int = 200
@export var merge_threshold: float = 6.0
@export var chamber_probability: float = 0.15
@export var deadend_pruning: float = 0.3

# Visual and material settings
@export var tunnel_segments: int = 8  # Sides per tunnel cylinder
@export var surface_detail_level: int = 3

# Core systems
var maze_generator: RhizomaticMazeGenerator
var path_network: RhizomaticPathNetwork
var mesh_builder: OrganicMeshBuilder
var material_system: RhizomaticMaterials

# Generated elements
var environment_container: Node3D
var path_meshes: Array[MeshInstance3D] = []
var navigation_nodes: Array[Vector3] = []

# Noise systems for organic variation
var path_noise: FastNoiseLite
var surface_noise: FastNoiseLite

func _ready():
	setup_noise_systems()
	setup_components()
	generate_rhizomatic_maze()

func setup_noise_systems():
	"""Initialize noise for organic path variation"""
	var seed = generation_seed if generation_seed >= 0 else randi()
	
	# Path deformation noise
	path_noise = FastNoiseLite.new()
	path_noise.seed = seed
	path_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	path_noise.frequency = 0.05
	#path_noise.amplitude = organic_distortion
	
	# Surface detail noise
	surface_noise = FastNoiseLite.new()
	surface_noise.seed = seed + 1000
	surface_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	surface_noise.frequency = 0.15

func setup_components():
	"""Initialize all generation systems"""
	# Main container
	environment_container = Node3D.new()
	environment_container.name = "RhizomaticMaze"
	add_child(environment_container)
	
	# Core systems
	maze_generator = RhizomaticMazeGenerator.new()
	path_network = RhizomaticPathNetwork.new()
	mesh_builder = OrganicMeshBuilder.new()
	material_system = RhizomaticMaterials.new()
	
	add_child(maze_generator)
	add_child(path_network)
	add_child(mesh_builder)
	add_child(material_system)
	
	# Configure systems
	maze_generator.configure({
		"size": maze_size,
		"seed": generation_seed,
		"iterations": growth_iterations,
		"branch_prob": branch_probability,
		"merge_threshold": merge_threshold
	})

func generate_rhizomatic_maze():
	"""Generate the complete rhizomatic maze system"""
	print("🌿 RhizomaticMazeSpace: Starting generation...")
	
	# 1. Generate base network structure
	generate_network_structure()
	
	# 2. Create rhizomatic paths
	create_rhizomatic_paths()
	
	# 3. Add organic chambers
	create_chamber_spaces()
	
	# 4. Build tunnel meshes
	build_tunnel_system()
	
	# 5. Add surface details and branching
	add_organic_details()
	
	# 6. Create navigation waypoints
	generate_navigation_system()
	
	print("✅ RhizomaticMazeSpace: Generation complete!")

func generate_network_structure():
	"""Create the underlying rhizomatic network"""
	# Create growth seeds across vertical layers
	var growth_seeds: Array[Vector3] = []
	
	for layer in range(vertical_layers):
		var layer_y = (float(layer) / (vertical_layers - 1) - 0.5) * maze_size.y
		var seeds_per_layer = 2 + layer * 2  # More seeds in upper layers
		
		for i in range(seeds_per_layer):
			var angle = i * TAU / seeds_per_layer + randf() * 0.5
			var radius = randf_range(maze_size.x * 0.2, maze_size.x * 0.4)
			
			var seed_pos = Vector3(
				cos(angle) * radius,
				layer_y + randf_range(-2, 2),
				sin(angle) * radius
			)
			growth_seeds.append(seed_pos)
	
	# Generate rhizomatic network from seeds
	maze_generator.initialize_growth_points(growth_seeds)
	var network = maze_generator.generate_rhizomatic_network()
	path_network.set_network_data(network)
	
	print("🌱 Network structure: %d nodes, %d connections" % [network.nodes.size(), network.connections.size()])

func create_rhizomatic_paths():
	"""Create organic tunnel paths through the network"""
	var connections = path_network.get_all_connections()
	
	for connection in connections:
		create_organic_tunnel(connection.start, connection.end, connection.properties)

func create_organic_tunnel(start: Vector3, end: Vector3, properties: Dictionary):
	"""Create a single organic tunnel segment"""
	var distance = start.distance_to(end)
	var segments = max(4, int(distance / 2.0))  # More segments for longer tunnels
	
	# Generate organic path points
	var path_points = generate_organic_path(start, end, segments)
	
	# Create tunnel mesh along path
	var tunnel_mesh = create_tunnel_mesh(path_points, properties)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = tunnel_mesh
	mesh_instance.material_override = material_system.get_tunnel_material(properties)
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	
	environment_container.add_child(mesh_instance)
	path_meshes.append(mesh_instance)

func generate_organic_path(start: Vector3, end: Vector3, segments: int) -> Array[Vector3]:
	"""Generate organic path with noise-based deformation"""
	var points: Array[Vector3] = []
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var base_point = start.lerp(end, t)
		
		# Add organic displacement perpendicular to main direction
		var perpendicular1 = direction.cross(Vector3.UP).normalized()
		var perpendicular2 = direction.cross(perpendicular1).normalized()
		
		var noise_offset = Vector3(
			path_noise.get_noise_3d(base_point.x, base_point.y, base_point.z) * organic_distortion,
			path_noise.get_noise_3d(base_point.x + 100, base_point.y, base_point.z) * organic_distortion * 0.5,
			path_noise.get_noise_3d(base_point.x, base_point.y, base_point.z + 100) * organic_distortion
		)
		
		# Apply smooth falloff at endpoints
		var falloff = sin(t * PI)
		noise_offset *= falloff
		
		points.append(base_point + noise_offset)
	
	return points

func create_tunnel_mesh(path_points: Array[Vector3], properties: Dictionary) -> ArrayMesh:
	"""Create tube mesh following the organic path"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var radius = path_width * 0.5
	if properties.has("width_multiplier"):
		radius *= properties.width_multiplier
	
	# Generate tube geometry
	for i in range(path_points.size() - 1):
		var current_point = path_points[i]
		var next_point = path_points[i + 1]
		var forward = (next_point - current_point).normalized()
		
		# Create cross-section
		var right = forward.cross(Vector3.UP).normalized()
		if right.length() < 0.1:  # Handle vertical segments
			right = Vector3.RIGHT
		var up = forward.cross(right).normalized()
		
		# Add radius variation based on noise
		var noise_radius = radius * (1.0 + surface_noise.get_noise_3d(
			current_point.x, current_point.y, current_point.z
		) * 0.3)
		
		# Create ring of vertices
		for j in range(tunnel_segments):
			var angle = j * TAU / tunnel_segments
			var ring_offset = right * cos(angle) * noise_radius + up * sin(angle) * noise_radius
			var vertex = current_point + ring_offset
			
			vertices.append(vertex)
			normals.append(ring_offset.normalized())
			uvs.append(Vector2(float(j) / tunnel_segments, float(i) / (path_points.size() - 1)))
	
	# Generate indices for tube
	for i in range(path_points.size() - 2):
		for j in range(tunnel_segments):
			var current_ring_start = i * tunnel_segments
			var next_ring_start = (i + 1) * tunnel_segments
			
			var v0 = current_ring_start + j
			var v1 = current_ring_start + (j + 1) % tunnel_segments
			var v2 = next_ring_start + j
			var v3 = next_ring_start + (j + 1) % tunnel_segments
			
			# Two triangles per quad
			indices.append_array([v0, v2, v1, v1, v2, v3])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

func create_chamber_spaces():
	"""Create larger chamber spaces at network nodes"""
	var nodes = path_network.get_chamber_nodes()
	
	for node in nodes:
		if randf() < chamber_probability:
			create_organic_chamber(node.position, node.properties)

func create_organic_chamber(center: Vector3, properties: Dictionary):
	"""Create an organic chamber space"""
	var chamber_radius = randf_range(4.0, 8.0)
	var chamber_height = chamber_radius * randf_range(0.7, 1.3)
	
	# Create base chamber shape
	var chamber = CSGSphere3D.new()
	chamber.radius = chamber_radius
	chamber.position = center
	chamber.material = material_system.get_chamber_material()
	
	# Add organic deformation
	for i in range(randi_range(3, 7)):
		var deform_sphere = CSGSphere3D.new()
		deform_sphere.radius = chamber_radius * randf_range(0.3, 0.8)
		
		var angle = randf() * TAU
		var elevation = randf_range(-PI * 0.3, PI * 0.3)
		var distance = chamber_radius * randf_range(0.6, 1.2)
		
		deform_sphere.position = Vector3(
			cos(angle) * cos(elevation) * distance,
			sin(elevation) * distance,
			sin(angle) * cos(elevation) * distance
		)
		
		deform_sphere.operation = CSGShape3D.OPERATION_UNION if randf() > 0.3 else CSGShape3D.OPERATION_SUBTRACTION
		chamber.add_child(deform_sphere)
	
	environment_container.add_child(chamber)

func build_tunnel_system():
	"""Build the main tunnel system meshes"""
	# This is handled in create_rhizomatic_paths()
	print("🏗️ Built %d tunnel segments" % path_meshes.size())

func add_organic_details():
	"""Add organic surface details and growth"""
	add_surface_growths()
	add_hanging_elements()
	add_organic_textures()

func add_surface_growths():
	"""Add small organic growths to tunnel walls"""
	for mesh_instance in path_meshes:
		var growth_count = randi_range(2, 6)
		
		for i in range(growth_count):
			var growth = CSGSphere3D.new()
			growth.radius = randf_range(0.3, 1.2)
			
			# Random position relative to tunnel
			growth.position = Vector3(
				randf_range(-path_width, path_width),
				randf_range(-path_width * 0.5, path_width * 0.5),
				randf_range(-2, 2)
			)
			
			growth.material = material_system.get_growth_material()
			mesh_instance.add_child(growth)

func add_hanging_elements():
	"""Add hanging organic elements like roots or tendrils"""
	var hanging_count = randi_range(5, 12)
	
	for i in range(hanging_count):
		var hanging_pos = Vector3(
			randf_range(-maze_size.x * 0.4, maze_size.x * 0.4),
			maze_size.y * 0.4,  # Start from ceiling
			randf_range(-maze_size.z * 0.4, maze_size.z * 0.4)
		)
		
		create_hanging_tendril(hanging_pos)

func create_hanging_tendril(start_pos: Vector3):
	"""Create a hanging organic tendril"""
	var segments = randi_range(8, 15)
	var current_pos = start_pos
	var direction = Vector3.DOWN
	
	for i in range(segments):
		var segment = CSGCylinder3D.new()
		segment.height = 1.0
		segment.radius = randf_range(0.1, 0.3) * (1.0 - float(i) / segments)  # Taper
		#segment.bottom_radius = segment.top_radius * 0.8
		
		# Add organic sway
		direction += Vector3(
			surface_noise.get_noise_3d(current_pos.x, current_pos.y, i * 0.5) * 0.2,
			-0.8,  # Gravity
			surface_noise.get_noise_3d(current_pos.x + 50, current_pos.y, i * 0.5) * 0.2
		).normalized()
		
		current_pos += direction * segment.height
		segment.position = current_pos
		segment.material = material_system.get_tendril_material()
		
		environment_container.add_child(segment)

func add_organic_textures():
	"""Apply organic texture variations to surfaces"""
	# This would integrate with your material system
	pass

func generate_navigation_system():
	"""Create navigation waypoints for AI or player guidance"""
	navigation_nodes.clear()
	
	# Add waypoints at tunnel intersections
	var intersections = path_network.get_intersection_points()
	for intersection in intersections:
		navigation_nodes.append(intersection)
	
	# Add waypoints along major paths
	var major_paths = path_network.get_major_paths()
	for path in major_paths:
		var waypoint_spacing = 5.0
		var distance = 0.0
		
		for i in range(path.points.size() - 1):
			var segment_length = path.points[i].distance_to(path.points[i + 1])
			if distance >= waypoint_spacing:
				navigation_nodes.append(path.points[i])
				distance = 0.0
			distance += segment_length
	
	print("🧭 Generated %d navigation waypoints" % navigation_nodes.size())

func get_navigation_nodes() -> Array[Vector3]:
	"""Get all navigation waypoints for external systems"""
	return navigation_nodes

func regenerate_maze():
	"""Regenerate the entire maze with new seed"""
	# Clear existing
	if environment_container:
		environment_container.queue_free()
	
	path_meshes.clear()
	navigation_nodes.clear()
	
	# Regenerate with new seed
	generation_seed = randi()
	await get_tree().process_frame
	setup_noise_systems()
	setup_components()
	generate_rhizomatic_maze()
