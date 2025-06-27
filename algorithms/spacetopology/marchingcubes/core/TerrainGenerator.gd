# TerrainGenerator.gd
# Generates walkable terrain using marching cubes algorithm
# Creates smooth ground surfaces with interesting topology

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
	if params.has("debug_simple"):
		# Enable simple debug terrain without complex noise
		pass

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
	"""Create voxel chunks for terrain generation"""
	terrain_chunks.clear()
	
	# Calculate effective chunk size in world units
	var chunk_world_size_x = chunk_size.x * voxel_scale
	var chunk_world_size_z = chunk_size.z * voxel_scale
	var chunk_world_size_y = chunk_size.y * voxel_scale
	
	# Calculate number of chunks needed with slight overlap
	var chunks_x = int(ceil(terrain_size.x / chunk_world_size_x)) + 1  # Extra chunk for safety
	var chunks_z = int(ceil(terrain_size.y / chunk_world_size_z)) + 1
	var chunks_y = int(ceil(terrain_height * 2.0 / chunk_world_size_y))  # Multiple layers for depth
	
	print("Creating %dx%dx%d terrain chunks" % [chunks_x, chunks_y, chunks_z])
	
	# Create chunks with proper coverage
	for x in range(chunks_x):
		for y in range(chunks_y):
			for z in range(chunks_z):
				var chunk_world_pos = Vector3(
					x * chunk_world_size_x - terrain_size.x * 0.5 - chunk_world_size_x * 0.5,
					y * chunk_world_size_y - terrain_height,  # Start below terrain
					z * chunk_world_size_z - terrain_size.y * 0.5 - chunk_world_size_z * 0.5
				)
				
				var chunk = VoxelChunk.new(chunk_size, chunk_world_pos, voxel_scale)
				terrain_chunks.append(chunk)
	
	print("Created %d terrain chunks" % terrain_chunks.size())

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
	"""Fill a chunk with terrain height field data"""
	for x in range(chunk.chunk_size.x + 1):
		for y in range(chunk.chunk_size.y + 1):
			for z in range(chunk.chunk_size.z + 1):
				var world_pos = chunk.local_to_world(Vector3i(x, y, z))
				var density = calculate_terrain_density(world_pos)
				chunk.set_density(Vector3i(x, y, z), density)

func calculate_terrain_density(world_pos: Vector3) -> float:
	"""Calculate density value for terrain at world position"""
	# Get height from noise with better sampling
	var height_value = height_noise.get_noise_2d(world_pos.x, world_pos.z)
	var detail_value = detail_noise.get_noise_2d(world_pos.x, world_pos.z) * 0.2
	var feature_value = feature_noise.get_noise_2d(world_pos.x, world_pos.z) * 0.3
	
	# Combined height with smoother interpolation
	var combined_height = (height_value + detail_value + feature_value) * terrain_height
	
	# Create a solid base terrain - much simpler approach
	var distance_to_surface = world_pos.y - combined_height
	
	# Ensure solid ground below the terrain
	if world_pos.y <= combined_height:
		# Solid terrain with gradual transition at surface
		var depth_factor = max(0.0, (combined_height - world_pos.y) / terrain_height)
		var base_density = 0.8 + depth_factor * 0.2  # Denser deeper down
		
		# Add very subtle surface noise only (can be disabled for debug)
		var surface_variation = 0.0
		if height_noise != null:  # Safety check
			surface_variation = height_noise.get_noise_3d(world_pos.x * 2.0, world_pos.y * 2.0, world_pos.z * 2.0) * 0.05
		return clamp(base_density + surface_variation, 0.6, 1.0)  # Ensure minimum density
	else:
		# Air above terrain with smooth transition
		var transition_width = voxel_scale * 1.5
		if distance_to_surface < transition_width:
			# Smooth transition zone
			var transition_factor = distance_to_surface / transition_width
			return clamp(0.5 - transition_factor * 0.5, 0.0, 0.5)
		else:
			# Pure air
			return 0.0

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
	
	return material

func generate_walkable_collision():
	"""Generate VR-walkable collision for terrain"""
	collision_bodies.clear()
	
	if terrain_meshes.size() == 0:
		return
	
	# Use a temporary parent for collision generation
	var temp_parent = Node3D.new()
	
	# Generate walkable collision bodies
	var walkable_bodies = collision_generator.generate_walkable_collision(terrain_meshes, temp_parent)
	collision_bodies.append_array(walkable_bodies)
	
	# Generate navigation tiles for each walkable body
	for walkable_body in walkable_bodies:
		if walkable_body.has_meta("vr_walkable"):
			# Get corresponding mesh
			var mesh_name = walkable_body.name.replace("_VR_Collision", "")
			var mesh_instance: MeshInstance3D = null
			
			for instance in terrain_meshes:
				if instance.name == mesh_name:
					mesh_instance = instance
					break
			
			if mesh_instance != null and mesh_instance.mesh != null:
				# Analyze for walkable surfaces
				var surface_data = collision_generator.analyze_walkable_surfaces(mesh_instance.mesh)
				
				# Generate 1x1m navigation tiles
				var nav_tiles = collision_generator.generate_navigation_tiles(surface_data.walkable_triangles, temp_parent)
				
				# Create visual markers
				collision_generator.create_vr_teleport_markers(nav_tiles, temp_parent)
	
	print("Generated %d collision bodies for terrain" % collision_bodies.size())

func clear_previous_terrain():
	"""Clear previously generated terrain"""
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
