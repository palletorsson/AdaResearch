class_name CartridgeRandomWalk1D
extends ProfileCartridge

## 1D random walk — displacement over time.
## Scrolling: new steps appear on the right, old ones scroll left.

var _position: float = 0.0
var _history: PackedFloat32Array
var _max_val: float = 1.0

func get_name() -> String:
	return "Random Walk (1D)"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(1.0, 0.85, 0.2)  # warm yellow

func get_y_range() -> Vector2:
	return Vector2(-5.0, 5.0)

func initialize(sample_count: int) -> Array:
	_position = 0.0
	_history = PackedFloat32Array()
	_history.resize(sample_count)
	_history.fill(0.0)
	return [_history.duplicate()]

func get_preferred_interval() -> float:
	return 0.03

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	# Random step
	_position += randf_range(-0.15, 0.15)

	# Shift history left, add new position at end
	var n = _history.size()
	for i in range(n - 1):
		_history[i] = _history[i + 1]
	_history[n - 1] = _position

	# Auto-scale Y range
	var min_v = _history[0]
	var max_v = _history[0]
	for i in range(1, n):
		min_v = minf(min_v, _history[i])
		max_v = maxf(max_v, _history[i])
	var range_v = maxf(max_v - min_v, 1.0)
	var center = (min_v + max_v) * 0.5

	var buf: PackedFloat32Array = traces[0]
	for i in range(n):
		buf[i] = (_history[i] - center) / (range_v * 0.5)  # normalize to -1..1

	return {"traces": traces, "markers": [], "done": false, "description": ""}
