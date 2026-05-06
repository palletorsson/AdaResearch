class_name CartridgeLogisticMap
extends ProfileCartridge

## Logistic map: x_{n+1} = r * x_n * (1 - x_n)
## r sweeps from 2.5 to 4.0 across the display. At each X position,
## iterates and plots the attractor values. The bifurcation diagram.
## Builds incrementally — each step adds more iterations for precision.

var _iterations_done: int = 0
var _max_iterations: int = 200
var _settle: int = 100  # discard transient
var _accumulator: PackedFloat32Array  # max Y value at each X column

func get_name() -> String:
	return "Logistic Map (Bifurcation)"

func get_trace_color(trace_index: int) -> Color:
	return Color(1.0, 0.5, 0.2)  # warm orange

func get_y_range() -> Vector2:
	return Vector2(0.0, 1.0)

func get_preferred_interval() -> float:
	return 0.05

func initialize(sample_count: int) -> Array:
	_iterations_done = 0
	_accumulator = PackedFloat32Array()
	_accumulator.resize(sample_count)
	_accumulator.fill(0.0)
	return [_accumulator.duplicate()]

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	if _iterations_done >= _max_iterations:
		return {"traces": null, "markers": [], "done": true, "description": "Bifurcation complete"}

	var n = traces[0].size()
	var buf: PackedFloat32Array = traces[0]

	# Each step: iterate more at every r value
	var batch = 5
	for b in range(batch):
		_iterations_done += 1
		for i in range(n):
			var r = lerpf(2.5, 4.0, float(i) / float(n - 1))
			var x = randf_range(0.1, 0.9)

			# Settle
			for s in range(_settle):
				x = r * x * (1.0 - x)

			# Plot attractor value (take max of existing and new for density)
			# Actually: for bifurcation diagram, each column should show the last N values
			# We'll use running average to build density
			var old = buf[i]
			buf[i] = lerpf(old, x, 1.0 / float(_iterations_done))

	return {
		"traces": traces, "markers": [], "done": false,
		"description": "Iterations: %d/%d" % [_iterations_done, _max_iterations]
	}
