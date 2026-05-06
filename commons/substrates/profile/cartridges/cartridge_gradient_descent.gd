class_name CartridgeGradientDescent
extends ProfileCartridge

## Gradient descent on a 1D loss landscape.
## Shows the landscape + a ball rolling downhill.
## The landscape has local minima — watch it get stuck or find the global minimum.

var _landscape: PackedFloat32Array
var _ball_x: float = 0.1  # normalized position 0..1
var _ball_v: float = 0.0
var _learning_rate: float = 0.002
var _momentum: float = 0.9
var _converged: bool = false

func get_name() -> String:
	return "Gradient Descent"

func get_trace_count() -> int:
	return 1  # landscape only; ball shown as marker

func get_trace_color(trace_index: int) -> Color:
	return Color(0.5, 0.4, 1.0)  # purple landscape

func get_y_range() -> Vector2:
	return Vector2(-0.3, 1.2)

func get_preferred_interval() -> float:
	return 0.03

func initialize(sample_count: int) -> Array:
	_landscape = PackedFloat32Array()
	_landscape.resize(sample_count)
	_ball_x = randf_range(0.05, 0.25)  # start near left
	_ball_v = 0.0
	_converged = false

	# Generate interesting landscape with multiple minima
	var n = sample_count
	for i in range(n):
		var x = float(i) / float(n - 1)
		# Combination of sinusoids creating multiple valleys
		_landscape[i] = (
			0.5 * sin(x * TAU * 1.5 + 0.5) +
			0.3 * sin(x * TAU * 3.0 + 1.0) +
			0.15 * sin(x * TAU * 7.0) +
			0.4  # bias upward
		)

	return [_landscape.duplicate()]

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var n = _landscape.size()
	var markers = []

	if not _converged:
		# Compute gradient at ball position
		var idx = int(_ball_x * float(n - 1))
		idx = clampi(idx, 1, n - 2)
		var gradient = (_landscape[idx + 1] - _landscape[idx - 1]) * 0.5 * float(n)

		# Update with momentum
		_ball_v = _momentum * _ball_v - _learning_rate * gradient
		_ball_x += _ball_v
		_ball_x = clampf(_ball_x, 0.01, 0.99)

		# Check convergence
		if absf(_ball_v) < 0.0001 and step_index > 50:
			_converged = true

	# Ball marker
	var ball_idx = int(_ball_x * float(n - 1))
	ball_idx = clampi(ball_idx, 0, n - 1)
	markers.append({
		"x": _ball_x,
		"color": Color(1.0, 0.3, 0.2, 0.9) if not _converged else Color(0.2, 1.0, 0.4, 0.9),
		"label": "●"
	})

	# Copy landscape to trace (unchanged)
	traces[0] = _landscape.duplicate()

	return {
		"traces": traces, "markers": markers, "done": false,
		"description": "x=%.3f grad=%.3f" % [_ball_x, _ball_v / _learning_rate] if not _converged else "Converged at x=%.3f" % _ball_x
	}

func on_touch(x_normalized: float, traces: Array) -> Array:
	_ball_x = clampf(x_normalized, 0.01, 0.99)
	_ball_v = 0.0
	_converged = false
	return traces
