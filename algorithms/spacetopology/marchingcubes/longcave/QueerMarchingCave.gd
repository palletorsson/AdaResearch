extends Node3D
class_name QueerMarchingCave

# Marching cubes parameters
@export var cave_size: Vector3 = Vector3(80, 40, 80)
@export var resolution: int = 64
@export var iso_level: float = 0.0

# Noise parameters for queer bulgy aesthetics
@export var primary_noise_scale: float = 0.02
@export var secondary_noise_scale: float = 0.08
@export var bulginess: float = 1.5
@export var cave_density: float = 0.3
@export var vertical_bias: float = 0.2

# Color and animation
@export var color_shift_speed: float = 0.5
@export var pulse_intensity: float = 0.3

# Noise generators
var primary_noise: FastNoiseLite
var secondary_noise: FastNoiseLite
var bulge_noise: FastNoiseLite
var cave_noise: FastNoiseLite

# Marching cubes data
var density_field: Array = []
var vertices: PackedVector3Array
var indices: PackedInt32Array
var normals: PackedVector3Array
var colors: PackedColorArray

# Cave mesh and collision
var cave_mesh: ArrayMesh
var time: float = 0.0

# Marching cubes edge table (256 entries)
var edge_table: PackedInt32Array = [
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
]

# Simplified triangle table (first few entries - full table would be very long)
var triangle_table: Array = []

func _ready():
	setup_noise_generators()
	setup_triangle_table()
	generate_cave()

func _process(delta):
	time += delta
	animate_cave_colors(delta)

func setup_noise_generators():
	# Primary cave structure noise
	primary_noise = FastNoiseLite.new()
	primary_noise.seed = randi()
	primary_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	primary_noise.frequency = primary_noise_scale
	primary_noise.fractal_octaves = 4
	primary_noise.fractal_gain = 0.5
	
	# Secondary detail noise
	secondary_noise = FastNoiseLite.new()
	secondary_noise.seed = randi()
	secondary_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	secondary_noise.frequency = secondary_noise_scale
	primary_noise.fractal_octaves = 3
	
	# Bulge/distortion noise for queer aesthetics
	bulge_noise = FastNoiseLite.new()
	bulge_noise.seed = randi()
	bulge_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	bulge_noise.frequency = 0.01
	bulge_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	# Cave carving noise
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = randi()
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cave_noise.frequency = 0.015

func setup_triangle_table():
	# Simplified triangle table setup - in practice this would be the full 256-entry table
	triangle_table.resize(256)
	for i in range(256):
		triangle_table[i] = []
	
	# Add some basic triangle configurations (this is a simplified version)
	triangle_table[0] = []
	triangle_table[1] = [0, 8, 3]
	triangle_table[2] = [0, 1, 9]
	triangle_table[3] = [1, 8, 3, 9, 8, 1]
	# ... (full table would have all 256 configurations)

func generate_cave():
	print("Generating queer bulgy cave landscape...")
	
	clear_previous_data()
	generate_density_field()
	generate_mesh_marching_cubes()
	create_collision()
	
	print("Cave generation complete!")

func clear_previous_data():
	vertices.clear()
	indices.clear()
	normals.clear()
	colors.clear()
	density_field.clear()

func generate_density_field():
	# Create 3D density field for marching cubes
	var size_x = int(cave_size.x / resolution) + 1
	var size_y = int(cave_size.y / resolution) + 1
	var size_z = int(cave_size.z / resolution) + 1
	
	density_field.resize(size_x * size_y * size_z)
	
	for x in range(size_x):
		for y in range(size_y):
			for z in range(size_z):
				var world_pos = Vector3(
					x * resolution - cave_size.x * 0.5,
					y * resolution - cave_size.y * 0.5,
					z * resolution - cave_size.z * 0.5
				)
				
				var density = calculate_density_at_position(world_pos)
				var index = x + y * size_x + z * size_x * size_y
				density_field[index] = density

func calculate_density_at_position(pos: Vector3) -> float:
	# Primary cave structure
	var primary_val = primary_noise.get_noise_3d(pos.x, pos.y, pos.z)
	
	# Secondary detail
	var secondary_val = secondary_noise.get_noise_3d(pos.x, pos.y, pos.z) * 0.3
	
	# Bulge distortion for queer aesthetics
	var bulge_x = pos.x + bulge_noise.get_noise_3d(pos.x * 0.1, pos.y * 0.1, pos.z * 0.1) * bulginess * 10.0
	var bulge_y = pos.y + bulge_noise.get_noise_3d(pos.x * 0.12, pos.y * 0.12, pos.z * 0.12) * bulginess * 8.0
	var bulge_z = pos.z + bulge_noise.get_noise_3d(pos.x * 0.11, pos.y * 0.11, pos.z * 0.11) * bulginess * 10.0
	var bulge_val = primary_noise.get_noise_3d(bulge_x, bulge_y, bulge_z) * bulginess
	
	# Cave carving
	var cave_val = cave_noise.get_noise_3d(pos.x, pos.y, pos.z)
	
	# Vertical bias to create more horizontal cave passages
	var height_factor = pos.y / (cave_size.y * 0.5)
	var vertical_influence = height_factor * vertical_bias
	
	# Distance from center for organic cave shape
	var center_distance = pos.length() / (cave_size.length() * 0.3)
	var cave_boundary = smoothstep(0.8, 1.2, center_distance)
	
	# Combine all influences
	var final_density = primary_val + secondary_val + bulge_val * 0.5 + cave_val * cave_density
	final_density += vertical_influence + cave_boundary
	
	return final_density

func generate_mesh_marching_cubes():
	var size_x = int(cave_size.x / resolution)
	var size_y = int(cave_size.y / resolution)
	var size_z = int(cave_size.z / resolution)
	
	for x in range(size_x):
		for y in range(size_y):
			for z in range(size_z):
				process_cube(x, y, z, size_x, size_y, size_z)
	
	# Create the mesh
	if vertices.size() > 0:
		create_mesh()

func process_cube(x: int, y: int, z: int, size_x: int, size_y: int, size_z: int):
	var cube_index = 0
	var cube_vertices: Array = []
	
	# Get the 8 corner positions
	var positions = [
		Vector3(x, y, z),
		Vector3(x + 1, y, z),
		Vector3(x + 1, y + 1, z),
		Vector3(x, y + 1, z),
		Vector3(x, y, z + 1),
		Vector3(x + 1, y, z + 1),
		Vector3(x + 1, y + 1, z + 1),
		Vector3(x, y + 1, z + 1)
	]
	
	# Get density values at each corner
	var densities: Array = []
	for i in range(8):
		var pos = positions[i]
		var index = int(pos.x + pos.y * (size_x + 1) + pos.z * (size_x + 1) * (size_y + 1))
		if index < density_field.size():
			densities.append(density_field[index])
		else:
			densities.append(1.0)  # Outside bounds = solid
	
	# Determine cube configuration
	for i in range(8):
		if densities[i] < iso_level:
			cube_index |= (1 << i)
	
	# Skip if completely inside or outside
	if cube_index == 0 or cube_index == 255:
		return
	
	# Generate triangles for this cube (simplified)
	var edge_list = edge_table[cube_index]
	if edge_list != 0:
		generate_triangles_for_cube(positions, densities, edge_list, x, y, z)

func generate_triangles_for_cube(positions: Array, densities: Array, edge_list: int, x: int, y: int, z: int):
	# Simplified triangle generation
	var edge_vertices: Array = []
	
	# Calculate interpolated vertices on edges
	for i in range(12):
		if edge_list & (1 << i):
			var edge_vertex = interpolate_edge(positions, densities, i)
			edge_vertices.append(edge_vertex)
	
	# Add vertices and create triangles (simplified)
	if edge_vertices.size() >= 3:
		for i in range(0, edge_vertices.size() - 2, 3):
			if i + 2 < edge_vertices.size():
				var v1 = edge_vertices[i]
				var v2 = edge_vertices[i + 1]
				var v3 = edge_vertices[i + 2]
				
				# Convert to world coordinates
				v1 = world_position_from_grid(v1, x, y, z)
				v2 = world_position_from_grid(v2, x, y, z)
				v3 = world_position_from_grid(v3, x, y, z)
				
				# Add triangle
				add_triangle(v1, v2, v3)

func interpolate_edge(positions: Array, densities: Array, edge_index: int) -> Vector3:
	# Edge vertex mapping
	var edge_connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	if edge_index >= edge_connections.size():
		return Vector3.ZERO
	
	var v1_idx = edge_connections[edge_index][0]
	var v2_idx = edge_connections[edge_index][1]
	
	var p1 = positions[v1_idx]
	var p2 = positions[v2_idx]
	var d1 = densities[v1_idx]
	var d2 = densities[v2_idx]
	
	# Linear interpolation
	var t = (iso_level - d1) / (d2 - d1)
	t = clamp(t, 0.0, 1.0)
	
	return p1.lerp(p2, t)

func world_position_from_grid(grid_pos: Vector3, offset_x: int, offset_y: int, offset_z: int) -> Vector3:
	return Vector3(
		(grid_pos.x + offset_x) * resolution - cave_size.x * 0.5,
		(grid_pos.y + offset_y) * resolution - cave_size.y * 0.5,
		(grid_pos.z + offset_z) * resolution - cave_size.z * 0.5
	)

func add_triangle(v1: Vector3, v2: Vector3, v3: Vector3):
	var base_index = vertices.size()
	
	# Add vertices
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	
	# Add indices
	indices.append(base_index)
	indices.append(base_index + 1)
	indices.append(base_index + 2)
	
	# Calculate normal
	var normal = (v2 - v1).cross(v3 - v1).normalized()
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	
	# Generate queer colors
	colors.append(generate_queer_color(v1))
	colors.append(generate_queer_color(v2))
	colors.append(generate_queer_color(v3))

func generate_queer_color(pos: Vector3) -> Color:
	# Base queer color palette
	var base_pink = Color(0.9, 0.3, 0.7, 1.0)
	var base_purple = Color(0.6, 0.2, 0.9, 1.0)
	var base_cyan = Color(0.2, 0.8, 0.9, 1.0)
	
	# Noise-based color variation
	var color_noise = secondary_noise.get_noise_3d(pos.x * 0.05, pos.y * 0.05, pos.z * 0.05)
	var color_variation = (color_noise + 1.0) * 0.5
	
	# Height-based color mixing
	var height_ratio = (pos.y + cave_size.y * 0.5) / cave_size.y
	height_ratio = clamp(height_ratio, 0.0, 1.0)
	
	# Mix colors
	var color1 = base_pink.lerp(base_purple, height_ratio)
	var color2 = base_purple.lerp(base_cyan, color_variation)
	var final_color = color1.lerp(color2, 0.5)
	
	# Add some sparkle
	var sparkle = abs(bulge_noise.get_noise_3d(pos.x * 0.1, pos.y * 0.1, pos.z * 0.1))
	final_color = final_color.lerp(Color.WHITE, sparkle * 0.2)
	
	return final_color

func create_mesh():
	cave_mesh = ArrayMesh.new()
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	
	cave_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance = $CaveMesh
	mesh_instance.mesh = cave_mesh

func create_collision():
	var collision_shape = $CaveCollision/CollisionShape
	
	if cave_mesh and vertices.size() > 0:
		var shape = ConcavePolygonShape3D.new()
		var collision_faces: PackedVector3Array = []
		
		# Create collision from mesh
		for i in range(0, indices.size(), 3):
			collision_faces.append(vertices[indices[i]])
			collision_faces.append(vertices[indices[i + 1]])
			collision_faces.append(vertices[indices[i + 2]])
		
		shape.set_faces(collision_faces)
		collision_shape.shape = shape

func animate_cave_colors(delta):
	var mesh_instance = $CaveMesh
	if mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Pulse emission
			material.emission_energy = 1.8 + sin(time * color_shift_speed) * pulse_intensity
			
			# Shift colors
			var hue_shift = sin(time * color_shift_speed * 0.3) * 0.1
			var base_color = Color(0.7, 0.3, 0.8, 1.0)
			material.albedo_color = base_color.lerp(Color(0.8, 0.3, 0.7, 1.0), hue_shift + 0.5)

# Public API for parameter adjustment
func set_cave_parameters(params: Dictionary):
	if params.has("bulginess"):
		bulginess = params.bulginess
	if params.has("cave_density"):
		cave_density = params.cave_density
	if params.has("vertical_bias"):
		vertical_bias = params.vertical_bias
	if params.has("primary_noise_scale"):
		primary_noise_scale = params.primary_noise_scale
		primary_noise.frequency = primary_noise_scale
	if params.has("secondary_noise_scale"):
		secondary_noise_scale = params.secondary_noise_scale
		secondary_noise.frequency = secondary_noise_scale
	
	# Regenerate cave with new parameters
	generate_cave()

func regenerate_cave():
	# Generate new random seeds
	primary_noise.seed = randi()
	secondary_noise.seed = randi()
	bulge_noise.seed = randi()
	cave_noise.seed = randi()
	
	generate_cave()

func get_cave_info() -> Dictionary:
	return {
		"vertices": vertices.size(),
		"triangles": indices.size() / 3,
		"cave_size": cave_size,
		"resolution": resolution,
		"bulginess": bulginess,
		"cave_density": cave_density,
		"vertical_bias": vertical_bias
	}
