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
	"""Generate a mesh from a voxel chunk using marching cubes - ROBUST VERSION"""
	if chunk.cached_mesh != null and not chunk.is_dirty:
		return chunk.cached_mesh
	
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array = []
	
	var triangle_count = 0
	
	# Process each cube in the chunk 
	for x in range(chunk.chunk_size.x):
		for y in range(chunk.chunk_size.y):
			for z in range(chunk.chunk_size.z):
				var cube_vertices_data = get_cube_vertices(chunk, Vector3i(x, y, z))
				if is_valid_cube_data(cube_vertices_data):
					var triangles = march_cube(cube_vertices_data)
					
					# Add triangles to mesh arrays
					for triangle in triangles:
						if triangle.vertices.size() == 3 and triangle.normals.size() == 3:
							var start_index = vertices.size()
							vertices.append_array(triangle.vertices)
							normals.append_array(triangle.normals)
							
							# Add indices for the triangle (ensure proper winding)
							indices.append(start_index)
							indices.append(start_index + 1)
							indices.append(start_index + 2)
							
							triangle_count += 1
	
	# Create the mesh
	var mesh = ArrayMesh.new()
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		print("MarchingCubes: Generated %d triangles, %d vertices for chunk %s" % 
			[triangle_count, vertices.size(), chunk.chunk_name])
	else:
		print("MarchingCubes: WARNING - No geometry generated for chunk %s" % chunk.chunk_name)
	
	# Cache the result
	chunk.cached_mesh = mesh
	chunk.is_dirty = false
	
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
	"""Get the 8 vertex data for a cube at the given position - FIXED VERSION"""
	var cube_data = {
		"positions": [],
		"densities": []
	}
	
	var cube_verts = lookup_tables.get_cube_vertices()
	for i in range(8):
		var vert_pos = cube_pos + Vector3i(cube_verts[i])
		var world_pos = chunk.local_to_world(vert_pos)
		
		# FIXED: Use consistent density evaluation for all vertices
		var density: float
		if chunk.is_valid_position(vert_pos):
			density = chunk.get_density(vert_pos)
		else:
			# For vertices outside chunk, use direct terrain calculation
			density = calculate_direct_terrain_density(world_pos)
		
		cube_data.positions.append(world_pos)
		cube_data.densities.append(density)
	
	return cube_data

func evaluate_density_at_world_position(world_pos: Vector3, chunk: VoxelChunk) -> float:
	"""Seamless density evaluation using neighbor chunks - DEPRECATED"""
	# This function is no longer used - density evaluation is now handled directly
	# in get_cube_vertices for consistency
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
	"""Get density with safe boundary handling - FIXED FOR SEAMLESS TERRAIN"""
	if chunk.is_valid_position(local_pos):
		var interior_density = chunk.get_density(local_pos)
		return interior_density
	
	# FIXED: Use world coordinates for boundary density evaluation
	var world_pos = chunk.local_to_world(local_pos)
	var boundary_density = calculate_direct_terrain_density(world_pos)
	
	# DEBUG: Only print when debugging specific areas
	if local_pos.x == chunk.chunk_size.x or local_pos.y == chunk.chunk_size.y or local_pos.z == chunk.chunk_size.z:
		print("🔗 BOUNDARY SEAMLESS: pos %v -> density %.3f (world: %v)" % [local_pos, boundary_density, world_pos])
	
	return boundary_density

func march_cube(cube_data: Dictionary) -> Array:
	"""Apply marching cubes algorithm to a single cube - FIXED FOR BINARY DENSITY"""
	var triangles = []
	
	# Calculate configuration index using threshold comparison
	var config_index = 0
	for i in range(8):
		if cube_data.densities[i] < threshold:
			config_index |= (1 << i)
	
	# DEBUG: Log configuration for first few cubes to understand what's happening
	if triangles.size() == 0:  # Only log for debugging
		var density_str = ""
		for d in cube_data.densities:
			density_str += "%.1f " % d
		print("🔍 Cube config %d, densities: [%s]" % [config_index, density_str.strip_edges()])
	
	# Get edge table entry
	var edge_table = lookup_tables.get_edge_table()
	if config_index >= edge_table.size() or config_index < 0:
		return triangles
	
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
			
			edge_vertices[i] = calculate_interpolation(v1_pos, v2_pos, v1_density, v2_density)
		else:
			edge_vertices[i] = null
	
	# Generate triangles using triangle table
	var triangle_table = lookup_tables.get_triangle_table()
	if config_index >= triangle_table.size():
		return triangles
	
	var triangle_config = triangle_table[config_index]
	var i = 0
	while i < triangle_config.size():
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
		
		# Check if all edge vertices exist
		if (edge_vertices[edge_idx1] == null or 
			edge_vertices[edge_idx2] == null or 
			edge_vertices[edge_idx3] == null):
			i += 3
			continue
		
		var triangle = TriangleData.new()
		var v1 = edge_vertices[edge_idx1]
		var v2 = edge_vertices[edge_idx2]
		var v3 = edge_vertices[edge_idx3]
		
		triangle.vertices = [v1, v2, v3]
		
		# Calculate normal
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var normal = edge1.cross(edge2)
		
		if normal.length_squared() > 0.000001:
			normal = normal.normalized()
			triangle.normals = [normal, normal, normal]
			triangles.append(triangle)
		
		i += 3
	
	return triangles

func calculate_interpolation(a: Vector3, b: Vector3, val_a: float, val_b: float) -> Vector3:
	"""Linear interpolation - FIXED for binary density values"""
	# With binary values (0.0 or 1.0), we need to handle the edge case properly
	var density_diff = abs(val_b - val_a)
	
	if density_diff < 0.000001:
		# Both values are the same, return midpoint
		return (a + b) * 0.5
	
	# Standard interpolation formula
	var t = (threshold - val_a) / (val_b - val_a)
	t = clamp(t, 0.0, 1.0)
	
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
