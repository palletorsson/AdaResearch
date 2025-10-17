# DendriteGrowthCA.gd
# Crystal dendrite formation simulation
extends BaseCA

const GROWTH_PROBABILITY = 0.3
const BRANCHING_FACTOR = 0.15

var growth_centers: Array = []

func initialize_grid():
	grid = create_3d_grid()
	
	# Central growth point
	var center = Vector3i(GRID_SIZE/2.0, GRID_SIZE/2.0, GRID_SIZE/2.0)
	growth_centers.append(center)
	grid[center.x][center.y][center.z] = 2  # Dendrite state

func update_simulation(delta):
	# Probabilistic dendrite branching
	for center in growth_centers:
		if randf() < GROWTH_PROBABILITY:
			add_dendrite_branch(center)
	
	update_visualization()

func add_dendrite_branch(center: Vector3i):
	# Probabilistic growth in 6 directions
	var growth_directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for direction in growth_directions:
		var new_pos = center + direction
		if is_valid_3d_position(new_pos) and randf() < BRANCHING_FACTOR:
			if grid[new_pos.x][new_pos.y][new_pos.z] == 0:
				grid[new_pos.x][new_pos.y][new_pos.z] = 2  # Dendrite state
				# Add new growth center for branching
				if randf() < 0.1:
					growth_centers.append(new_pos)

func update_visualization():
	var array_mesh = ArrayMesh.new()
	
	# Create mesh for dendrite cells
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	# Sample subset for performance
	var step = 3
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == 2:  # Dendrite
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, z)
					vertex_index += 8
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(0, material_active)
	
	mesh_instance.mesh = array_mesh

func get_dendrite_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 2:
					count += 1
	return count

func reset_simulation():
	grid = create_3d_grid()
	growth_centers.clear()
	initialize_grid()
	iteration_count = 0
