class_name CAStrategy
extends RefCounted



enum StrategyType { SIMPLE_SWITCHED, MEMORY_BASED, GRADIENT_BASED, PURE_CA, DOWNWARD_COLUMNS }

var grid: CAGrid
var strategy_type: StrategyType

func _init(grid_ref: CAGrid, type: StrategyType) -> void:
	grid = grid_ref
	strategy_type = type

func step() -> void:
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
		StrategyType.DOWNWARD_COLUMNS:
			strategy_downward_columns()
	
	grid.generation += 1
	grid.update_visualization()

func strategy_downward_columns() -> void:
	"""Strategy 5: Start with platform, grow legs down using Rule 110"""
	var z = 6 - grid.generation
	if z < 0 or z >= 6:
		return

	var new_states = []
	var prev_z = z + 1
	
	# Define the axes for the legs (inset by 1 from 8x8 corners)
	# Platform is 6..13. Corners 6, 13. Inset: 7, 12.
	var leg_axes = [7, 12]
	
	# 1. Simulate along X-axis for fixed Y rows (Y=7, Y=12)
	for y in leg_axes:
		for x in range(1, grid.grid_size.x - 1):
			var l = 1 if is_occupied(x - 1, y, prev_z) else 0
			var c = 1 if is_occupied(x, y, prev_z) else 0
			var r = 1 if is_occupied(x + 1, y, prev_z) else 0
			
			if apply_rule_110(l, c, r):
				var cell = grid.get_cell(x, y, z)
				if cell and not cell.is_occupied:
					new_states.append([cell, ChairCell.CellType.STRUCTURE])

	# 2. Simulate along Y-axis for fixed X columns (X=7, X=12)
	for x in leg_axes:
		for y in range(1, grid.grid_size.y - 1):
			var l = 1 if is_occupied(x, y - 1, prev_z) else 0
			var c = 1 if is_occupied(x, y, prev_z) else 0
			var r = 1 if is_occupied(x, y + 1, prev_z) else 0
			
			if apply_rule_110(l, c, r):
				var cell = grid.get_cell(x, y, z)
				if cell and not cell.is_occupied:
					new_states.append([cell, ChairCell.CellType.STRUCTURE])
	
	# Apply new states
	for state in new_states:
		grid.occupy(state[0], state[1])

func is_occupied(x: int, y: int, z: int) -> bool:
	var cell = grid.get_cell(x, y, z)
	return cell != null and cell.is_occupied

func apply_rule_110(l: int, c: int, r: int) -> int:
	# Rule 110: 01101110
	# Patterns: 111(0), 110(1), 101(1), 100(0), 011(1), 010(1), 001(1), 000(0)
	var key = (l << 2) | (c << 1) | r
	var rule = 110
	return (rule >> key) & 1

func strategy_simple_switched() -> void:
	"""Strategy 1: Simple time-based rule switching"""
	var new_states = []
	var max_seat_radius = 4.5  # Maximum distance from origin for seat cells

	if grid.generation < 10:
		# Phase 1: All pillars grow vertically
		for cell in grid.occupied.duplicate():
			if cell.is_occupied:
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, cell.memory_type])

	elif grid.generation < 15:
		# Phase 2: Front spread, back continue up
		for cell in grid.occupied.duplicate():
			if cell.is_occupied:
				var type = cell.memory_type

				# Back pillars continue up
				if type in [ChairCell.CellType.BACK_LEFT, ChairCell.CellType.BACK_RIGHT]:
					var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
					if above and not above.is_occupied:
						new_states.append([above, type])

				# Front pillars spread horizontally (with constraints) - at SEAT height only. Every front cell spread,
				# at all eleven heights, so the seat filled the whole leg volume: a solid block, not a chair.
				# The legs grow one cell a generation for the first ten, so their top - the seat - is z = 10.
				elif type in [ChairCell.CellType.FRONT_LEFT, ChairCell.CellType.FRONT_RIGHT] and cell.position.z == 10:
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
		grid.occupy(state[0], state[1])

func strategy_memory_based() -> void:
	"""Strategy 2: Cells remember origin and act accordingly"""
	var new_states = []
	
	for cell in grid.occupied.duplicate():
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
				if type in [ChairCell.CellType.BACK_LEFT, ChairCell.CellType.BACK_RIGHT]:
					# Back pillars: continue up
					if age < 18:
						var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
						if above and not above.is_occupied:
							new_states.append([above, type])
							
				elif type in [ChairCell.CellType.FRONT_LEFT, ChairCell.CellType.FRONT_RIGHT]:
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
		grid.occupy(state[0], state[1])

func compute_gradient() -> void:
	"""Compute distance gradient from back edge"""
	var back_cells = []
	
	for cell in grid.occupied.duplicate():
		if cell.is_occupied and cell.memory_type in [ChairCell.CellType.BACK_LEFT, ChairCell.CellType.BACK_RIGHT]:
			back_cells.append(cell)
	
	if back_cells.is_empty():
		return

	# Only occupied cells read a gradient, and the back cells stand in vertical runs, so the distance to a
	# run is exact from its (x, y) and z span. This compared every one of 10 000 cells with every back cell:
	# 84 ms a step, 167 ms at worst - in a headset. Same values for every cell that is read. (2026-11-10)
	var runs := {}   # Vector2i(x, y) -> Vector2i(z_min, z_max)
	for back_cell in back_cells:
		var key := Vector2i(back_cell.position.x, back_cell.position.y)
		if runs.has(key):
			runs[key] = Vector2i(mini(runs[key].x, back_cell.position.z), maxi(runs[key].y, back_cell.position.z))
		else:
			runs[key] = Vector2i(back_cell.position.z, back_cell.position.z)
	for cell in grid.occupied:
		var min_dist := INF
		for key: Vector2i in runs:
			var span: Vector2i = runs[key]
			var dz := 0
			if cell.position.z < span.x:
				dz = span.x - cell.position.z
			elif cell.position.z > span.y:
				dz = cell.position.z - span.y
			var dx: int = cell.position.x - key.x
			var dy: int = cell.position.y - key.y
			min_dist = minf(min_dist, sqrt(float(dx * dx + dy * dy + dz * dz)))
		cell.gradient = min_dist

func strategy_gradient_based() -> void:
	"""Strategy 3: Chemical gradient determines behavior"""
	compute_gradient()
	var new_states = []
	
	for cell in grid.occupied.duplicate():
		if cell.is_occupied:
			var gradient_value = cell.gradient
			
			# High gradient (far from back) = horizontal growth - from the TOP of a column only. Every cell spread,
			# at every height, so the work filled into a 2 942-cell block (23-84 ms a step); from the top it lays a
			# seat, and where the seat reaches the back legs' field it turns upward into a back. (2026-11-10)
			var above_cell := grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
			if gradient_value > 5.0 and grid.generation > 5 and above_cell != null and above_cell.is_occupied:
				pass
			elif gradient_value > 5.0 and grid.generation > 5:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var neighbor = grid.get_cell(
							cell.position.x + dx,
							cell.position.y + dy,
							cell.position.z
						)
						# ...and within the legs' footprint plus two cells, as the switched strategy bounds its seat.
						if neighbor and not neighbor.is_occupied \
								and absi(neighbor.position.x - grid.grid_size.x / 2) <= 5 \
								and absi(neighbor.position.y - grid.grid_size.y / 2) <= 5:
							new_states.append([neighbor, cell.memory_type])
			else:
				# Low gradient = vertical growth
				var above = grid.get_cell(cell.position.x, cell.position.y, cell.position.z + 1)
				if above and not above.is_occupied:
					new_states.append([above, cell.memory_type])
	
	# Apply new states
	for state in new_states:
		grid.occupy(state[0], state[1])

func strategy_pure_ca() -> void:
	"""Strategy 4: Pure CA with state encoding"""
	var new_states = []
	
	# Calculate local "clock" from column heights
	var heights = {}
	for cell in grid.occupied.duplicate():
		if cell.is_occupied:
			var key = Vector2i(cell.position.x, cell.position.y)
			if not heights.has(key):
				heights[key] = 0
			heights[key] = max(heights[key], cell.position.z + 1)
	
	for cell in grid.occupied.duplicate():
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
		grid.occupy(state[0], state[1])

func count_horizontal_neighbors(cell: ChairCell) -> int:
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

func get_pillar_origin(type: ChairCell.CellType) -> Vector2i:
	"""Get the original position of a pillar type"""
	var center_x = grid.grid_size.x / 2
	var center_y = grid.grid_size.y / 2
	var spacing = 3

	match type:
		ChairCell.CellType.FRONT_LEFT:
			return Vector2i(center_x - spacing, center_y - spacing)
		ChairCell.CellType.FRONT_RIGHT:
			return Vector2i(center_x + spacing, center_y - spacing)
		ChairCell.CellType.BACK_LEFT:
			return Vector2i(center_x - spacing, center_y + spacing)
		ChairCell.CellType.BACK_RIGHT:
			return Vector2i(center_x + spacing, center_y + spacing)
		_:
			return Vector2i(center_x, center_y)
