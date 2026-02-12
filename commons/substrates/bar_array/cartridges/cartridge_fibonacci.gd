class_name CartridgeFibonacci
extends BarArrayCartridge

## Fibonacci Sequence — each bar = F(n), growing exponentially.
## NOT sorting. Builds the sequence bar by bar.
## Colors: golden ratio gradient (warm amber).

var _current: int = 2  # next bar to fill
var _done: bool = false

func get_name() -> String:
	return "Fibonacci"

func get_category() -> String:
	return "mathematical"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if index >= _current and not _done:
		return Color(0.1, 0.1, 0.12)  # unfilled: dark
	# Golden amber gradient
	var t = float(index) / float(maxi(total - 1, 1))
	return Color(0.9 + t * 0.1, 0.6 - t * 0.2, 0.1 + t * 0.1)

func get_preferred_size() -> int:
	return 24  # 24 bars shows nice exponential growth

func get_preferred_interval() -> float:
	return 0.15  # slower — let each bar land

func initialize(size: int) -> PackedFloat32Array:
	_current = 2
	_done = false
	var arr = PackedFloat32Array()
	arr.resize(size)
	arr.fill(0.0)
	# F(0)=1, F(1)=1 (normalized later)
	arr[0] = 1.0
	arr[1] = 1.0
	return arr

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done or _current >= arr.size():
		_done = true
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Fibonacci complete"}

	# Compute next Fibonacci (in unnormalized space)
	# We store raw values, then normalize to 0–1 each step
	var raw = PackedFloat32Array()
	raw.resize(arr.size())

	# Reconstruct raw values from normalized
	# Actually, let's track raw values internally
	# Simpler: just track that arr stores normalized values
	# and we compute fibonacci raw, then normalize

	# Use a different approach: store actual fib values, normalize each frame
	# Fibonacci values grow fast, so normalize by the current max
	var fib_a = 1.0
	var fib_b = 1.0
	raw[0] = 1.0
	raw[1] = 1.0
	for i in range(2, _current + 1):
		var next = fib_a + fib_b
		raw[i] = next
		fib_a = fib_b
		fib_b = next

	_current += 1

	# Normalize by max value
	var max_val = raw[_current - 1]
	for i in range(arr.size()):
		if i < _current:
			arr[i] = raw[i] / max_val
		else:
			arr[i] = 0.0

	var highlights = {}
	highlights[_current - 1] = Color(1.0, 0.9, 0.3)  # flash new bar

	return {
		"array": arr,
		"comparisons": [[_current - 2, _current - 3]] if _current >= 3 else [],
		"swaps": [],
		"highlights": highlights,
		"done": false,
		"description": "F(%d) = %.0f" % [_current - 1, raw[_current - 1]]
	}

func is_complete(arr: PackedFloat32Array) -> bool:
	return _done
