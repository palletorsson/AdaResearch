# cartridge_sieve.gd
# Sieve of Eratosthenes laid into the array. State 1 if the cell's
# row-major index is prime, 0 otherwise. Primes don't follow a
# periodic structure — the array reads as sparse and irregular, the
# opposite of disco's rhythm.
#
# Curriculum role (array_tutorial): disco/wave/count put structure
# ONTO the array; sieve reads structure OUT of the index. The same
# substrate that hosts pure rhythm also hosts deep irregularity. A
# preview of the math sequence later in the spine.
#
# QFEP: F_order substrate (the indexing) hosting an arithmetic content
# layer — primality is a property of the index itself, not of the
# cell's neighbors. The lattice still wins; the content surprises.

class_name CartridgeSieve
extends Grid2DCartridge

## Two states: 0 = composite/unit/dead, 1 = prime.
## A third "step glow" state lights up the most-recently-revealed prime
## so the sieve reads as discovering primes over time.
const STATES = 3
const DEAD = 0
const PRIME = 1
const FRESH = 2

## How many primes are pre-revealed on init (rest get unveiled during step).
const WARMUP_REVEAL = 6

var _max_index_revealed: int = -1


func get_name() -> String:
	return "Sieve"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	match state:
		PRIME:
			# Cool blue — old primes settle into a quiet revealed state.
			return Color.from_hsv(0.62, 0.55, 0.85)
		FRESH:
			# Warm yellow — newly revealed prime flashes briefly.
			return Color.from_hsv(0.12, 0.85, 1.0)
		_:
			# Composite / unit: dim background.
			return Color(0.05, 0.05, 0.07)


func get_state_emission(state: int) -> float:
	match state:
		PRIME:
			return 0.55
		FRESH:
			return 1.0
		_:
			return 0.0


func _is_prime(n: int) -> bool:
	if n < 2:
		return false
	if n < 4:
		return true
	if n % 2 == 0:
		return false
	var i = 3
	while i * i <= n:
		if n % i == 0:
			return false
		i += 2
	return true


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	# Mark every index that is prime. The result reads as a sparse,
	# self-similar starfield of primes across the index space.
	_max_index_revealed = -1
	for i in range(grid.size()):
		grid[i] = PRIME if _is_prime(i) else DEAD


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# The sieve has nothing to compute (it's already done). The step
	# instead acts like a slow scanner: each step advances a "fresh"
	# marker through the index space. Primes light up bright (FRESH)
	# as the scan crosses them, then settle to PRIME. Reads as
	# discovery proceeding over time across the array.
	var n = grid.size()
	if _max_index_revealed >= n - 1:
		# Reset: rescan from the start.
		_max_index_revealed = -1
		for i in range(n):
			if grid[i] == FRESH:
				grid[i] = PRIME
	# Decay last frame's FRESH back to PRIME.
	for i in range(n):
		if grid[i] == FRESH:
			grid[i] = PRIME
	# Advance scan by ~1/16 of the array, highlight any primes crossed.
	var step_size = max(1, int(n / 16))
	var start = _max_index_revealed + 1
	var stop = min(n, start + step_size)
	for i in range(start, stop):
		if _is_prime(i):
			grid[i] = FRESH
	_max_index_revealed = stop - 1
	return grid
