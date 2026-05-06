# res://algorithms/proceduralgeneration/constraint_solvers/wfcRooms/wfc_maze_office.gd
# Combined WFC + Maze generator
extends "res://algorithms/proceduralgeneration/constraint_solvers/wfcRooms/wfc_office_generator.gd"

## Add a random path constraint to ensure connectivity to an office
@export var force_path_to_office : bool = true

func _initialize_grid() -> void:
	super._initialize_grid()
	
	if force_path_to_office:
		_generate_guide_path()

func _generate_guide_path() -> void:
	print("🗺️ Generating reliable path to Office...")
	
	# Start at (0,0) or random edge
	var start_pos = Vector2i(0, 0)
	
	# End at random far point
	var end_pos = Vector2i(grid_width - 1, grid_height - 1)
	
	if generation_seed >= 0:
		seed(generation_seed)
	
	# Simple Random Walk or A* to find a path
	# Since grid is empty, Manhattan path is fine, but let's make it wiggly
	var path = _get_wiggly_path(start_pos, end_pos)
	
	print("  Path length: ", path.size())
	
	# Apply constraints
	for i in range(path.size()):
		var coord = path[i]
		var x = coord.x
		var y = coord.y
		
		if i == path.size() - 1:
			# LAST CELL: Destination (Office)
			possible[y][x] = office_tiles.duplicate()
			print("  Office placed at ", x, ",", y)
			
		elif i == path.size() - 2:
			# SECOND TO LAST: Transition (Corridor -> Office)
			# We need to allow Transition tiles
			possible[y][x] = transition_tiles.duplicate()
			
		else:
			# PATH: Corridor
			possible[y][x] = corridor_tiles.duplicate()
			# Also allow transitions if we want side rooms off the main path?
			# Strict corridor path is safer for guaranteed connectivity
			
	# Start cell is definitely a corridor (Entrance)
	# possible[start_pos.y][start_pos.x] = corridor_tiles.duplicate()

func _get_wiggly_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var current = start
	var path : Array[Vector2i] = [current]
	
	# Simple step-by-step walker
	while current != end:
		var moves = []
		
		# Valid moves (neighbors)
		var potential = [
			Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
		]
		
		for p in potential:
			var next = current + p
			
			# Bounds check
			if next.x < 0 or next.x >= grid_width or next.y < 0 or next.y >= grid_height:
				continue
				
			# Don't go back immediately (simple loop avoidance)
			if path.size() > 1 and next == path[path.size()-2]:
				continue
			
			var dist_current = abs(end.x - current.x) + abs(end.y - current.y)
			var dist_next = abs(end.x - next.x) + abs(end.y - next.y)
			
			# Bias towards goal, but allow some deviation
			if dist_next < dist_current:
				# Good move
				moves.append(next)
				moves.append(next) # Weighted higher
				moves.append(next)
			else:
				# Bad move (away from goal), but allow it occasionally for wiggle
				# Only if we aren't too far away
				if randf() > 0.7:
					moves.append(next)
		
		if moves.is_empty():
			# Dead end (shouldn't happen on empty grid easily), just force naive move
			var diff = end - current
			if abs(diff.x) > abs(diff.y):
				current.x += sign(diff.x)
			else:
				current.y += sign(diff.y)
		else:
			current = moves[randi() % moves.size()]
			
		# Filter loops
		if current in path:
			# If we looped, just skip adding or truncate?
			# Let's simple truncate to the loop point to strip the loop
			var idx = path.find(current)
			path = path.slice(0, idx+1)
		else:
			path.append(current)
			
	return path

func apply_grid_config(config: Dictionary) -> void:
	pass
