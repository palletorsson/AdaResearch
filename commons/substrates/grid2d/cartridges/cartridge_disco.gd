# cartridge_disco.gd
# Pure rhythm. The array as a clock — every cell advances together,
# the same color sweeps through the index space. Same composition
# repeated; the variation IS the index. F_order at its plainest.
#
# Curriculum role (array_tutorial): introduces "an array is a regular
# indexing where the position itself carries meaning." Disco sets the
# expectation that the same rule applied across an array produces
# pattern, not chaos.

class_name CartridgeDisco
extends Grid2DCartridge

## How many color states cycle.
const STATES = 8

## Hue spread across the cycle (full rainbow when 1.0).
const HUE_SPREAD = 1.0

## Saturation and value for the disco palette.
const SAT = 0.85
const VAL = 1.0


func get_name() -> String:
	return "Disco"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	var hue = fposmod(float(state) * (HUE_SPREAD / float(STATES)), 1.0)
	return Color.from_hsv(hue, SAT, VAL)


func get_state_emission(state: int) -> float:
	# Stronger glow on the leading-edge state, fading behind it.
	return 0.6 + 0.4 * sin(float(state) / float(STATES) * TAU)


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Each cell starts with state = (x + y) mod STATES — a diagonal
	# rainbow across the array. Walking the index space, you SEE the
	# index in the color.
	for y in range(height):
		for x in range(width):
			grid[y * width + x] = (x + y) % STATES


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# All cells advance one state. Pattern shifts diagonally.
	# Note: we modify and return the same buffer (O(N), no realloc).
	for i in range(grid.size()):
		grid[i] = (grid[i] + 1) % STATES
	return grid
