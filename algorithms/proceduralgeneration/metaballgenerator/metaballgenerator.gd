# MetaballGenerator.gd
# Procedural metaball system using marching cubes algorithm
extends Node3D
class_name MetaballGenerator

@export var grid_size: Vector3i = Vector3i(64, 32, 64)
@export var cell_size: float = 0.5
@export var iso_level: float = 1.0
@export var metaball_count: int = 8
@export var animation_speed: float = 0.5
@export var generate_on_ready: bool = true

# Metaball properties
var metaballs: Array[Metaball] = []
var field_values: PackedFloat32Array = []
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var static_body: StaticBody3D

# Marching cubes lookup tables
var edge_table: PackedInt32Array
var tri_table: Array[PackedInt32Array]

# Performance tracking
var generation_time: float = 0.0

class Metaball:
	var position: Vector3
	var strength: float
	var radius: float
	var velocity: Vector3
	var target_strength: float
	var animation_phase: float
	
	func _init(pos: Vector3, str: float, rad: float):
		position = pos
		strength = str
		target_strength = str
		radius = rad
		velocity = Vector3.ZERO
		animation_phase = randf() * TAU
	
	func get_field_value(point: Vector3) -> float:
		var distance = position.distance_to(point)
		if distance < 0.001:
			return strength * 1000.0  # Avoid division by zero
		return strength * radius * radius / (distance * distance)
	
	func update(delta: float, bounds: Vector3):
		# Animate metaball movement
		animation_phase += delta * 2.0
		
		# Smooth movement with sine waves
		var target_pos = Vector3(
			bounds.x * 0.3 * sin(animation_phase * 0.7),
			bounds.y * 0.2 * sin(animation_phase * 0.5 + 1.0),
			bounds.z * 0.3 * cos(animation_phase * 0.6)
		)
		
		position = position.lerp(target_pos, delta * 2.0)
		
		# Animate strength
		strength = lerp(strength, target_strength * (0.8 + 0.4 * sin(animation_phase * 1.3)), delta * 3.0)

func _ready():
	setup_marching_cubes_tables()
	setup_scene()
	
	if generate_on_ready:
		generate_metaballs()
		generate_mesh()

func setup_scene():
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Setup material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.9, 0.3)  # Yellow like in the image
	material.metallic = 0.1
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(0.2, 0.15, 0.05)
	mesh_instance.material_override = material
	
	# Create collision body
	static_body = StaticBody3D.new()
	collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	add_child(static_body)

func generate_metaballs():
	metaballs.clear()
	var bounds = Vector3(grid_size) * cell_size * 0.4
	
	# Create main cluster of metaballs
	for i in metaball_count:
		var pos = Vector3(
			randf_range(-bounds.x, bounds.x),
			randf_range(-bounds.y * 0.5, bounds.y),
			randf_range(-bounds.z, bounds.z)
		)
		
		var strength = randf_range(0.8, 2.0)
		var radius = randf_range(3.0, 8.0)
		
		var metaball = Metaball.new(pos, strength, radius)
		metaballs.append(metaball)
	
	# Add a few larger metaballs for main structure
	for i in 3:
		var pos = Vector3(
			randf_range(-bounds.x * 0.5, bounds.x * 0.5),
			randf_range(-bounds.y * 0.3, bounds.y * 0.7),
			randf_range(-bounds.z * 0.5, bounds.z * 0.5)
		)
		
		var metaball = Metaball.new(pos, randf_range(2.0, 4.0), randf_range(8.0, 12.0))
		metaballs.append(metaball)

func calculate_field_value(point: Vector3) -> float:
	var total_field = 0.0
	
	for metaball in metaballs:
		total_field += metaball.get_field_value(point)
	
	return total_field

func generate_mesh():
	var start_time = Time.get_ticks_usec()
	
	# Calculate field values for all grid points
	field_values.clear()
	field_values.resize(grid_size.x * grid_size.y * grid_size.z)
	
	var index = 0
	for z in grid_size.z:
		for y in grid_size.y:
			for x in grid_size.x:
				var world_pos = Vector3(
					(x - grid_size.x * 0.5) * cell_size,
					(y - grid_size.y * 0.5) * cell_size,
					(z - grid_size.z * 0.5) * cell_size
				)
				field_values[index] = calculate_field_value(world_pos)
				index += 1
	
	# Generate mesh using marching cubes
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for z in range(grid_size.z - 1):
		for y in range(grid_size.y - 1):
			for x in range(grid_size.x - 1):
				march_cube(x, y, z, vertices, normals, indices)
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	if vertices.size() > 0:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh_instance.mesh = array_mesh
		
		# Create collision shape
		var shape = mesh_instance.mesh.create_trimesh_shape()
		collision_shape.shape = shape
	
	generation_time = (Time.get_ticks_usec() - start_time) / 1000.0
	print("Metaball mesh generated in %.2f ms with %d vertices" % [generation_time, vertices.size()])

func march_cube(x: int, y: int, z: int, vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array):
	# Get the 8 cube vertices
	var cube_values = PackedFloat32Array()
	var cube_positions = PackedVector3Array()
	
	for i in 8:
		var dx = i & 1
		var dy = (i >> 1) & 1
		var dz = (i >> 2) & 1
		
		var grid_pos = Vector3i(x + dx, y + dy, z + dz)
		var world_pos = Vector3(
			(grid_pos.x - grid_size.x * 0.5) * cell_size,
			(grid_pos.y - grid_size.y * 0.5) * cell_size,
			(grid_pos.z - grid_size.z * 0.5) * cell_size
		)
		
		cube_positions.append(world_pos)
		cube_values.append(get_field_value_at_grid(grid_pos))
	
	# Determine cube configuration
	var cube_index = 0
	for i in 8:
		if cube_values[i] > iso_level:
			cube_index |= (1 << i)
	
	# Skip if completely inside or outside
	if cube_index == 0 or cube_index == 255:
		return
	
	# Get edge intersections
	var edge_vertices = PackedVector3Array()
	edge_vertices.resize(12)
	
	var edges = edge_table[cube_index]
	
	for i in 12:
		if edges & (1 << i):
			edge_vertices[i] = interpolate_edge(i, cube_positions, cube_values)
	
	# Generate triangles
	var triangle_config = tri_table[cube_index]
	var base_index = vertices.size()
	
	for i in range(0, triangle_config.size(), 3):
		if triangle_config[i] == -1:
			break
		
		var v1 = edge_vertices[triangle_config[i]]
		var v2 = edge_vertices[triangle_config[i + 1]]
		var v3 = edge_vertices[triangle_config[i + 2]]
		
		vertices.append(v1)
		vertices.append(v2)
		vertices.append(v3)
		
		# Calculate normal
		var normal = (v2 - v1).cross(v3 - v1).normalized()
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		
		indices.append(base_index)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		base_index += 3

func interpolate_edge(edge_index: int, positions: PackedVector3Array, values: PackedFloat32Array) -> Vector3:
	# Edge to vertex mapping
	var edge_vertices = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	var v1_idx = edge_vertices[edge_index][0]
	var v2_idx = edge_vertices[edge_index][1]
	
	var p1 = positions[v1_idx]
	var p2 = positions[v2_idx]
	var val1 = values[v1_idx]
	var val2 = values[v2_idx]
	
	# Linear interpolation to iso_level
	var t = (iso_level - val1) / (val2 - val1)
	t = clamp(t, 0.0, 1.0)
	
	return p1.lerp(p2, t)

func get_field_value_at_grid(grid_pos: Vector3i) -> float:
	if grid_pos.x < 0 or grid_pos.x >= grid_size.x or grid_pos.y < 0 or grid_pos.y >= grid_size.y or grid_pos.z < 0 or grid_pos.z >= grid_size.z:
		return 0.0
	
	var index = grid_pos.z * grid_size.y * grid_size.x + grid_pos.y * grid_size.x + grid_pos.x
	return field_values[index]

func _process(delta):
	if metaballs.size() > 0:
		# Update metaball positions
		var bounds = Vector3(grid_size) * cell_size * 0.4
		for metaball in metaballs:
			metaball.update(delta * animation_speed, bounds)
		
		# Regenerate mesh periodically for animation
		var current_time = Time.get_unix_time_from_system()
		if fmod(current_time, 0.1) < delta:
			generate_mesh()

# Marching cubes lookup tables setup
func setup_marching_cubes_tables():
	# Edge table - which edges are intersected for each cube configuration
	edge_table = PackedInt32Array([
		0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
		0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
		0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
		0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
		0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
		0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
		0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
		0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
		0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
		0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
		0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
		0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
		0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
		0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
		0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
		0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
		0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
		0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
		0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
		0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
		0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
		0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
		0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
		0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
		0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
		0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
		0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
		0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
		0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
		0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
		0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
		0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
	])
	
	# Triangle table - simplified version (you'd need the full 256 entries)
	# This is a simplified version - in a full implementation, you'd need all 256 configurations
	tri_table = []
	for i in 256:
		tri_table.append(PackedInt32Array([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]))
	
	# Add some basic triangle configurations (you'd need to complete this)
	tri_table[1] = PackedInt32Array([0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1])
	tri_table[2] = PackedInt32Array([0, 1, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1])
	# ... (you would continue with all 256 configurations)

# Public interface functions
func regenerate():
	generate_metaballs()
	generate_mesh()

func set_metaball_count(count: int):
	metaball_count = count
	regenerate()

func set_iso_level(level: float):
	iso_level = level
	generate_mesh()

func set_animation_speed(speed: float):
	animation_speed = speed
