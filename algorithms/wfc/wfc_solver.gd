extends RefCounted
class_name WFCSolver

# Wave Function Collapse Solver
# Implements the WFC algorithm for 3D grid generation

var tile_types = {}  # Dictionary of tile_id -> WFCTile
var grid_size: Vector3
var grid = {}  # Dictionary of Vector3 position -> Array of possible tiles
var collapsed = {}  # Dictionary of Vector3 position -> selected tile_id
var random_seed: int = 0

signal generation_complete
signal tile_collapsed(position, tile_id)

func _init(size: Vector3 = Vector3(10, 1, 10), seed_val: int = 0):
	grid_size = size
	random_seed = seed_val
	if seed_val != 0:
		seed(seed_val)

func add_tile_type(tile: WFCTile):
	"""Register a tile type that can be used in generation"""
	tile_types[tile.tile_id] = tile

func initialize_grid():
	"""Initialize the grid with all possible tiles at each position"""
	grid.clear()
	collapsed.clear()

	var all_tile_ids = tile_types.keys()

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var pos = Vector3(x, y, z)
				grid[pos] = all_tile_ids.duplicate()

func get_entropy(pos: Vector3) -> int:
	"""Get the entropy (number of possible tiles) at a position"""
	if collapsed.has(pos):
		return 0
	if grid.has(pos):
		return grid[pos].size()
	return 0

func find_lowest_entropy_position() -> Vector3:
	"""Find uncollapsed position with fewest possible tiles"""
	var min_entropy = 999999
	var candidates = []

	for pos in grid.keys():
		if collapsed.has(pos):
			continue

		var entropy = get_entropy(pos)
		if entropy == 0:
			continue

		if entropy < min_entropy:
			min_entropy = entropy
			candidates = [pos]
		elif entropy == min_entropy:
			candidates.append(pos)

	if candidates.is_empty():
		return Vector3(-1, -1, -1)  # No valid position

	# Randomly select from candidates with same entropy
	return candidates[randi() % candidates.size()]

func collapse_at(pos: Vector3) -> bool:
	"""Collapse the wave function at a position by selecting one tile"""
	if not grid.has(pos) or collapsed.has(pos):
		return false

	var possible = grid[pos]
	if possible.is_empty():
		return false  # Contradiction - no valid tiles

	# Select tile based on weights
	var selected = select_weighted_tile(possible)
	collapsed[pos] = selected
	grid[pos] = [selected]

	emit_signal("tile_collapsed", pos, selected)

	# Propagate constraints to neighbors
	return propagate(pos)

func select_weighted_tile(tile_ids: Array) -> String:
	"""Select a tile from the list based on weights"""
	var total_weight = 0.0
	for tid in tile_ids:
		if tile_types.has(tid):
			total_weight += tile_types[tid].weight

	var r = randf() * total_weight
	var cumulative = 0.0

	for tid in tile_ids:
		if tile_types.has(tid):
			cumulative += tile_types[tid].weight
			if r <= cumulative:
				return tid

	return tile_ids[0]  # Fallback

func propagate(start_pos: Vector3) -> bool:
	"""Propagate constraints from a collapsed tile to neighbors"""
	var stack = [start_pos]

	while not stack.is_empty():
		var pos = stack.pop_back()

		# Check all 6 directions
		var directions = [
			Vector3.RIGHT,
			Vector3.LEFT,
			Vector3.UP,
			Vector3.DOWN,
			Vector3(0, 0, 1),   # FORWARD
			Vector3(0, 0, -1)   # BACK
		]

		for direction in directions:
			var neighbor_pos = pos + direction

			# Skip if out of bounds
			if not is_in_bounds(neighbor_pos):
				continue

			# Skip if already collapsed
			if collapsed.has(neighbor_pos):
				continue

			# Get current possible tiles at this position
			if not grid.has(neighbor_pos):
				continue

			var old_possibilities = grid[neighbor_pos].duplicate()
			var new_possibilities = []

			# For each possible tile at neighbor position
			for neighbor_tile_id in old_possibilities:
				var is_valid = false

				# Check if any tile at current position allows this neighbor tile
				for current_tile_id in grid[pos]:
					if tile_types.has(current_tile_id):
						var current_tile = tile_types[current_tile_id]
						if current_tile.is_compatible_with(neighbor_tile_id, direction):
							is_valid = true
							break

				if is_valid:
					new_possibilities.append(neighbor_tile_id)

			# If possibilities changed, update and add to stack
			if new_possibilities.size() < old_possibilities.size():
				if new_possibilities.is_empty():
					return false  # Contradiction
				grid[neighbor_pos] = new_possibilities
				stack.append(neighbor_pos)

	return true

func is_in_bounds(pos: Vector3) -> bool:
	"""Check if position is within grid bounds"""
	return pos.x >= 0 and pos.x < grid_size.x and \
		   pos.y >= 0 and pos.y < grid_size.y and \
		   pos.z >= 0 and pos.z < grid_size.z

func is_complete() -> bool:
	"""Check if all tiles have been collapsed"""
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var pos = Vector3(x, y, z)
				if not collapsed.has(pos):
					return false
	return true

func generate() -> bool:
	"""Run the WFC algorithm to generate the complete grid"""
	initialize_grid()

	var iterations = 0
	var max_iterations = grid_size.x * grid_size.y * grid_size.z * 10

	while not is_complete() and iterations < max_iterations:
		iterations += 1

		# Find position with lowest entropy
		var pos = find_lowest_entropy_position()
		if pos == Vector3(-1, -1, -1):
			break  # No valid position found

		# Collapse at that position
		if not collapse_at(pos):
			# Contradiction - restart or handle error
			print("WFC: Contradiction at ", pos, " - restarting")
			initialize_grid()
			iterations = 0
			continue

	var success = is_complete()
	if success:
		emit_signal("generation_complete")

	return success

func get_collapsed_grid() -> Dictionary:
	"""Get the final collapsed grid"""
	return collapsed.duplicate()
