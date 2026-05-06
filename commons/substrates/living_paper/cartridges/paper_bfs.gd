extends PaperAlgorithm
class_name PaperBFS

## BFS flood fill from center — color expanding through a maze.
## Walls are random, frontier is bright, visited fades.

var _w: int
var _h: int
var _grid: Array[int] = []  # 0=empty, 1=wall, 2=visited, 3=frontier
var _frontier: Array[Vector2i] = []
var _wall_color: Color = Color(0.15, 0.12, 0.1)
var _visit_color: Color = Color(0.1, 0.2, 0.4)
var _frontier_color: Color = Color(0.3, 0.9, 1.0)
var _cells_per_step: int = 8

func get_name() -> String:
	return "BFS Flood Fill"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_primary_color() -> Color:
	return _frontier_color

func get_initial_steps() -> int:
	return 15

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_grid.resize(width * height)
	_grid.fill(0)
	_frontier.clear()

	# Generate random walls (~25%)
	for i in range(width * height):
		if randf() < 0.25:
			_grid[i] = 1
			var x = i % width
			var y = i / width
			set_pixel_safe(img, x, y, _wall_color)

	# Start BFS from center
	var cx = width / 2
	var cy = height / 2
	# Clear center area
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var idx = (cy + dy) * width + (cx + dx)
			if idx >= 0 and idx < _grid.size():
				_grid[idx] = 3  # frontier
				_frontier.append(Vector2i(cx + dx, cy + dy))
				set_pixel_safe(img, cx + dx, cy + dy, _frontier_color)

func step(img: Image, _step_index: int) -> bool:
	if _frontier.is_empty():
		return false

	var next_frontier: Array[Vector2i] = []
	var steps = min(_cells_per_step, _frontier.size())

	for i in range(steps):
		if _frontier.is_empty():
			break
		var pos = _frontier.pop_front()

		# Mark as visited
		var idx = pos.y * _w + pos.x
		_grid[idx] = 2

		# Distance-based color — further from center = deeper blue
		var dist = Vector2(pos).distance_to(Vector2(_w / 2.0, _h / 2.0))
		var t = clampf(dist / float(min(_w, _h) / 2), 0.0, 1.0)
		var visited_c = Color(
			0.05 + 0.15 * (1.0 - t),
			0.1 + 0.3 * t,
			0.3 + 0.4 * t
		)
		set_pixel_safe(img, pos.x, pos.y, visited_c)

		# Expand to neighbors
		var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		for d in dirs:
			var np = pos + d
			if np.x < 0 or np.x >= _w or np.y < 0 or np.y >= _h:
				continue
			var nidx = np.y * _w + np.x
			if _grid[nidx] == 0:  # empty, not visited
				_grid[nidx] = 3
				next_frontier.append(np)
				set_pixel_safe(img, np.x, np.y, _frontier_color)

	_frontier.append_array(next_frontier)
	return true
