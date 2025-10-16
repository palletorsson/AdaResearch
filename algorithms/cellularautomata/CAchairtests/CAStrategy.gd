class_name CAStrategy
extends RefCounted

const Cell = preload("res://algorithms/cellularautomata/CAchairtests/Cell.gd")

enum StrategyType { SIMPLE_SWITCHED, MEMORY_BASED, GRADIENT_BASED, PURE_CA }

var grid: CAGrid
var strategy_type: StrategyType

func _init(grid_ref: CAGrid, type: StrategyType):
	grid = grid_ref
	strategy_type = type

func step():
	"""Execute one generation step"""
	match strategy_type:
		StrategyType.SIMPLE_SWITCHED:
			strategy_simple_switched()
		StrategyType.MEMORY_BASED:
			strategy_memory_based()
		StrategyType.GRADIENT_BASED:
			strategy_gradient_based()
		StrategyType.PURE_CA:
			strategy_pure_ca()
	
	grid.generation += 1
	grid.update_visualization()

func strategy_simple_switched():
	"""Strategy 1: Simple time-based rule switching"""
	var new_states = []
	var max_seat_radius = 4.5  # Maximum distance from origin for seat cells

	if grid.generation < 10:
		# Phase 1: All pillars grow vertically
		for cell in grid.cells:
			if cell.is_occupied:
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, cell.memory_type])

	elif grid.generation < 15:
		# Phase 2: Front spread, back continue up
		for cell in grid.cells:
			if cell.is_occupied:
				var type = cell.memory_type

				# Back pillars continue up
				if type in [Cell.CellType.BACK_LEFT, Cell.CellType.BACK_RIGHT]:
					var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
					if above and not above.is_occupied:
						new_states.append([above, type])

				# Front pillars spread horizontally (with constraints)
				elif type in [Cell.CellType.FRONT_LEFT, Cell.CellType.FRONT_RIGHT]:
					# Only edge cells can spread
					var horiz_neighbors = count_horizontal_neighbors(cell)

					if horiz_neighbors < 8:  # Cell is at edge
						var origin = get_pillar_origin(type)

						for dx in [-1, 0, 1]:
							for dy in [-1, 0, 1]:
								if dx == 0 and dy == 0:
									continue

								var new_x = cell.position.x + dx
								var new_y = cell.position.y + dy
								var neighbor = grid.get_cell(new_x, new_y, cell.position.z)

								if neighbor and not neighbor.is_occupied:
									# Check distance from origin pillar
									var dist = Vector2(new_x - origin.x, new_y - origin.y).length()

									if dist <= max_seat_radius:
										new_states.append([neighbor, type])

	# Apply new states
	for state in new_states:
		state[0].set_occupied(state[1], grid.generation)

func strategy_memory_based():
	"""Strategy 2: Cells remember origin and act accordingly"""
	var new_states = []
	
	for cell in grid.cells:
		if cell.is_occupied:
			var age = grid.generation - cell.generation_born
			var type = cell.memory_type
			
			# Initial vertical growth
			if age < 8:
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, type])
					
			# Divergent behavior based on type
			else:
				if type in [Cell.CellType.BACK_LEFT, Cell.CellType.BACK_RIGHT]:
					# Back pillars: continue up
					if age < 18:
						var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
						if above and not above.is_occupied:
							new_states.append([above, type])
							
				elif type in [Cell.CellType.FRONT_LEFT, Cell.CellType.FRONT_RIGHT]:
					# Front pillars: spread toward center
					if age < 13:
						var center_x = grid.grid_size.x / 2
						var center_y = grid.grid_size.y / 2
						var dx = sign(center_x - cell.position.x)
						var dy = sign(center_y - cell.position.y)
						
						var neighbor = grid.get_cell(
							cell.position.x + dx,
							cell.position.y + dy,
							cell.position.z
						)
						if neighbor and not neighbor.is_occupied:
							new_states.append([neighbor, type])
	
	# Apply new states
	for state in new_states:
		state[0].set_occupied(state[1], grid.generation)

func compute_gradient():
	"""Compute distance gradient from back edge"""
	var back_cells = []
	
	for cell in grid.cells:
		if cell.is_occupied and cell.memory_type in [Cell.CellType.BACK_LEFT, Cell.CellType.BACK_RIGHT]:
			back_cells.append(cell)
	
	if back_cells.is_empty():
		return
	
	for cell in grid.cells:
		var min_dist = INF
		for back_cell in back_cells:
			var dist = cell.position.distance_to(back_cell.position)
			min_dist = min(min_dist, dist)
		cell.gradient = min_dist

func strategy_gradient_based():
	"""Strategy 3: Chemical gradient determines behavior"""
	compute_gradient()
	var new_states = []
	
	for cell in grid.cells:
		if cell.is_occupied:
			var gradient_value = cell.gradient
			
			# High gradient (far from back) = horizontal growth
			if gradient_value > 5.0 and grid.generation > 5:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var neighbor = grid.get_cell(
							cell.position.x + dx,
							cell.position.y + dy,
							cell.position.z
						)
						if neighbor and not neighbor.is_occupied:
							new_states.append([neighbor, cell.memory_type])
			else:
				# Low gradient = vertical growth
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, cell.memory_type])
	
	# Apply new states
	for state in new_states:
		state[0].set_occupied(state[1], grid.generation)

func strategy_pure_ca():
	"""Strategy 4: Pure CA with state encoding"""
	var new_states = []
	
	# Calculate local "clock" from column heights
	var heights = {}
	for cell in grid.cells:
		if cell.is_occupied:
			var key = Vector2i(cell.position.x, cell.position.y)
			if not heights.has(key):
				heights[key] = 0
			heights[key] = max(heights[key], cell.position.z + 1)
	
	for cell in grid.cells:
		if cell.is_occupied:
			var key = Vector2i(cell.position.x, cell.position.y)
			var height = heights.get(key, 0)
			
			if height < 10:
				# Phase 1: Grow up
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, cell.memory_type])
			else:
				# Phase 2: Check neighbors to determine position
				var back_neighbors = 0
				for dy in [1]:
					var neighbor = grid.get_cell(cell.position.x, cell.position.y + dy, cell.position.z)
					if neighbor and neighbor.is_occupied:
						back_neighbors += 1
				
				if back_neighbors == 0:  # At the back
					var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
					if above and not above.is_occupied:
						new_states.append([above, cell.memory_type])
				else:  # At the front
					for dx in [-1, 0, 1]:
						for dy in [-1, 0, 1]:
							var neighbor = grid.get_cell(
								cell.position.x + dx,
								cell.position.y + dy,
								cell.position.z
							)
							if neighbor and not neighbor.is_occupied:
								new_states.append([neighbor, cell.memory_type])

	# Apply new states
	for state in new_states:
		state[0].set_occupied(state[1], grid.generation)

func count_horizontal_neighbors(cell: Cell) -> int:
	"""Count neighbors in the same horizontal layer (Z level)"""
	var count = 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var neighbor = grid.get_cell(
				cell.position.x + dx,
				cell.position.y + dy,
				cell.position.z
			)
			if neighbor and neighbor.is_occupied:
				count += 1
	return count

func get_pillar_origin(type: Cell.CellType) -> Vector2i:
	"""Get the original position of a pillar type"""
	var center_x = grid.grid_size.x / 2
	var center_y = grid.grid_size.y / 2
	var spacing = 3

	match type:
		Cell.CellType.FRONT_LEFT:
			return Vector2i(center_x - spacing, center_y - spacing)
		Cell.CellType.FRONT_RIGHT:
			return Vector2i(center_x + spacing, center_y - spacing)
		Cell.CellType.BACK_LEFT:
			return Vector2i(center_x - spacing, center_y + spacing)
		Cell.CellType.BACK_RIGHT:
			return Vector2i(center_x + spacing, center_y + spacing)
		_:
			return Vector2i(center_x, center_y)
