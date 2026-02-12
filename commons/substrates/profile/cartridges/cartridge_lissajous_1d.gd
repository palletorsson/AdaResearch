class_name CartridgeLissajous1D
extends ProfileCartridge

## Lissajous projected to 1D — shows X and Y components of the figure.
## Two traces: X(t) and Y(t) with different frequency ratios.

var _freq_a: float = 3.0
var _freq_b: float = 2.0  # 3:2 ratio
var _phase_speed: float = 1.5

func get_name() -> String:
	return "Lissajous Components"

func get_trace_count() -> int:
	return 2

func get_trace_color(trace_index: int) -> Color:
	if trace_index == 0:
		return Color(0.2, 1.0, 0.4)  # X: green
	return Color(1.0, 0.5, 0.2)      # Y: orange

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf_x: PackedFloat32Array = traces[0]
	var buf_y: PackedFloat32Array = traces[1]
	var n = buf_x.size()

	for i in range(n):
		var t = float(i) / float(n - 1) * TAU * 2.0 + delta_time * _phase_speed
		buf_x[i] = sin(t * _freq_a)
		buf_y[i] = sin(t * _freq_b + PI * 0.25)

	return {"traces": traces, "markers": [], "done": false, "description": ""}
