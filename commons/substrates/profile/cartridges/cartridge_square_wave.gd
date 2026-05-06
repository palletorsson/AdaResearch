class_name CartridgeSquareWave
extends ProfileCartridge

## Square wave — digital on/off. Harmonics are odd only.

var _frequency: float = 2.0
var _phase_speed: float = 3.0

func get_name() -> String:
	return "Square Wave"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(0.2, 0.8, 1.0)  # cyan

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf: PackedFloat32Array = traces[0]
	var n = buf.size()
	for i in range(n):
		var t = float(i) / float(n - 1)
		buf[i] = sign(sin(t * TAU * _frequency + delta_time * _phase_speed))
	return {"traces": traces, "markers": [], "done": false, "description": ""}
