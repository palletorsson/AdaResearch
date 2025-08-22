# FastLandscapeCaveGenerator.gd
# High-performance landscape + cave generator using GPU compute shaders
# Based on the rhizomatic approach but with GPU acceleration

extends Node3D
class_name FastLandscapeCaveGenerator

# === MARCHING CUBES ===
var marching_cubes: MarchingCubesGenerator
var gpu_marching_cubes: FixedGPUMarchingCubes
var use_gpu_acceleration: bool = true

# === GENERATION PARAMETERS ===
@export_group("World Configuration")
@export var world_size: Vector3 = Vector3(100, 40, 100)
@export var voxel_resolution: Vector3i = Vector3i(128, 64, 128)  # Higher resolution for GPU
@export var auto_generate_on_ready: bool = true

@export_group("Terrain Parameters")
@export var terrain_height: float = 8.0
@export var terrain_noise_frequency: float = 0.0015
@export var terrain_octaves: int = 4
@export var terrain_persistence: float = 0.5

@export_group("Cave Parameters")
@export var cave_density: float = 0.25
@export var cave_noise_frequency: float = 0.015
@export var cave_size_multiplier: float = 2.0
@export var cave_min_height: float = -10.0
@export var cave_max_height: float = 5.0
@export var cave_vertical_bias: float = 0.4

@export_group("Visual Settings")
@export var material_terrain: Material
@export var material_cave: Material
@export var generate_collision: bool = true
@export var show_generation_progress: bool = true
# ADD THESE NEW PROPERTIES HERE:
@export var ISO_LEVEL: float = 0.5
@export var USE_ROBUST_INTERPOLATION: bool = true
@export var PREVENT_DEGENERATE_TRIANGLES: bool = true
# === NOISE GENERATORS ===
var noise_terrain: FastNoiseLite
var noise_cave_primary: FastNoiseLite
var noise_cave_secondary: FastNoiseLite
var noise_cave_detail: FastNoiseLite

# === GENERATED CONTENT ===
var terrain_mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var generation_time: float = 0.0

# === SIGNALS ===
signal generation_complete(generation_time: float)
signal generation_progress(percentage: float)



func _ready():
	setup_noise_generators()
	setup_gpu_marching_cubes()
	
	if auto_generate_on_ready:
		call_deferred("generate_world_async")

func setup_noise_generators():
	"""Initialize all noise generators for terrain and caves"""
	var base_seed = randi()
	
	# Terrain noise - multiple octaves for realistic landscapes
	noise_terrain = FastNoiseLite.new()
	noise_terrain.seed = base_seed
	noise_terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_terrain.frequency = terrain_noise_frequency
	noise_terrain.fractal_octaves = terrain_octaves
	noise_terrain.fractal_gain = terrain_persistence
	noise_terrain.fractal_lacunarity = 2.0
	
	# Primary cave structure - creates main chambers and tunnels
	noise_cave_primary = FastNoiseLite.new()
	noise_cave_primary.seed = base_seed + 1000
	noise_cave_primary.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_cave_primary.frequency = cave_noise_frequency
	noise_cave_primary.fractal_octaves = 3
	noise_cave_primary.fractal_gain = 0.6
	
	# Secondary cave variation - adds branching and complexity
	noise_cave_secondary = FastNoiseLite.new()
	noise_cave_secondary.seed = base_seed + 2000
	noise_cave_secondary.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_cave_secondary.frequency = cave_noise_frequency * 2.0
	noise_cave_secondary.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	# Cave detail noise - adds surface texture and small features
	noise_cave_detail = FastNoiseLite.new()
	noise_cave_detail.seed = base_seed + 3000
	noise_cave_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_cave_detail.frequency = cave_noise_frequency * 4.0
	
	print("FastLandscapeCaveGenerator: Noise generators initialized")

func setup_gpu_marching_cubes():
	"""Initialize marching cubes system with GPU acceleration"""
	# Try GPU acceleration first
	gpu_marching_cubes = FixedGPUMarchingCubes.new()
	
	if gpu_marching_cubes.is_initialized:
		use_gpu_acceleration = true
		print("FastLandscapeCaveGenerator: Using GPU acceleration")
	else:
		use_gpu_acceleration = false
		# Fallback to CPU
		marching_cubes = MarchingCubesGenerator.new()
		marching_cubes.threshold = 0.5
		marching_cubes.smoothing_enabled = true
		print("FastLandscapeCaveGenerator: GPU not available, using CPU fallback")

func generate_world_async():
	"""Generate the complete world asynchronously using GPU acceleration"""
	var start_time = Time.get_ticks_msec()
	print("FastLandscapeCaveGenerator: Starting high-performance world generation...")
	
	if show_generation_progress:
		generation_progress.emit(0.0)
	
	# Clear previous generation
	clear_previous_world()
	
	# Step 1: Create voxel chunk (30%)
	print("FastLandscapeCaveGenerator: Step 1/4 - Creating voxel chunk...")
	var chunk = await generate_unified_voxel_chunk()
	if show_generation_progress:
		generation_progress.emit(30.0)
	
	# Step 2: GPU/CPU marching cubes generation (50%)
	var mesh: ArrayMesh
	if use_gpu_acceleration:
		print("FastLandscapeCaveGenerator: Step 2/4 - GPU mesh generation...")
		mesh = await generate_mesh_gpu(chunk)
	else:
		print("FastLandscapeCaveGenerator: Step 2/4 - CPU mesh generation...")
		mesh = await generate_mesh_cpu(chunk)
	if show_generation_progress:
		generation_progress.emit(80.0)
	
	# Step 3: Create visual representation (15%)
	print("FastLandscapeCaveGenerator: Step 3/4 - Creating visual representation...")
	create_mesh_instance(mesh)
	if show_generation_progress:
		generation_progress.emit(90.0)
	
	# Step 4: Generate collision (5%)
	if generate_collision:
		print("FastLandscapeCaveGenerator: Step 4/4 - Generating collision...")
		create_collision_shape(mesh)
	
	if show_generation_progress:
		generation_progress.emit(100.0)
	
	var end_time = Time.get_ticks_msec()
	generation_time = (end_time - start_time) / 1000.0  # Convert to seconds
	
	generation_complete.emit(generation_time)
	print("FastLandscapeCaveGenerator: World generation complete in %.2f seconds!" % generation_time)

func generate_unified_voxel_chunk() -> VoxelChunk:
	"""Generate a unified voxel chunk combining terrain and caves"""
	var chunk_world_pos = -world_size * 0.5
	var voxel_scale = world_size.x / (voxel_resolution.x - 1)
	
	var chunk = VoxelChunk.new(voxel_resolution, chunk_world_pos, voxel_scale)
	chunk.chunk_name = "FastLandscapeChunk"
	
	var total_voxels = (voxel_resolution.x + 1) * (voxel_resolution.y + 1) * (voxel_resolution.z + 1)
	var processed_voxels = 0
	var voxels_per_frame = max(1000, total_voxels / 50)  # Process in chunks to prevent blocking
	
	# Fill chunk with unified density field
	for x in range(voxel_resolution.x + 1):
		for y in range(voxel_resolution.y + 1):
			for z in range(voxel_resolution.z + 1):
				var world_pos = chunk.local_to_world(Vector3i(x, y, z))
				var density = calculate_unified_density(world_pos)
				chunk.set_density(Vector3i(x, y, z), density)
				
				processed_voxels += 1
				
				# Yield occasionally to prevent blocking
				if processed_voxels % voxels_per_frame == 0:
					var progress = float(processed_voxels) / float(total_voxels) * 25.0  # 25% of total progress
					if show_generation_progress:
						generation_progress.emit(5.0 + progress)
					await get_tree().process_frame
	
	return chunk

func calculate_unified_density(world_pos: Vector3) -> float:
	"""Calculate density using RHIZOMATIC APPROACH - Start solid, carve terrain and caves"""
	
	# === RHIZOMATIC APPROACH ===
	# Start with solid terrain everywhere (like rhizomatic demo)
	var base_density = 1.0
	
	# Add slight noise variation to prevent uniform surfaces
	var base_noise = noise_terrain.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.05
	var solid_density = base_density + base_noise
	
	# === CARVE TERRAIN SURFACE ===
	# Calculate terrain surface height
	var terrain_surface_noise = noise_terrain.get_noise_2d(world_pos.x, world_pos.z)
	var terrain_surface_height = terrain_surface_noise * terrain_height
	
	# Distance above terrain surface
	var distance_above_terrain = world_pos.y - terrain_surface_height
	
	# CARVE air above terrain surface (like rhizomatic carving)
	var terrain_carve_amount: float = 0.0
	if distance_above_terrain > 0.0:
		# Above terrain - carve to create air
		if distance_above_terrain <= 2.0:
			# Smooth transition at surface
			var t = distance_above_terrain / 2.0
			terrain_carve_amount = smoothstep(0.0, 1.0, t) * 0.95  # Remove most material
		else:
			# Definitely air above terrain
			terrain_carve_amount = 0.95
	
	# Apply terrain carving
	var terrain_density = solid_density * (1.0 - terrain_carve_amount)
	
	# === CARVE CAVE SYSTEM ===
	var final_density = terrain_density
	
	# Only carve caves in remaining solid areas and within height range
	if (world_pos.y >= cave_min_height and world_pos.y <= cave_max_height and 
		terrain_density > 0.4):  # Only carve where there's still material
		
		# Primary cave structure
		var cave_primary = noise_cave_primary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		
		# Secondary cave structure
		var cave_secondary = noise_cave_secondary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.4
		
		# Vertical bias - prefer horizontal caves
		var height_factor = abs(world_pos.y) / max(terrain_height, 1.0)
		var vertical_bias_factor = 1.0 - (height_factor * cave_vertical_bias)
		
		# Combine cave noises
		var combined_cave_noise = cave_primary + cave_secondary
		combined_cave_noise *= vertical_bias_factor
		
		# Cave carving - positive values carve material away
		var cave_threshold = (combined_cave_noise + 1.0) * 0.5  # Normalize to 0-1
		if cave_threshold > (1.0 - cave_density):
			# Carve cave - remove material like rhizomatic approach
			var carve_amount = (cave_threshold - (1.0 - cave_density)) / cave_density
			carve_amount = clamp(carve_amount * cave_size_multiplier, 0.0, 0.8)
			
			# Carve by reducing density (like fill_sphere with 0.0)
			final_density = final_density * (1.0 - carve_amount)
	
	return clamp(final_density, 0.0, 1.0)

func generate_mesh_gpu(chunk: VoxelChunk) -> ArrayMesh:
	"""Generate mesh using GPU compute shader"""
	print("FastLandscapeCaveGenerator: Starting GPU mesh generation...")
	
	# Convert VoxelChunk data to PackedFloat32Array for GPU
	var density_data = PackedFloat32Array()
	var total_voxels = (voxel_resolution.x + 1) * (voxel_resolution.y + 1) * (voxel_resolution.z + 1)
	density_data.resize(total_voxels)
	
	var index = 0
	for x in range(voxel_resolution.x + 1):
		for y in range(voxel_resolution.y + 1):
			for z in range(voxel_resolution.z + 1):
				var density = chunk.get_density(Vector3i(x, y, z))
				density_data[index] = density
				index += 1
	
	# Setup GPU parameters
	gpu_marching_cubes.set_grid_parameters(
		voxel_resolution + Vector3i.ONE,  # Include boundary voxels
		Vector3.ONE * chunk.voxel_scale,
		chunk.world_position
	)
	gpu_marching_cubes.set_iso_level(0.5)
	
	# Generate mesh on GPU
	var mesh = gpu_marching_cubes.generate_mesh_gpu(density_data)
	
	if mesh == null or mesh.get_surface_count() == 0:
		print("FastLandscapeCaveGenerator: GPU generation failed, falling back to CPU")
		# Fallback to CPU
		if not marching_cubes:
			marching_cubes = MarchingCubesGenerator.new()
			marching_cubes.threshold = 0.5
			marching_cubes.smoothing_enabled = true
		mesh = marching_cubes.generate_mesh_from_chunk(chunk)
	
	await get_tree().process_frame  # Allow for UI updates
	return mesh if mesh else ArrayMesh.new()

func generate_mesh_cpu(chunk: VoxelChunk) -> ArrayMesh:
	"""Generate mesh using CPU marching cubes"""
	print("FastLandscapeCaveGenerator: Starting CPU mesh generation...")
	
	# Generate mesh using proven CPU marching cubes
	var mesh = marching_cubes.generate_mesh_from_chunk(chunk)
	
	if mesh == null:
		push_error("CPU mesh generation failed")
		return ArrayMesh.new()
	
	await get_tree().process_frame  # Allow for UI updates
	return mesh

func create_mesh_instance(mesh: ArrayMesh):
	"""Create visual mesh instance with appropriate material"""
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "LandscapeCaveMesh"
	terrain_mesh_instance.mesh = mesh
	
	# Apply material
	var material = get_landscape_material()
	terrain_mesh_instance.set_surface_override_material(0, material)
	
	add_child(terrain_mesh_instance)
	print("FastLandscapeCaveGenerator: Mesh instance created")

func create_collision_shape(mesh: ArrayMesh):
	"""Create collision shape for physics interaction"""
	if mesh.get_surface_count() == 0:
		return
	
	collision_body = StaticBody3D.new()
	collision_body.name = "LandscapeCaveCollision"
	
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	
	# Get vertex data from mesh
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	# Create collision faces
	var collision_faces: PackedVector3Array = []
	for i in range(0, indices.size(), 3):
		if i + 2 < indices.size():
			collision_faces.append(vertices[indices[i]])
			collision_faces.append(vertices[indices[i + 1]])
			collision_faces.append(vertices[indices[i + 2]])
	
	shape.set_faces(collision_faces)
	collision_shape.shape = shape
	collision_body.add_child(collision_shape)
	
	add_child(collision_body)
	print("FastLandscapeCaveGenerator: Collision shape created")

func get_landscape_material() -> StandardMaterial3D:
	"""Create or return landscape material"""
	if material_terrain:
		return material_terrain
	
	# Create default material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.3, 1.0)  # Earthy green
	material.roughness = 0.8
	material.metallic = 0.0
	
	# Add subtle emission for magical feel
	material.emission_enabled = true
	material.emission = Color(0.2, 0.3, 0.1, 1.0)
	material.emission_energy = 0.3
	
	# Double-sided for cave interiors
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	return material

func clear_previous_world():
	"""Clear any previously generated content"""
	if terrain_mesh_instance:
		terrain_mesh_instance.queue_free()
		terrain_mesh_instance = null
	
	if collision_body:
		collision_body.queue_free()
		collision_body = null



# === PUBLIC API ===
func regenerate_world():
	"""Regenerate the world with new random seed"""
	setup_noise_generators()  # New random seed
	generate_world_async()

func set_terrain_parameters(params: Dictionary):
	"""Update terrain parameters"""
	if params.has("height"):
		terrain_height = params.height
	if params.has("noise_frequency"):
		terrain_noise_frequency = params.noise_frequency
		if noise_terrain:
			noise_terrain.frequency = terrain_noise_frequency

func set_cave_parameters(params: Dictionary):
	"""Update cave parameters"""
	if params.has("density"):
		cave_density = params.density
	if params.has("size_multiplier"):
		cave_size_multiplier = params.size_multiplier
	if params.has("noise_frequency"):
		cave_noise_frequency = params.noise_frequency
		if noise_cave_primary:
			noise_cave_primary.frequency = cave_noise_frequency
			noise_cave_secondary.frequency = cave_noise_frequency * 2.0
			noise_cave_detail.frequency = cave_noise_frequency * 4.0

func get_generation_info() -> Dictionary:
	"""Get information about the generated world"""
	var total_vertices = 0
	var total_triangles = 0
	
	if terrain_mesh_instance and terrain_mesh_instance.mesh:
		var mesh = terrain_mesh_instance.mesh as ArrayMesh
		if mesh.get_surface_count() > 0:
			var arrays = mesh.surface_get_arrays(0)
			var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			
			total_vertices = vertices.size()
			total_triangles = indices.size() / 3
	
	return {
		"generation_time": generation_time,
		"total_vertices": total_vertices,
		"total_triangles": total_triangles,
		"voxel_resolution": voxel_resolution,
		"world_size": world_size,
		"terrain_height": terrain_height,
		"cave_density": cave_density,
		"gpu_accelerated": use_gpu_acceleration,
		"cpu_optimized": not use_gpu_acceleration
	}

func _exit_tree():
	"""Clean up resources"""
	if gpu_marching_cubes:
		gpu_marching_cubes.cleanup()
	# No special cleanup needed for CPU implementation

# === UI INTERACTION METHODS ===
func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				regenerate_world()

func _on_generation_complete(time: float):
	"""Handle generation completion"""
	update_stats_display()

func _on_generation_progress(percentage: float):
	"""Handle generation progress updates"""
	var progress_bar = get_node_or_null("UI/ControlsPanel/ControlsContainer/ProgressBar")
	if progress_bar:
		progress_bar.value = percentage

func _on_regenerate_button_pressed():
	"""Handle regenerate button press"""
	regenerate_world()

func _on_terrain_height_slider_value_changed(value: float):
	"""Handle terrain height slider change"""
	set_terrain_parameters({"height": value})

func _on_cave_density_slider_value_changed(value: float):
	"""Handle cave density slider change"""
	set_cave_parameters({"density": value})

func update_stats_display():
	"""Update the statistics display"""
	var stats_label = get_node_or_null("UI/InfoPanel/InfoContainer/StatsLabel")
	if stats_label:
		var info = get_generation_info()
		var acceleration_type = "GPU Accelerated" if info.gpu_accelerated else "CPU Optimized"
		var stats_text = """[b]Performance Stats:[/b]
Generation Time: %.2f seconds
Vertices: %s
Triangles: %s
%s: Yes

[color=yellow]Controls:[/color]
R - Regenerate World
Mouse - Look Around
WASD - Move Camera""" % [
			info.generation_time,
			format_number(info.total_vertices),
			format_number(info.total_triangles),
			acceleration_type
		]
		stats_label.text = stats_text

func format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	
	return result
