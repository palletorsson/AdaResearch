# cartridge_count.gd
# Each cell shows its own row-major index: (y * width + x) mod STATES.
# Row 0 reads 0, 1, 2, 3, ... ; row 1 picks up where row 0 ended and
# keeps counting. The DNA of the array — its enumeration — laid bare.
#
# Curriculum role (array_tutorial): this is the array introducing
# itself. Disco hides the index inside a rainbow; count makes it
# explicit. After playing with count, the player has felt what "linear
# memory laid out in 2D" really means. F_order, the most literal form.

class_name CartridgeCount
extends Grid2DCartridge

## Number of color buckets the index cycles through.
const STATES = 8

## Hue cycle — same rainbow as disco, but driven by index, not (x+y).
const HUE_SPREAD = 1.0
const SAT = 0.75
const VAL = 0.95


func get_name() -> String:
	return "Count"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	var hue = fposmod(float(state) * (HUE_SPREAD / float(STATES)), 1.0)
	return Color.from_hsv(hue, SAT, VAL)


func get_state_emission(state: int) -> float:
	# A linear ramp by state — the count sweeps brighter as it rises.
	return 0.3 + 0.5 * (float(state) / float(STATES - 1))


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Each cell IS its own index (mod STATES). Row 0: 0,1,2,...
	# Row 1: width, width+1, ... — picks up after row 0 ends.
	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			grid[y * width + x] = idx % STATES


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# The count doesn't change — it IS the array. Stepping shifts the
	# whole field by one, so the rows visibly "tick forward" like an
	# odometer. Index made visible, index in motion.
	for i in range(grid.size()):
		grid[i] = (grid[i] + 1) % STATES
	return grid
