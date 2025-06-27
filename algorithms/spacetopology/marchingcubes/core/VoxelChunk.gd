# VoxelChunk.gd
# Manages a 3D chunk of voxel data for marching cubes generation
# Handles density values, caching, and efficient data access

extends RefCounted
class_name VoxelChunk

@export var chunk_size: Vector3i = Vector3i(32, 32, 32)
@export var world_position: Vector3 = Vector3.ZERO
@export var voxel_scale: float = 1.0

# Chunk identification
var chunk_name: String = ""

# 3D array storing density values (0.0 to 1.0)
var density_data: Array = []
var is_dirty: bool = true
var cached_mesh: ArrayMesh = null

# Chunk boundaries for neighbor access
var neighbors: Dictionary = {}

func _init(size: Vector3i = Vector3i(32, 32, 32), pos: Vector3 = Vector3.ZERO, scale: float = 1.0):
	chunk_size = size
	world_position = pos
	voxel_scale = scale
	initialize_density_data()

func initialize_density_data():
	"""Initialize the 3D density array with default values"""
	density_data = []
	
	for x in range(chunk_size.x + 1):  # +1 for marching cubes overlap
		var x_layer = []
		for y in range(chunk_size.y + 1):
			var y_layer = []
			for z in range(chunk_size.z + 1):
				y_layer.append(0.0)  # Default to empty space
			x_layer.append(y_layer)
		density_data.append(x_layer)
	
	print("VoxelChunk: Initialized %dx%dx%d density grid" % [chunk_size.x + 1, chunk_size.y + 1, chunk_size.z + 1])

func set_density(local_pos: Vector3i, value: float):
	"""Set density value at local voxel position"""
	if is_valid_position(local_pos):
		density_data[local_pos.x][local_pos.y][local_pos.z] = clamp(value, 0.0, 1.0)
		is_dirty = true

func get_density(local_pos: Vector3i) -> float:
	"""Get density value at local voxel position"""
	if is_valid_position(local_pos):
		return density_data[local_pos.x][local_pos.y][local_pos.z]
	return 0.0

func is_valid_position(local_pos: Vector3i) -> bool:
	"""Check if position is within chunk bounds"""
	return (local_pos.x >= 0 and local_pos.x <= chunk_size.x and
			local_pos.y >= 0 and local_pos.y <= chunk_size.y and
			local_pos.z >= 0 and local_pos.z <= chunk_size.z)

func world_to_local(world_pos: Vector3) -> Vector3i:
	"""Convert world position to local voxel coordinates"""
	var local_pos = (world_pos - world_position) / voxel_scale
	return Vector3i(int(local_pos.x), int(local_pos.y), int(local_pos.z))

func local_to_world(local_pos: Vector3i) -> Vector3:
	"""Convert local voxel coordinates to world position"""
	return world_position + Vector3(local_pos) * voxel_scale

func fill_sphere(center: Vector3, radius: float, density: float = 1.0):
	"""Fill a spherical region with specified density"""
	var local_center = world_to_local(center)
	var voxel_radius = radius / voxel_scale
	
	# Expand bounds slightly to ensure complete coverage
	var min_x = max(0, int(local_center.x - voxel_radius) - 1)
	var max_x = min(chunk_size.x, int(local_center.x + voxel_radius) + 1)
	var min_y = max(0, int(local_center.y - voxel_radius) - 1) 
	var max_y = min(chunk_size.y, int(local_center.y + voxel_radius) + 1)
	var min_z = max(0, int(local_center.z - voxel_radius) - 1)
	var max_z = min(chunk_size.z, int(local_center.z + voxel_radius) + 1)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			for z in range(min_z, max_z + 1):
				var distance = Vector3(x - local_center.x, y - local_center.y, z - local_center.z).length()
				if distance <= voxel_radius:
					# Use smooth falloff for better surface quality
					var falloff = 1.0 - smoothstep(voxel_radius * 0.7, voxel_radius, distance)
					var new_density = density * falloff
					
					# Blend with existing density for smoother results
					var current_density = get_density(Vector3i(x, y, z))
					if density < current_density:  # Carving (reducing density)
						set_density(Vector3i(x, y, z), min(current_density, new_density))
					else:  # Adding material
						set_density(Vector3i(x, y, z), max(current_density, new_density))

func carve_tunnel(start: Vector3, end: Vector3, radius: float):
	"""Carve a tunnel between two points"""
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var steps = max(int(distance / (voxel_scale * 0.25)), 10)  # Finer sampling for smoother tunnels
	
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var current_pos = start.lerp(end, t)
		
		# Add slight radius variation for more organic look
		var radius_variation = 1.0 + sin(t * PI * 3.0) * 0.1
		var current_radius = radius * radius_variation
		
		fill_sphere(current_pos, current_radius, 0.0)  # Carve by setting density to 0

func add_rhizome_branch(start: Vector3, direction: Vector3, length: float, start_radius: float, end_radius: float):
	"""Add a rhizomatic branch with varying radius"""
	var steps = max(int(length / (voxel_scale * 0.25)), 15)  # Finer steps for smoother branches
	
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var current_pos = start + direction * length * t
		var current_radius = lerp(start_radius, end_radius, t)
		
		# Add organic variation with multiple frequency components
		var noise_offset = Vector3(
			sin(t * 10.0) * 0.3 + sin(t * 25.0) * 0.1,
			cos(t * 8.0) * 0.2 + cos(t * 20.0) * 0.08,
			sin(t * 12.0) * 0.25 + sin(t * 30.0) * 0.06
		) * current_radius * 0.2
		
		# Smooth radius variation for organic feel
		var radius_noise = 1.0 + sin(t * PI * 4.0) * 0.15 + sin(t * PI * 12.0) * 0.05
		current_radius *= radius_noise
		
		fill_sphere(current_pos + noise_offset, current_radius, 0.0)

func apply_noise_field(noise: FastNoiseLite, strength: float = 0.5):
	"""Apply 3D noise to density field for organic variation"""
	for x in range(chunk_size.x + 1):
		for y in range(chunk_size.y + 1):
			for z in range(chunk_size.z + 1):
				var world_pos = local_to_world(Vector3i(x, y, z))
				
				# Use multiple octaves for more complex noise
				var noise_value = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
				var detail_noise = noise.get_noise_3d(world_pos.x * 3.0, world_pos.y * 3.0, world_pos.z * 3.0) * 0.3
				var fine_noise = noise.get_noise_3d(world_pos.x * 8.0, world_pos.y * 8.0, world_pos.z * 8.0) * 0.1
				
				var combined_noise = noise_value + detail_noise + fine_noise
				
				var current_density = get_density(Vector3i(x, y, z))
				var new_density = current_density + combined_noise * strength
				set_density(Vector3i(x, y, z), clamp(new_density, 0.0, 1.0))

func set_neighbor_chunk(direction: Vector3i, chunk: VoxelChunk):
	"""Set neighboring chunk for seamless generation"""
	var key = str(direction)
	neighbors[key] = chunk

func get_density_with_neighbors(local_pos: Vector3i) -> float:
	"""Get density considering neighboring chunks for seamless edges - FIXED VERSION"""
	if is_valid_position(local_pos):
		return get_density(local_pos)
	
	# FIXED: For out-of-bounds positions, return a special value to indicate
	# that direct terrain calculation should be used instead
	return -1.0  # Special value indicating "use direct calculation"

func clear():
	"""Clear all density data"""
	initialize_density_data()
	is_dirty = true
	cached_mesh = null

func get_memory_usage() -> int:
	"""Get approximate memory usage in bytes"""
	var total_voxels = (chunk_size.x + 1) * (chunk_size.y + 1) * (chunk_size.z + 1)
	return total_voxels * 4  # 4 bytes per float 