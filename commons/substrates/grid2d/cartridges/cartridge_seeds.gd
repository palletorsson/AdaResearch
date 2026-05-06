class_name CartridgeSeeds
extends Grid2DCartridge

## Seeds — B2/S (born with exactly 2 neighbors, never survives).
## Explosive, ephemeral. Every cell lives for exactly one generation.
## Creates expanding diamond/snowflake patterns from minimal seeds.

const COLOR_DEAD = Color(0.02, 0.02, 0.025)
const COLOR_ALIVE = Color(0.3, 0.85, 0.95)   # Electric cyan
const COLOR_TRAIL = Color(0.05, 0.12, 0.18)   # Dark cyan ghost


func get_name() -> String:
	return "Seeds"

func get_state_count() -> int:
	return 3

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_DEAD
		1: return COLOR_ALIVE
		2: return COLOR_TRAIL
	return COLOR_DEAD

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.0
		1: return 1.2
		2: return 0.1
	return 0.0


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Single seed point — watch it explode
	var cx = width / 2
	var cy = height / 2
	grid[cy * width + cx] = 1
	grid[cy * width + cx + 1] = 1
	grid[(cy + 1) * width + cx] = 1


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	var new_grid = PackedInt32Array()
	new_grid.resize(width * height)

	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var neighbors = _count_alive(grid, x, y, width, height)

			if grid[idx] == 1:
				# All alive cells die (Seeds rule: no survival)
				new_grid[idx] = 2  # Trail
			elif grid[idx] == 0 or grid[idx] == 2:
				if neighbors == 2:
					new_grid[idx] = 1  # Born
				elif grid[idx] == 2:
					new_grid[idx] = 0  # Trail fades
				else:
					new_grid[idx] = 0

	return new_grid


func _count_alive(grid: PackedInt32Array, x: int, y: int, w: int, h: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = (x + dx + w) % w
			var ny = (y + dy + h) % h
			if grid[ny * w + nx] == 1:
				count += 1
	return count
