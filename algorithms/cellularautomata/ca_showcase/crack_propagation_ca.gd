# CrackPropagationCA.gd
# Material crack propagation simulation
extends BaseCA

const CRACK_THRESHOLD = 0.4
const STRESS_POINTS = 3

var stress_points: Array = []

func initialize_grid():
	grid = create_3d_grid()
	
	# Add initial stress concentrators
	for i in range(STRESS_POINTS):
		var stress_point = Vector3i(
			randi() % GRID_SIZE,
			GRID_SIZE - 1,
			randi() % GRID_SIZE
		)
		stress_points.append(stress_point)
		grid[stress_point.x][stress_point.y][stress_point.z] = 1  # Stress point

func update_simulation(delta):
	# Propagate cracks from stress concentrators
	propagate_cracks()
	update_visualization()

func propagate_cracks():
	for stress_point in stress_points:
		var neighbors = get_3d_neighbors(stress_point)
		for neighbor in neighbors:
			if is_valid_3d_position(neighbor) and randf() < 0.05:
				if grid[neighbor.x][neighbor.y][neighbor.z] == 0:
					grid[neighbor.x][neighbor.y][neighbor.z] = 2  # Cracked state

func update_visualization():
	var array_mesh = ArrayMesh.new()
	
	# Create separate surfaces for different states
	create_mesh_surface(array_mesh, 1, material_active)    # Stress points
	create_mesh_surface(array_mesh, 2, material_occupied)  # Cracks
	
	mesh_instance.mesh = array_mesh

func create_mesh_surface(array_mesh: ArrayMesh, target_state: int, material: StandardMaterial3D):
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	var step = 3
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == target_state:
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, z)
					vertex_index += 8
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		var surface_index = array_mesh.get_surface_count()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(surface_index, material)

func get_crack_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 2:
					count += 1
	return count

func reset_simulation():
	grid = create_3d_grid()
	stress_points.clear()
	initialize_grid()
	iteration_count = 0
