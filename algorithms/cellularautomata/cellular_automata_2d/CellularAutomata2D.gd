extends Node3D

# Preload the cube scene
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

var time: float = 0.0
var generation: int = 0
var generation_time: float = 0.0
var generation_interval: float = 2.0
var density: float = 0.0
var stability: float = 0.0
var grid_size: int = 20
var cell_grid: Array = []
var next_grid: Array = []
var live_cells: Array = []
var dead_cells: Array = []
var gliders: Array = []
var oscillators: Array = []
var still_lifes: Array = []
var dying_cells: Array = []

func _ready():
	# Initialize Cellular Automata visualization
	print("Cellular Automata 2D Visualization initialized")
	$PatternEvolution.queue_free()
	$AutomataMetrics.queue_free()
	$RuleEngine.queue_free()
	initialize_grid()

func _process(delta):
	time += delta
	generation_time += delta
	
	# Update generation
	if generation_time >= generation_interval:
		generation_time = 0.0
		update_generation()
		generation += 1
	
	animate_cells(delta)

func animate_cells(delta):
	# Animate dying cells
	for dying_cell_data in dying_cells:
		for cell_data in live_cells:
			if cell_data["x"] == dying_cell_data["x"] and cell_data["z"] == dying_cell_data["z"]:
				var cell = cell_data["cell"]
				if cell:
					cell.scale = Vector3.ONE * (1.0 - generation_time / generation_interval)

	# Animate live cells
	for i in range(live_cells.size()):
		var cell_data = live_cells[i]
		var cell = cell_data["cell"]

		if cell:
			# Age the cell
			cell_data["age"] += delta

			# Access the cube mesh to update shader parameters
			var cube_mesh = cell.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
			if cube_mesh and cube_mesh.material_override:
				# Change color based on age
				var age_factor = min(1.0, cell_data["age"] * 0.5)
				var green_component = 0.8 * (1.0 - age_factor * 0.5)
				var red_component = 0.2 + age_factor * 0.3

				cube_mesh.material_override.set_shader_parameter("modelColor", Color(red_component, green_component, 0.2, 1))
				cube_mesh.material_override.set_shader_parameter("emissionColor", Color(red_component, green_component, 0.2, 1))

				# Increase emission for newer cells
				var emission_intensity = 0.4 + (1.0 - age_factor) * 0.3
				cube_mesh.material_override.set_shader_parameter("emission_strength", emission_intensity)

func initialize_grid():
	# Initialize cellular automata grid
	cell_grid = []
	next_grid = []
	live_cells.clear()
	for child in $CellGrid/LiveCells.get_children():
		child.queue_free()
	
	for x in range(grid_size):
		cell_grid.append([])
		next_grid.append([])
		for y in range(grid_size):
			# Random initial state with some bias towards dead cells
			var initial_state = randf() < 0.3
			cell_grid[x].append(initial_state)
			next_grid[x].append(false)
	
	# Add some known patterns for demonstration
	add_glider_pattern(5, 5)
	add_blinker_pattern(10, 10)
	add_block_pattern(15, 15)
	
	create_cell_visuals()

func create_cell_visuals():
	# Create visual representation of cells
	for x in range(grid_size):
		for z in range(grid_size):
			if cell_grid[x][z]:
				# Only create live cells - use cube scene
				var cell = CUBE_SCENE.instantiate()

				# Set scale to 1 meter (assuming default cube is 1x1x1)
				cell.scale = Vector3(1.0, 1.0, 1.0)

				# Position cell in grid (expanding in Z direction)
				var pos_x = (x - grid_size/2.0) * 1.1  # 1.1 for slight spacing between 1m cubes
				var pos_z = (z - grid_size/2.0) * 1.1
				cell.position = Vector3(pos_x, 0, pos_z)

				# Access the cube mesh to set material
				var cube_mesh = cell.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
				if cube_mesh and cube_mesh.material_override:
					# Update shader parameters for live cells
					cube_mesh.material_override.set_shader_parameter("modelColor", Color(0.2, 0.8, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("wireframeColor", Color(0.2, 1.0, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("emissionColor", Color(0.2, 0.8, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("emission_strength", 0.6)

				$CellGrid/LiveCells.add_child(cell)
				live_cells.append({"cell": cell, "x": x, "z": z, "age": 0})

func update_cell_visuals():
	var new_live_cells = []
	var cells_to_remove = []

	# Identify new and existing cells
	for x in range(grid_size):
		for y in range(grid_size):
			var is_alive = cell_grid[x][y]
			var cell_found = false
			for cell_data in live_cells:
				if cell_data["x"] == x and cell_data["z"] == y:
					if is_alive:
						new_live_cells.append(cell_data)
					else:
						cells_to_remove.append(cell_data)
					cell_found = true
					break
			if is_alive and not cell_found:
				# New cell
				var cell = CUBE_SCENE.instantiate()
				cell.scale = Vector3(1.0, 1.0, 1.0)
				var pos_x = (x - grid_size/2.0) * 1.1
				var pos_z = (y - grid_size/2.0) * 1.1
				cell.position = Vector3(pos_x, 0, pos_z)
				var cube_mesh = cell.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
				if cube_mesh and cube_mesh.material_override:
					cube_mesh.material_override.set_shader_parameter("modelColor", Color(0.2, 0.8, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("wireframeColor", Color(0.2, 1.0, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("emissionColor", Color(0.2, 0.8, 0.2, 1))
					cube_mesh.material_override.set_shader_parameter("emission_strength", 0.6)
				$CellGrid/LiveCells.add_child(cell)
				new_live_cells.append({"cell": cell, "x": x, "z": y, "age": 0})

	# Remove dead cells
	for cell_data in cells_to_remove:
		cell_data["cell"].queue_free()

	live_cells = new_live_cells

func add_glider_pattern(start_x: int, start_y: int):
	# Add Conway's Game of Life glider pattern
	var glider_pattern = [
		[false, true, false],
		[false, false, true],
		[true, true, true]
	]
	
	for i in range(3):
		for j in range(3):
			var x = start_x + i
			var y = start_y + j
			if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
				cell_grid[x][y] = glider_pattern[i][j]

func add_blinker_pattern(start_x: int, start_y: int):
	# Add oscillator pattern (blinker)
	for i in range(3):
		var x = start_x + i
		var y = start_y
		if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
			cell_grid[x][y] = true

func add_block_pattern(start_x: int, start_y: int):
	# Add still life pattern (block)
	for i in range(2):
		for j in range(2):
			var x = start_x + i
			var y = start_y + j
			if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
				cell_grid[x][y] = true

func update_generation():
	# Apply Conway's Game of Life rules
	var live_count = 0
	dying_cells.clear()
	
	for x in range(grid_size):
		for y in range(grid_size):
			var neighbors = count_neighbors(x, y)
			var current_state = cell_grid[x][y]
			
			# Conway's rules:
			# 1. Live cell with < 2 neighbors dies (underpopulation)
			# 2. Live cell with 2-3 neighbors survives
			# 3. Live cell with > 3 neighbors dies (overpopulation)
			# 4. Dead cell with exactly 3 neighbors becomes alive (reproduction)
			
			if current_state:
				# Live cell
				if neighbors < 2 or neighbors > 3:
					next_grid[x][y] = false  # Dies
					dying_cells.append({"x": x, "z": y})
				else:
					next_grid[x][y] = true   # Survives
					live_count += 1
			else:
				# Dead cell
				if neighbors == 3:
					next_grid[x][y] = true   # Born
					live_count += 1
				else:
					next_grid[x][y] = false  # Stays dead
	
	# Swap grids
	var temp = cell_grid
	cell_grid = next_grid
	next_grid = temp
	
	# Update density
	density = float(live_count) / (grid_size * grid_size)
	
	# Calculate stability (simplified - based on change rate)
	stability = 1.0 - min(1.0, float(live_count) * 0.01)

	update_cell_visuals()

func count_neighbors(x: int, y: int) -> int:
	var count = 0
	
	# Check all 8 neighbors
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue  # Skip center cell
			
			var nx = x + dx
			var ny = y + dy
			
			# Wrap around edges (toroidal topology)
			if nx < 0:
				nx = grid_size - 1
			elif nx >= grid_size:
				nx = 0
			
			if ny < 0:
				ny = grid_size - 1
			elif ny >= grid_size:
				ny = 0
			
			if cell_grid[nx][ny]:
				count += 1
	
	return count



func set_generation_interval(interval: float):
	generation_interval = clamp(interval, 0.1, 2.0)

func get_generation() -> int:
	return generation

func get_density() -> float:
	return density

func get_stability() -> float:
	return stability

func reset_automata():
	generation = 0
	generation_time = 0.0
	time = 0.0
	initialize_grid()
