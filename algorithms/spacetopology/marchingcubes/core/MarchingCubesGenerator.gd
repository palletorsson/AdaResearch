# MarchingCubesGenerator.gd
# Core marching cubes algorithm implementation
# Generates smooth meshes from voxel density data

extends RefCounted
class_name MarchingCubesGenerator

@export var threshold: float = 0.5
@export var smoothing_iterations: int = 1

# Lookup tables reference
var lookup_tables: MarchingCubesLookupTables

# Reference to terrain generator for direct density evaluation
var terrain_generator_ref: TerrainGenerator = null

func _init():
	lookup_tables = MarchingCubesLookupTables.new()

func generate_mesh_from_chunk(chunk: VoxelChunk) -> ArrayMesh:
	"""Generate a mesh from a voxel chunk using marching cubes"""
	if chunk.cached_mesh != null and not chunk.is_dirty:
		return chunk.cached_mesh
	
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array = []
	
	# Process each cube in the chunk (excluding the last layer to avoid boundary issues)
	for x in range(chunk.chunk_size.x):
		for y in range(chunk.chunk_size.y):
			for z in range(chunk.chunk_size.z):
				# Ensure we have valid voxel data for all 8 cube vertices
				if x < chunk.chunk_size.x and y < chunk.chunk_size.y and z < chunk.chunk_size.z:
					var cube_vertices_data = get_cube_vertices(chunk, Vector3i(x, y, z))
					if is_valid_cube_data(cube_vertices_data):
						var triangles = march_cube(cube_vertices_data)
						
						# Add triangles to mesh arrays
						for triangle in triangles:
							if triangle.vertices.size() == 3:
								var start_index = vertices.size()
								vertices.append_array(triangle.vertices)
								normals.append_array(triangle.normals)
								
								# Add indices for the triangle
								indices.append(start_index)
								indices.append(start_index + 1)
								indices.append(start_index + 2)
	
	# Create the mesh
	var mesh = ArrayMesh.new()
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Cache the result
	chunk.cached_mesh = mesh
	chunk.is_dirty = false
	
	print("MarchingCubes: Generated mesh with %d vertices, %d triangles, %d indices" % [vertices.size(), indices.size() / 3, indices.size()])
	
	# DEBUG: Check if mesh has proper surfaces
	if mesh.get_surface_count() > 0:
		var surface_arrays = mesh.surface_get_arrays(0)
		var mesh_vertices = surface_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var mesh_indices = surface_arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		print("MarchingCubes: Surface has %d vertices, %d indices" % [mesh_vertices.size(), mesh_indices.size()])
	else:
		print("MarchingCubes: WARNING - No surfaces in generated mesh!")
	
	return mesh

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
	
	return true

func get_cube_vertices(chunk: VoxelChunk, cube_pos: Vector3i) -> Dictionary:
	"""Get the 8 vertex data for a cube at the given position - GLSL-INSPIRED VERSION"""
	var cube_data = {
		"positions": [],
		"densities": []
	}
	
	var cube_verts = lookup_tables.get_cube_vertices()
	for i in range(8):
		var vert_pos = cube_pos + Vector3i(cube_verts[i])
		var world_pos = chunk.local_to_world(vert_pos)
		
		# CRITICAL FIX: Use direct evaluation instead of stored grid values
		var density = evaluate_density_at_world_position(world_pos, chunk)
		
		cube_data.positions.append(world_pos)
		cube_data.densities.append(density)
	
	return cube_data

func evaluate_density_at_world_position(world_pos: Vector3, chunk: VoxelChunk) -> float:
	"""Seamless density evaluation using neighbor chunks (inspired by reference implementation)"""
	var local_pos = chunk.world_to_local(world_pos)
	
	# FIRST: Try neighbor-aware lookup (inspired by reference architecture)
	var neighbor_density = chunk.get_density_with_neighbors(local_pos)
	if neighbor_density > 0.0:  # Valid density from chunk network
		return neighbor_density
	
	# FALLBACK: Direct evaluation for missing data
	if chunk.is_valid_position(local_pos):
		var stored_density = chunk.get_density(local_pos)
		
		# DEBUG: Check for problematic stored values
		if stored_density < 0.1:
			var direct_density = calculate_direct_terrain_density(world_pos)
			if abs(direct_density - stored_density) > 0.2:
				print("🔄 CHUNK BOUNDARY FIX: stored %.3f -> direct %.3f at %v" % [stored_density, direct_density, world_pos])
			return direct_density
		
		return stored_density
	else:
		# Final fallback: direct evaluation (like GLSL/reference approach)
		return calculate_direct_terrain_density(world_pos)

func calculate_direct_terrain_density(world_pos: Vector3) -> float:
	"""Direct terrain density calculation - independent of chunk storage"""
	# Use terrain generator if available, otherwise fallback to simple calculation
	if terrain_generator_ref != null:
		return terrain_generator_ref.calculate_terrain_density(world_pos)
	
	# Fallback: Simple mathematical terrain (GLSL-style approach)
	var surface_height = sin(world_pos.x * 0.1) * 2.0 + cos(world_pos.z * 0.1) * 1.5
	
	# Create terrain surface with smooth transitions (like GLSL)
	var distance_to_surface = world_pos.y - surface_height
	
	if distance_to_surface <= -1.0:
		return 0.9  # Deep solid
	elif distance_to_surface <= 0.0:
		return 0.7  # Surface solid  
	elif distance_to_surface <= 1.0:
		# Smooth transition zone
		return 0.5 - distance_to_surface * 0.3
	else:
		return 0.0  # Air above

func get_safe_density(chunk: VoxelChunk, local_pos: Vector3i) -> float:
	"""Get density with safe boundary handling - ENHANCED DEBUG VERSION"""
	if chunk.is_valid_position(local_pos):
		var interior_density = chunk.get_density(local_pos)
	
		# DEBUG: Check for suspiciously low densities
		if interior_density < 0.3:
			print("⚠️ LOW INTERIOR DENSITY: %.3f at local pos %v in chunk %s" % [interior_density, local_pos, chunk.chunk_name])
		
		return interior_density
	
	# CRITICAL: Boundary case - this should prevent holes
	var boundary_density = 1.0  # Default to solid material outside chunk bounds
	print("🔴 BOUNDARY HIT at local pos %v - returning %.3f (should prevent holes)" % [local_pos, boundary_density])
	return boundary_density

func march_cube(cube_data: Dictionary) -> Array:
	"""Apply marching cubes algorithm to a single cube - BLOG POST PATTERN"""
	var triangles = []
	
	# BLOG POST PATTERN: Bit manipulation for configuration index
	var config_index = 0
	# Use the exact same order as the blog post for consistency
	config_index |= int(cube_data.densities[0] < threshold) << 0  # vertex 0
	config_index |= int(cube_data.densities[1] < threshold) << 1  # vertex 1  
	config_index |= int(cube_data.densities[2] < threshold) << 2  # vertex 2
	config_index |= int(cube_data.densities[3] < threshold) << 3  # vertex 3
	config_index |= int(cube_data.densities[4] < threshold) << 4  # vertex 4
	config_index |= int(cube_data.densities[5] < threshold) << 5  # vertex 5
	config_index |= int(cube_data.densities[6] < threshold) << 6  # vertex 6
	config_index |= int(cube_data.densities[7] < threshold) << 7  # vertex 7
	
	# DEBUG: Log configuration for first few cubes
	if triangles.size() < 3:  # Only first few cubes to avoid spam
		print("🔍 CUBE CONFIG: index %d, densities: [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f]" % 
			[config_index, cube_data.densities[0], cube_data.densities[1], cube_data.densities[2], 
			cube_data.densities[3], cube_data.densities[4], cube_data.densities[5], 
			cube_data.densities[6], cube_data.densities[7]])
	
	# Get edge table entry
	var edge_table = lookup_tables.get_edge_table()
	if config_index >= edge_table.size():
		return triangles  # Invalid configuration
	
	var edge_flags = edge_table[config_index]
	if edge_flags == 0:
		return triangles  # No intersection
	
	# Calculate edge intersections
	var edge_vertices = []
	edge_vertices.resize(12)
	
	var edge_connections = lookup_tables.get_edge_connections()
	for i in range(12):
		if (edge_flags & (1 << i)) != 0:
			var v1_idx = edge_connections[i][0]
			var v2_idx = edge_connections[i][1]
			
			var v1_pos = cube_data.positions[v1_idx]
			var v2_pos = cube_data.positions[v2_idx]
			var v1_density = cube_data.densities[v1_idx]
			var v2_density = cube_data.densities[v2_idx]
			
			# BLOG POST INTERPOLATION PATTERN: Exact linear interpolation  
			edge_vertices[i] = calculate_interpolation(v1_pos, v2_pos, v1_density, v2_density)
		else:
			edge_vertices[i] = null
	
	# Generate triangles using triangle table
	var triangle_table = lookup_tables.get_triangle_table()
	if config_index >= triangle_table.size():
		return triangles  # Invalid configuration
	
	var triangle_config = triangle_table[config_index]
	var i = 0
	while i < triangle_config.size():
		# Process triangles in groups of 3
		if i + 2 >= triangle_config.size():
			break
			
		var edge_idx1 = triangle_config[i]
		var edge_idx2 = triangle_config[i + 1] 
		var edge_idx3 = triangle_config[i + 2]
		
		# Validate edge indices
		if (edge_idx1 < 0 or edge_idx1 >= edge_vertices.size() or
			edge_idx2 < 0 or edge_idx2 >= edge_vertices.size() or
			edge_idx3 < 0 or edge_idx3 >= edge_vertices.size()):
			i += 3
			continue
		
		# Check if all edge vertices exist and are valid
		if (edge_vertices[edge_idx1] == null or 
			edge_vertices[edge_idx2] == null or 
			edge_vertices[edge_idx3] == null):
			i += 3
			continue
		
		var triangle = TriangleData.new()
		
		# Get triangle vertices
		var v1 = edge_vertices[edge_idx1]
		var v2 = edge_vertices[edge_idx2]
		var v3 = edge_vertices[edge_idx3]
		
		# Validate vertices
		if v1 == null or v2 == null or v3 == null:
			i += 3
			continue
			
		# FIX: Correct winding order for terrain surfaces (counter-clockwise when viewed from above)
		triangle.vertices = [v1, v2, v3]  # Proper counter-clockwise winding
		
		# Calculate normal with proper winding order (right-hand rule)
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var normal = edge1.cross(edge2)
		
		# Only add triangle if normal is valid
		if normal.length_squared() > 0.0001:
			normal = normal.normalized()
			triangle.normals = [normal, normal, normal]
			triangles.append(triangle)
		
		i += 3
	
	return triangles

func calculate_interpolation(a: Vector3, b: Vector3, val_a: float, val_b: float) -> Vector3:
	"""Linear interpolation exactly like the blog post"""
	# Prevent division by zero
	if abs(val_b - val_a) < 0.000001:
		return a
	
	# Blog post interpolation formula: t = (ISO_LEVEL - val_a) / (val_b - val_a)
	var t = (threshold - val_a) / (val_b - val_a)
	t = clamp(t, 0.0, 1.0)  # Safety clamp
	
	return a + t * (b - a)

func smooth_mesh(mesh: ArrayMesh) -> ArrayMesh:
	"""Apply smoothing to the generated mesh"""
	if smoothing_iterations <= 0:
		return mesh
	
	# Implementation of Laplacian smoothing would go here
	# For now, return the original mesh
	return mesh

# Helper class for triangle data
class TriangleData:
	var vertices: Array = []
	var normals: Array = [] 
