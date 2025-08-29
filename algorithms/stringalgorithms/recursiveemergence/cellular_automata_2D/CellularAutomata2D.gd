extends Node3D
class_name CellularAutomata2DSystem

var time: float = 0.0
var generation: int = 0
var generation_time: float = 0.0
var generation_interval: float = 0.5
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

func _ready():
	# Initialize Cellular Automata visualization
	print("Cellular Automata 2D Visualization initialized")
	initialize_grid()
	create_pattern_indicators()
	setup_automata_metrics()

func _process(delta):
	time += delta
	generation_time += delta
	
	# Update generation
	if generation_time >= generation_interval:
		generation_time = 0.0
		update_generation()
		generation += 1
	
	animate_cells(delta)
	animate_rule_engine(delta)
	animate_pattern_evolution(delta)
	update_automata_metrics(delta)

func initialize_grid():
	# Initialize cellular automata grid
	cell_grid = []
	next_grid = []
	
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
	# Clear existing cells
	for child in $CellGrid/LiveCells.get_children():
		child.queue_free()
	for child in $CellGrid/DeadCells.get_children():
		child.queue_free()
	
	live_cells.clear()
	dead_cells.clear()
	
	# Create visual representation of cells
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = CSGBox3D.new()
			cell.size = Vector3(0.3, 0.1, 0.3)
			cell.material_override = StandardMaterial3D.new()
			
			# Position cell in grid
			var pos_x = (x - grid_size/2.0) * 0.4
			var pos_z = (y - grid_size/2.0) * 0.4
			cell.position = Vector3(pos_x, 0, pos_z)
			
			if cell_grid[x][y]:
				# Live cell
				cell.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
				cell.material_override.emission_enabled = true
				cell.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.4
				$CellGrid/LiveCells.add_child(cell)
				live_cells.append({"cell": cell, "x": x, "y": y, "age": 0})
			else:
				# Dead cell
				cell.material_override.albedo_color = Color(0.2, 0.2, 0.2, 0.3)
				cell.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				$CellGrid/DeadCells.add_child(cell)
				dead_cells.append({"cell": cell, "x": x, "y": y})

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
	
	# Recreate visual representation
	create_cell_visuals()

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

func create_pattern_indicators():
	# Create glider indicators
	var gliders_node = $PatternEvolution/Patterns/Gliders
	for i in range(3):
		var glider = CSGCylinder3D.new()
		glider.radius = 0.1
		
		glider.height = 0.3
		glider.material_override = StandardMaterial3D.new()
		glider.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		glider.material_override.emission_enabled = true
		glider.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		var angle = float(i) / 3.0 * PI * 2
		var radius = 1.5
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		glider.position = pos
		
		gliders_node.add_child(glider)
		gliders.append(glider)
	
	# Create oscillator indicators
	var oscillators_node = $PatternEvolution/Patterns/Oscillators
	for i in range(4):
		var oscillator = CSGBox3D.new()
		oscillator.size = Vector3(0.2, 0.2, 0.2)
		oscillator.material_override = StandardMaterial3D.new()
		oscillator.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		oscillator.material_override.emission_enabled = true
		oscillator.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		var angle = float(i) / 4.0 * PI * 2
		var radius = 1.0
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		oscillator.position = pos
		
		oscillators_node.add_child(oscillator)
		oscillators.append(oscillator)
	
	# Create still life indicators
	var still_lifes_node = $PatternEvolution/Patterns/StillLifes
	for i in range(2):
		var still_life = CSGSphere3D.new()
		still_life.radius = 0.15
		still_life.material_override = StandardMaterial3D.new()
		still_life.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		still_life.material_override.emission_enabled = true
		still_life.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		var pos = Vector3((i - 0.5) * 1.0, 0, 0)
		still_life.position = pos
		
		still_lifes_node.add_child(still_life)
		still_lifes.append(still_life)

func setup_automata_metrics():
	# Initialize automata metrics
	var density_indicator = $AutomataMetrics/DensityMeter/DensityIndicator
	var stability_indicator = $AutomataMetrics/StabilityMeter/StabilityIndicator
	if density_indicator:
		density_indicator.position.x = 0  # Start at middle
	if stability_indicator:
		stability_indicator.position.x = 0  # Start at middle

func animate_cells(delta):
	# Animate live cells
	for i in range(live_cells.size()):
		var cell_data = live_cells[i]
		var cell = cell_data["cell"]
		
		if cell:
			# Age the cell
			cell_data["age"] += delta
			
			# Pulse based on age and generation
			var pulse = 1.0 + sin(time * 3.0 + i * 0.2) * 0.2
			cell.scale = Vector3.ONE * pulse
			
			# Change color based on age
			var age_factor = min(1.0, cell_data["age"] * 0.5)
			var green_component = 0.8 * (1.0 - age_factor * 0.5)
			var red_component = 0.2 + age_factor * 0.3
			cell.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
			
			# Increase emission for newer cells
			var emission_intensity = 0.4 + (1.0 - age_factor) * 0.3
			cell.material_override.emission = Color(red_component, green_component, 0.2, 1) * emission_intensity
	
	# Animate dead cells (subtle)
	for i in range(dead_cells.size()):
		var cell_data = dead_cells[i]
		var cell = cell_data["cell"]
		
		if cell:
			# Slight pulse for dead cells
			var pulse = 1.0 + sin(time * 1.0 + i * 0.1) * 0.05
			cell.scale = Vector3.ONE * pulse

func animate_rule_engine(delta):
	# Animate rule engine core
	var engine_core = $RuleEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on generation activity
		var pulse = 1.0 + sin(time * 2.0) * 0.1
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on activity
		if engine_core.material_override:
			var intensity = 0.3 + (generation % 10) * 0.07
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate rule cores
	var conway_core = $RuleEngine/AutomataRules/ConwayCore
	if conway_core:
		conway_core.rotation.y += delta * 0.8
		var conway_activation = sin(time * 1.5) * 0.5 + 0.5
		
		var pulse = 1.0 + conway_activation * 0.3
		conway_core.scale = Vector3.ONE * pulse
		
		if conway_core.material_override:
			var intensity = 0.3 + conway_activation * 0.7
			conway_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var rule30_core = $RuleEngine/AutomataRules/Rule30Core
	if rule30_core:
		rule30_core.rotation.y += delta * 1.0
		var rule30_activation = cos(time * 1.8) * 0.5 + 0.5
		
		var pulse = 1.0 + rule30_activation * 0.3
		rule30_core.scale = Vector3.ONE * pulse
		
		if rule30_core.material_override:
			var intensity = 0.3 + rule30_activation * 0.7
			rule30_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var rule110_core = $RuleEngine/AutomataRules/Rule110Core
	if rule110_core:
		rule110_core.rotation.y += delta * 1.2
		var rule110_activation = sin(time * 2.0) * 0.5 + 0.5
		
		var pulse = 1.0 + rule110_activation * 0.3
		rule110_core.scale = Vector3.ONE * pulse
		
		if rule110_core.material_override:
			var intensity = 0.3 + rule110_activation * 0.7
			rule110_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_pattern_evolution(delta):
	# Animate evolution core
	var evolution_core = $PatternEvolution/EvolutionCore
	if evolution_core:
		# Rotate evolution engine
		evolution_core.rotation.y += delta * 0.3
		
		# Pulse based on pattern complexity
		var pulse = 1.0 + sin(time * 2.5) * 0.1
		evolution_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if evolution_core.material_override:
			var intensity = 0.3 + density * 0.7
			evolution_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate gliders
	for i in range(gliders.size()):
		var glider = gliders[i]
		if glider:
			# Move gliders in gliding pattern
			var glider_angle = time * 0.5 + i * 0.7
			var glider_radius = 1.5 + sin(time * 0.8 + i * 0.3) * 0.3
			var move_x = cos(glider_angle) * glider_radius
			var move_z = sin(glider_angle) * glider_radius
			
			glider.position.x = lerp(glider.position.x, move_x, delta * 1.0)
			glider.position.z = lerp(glider.position.z, move_z, delta * 1.0)
			
			# Rotate glider
			glider.rotation.y += delta * 1.5
			
			# Pulse based on activity
			var pulse = 1.0 + sin(time * 3.0 + i * 0.4) * 0.3
			glider.scale = Vector3.ONE * pulse
	
	# Animate oscillators
	for i in range(oscillators.size()):
		var oscillator = oscillators[i]
		if oscillator:
			# Oscillate in place
			var oscillation = sin(time * 2.0 + i * 0.5) * 0.3
			oscillator.position.y = oscillation
			
			# Scale oscillation
			var scale_oscillation = 1.0 + sin(time * 4.0 + i * 0.6) * 0.4
			oscillator.scale = Vector3.ONE * scale_oscillation
	
	# Animate still lifes
	for i in range(still_lifes.size()):
		var still_life = still_lifes[i]
		if still_life:
			# Gentle rotation
			still_life.rotation.y += delta * 0.2
			
			# Subtle pulse
			var pulse = 1.0 + sin(time * 1.5 + i * 0.8) * 0.1
			still_life.scale = Vector3.ONE * pulse

func update_automata_metrics(delta):
	# Update density meter
	var density_indicator = $AutomataMetrics/DensityMeter/DensityIndicator
	if density_indicator:
		var target_x = lerp(-2, 2, density)
		density_indicator.position.x = lerp(density_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on density
		var green_component = 0.8 * density
		var red_component = 0.2 + 0.6 * (1.0 - density)
		density_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update stability meter
	var stability_indicator = $AutomataMetrics/StabilityMeter/StabilityIndicator
	if stability_indicator:
		var target_x = lerp(-2, 2, stability)
		stability_indicator.position.x = lerp(stability_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on stability
		var green_component = 0.8 * stability
		var red_component = 0.2 + 0.6 * (1.0 - stability)
		stability_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

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
