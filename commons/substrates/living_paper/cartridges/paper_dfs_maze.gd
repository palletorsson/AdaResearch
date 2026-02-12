extends PaperAlgorithm
class_name PaperDFSMaze

## DFS maze generation — watch corridors carve themselves.
## The stack backtracking is visible as the path retreats.

var _w: int  # maze width in cells (half of pixel width)
var _h: int
var _pw: int  # pixel width
var _ph: int
var _visited: Array[bool] = []
var _stack: Array[Vector2i] = []
var _wall_color: Color = Color(0.12, 0.1, 0.15)
var _path_color: Color = Color(0.1, 0.6, 0.3)
var _head_color: Color = Color(1.0, 0.8, 0.2)

func get_name() -> String:
	return "DFS Maze"

func get_background_color() -> Color:
	return _wall_color

func get_primary_color() -> Color:
	return _path_color

func get_initial_steps() -> int:
	return 30

func initialize(img: Image, width: int, height: int) -> void:
	_pw = width
	_ph = height
	_w = width / 2
	_h = height / 2
	_visited.resize(_w * _h)
	_visited.fill(false)
	_stack.clear()

	# Fill with walls
	img.fill(_wall_color)

	# Start from center
	var start = Vector2i(_w / 2, _h / 2)
	_visited[start.y * _w + start.x] = true
	_stack.append(start)
	_carve(img, start)

func step(img: Image, _step_index: int) -> bool:
	if _stack.is_empty():
		return false

	var current = _stack[-1]

	# Find unvisited neighbors
	var neighbors: Array[Vector2i] = []
	var dirs = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]
	for d in dirs:
		var n = current + d
		if n.x >= 0 and n.x < _w and n.y >= 0 and n.y < _h:
			if not _visited[n.y * _w + n.x]:
				neighbors.append(n)

	if neighbors.is_empty():
		# Backtrack — dim the current cell slightly
		var px = current.x * 2
		var py = current.y * 2
		set_pixel_safe(img, px, py, _path_color * 0.7)
		_stack.pop_back()
	else:
		# Pick random neighbor
		var next = neighbors[randi() % neighbors.size()]
		_visited[next.y * _w + next.x] = true

		# Carve passage (remove wall between current and next)
		var wall_x = current.x + next.x  # This works because cells are 2px apart
		var wall_y = current.y + next.y
		set_pixel_safe(img, wall_x, wall_y, _path_color)

		# Carve the new cell
		_carve(img, next)

		# Mark head bright
		set_pixel_safe(img, next.x * 2, next.y * 2, _head_color)
		# Dim previous head
		set_pixel_safe(img, current.x * 2, current.y * 2, _path_color)

		_stack.append(next)

	return true

func _carve(img: Image, pos: Vector2i) -> void:
	set_pixel_safe(img, pos.x * 2, pos.y * 2, _path_color)
