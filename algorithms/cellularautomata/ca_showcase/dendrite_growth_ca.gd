# DendriteGrowthCA.gd
# Crystal dendrite formation simulation
extends BaseCA

const GROWTH_PROBABILITY = 0.3
const BRANCHING_FACTOR = 0.15

var growth_centers: Array = []

func initialize_grid():
	# Configure MultiMesh
	var step = 3
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
	grid = create_3d_grid()
	
	# Central growth point
	var center = Vector3i(GRID_SIZE/2, GRID_SIZE/2, GRID_SIZE/2)
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
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 3
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				if grid[x][y][z] == 2:  # Dendrite
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic: Distance from center for gradient
					var dist = Vector3(x,y,z).distance_to(Vector3(GRID_SIZE/2, GRID_SIZE/2, GRID_SIZE/2))
					var hue = fmod(dist / (GRID_SIZE/2.0), 1.0)
					mm.set_instance_color(idx, Color.from_hsv(hue, 0.8, 1.0))
					
					idx += 1

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
