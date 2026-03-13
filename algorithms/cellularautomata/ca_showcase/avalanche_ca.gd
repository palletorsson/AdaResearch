# AvalancheCA.gd
# Sand pile avalanche model (Bak-Tang-Wiesenfeld)
extends BaseCA

const CRITICAL_SLOPE = 4
const SAND_DROP_RATE = 0.1

func initialize_grid() -> void:
	# Configure MultiMesh
	var step = 2
	var cube_size = CUBE_SIZE * step # Match step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	# Estimate max instances (grid * max_height)
	# Max stable height is 3, but can go higher temporarily. Let's say 10.
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * 10
	configure_multimesh(mesh, max_instances)
	
	grid = create_2d_grid()

func update_simulation(_delta) -> void:
	# Add sand grain to random location
	if randf() < SAND_DROP_RATE:
		add_sand_grain()
	
	# Check for avalanche conditions
	check_avalanche_conditions()
	
	update_visualization()

func add_sand_grain() -> void:
	var x = randi() % GRID_SIZE
	var y = randi() % GRID_SIZE
	grid[x][y] += 1

func check_avalanche_conditions() -> void:
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

func update_visualization() -> void:
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 2
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			var height = int(grid[x][y])
			if height > 0:
				for h in range(height):
					if idx >= mm.instance_count: break
					
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						h * CUBE_SIZE * step, # Stack vertically
						(y - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color based on height
					var col = Color.SANDY_BROWN.darkened(h * 0.1)
					mm.set_instance_color(idx, col)
					
					idx += 1

func get_total_sand() -> int:
	var total = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			total += grid[x][y]
	return total

func reset_simulation() -> void:
	grid = create_2d_grid()
	iteration_count = 0
