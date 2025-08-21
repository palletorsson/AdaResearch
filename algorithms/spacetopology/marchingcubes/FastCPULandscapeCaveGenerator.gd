# FastCPULandscapeCaveGenerator.gd
# High-performance CPU landscape + cave generator
# Optimized for speed while maintaining quality

extends Node3D
class_name FastCPULandscapeCaveGenerator

# === GENERATION PARAMETERS ===
@export_group("World Configuration")
@export var world_size: Vector3 = Vector3(80, 30, 80)
@export var voxel_resolution: Vector3i = Vector3i(64, 32, 64)  # Optimized resolution
@export var auto_generate_on_ready: bool = true

@export_group("Terrain Parameters")
@export var terrain_height: float = 12.0
@export var terrain_noise_frequency: float = 0.025
@export var terrain_octaves: int = 4
@export var terrain_persistence: float = 0.6

@export_group("Cave Parameters")
@export var cave_density: float = 0.35
@export var cave_noise_frequency: float = 0.018
@export var cave_size_multiplier: float = 1.8
@export var cave_min_height: float = -8.0
@export var cave_max_height: float = 6.0
@export var cave_vertical_bias: float = 0.4

@export_group("Visual Settings")
@export var material_terrain: Material
@export var generate_collision: bool = true
@export var show_generation_progress: bool = true

# === NOISE GENERATORS ===
var noise_terrain: FastNoiseLite
var noise_cave_primary: FastNoiseLite
var noise_cave_secondary: FastNoiseLite
var noise_cave_detail: FastNoiseLite

# === MARCHING CUBES ===
var marching_cubes: MarchingCubesGenerator

# === GENERATED CONTENT ===
var terrain_mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var generation_time: float = 0.0

# === SIGNALS ===
signal generation_complete(generation_time: float)
signal generation_progress(percentage: float)

func _ready():
	setup_noise_generators()
	setup_marching_cubes()
	
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
	
	print("FastCPULandscapeCaveGenerator: Noise generators initialized")

func setup_marching_cubes():
	"""Initialize marching cubes system"""
	marching_cubes = MarchingCubesGenerator.new()
	marching_cubes.threshold = 0.5
	marching_cubes.smoothing_enabled = true
	
	print("FastCPULandscapeCaveGenerator: Marching cubes initialized")

func generate_world_async():
	"""Generate the complete world asynchronously using optimized CPU approach"""
	var start_time = Time.get_ticks_msec()
	print("FastCPULandscapeCaveGenerator: Starting optimized world generation...")
	
	if show_generation_progress:
		generation_progress.emit(0.0)
	
	# Clear previous generation
	clear_previous_world()
	
	# Step 1: Create voxel chunk with optimized density field (40%)
	print("FastCPULandscapeCaveGenerator: Step 1/3 - Creating voxel chunk...")
	var chunk = await create_optimized_voxel_chunk()
	if show_generation_progress:
		generation_progress.emit(40.0)
	
	# Step 2: Generate mesh using proven marching cubes (40%)
	print("FastCPULandscapeCaveGenerator: Step 2/3 - Generating mesh...")
	var mesh = await generate_mesh_from_chunk(chunk)
	if show_generation_progress:
		generation_progress.emit(80.0)
	
	# Step 3: Create visual representation and collision (20%)
	print("FastCPULandscapeCaveGenerator: Step 3/3 - Creating visual representation...")
	create_mesh_instance(mesh)
	
	if generate_collision:
		create_collision_shape(mesh)
	
	if show_generation_progress:
		generation_progress.emit(100.0)
	
	var end_time = Time.get_ticks_msec()
	generation_time = (end_time - start_time) / 1000.0
	
	generation_complete.emit(generation_time)
	print("FastCPULandscapeCaveGenerator: World generation complete in %.2f seconds!" % generation_time)

func create_optimized_voxel_chunk() -> VoxelChunk:
	"""Create a single optimized voxel chunk for the entire world"""
	var chunk_world_pos = -world_size * 0.5
	var voxel_scale = world_size.x / (voxel_resolution.x - 1)
	
	var chunk = VoxelChunk.new(voxel_resolution, chunk_world_pos, voxel_scale)
	chunk.chunk_name = "OptimizedLandscapeChunk"
	
	# Calculate total voxels for progress tracking
	var total_voxels = (voxel_resolution.x + 1) * (voxel_resolution.y + 1) * (voxel_resolution.z + 1)
	var processed_voxels = 0
	var voxels_per_frame = max(1000, total_voxels / 30)  # Process in batches
	
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
					var progress = float(processed_voxels) / float(total_voxels) * 35.0  # 35% of total progress
					if show_generation_progress:
						generation_progress.emit(5.0 + progress)
					await get_tree().process_frame
	
	return chunk

func calculate_unified_density(world_pos: Vector3) -> float:
	"""Calculate density combining terrain and cave systems - OPTIMIZED"""
	
	# === TERRAIN SURFACE ===
	# Use multiple octaves for realistic terrain
	var terrain_base = noise_terrain.get_noise_2d(world_pos.x, world_pos.z)
	var terrain_detail = noise_terrain.get_noise_2d(world_pos.x * 2.0, world_pos.z * 2.0) * 0.3
	var terrain_surface_height = (terrain_base + terrain_detail) * terrain_height
	
	# Distance from terrain surface
	var distance_from_terrain = world_pos.y - terrain_surface_height
	
	# Terrain density with proper iso-level crossing
	var terrain_density: float
	if distance_from_terrain <= -4.0:
		terrain_density = 0.95  # Deep solid
	elif distance_from_terrain <= -1.0:
		# Smooth transition zone
		var t = (-distance_from_terrain - 1.0) / 3.0
		terrain_density = lerp(0.75, 0.95, t)
	elif distance_from_terrain <= 0.0:
		# Surface crossing zone - critical for proper marching cubes
		var t = -distance_from_terrain
		terrain_density = lerp(0.25, 0.75, t)
	elif distance_from_terrain <= 2.0:
		# Air transition
		var t = distance_from_terrain / 2.0
		terrain_density = lerp(0.25, 0.05, t)
	else:
		terrain_density = 0.05  # Definitely air
	
	# === CAVE SYSTEM ===
	var final_density = terrain_density
	
	# Only generate caves in solid terrain and within height range
	if (world_pos.y >= cave_min_height and world_pos.y <= cave_max_height and 
		terrain_density > 0.5):
		
		# Primary cave structure - creates main chambers
		var cave_primary = noise_cave_primary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		
		# Secondary cave structure - adds complexity
		var cave_secondary = noise_cave_secondary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.6
		
		# Cave detail - surface texture
		var cave_detail = noise_cave_detail.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.3
		
		# Vertical bias - prefer horizontal caves
		var height_factor = abs(world_pos.y) / max(terrain_height, 1.0)
		var vertical_bias_factor = 1.0 - (height_factor * cave_vertical_bias)
		
		# Combine cave noises
		var combined_cave_noise = cave_primary + cave_secondary + cave_detail
		combined_cave_noise *= vertical_bias_factor
		
		# Cave carving - positive values create caves
		var cave_threshold = (combined_cave_noise + 1.0) * 0.5  # Normalize to 0-1
		if cave_threshold > (1.0 - cave_density):
			# Carve cave - reduce density significantly
			var carve_amount = (cave_threshold - (1.0 - cave_density)) / cave_density
			carve_amount = clamp(carve_amount * cave_size_multiplier, 0.0, 1.0)
			final_density = lerp(final_density, 0.1, carve_amount)
	
	return clamp(final_density, 0.0, 1.0)

func generate_mesh_from_chunk(chunk: VoxelChunk) -> ArrayMesh:
	"""Generate mesh using proven marching cubes implementation"""
	print("FastCPULandscapeCaveGenerator: Generating mesh from %s voxels..." % [voxel_resolution])
	
	# Use the proven marching cubes generator
	var mesh = marching_cubes.generate_mesh_from_chunk(chunk)
	
	await get_tree().process_frame  # Allow for UI updates
	return mesh

func create_mesh_instance(mesh: ArrayMesh):
	"""Create visual mesh instance with appropriate material"""
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "FastLandscapeCaveMesh"
	terrain_mesh_instance.mesh = mesh
	
	# Apply material
	var material = get_landscape_material()
	if mesh.get_surface_count() > 0:
		terrain_mesh_instance.set_surface_override_material(0, material)
	
	add_child(terrain_mesh_instance)
	print("FastCPULandscapeCaveGenerator: Mesh instance created")

func create_collision_shape(mesh: ArrayMesh):
	"""Create collision shape for physics interaction"""
	if mesh.get_surface_count() == 0:
		return
	
	collision_body = StaticBody3D.new()
	collision_body.name = "FastLandscapeCaveCollision"
	
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
	print("FastCPULandscapeCaveGenerator: Collision shape created")

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
		"cpu_optimized": true
	}

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
		var stats_text = """[b]Performance Stats:[/b]
Generation Time: %.2f seconds
Vertices: %s
Triangles: %s
CPU Optimized: Yes

[color=yellow]Controls:[/color]
R - Regenerate World
Mouse - Look Around
WASD - Move Camera""" % [
			info.generation_time,
			format_number(info.total_vertices),
			format_number(info.total_triangles)
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
