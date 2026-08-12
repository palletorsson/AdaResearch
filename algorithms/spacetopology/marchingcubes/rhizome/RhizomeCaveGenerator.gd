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

# --- DNA plumbing (2026-08-12) ----------------------------------------------
# Three fields, each defaulting to the literal that used to be written inline, so the
# path a map takes is unchanged. RhizomeCaveDemoController sets them; nothing else in
# the corpus constructs this class except examples/simple_cave.gd, which sets none of
# them and therefore gets the old behaviour exactly.
#
#   growth_seed        -1 keeps the shipped `RhizomeGrowthPattern.new(randi())` call,
#                      character for character. >= 0 pins the whole growth history,
#                      which is what makes a four-tile sweep four views of ONE cave
#                      instead of four different caves.
#   carve_radius_scale the `bore` axis. 1.0, and `radius * 1.0` returns the identical
#                      bit pattern for every finite float, so the default carve is not
#                      merely close to the shipped one — it is the same call.
#   synchronous        capture only. Removes the frame yields so one _ready() returns a
#                      finished cave; the map path leaves it false and still builds
#                      across frames, because a 13k-voxel march must not gate map load.
var growth_seed: int = -1
var carve_radius_scale: float = 1.0
var synchronous: bool = false

## Nodes THIS SCRIPT created, so a rebuild frees its own work and nothing else. A
## blanket free of get_children() is what cost three scripts a pass in an earlier wave.
var _owned: Array[Node] = []

# VoxelChunk class
class RhizomeVoxelChunk:
	var chunk_size: Vector3i
	var voxel_scale: float
	var world_position: Vector3 = Vector3.ZERO
	var density_data: Array  # 3D array [x][y][z] of floats

	func _init(size: Vector3i, scale: float) -> void:
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
	
	func set_density(pos: Vector3i, value: float) -> void:
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
				# Check if we've exceeded our time budget.
				# GATED. On the capture path there is no next frame to wait for, and
				# yielding here is what turns a still of this artifact into a photograph
				# of a half-marched chunk. The map path is untouched.
				if not synchronous:
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
	var triangles = []

	# Get edge indices from lookup table (flat array, 3 edges per triangle)
	var triangle_config = get_triangle_configuration(cube_index)

	# Parse into individual triangles (groups of 3 edge indices)
	var i = 0
	while i + 2 < triangle_config.size():
		var triangle = [triangle_config[i], triangle_config[i + 1], triangle_config[i + 2]]
		triangles.append(triangle)
		i += 3

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
	var result: Array[int] = []
	if cube_index >= 0 and cube_index < 256:
		var config = MarchingCubesLookupTables.triangle_table[cube_index]
		for val in config:
			result.append(val as int)
	return result

func get_edge_table_entry(cube_index: int) -> int:
	"""Get edge table entry for cube configuration"""
	if cube_index >= 0 and cube_index < 256:
		return MarchingCubesLookupTables.edge_table[cube_index]
	return 0

func carve_sphere(chunk: RhizomeVoxelChunk, center: Vector3, radius: float) -> void:
	"""Carve a spherical cavity in the density field"""
	var voxel_center = center / voxel_scale
	# THE `bore` AXIS, and the only place it touches anything. The growth graph has
	# already been decided by the time this runs, so every rung carves the SAME network
	# at a different width — same nodes, same edges, same positions, same rng draws.
	# carve_tunnel reaches the field only through this function, so scaling here scales
	# tunnels and chambers alike and nothing else. `radius * 1.0` is bit-identical.
	var voxel_radius = (radius * carve_radius_scale) / voxel_scale

	var min_x = int(max(0, voxel_center.x - voxel_radius - 1))
	var max_x = int(min(chunk.chunk_size.x - 1, voxel_center.x + voxel_radius + 1))
	var min_y = int(max(0, voxel_center.y - voxel_radius - 1))
	var max_y = int(min(chunk.chunk_size.y - 1, voxel_center.y + voxel_radius + 1))
	var min_z = int(max(0, voxel_center.z - voxel_radius - 1))
	var max_z = int(min(chunk.chunk_size.z - 1, voxel_center.z + voxel_radius + 1))

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			for z in range(min_z, max_z + 1):
				var pos = Vector3(x, y, z)
				var dist = pos.distance_to(voxel_center)
				if dist < voxel_radius:
					# Smooth falloff at edges
					var density = dist / voxel_radius
					var current = chunk.get_density(Vector3i(x, y, z))
					chunk.set_density(Vector3i(x, y, z), min(current, density))

func carve_tunnel(chunk: RhizomeVoxelChunk, connection: Dictionary) -> void:
	"""Carve a tunnel between two points"""
	var start = connection.get("start", Vector3.ZERO)
	var end = connection.get("end", Vector3.ZERO)
	var start_radius = connection.get("start_radius", 2.0)
	var end_radius = connection.get("end_radius", 2.0)

	# Sample points along the tunnel
	var length = start.distance_to(end)
	var step_len: float = voxel_scale * 0.5
	# COST GUARD, live only on the WIDE rungs of `bore`. carve_sphere's clamped loop is
	# O(radius^3) capped by the chunk, and this samples the segment twice per voxel: at
	# bore=hollow the carve radius is 7.2 m in a 24 m box, so every one of ~50 samples
	# sweeps the ENTIRE chunk and a single tunnel costs ~700k voxel writes. A tube of
	# carved radius R is fully resolved by samples every R/4 — four per radius cannot
	# leave a seam between consecutive spheres — so the spacing is floored at that.
	# Gated on > 1.0, which means bore=tunnel (the default) and bore=thread both take the
	# shipped expression: step_len is voxel_scale * 0.5 and the division is the same one.
	if carve_radius_scale > 1.0:
		var min_r: float = minf(float(start_radius), float(end_radius)) * carve_radius_scale
		step_len = maxf(step_len, min_r * 0.25)
	var steps = int(max(2, length / step_len))

	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var pos = start.lerp(end, t)
		var radius = lerpf(start_radius, end_radius, t)
		carve_sphere(chunk, pos, radius)

# Public API methods for cave generation
func setup_parameters(params: Dictionary) -> void:
	"""Setup basic cave generation parameters"""
	if params.has("chunk_size"):
		chunk_size = params["chunk_size"]
	if params.has("voxel_scale"):
		voxel_scale = params["voxel_scale"]
	if params.has("threshold"):
		threshold = params["threshold"]
	# REPORTED, NOT INVENTED. Every caller of this function has always passed a "seed"
	# key and this function has always dropped it: RhizomeCaveDemoController wrote
	# `"seed": randi()` and examples/simple_cave.gd writes `"seed": 12345, # Reproducible
	# generation`, and neither has ever reached the RNG. The key is now read. It defaults
	# to -1 in the controller, which is the sentinel RhizomeGrowthPattern._init already
	# understood, so the shipped `randi()` path below is unchanged.
	if params.has("seed"):
		growth_seed = int(params["seed"])

# Rhizome growth parameters
var rhizome_branch_probability: float = 0.6
var rhizome_merge_distance: float = 6.0
var rhizome_vertical_bias: float = 0.3
var rhizome_chamber_probability: float = 0.25
var rhizome_max_depth: int = 4
# RhizomeGrowthPattern declares these two and set_growth_rules never read them, so
# nothing in the corpus could reach them and every cave was grown at 5..20 m. The
# defaults here ARE 5.0 and 20.0, so that stays true unless someone says otherwise.
var rhizome_min_branch_length: float = 5.0
var rhizome_max_branch_length: float = 20.0
var rhizome_growth: RhizomeGrowthPattern

func configure_rhizome_parameters(params: Dictionary) -> void:
	"""Configure rhizomatic growth parameters"""
	if params.has("branch_probability"):
		rhizome_branch_probability = params["branch_probability"]
	if params.has("merge_distance"):
		rhizome_merge_distance = params["merge_distance"]
	if params.has("vertical_bias"):
		rhizome_vertical_bias = params["vertical_bias"]
	if params.has("chamber_probability"):
		rhizome_chamber_probability = params["chamber_probability"]
	if params.has("max_depth"):
		rhizome_max_depth = params["max_depth"]
	if params.has("min_branch_length"):
		rhizome_min_branch_length = float(params["min_branch_length"])
	if params.has("max_branch_length"):
		rhizome_max_branch_length = float(params["max_branch_length"])


## Free ONLY what this script created, and nothing else. GridInteractablesComponent
## attaches its own children to a spawned artifact; a blanket sweep of get_children()
## would take them too.
func clear_generated() -> void:
	for n in _owned:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_owned.clear()


func generate_cave_async() -> void:
	"""Generate cave asynchronously using rhizomatic growth"""
	# Emit progress at start
	generation_progress.emit(0.0)

	# Create rhizome growth pattern
	# SEEDED, OR NOT, EXACTLY AS BEFORE. growth_seed is -1 unless somebody set it, and
	# on that branch this is the same `RhizomeGrowthPattern.new(randi())` call at the
	# same site drawing from the same unseeded global stream. The only thing that has
	# changed for a map is that the controller no longer takes a second randi() draw
	# and throws it away. With a seed the whole growth history repeats, which is what
	# lets four tiles be four views of ONE cave rather than four different caves.
	rhizome_growth = RhizomeGrowthPattern.new(growth_seed if growth_seed >= 0 else randi())
	rhizome_growth.set_growth_rules({
		"branch_probability": rhizome_branch_probability,
		"merge_distance": rhizome_merge_distance,
		"vertical_bias": rhizome_vertical_bias,
		"chamber_probability": rhizome_chamber_probability,
		"max_depth": rhizome_max_depth,
		"min_branch_length": rhizome_min_branch_length,
		"max_branch_length": rhizome_max_branch_length
	})

	# Add initial growth nodes
	var center = Vector3(chunk_size.x / 2.0, chunk_size.y / 2.0, chunk_size.z / 2.0) * voxel_scale
	rhizome_growth.add_growth_node(center, 3.0)

	# Generate network
	generation_progress.emit(10.0)
	var network = rhizome_growth.generate_rhizome_network(30)
	generation_progress.emit(30.0)

	if not synchronous:
		await get_tree().process_frame

	# Create voxel chunk
	var chunk = RhizomeVoxelChunk.new(chunk_size, voxel_scale)

	# Convert rhizome network to density field
	# Start with solid (density = 1.0)
	for x in range(chunk_size.x):
		for y in range(chunk_size.y):
			for z in range(chunk_size.z):
				chunk.set_density(Vector3i(x, y, z), 1.0)

	generation_progress.emit(40.0)
	if not synchronous:
		await get_tree().process_frame

	# Carve tunnels along connections
	var connections = network.get("connections", [])
	for conn in connections:
		carve_tunnel(chunk, conn)

	generation_progress.emit(60.0)
	if not synchronous:
		await get_tree().process_frame

	# Carve chambers at nodes
	var all_nodes = network.get("all_nodes", [])
	for node in all_nodes:
		if node is RhizomeGrowthPattern.GrowthNode:
			carve_sphere(chunk, node.position, node.radius * (2.0 if node.is_chamber else 1.0))

	generation_progress.emit(80.0)
	if not synchronous:
		await get_tree().process_frame
	
	# Generate mesh from chunk
	var mesh = await generate_mesh_from_chunk_async(chunk)

	# Create MeshInstance3D and add to scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "CaveMesh"

	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.35, 0.5)
	material.metallic = 0.2
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	add_child(mesh_instance)
	_owned.append(mesh_instance)

	# Create collision
	if mesh.get_surface_count() > 0:
		var collision_body = StaticBody3D.new()
		collision_body.name = "CaveCollision"
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = mesh.create_trimesh_shape()
		collision_body.add_child(collision_shape)
		add_child(collision_body)
		_owned.append(collision_body)

	# Emit completion
	generation_complete.emit()
	generation_progress.emit(100.0)

func get_cave_info() -> Dictionary:
	"""Return statistics about the generated cave"""
	var info = {
		"mesh_instances": 0,
		"collision_bodies": 0,
		"total_vertices": 0,
		"total_triangles": 0,
		"voxel_chunks": 1,
		"growth_nodes": 0,
		"chambers": 0
	}

	for child in get_children():
		if child is MeshInstance3D:
			info.mesh_instances += 1
			if child.mesh:
				for i in range(child.mesh.get_surface_count()):
					var arrays = child.mesh.surface_get_arrays(i)
					if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX]:
						info.total_vertices += arrays[Mesh.ARRAY_VERTEX].size()
					if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX]:
						info.total_triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		elif child is StaticBody3D:
			info.collision_bodies += 1

	return info

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
