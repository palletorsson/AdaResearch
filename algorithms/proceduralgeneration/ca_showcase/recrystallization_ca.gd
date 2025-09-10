# RecrystallizationCA.gd
# Metal recrystallization simulation
extends BaseCA

const GROWTH_RATE = 0.02
const NUCLEATION_SITES = 5

var nucleation_sites: Array = []

func initialize_grid():
	grid = create_3d_grid()
	
	# Add random nucleation sites
	for i in range(NUCLEATION_SITES):
		var site = Vector3i(
			randi() % GRID_SIZE,
			randi() % GRID_SIZE,
			randi() % GRID_SIZE
		)
		nucleation_sites.append(site)
		grid[site.x][site.y][site.z] = 1  # Mark as crystal

func update_simulation(delta):
	# Grow crystals from nucleation sites
	for site in nucleation_sites:
		if randf() < GROWTH_RATE:
			grow_crystal_at_site(site)
	
	update_visualization()

func grow_crystal_at_site(site: Vector3i):
	# Expand from nucleation sites
	var neighbors = get_3d_neighbors(site)
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor) and randf() < 0.1:
			grid[neighbor.x][neighbor.y][neighbor.z] = 1  # Crystal state

func update_visualization():
	var array_mesh = ArrayMesh.new()
	
	# Create mesh for occupied cells
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	# Sample subset for performance (every 4th cell)
	var step = 4
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == 1:  # Crystal
					create_cube_at_position(vertices, normals, indices, vertex_index, x, y, z)
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

func get_crystal_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 1:
					count += 1
	return count

func reset_simulation():
	grid = create_3d_grid()
	nucleation_sites.clear()
	initialize_grid()
	iteration_count = 0
