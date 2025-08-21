# LandscapeCaveGenerator.gd
# Unified marching cubes implementation for generating landscapes with caves
# Inspired by Unity's MeshGenerator with GDScript optimizations
# Combines terrain generation with cave systems using density fields

extends Node3D
class_name LandscapeCaveGenerator

# === GENERAL SETTINGS ===
@export_group("General Settings")
@export var auto_update_in_editor: bool = true
@export var auto_update_in_game: bool = true
@export var generate_colliders: bool = true
@export var fixed_map_size: bool = true

# === WORLD SIZE AND CHUNKS ===
@export_group("World Configuration")
@export var num_chunks: Vector3i = Vector3i(4, 1, 4)  # Chunk grid size
@export var bounds_size: float = 20.0  # Size of each chunk in world units
@export var viewer_distance: float = 60.0  # For infinite terrain mode
@export var viewer: Node3D  # Reference to player/camera for infinite terrain

# === VOXEL SETTINGS ===
@export_group("Voxel Settings")
@export var iso_level: float = 0.5
@export var num_points_per_axis: int = 32  # Voxel resolution per chunk
@export var offset: Vector3 = Vector3.ZERO

# === TERRAIN GENERATION ===
@export_group("Terrain Parameters")
@export var terrain_height: float = 8.0
@export var terrain_noise_frequency: float = 0.02
@export var terrain_octaves: int = 4
@export var terrain_persistence: float = 0.5
@export var terrain_lacunarity: float = 2.0

# === CAVE GENERATION ===
@export_group("Cave Parameters")
@export var cave_density: float = 0.3  # How much cave vs solid
@export var cave_noise_frequency: float = 0.015
@export var cave_size_multiplier: float = 1.5
@export var cave_vertical_bias: float = 0.2  # Prefer horizontal caves
@export var cave_min_height: float = -5.0  # Caves only below this height
@export var cave_max_height: float = 3.0   # Caves only above this height

# === VISUAL SETTINGS ===
@export_group("Visuals")
@export var show_wireframe: bool = false
@export var show_bounds_gizmo: bool = true
@export var bounds_gizmo_color: Color = Color.WHITE
@export var terrain_material: Material
@export var cave_material: Material

# === COMPONENTS ===
var noise_terrain: FastNoiseLite
var noise_cave_primary: FastNoiseLite
var noise_cave_secondary: FastNoiseLite
var noise_cave_detail: FastNoiseLite

# Marching cubes lookup tables
var edge_table: Array[int] = []
var triangle_table: Array[Array] = []

# Chunk management
var chunks: Array[TerrainChunk] = []
var chunk_holder: Node3D
var existing_chunks: Dictionary = {}
var recycleable_chunks: Array[TerrainChunk] = []

# Generation state
var settings_updated: bool = false
var is_generating: bool = false

# === DATA STRUCTURES ===
class TerrainChunk:
	var coord: Vector3i
	var mesh_instance: MeshInstance3D
	var collision_body: StaticBody3D
	var collision_shape: CollisionShape3D
	var world_bounds: AABB
	var mesh: ArrayMesh
	var density_field: Array = []
	var is_dirty: bool = true
	
	func _init(chunk_coord: Vector3i, bounds: AABB):
		coord = chunk_coord
		world_bounds = bounds
		
		# Create visual mesh
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Chunk_%d_%d_%d" % [coord.x, coord.y, coord.z]
		
		# Create collision
		collision_body = StaticBody3D.new()
		collision_shape = CollisionShape3D.new()
		collision_body.add_child(collision_shape)
		collision_body.name = "Chunk_Collision_%d_%d_%d" % [coord.x, coord.y, coord.z]
	
	func set_up(material: Material, generate_collision: bool):
		if material:
			mesh_instance.set_surface_override_material(0, material)
		
		collision_body.visible = false  # Collision doesn't need to be visible
		
	func destroy_or_disable():
		if mesh_instance:
			mesh_instance.queue_free()
		if collision_body:
			collision_body.queue_free()

class Triangle:
	var vertices: Array[Vector3]
	var normals: Array[Vector3]
	
	func _init(v1: Vector3, v2: Vector3, v3: Vector3):
		vertices = [v1, v2, v3]
		# Calculate normal
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var normal = edge1.cross(edge2).normalized()
		normals = [normal, normal, normal]

# === INITIALIZATION ===
func _ready():
	setup_noise_generators()
	setup_marching_cubes_tables()
	
	if auto_update_in_editor or (Engine.is_editor_hint() == false and auto_update_in_game):
		call_deferred("generate_world")

func setup_noise_generators():
	"""Initialize all noise generators with proper parameters"""
	var base_seed = randi()
	
	# Terrain height noise
	noise_terrain = FastNoiseLite.new()
	noise_terrain.seed = base_seed
	noise_terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_terrain.frequency = terrain_noise_frequency
	noise_terrain.fractal_octaves = terrain_octaves
	noise_terrain.fractal_gain = terrain_persistence
	noise_terrain.fractal_lacunarity = terrain_lacunarity
	
	# Primary cave structure
	noise_cave_primary = FastNoiseLite.new()
	noise_cave_primary.seed = base_seed + 1000
	noise_cave_primary.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_cave_primary.frequency = cave_noise_frequency
	noise_cave_primary.fractal_octaves = 3
	noise_cave_primary.fractal_gain = 0.6
	
	# Secondary cave variation
	noise_cave_secondary = FastNoiseLite.new()
	noise_cave_secondary.seed = base_seed + 2000
	noise_cave_secondary.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_cave_secondary.frequency = cave_noise_frequency * 2.0
	noise_cave_secondary.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	# Cave detail noise
	noise_cave_detail = FastNoiseLite.new()
	noise_cave_detail.seed = base_seed + 3000
	noise_cave_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_cave_detail.frequency = cave_noise_frequency * 4.0
	
	print("LandscapeCaveGenerator: Noise generators initialized")

func setup_marching_cubes_tables():
	"""Initialize marching cubes lookup tables"""
	# Use the proper lookup tables class
	edge_table = MarchingCubesLookupTables.get_edge_table()
	triangle_table = MarchingCubesLookupTables.get_triangle_table()
	print("LandscapeCaveGenerator: Marching cubes tables initialized")

# === MAIN GENERATION FUNCTIONS ===
func _process(delta):
	if settings_updated and not is_generating:
		generate_world()
		settings_updated = false

func generate_world():
	"""Main world generation function - unified landscape and caves"""
	if is_generating:
		return
		
	is_generating = true
	print("LandscapeCaveGenerator: Starting world generation...")
	
	if fixed_map_size:
		await generate_fixed_world()
	else:
		await generate_infinite_world()
	
	is_generating = false
	print("LandscapeCaveGenerator: World generation complete!")

func generate_fixed_world():
	"""Generate a fixed-size world with chunks"""
	create_chunk_holder()
	await init_chunks()
	await update_all_chunks()

func generate_infinite_world():
	"""Generate infinite world around viewer"""
	if not viewer:
		print("LandscapeCaveGenerator: No viewer set for infinite world")
		return
	
	create_chunk_holder()
	await init_visible_chunks()

func init_chunks():
	"""Initialize all chunks for fixed world"""
	chunks.clear()
	
	# Calculate total world bounds
	var total_bounds = Vector3(num_chunks) * bounds_size
	var start_pos = -total_bounds * 0.5
	
	# Create chunks
	for x in range(num_chunks.x):
		for y in range(num_chunks.y):
			for z in range(num_chunks.z):
				var coord = Vector3i(x, y, z)
				var chunk_pos = start_pos + Vector3(coord) * bounds_size
				var chunk_bounds = AABB(chunk_pos, Vector3.ONE * bounds_size)
				
				var chunk = TerrainChunk.new(coord, chunk_bounds)
				chunk.set_up(get_material_for_chunk(coord), generate_colliders)
				chunks.append(chunk)
	
	print("LandscapeCaveGenerator: Created %d chunks" % chunks.size())

func init_visible_chunks():
	"""Initialize chunks around viewer for infinite world"""
	if not viewer:
		return
	
	var viewer_pos = viewer.global_position
	var viewer_coord = Vector3i(
		round(viewer_pos.x / bounds_size),
		round(viewer_pos.y / bounds_size),
		round(viewer_pos.z / bounds_size)
	)
	
	var max_chunks_in_view = int(ceil(viewer_distance / bounds_size))
	var sqr_view_distance = viewer_distance * viewer_distance
	
	# Remove chunks outside view distance
	for i in range(chunks.size() - 1, -1, -1):
		var chunk = chunks[i]
		var chunk_center = chunk.world_bounds.get_center()
		var distance_sqr = viewer_pos.distance_squared_to(chunk_center)
		
		if distance_sqr > sqr_view_distance:
			existing_chunks.erase(chunk.coord)
			recycleable_chunks.append(chunk)
			chunks.remove_at(i)
	
	# Add new chunks in view
	for x in range(-max_chunks_in_view, max_chunks_in_view + 1):
		for y in range(-max_chunks_in_view, max_chunks_in_view + 1):
			for z in range(-max_chunks_in_view, max_chunks_in_view + 1):
				var coord = Vector3i(x, y, z) + viewer_coord
				
				if existing_chunks.has(coord):
					continue
				
				var chunk_pos = Vector3(coord) * bounds_size
				var distance_sqr = viewer_pos.distance_squared_to(chunk_pos)
				
				if distance_sqr <= sqr_view_distance:
					var chunk_bounds = AABB(chunk_pos, Vector3.ONE * bounds_size)
					var chunk: TerrainChunk
					
					if recycleable_chunks.size() > 0:
						chunk = recycleable_chunks.pop_back()
						chunk.coord = coord
						chunk.world_bounds = chunk_bounds
						chunk.is_dirty = true
					else:
						chunk = TerrainChunk.new(coord, chunk_bounds)
					
					chunk.set_up(get_material_for_chunk(coord), generate_colliders)
					existing_chunks[coord] = chunk
					chunks.append(chunk)
					
					# Update this chunk immediately
					await update_chunk_mesh(chunk)

func update_all_chunks():
	"""Update all chunks with mesh generation"""
	var chunks_per_frame = max(1, chunks.size() / 10)
	var processed = 0
	
	for chunk in chunks:
		await update_chunk_mesh(chunk)
		processed += 1
		
		# Yield periodically to prevent blocking
		if processed % chunks_per_frame == 0:
			await get_tree().process_frame

func update_chunk_mesh(chunk: TerrainChunk):
	"""Update a single chunk's mesh using marching cubes"""
	var point_spacing = bounds_size / (num_points_per_axis - 1)
	
	# Generate density field
	await generate_density_field(chunk, point_spacing)
	
	# Apply marching cubes algorithm
	var triangles = march_cubes_in_chunk(chunk, point_spacing)
	
	# Create mesh from triangles
	create_mesh_from_triangles(chunk, triangles)
	
	# Add to scene
	if chunk.mesh_instance.mesh and chunk.mesh_instance.mesh.get_surface_count() > 0:
		chunk_holder.add_child(chunk.mesh_instance)
		
		if generate_colliders:
			create_collision_for_chunk(chunk)
			chunk_holder.add_child(chunk.collision_body)

# === DENSITY FIELD GENERATION ===
func generate_density_field(chunk: TerrainChunk, point_spacing: float):
	"""Generate density field combining terrain and caves"""
	var field_size = num_points_per_axis
	chunk.density_field.clear()
	chunk.density_field.resize(field_size * field_size * field_size)
	
	var chunk_start = chunk.world_bounds.position
	
	for x in range(field_size):
		for y in range(field_size):
			for z in range(field_size):
				var local_pos = Vector3(x, y, z) * point_spacing
				var world_pos = chunk_start + local_pos + offset
				
				var density = calculate_density_at_position(world_pos)
				var index = x + y * field_size + z * field_size * field_size
				chunk.density_field[index] = density
	
	# Yield occasionally to prevent blocking
	if randf() < 0.1:  # 10% chance to yield per chunk
		await get_tree().process_frame

func calculate_density_at_position(world_pos: Vector3) -> float:
	"""Calculate density combining terrain surface and cave systems - FIXED"""
	
	# === TERRAIN SURFACE ===
	var terrain_height_noise = noise_terrain.get_noise_2d(world_pos.x, world_pos.z)
	var terrain_surface_height = terrain_height_noise * terrain_height
	
	# Distance from terrain surface (negative = below surface = solid)
	var distance_from_terrain = world_pos.y - terrain_surface_height
	
	# Base terrain density - values > 0.5 = solid, < 0.5 = air
	var terrain_density = 0.0
	if distance_from_terrain <= -3.0:
		terrain_density = 0.9  # Deep underground = definitely solid
	elif distance_from_terrain <= -1.0:
		# Transition zone - map -3 to -1 → 0.9 to 0.7
		var t = (-distance_from_terrain - 1.0) / 2.0  # 0 to 1
		terrain_density = lerp(0.7, 0.9, t)
	elif distance_from_terrain <= 0.0:
		# Surface zone - map -1 to 0 → 0.7 to 0.3
		var t = -distance_from_terrain  # 0 to 1
		terrain_density = lerp(0.3, 0.7, t)
	elif distance_from_terrain <= 1.0:
		# Air transition - map 0 to 1 → 0.3 to 0.1
		var t = distance_from_terrain  # 0 to 1
		terrain_density = lerp(0.3, 0.1, t)
	else:
		terrain_density = 0.1  # High above surface = definitely air
	
	# === CAVE SYSTEM ===
	var final_density = terrain_density
	
	# Only generate caves within specified height range and in solid terrain
	if (world_pos.y >= cave_min_height and world_pos.y <= cave_max_height and 
		terrain_density > 0.5):  # Only carve caves in solid terrain
		
		# Primary cave structure
		var cave_primary = noise_cave_primary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
		
		# Secondary cave variation
		var cave_secondary = noise_cave_secondary.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.5
		
		# Cave detail noise
		var cave_detail = noise_cave_detail.get_noise_3d(world_pos.x, world_pos.y, world_pos.z) * 0.3
		
		# Vertical bias - prefer horizontal caves
		var height_factor = abs(world_pos.y) / max(terrain_height, 1.0)
		var vertical_bias_factor = 1.0 - (height_factor * cave_vertical_bias)
		
		# Combine cave noises
		var combined_cave_noise = cave_primary + cave_secondary + cave_detail
		combined_cave_noise *= vertical_bias_factor
		
		# Cave threshold - positive values create caves
		var cave_threshold = (combined_cave_noise + 1.0) * 0.5  # Normalize to 0-1
		if cave_threshold > (1.0 - cave_density):
			# This is a cave - reduce density significantly
			final_density = lerp(final_density, 0.2, cave_size_multiplier)
	
	return clamp(final_density, 0.0, 1.0)

# === MARCHING CUBES IMPLEMENTATION ===
func march_cubes_in_chunk(chunk: TerrainChunk, point_spacing: float) -> Array[Triangle]:
	"""Apply marching cubes algorithm to chunk"""
	var triangles: Array[Triangle] = []
	var field_size = num_points_per_axis
	var chunk_start = chunk.world_bounds.position
	
	# Process each cube in the voxel grid
	for x in range(field_size - 1):
		for y in range(field_size - 1):
			for z in range(field_size - 1):
				var cube_triangles = process_marching_cube(
					chunk, Vector3i(x, y, z), point_spacing, chunk_start
				)
				triangles.append_array(cube_triangles)
	
	return triangles

func process_marching_cube(chunk: TerrainChunk, cube_pos: Vector3i, point_spacing: float, chunk_start: Vector3) -> Array[Triangle]:
	"""Process a single cube with marching cubes algorithm - FIXED VERSION"""
	var triangles: Array[Triangle] = []
	var field_size = num_points_per_axis
	
	# Get the 8 corner densities and positions (marching cubes order)
	var cube_densities: Array[float] = []
	var cube_positions: Array[Vector3] = []
	
	# Standard marching cubes vertex order
	var cube_offsets = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),  # Bottom face
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)   # Top face
	]
	
	for i in range(8):
		var corner_pos = cube_pos + cube_offsets[i]
		var world_pos = chunk_start + Vector3(corner_pos) * point_spacing
		
		var density_index = corner_pos.x + corner_pos.y * field_size + corner_pos.z * field_size * field_size
		var density = 0.0
		if density_index < chunk.density_field.size():
			density = chunk.density_field[density_index]
		
		cube_densities.append(density)
		cube_positions.append(world_pos)
	
	# Create cube data dictionary for compatibility
	var cube_data = {
		"positions": cube_positions,
		"densities": cube_densities
	}
	
	# Use the working marching cubes logic
	return march_cube_fixed(cube_data)

func march_cube_fixed(cube_data: Dictionary) -> Array[Triangle]:
	"""FIXED: Apply marching cubes algorithm with proper configuration handling"""
	var triangles: Array[Triangle] = []
	
	# Calculate configuration index
	var config_index = 0
	var inside_count = 0
	
	for i in range(8):
		var density = cube_data.densities[i]
		if density < iso_level:
			config_index |= (1 << i)
		else:
			inside_count += 1
	
	# Skip completely inside or outside cubes
	if config_index == 0 or config_index == 255:
		return triangles
	
	# Get triangulation from lookup table
	if config_index >= triangle_table.size():
		print("ERROR: Invalid configuration index %d (max %d)" % [config_index, triangle_table.size() - 1])
		return triangles
	
	var triangle_config = triangle_table[config_index]
	if triangle_config == null or triangle_config.is_empty():
		return triangles
	
	# Calculate edge intersections
	var edge_vertices = calculate_edge_intersections_fixed(cube_data)
	
	# Generate triangles
	var i = 0
	while i < triangle_config.size() and triangle_config[i] >= 0:
		if i + 2 < triangle_config.size():
			var v1 = edge_vertices[triangle_config[i]]
			var v2 = edge_vertices[triangle_config[i + 1]] 
			var v3 = edge_vertices[triangle_config[i + 2]]
			
			if v1 != null and v2 != null and v3 != null:
				triangles.append(Triangle.new(v1, v2, v3))
		i += 3
	
	return triangles

func calculate_edge_intersections_fixed(cube_data: Dictionary) -> Array:
	"""Calculate vertex positions on cube edges"""
	var edge_vertices = []
	edge_vertices.resize(12)
	
	# Edge connections (which vertices each edge connects)
	var edge_connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face edges
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face edges
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	for i in range(12):
		var v1_idx = edge_connections[i][0]
		var v2_idx = edge_connections[i][1]
		
		var v1_pos = cube_data.positions[v1_idx]
		var v2_pos = cube_data.positions[v2_idx]
		var v1_density = cube_data.densities[v1_idx]
		var v2_density = cube_data.densities[v2_idx]
		
		# Check if edge crosses the isosurface
		if (v1_density < iso_level) != (v2_density < iso_level):
			# Interpolate vertex position
			var t = (iso_level - v1_density) / (v2_density - v1_density)
			t = clamp(t, 0.0, 1.0)  # Safety clamp
			edge_vertices[i] = v1_pos.lerp(v2_pos, t)
		else:
			edge_vertices[i] = null
	
	return edge_vertices



# === MESH CREATION ===
func create_mesh_from_triangles(chunk: TerrainChunk, triangles: Array[Triangle]):
	"""Create ArrayMesh from triangle array"""
	if triangles.is_empty():
		return
	
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array = []
	
	# Convert triangles to mesh arrays
	for triangle in triangles:
		var base_index = vertices.size()
		
		# Add vertices and normals
		for i in range(3):
			vertices.append(triangle.vertices[i])
			normals.append(triangle.normals[i])
			indices.append(base_index + i)
	
	# Create mesh
	chunk.mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	chunk.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	chunk.mesh_instance.mesh = chunk.mesh
	
	# Apply material
	var material = get_material_for_chunk(chunk.coord)
	if material:
		chunk.mesh_instance.set_surface_override_material(0, material)
	
	print("LandscapeCaveGenerator: Created mesh with %d triangles for chunk %s" % [triangles.size(), chunk.coord])

func create_collision_for_chunk(chunk: TerrainChunk):
	"""Create collision shape for chunk"""
	if not chunk.mesh or chunk.mesh.get_surface_count() == 0:
		return
	
	var shape = ConcavePolygonShape3D.new()
	var collision_faces: PackedVector3Array = []
	
	# Get vertex data from mesh
	var arrays = chunk.mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	# Create collision faces
	for i in range(0, indices.size(), 3):
		if i + 2 < indices.size():
			collision_faces.append(vertices[indices[i]])
			collision_faces.append(vertices[indices[i + 1]])
			collision_faces.append(vertices[indices[i + 2]])
	
	shape.set_faces(collision_faces)
	chunk.collision_shape.shape = shape

# === UTILITY FUNCTIONS ===
func create_chunk_holder():
	"""Create or find chunk holder node"""
	if chunk_holder == null:
		var existing = get_node_or_null("ChunkHolder")
		if existing:
			chunk_holder = existing
		else:
			chunk_holder = Node3D.new()
			chunk_holder.name = "ChunkHolder"
			add_child(chunk_holder)

func get_material_for_chunk(coord: Vector3i) -> Material:
	"""Get appropriate material for chunk based on content"""
	# Simple material selection - could be enhanced
	if terrain_material:
		return terrain_material
	
	# Default material
	var material = StandardMaterial3D.new()
	
	# Vary color slightly based on chunk position
	var hue = fmod(coord.x * 0.1 + coord.z * 0.05, 1.0)
	material.albedo_color = Color.from_hsv(0.3 + hue * 0.2, 0.6, 0.8)
	material.roughness = 0.8
	material.metallic = 0.0
	
	if show_wireframe:
		material.wireframe = true
		material.flags_transparent = true
		material.albedo_color = Color.WHITE
	
	return material

# === PUBLIC API ===
func regenerate_world():
	"""Public function to regenerate the world"""
	clear_world()
	generate_world()

func clear_world():
	"""Clear all generated chunks"""
	for chunk in chunks:
		chunk.destroy_or_disable()
	
	chunks.clear()
	existing_chunks.clear()
	recycleable_chunks.clear()

func set_terrain_parameters(params: Dictionary):
	"""Set terrain generation parameters"""
	if params.has("height"):
		terrain_height = params.height
	if params.has("noise_frequency"):
		terrain_noise_frequency = params.noise_frequency
		if noise_terrain:
			noise_terrain.frequency = terrain_noise_frequency
	
	settings_updated = true

func set_cave_parameters(params: Dictionary):
	"""Set cave generation parameters"""
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
	
	settings_updated = true

func get_generation_info() -> Dictionary:
	"""Get information about current generation"""
	var total_triangles = 0
	var total_vertices = 0
	
	for chunk in chunks:
		if chunk.mesh and chunk.mesh.get_surface_count() > 0:
			var arrays = chunk.mesh.surface_get_arrays(0)
			var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			
			total_vertices += vertices.size()
			total_triangles += indices.size() / 3
	
	return {
		"chunks": chunks.size(),
		"total_triangles": total_triangles,
		"total_vertices": total_vertices,
		"bounds_size": bounds_size,
		"terrain_height": terrain_height,
		"cave_density": cave_density
	}

# === EDITOR INTEGRATION ===
func _on_validate():
	"""Called when properties change in editor"""
	settings_updated = true

# === GIZMO DRAWING ===
func _draw_gizmos():
	"""Draw chunk bounds gizmos"""
	if not show_bounds_gizmo:
		return
	
	# This would need to be implemented with a custom EditorPlugin for actual gizmo drawing
	# For now, we can visualize bounds with debug mesh instances

# === UI INTERACTION ===
func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				regenerate_world()

func _on_regenerate_button_pressed():
	"""Handle regenerate button press"""
	regenerate_world()

func _on_cave_density_slider_value_changed(value: float):
	"""Handle cave density slider change"""
	cave_density = value
	settings_updated = true

func _on_terrain_height_slider_value_changed(value: float):
	"""Handle terrain height slider change"""
	terrain_height = value
	settings_updated = true
