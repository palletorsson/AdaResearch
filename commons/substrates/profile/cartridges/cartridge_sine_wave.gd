class_name CartridgeSineWave
extends ProfileCartridge

## Pure sine wave — the fundamental. Scrolls continuously.

var _frequency: float = 2.0  # cycles across display
var _phase_speed: float = 3.0

func get_name() -> String:
	return "Sine Wave"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(0.2, 1.0, 0.4)  # phosphor green

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf: PackedFloat32Array = traces[0]
	var n = buf.size()
	for i in range(n):
		var t = float(i) / float(n - 1)
		buf[i] = sin(t * TAU * _frequency + delta_time * _phase_speed)
	return {"traces": traces, "markers": [], "done": false, "description": ""}
