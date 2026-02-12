class_name CartridgeLangtonsAnt
extends Grid2DCartridge

## Langton's Ant — deterministic but produces emergent "highway" after ~10K steps.
## On white: turn right, flip color, move forward.
## On black: turn left, flip color, move forward.
## States: 0=white, 1=black, 2=ant_on_white, 3=ant_on_black

const COLOR_WHITE = Color(0.08, 0.08, 0.09)
const COLOR_BLACK = Color(0.6, 0.35, 0.8)         # Purple trail
const COLOR_ANT = Color(1.0, 0.2, 0.3)            # Red ant

var _ant_x: int = 0
var _ant_y: int = 0
var _ant_dir: int = 0  # 0=up, 1=right, 2=down, 3=left
const DIRS = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


func get_name() -> String:
	return "Langton's Ant"

func get_state_count() -> int:
	return 4

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_WHITE
		1: return COLOR_BLACK
		2: return COLOR_ANT
		3: return COLOR_ANT
	return COLOR_WHITE

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.03
		1: return 0.4
		2: return 1.5
		3: return 1.5
	return 0.0

func get_preferred_interval() -> float:
	return 0.01  # Very fast — ant needs thousands of steps

func get_warmup_steps() -> int:
	return 200  # Pre-run so there's already a pattern


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	grid.fill(0)
	_ant_x = width / 2
	_ant_y = height / 2
	_ant_dir = 0
	grid[_ant_y * width + _ant_x] = 2  # Ant on white


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# Multiple ant steps per frame (it's slow otherwise)
	var steps_per_frame = 8
	for _i in range(steps_per_frame):
		_single_step(grid, width, height)
	return grid


func _single_step(grid: PackedInt32Array, width: int, height: int) -> void:
	var idx = _ant_y * width + _ant_x
	var cell_state = grid[idx]
	var is_black = (cell_state == 1 or cell_state == 3)

	if is_black:
		# On black: turn left, flip to white
		_ant_dir = (_ant_dir + 3) % 4
		grid[idx] = 0
	else:
		# On white: turn right, flip to black
		_ant_dir = (_ant_dir + 1) % 4
		grid[idx] = 1

	# Move forward (wrap)
	_ant_x = (_ant_x + DIRS[_ant_dir].x + width) % width
	_ant_y = (_ant_y + DIRS[_ant_dir].y + height) % height

	# Mark new position
	var new_idx = _ant_y * width + _ant_x
	var on_black = (grid[new_idx] == 1)
	grid[new_idx] = 3 if on_black else 2
