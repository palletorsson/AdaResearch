class_name CartridgeDampedOscillation
extends ProfileCartridge

## Damped harmonic oscillation — amplitude decays exponentially.
## Two traces: the oscillation + the decay envelope.

var _frequency: float = 4.0
var _damping: float = 0.8
var _phase_speed: float = 2.0

func get_name() -> String:
	return "Damped Oscillation"

func get_trace_count() -> int:
	return 2  # oscillation + envelope

func get_trace_color(trace_index: int) -> Color:
	if trace_index == 0:
		return Color(0.2, 1.0, 0.4)    # oscillation: green
	return Color(0.9, 0.3, 0.3, 0.5)  # envelope: dim red

func get_trace_width(trace_index: int) -> float:
	return 1.0 if trace_index == 0 else 0.5

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var osc_buf: PackedFloat32Array = traces[0]
	var env_buf: PackedFloat32Array = traces[1]
	var n = osc_buf.size()

	for i in range(n):
		var t = float(i) / float(n - 1) * 3.0  # time span
		var envelope = exp(-_damping * t)
		var oscillation = envelope * sin(t * TAU * _frequency + delta_time * _phase_speed)
		osc_buf[i] = oscillation
		env_buf[i] = envelope

	return {"traces": traces, "markers": [], "done": false, "description": ""}
