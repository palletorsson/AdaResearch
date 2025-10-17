# RhizomeCaveGenerator.gd - Rhizome-based cave generation using marching cubes
extends Node3D
class_name RhizomeCaveGenerator

# Signals
signal generation_progress(percentage: float)
signal generation_complete()

# Configuration
@export var threshold: float = 0.5
@export var chunk_size: Vector3i = Vector3i(32, 32, 32)
@export var voxel_scale: float = 1.0

# VoxelChunk class
class RhizomeVoxelChunk:
	var chunk_size: Vector3i
	var voxel_scale: float
	var density_data: Array  # 3D array [x][y][z] of floats
	
	func _init(size: Vector3i, scale: float):
		chunk_size = size
		voxel_scale = scale
		# Initialize 3D array
		density_data = []
		for x in size.x:
			density_data.append([])
			for y in size.y:
				density_data[x].append([])
				for z in size.z:
					density_data[x][y].append(0.0)
	
	func get_density(pos: Vector3i) -> float:
		if pos.x >= 0 and pos.x < chunk_size.x and \
		   pos.y >= 0 and pos.y < chunk_size.y and \
		   pos.z >= 0 and pos.z < chunk_size.z:
			return density_data[pos.x][pos.y][pos.z]
		return 1.0
	
	func set_density(pos: Vector3i, value: float):
		if pos.x >= 0 and pos.x < chunk_size.x and \
		   pos.y >= 0 and pos.y < chunk_size.y and \
		   pos.z >= 0 and pos.z < chunk_size.z:
			density_data[pos.x][pos.y][pos.z] = value

# Async version of generate_mesh_from_chunk
func generate_mesh_from_chunk_async(chunk: RhizomeVoxelChunk, max_time_ms: float = 8.0) -> ArrayMesh:
	"""Generate mesh from voxel chunk asynchronously with time-based yielding"""
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var start_time = Time.get_ticks_msec()
	var vertex_index = 0
	
	# Process voxels in smaller batches with time checking
	for x in range(chunk.chunk_size.x):
		for y in range(chunk.chunk_size.y):
			for z in range(chunk.chunk_size.z):
				# Check if we've exceeded our time budget
				var current_time = Time.get_ticks_msec()
				if current_time - start_time > max_time_ms:
					start_time = Time.get_ticks_msec()
					await get_tree().process_frame
				
				# Get the 8 corner values for this voxel
				var corner_values = get_voxel_corners(chunk, Vector3i(x, y, z))
				
				# Determine which corners are inside/outside the surface
				var cube_index = 0
				for i in range(8):
					if corner_values[i] < threshold:
						cube_index |= (1 << i)
				
				# Skip empty voxels
				if cube_index == 0 or cube_index == 255:
					continue
				
				# Get triangle configuration for this cube
				var triangles = get_triangles_for_cube(cube_index)
				
				# Generate triangles
				for triangle in triangles:
					var triangle_vertices = []
					var triangle_normals = []
					
					for edge_index in triangle:
						if edge_index == -1:
							break
							
						var vertex_pos = interpolate_vertex(chunk, Vector3i(x, y, z), edge_index, corner_values)
						var normal = calculate_normal(chunk, vertex_pos)
						
						triangle_vertices.append(vertex_pos)
						triangle_normals.append(normal)
					
					# Add triangle to mesh data
					if triangle_vertices.size() == 3:
						vertices.append_array(triangle_vertices)
						normals.append_array(triangle_normals)
						
						# Add indices for this triangle
						indices.append(vertex_index)
						indices.append(vertex_index + 1)
						indices.append(vertex_index + 2)
						vertex_index += 3
	
	# Create the final mesh
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

func get_voxel_corners(chunk: RhizomeVoxelChunk, voxel_pos: Vector3i) -> Array[float]:
	"""Get the density values at the 8 corners of a voxel"""
	var corners: Array[float] = []
	
	# Corner offsets for a cube
	var corner_offsets = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1),
		Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 1, 1), Vector3i(0, 1, 1)
	]
	
	for offset in corner_offsets:
		var corner_pos = voxel_pos + offset
		var density = chunk.get_density(corner_pos)
		corners.append(density)
	
	return corners

func get_triangles_for_cube(cube_index: int) -> Array:
	"""Get triangle configuration for a marching cubes case"""
	# This should return the triangle table data for the given cube index
	# You'll need to implement your marching cubes lookup table here
	# For now, returning a simple placeholder
	var triangles = []
	
	# Add your marching cubes triangle table lookup here
	# This is where you'd use your MarchingCubesLUT.txt data
	var triangle_config = get_triangle_configuration(cube_index)
	
	# Parse triangle configuration into individual triangles
	var triangle = []
	for edge in triangle_config:
		if edge == -1:
			if triangle.size() == 3:
				triangles.append(triangle.duplicate())
				triangle.clear()
		else:
			triangle.append(edge)
			if triangle.size() == 3:
				triangles.append(triangle.duplicate())
				triangle.clear()
	
	return triangles

func interpolate_vertex(chunk: RhizomeVoxelChunk, voxel_pos: Vector3i, edge_index: int, corner_values: Array[float]) -> Vector3:
	"""Interpolate vertex position along an edge based on density values"""
	# Edge vertex pairs for marching cubes
	var edge_vertices = [
		[0, 1], [1, 2], [2, 3], [3, 0], # Bottom edges
		[4, 5], [5, 6], [6, 7], [7, 4], # Top edges
		[0, 4], [1, 5], [2, 6], [3, 7]  # Vertical edges
	]
	
	var edge = edge_vertices[edge_index]
	var v0_index = edge[0]
	var v1_index = edge[1]
	
	var density0 = corner_values[v0_index]
	var density1 = corner_values[v1_index]
	
	# Corner positions relative to voxel
	var corner_positions = [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1),
		Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)
	]
	
	var pos0 = corner_positions[v0_index]
	var pos1 = corner_positions[v1_index]
	
	# Linear interpolation based on threshold
	var t = 0.5  # Default to middle
	if abs(density1 - density0) > 0.001:
		t = (threshold - density0) / (density1 - density0)
		t = clamp(t, 0.0, 1.0)
	
	var interpolated_pos = pos0.lerp(pos1, t)
	
	# Convert to world position
	var world_pos = chunk.world_position + (Vector3(voxel_pos) + interpolated_pos) * chunk.voxel_scale
	
	return world_pos

func calculate_normal(chunk: RhizomeVoxelChunk, world_pos: Vector3) -> Vector3:
	"""Calculate normal vector at a world position using gradient"""
	var epsilon = chunk.voxel_scale * 0.5
	
	# Sample density at offset positions
	var dx = get_density_at_world_pos(chunk, world_pos + Vector3(epsilon, 0, 0)) - \
			 get_density_at_world_pos(chunk, world_pos - Vector3(epsilon, 0, 0))
	var dy = get_density_at_world_pos(chunk, world_pos + Vector3(0, epsilon, 0)) - \
			 get_density_at_world_pos(chunk, world_pos - Vector3(0, epsilon, 0))
	var dz = get_density_at_world_pos(chunk, world_pos + Vector3(0, 0, epsilon)) - \
			 get_density_at_world_pos(chunk, world_pos - Vector3(0, 0, epsilon))
	
	var normal = Vector3(dx, dy, dz).normalized()
	
	# Ensure we have a valid normal
	if normal.length_squared() < 0.1:
		normal = Vector3(0, 1, 0)  # Default upward normal
	
	return normal

func get_density_at_world_pos(chunk: RhizomeVoxelChunk, world_pos: Vector3) -> float:
	"""Get density value at a world position (with bounds checking)"""
	var local_pos = world_pos - chunk.world_position
	var voxel_pos = Vector3i(
		int(local_pos.x / chunk.voxel_scale),
		int(local_pos.y / chunk.voxel_scale),
		int(local_pos.z / chunk.voxel_scale)
	)
	
	# Bounds check
	if voxel_pos.x < 0 or voxel_pos.x >= chunk.chunk_size.x or \
	   voxel_pos.y < 0 or voxel_pos.y >= chunk.chunk_size.y or \
	   voxel_pos.z < 0 or voxel_pos.z >= chunk.chunk_size.z:
		return 1.0  # Outside bounds = solid
	
	return chunk.get_density(voxel_pos)

func get_triangle_configuration(cube_index: int) -> Array[int]:
	"""Get triangle configuration from lookup table"""
	# This is where you'd use your loaded LUT data
	# For now, return a simple configuration
	# You'll need to replace this with your actual triangle table
	
	# Placeholder - replace with your actual marching cubes table
	var triangle_table = get_marching_cubes_table()
	
	var result: Array[int] = []
	if cube_index >= 0 and cube_index < triangle_table.size():
		var config = triangle_table[cube_index]
		for val in config:
			result.append(val as int)
	return result

func get_marching_cubes_table() -> Array:
	"""Return the marching cubes triangle lookup table"""
	# This should return your loaded LUT data
	# For now returning a minimal example
	var table = []
	
	# Initialize with 256 empty configurations
	for i in range(256):
		table.append([])
	
	# You would populate this with your actual triangle table data
	# from the MarchingCubesLUT.txt file
	
	return table

# Public API methods for cave generation
func setup_parameters(params: Dictionary) -> void:
	"""Setup basic cave generation parameters"""
	if params.has("chunk_size"):
		chunk_size = params["chunk_size"]
	if params.has("voxel_scale"):
		voxel_scale = params["voxel_scale"]
	if params.has("threshold"):
		threshold = params["threshold"]

func configure_rhizome_parameters(params: Dictionary) -> void:
	"""Configure rhizomatic growth parameters"""
	# Store rhizome parameters for use during generation
	# This is a placeholder - you would use these in actual rhizome generation
	pass

func generate_cave_async() -> void:
	"""Generate cave asynchronously"""
	# Emit progress at start
	generation_progress.emit(0.0)
	
	# Create a sample chunk for demonstration
	var chunk = RhizomeVoxelChunk.new(chunk_size, voxel_scale)
	
	# Generate some sample density data (replace with actual rhizome algorithm)
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			for z in range(chunk_size.z):
				var pos = Vector3(x, y, z)
				var density = 0.5 + 0.3 * sin(pos.x * 0.5) + 0.3 * sin(pos.z * 0.5)
				chunk.set_density(Vector3i(x, y, z), density)
		
		# Emit progress
		var progress = float(x) / float(chunk_size.x) * 100.0
		generation_progress.emit(progress)
		await get_tree().process_frame
	
	# Generate mesh from chunk
	var mesh = await generate_mesh_from_chunk_async(chunk)
	
	# Create MeshInstance3D and add to scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	
	# Emit completion
	generation_complete.emit()
	generation_progress.emit(100.0)

func get_cave_info() -> Dictionary:
	"""Return cave generation statistics"""
	var mesh_instances = 0
	var collision_bodies = 0
	var total_vertices = 0
	var total_triangles = 0
	
	# Count mesh instances, vertices, and triangles
	for child in get_children():
		if child is MeshInstance3D:
			mesh_instances += 1
			if child.mesh and child.mesh.get_surface_count() > 0:
				var vertex_array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var index_array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
				total_vertices += vertex_array.size()
				if index_array.size() > 0:
					total_triangles += index_array.size() / 3
				else:
					total_triangles += vertex_array.size() / 3
		elif child is StaticBody3D:
			collision_bodies += 1
	
	return {
		"mesh_instances": mesh_instances,
		"collision_bodies": collision_bodies,
		"total_vertices": total_vertices,
		"total_triangles": total_triangles,
		"voxel_chunks": 1,  # Placeholder - would need actual chunk count
		"growth_nodes": 0,  # Placeholder - would need actual growth node count
		"chambers": 1,  # Placeholder - would need actual chamber count
		"chunk_size": chunk_size,
		"voxel_scale": voxel_scale,
		"threshold": threshold
	}
