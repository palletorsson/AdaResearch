class_name CartridgeBrownianBridge
extends ProfileCartridge

## Brownian bridge — random walk constrained to return to zero.
## Generates a new bridge each cycle. Shows how constraint shapes randomness.

var _bridge: PackedFloat32Array
var _rebuild_interval: int = 120

func get_name() -> String:
	return "Brownian Bridge"

func get_trace_color(trace_index: int) -> Color:
	return Color(0.4, 0.7, 1.0)  # soft blue

func get_preferred_interval() -> float:
	return 0.03

func initialize(sample_count: int) -> Array:
	_bridge = _generate_bridge(sample_count)
	return [_bridge.duplicate()]

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	if step_index > 0 and step_index % _rebuild_interval == 0:
		var n = traces[0].size()
		_bridge = _generate_bridge(n)

	# Interpolate current display toward target bridge
	var buf: PackedFloat32Array = traces[0]
	for i in range(buf.size()):
		buf[i] = lerpf(buf[i], _bridge[i], 0.05)

	return {"traces": traces, "markers": [], "done": false, "description": ""}

func _generate_bridge(n: int) -> PackedFloat32Array:
	## Generate Brownian bridge: W(t) - t*W(1) where W is Brownian motion
	var walk = PackedFloat32Array()
	walk.resize(n)
	walk[0] = 0.0

	# Forward walk
	for i in range(1, n):
		walk[i] = walk[i - 1] + randf_range(-0.1, 0.1)

	# Subtract linear interpolation to force start=0, end=0
	var end_val = walk[n - 1]
	for i in range(n):
		var t = float(i) / float(n - 1)
		walk[i] -= t * end_val

	# Normalize to -1..1
	var max_abs = 0.001
	for i in range(n):
		max_abs = maxf(max_abs, absf(walk[i]))
	for i in range(n):
		walk[i] /= max_abs

	return walk
