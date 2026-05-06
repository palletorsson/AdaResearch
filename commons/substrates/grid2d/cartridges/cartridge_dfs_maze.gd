class_name CartridgeDFSMaze
extends Grid2DCartridge

## DFS recursive backtracker maze generation.
## Watch the carver drill through walls, backtrack, explore.
## States: 0=wall, 1=corridor, 2=current, 3=backtracking

const COLOR_WALL = Color(0.06, 0.05, 0.07)
const COLOR_CORRIDOR = Color(0.12, 0.35, 0.25)    # Muted green
const COLOR_CURRENT = Color(0.4, 1.0, 0.5)         # Bright green (carver head)
const COLOR_BACKTRACK = Color(0.5, 0.3, 0.15)      # Amber (retreating)

var _stack: Array[Vector2i] = []
var _visited: Dictionary = {}
var _finished: bool = false
# Maze uses odd coords as cells, even as walls
var _cell_w: int = 0
var _cell_h: int = 0


func get_name() -> String:
	return "DFS Maze Generator"

func get_state_count() -> int:
	return 4

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_WALL
		1: return COLOR_CORRIDOR
		2: return COLOR_CURRENT
		3: return COLOR_BACKTRACK
	return COLOR_WALL

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.02
		1: return 0.3
		2: return 1.4
		3: return 0.5
	return 0.0

func get_preferred_interval() -> float:
	return 0.03  # Fast — maze carving is satisfying at speed


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_stack.clear()
	_visited.clear()
	_finished = false

	# All walls
	grid.fill(0)

	# Cell grid is every other position (odd x, odd y)
	_cell_w = (width - 1) / 2
	_cell_h = (height - 1) / 2

	# Start at (1, 1)
	var start = Vector2i(1, 1)
	grid[start.y * width + start.x] = 2
	_stack.append(start)
	_visited[start] = true


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	if _finished or _stack.is_empty():
		_finished = true
		return grid

	var current = _stack[-1]
	var cur_idx = current.y * width + current.x

	# Get unvisited neighbors (2 steps away)
	var neighbors: Array[Vector2i] = []
	for dir in [Vector2i(2,0), Vector2i(-2,0), Vector2i(0,2), Vector2i(0,-2)]:
		var nx = current.x + dir.x
		var ny = current.y + dir.y
		var n = Vector2i(nx, ny)
		if nx > 0 and nx < width - 1 and ny > 0 and ny < height - 1:
			if not _visited.has(n):
				neighbors.append(n)

	if neighbors.size() > 0:
		# Pick random neighbor
		var next = neighbors[randi() % neighbors.size()]
		_visited[next] = true

		# Carve wall between current and next
		var wall_x = (current.x + next.x) / 2
		var wall_y = (current.y + next.y) / 2
		grid[wall_y * width + wall_x] = 1  # Open wall

		# Mark current as corridor, next as current head
		grid[cur_idx] = 1
		grid[next.y * width + next.x] = 2

		_stack.append(next)
	else:
		# Backtrack
		grid[cur_idx] = 3  # Show backtrack briefly
		_stack.pop_back()

		if not _stack.is_empty():
			var prev = _stack[-1]
			grid[prev.y * width + prev.x] = 2  # Re-highlight head

	return grid
