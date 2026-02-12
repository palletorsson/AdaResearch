class_name CartridgeInsertionSort
extends BarArrayCartridge

## Insertion Sort — slides each element into its sorted position.
## O(n²) worst, O(n) best (already sorted). The "card player" sort.
## Colors: inserting=cyan, sorted=green-tinted, comparing=yellow.

var _outer: int = 1  # current element to insert
var _inner: int = 0  # scanning position within sorted region
var _inserting: bool = false
var _done: bool = false

func get_name() -> String:
	return "Insertion Sort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if _done:
		return Color(0.2, 0.85, 0.3)
	if index < _outer:
		# Sorted region: green tint
		return Color(0.2 + value * 0.3, 0.7 + value * 0.15, 0.3)
	# Unsorted: default gradient
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

func initialize(size: int) -> PackedFloat32Array:
	_outer = 1
	_inner = 0
	_inserting = false
	_done = false
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done or _outer >= arr.size():
		_done = true
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	var comparisons = []
	var swaps = []
	var highlights = {}

	if not _inserting:
		# Start inserting current element
		_inner = _outer
		_inserting = true

	# Compare with left neighbor
	if _inner > 0 and arr[_inner] < arr[_inner - 1]:
		comparisons.append([_inner, _inner - 1])
		# Swap left
		var tmp = arr[_inner]
		arr[_inner] = arr[_inner - 1]
		arr[_inner - 1] = tmp
		swaps.append([_inner, _inner - 1])
		highlights[_inner - 1] = Color(0.2, 0.9, 0.95)  # cyan: element being inserted
		_inner -= 1
	else:
		# Element is in position — move to next
		if _inner > 0:
			comparisons.append([_inner, _inner - 1])
		highlights[_inner] = Color(0.2, 0.9, 0.95)  # landed position
		_inserting = false
		_outer += 1

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": swaps,
		"highlights": highlights,
		"done": false,
		"description": "Inserting element %d" % _outer
	}
