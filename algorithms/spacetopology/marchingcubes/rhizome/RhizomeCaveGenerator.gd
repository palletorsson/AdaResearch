# RhizomeCaveGenerator.gd
# Main orchestrator for rhizomatic cave system generation
# Combines growth patterns, voxel carving, and marching cubes

extends Node3D
class_name RhizomeCaveGenerator

# Components
var growth_pattern: RhizomeGrowthPattern
var marching_cubes: MarchingCubesGenerator
var voxel_chunks: Array[VoxelChunk] = []

# Generation parameters
@export var cave_size: Vector3 = Vector3(100, 40, 100)
@export var chunk_size: Vector3i = Vector3i(16, 16, 16)  # Smaller chunks for better quality
@export var voxel_scale: float = 0.8  # Finer voxel resolution
@export var generation_seed: int = -1

# Cave system parameters
@export var initial_chambers: int = 3
@export var growth_iterations: int = 30  # Reduced for performance
@export var noise_strength: float = 0.2  # Reduced to prevent holes
@export var surface_threshold: float = 0.5

# Generated content
var cave_mesh_instances: Array[MeshInstance3D] = []
var collision_bodies: Array[StaticBody3D] = []

# Noise for organic variation
var cave_noise: FastNoiseLite

signal generation_complete()
signal generation_progress(percentage: float)

func _ready():
	setup_components()

func setup_components():
	"""Initialize all components for cave generation"""
	# Initialize growth pattern generator
	growth_pattern = RhizomeGrowthPattern.new(generation_seed)
	
	# Initialize marching cubes
	marching_cubes = MarchingCubesGenerator.new()
	marching_cubes.threshold = surface_threshold
	
	# Setup noise for organic variation
	cave_noise = FastNoiseLite.new()
	if generation_seed >= 0:
		cave_noise.seed = generation_seed
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.02
	
	print("RhizomeCaveGenerator: Components initialized")

func setup_parameters(params: Dictionary):
	"""Configure generation parameters from dictionary"""
	if params.has("size"):
		cave_size = params.size
	if params.has("chunk_size"):
		chunk_size = params.chunk_size
	if params.has("voxel_scale"):
		voxel_scale = params.voxel_scale
	if params.has("seed"):
		generation_seed = params.seed
		setup_components()  # Reinitialize with new seed
	if params.has("initial_chambers"):
		initial_chambers = params.initial_chambers
	if params.has("growth_iterations"):
		growth_iterations = params.growth_iterations

func configure_rhizome_parameters(rhizome_params: Dictionary):
	"""Configure rhizomatic growth behavior"""
	if growth_pattern != null:
		growth_pattern.set_growth_rules(rhizome_params)

func generate_cave() -> Array[MeshInstance3D]:
	"""Generate the complete cave system and return mesh instances"""
	print("RhizomeCaveGenerator: Starting gradual cave generation...")
	
	# Start async generation
	_generate_cave_async()
	
	return cave_mesh_instances

func generate_cave_async() -> Array[MeshInstance3D]:
	"""Generate the complete cave system asynchronously and return mesh instances"""
	print("RhizomeCaveGenerator: Starting non-blocking cave generation...")
	
	# Start async generation and wait for completion
	await _generate_cave_async()
	
	return cave_mesh_instances

func _generate_cave_async():
	"""Generate cave system asynchronously across multiple frames"""
	# Clear previous generation
	clear_previous_cave()
	
	# Step 1: Generate rhizomatic growth pattern
	print("RhizomeCaveGenerator: Step 1/5 - Generating growth pattern...")
	generate_growth_pattern()
	generation_progress.emit(20.0)
	await get_tree().process_frame  # Wait one frame
	
	# Step 2: Create voxel chunks
	print("RhizomeCaveGenerator: Step 2/5 - Creating voxel grid...")
	create_voxel_grid()
	generation_progress.emit(40.0)
	await get_tree().process_frame
	
	# Step 3: Carve cave system (do this gradually)
	print("RhizomeCaveGenerator: Step 3/5 - Carving cave system...")
	await carve_cave_system_async()
	generation_progress.emit(60.0)
	
	# Step 4: Apply organic variation
	print("RhizomeCaveGenerator: Step 4/5 - Applying organic variation...")
	await apply_organic_variation_async()
	generation_progress.emit(80.0)
	
	# Step 5: Generate meshes (do this gradually)
	print("RhizomeCaveGenerator: Step 5/5 - Generating meshes...")
	await generate_meshes_async()
	generation_progress.emit(95.0)
	
	# Step 6: Create collision bodies
	print("RhizomeCaveGenerator: Creating collision bodies...")
	generate_collision_meshes()
	generation_progress.emit(100.0)
	
	generation_complete.emit()
	print("RhizomeCaveGenerator: Cave generation complete!")

func generate_growth_pattern():
	"""Generate the rhizomatic growth pattern"""
	print("RhizomeCaveGenerator: Generating growth pattern...")
	
	# Add initial seed chambers
	for i in range(initial_chambers):
		var chamber_pos = Vector3(
			randf_range(-cave_size.x * 0.3, cave_size.x * 0.3),
			randf_range(-cave_size.y * 0.5, cave_size.y * 0.2),
			randf_range(-cave_size.z * 0.3, cave_size.z * 0.3)
		)
		var chamber_radius = randf_range(3.0, 6.0)
		growth_pattern.add_growth_node(chamber_pos, chamber_radius)
	
	# Generate the network
	var network_data = growth_pattern.generate_rhizome_network(growth_iterations)
	print("RhizomeCaveGenerator: Growth pattern complete - %d nodes generated" % network_data.all_nodes.size())

func create_voxel_grid():
	"""Create the voxel chunk grid for the cave area"""
	print("RhizomeCaveGenerator: Creating voxel grid...")
	
	voxel_chunks.clear()
	
	# Calculate number of chunks needed
	var chunks_x = int(ceil(cave_size.x / (chunk_size.x * voxel_scale)))
	var chunks_y = int(ceil(cave_size.y / (chunk_size.y * voxel_scale)))
	var chunks_z = int(ceil(cave_size.z / (chunk_size.z * voxel_scale)))
	
	# Create chunks with proper overlap
	for x in range(chunks_x):
		for y in range(chunks_y):
			for z in range(chunks_z):
				var chunk_world_pos = Vector3(
					x * chunk_size.x * voxel_scale - cave_size.x * 0.5,
					y * chunk_size.y * voxel_scale - cave_size.y * 0.5,
					z * chunk_size.z * voxel_scale - cave_size.z * 0.5
				)
				
				var chunk = VoxelChunk.new(chunk_size, chunk_world_pos, voxel_scale)
				
				# Initialize with solid material (density = 1.0) everywhere
				for cx in range(chunk_size.x + 1):
					for cy in range(chunk_size.y + 1):
						for cz in range(chunk_size.z + 1):
							# Add slight density variation to prevent uniform surfaces
							var base_density = 1.0
							var noise_variation = cave_noise.get_noise_3d(
								chunk_world_pos.x + cx * voxel_scale,
								chunk_world_pos.y + cy * voxel_scale,
								chunk_world_pos.z + cz * voxel_scale
							) * 0.05
							chunk.set_density(Vector3i(cx, cy, cz), base_density + noise_variation)
				
				voxel_chunks.append(chunk)
	
	print("RhizomeCaveGenerator: Created %d voxel chunks" % voxel_chunks.size())

func carve_cave_system():
	"""Carve the cave system into the voxel chunks based on growth pattern"""
	print("RhizomeCaveGenerator: Carving cave system...")
	
	var network_data = growth_pattern.export_network_data()
	
	# Carve chambers (nodes)
	for node_data in network_data.nodes:
		var position = Vector3(node_data.position[0], node_data.position[1], node_data.position[2])
		var radius = node_data.radius
		
		# Find overlapping chunks and carve spherical chambers
		for chunk in voxel_chunks:
			var chunk_bounds = AABB(chunk.world_position, Vector3(chunk.chunk_size) * chunk.voxel_scale)
			var sphere_bounds = AABB(position - Vector3.ONE * radius, Vector3.ONE * radius * 2)
			
			if chunk_bounds.intersects(sphere_bounds):
				if node_data.is_chamber:
					chunk.fill_sphere(position, radius * 1.5, 0.0)  # Larger chambers
				else:
					chunk.fill_sphere(position, radius, 0.0)
	
	# Carve tunnels (connections)
	for connection in network_data.connections:
		var start_pos = connection.start
		var end_pos = connection.end
		var start_radius = connection.start_radius
		var end_radius = connection.end_radius
		
		# Find chunks that intersect with the tunnel
		for chunk in voxel_chunks:
			var tunnel_bounds = AABB(start_pos.min(end_pos), start_pos.max(end_pos) - start_pos.min(end_pos))
			tunnel_bounds = tunnel_bounds.grow(max(start_radius, end_radius))
			var chunk_bounds = AABB(chunk.world_position, Vector3(chunk.chunk_size) * chunk.voxel_scale)
			
			if chunk_bounds.intersects(tunnel_bounds):
				chunk.add_rhizome_branch(start_pos, (end_pos - start_pos).normalized(), 
										start_pos.distance_to(end_pos), start_radius, end_radius)

func carve_cave_system_async():
	"""Carve the cave system asynchronously to prevent blocking"""
	var network_data = growth_pattern.export_network_data()
	var operations_per_frame = 5  # Process 5 operations per frame
	var operations = 0
	
	# Carve chambers (nodes)
	for node_data in network_data.nodes:
		var position = Vector3(node_data.position[0], node_data.position[1], node_data.position[2])
		var radius = node_data.radius
		
		# Find overlapping chunks and carve spherical chambers
		for chunk in voxel_chunks:
			var chunk_bounds = AABB(chunk.world_position, Vector3(chunk.chunk_size) * chunk.voxel_scale)
			var sphere_bounds = AABB(position - Vector3.ONE * radius, Vector3.ONE * radius * 2)
			
			if chunk_bounds.intersects(sphere_bounds):
				if node_data.is_chamber:
					chunk.fill_sphere(position, radius * 1.5, 0.0)  # Larger chambers
				else:
					chunk.fill_sphere(position, radius, 0.0)
				
				operations += 1
				if operations >= operations_per_frame:
					operations = 0
					await get_tree().process_frame
	
	# Carve tunnels (connections)
	for connection in network_data.connections:
		var start_pos = connection.start
		var end_pos = connection.end
		var start_radius = connection.start_radius
		var end_radius = connection.end_radius
		
		# Find chunks that intersect with the tunnel
		for chunk in voxel_chunks:
			var tunnel_bounds = AABB(start_pos.min(end_pos), start_pos.max(end_pos) - start_pos.min(end_pos))
			tunnel_bounds = tunnel_bounds.grow(max(start_radius, end_radius))
			var chunk_bounds = AABB(chunk.world_position, Vector3(chunk.chunk_size) * chunk.voxel_scale)
			
			if chunk_bounds.intersects(tunnel_bounds):
				chunk.add_rhizome_branch(start_pos, (end_pos - start_pos).normalized(), 
										start_pos.distance_to(end_pos), start_radius, end_radius)
				
				operations += 1
				if operations >= operations_per_frame:
					operations = 0
					await get_tree().process_frame

func apply_organic_variation():
	"""Apply noise-based organic variation to make caves more natural"""
	print("RhizomeCaveGenerator: Applying organic variation...")
	
	for chunk in voxel_chunks:
		chunk.apply_noise_field(cave_noise, noise_strength)

func apply_organic_variation_async():
	"""Apply noise-based organic variation asynchronously"""
	var chunks_per_frame = max(1, voxel_chunks.size() / 10)  # Process ~10% per frame
	var processed = 0
	
	for chunk in voxel_chunks:
		chunk.apply_noise_field(cave_noise, noise_strength)
		processed += 1
		
		# Yield every few chunks to prevent blocking
		if processed % chunks_per_frame == 0:
			await get_tree().process_frame

func generate_meshes():
	"""Generate meshes from voxel data using marching cubes"""
	print("RhizomeCaveGenerator: Generating meshes...")
	
	cave_mesh_instances.clear()
	
	for i in range(voxel_chunks.size()):
		var chunk = voxel_chunks[i]
		var mesh = marching_cubes.generate_mesh_from_chunk(chunk)
		
		if mesh.get_surface_count() > 0:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = mesh
			mesh_instance.name = "CaveChunk_%d" % i
			
			# Apply cave material
			var material = create_cave_material()
			mesh_instance.set_surface_override_material(0, material)
			
			add_child(mesh_instance)
			cave_mesh_instances.append(mesh_instance)

func generate_meshes_async():
	"""Generate meshes asynchronously, one chunk per frame"""
	cave_mesh_instances.clear()
	
	for i in range(voxel_chunks.size()):
		var chunk = voxel_chunks[i]
		
		# Update progress for this specific chunk
		var chunk_progress = float(i) / float(voxel_chunks.size()) * 15.0  # 15% of total progress
		generation_progress.emit(80.0 + chunk_progress)
		
		var mesh = marching_cubes.generate_mesh_from_chunk(chunk)
		
		if mesh.get_surface_count() > 0:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = mesh
			mesh_instance.name = "CaveChunk_%d" % i
			
			# Apply cave material
			var material = create_cave_material()
			mesh_instance.set_surface_override_material(0, material)
			
			add_child(mesh_instance)
			cave_mesh_instances.append(mesh_instance)
			
			print("Generated mesh chunk %d/%d" % [i + 1, voxel_chunks.size()])
		
		# Wait one frame between chunks to keep UI responsive
		await get_tree().process_frame

func generate_collision_meshes():
	"""Generate VR-walkable collision bodies for the cave meshes"""
	print("RhizomeCaveGenerator: Generating VR collision meshes...")
	
	collision_bodies.clear()
	
	# Create collision generator for VR walkable surfaces
	var collision_generator = CaveCollisionGenerator.new()
	
	# Generate walkable collision bodies
	var walkable_bodies = collision_generator.generate_walkable_collision(cave_mesh_instances, self)
	collision_bodies.append_array(walkable_bodies)
	
	# Generate 1x1 meter navigation tiles for VR teleportation
	for walkable_body in walkable_bodies:
		if walkable_body.has_meta("vr_walkable"):
			# Get the mesh from the corresponding mesh instance
			var mesh_name = walkable_body.name.replace("_VR_Collision", "")
			var mesh_instance: MeshInstance3D = null
			
			for instance in cave_mesh_instances:
				if instance.name == mesh_name:
					mesh_instance = instance
					break
			
			if mesh_instance != null and mesh_instance.mesh != null:
				# Analyze the mesh for walkable surfaces
				var surface_data = collision_generator.analyze_walkable_surfaces(mesh_instance.mesh)
				
				# Generate navigation tiles
				var nav_tiles = collision_generator.generate_navigation_tiles(surface_data.walkable_triangles, self)
				
				# Create visual markers for VR teleportation
				collision_generator.create_vr_teleport_markers(nav_tiles, self)
	
	print("RhizomeCaveGenerator: Generated %d VR collision bodies with navigation tiles" % collision_bodies.size())

func create_cave_material() -> StandardMaterial3D:
	"""Create a lush, vibrant material for cave surfaces with queer aesthetic"""
	var material = StandardMaterial3D.new()
	
	# Vibrant, lush colors - cycling through rainbow spectrum based on position
	var base_hue = randf()  # Random hue for each chunk
	material.albedo_color = Color.from_hsv(base_hue, 0.7, 0.8)  # Saturated, bright colors
	
	# Add iridescent metallic sheen for that magical queer sparkle
	material.metallic = 0.4
	material.roughness = 0.3  # Shinier surface
	
	# Enable emission for glowing effect
	material.emission_enabled = true
	material.emission = Color.from_hsv(fmod(base_hue + 0.3, 1.0), 0.5, 0.3)  # Complementary glow
	material.emission_energy = 0.5
	
	# Make the material double-sided for better cave interior visibility
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Add subtle rim lighting effect
	material.rim_enabled = true
	material.rim_tint = 0.5
	
	# Enhance with clearcoat for extra shine
	material.clearcoat_enabled = true
	material.clearcoat = 0.3
	material.clearcoat_roughness = 0.1
	
	return material

func clear_previous_cave():
	"""Clear any previously generated cave content"""
	for mesh_instance in cave_mesh_instances:
		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	
	for collision_body in collision_bodies:
		if is_instance_valid(collision_body):
			collision_body.queue_free()
	
	cave_mesh_instances.clear()
	collision_bodies.clear()

func get_cave_info() -> Dictionary:
	"""Get information about the generated cave system"""
	var total_vertices = 0
	var total_triangles = 0
	
	for mesh_instance in cave_mesh_instances:
		var mesh = mesh_instance.mesh as ArrayMesh
		if mesh != null and mesh.get_surface_count() > 0:
			var arrays = mesh.surface_get_arrays(0)
			if arrays[Mesh.ARRAY_VERTEX] != null:
				total_vertices += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			if arrays[Mesh.ARRAY_INDEX] != null:
				total_triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	
	return {
		"mesh_instances": cave_mesh_instances.size(),
		"collision_bodies": collision_bodies.size(),
		"total_vertices": total_vertices,
		"total_triangles": total_triangles,
		"voxel_chunks": voxel_chunks.size(),
		"growth_nodes": growth_pattern.growth_nodes.size() if growth_pattern else 0,
		"chambers": growth_pattern.chamber_nodes.size() if growth_pattern else 0
	} 
