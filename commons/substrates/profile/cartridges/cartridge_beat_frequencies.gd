class_name CartridgeBeatFrequencies
extends ProfileCartridge

## Two close frequencies creating beats — amplitude modulation.
## Two traces: individual waves + their sum showing the envelope.

var _freq_a: float = 5.0
var _freq_b: float = 5.5  # close → slow beat
var _phase_speed: float = 3.0

func get_name() -> String:
	return "Beat Frequencies"

func get_trace_count() -> int:
	return 3  # wave A, wave B, sum

func get_trace_color(trace_index: int) -> Color:
	match trace_index:
		0: return Color(0.3, 0.6, 1.0, 0.4)  # A: dim blue
		1: return Color(1.0, 0.4, 0.3, 0.4)  # B: dim red
		2: return Color(0.2, 1.0, 0.4)        # sum: bright green
	return Color.WHITE

func get_trace_width(trace_index: int) -> float:
	return 0.4 if trace_index < 2 else 1.0

func get_trace_emission(trace_index: int) -> float:
	return 0.3 if trace_index < 2 else 0.8

func get_y_range() -> Vector2:
	return Vector2(-2.0, 2.0)

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var buf_a: PackedFloat32Array = traces[0]
	var buf_b: PackedFloat32Array = traces[1]
	var buf_sum: PackedFloat32Array = traces[2]
	var n = buf_a.size()

	for i in range(n):
		var t = float(i) / float(n - 1)
		var phase = delta_time * _phase_speed
		var a = sin(t * TAU * _freq_a + phase)
		var b = sin(t * TAU * _freq_b + phase * 1.1)
		buf_a[i] = a
		buf_b[i] = b
		buf_sum[i] = a + b

	return {"traces": traces, "markers": [], "done": false, "description": ""}
