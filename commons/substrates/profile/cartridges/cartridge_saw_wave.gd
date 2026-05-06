class_name CartridgeSawWave
extends ProfileCartridge

## Sawtooth wave — ramp up, instant drop. All harmonics present.

var _frequency: float = 2.0
var _phase_speed: float = 3.0

func get_name() -> String:
	return "Sawtooth Wave"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(1.0, 0.7, 0.1)  # amber

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf: PackedFloat32Array = traces[0]
	var n = buf.size()
	for i in range(n):
		var t = float(i) / float(n - 1)
		var phase = t * _frequency + delta_time * _phase_speed / TAU
		buf[i] = 2.0 * (fmod(phase + 0.5, 1.0)) - 1.0
	return {"traces": traces, "markers": [], "done": false, "description": ""}
