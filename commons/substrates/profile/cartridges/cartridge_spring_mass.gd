class_name CartridgeSpringMass
extends ProfileCartridge

## Spring-mass system — real-time physics simulation.
## Scrolling: position trace of a spring evolving over time.
## Touch to perturb.

var _position: float = 0.5
var _velocity: float = 0.0
var _spring_k: float = 20.0
var _damping: float = 0.3
var _mass: float = 1.0
var _history: PackedFloat32Array

func get_name() -> String:
	return "Spring-Mass System"

func is_scrolling() -> bool:
	return true

func get_trace_color(trace_index: int) -> Color:
	return Color(0.3, 0.9, 0.6)  # spring green

func get_preferred_interval() -> float:
	return 0.016

func initialize(sample_count: int) -> Array:
	_position = 0.5  # initial displacement
	_velocity = 0.0
	_history = PackedFloat32Array()
	_history.resize(sample_count)
	_history.fill(0.0)
	return [_history.duplicate()]

func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	# Euler integration
	var dt = 0.016
	var force = -_spring_k * _position - _damping * _velocity
	var accel = force / _mass
	_velocity += accel * dt
	_position += _velocity * dt

	# Shift and append
	var n = _history.size()
	for i in range(n - 1):
		_history[i] = _history[i + 1]
	_history[n - 1] = _position

	var buf: PackedFloat32Array = traces[0]
	for i in range(n):
		buf[i] = _history[i]

	return {"traces": traces, "markers": [], "done": false, "description": ""}

func on_touch(x_normalized: float, traces: Array) -> Array:
	# Kick the spring
	_velocity += 2.0
	return traces
