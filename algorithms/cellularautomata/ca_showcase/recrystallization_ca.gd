# RecrystallizationCA.gd
# Metal recrystallization simulation
extends BaseCA

const GROWTH_RATE = 0.02
const NUCLEATION_SITES = 5

var nucleation_sites: Array = []

func initialize_grid():
	# Configure MultiMesh
	var step = 4
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
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

func update_simulation(_delta):
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
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 4
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == 1:  # Crystal
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic: Randomize slightly for crystal effect
					var col = Color.CYAN.lightened(randf() * 0.2)
					mm.set_instance_color(idx, col)
					
					idx += 1

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
