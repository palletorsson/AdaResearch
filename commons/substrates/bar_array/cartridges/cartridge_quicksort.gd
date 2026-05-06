class_name CartridgeQuicksort
extends BarArrayCartridge

## Quicksort — iterative with explicit stack. Pivot, partition, recurse.
## O(n log n) average, O(n²) worst. The practical fast sort.
## Colors: pivot=magenta, partitioning=yellow, done=green.

var _stack: Array = []  # Stack of [low, high] ranges to sort
var _low: int = 0
var _high: int = 0
var _pivot_idx: int = 0
var _scan_left: int = 0
var _partitioning: bool = false
var _done: bool = false

func get_name() -> String:
	return "Quicksort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if _done:
		return Color(0.2, 0.85, 0.3)
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

func initialize(size: int) -> PackedFloat32Array:
	_stack = [[0, size - 1]]
	_partitioning = false
	_done = false
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	var comparisons = []
	var swaps = []
	var highlights = {}

	if not _partitioning:
		# Pop next range from stack
		if _stack.is_empty():
			_done = true
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

		var range_pair = _stack.pop_back()
		_low = range_pair[0]
		_high = range_pair[1]

		if _low >= _high:
			# Single element or empty — already sorted
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": false, "description": "Skipping range [%d, %d]" % [_low, _high]}

		# Choose pivot: median of three (low, mid, high)
		var mid = (_low + _high) / 2
		# Sort low/mid/high to get median
		if arr[_low] > arr[mid]:
			var tmp = arr[_low]; arr[_low] = arr[mid]; arr[mid] = tmp
		if arr[_low] > arr[_high]:
			var tmp = arr[_low]; arr[_low] = arr[_high]; arr[_high] = tmp
		if arr[mid] > arr[_high]:
			var tmp = arr[mid]; arr[mid] = arr[_high]; arr[_high] = tmp
		# Put pivot at high-1 (or high for small ranges)
		if _high - _low > 2:
			var tmp = arr[mid]; arr[mid] = arr[_high - 1]; arr[_high - 1] = tmp
			_pivot_idx = _high - 1
		else:
			_pivot_idx = _high

		_scan_left = _low
		_partitioning = true

	# Partition: scan left to right, swap elements smaller than pivot to front
	if _scan_left < _pivot_idx:
		var pivot_val = arr[_pivot_idx]
		comparisons.append([_scan_left, _pivot_idx])
		highlights[_pivot_idx] = Color(0.9, 0.2, 0.8)  # magenta: pivot

		if arr[_scan_left] > pivot_val:
			# Leave it — it's on the correct side (will be right of pivot)
			pass
		_scan_left += 1
	else:
		# Partition complete — use Lomuto scheme for simplicity
		# Re-do partition properly with Lomuto
		_partitioning = false
		var pivot_val = arr[_pivot_idx]
		var store_idx = _low

		for i in range(_low, _pivot_idx):
			if arr[i] <= pivot_val:
				if i != store_idx:
					var tmp = arr[i]; arr[i] = arr[store_idx]; arr[store_idx] = tmp
				store_idx += 1

		# Move pivot to its final position
		if store_idx != _pivot_idx:
			var tmp = arr[store_idx]; arr[store_idx] = arr[_pivot_idx]; arr[_pivot_idx] = tmp
			swaps.append([store_idx, _pivot_idx])

		highlights[store_idx] = Color(0.9, 0.2, 0.8)  # pivot in final position

		# Push sub-ranges onto stack
		if store_idx - 1 > _low:
			_stack.append([_low, store_idx - 1])
		if store_idx + 1 < _high:
			_stack.append([store_idx + 1, _high])

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": swaps,
		"highlights": highlights,
		"done": false,
		"description": "Partitioning [%d, %d]" % [_low, _high]
	}
