class_name CartridgeBFS
extends Grid2DCartridge

## BFS flood fill on a grid with random walls.
## States: 0=empty, 1=wall, 2=frontier, 3=visited, 4=source
## Watch the wavefront expand uniformly — BFS in action.

const COLOR_EMPTY = Color(0.025, 0.025, 0.03)
const COLOR_WALL = Color(0.12, 0.1, 0.08)
const COLOR_FRONTIER = Color(0.2, 0.7, 1.0)     # Bright blue wavefront
const COLOR_VISITED = Color(0.06, 0.18, 0.3)     # Deep blue
const COLOR_SOURCE = Color(0.95, 0.4, 0.2)       # Orange source

var _frontier: Array[Vector2i] = []
var _finished: bool = false


func get_name() -> String:
	return "BFS Flood Fill"

func get_state_count() -> int:
	return 5

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_EMPTY
		1: return COLOR_WALL
		2: return COLOR_FRONTIER
		3: return COLOR_VISITED
		4: return COLOR_SOURCE
	return COLOR_EMPTY

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.0
		1: return 0.05
		2: return 1.3    # Frontier glows bright
		3: return 0.15
		4: return 1.0
	return 0.0

func get_preferred_interval() -> float:
	return 0.06  # Fast steps to see the wave move


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_frontier.clear()
	_finished = false

	# Random walls (~25%)
	for i in range(grid.size()):
		grid[i] = 1 if randf() < 0.25 else 0

	# Source at center
	var cx = width / 2
	var cy = height / 2
	var idx = cy * width + cx
	grid[idx] = 4
	# Clear area around source
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var nx = cx + dx
			var ny = cy + dy
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				grid[ny * width + nx] = 0
	grid[idx] = 4

	# Init frontier
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = cx + dx
			var ny = cy + dy
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				if grid[ny * width + nx] == 0:
					grid[ny * width + nx] = 2
					_frontier.append(Vector2i(nx, ny))


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	if _finished or _frontier.is_empty():
		_finished = true
		return grid

	# Process current frontier, build next frontier
	var next_frontier: Array[Vector2i] = []

	for cell in _frontier:
		var idx = cell.y * width + cell.x
		grid[idx] = 3  # Frontier → visited

		# Expand to 4-connected neighbors
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nx = cell.x + dir.x
			var ny = cell.y + dir.y
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var nidx = ny * width + nx
				if grid[nidx] == 0:  # Empty → frontier
					grid[nidx] = 2
					next_frontier.append(Vector2i(nx, ny))

	_frontier = next_frontier
	return grid
