# cartridge_slow.gd
# Same array, slower cadence. The disco rhythm dilated. By placing this
# substrate next to the disco one, the player feels TIME — the array
# rule is identical; only the step interval differs (set in map config).
# The lesson: rhythm = rule + tempo, two separable knobs.
#
# Curriculum role (array_tutorial): timing is parameter, not law. Same
# F_order rule as disco; the array reads as different *because the rate
# changes the felt experience*. Prepares the array_tutorial for the
# eventual handoff to the wavefunctions / oscillation sequence.

class_name CartridgeSlow
extends Grid2DCartridge

const STATES = 8

# A muted, contemplative palette — same hue cycle as disco but desaturated.
const SAT = 0.4
const VAL = 0.7


func get_name() -> String:
	return "Slow"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	var hue = fposmod(float(state) * (1.0 / float(STATES)), 1.0)
	return Color.from_hsv(hue, SAT, VAL)


func get_state_emission(state: int) -> float:
	# Soft, even glow — no leading edge, no urgency.
	return 0.45


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Same diagonal init as disco — same rule, side-by-side comparison.
	for y in range(height):
		for x in range(width):
			grid[y * width + x] = (x + y) % STATES


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	for i in range(grid.size()):
		grid[i] = (grid[i] + 1) % STATES
	return grid
