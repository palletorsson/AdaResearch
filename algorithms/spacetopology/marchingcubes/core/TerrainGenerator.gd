# TerrainGenerator.gd
# Generates walkable terrain using marching cubes algorithm
# Creates smooth ground surfaces with interesting topology
#
# HOLE-FREE TERRAIN STRATEGY:
# 1. Minimum density guarantee (0.7+) for all terrain voxels
# 2. Reduced surface noise intensity (0.02 vs 0.05)
# 3. Debug mode to completely disable surface variation
# 4. Safe boundary handling returns solid material (1.0) outside chunks
# 5. Proper chunk overlap and positioning

extends RefCounted
class_name TerrainGenerator

# Components
var marching_cubes: MarchingCubesGenerator
var collision_generator: CaveCollisionGenerator

# Terrain parameters
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var terrain_height: float = 5.0
@export var chunk_size: Vector3i = Vector3i(16, 12, 16)  # Slightly taller for better terrain
@export var voxel_scale: float = 0.8  # Finer voxels for smoother surfaces
@export var noise_frequency: float = 0.05
@export var surface_threshold: float = 0.5  # Standard threshold for marching cubes

# Debug options for fixing holes
@export var debug_disable_surface_variation: bool = false  # Set true to eliminate surface noise
@export var debug_minimum_density: float = 0.7  # Adjustable minimum density for terrain
@export var debug_wireframe_mode: bool = false  # Set true to show wireframe

# Noise layers for terrain variation
var height_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var feature_noise: FastNoiseLite

# Generated content
var terrain_chunks: Array[VoxelChunk] = []
var terrain_meshes: Array[MeshInstance3D] = []
var collision_bodies: Array[StaticBody3D] = []

signal generation_complete()
signal generation_progress(percentage: float)

func _init(seed_value: int = -1):
	setup_components(seed_value)

func setup_components(seed_value: int = -1):
	"""Initialize terrain generation components"""
	# Initialize marching cubes
	marching_cubes = MarchingCubesGenerator.new()
	marching_cubes.threshold = surface_threshold
	
	# CRITICAL: Pass self reference to marching cubes for GLSL-style direct density evaluation
	marching_cubes.terrain_generator_ref = self
	
	# Initialize collision generator
	collision_generator = CaveCollisionGenerator.new()
	
	# Setup noise generators
	setup_noise_generators(seed_value)
	
	print("TerrainGenerator: Components initialized")

func setup_noise_generators(seed_value: int):
	"""Setup multiple noise layers for terrain variation"""
	var actual_seed = seed_value if seed_value >= 0 else randi()
	
	# Primary height noise
	height_noise = FastNoiseLite.new()
	height_noise.seed = actual_seed
	height_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	height_noise.frequency = noise_frequency
	height_noise.fractal_octaves = 4
	height_noise.fractal_gain = 0.5
	height_noise.fractal_lacunarity = 2.0
	
	# Detail noise for surface variation
	detail_noise = FastNoiseLite.new()
	detail_noise.seed = actual_seed + 1000
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = noise_frequency * 3.0
	detail_noise.fractal_octaves = 2
	
	# Feature noise for hills and valleys
	feature_noise = FastNoiseLite.new()
	feature_noise.seed = actual_seed + 2000
	feature_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	feature_noise.frequency = noise_frequency * 0.3
	feature_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

func configure_terrain(params: Dictionary):
	"""Configure terrain generation parameters"""
	if params.has("size"):
		terrain_size = params.size
	if params.has("height"):
		terrain_height = params.height
	if params.has("noise_frequency"):
		noise_frequency = params.noise_frequency
		if height_noise != null:
			height_noise.frequency = noise_frequency
			detail_noise.frequency = noise_frequency * 3.0
			feature_noise.frequency = noise_frequency * 0.3
	if params.has("threshold"):
		surface_threshold = params.threshold
		if marching_cubes != null:
			marching_cubes.threshold = surface_threshold
	if params.has("debug_mode"):
		# Enable debug mode to eliminate holes
		debug_disable_surface_variation = params.get("debug_mode", false)
		debug_minimum_density = params.get("min_density", 0.7)
		print("TerrainGenerator: Debug mode enabled - surface variation: %s, min density: %.2f" % [not debug_disable_surface_variation, debug_minimum_density])

func generate_terrain_async() -> Array[MeshInstance3D]:
	"""Generate terrain asynchronously"""
	print("TerrainGenerator: Starting terrain generation...")
	
	# Clear previous generation
	clear_previous_terrain()
	
	# Step 1: Create voxel grid
	print("TerrainGenerator: Step 1/4 - Creating voxel grid...")
	create_terrain_voxel_grid()
	generation_progress.emit(25.0)
	await Engine.get_main_loop().process_frame
	
	# Step 2: Generate height field
	print("TerrainGenerator: Step 2/4 - Generating height field...")
	await generate_height_field_async()
	generation_progress.emit(50.0)
	
	# Step 3: Generate meshes
	print("TerrainGenerator: Step 3/4 - Generating meshes...")
	await generate_terrain_meshes_async()
	generation_progress.emit(75.0)
	
	# Step 4: Create collision
	print("TerrainGenerator: Step 4/4 - Creating collision...")
	generate_walkable_collision()
	generation_progress.emit(100.0)
	
	generation_complete.emit()
	print("TerrainGenerator: Terrain generation complete!")
	
	return terrain_meshes

func create_terrain_voxel_grid():
	"""Create voxel chunks for terrain generation - FIXED FOR SEAMLESS BOUNDARIES"""
	terrain_chunks.clear()
	
	# Calculate effective chunk size in world units
	var chunk_world_size_x = chunk_size.x * voxel_scale
	var chunk_world_size_z = chunk_size.z * voxel_scale
	var chunk_world_size_y = chunk_size.y * voxel_scale
	
	# FIXED: No overlap needed - chunks will share boundary vertices through direct calculation
	var chunks_x = int(ceil(terrain_size.x / chunk_world_size_x))
	var chunks_z = int(ceil(terrain_size.y / chunk_world_size_z))
	var chunks_y = 1  # Single layer for terrain
	
	print("Creating %dx%dx%d terrain chunks (seamless boundaries)" % [chunks_x, chunks_y, chunks_z])
	
	# Create chunks with precise positioning for seamless boundaries
	for x in range(chunks_x):
		for y in range(chunks_y):
			for z in range(chunks_z):
				var chunk_world_pos = Vector3(
					x * chunk_world_size_x - terrain_size.x * 0.5,
					-terrain_height * 0.5,
					z * chunk_world_size_z - terrain_size.y * 0.5
				)
				
				var chunk = VoxelChunk.new(chunk_size, chunk_world_pos, voxel_scale)
				chunk.chunk_name = "TerrainChunk_%d_%d_%d" % [x, y, z]
				terrain_chunks.append(chunk)
	
	# Setup neighbor connections for reference (not used for density lookup anymore)
	setup_chunk_neighbors(chunks_x, chunks_y, chunks_z)
	
	print("Created %d terrain chunks with seamless boundary handling" % terrain_chunks.size())

func setup_chunk_neighbors(chunks_x: int, chunks_y: int, chunks_z: int):
	"""Setup neighbor connections between chunks for seamless boundaries (inspired by reference)"""
	print("TerrainGenerator: Setting up chunk neighbor connections...")
	
	for x in range(chunks_x):
		for y in range(chunks_y):
			for z in range(chunks_z):
				var chunk_index = x + y * chunks_x + z * chunks_x * chunks_y
				if chunk_index >= terrain_chunks.size():
					continue
					
				var current_chunk = terrain_chunks[chunk_index]
				
				# Connect to neighboring chunks in all 6 directions
				var neighbor_offsets = [
					Vector3i(1, 0, 0),   # Right
					Vector3i(-1, 0, 0),  # Left  
					Vector3i(0, 1, 0),   # Up
					Vector3i(0, -1, 0),  # Down
					Vector3i(0, 0, 1),   # Forward
					Vector3i(0, 0, -1)   # Back
				]
				
				for offset in neighbor_offsets:
					var neighbor_x = x + offset.x
					var neighbor_y = y + offset.y
					var neighbor_z = z + offset.z
					
					# Check bounds
					if (neighbor_x >= 0 and neighbor_x < chunks_x and
						neighbor_y >= 0 and neighbor_y < chunks_y and
						neighbor_z >= 0 and neighbor_z < chunks_z):
						
						var neighbor_index = neighbor_x + neighbor_y * chunks_x + neighbor_z * chunks_x * chunks_y
						if neighbor_index < terrain_chunks.size():
							var neighbor_chunk = terrain_chunks[neighbor_index]
							current_chunk.set_neighbor_chunk(offset, neighbor_chunk)
	
	print("TerrainGenerator: Chunk neighbor connections established")

func generate_height_field_async():
	"""Generate height field data asynchronously"""
	var chunks_per_frame = max(1, terrain_chunks.size() / 10)
	var processed = 0
	
	for chunk in terrain_chunks:
		fill_chunk_with_terrain(chunk)
		processed += 1
		
		# Yield every few chunks to prevent blocking
		if processed % chunks_per_frame == 0:
			await Engine.get_main_loop().process_frame

func fill_chunk_with_terrain(chunk: VoxelChunk):
	"""Fill a chunk with terrain height field data - HOLE-FREE VERSION"""
	var chunk_offset = chunk.world_position
	
	# Generate density data for ALL voxels (interior + boundary)
	# This ensures seamless marching cubes can operate across chunk boundaries
	for x in range(chunk.chunk_size.x + 1):  # +1 for marching cubes boundary
		for y in range(chunk.chunk_size.y + 1):
			for z in range(chunk.chunk_size.z + 1):
				var world_x = chunk_offset.x + x * chunk.voxel_scale
				var world_y = chunk_offset.y + y * chunk.voxel_scale
				var world_z = chunk_offset.z + z * chunk.voxel_scale
				
				var world_pos = Vector3(world_x, world_y, world_z)
				var density = calculate_terrain_density(world_pos)
				
				# Ensure density is valid before storing
				density = clamp(density, 0.0, 1.0)
				chunk.set_density(Vector3i(x, y, z), density)
	
	# Mark chunk as clean after filling
	chunk.is_dirty = false
	
	print("TerrainGenerator: Filled chunk %s with hole-free density data" % chunk.chunk_name)

func calculate_terrain_density(world_pos: Vector3) -> float:
	"""Calculate density value for terrain at world position - HOLE-FREE VERSION"""
	# Get height from multiple noise layers
	var height_value = height_noise.get_noise_2d(world_pos.x, world_pos.z)
	var detail_value = detail_noise.get_noise_2d(world_pos.x, world_pos.z) * 0.2  # Reduced for stability
	var feature_value = feature_noise.get_noise_2d(world_pos.x, world_pos.z) * 0.3  # Reduced for stability
	
	var combined_height = (height_value + detail_value + feature_value) * terrain_height * 0.4
	
	# Distance from surface
	var distance_to_surface = world_pos.y - combined_height
	
	# HOLE-FREE STRATEGY: Use smooth distance field
	if distance_to_surface <= -2.0:
		# Deep solid - guaranteed high density
		return 0.95
	elif distance_to_surface <= -1.0:
		# Near-surface solid with smooth falloff
		var depth_factor = (-distance_to_surface - 1.0) / 1.0
		return lerp(0.75, 0.95, depth_factor)
	elif distance_to_surface <= 0.0:
		# Surface transition zone - critical for hole prevention
		var surface_factor = -distance_to_surface / 1.0
		var base_density = lerp(0.45, 0.75, surface_factor)
		
		# Add minimal surface variation only if not in debug mode
		var surface_var = 0.0
		if not debug_disable_surface_variation:
			surface_var = detail_value * 0.05  # Minimal variation
		
		return clamp(base_density + surface_var, 0.4, 0.8)  # Ensure it crosses threshold cleanly
	elif distance_to_surface <= 1.0:
		# Air transition zone - smooth falloff to prevent floating geometry
		var air_factor = distance_to_surface / 1.0
		return lerp(0.45, 0.1, air_factor)
	else:
		# Definitely air
		return 0.05

func smooth_air_transition(world_pos: Vector3, surface_height: float) -> float:
	"""Create smooth air transition above terrain surface"""
	var height_above_surface = world_pos.y - surface_height
	var transition_zone = terrain_height * 0.1  # 10% of terrain height for smooth transition
	
	if height_above_surface < transition_zone:
		# Smooth falloff from surface to air
		var t = height_above_surface / transition_zone
		return lerp(0.6, 0.0, smoothstep(0.0, 1.0, t))
	else:
		# Definitely air
		return 0.0

func calculate_surface_height(x: float, z: float) -> float:
	"""Calculate terrain surface height at given X,Z coordinates"""
	var height_base = height_noise.get_noise_2d(x, z)
	var height_detail = detail_noise.get_noise_2d(x * 2.0, z * 2.0) * 0.3
	var height_features = feature_noise.get_noise_2d(x * 0.5, z * 0.5) * 0.5
	
	return (height_base + height_detail + height_features) * terrain_height * 0.5

func generate_terrain_meshes_async():
	"""Generate meshes from terrain chunks asynchronously"""
	terrain_meshes.clear()
	
	for i in range(terrain_chunks.size()):
		var chunk = terrain_chunks[i]
		var mesh = marching_cubes.generate_mesh_from_chunk(chunk)
		
		if mesh.get_surface_count() > 0:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = mesh
			mesh_instance.name = "TerrainChunk_%d" % i
			
			# Apply terrain material
			var material = create_terrain_material(i)
			mesh_instance.set_surface_override_material(0, material)
			
			terrain_meshes.append(mesh_instance)
			
			print("Generated terrain mesh chunk %d/%d" % [i + 1, terrain_chunks.size()])
		
		# Wait one frame between chunks
		await Engine.get_main_loop().process_frame

func create_terrain_material(chunk_index: int) -> StandardMaterial3D:
	"""Create material for terrain surface"""
	var material = StandardMaterial3D.new()
	
	# Earthy color palette with some variation
	var hue_base = 0.25 + fmod(chunk_index * 0.02, 0.1)  # Green to brown range
	var saturation = 0.6 + sin(chunk_index * 0.5) * 0.2
	var brightness = 0.7 + cos(chunk_index * 0.3) * 0.1
	
	material.albedo_color = Color.from_hsv(hue_base, saturation, brightness)
	
	# Natural surface properties
	material.metallic = 0.0
	material.roughness = 0.8  # Natural, rough surface
	
	# Subtle emission for magical feel
	material.emission_enabled = true
	material.emission = Color.from_hsv(hue_base + 0.1, 0.3, 0.1)
	material.emission_energy = 0.2
	
	# Double-sided for proper visibility
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL  # Enable proper lighting
	
	# Debug wireframe mode (disabled by default)
	if debug_wireframe_mode:
		material.flags_transparent = true
		material.wireframe = true
		material.albedo_color = Color.WHITE
	
	return material

func generate_walkable_collision():
	"""Generate VR-walkable collision for terrain"""
	collision_bodies.clear()
	
	if terrain_meshes.size() == 0:
		return
	
	# Safety check for collision generator
	if collision_generator == null:
		print("TerrainGenerator: Warning - collision_generator is null, skipping collision generation")
		return
	
	# Use a temporary parent for collision generation
	var temp_parent = Node3D.new()
	
	# Generate walkable collision bodies with error handling
	var walkable_bodies = collision_generator.generate_walkable_collision(terrain_meshes, temp_parent)
	if walkable_bodies == null:
		print("TerrainGenerator: Error generating walkable collision, continuing without collision")
		temp_parent.queue_free()
		return
	
	collision_bodies.append_array(walkable_bodies)
	
	# Generate navigation tiles for each walkable body
	for walkable_body in walkable_bodies:
		if walkable_body != null and walkable_body.has_meta("vr_walkable"):
			# Get corresponding mesh
			var mesh_name = walkable_body.name.replace("_VR_Collision", "")
			var mesh_instance: MeshInstance3D = null
			
			for instance in terrain_meshes:
				if instance != null and instance.name == mesh_name:
					mesh_instance = instance
					break
			
			if mesh_instance != null and mesh_instance.mesh != null:
				# Analyze for walkable surfaces
				var surface_data = collision_generator.analyze_walkable_surfaces(mesh_instance.mesh)
				
				if surface_data != null and surface_data.has("walkable_triangles"):
					# Generate 1x1m navigation tiles
					var nav_tiles = collision_generator.generate_navigation_tiles(surface_data.walkable_triangles, temp_parent)
					
					# Create visual markers
					if nav_tiles != null:
						collision_generator.create_vr_teleport_markers(nav_tiles, temp_parent)
				else:
					print("TerrainGenerator: No walkable triangles found for %s, skipping" % mesh_name)
	
	print("Generated %d collision bodies for terrain" % collision_bodies.size())

func clear_previous_terrain():
	"""Clear previously generated terrain"""
	# Clean up marching cubes GPU resources if they exist
	if marching_cubes != null and marching_cubes.has_method("cleanup"):
		marching_cubes.cleanup()
	
	terrain_chunks.clear()
	terrain_meshes.clear()
	collision_bodies.clear()

func get_terrain_info() -> Dictionary:
	"""Get information about generated terrain"""
	var total_vertices = 0
	var total_triangles = 0
	
	for mesh_instance in terrain_meshes:
		var mesh = mesh_instance.mesh as ArrayMesh
		if mesh != null and mesh.get_surface_count() > 0:
			var arrays = mesh.surface_get_arrays(0)
			var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			
			total_vertices += vertices.size()
			total_triangles += indices.size() / 3
	
	return {
		"terrain_chunks": terrain_chunks.size(),
		"mesh_instances": terrain_meshes.size(),
		"collision_bodies": collision_bodies.size(),
		"total_vertices": total_vertices,
		"total_triangles": total_triangles,
		"terrain_size": terrain_size,
		"height_variation": terrain_height
	}

func add_terrain_to_scene(parent_node: Node3D):
	"""Add generated terrain to scene"""
	for mesh_instance in terrain_meshes:
		parent_node.add_child(mesh_instance)
	
	for collision_body in collision_bodies:
		parent_node.add_child(collision_body) 
