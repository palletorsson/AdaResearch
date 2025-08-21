# MarchingCubesGenerator.gd - FIXED VERSION
# Generates seamless meshes from voxel data with proper boundary handling

extends RefCounted
class_name MarchingCubesGenerator

# Core parameters
var threshold: float = 0.5
var smoothing_enabled: bool = true

# Components
var lookup_tables: MarchingCubesLookupTables
var terrain_generator_ref: TerrainGenerator = null  # CRITICAL: Reference for boundary calculations

# Performance tracking
var total_cubes_processed: int = 0
var total_triangles_generated: int = 0

func _init():
	lookup_tables = MarchingCubesLookupTables.new()
	print("MarchingCubesGenerator: Initialized with seamless boundary support")

func generate_mesh_from_chunk(chunk: VoxelChunk) -> ArrayMesh:
	"""FIXED: Generate mesh with seamless boundary handling"""
	if chunk == null or chunk.density_data.is_empty():
		print("MarchingCubesGenerator: Invalid chunk data")
		return null
	
	# Check if chunk has valid density data
	if not validate_chunk_data(chunk):
		print("MarchingCubesGenerator: Chunk validation failed")
		return null
	
	# Arrays for mesh generation
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array = []
	var current_vertex_index: int = 0
	
	# Reset counters
	total_cubes_processed = 0
	var cubes_with_geometry = 0
	
	# FIXED: March through ALL cubes in chunk (not just interior)
	for x in range(chunk.chunk_size.x):
		for y in range(chunk.chunk_size.y):
			for z in range(chunk.chunk_size.z):
				var cube_pos = Vector3i(x, y, z)
				
				# CRITICAL: Use boundary-safe cube data
				var cube_data = get_cube_vertices_safe(chunk, cube_pos)
				
				if not is_valid_cube_data(cube_data):
					continue
				
				# Generate triangles for this cube
				var triangles = march_cube_fixed(cube_data)
				total_cubes_processed += 1
				
				if triangles.size() > 0:
					cubes_with_geometry += 1
					
					# Add triangles to mesh arrays
					for triangle in triangles:
						# Add vertices
						for i in range(3):
							vertices.append(triangle.vertices[i])
							normals.append(triangle.normals[i])
							indices.append(current_vertex_index)
							current_vertex_index += 1
	
	total_triangles_generated = indices.size() / 3
	
	# Create the mesh
	var mesh = ArrayMesh.new()
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		print("MarchingCubes: Generated mesh with %d vertices, %d triangles, %d indices" % 
			[vertices.size(), total_triangles_generated, indices.size()])
		print("MarchingCubes: Surface has %d vertices, %d indices" % [vertices.size(), indices.size()])
	else:
		print("MarchingCubes: No geometry generated - all densities might be uniform")
	
	# Cache the result
	chunk.cached_mesh = mesh
	chunk.is_dirty = false
	
	return mesh

func get_cube_vertices_safe(chunk: VoxelChunk, cube_pos: Vector3i) -> Dictionary:
	"""FIXED: Get cube vertices with seamless boundary handling"""
	var cube_data = {
		"positions": [],
		"densities": []
	}
	
	# Standard cube vertex offsets (marching cubes order)
	var cube_verts = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),  # Bottom face
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)   # Top face
	]
	
	for i in range(8):
		var vert_pos = cube_pos + cube_verts[i]
		var world_pos = chunk.local_to_world(vert_pos)
		
		# CRITICAL: Use boundary-safe density retrieval
		var density = get_safe_density_fixed(chunk, vert_pos)
		
		cube_data.positions.append(world_pos)
		cube_data.densities.append(density)
	
	return cube_data

func get_safe_density_fixed(chunk: VoxelChunk, local_pos: Vector3i) -> float:
	"""FIXED: Get density with proper boundary handling to prevent holes"""
	
	# If position is within chunk bounds, use chunk data
	if chunk.is_valid_position(local_pos):
		return chunk.get_density(local_pos)
	
	# CRITICAL: For boundary positions, calculate density directly
	var world_pos = chunk.local_to_world(local_pos)
	
	# Use terrain generator for consistent boundary density
	if terrain_generator_ref != null:
		var boundary_density = terrain_generator_ref.calculate_terrain_density(world_pos)
		return clamp(boundary_density, 0.0, 1.0)
	
	# Fallback: Use mathematical terrain (GLSL-style)
	var surface_height = sin(world_pos.x * 0.1) * 2.0 + cos(world_pos.z * 0.1) * 1.5
	var distance_to_surface = world_pos.y - surface_height
	
	if distance_to_surface <= 0.0:
		return 0.8  # Solid terrain
	elif distance_to_surface <= 1.0:
		return 0.5 - distance_to_surface * 0.3  # Transition
	else:
		return 0.0  # Air

func march_cube_fixed(cube_data: Dictionary) -> Array:
	"""FIXED: Apply marching cubes algorithm with proper configuration handling"""
	var triangles = []
	
	# Calculate configuration index
	var config_index = 0
	var inside_count = 0
	
	for i in range(8):
		var density = cube_data.densities[i]
		if density < threshold:
			config_index |= (1 << i)
		else:
			inside_count += 1
	
	# Skip completely inside or outside cubes
	if config_index == 0 or config_index == 255:
		return triangles
	
	# Get triangulation from lookup table
	var triangle_table = lookup_tables.get_triangle_table()
	if config_index >= triangle_table.size():
		print("ERROR: Invalid configuration index %d (max %d)" % [config_index, triangle_table.size() - 1])
		return triangles
	
	var triangle_config = triangle_table[config_index]
	if triangle_config == null or triangle_config.is_empty():
		return triangles
	
	# Calculate edge intersections
	var edge_vertices = calculate_edge_intersections(cube_data)
	
	# Generate triangles
	var i = 0
	while i < triangle_config.size() and triangle_config[i] >= 0:
		if i + 2 < triangle_config.size():
			var v1 = edge_vertices[triangle_config[i]]
			var v2 = edge_vertices[triangle_config[i + 1]]
			var v3 = edge_vertices[triangle_config[i + 2]]
			
			# Check that all vertices are valid (not null)
			if v1 != null and v2 != null and v3 != null:
				var triangle = create_triangle_from_edges(v1, v2, v3)
				
				if not triangle.is_empty():
					triangles.append(triangle)
		
		i += 3
	
	return triangles

func calculate_edge_intersections(cube_data: Dictionary) -> Array:
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
		if (v1_density < threshold) != (v2_density < threshold):
			# Interpolate vertex position
			var t = (threshold - v1_density) / (v2_density - v1_density)
			t = clamp(t, 0.0, 1.0)  # Safety clamp
			edge_vertices[i] = v1_pos.lerp(v2_pos, t)
		else:
			edge_vertices[i] = null
	
	return edge_vertices

func create_triangle_from_edges(v1: Vector3, v2: Vector3, v3: Vector3) -> Dictionary:
	"""Create triangle from three edge vertices"""
	if v1 == null or v2 == null or v3 == null:
		return {}
	
	# Calculate normal
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var normal = edge1.cross(edge2).normalized()
	
	# Ensure consistent winding order
	if normal.y < 0:  # If normal points downward, flip it
		normal = -normal
		# Swap vertices to maintain correct winding
		var temp = v2
		v2 = v3
		v3 = temp
	
	return {
		"vertices": [v1, v2, v3],
		"normals": [normal, normal, normal]
	}

func validate_chunk_data(chunk: VoxelChunk) -> bool:
	"""Validate chunk has proper density data"""
	if chunk.density_data.is_empty():
		return false
	
	# Check if all densities are valid numbers
	var valid_count = 0
	var total_count = 0
	
	for x in range(min(3, chunk.chunk_size.x + 1)):
		for y in range(min(3, chunk.chunk_size.y + 1)):
			for z in range(min(3, chunk.chunk_size.z + 1)):
				var density = chunk.get_density(Vector3i(x, y, z))
				total_count += 1
				if density >= 0.0 and density <= 1.0 and is_finite(density):
					valid_count += 1
	
	var valid_ratio = float(valid_count) / float(total_count)
	return valid_ratio > 0.8  # At least 80% valid densities

func is_valid_cube_data(cube_data: Dictionary) -> bool:
	"""Check if cube data is valid for processing"""
	if not cube_data.has("positions") or not cube_data.has("densities"):
		return false
	
	if cube_data.positions.size() != 8 or cube_data.densities.size() != 8:
		return false
	
	# Check for valid density values
	for density in cube_data.densities:
		if density == null or not is_finite(density):
			return false
		if density < 0.0 or density > 1.0:
			return false
	
	return true

# ========== DEBUG AND UTILITY FUNCTIONS ==========

func debug_cube_configuration(cube_data: Dictionary) -> void:
	"""Debug cube configuration for troubleshooting"""
	var config_index = 0
	var densities_str = "["
	
	for i in range(8):
		var density = cube_data.densities[i]
		if density < threshold:
			config_index |= (1 << i)
		densities_str += "%.2f" % density
		if i < 7:
			densities_str += ", "
	densities_str += "]"
	
	print("DEBUG: Config %d, Densities %s, Threshold %.2f" % [config_index, densities_str, threshold])
	
	# Check if this configuration should generate geometry
	var triangle_table = lookup_tables.get_triangle_table()
	if config_index < triangle_table.size():
		var triangle_config = triangle_table[config_index]
		var triangle_count = 0
		for edge in triangle_config:
			if edge >= 0:
				triangle_count += 1
		triangle_count = triangle_count / 3
		print("DEBUG: Should generate %d triangles" % triangle_count)

func get_generation_stats() -> Dictionary:
	"""Get statistics about mesh generation"""
	return {
		"cubes_processed": total_cubes_processed,
		"triangles_generated": total_triangles_generated,
		"threshold": threshold,
		"has_terrain_ref": terrain_generator_ref != null
	}

func set_terrain_generator_reference(terrain_gen: TerrainGenerator):
	"""Set reference to terrain generator for boundary calculations"""
	terrain_generator_ref = terrain_gen
	print("MarchingCubesGenerator: Terrain generator reference set for seamless boundaries") 
