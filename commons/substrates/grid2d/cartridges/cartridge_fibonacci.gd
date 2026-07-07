# cartridge_fibonacci.gd
# Each cell's value is fib(index) mod K — the Fibonacci sequence laid
# along row-major order, then quantized. Because Fibonacci numbers
# mod K are eventually periodic (Pisano period π(K)), the array
# reads as a repeating but non-trivial band pattern. Different K
# gives different Pisano period, hence different visible rhythm.
#
# Curriculum role (array_tutorial): a third F_order rule, distinct
# from disco/count/wave. The structure exists, but the pattern's
# period isn't obvious from the rule — π(K) is its own little
# arithmetic mystery. Teaches: arrays carry whatever you put on them;
# some rules carry hidden structure.
#
# QFEP: F_order — the index-period-bands are deterministic and
# repeatable — but with a wink at the unexpected. Pisano periods
# are nice computer-science folklore the curious player can chase
# from here into number theory.

class_name CartridgeFibonacci
extends Grid2DCartridge

## Modulus — number of distinct visible classes. Pisano period π(K):
## K=8 → π=12, K=16 → π=24. Either reads cleanly. We use 8 for crisp
## band visibility on small arrays.
const STATES = 8

const HUE_SPREAD = 1.0
const SAT = 0.7
const VAL = 0.92

# Internal offset, advanced each step so the bands drift along the
# array like a moving spectrum.
var _offset: int = 0


func get_name() -> String:
	return "Fibonacci"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	# Map Fibonacci-mod-K classes to a circular palette. Same hue cycle
	# as disco — to make explicit that the cells are the same kind of
	# states; only the rule that picks them is different.
	var hue = fposmod(float(state) * (HUE_SPREAD / float(STATES)), 1.0)
	return Color.from_hsv(hue, SAT, VAL)


func get_state_emission(state: int) -> float:
	# Slight emphasis on higher-index classes so the bands "ring."
	return 0.4 + 0.4 * (float(state) / float(STATES - 1))


func _fib_mod(n: int, k: int) -> int:
	# Iterative — no need to memoize for grid sizes we render.
	if n == 0:
		return 0
	var a = 0
	var b = 1
	for _i in range(n - 1):
		var c = (a + b) % k
		a = b
		b = c
	return b


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_offset = 0
	for i in range(grid.size()):
		grid[i] = _fib_mod(i, STATES)


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# Each step, slide the sequence's starting index by 1 — the bands
	# drift along the array as if the Pisano period were scrolling
	# across the index space.
	_offset += 1
	for i in range(grid.size()):
		grid[i] = _fib_mod(i + _offset, STATES)
	return grid
