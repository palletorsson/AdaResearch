# DendriteGrowthCA.gd
# Crystal dendrite formation simulation
extends LineNetworkCA

const GROWTH_PROBABILITY = 0.3
const BRANCHING_FACTOR = 0.15

var growth_centers: Array = []

func initialize_grid() -> void:
	# Configure Line Renderer colors
	color_start = Color(0.0, 0.8, 1.0) # Cyan
	color_end = Color(0.0, 0.2, 0.8) # Deep Blue
	
	grid = create_3d_grid()
	
	# Central growth point
	var center = Vector3i(GRID_SIZE/2, GRID_SIZE/2, GRID_SIZE/2)
	growth_centers.append(center)
	grid[center.x][center.y][center.z] = 2  # Dendrite state

func update_simulation(_delta) -> void:
	# Probabilistic dendrite branching
	var new_centers = []
	
	for center in growth_centers:
		if randf() < GROWTH_PROBABILITY:
			var added = add_dendrite_branch(center)
			if added != Vector3i(-1,-1,-1):
				new_centers.append(added)
	
	# Add new centers to the list (so they can grow too)
	for nc in new_centers:
		growth_centers.append(nc)
		
	# Base class handles visualization
	super.update_visualization()

func add_dendrite_branch(center: Vector3i) -> Vector3i:
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
				return new_pos
	
	return Vector3i(-1, -1, -1)

func get_dendrite_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 2:
					count += 1
	return count

func reset_simulation() -> void:
	grid = create_3d_grid()
	growth_centers.clear()
	connections.clear()
	cell_birth_times.clear()
	cell_parents.clear()
	if immediate_mesh: immediate_mesh.clear_surfaces()
	initialize_grid()
	iteration_count = 0
