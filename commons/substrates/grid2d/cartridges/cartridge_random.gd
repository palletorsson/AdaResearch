# cartridge_random.gd
# The same indexing — but the step rule is sampled, not advanced. The
# array still HAS positions, but the values at those positions are
# unrelated to anything else. F_order's structure persists; E_entropy
# fills the cells.
#
# Curriculum role: a preview of what the randomness sequence will do
# in depth. Place this next to disco/slow in the array plaza so the
# player feels the contrast — same physical array, totally different
# legibility. Teaches: the array is the SUBSTRATE; what fills it is a
# separate decision. (Substrates are reusable; cartridges are choices.)

class_name CartridgeRandom
extends Grid2DCartridge

const STATES = 8

const SAT = 0.7
const VAL = 0.95


func get_name() -> String:
	return "Random"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	var hue = fposmod(float(state) * (1.0 / float(STATES)), 1.0)
	return Color.from_hsv(hue, SAT, VAL)


func get_state_emission(state: int) -> float:
	# Slightly punchier than slow — random reads as alive, but not
	# rhythmic — so the glow is uniform and bright.
	return 0.7


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Random initial state — every cell rolls its own.
	for i in range(grid.size()):
		grid[i] = randi() % STATES


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# Each step, every cell rerolls. No history, no neighbor reads.
	# This is the "antithesis" cartridge — same hardware, no memory.
	for i in range(grid.size()):
		grid[i] = randi() % STATES
	return grid
