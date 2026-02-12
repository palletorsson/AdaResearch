class_name CartridgeGameOfLife
extends Grid2DCartridge

## Conway's Game of Life.
## B3/S23 — born with 3 neighbors, survive with 2-3.
## The canonical cellular automaton.

# --- Palette: warm amber for life, cool dark for death ---

const COLOR_DEAD = Color(0.025, 0.025, 0.03)
const COLOR_ALIVE = Color(0.95, 0.65, 0.15)       # Warm amber
const COLOR_DYING = Color(0.15, 0.25, 0.4)         # Cool blue ghost (fading trail)

# Track previous state for dying trail
var _prev_alive: PackedByteArray


func get_name() -> String:
	return "Game of Life"

func get_state_count() -> int:
	return 3  # 0=dead, 1=alive, 2=dying

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_DEAD
		1: return COLOR_ALIVE
		2: return COLOR_DYING
	return COLOR_DEAD

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.0
		1: return 0.9
		2: return 0.2
	return 0.0


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_prev_alive = PackedByteArray()
	_prev_alive.resize(width * height)
	_prev_alive.fill(0)

	# Seed: random 15% density in center region
	var cx = width / 2
	var cy = height / 2
	var radius = mini(width, height) / 3
	for y in range(height):
		for x in range(width):
			var dx = x - cx
			var dy = y - cy
			if dx * dx + dy * dy < radius * radius:
				if randf() < 0.15:
					grid[y * width + x] = 1

func get_warmup_steps() -> int:
	return 3  # A few gens so it's already active


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	var new_grid = PackedInt32Array()
	new_grid.resize(width * height)

	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var alive = grid[idx] == 1
			var neighbors = _count_alive_neighbors(grid, x, y, width, height)

			if alive:
				if neighbors == 2 or neighbors == 3:
					new_grid[idx] = 1  # Survive
				else:
					new_grid[idx] = 2  # Dying (was alive, now dead — show trail)
			else:
				if neighbors == 3:
					new_grid[idx] = 1  # Born
				elif grid[idx] == 2:
					new_grid[idx] = 0  # Dying → dead (trail fades after one gen)
				else:
					new_grid[idx] = 0  # Stay dead

	return new_grid


func _count_alive_neighbors(grid: PackedInt32Array, x: int, y: int, w: int, h: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = (x + dx + w) % w  # Wrap edges (toroidal)
			var ny = (y + dy + h) % h
			if grid[ny * w + nx] == 1:
				count += 1
	return count
