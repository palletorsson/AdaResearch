class_name CartridgeHistogram
extends BarArrayCartridge

## Histogram — bins incoming random values to form a distribution.
## NOT a sorting algorithm. Step adds one sample, bins normalize.
## Colors: height-mapped blue gradient. Fills up over time.

var _bins: PackedInt32Array
var _total_samples: int = 0
var _max_samples: int = 500
var _done: bool = false

func get_name() -> String:
	return "Histogram"

func get_category() -> String:
	return "signal"

func get_bar_color(index: int, value: float, total: int) -> Color:
	# Blue gradient: darker base, brighter with height
	return Color(0.15 + value * 0.15, 0.4 + value * 0.4, 0.8 + value * 0.2)

func get_preferred_interval() -> float:
	return 0.02  # fast sampling

func initialize(size: int) -> PackedFloat32Array:
	_bins = PackedInt32Array()
	_bins.resize(size)
	_bins.fill(0)
	_total_samples = 0
	_done = false
	_max_samples = size * 15

	var arr = PackedFloat32Array()
	arr.resize(size)
	arr.fill(0.0)
	return arr

func step(arr: PackedFloat32Array) -> Dictionary:
	if _done or _total_samples >= _max_samples:
		_done = true
		return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": "Sampling complete (%d)" % _total_samples}

	# Sample from Gaussian distribution (Box-Muller)
	var u1 = randf()
	var u2 = randf()
	var z = sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
	var value = clampf(0.5 + z * 0.15, 0.0, 0.999)

	# Bin it
	var bin_idx = int(value * arr.size())
	bin_idx = clampi(bin_idx, 0, arr.size() - 1)
	_bins[bin_idx] += 1
	_total_samples += 1

	# Normalize bins to 0.0–1.0
	var max_count = 1
	for i in range(_bins.size()):
		if _bins[i] > max_count:
			max_count = _bins[i]

	for i in range(arr.size()):
		arr[i] = float(_bins[i]) / float(max_count)

	var highlights = {}
	highlights[bin_idx] = Color(1.0, 1.0, 0.5)  # flash the bin that got the sample

	return {
		"array": arr,
		"comparisons": [],
		"swaps": [],
		"highlights": highlights,
		"done": false,
		"description": "Sample %d → bin %d" % [_total_samples, bin_idx]
	}

func is_complete(arr: PackedFloat32Array) -> bool:
	return _done
