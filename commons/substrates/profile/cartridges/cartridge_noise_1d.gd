class_name CartridgeNoise1D
extends ProfileCartridge

## 1D Perlin noise profile — smooth organic randomness.
## Scrolls continuously, revealing new terrain.

var _noise: FastNoiseLite
var _scroll_speed: float = 0.3
var _scale: float = 0.02

func get_name() -> String:
	return "1D Noise"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(0.6, 0.85, 1.0)  # light blue

func initialize(sample_count: int) -> Array:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = randi()
	_noise.frequency = 0.01
	return super.initialize(sample_count)

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf: PackedFloat32Array = traces[0]
	var n = buf.size()
	var offset = delta_time * _scroll_speed

	for i in range(n):
		var x = float(i) * _scale + offset
		buf[i] = _noise.get_noise_1d(x * 100.0)

	return {"traces": traces, "markers": [], "done": false, "description": ""}
