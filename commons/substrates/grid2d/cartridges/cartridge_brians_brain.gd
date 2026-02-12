class_name CartridgeBriansBrain
extends Grid2DCartridge

## Brian's Brain — 3-state automaton.
## States: Off → On → Dying → Off
## On if exactly 2 On neighbors and currently Off.
## Creates self-sustaining oscillators and spaceships.

const COLOR_OFF = Color(0.02, 0.015, 0.025)
const COLOR_ON = Color(0.95, 0.3, 0.5)          # Hot pink
const COLOR_DYING = Color(0.25, 0.08, 0.15)     # Dark rose


func get_name() -> String:
	return "Brian's Brain"

func get_state_count() -> int:
	return 3  # 0=off, 1=on, 2=dying

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_OFF
		1: return COLOR_ON
		2: return COLOR_DYING
	return COLOR_OFF

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.0
		1: return 1.1
		2: return 0.25
	return 0.0


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Random seed: 8% on, 4% dying
	var cx = width / 2
	var cy = height / 2
	var radius = mini(width, height) / 3
	for y in range(height):
		for x in range(width):
			var dx = x - cx
			var dy = y - cy
			if dx * dx + dy * dy < radius * radius:
				var r = randf()
				if r < 0.08:
					grid[y * width + x] = 1
				elif r < 0.12:
					grid[y * width + x] = 2

func get_warmup_steps() -> int:
	return 5


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	var new_grid = PackedInt32Array()
	new_grid.resize(width * height)

	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var state = grid[idx]

			match state:
				0:  # Off
					var neighbors = _count_on(grid, x, y, width, height)
					new_grid[idx] = 1 if neighbors == 2 else 0
				1:  # On → Dying
					new_grid[idx] = 2
				2:  # Dying → Off
					new_grid[idx] = 0

	return new_grid


func _count_on(grid: PackedInt32Array, x: int, y: int, w: int, h: int) -> int:
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
