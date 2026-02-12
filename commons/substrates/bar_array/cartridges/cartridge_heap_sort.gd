class_name CartridgeHeapSort
extends BarArrayCartridge

## Heap Sort — build max-heap, then extract maximums.
## O(n log n) always. In-place. Two phases: heapify, then extract.
## Colors: heap_building=orange, extracting=cyan, sorted=green.

enum Phase { HEAPIFY, EXTRACT }

var _phase: Phase = Phase.HEAPIFY
var _heapify_idx: int = 0     # current node being sifted down during build
var _heap_size: int = 0       # boundary of the heap region
var _sift_node: int = -1      # node currently being sifted
var _done: bool = false

func get_name() -> String:
	return "Heap Sort"

func get_bar_color(index: int, value: float, total: int) -> Color:
	if _done:
		return Color(0.2, 0.85, 0.3)
	if index >= _heap_size and _phase == Phase.EXTRACT:
		return Color(0.2, 0.85, 0.3)  # sorted region: green
	if _phase == Phase.HEAPIFY:
		return Color(1.0, 0.6 + value * 0.2, 0.2)  # orange during build
	return Color(0.2, 0.7 + value * 0.2, 0.95)  # cyan during extract

func initialize(size: int) -> PackedFloat32Array:
	_phase = Phase.HEAPIFY
	_heapify_idx = size / 2 - 1  # last non-leaf
	_heap_size = size
	_sift_node = -1
	_done = false
	return super.initialize(size)

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	var comparisons = []
	var swaps = []
	var highlights = {}

	if _phase == Phase.HEAPIFY:
		if _heapify_idx >= 0:
			# Sift down one node
			_sift_down(arr, _heapify_idx, _heap_size, comparisons, swaps, highlights)
			_heapify_idx -= 1
		else:
			# Heap built, switch to extract phase
			_phase = Phase.EXTRACT

		return {
			"array": arr,
			"comparisons": comparisons,
			"swaps": swaps,
			"highlights": highlights,
			"done": false,
			"description": "Building heap, sifting node %d" % (_heapify_idx + 1)
		}

	# EXTRACT phase: swap root (max) to end, shrink heap, sift down new root
	if _heap_size <= 1:
		_done = true
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sorted!"}

	# Swap root with last heap element
	_heap_size -= 1
	var tmp = arr[0]
	arr[0] = arr[_heap_size]
	arr[_heap_size] = tmp
	swaps.append([0, _heap_size])

	# Sift new root down
	_sift_down(arr, 0, _heap_size, comparisons, swaps, highlights)

	return {
		"array": arr,
		"comparisons": comparisons,
		"swaps": swaps,
		"highlights": highlights,
		"done": false,
		"description": "Extracting max, heap size = %d" % _heap_size
	}


func _sift_down(arr: PackedFloat32Array, node: int, size: int,
		comparisons: Array, swaps: Array, highlights: Dictionary) -> void:
	var parent = node
	while true:
		var left = 2 * parent + 1
		var right = 2 * parent + 2
		var largest = parent

		if left < size:
			comparisons.append([left, largest])
			if arr[left] > arr[largest]:
				largest = left

		if right < size:
			comparisons.append([right, largest])
			if arr[right] > arr[largest]:
				largest = right

		if largest != parent:
			var tmp = arr[parent]
			arr[parent] = arr[largest]
			arr[largest] = tmp
			swaps.append([parent, largest])
			highlights[largest] = Color(1.0, 0.8, 0.2)  # sifting node
			parent = largest
		else:
			break
