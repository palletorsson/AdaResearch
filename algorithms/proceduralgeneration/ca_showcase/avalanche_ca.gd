# AvalancheCA.gd
# Sand pile avalanche model (Bak-Tang-Wiesenfeld)
extends BaseCA

const CRITICAL_SLOPE = 4
const SAND_DROP_RATE = 0.1

func initialize_grid():
	grid = create_2d_grid()

func update_simulation(delta):
	# Add sand grain to random location
	if randf() < SAND_DROP_RATE:
		add_sand_grain()
	
	# Check for avalanche conditions
	check_avalanche_conditions()
	
	update_visualization()

func add_sand_grain():
	var x = randi() % GRID_SIZE
	var y = randi() % GRID_SIZE
	grid[x][y] += 1

func check_avalanche_conditions():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] >= CRITICAL_SLOPE:
				# Avalanche occurs - redistribute to neighbors
				var excess = grid[x][y] - CRITICAL_SLOPE + 1
				grid[x][y] = CRITICAL_SLOPE - 1
				
				var neighbors = get_2d_neighbors(Vector2i(x, y))
				for neighbor in neighbors:
					if is_valid_2d_position(neighbor):
						grid[neighbor.x][neighbor.y] += excess / neighbors.size()

func update_visualization():
	var array_mesh = ArrayMesh.new()
	
	# Create mesh for sand pile
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	var step = 2
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			var height = grid[x][y]
			if height > 0:
				# Create multiple cubes for height visualization
				for h in range(height):
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, h)
					vertex_index += 8
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		array_mesh.surface_set_material(0, material_occupied)
	
	mesh_instance.mesh = array_mesh

func get_total_sand() -> int:
	var total = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			total += grid[x][y]
	return total

func reset_simulation():
	grid = create_2d_grid()
	iteration_count = 0
