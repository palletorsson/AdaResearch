class_name CartridgeRule1D
extends Grid2DCartridge

## Wolfram elementary 1D cellular automaton.
## Draws row by row, scrolling down. Each row = one generation.
## Supports any rule 0-255 (Rule 30, 110, 90, etc.)

var rule_number: int = 30
var _current_row: int = 0

const COLOR_OFF = Color(0.02, 0.02, 0.025)
const COLOR_ON = Color(1.0, 0.85, 0.35)  # Warm gold


func _init(rule: int = 30) -> void:
	rule_number = rule

func get_name() -> String:
	return "Rule %d" % rule_number

func get_state_count() -> int:
	return 2

func get_state_color(state: int) -> Color:
	return COLOR_ON if state == 1 else COLOR_OFF

func get_state_emission(state: int) -> float:
	return 0.9 if state == 1 else 0.0

func get_preferred_height() -> int:
	return 64  # Taller to show more history


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_current_row = 0
	# Single cell at top center
	grid[width / 2] = 1


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	_current_row += 1
	if _current_row >= height:
		# Scroll: shift everything up one row
		for y in range(height - 1):
			for x in range(width):
				grid[y * width + x] = grid[(y + 1) * width + x]
		_current_row = height - 1
		# Clear bottom row
		for x in range(width):
			grid[_current_row * width + x] = 0

	# Compute new row from previous row
	var prev_row = _current_row - 1
	for x in range(width):
		var left = grid[prev_row * width + ((x - 1 + width) % width)]
		var center = grid[prev_row * width + x]
		var right = grid[prev_row * width + ((x + 1) % width)]

		var neighborhood = (left << 2) | (center << 1) | right  # 0-7
		var new_state = (rule_number >> neighborhood) & 1
		grid[_current_row * width + x] = new_state

	return grid

func get_warmup_steps() -> int:
	return 20  # Pre-fill some rows so it's not almost empty
