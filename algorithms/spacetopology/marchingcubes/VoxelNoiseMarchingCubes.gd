# VoxelNoiseMarchingCubes.gd
# Voxel world generation using marching cubes algorithm
# Combines 3D noise sampling with smooth marching cubes surface generation

extends Node3D
class_name VoxelNoiseMarchingCubes

# === WORLD SETTINGS ===
@export_group("World Configuration")
@export var chunk_size: int = 32  # Size of chunk in world units
@export var num_points_per_axis: int = 32  # Voxel resolution
@export var voxel_scale: float = 1.0
@export var iso_level: float = 0.5  # Isosurface threshold (0.0-1.0, default 0.5)
@export var generate_colliders: bool = true

# === NOISE SETTINGS ===
@export_group("Noise Parameters")
@export var noise_seed: int = 1337
@export var noise_scale: float = 0.05
@export var noise_octaves: int = 4
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 2.0

# === VISUAL SETTINGS ===
@export_group("Visuals")
@export var use_shader: bool = true
@export var glass_color: Color = Color(0.2, 0.4, 1.0, 1.0)
@export var outline_color: Color = Color(1.0, 0.0, 0.5, 1.0)
@export var outline_width: float = 1.5

# === COMPONENTS ===
var noise: FastNoiseLite

# Marching cubes lookup tables
var edge_table: Array[int] = []
var triangle_table: Array[Array] = []

# Mesh instance
var mesh_instance: MeshInstance3D

# === DATA STRUCTURES ===
class Triangle:
	var vertices: Array[Vector3]
	var normals: Array[Vector3]

	func _init(v1: Vector3, v2: Vector3, v3: Vector3) -> void:
		vertices = [v1, v2, v3]
		# Calculate normal
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var normal = edge1.cross(edge2).normalized()
		normals = [normal, normal, normal]

# === INITIALIZATION ===
func _ready() -> void:
	setup_noise()
	setup_marching_cubes_tables()
	generate_world()

func setup_noise() -> void:
	"""Initialize noise generator"""
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed
	noise.frequency = noise_scale
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_persistence
	print("VoxelNoiseMarchingCubes: Noise generator initialized")

func setup_marching_cubes_tables() -> void:
	"""Initialize marching cubes lookup tables"""
	edge_table = MarchingCubesLookupTables.get_edge_table()
	triangle_table = MarchingCubesLookupTables.get_triangle_table()
	print("VoxelNoiseMarchingCubes: Marching cubes tables initialized")

# === MAIN GENERATION ===
func generate_world() -> void:
	"""Generate the voxel world with marching cubes"""
	print("VoxelNoiseMarchingCubes: Starting world generation...")

	# Generate density field
	var density_field = generate_density_field()

	# Apply marching cubes
	var triangles = march_cubes(density_field)

	# Create mesh
	var mesh = create_mesh_from_triangles(triangles)

	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "VoxelWorld"
	add_child(mesh_instance)

	# Apply material
	if use_shader:
		apply_shader_material(mesh_instance)

	# Create collision
	if generate_colliders and mesh != null and mesh.get_surface_count() > 0:
		create_collision(mesh)

	print("VoxelNoiseMarchingCubes: World generation complete! Triangles: %d" % triangles.size())

# === DENSITY FIELD GENERATION ===
func generate_density_field() -> Array:
	"""Generate 3D density field from noise"""
	var field_size = num_points_per_axis
	var density_field: Array = []
	density_field.resize(field_size * field_size * field_size)

	var point_spacing = chunk_size / float(field_size - 1)
	var start_pos = Vector3.ZERO - Vector3.ONE * chunk_size * 0.5

	for x in range(field_size):
		for y in range(field_size):
			for z in range(field_size):
				var local_pos = Vector3(x, y, z) * point_spacing
				var world_pos = start_pos + local_pos

				# Sample noise at this position
				var noise_value = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)

				# Store as density (normalize from -1..1 to 0..1)
				var density = (noise_value + 1.0) * 0.5

				var index = x + y * field_size + z * field_size * field_size
				density_field[index] = density

	return density_field

# === MARCHING CUBES IMPLEMENTATION ===
func march_cubes(density_field: Array) -> Array[Triangle]:
	"""Apply marching cubes algorithm to density field"""
	var triangles: Array[Triangle] = []
	var field_size = num_points_per_axis
	var point_spacing = chunk_size / float(field_size - 1)
	var start_pos = Vector3.ZERO - Vector3.ONE * chunk_size * 0.5

	# Process each cube in the voxel grid
	for x in range(field_size - 1):
		for y in range(field_size - 1):
			for z in range(field_size - 1):
				var cube_triangles = process_cube(
					density_field,
					Vector3i(x, y, z),
					point_spacing,
					start_pos
				)
				triangles.append_array(cube_triangles)

	return triangles

func process_cube(density_field: Array, cube_pos: Vector3i, point_spacing: float, start_pos: Vector3) -> Array[Triangle]:
	"""Process a single cube with marching cubes algorithm"""
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
		var world_pos = start_pos + Vector3(corner_pos) * point_spacing

		var density_index = corner_pos.x + corner_pos.y * field_size + corner_pos.z * field_size * field_size
		var density = 0.0
		if density_index < density_field.size():
			density = density_field[density_index]

		cube_densities.append(density)
		cube_positions.append(world_pos)

	# Create cube data dictionary
	var cube_data = {
		"positions": cube_positions,
		"densities": cube_densities
	}

	# Apply marching cubes logic
	return march_cube(cube_data)

func march_cube(cube_data: Dictionary) -> Array[Triangle]:
	"""Apply marching cubes algorithm to single cube"""
	var triangles: Array[Triangle] = []

	# Calculate configuration index
	var config_index = 0
	for i in range(8):
		var density = cube_data.densities[i]
		if density < iso_level:
			config_index |= (1 << i)

	# Skip completely inside or outside cubes
	if config_index == 0 or config_index == 255:
		return triangles

	# Get triangulation from lookup table
	if config_index >= triangle_table.size():
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

			if v1 != null and v2 != null and v3 != null:
				triangles.append(Triangle.new(v1, v2, v3))
		i += 3

	return triangles

func calculate_edge_intersections(cube_data: Dictionary) -> Array:
	"""Calculate vertex positions on cube edges where surface crosses"""
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
			t = clamp(t, 0.0, 1.0)
			edge_vertices[i] = v1_pos.lerp(v2_pos, t)
		else:
			edge_vertices[i] = null

	return edge_vertices

# === MESH CREATION ===
func create_mesh_from_triangles(triangles: Array[Triangle]) -> ArrayMesh:
	"""Create ArrayMesh from triangle array"""
	if triangles.is_empty():
		print("Warning: No triangles generated")
		return null

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
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

func apply_shader_material(mi: MeshInstance3D) -> void:
	"""Apply glass shader with outline effect"""
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 glass_color : source_color = vec4(0.2, 0.4, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform float outline_width : hint_range(0.5, 5.0) = 1.5;

varying vec3 barycentric;

void vertex() {
	// Assign barycentric coords based on vertex ID
	int vid = VERTEX_ID % 3;
	if (vid == 0) barycentric = vec3(1.0, 0.0, 0.0);
	else if (vid == 1) barycentric = vec3(0.0, 1.0, 0.0);
	else barycentric = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	// Edge factor from barycentrics
	vec3 d = fwidth(barycentric);
	vec3 a3 = smoothstep(vec3(0.0), d * outline_width, barycentric);
	float edge = 1.0 - min(min(a3.x, a3.y), a3.z);

	// Mix between glass fill and outline
	vec3 color = mix(glass_color.rgb, outline_color.rgb, edge);

	ALBEDO = color;

	// Glassy appearance
	METALLIC = 0.1;
	ROUGHNESS = 0.1;

	// Edge glow
	EMISSION = outline_color.rgb * edge * 1.2;
}
"""

	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glass_color", glass_color)
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("outline_width", outline_width)
	mi.set_surface_override_material(0, mat)

func create_collision(mesh: ArrayMesh) -> void:
	"""Create collision shape for the mesh"""
	var col = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var concave = ConcavePolygonShape3D.new()

	# Get vertex data
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array

	concave.data = vertices
	shape.shape = concave
	col.add_child(shape)
	col.name = "VoxelWorldCollision"
	add_child(col)

# === PUBLIC API ===
func regenerate() -> void:
	"""Regenerate the world"""
	clear_world()
	generate_world()

func clear_world() -> void:
	"""Clear generated mesh and collision"""
	if mesh_instance:
		mesh_instance.queue_free()
		mesh_instance = null

	var collision = get_node_or_null("VoxelWorldCollision")
	if collision:
		collision.queue_free()

func set_noise_parameters(params: Dictionary) -> void:
	"""Update noise parameters"""
	if params.has("seed"):
		noise_seed = params.seed
		if noise:
			noise.seed = noise_seed
	if params.has("scale"):
		noise_scale = params.scale
		if noise:
			noise.frequency = noise_scale
	if params.has("octaves"):
		noise_octaves = params.octaves
		if noise:
			noise.fractal_octaves = noise_octaves
	if params.has("persistence"):
		noise_persistence = params.persistence
		if noise:
			noise.fractal_gain = noise_persistence
	if params.has("lacunarity"):
		noise_lacunarity = params.lacunarity
		if noise:
			noise.fractal_lacunarity = noise_lacunarity

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

