# marching_cubes.gd - Isosurface extraction (like liquid/terrain)
extends Node3D

@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var cell_size: float = 0.5
@export var iso_value: float = 0.5
@export var noise_scale: float = 5.0

var mesh_instance: MeshInstance3D

func _ready():
	generate_mesh()

func generate_mesh():
	var scalar_field = generate_scalar_field()
	var mesh = marching_cubes(scalar_field)
	
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 0.9)
	material.roughness = 0.3
	material.metallic = 0.1
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func generate_scalar_field() -> Array:
	var field = []
	field.resize(grid_size.x)
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	for x in range(grid_size.x):
		field[x] = []
		field[x].resize(grid_size.y)
		for y in range(grid_size.y):
			field[x][y] = []
			field[x][y].resize(grid_size.z)
			for z in range(grid_size.z):
				# Sphere + noise for interesting shape
				var center = Vector3(grid_size) * 0.5
				var pos = Vector3(x, y, z)
				var dist = pos.distance_to(center)
				var sphere = 1.0 - (dist / (grid_size.x * 0.4))
				var n = noise.get_noise_3d(x * noise_scale, y * noise_scale, z * noise_scale)
				field[x][y][z] = sphere + n * 0.3

	return field

func marching_cubes(field: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Marching cubes lookup table (simplified - only showing concept)
	# Full implementation would have 256 cases
	
	for x in range(grid_size.x - 1):
		for y in range(grid_size.y - 1):
			for z in range(grid_size.z - 1):
				# Get 8 corner values
				var cube_values = [
					field[x][y][z],
					field[x+1][y][z],
					field[x+1][y][z+1],
					field[x][y][z+1],
					field[x][y+1][z],
					field[x+1][y+1][z],
					field[x+1][y+1][z+1],
					field[x][y+1][z+1]
				]
				
				# Get corner positions
				var cube_corners = [
					Vector3(x, y, z),
					Vector3(x+1, y, z),
					Vector3(x+1, y, z+1),
					Vector3(x, y, z+1),
					Vector3(x, y+1, z),
					Vector3(x+1, y+1, z),
					Vector3(x+1, y+1, z+1),
					Vector3(x, y+1, z+1)
				]
				
				# Calculate case index (which corners are inside)
				var cube_index = 0
				for i in range(8):
					if cube_values[i] > iso_value:
						cube_index |= (1 << i)
				
				# Simplified: just handle some basic cases
				if cube_index != 0 and cube_index != 255:
					add_cube_triangles(st, cube_corners, cube_values, cube_index)
	
	st.generate_normals()
	return st.commit()

func add_cube_triangles(st: SurfaceTool, corners: Array, values: Array, case_idx: int):
	# Simplified triangle generation (real implementation uses lookup tables)
	# This creates basic geometry for demonstration
	
	var center = Vector3.ZERO
	for c in corners:
		center += c
	center = center / 8.0 * cell_size
	
	# Add a simple triangle for non-empty/non-full cases
	if case_idx > 0 and case_idx < 255:
		st.add_vertex(center)
		st.add_vertex(corners[0] * cell_size)
		st.add_vertex(corners[1] * cell_size)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		generate_mesh()
