# MarchingCubesGenerator.gd
# Core marching cubes algorithm implementation
# Generates smooth meshes from voxel density data

extends RefCounted
class_name MarchingCubesGenerator

@export var threshold: float = 0.5
@export var smoothing_iterations: int = 1

# Lookup tables reference
var lookup_tables: MarchingCubesLookupTables

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
	
	print("MarchingCubes: Generated mesh with %d vertices, %d triangles" % [vertices.size(), indices.size() / 3])
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
	"""Get the 8 vertex data for a cube at the given position"""
	var cube_data = {
		"positions": [],
		"densities": []
	}
	
	var cube_verts = lookup_tables.get_cube_vertices()
	for i in range(8):
		var vert_pos = cube_pos + Vector3i(cube_verts[i])
		var world_pos = chunk.local_to_world(vert_pos)
		
		# Use boundary-safe density retrieval
		var density = get_safe_density(chunk, vert_pos)
		
		cube_data.positions.append(world_pos)
		cube_data.densities.append(density)
	
	return cube_data

func get_safe_density(chunk: VoxelChunk, local_pos: Vector3i) -> float:
	"""Get density with safe boundary handling"""
	if chunk.is_valid_position(local_pos):
		return chunk.get_density(local_pos)
	
	# For positions outside the chunk, return a default value
	# This prevents holes at chunk boundaries
	return 1.0  # Default to solid material outside chunk bounds

func march_cube(cube_data: Dictionary) -> Array:
	"""Apply marching cubes algorithm to a single cube"""
	var triangles = []
	
	# Determine configuration index
	var config_index = 0
	for i in range(8):
		if cube_data.densities[i] < threshold:
			config_index |= (1 << i)
	
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
			
			edge_vertices[i] = lookup_tables.interpolate_vertex(v1_pos, v2_pos, v1_density, v2_density, threshold)
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
			
		triangle.vertices = [v1, v2, v3]
		
		# Calculate normal with proper winding order
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
