class_name CartridgePrimeSieve
extends BarArrayCartridge

## Sieve of Eratosthenes — bars go dark when eliminated.
## NOT sorting. Progressively eliminates composite numbers.
## Colors: prime=bright cyan, composite=dim, currently_sieving=red.

var _current_prime: int = 2  # current number we're sieving with
var _sieve_pos: int = 0      # current multiple being eliminated
var _is_prime: PackedInt32Array  # 1=prime candidate, 0=composite
var _done: bool = false

func get_name() -> String:
	return "Sieve of Eratosthenes"

func get_category() -> String:
	return "mathematical"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if index < 2:
		return Color(0.08, 0.08, 0.1)  # 0 and 1: not prime, dark
	if _is_prime.size() > index and _is_prime[index] == 0:
		return Color(0.08, 0.08, 0.1)  # composite: dark
	# Prime candidate: bright cyan
	return Color(0.2, 0.85, 0.95)

func get_preferred_size() -> int:
	return 50  # show primes up to 50

func get_preferred_interval() -> float:
	return 0.06

func initialize(size: int) -> PackedFloat32Array:
	_current_prime = 2
	_sieve_pos = 0
	_done = false

	_is_prime = PackedInt32Array()
	_is_prime.resize(size)
	_is_prime.fill(1)
	if size > 0:
		_is_prime[0] = 0
	if size > 1:
		_is_prime[1] = 0

	# Bar height = proportional to the number itself (linear ramp)
	var arr = PackedFloat32Array()
	arr.resize(size)
	for i in range(size):
		arr[i] = float(i) / float(maxi(size - 1, 1))
	return arr

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sieve complete"}

	var n = arr.size()
	var highlights = {}

	# Find next prime to sieve with
	if _sieve_pos == 0:
		# Starting new prime
		while _current_prime < n and _is_prime[_current_prime] == 0:
			_current_prime += 1

		if _current_prime >= n or _current_prime * _current_prime >= n:
			_done = true
			# Update bar heights: composites go to zero
			for i in range(n):
				if _is_prime[i] == 0:
					arr[i] = 0.0
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sieve complete — %d primes found" % _count_primes()}

		_sieve_pos = _current_prime * 2  # first multiple
		highlights[_current_prime] = Color(0.95, 0.2, 0.2)  # red: current sieve prime

	# Eliminate one multiple
	if _sieve_pos < n:
		_is_prime[_sieve_pos] = 0
		arr[_sieve_pos] = 0.0  # bar goes to zero
		highlights[_sieve_pos] = Color(0.5, 0.1, 0.1)  # dark red: eliminated
		highlights[_current_prime] = Color(0.95, 0.2, 0.2)  # red: sieving prime
		_sieve_pos += _current_prime
	else:
		# Done with this prime, move to next
		_current_prime += 1
		_sieve_pos = 0

	return {
		"array": arr,
		"comparisons": [],
		"swaps": [],
		"highlights": highlights,
		"done": false,
		"description": "Sieving multiples of %d" % _current_prime
	}

func _count_primes() -> int:
	var count = 0
	for i in range(_is_prime.size()):
		if _is_prime[i] == 1:
			count += 1
	return count

func is_complete(arr: PackedFloat32Array) -> bool:
	return _done
