class_name CartridgeWireworld
extends Grid2DCartridge

## Wireworld — 4-state CA for simulating digital circuits.
## States: 0=empty, 1=wire, 2=electron_head, 3=electron_tail
## Head → Tail → Wire. Wire → Head if 1 or 2 head neighbors.
## Build logic gates, clocks, diodes from simple rules.

const COLOR_EMPTY = Color(0.015, 0.015, 0.02)
const COLOR_WIRE = Color(0.25, 0.2, 0.1)          # Copper wire
const COLOR_HEAD = Color(0.2, 0.6, 1.0)           # Electric blue
const COLOR_TAIL = Color(0.9, 0.4, 0.15)          # Orange afterglow


func get_name() -> String:
	return "Wireworld"

func get_state_count() -> int:
	return 4

func get_state_color(state: int) -> Color:
	match state:
		0: return COLOR_EMPTY
		1: return COLOR_WIRE
		2: return COLOR_HEAD
		3: return COLOR_TAIL
	return COLOR_EMPTY

func get_state_emission(state: int) -> float:
	match state:
		0: return 0.0
		1: return 0.25   # Wire glow — visible copper trace
		2: return 1.4    # Electron head — bright flash
		3: return 0.7    # Electron tail — orange afterglow
	return 0.0


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Build a circuit with loops and a diode — Wireworld showcase
	var cx = width / 2
	var cy = height / 2
	var s = mini(width, height) / 6  # Loop half-size

	# Main rectangular loop (wire)
	for x in range(cx - s, cx + s + 1):
		grid[(cy - s) * width + x] = 1  # Top
		grid[(cy + s) * width + x] = 1  # Bottom
	for y in range(cy - s, cy + s + 1):
		grid[y * width + (cx - s)] = 1  # Left
		grid[y * width + (cx + s)] = 1  # Right

	# Second smaller loop branching right (creates interesting interaction)
	var s2 = s / 2
	var ox = cx + s + s2  # Offset right
	if ox + s2 < width:
		for x in range(cx + s, ox + s2 + 1):
			grid[(cy - s2) * width + x] = 1  # Top branch
			grid[(cy + s2) * width + x] = 1  # Bottom branch
		for y in range(cy - s2, cy + s2 + 1):
			grid[y * width + (ox + s2)] = 1  # Right wall

	# Place electrons — two on the main loop for activity
	grid[(cy - s) * width + cx] = 2          # Head 1
	grid[(cy - s) * width + cx - 1] = 3      # Tail 1
	grid[(cy + s) * width + cx + 2] = 2      # Head 2
	grid[(cy + s) * width + cx + 1] = 3      # Tail 2


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	var new_grid = PackedInt32Array()
	new_grid.resize(width * height)

	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			match grid[idx]:
				0:  # Empty stays empty
					new_grid[idx] = 0
				1:  # Wire → Head if 1 or 2 head neighbors
					var heads = _count_heads(grid, x, y, width, height)
					new_grid[idx] = 2 if (heads == 1 or heads == 2) else 1
				2:  # Head → Tail
					new_grid[idx] = 3
				3:  # Tail → Wire
					new_grid[idx] = 1

	return new_grid


func on_cell_touch(grid: PackedInt32Array, x: int, y: int, width: int, height: int) -> PackedInt32Array:
	var idx = y * width + x
	# Cycle: empty → wire → head → tail → empty
	grid[idx] = (grid[idx] + 1) % 4
	return grid


func _count_heads(grid: PackedInt32Array, x: int, y: int, w: int, h: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = (x + dx + w) % w
			var ny = (y + dy + h) % h
			if grid[ny * w + nx] == 2:
				count += 1
	return count
