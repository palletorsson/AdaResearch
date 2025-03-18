# CellularAutomata.gd
extends Node
class_name CellularAutomata

# Applies a Wolfram-like 1D ruleset to a triple (a, b, c).
static func apply_ruleset(ruleset: Array[int], a: int, b: int, c: int) -> int:
	if a == 1 and b == 1 and c == 1:
		return ruleset[0]
	if a == 1 and b == 1 and c == 0:
		return ruleset[1]
	if a == 1 and b == 0 and c == 1:
		return ruleset[2]
	if a == 1 and b == 0 and c == 0:
		return ruleset[3]
	if a == 0 and b == 1 and c == 1:
		return ruleset[4]
	if a == 0 and b == 1 and c == 0:
		return ruleset[5]
	if a == 0 and b == 0 and c == 1:
		return ruleset[6]
	# a == 0, b == 0, c == 0
	return ruleset[7]

# Count alive neighbors around the cell at (x, y) in a grid.
static func count_neighbors(grid: Array, x: int, y: int, grid_size: int) -> int:
	var count = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and ny >= 0 and nx < grid_size and ny < grid_size:
				count += grid[nx][ny]
	return count

# Determines the next state of a cell given its current state, neighbor count, and threshold.
static func update_cell_state(current: int, neighbors: int, threshold: int) -> int:
	if current == 1 and (neighbors < 2 or neighbors > 3):
		return 0
	elif current == 0 and neighbors == threshold:
		return 1
	else:
		return current

# Returns a color based on the cell state.
static func get_color_for_state(state: int) -> Color:
	if state == 1:
		return Color(0.2, 0.8, 0.2)  # Green for active cells
	else:
		return Color(0.2, 0.2, 0.2, 0.0)  # Transparent or dark for inactive
