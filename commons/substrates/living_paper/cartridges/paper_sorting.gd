extends PaperAlgorithm
class_name PaperSorting

## Sorting algorithms visualized as vertical bars.
## Each bar's height = value. Watch them swap into order.

enum SortMode { BUBBLE, INSERTION, MERGE, QUICK }

var sort_mode: SortMode = SortMode.BUBBLE
var _values: Array[float] = []
var _w: int
var _h: int
var _bar_width: int
var _num_bars: int
var _sorted: bool = false
var _color: Color
var _bg: Color
var _highlight: Color

# Sorting state
var _bubble_i: int = 0
var _bubble_j: int = 0
var _insertion_i: int = 1
var _merge_size: int = 1
var _merge_left: int = 0
var _quick_stack: Array = []  # stack of [lo, hi]
var _active_indices: Array[int] = []

func _init(mode: SortMode = SortMode.BUBBLE) -> void:
	sort_mode = mode

func get_name() -> String:
	match sort_mode:
		SortMode.BUBBLE: return "Bubble Sort"
		SortMode.INSERTION: return "Insertion Sort"
		SortMode.MERGE: return "Merge Sort"
		SortMode.QUICK: return "Quick Sort"
	return "Sort"

func get_background_color() -> Color:
	return Color(0.03, 0.02, 0.05)

func get_primary_color() -> Color:
	return Color(0.3, 0.8, 1.0)

func get_initial_steps() -> int:
	return 0  # Show the unsorted state first

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_bg = get_background_color()
	_color = get_primary_color()
	_highlight = Color(1.0, 0.3, 0.4)

	# Create bars — one per pixel column, or grouped
	_bar_width = max(1, width / 64)
	_num_bars = width / _bar_width

	# Shuffled values from 0.1 to 1.0
	_values.clear()
	for i in range(_num_bars):
		_values.append(float(i + 1) / float(_num_bars))
	# Fisher-Yates shuffle
	for i in range(_num_bars - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = _values[i]
		_values[i] = _values[j]
		_values[j] = temp

	# Init sort state
	_sorted = false
	_bubble_i = 0
	_bubble_j = 0
	_insertion_i = 1
	_merge_size = 1
	_merge_left = 0
	_quick_stack = [[0, _num_bars - 1]]
	_active_indices.clear()

	_render(img)

func step(img: Image, _step_index: int) -> bool:
	if _sorted:
		return false

	_active_indices.clear()

	match sort_mode:
		SortMode.BUBBLE:
			_step_bubble()
		SortMode.INSERTION:
			_step_insertion()
		SortMode.MERGE:
			_step_merge()
		SortMode.QUICK:
			_step_quick()

	_render(img)
	return not _sorted

func _step_bubble() -> void:
	if _bubble_i >= _num_bars - 1:
		_sorted = true
		return
	_active_indices = [_bubble_j, _bubble_j + 1]
	if _values[_bubble_j] > _values[_bubble_j + 1]:
		var temp = _values[_bubble_j]
		_values[_bubble_j] = _values[_bubble_j + 1]
		_values[_bubble_j + 1] = temp
	_bubble_j += 1
	if _bubble_j >= _num_bars - 1 - _bubble_i:
		_bubble_j = 0
		_bubble_i += 1

func _step_insertion() -> void:
	if _insertion_i >= _num_bars:
		_sorted = true
		return
	# Do one swap in the insertion
	var j = _insertion_i
	_active_indices = [j]
	if j > 0 and _values[j - 1] > _values[j]:
		_active_indices.append(j - 1)
		var temp = _values[j]
		_values[j] = _values[j - 1]
		_values[j - 1] = temp
		# Keep going down (next step will continue)
		if j - 1 <= 0 or _values[j - 2] <= _values[j - 1]:
			_insertion_i += 1
	else:
		_insertion_i += 1

func _step_merge() -> void:
	if _merge_size >= _num_bars:
		_sorted = true
		return
	# Merge one pair
	var mid = min(_merge_left + _merge_size, _num_bars)
	var right_end = min(_merge_left + 2 * _merge_size, _num_bars)
	_active_indices = range(_merge_left, right_end)
	_merge_subroutine(_merge_left, mid, right_end)
	_merge_left += 2 * _merge_size
	if _merge_left >= _num_bars:
		_merge_left = 0
		_merge_size *= 2

func _merge_subroutine(left: int, mid: int, right: int) -> void:
	var merged: Array[float] = []
	var i = left
	var j = mid
	while i < mid and j < right:
		if _values[i] <= _values[j]:
			merged.append(_values[i])
			i += 1
		else:
			merged.append(_values[j])
			j += 1
	while i < mid:
		merged.append(_values[i])
		i += 1
	while j < right:
		merged.append(_values[j])
		j += 1
	for k in range(merged.size()):
		_values[left + k] = merged[k]

func _step_quick() -> void:
	if _quick_stack.is_empty():
		_sorted = true
		return
	var bounds = _quick_stack.pop_back()
	var lo = bounds[0]
	var hi = bounds[1]
	if lo >= hi:
		return
	# Partition
	var pivot = _values[hi]
	var i = lo
	_active_indices = [hi]
	for j in range(lo, hi):
		if _values[j] < pivot:
			var temp = _values[i]
			_values[i] = _values[j]
			_values[j] = temp
			i += 1
	var temp = _values[i]
	_values[i] = _values[hi]
	_values[hi] = temp
	_active_indices.append(i)
	# Push sub-partitions
	if i - 1 > lo:
		_quick_stack.append([lo, i - 1])
	if i + 1 < hi:
		_quick_stack.append([i + 1, hi])

func _render(img: Image) -> void:
	for i in range(_num_bars):
		var x = i * _bar_width
		var bar_height = int(_values[i] * _h)
		var c = _highlight if i in _active_indices else _color
		# Fade based on value for depth
		c = c * (0.5 + 0.5 * _values[i])
		clear_column(img, x, _bar_width, _bg)
		draw_vertical_bar(img, x, bar_height, _bar_width, _h, c)
