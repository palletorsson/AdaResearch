class_name CartridgeFourierSeries
extends ProfileCartridge

## Fourier series building up — watch harmonics sum into a square wave.
## Each step adds one more harmonic. Multiple traces show components.

var _max_harmonics: int = 12
var _current_harmonics: int = 0
var _phase_speed: float = 3.0
var _frequency: float = 2.0
var _steps_per_harmonic: int = 30

func get_name() -> String:
	return "Fourier Series"

func get_trace_count() -> int:
	return 2  # sum + current harmonic being added

func get_trace_color(trace_index: int) -> Color:
	if trace_index == 0:
		return Color(0.2, 1.0, 0.4)  # sum: green
	return Color(0.9, 0.3, 0.3, 0.5)  # current harmonic: dim red

func get_trace_width(trace_index: int) -> float:
	return 1.0 if trace_index == 0 else 0.4

func get_preferred_interval() -> float:
	return 0.016

func initialize(sample_count: int) -> Array:
	_current_harmonics = 1
	return super.initialize(sample_count)

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	var sum_buf: PackedFloat32Array = traces[0]
	var harm_buf: PackedFloat32Array = traces[1]
	var n = sum_buf.size()

	# Slowly add harmonics
	if step_index > 0 and step_index % _steps_per_harmonic == 0:
		_current_harmonics = mini(_current_harmonics + 1, _max_harmonics)

	for i in range(n):
		var t = float(i) / float(n - 1)
		var phase_base = t * TAU * _frequency + delta_time * _phase_speed

		# Sum of odd harmonics: sin(x) + sin(3x)/3 + sin(5x)/5 + ...
		var total = 0.0
		for h in range(_current_harmonics):
			var k = 2 * h + 1  # odd harmonics only
			total += sin(phase_base * k) / float(k)
		sum_buf[i] = total * (4.0 / PI)

		# Current harmonic being added
		var k = 2 * (_current_harmonics - 1) + 1
		harm_buf[i] = sin(phase_base * k) / float(k) * (4.0 / PI)

	return {
		"traces": traces, "markers": [], "done": false,
		"description": "Harmonics: %d/%d" % [_current_harmonics, _max_harmonics]
	}
