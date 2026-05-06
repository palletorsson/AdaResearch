class_name CartridgeMergeSort
extends BarArrayCartridge

## Merge Sort — iterative bottom-up. Split, sort halves, merge.
## O(n log n) always. Stable. The "divide and conquer" sort.
## Colors: merging_left=cyan, merging_right=orange, merged=green.

var _width: int = 1         # current merge width (1, 2, 4, 8, ...)
var _start: int = 0         # start of current merge pair
var _merge_pos: int = 0     # position within current merge operation
var _left: PackedFloat32Array   # left half buffer
var _right: PackedFloat32Array  # right half buffer
var _li: int = 0            # left index
var _ri: int = 0            # right index
var _merging: bool = false  # currently inside a merge
var _done: bool = false

func get_name() -> String:
	return "Merge Sort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if _done:
		return Color(0.2, 0.85, 0.3)
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

func initialize(size: int) -> PackedFloat32Array:
	_width = 1
	_start = 0
	_merge_pos = 0
	_merging = false
	_done = false
	_left = PackedFloat32Array()
	_right = PackedFloat32Array()
	_li = 0
	_ri = 0
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	var n = arr.size()
	var comparisons = []
	var highlights = {}

	if not _merging:
		# Find next merge pair
		if _start >= n:
			# Done with this width level
			_width *= 2
			_start = 0
			if _width >= n:
				_done = true
				return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

		var mid = mini(_start + _width, n)
		var end = mini(_start + _width * 2, n)

		if mid >= end:
			# Nothing to merge, skip
			_start += _width * 2
			return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": false, "description": "Width %d" % _width}

		# Copy halves
		_left = PackedFloat32Array()
		for i in range(_start, mid):
			_left.append(arr[i])
		_right = PackedFloat32Array()
		for i in range(mid, end):
			_right.append(arr[i])

		_li = 0
		_ri = 0
		_merge_pos = _start
		_merging = true

	# Merge one element
	if _li < _left.size() and _ri < _right.size():
		comparisons.append([_start + _li, _start + _left.size() + _ri])
		if _left[_li] <= _right[_ri]:
			arr[_merge_pos] = _left[_li]
			highlights[_merge_pos] = Color(0.2, 0.9, 0.95)  # cyan: from left
			_li += 1
		else:
			arr[_merge_pos] = _right[_ri]
			highlights[_merge_pos] = Color(1.0, 0.6, 0.2)  # orange: from right
			_ri += 1
	elif _li < _left.size():
		arr[_merge_pos] = _left[_li]
		highlights[_merge_pos] = Color(0.2, 0.9, 0.95)
		_li += 1
	elif _ri < _right.size():
		arr[_merge_pos] = _right[_ri]
		highlights[_merge_pos] = Color(1.0, 0.6, 0.2)
		_ri += 1

	_merge_pos += 1

	# Check if merge is complete
	if _li >= _left.size() and _ri >= _right.size():
		_merging = false
		_start += _width * 2

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": [],
		"highlights": highlights,
		"done": false,
		"description": "Merging width %d at [%d]" % [_width, _start]
	}
