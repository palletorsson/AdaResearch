class_name CartridgeBellCurve
extends ProfileCartridge

## Bell curve forming — samples accumulate into a Gaussian.
## Histogram trace + theoretical curve overlay.

var _bins: PackedFloat32Array
var _sample_count_total: int = 0
var _max_bin: float = 1.0

func get_name() -> String:
	return "Bell Curve (CLT)"

func get_trace_count() -> int:
	return 2  # histogram + theoretical

func get_trace_color(trace_index: int) -> Color:
	if trace_index == 0:
		return Color(0.2, 0.85, 1.0)  # histogram: cyan
	return Color(1.0, 0.3, 0.3, 0.6)  # theoretical: dim red

func get_trace_width(trace_index: int) -> float:
	return 1.0 if trace_index == 0 else 0.5

func get_y_range() -> Vector2:
	return Vector2(0.0, 1.0)

func get_preferred_interval() -> float:
	return 0.01

func initialize(sample_count: int) -> Array:
	_bins = PackedFloat32Array()
	_bins.resize(sample_count)
	_bins.fill(0.0)
	_sample_count_total = 0
	_max_bin = 1.0

	var traces = []
	for i in range(2):
		var buf = PackedFloat32Array()
		buf.resize(sample_count)
		buf.fill(0.0)
		traces.append(buf)
	return traces

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var n = _bins.size()

	# Add samples (sum of 6 uniform randoms → approximately Gaussian via CLT)
	for s in range(5):
		var val = 0.0
		for j in range(6):
			val += randf()
		val = (val - 3.0) / 3.0  # center around 0, range roughly -1..1
		var bin_idx = int((val * 0.5 + 0.5) * float(n))
		bin_idx = clampi(bin_idx, 0, n - 1)
		_bins[bin_idx] += 1.0
		_sample_count_total += 1

	# Find max for normalization
	_max_bin = 1.0
	for i in range(n):
		_max_bin = maxf(_max_bin, _bins[i])

	# Histogram trace
	var hist_buf: PackedFloat32Array = traces[0]
	for i in range(n):
		hist_buf[i] = _bins[i] / _max_bin

	# Theoretical Gaussian
	var theory_buf: PackedFloat32Array = traces[1]
	var sigma = 0.17  # approximate std dev of the CLT distribution
	for i in range(n):
		var x = float(i) / float(n - 1) - 0.5  # center at 0
		theory_buf[i] = exp(-x * x / (2.0 * sigma * sigma))

	return {
		"traces": traces, "markers": [], "done": false,
		"description": "Samples: %d" % _sample_count_total
	}
