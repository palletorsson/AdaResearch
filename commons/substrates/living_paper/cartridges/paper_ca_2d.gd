extends PaperAlgorithm
class_name PaperCA2D

## 2D Cellular Automata on paper — Game of Life, Seeds, Brian's Brain.

enum Ruleset { LIFE, SEEDS, BRIANS_BRAIN }

var ruleset: Ruleset = Ruleset.LIFE
var _grid: Array = []  # 2D array of ints
var _w: int
var _h: int
var _colors: Array[Color]

func _init(rs: Ruleset = Ruleset.LIFE) -> void:
	ruleset = rs

func get_name() -> String:
	match ruleset:
		Ruleset.LIFE: return "Game of Life"
		Ruleset.SEEDS: return "Seeds"
		Ruleset.BRIANS_BRAIN: return "Brian's Brain"
	return "CA 2D"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.05)

func get_primary_color() -> Color:
	match ruleset:
		Ruleset.LIFE: return Color(0.2, 1.0, 0.3)
		Ruleset.SEEDS: return Color(1.0, 0.9, 0.2)
		Ruleset.BRIANS_BRAIN: return Color(0.3, 0.6, 1.0)
	return Color.WHITE

func get_initial_steps() -> int:
	return 10

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height

	match ruleset:
		Ruleset.LIFE:
			_colors = [get_background_color(), Color(0.2, 1.0, 0.3)]
		Ruleset.SEEDS:
			_colors = [get_background_color(), Color(1.0, 0.9, 0.2)]
		Ruleset.BRIANS_BRAIN:
			_colors = [get_background_color(), Color(0.3, 0.6, 1.0), Color(0.6, 0.3, 0.15)]

	# Init grid with random seed in center region
	_grid.clear()
	for y in range(height):
		var row: Array[int] = []
		row.resize(width)
		row.fill(0)
		_grid.append(row)

	# Seed central 30% with ~30% density
	var margin_x = int(width * 0.35)
	var margin_y = int(height * 0.35)
	for y in range(margin_y, height - margin_y):
		for x in range(margin_x, width - margin_x):
			if randf() < 0.3:
				_grid[y][x] = 1

	_render(img)

func step(img: Image, _step_index: int) -> bool:
	var new_grid: Array = []
	for y in range(_h):
		var row: Array[int] = []
		row.resize(_w)
		row.fill(0)
		new_grid.append(row)

	for y in range(_h):
		for x in range(_w):
			var neighbors = _count_neighbors(x, y, 1)
			var state = _grid[y][x]

			match ruleset:
				Ruleset.LIFE:
					if state == 1:
						new_grid[y][x] = 1 if neighbors in [2, 3] else 0
					else:
						new_grid[y][x] = 1 if neighbors == 3 else 0

				Ruleset.SEEDS:
					if state == 0:
						new_grid[y][x] = 1 if neighbors == 2 else 0
					else:
						new_grid[y][x] = 0

				Ruleset.BRIANS_BRAIN:
					if state == 0:
						new_grid[y][x] = 1 if neighbors == 2 else 0
					elif state == 1:
						new_grid[y][x] = 2  # dying
					else:
						new_grid[y][x] = 0  # dead

	_grid = new_grid
	_render(img)
	return true

func _count_neighbors(cx: int, cy: int, target_state: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = (cx + dx + _w) % _w
			var ny = (cy + dy + _h) % _h
			if _grid[ny][nx] == target_state:
				count += 1
	return count

func _render(img: Image) -> void:
	for y in range(_h):
		for x in range(_w):
			var state = _grid[y][x]
			var c = _colors[state] if state < _colors.size() else get_background_color()
			set_pixel_safe(img, x, y, c)
