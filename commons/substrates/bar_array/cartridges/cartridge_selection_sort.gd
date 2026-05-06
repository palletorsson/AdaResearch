class_name CartridgeSelectionSort
extends BarArrayCartridge

## Selection Sort — find minimum in unsorted region, swap to front.
## O(n²) always. Simple but inefficient. Minimum swaps though.
## Colors: current_min=magenta, scanning=yellow, sorted=green.

var _sorted_end: int = 0  # everything before this is sorted
var _scan_pos: int = 0    # current scan position
var _min_idx: int = 0     # index of current minimum
var _done: bool = false

func get_name() -> String:
	return "Selection Sort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if _done:
		return Color(0.2, 0.85, 0.3)
	if index < _sorted_end:
		return Color(0.2, 0.85, 0.3)  # sorted: green
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

func initialize(size: int) -> PackedFloat32Array:
	_sorted_end = 0
	_scan_pos = 0
	_min_idx = 0
	_done = false
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done or _sorted_end >= arr.size() - 1:
		_done = true
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	var comparisons = []
	var swaps = []
	var highlights = {}

	if _scan_pos == _sorted_end:
		# Start new scan: minimum begins at sorted_end
		_min_idx = _sorted_end
		_scan_pos = _sorted_end + 1

	if _scan_pos < arr.size():
		# Compare current with minimum
		comparisons.append([_scan_pos, _min_idx])
		highlights[_min_idx] = Color(0.9, 0.2, 0.8)  # magenta: current min

		if arr[_scan_pos] < arr[_min_idx]:
			_min_idx = _scan_pos
			highlights[_min_idx] = Color(0.9, 0.2, 0.8)

		_scan_pos += 1
	else:
		# Scan complete — swap minimum into sorted position
		if _min_idx != _sorted_end:
			var tmp = arr[_sorted_end]
			arr[_sorted_end] = arr[_min_idx]
			arr[_min_idx] = tmp
			swaps.append([_sorted_end, _min_idx])

		_sorted_end += 1
		_scan_pos = _sorted_end

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": swaps,
		"highlights": highlights,
		"done": false,
		"description": "Finding minimum for position %d" % _sorted_end
	}
