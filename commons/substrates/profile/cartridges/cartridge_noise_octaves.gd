class_name CartridgeNoiseOctaves
extends ProfileCartridge

## Noise octave layering — watch detail build up.
## Starts with one smooth octave, adds higher frequencies over time.
## Each trace = one octave. Sum shown as main trace.

var _noise: FastNoiseLite
var _max_octaves: int = 6
var _current_octaves: int = 1
var _steps_per_octave: int = 60
var _scroll_speed: float = 0.2

func get_name() -> String:
	return "Noise Octaves"

func get_trace_count() -> int:
	return _max_octaves + 1  # octaves + sum

func get_trace_color(trace_index: int) -> Color:
	if trace_index == 0:
		return Color(0.2, 1.0, 0.4)  # sum: bright green
	# Octaves: blue → red gradient
	var t = float(trace_index - 1) / float(_max_octaves - 1)
	return Color.from_hsv(lerpf(0.6, 0.0, t), 0.7, 0.8)

func get_trace_width(trace_index: int) -> float:
	return 1.0 if trace_index == 0 else 0.3

func get_trace_emission(trace_index: int) -> float:
	return 0.8 if trace_index == 0 else 0.2

func get_preferred_interval() -> float:
	return 0.016

func initialize(sample_count: int) -> Array:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()
	_current_octaves = 1
	var traces = []
	for i in range(_max_octaves + 1):
		var buf = PackedFloat32Array()
		buf.resize(sample_count)
		buf.fill(0.0)
		traces.append(buf)
	return traces

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	if step_index > 0 and step_index % _steps_per_octave == 0:
		_current_octaves = mini(_current_octaves + 1, _max_octaves)

	var n = traces[0].size()
	var offset = delta_time * _scroll_speed

	# Clear sum
	var sum_buf: PackedFloat32Array = traces[0]
	sum_buf.fill(0.0)

	for oct in range(_current_octaves):
		var freq = pow(2.0, oct)
		var amp = pow(0.5, oct)
		var oct_buf: PackedFloat32Array = traces[oct + 1]

		for i in range(n):
			var x = (float(i) / float(n - 1) + offset) * 50.0 * freq
			var val = _noise.get_noise_1d(x) * amp
			oct_buf[i] = val
			sum_buf[i] += val

	# Zero out inactive octave traces
	for oct in range(_current_octaves, _max_octaves):
		traces[oct + 1].fill(0.0)

	return {
		"traces": traces, "markers": [], "done": false,
		"description": "Octaves: %d/%d" % [_current_octaves, _max_octaves]
	}
