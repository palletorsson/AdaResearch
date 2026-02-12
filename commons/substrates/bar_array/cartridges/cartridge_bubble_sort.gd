class_name CartridgeBubbleSort
extends BarArrayCartridge

## Bubble Sort — adjacent comparisons, largest bubbles to the end.
## O(n²) average/worst. The canonical "bad sort" that everyone learns first.
## Colors: comparing=yellow, swapping=white flash, sorted=green.

var _cursor: int = 0
var _end: int = 0  # unsorted boundary (shrinks each pass)
var _sorted_from: int = 0  # everything >= this index is sorted
var _swapped_this_pass: bool = false

func get_name() -> String:
	return "Bubble Sort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if index >= _sorted_from and _sorted_from > 0:
		# Sorted region: green tint
		return Color(0.2, 0.85, 0.3)
	# Unsorted: height-mapped gradient
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

func initialize(size: int) -> PackedFloat32Array:
	_cursor = 0
	_end = size - 1
	_sorted_from = size  # nothing sorted yet
	_swapped_this_pass = false
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	var comparisons = []
	var swaps = []

	if _cursor >= _end:
		# End of pass
		if not _swapped_this_pass:
			# No swaps this pass — array is sorted
			_sorted_from = 0
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

		_sorted_from = _end + 1
		_end -= 1
		_cursor = 0
		_swapped_this_pass = false

		if _end <= 0:
			_sorted_from = 0
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	# Compare adjacent pair
	comparisons.append([_cursor, _cursor + 1])

	if arr[_cursor] > arr[_cursor + 1]:
		# Swap
		var tmp = arr[_cursor]
		arr[_cursor] = arr[_cursor + 1]
		arr[_cursor + 1] = tmp
		swaps.append([_cursor, _cursor + 1])
		_swapped_this_pass = true

	_cursor += 1

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": swaps,
		"highlights": {},
		"done": false,
		"description": "Pass %d, comparing [%d, %d]" % [arr.size() - _end, _cursor - 1, _cursor]
	}
