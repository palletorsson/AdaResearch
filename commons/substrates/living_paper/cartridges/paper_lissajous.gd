extends PaperAlgorithm
class_name PaperLissajous

## Lissajous figure tracing itself on the page.
## x = sin(at + δ), y = sin(bt)

var _w: int
var _h: int
var _a: float
var _b: float
var _delta: float
var _t: float = 0.0
var _dt: float
var _prev_pos: Vector2i
var _color: Color
var _trail_color: Color

func get_name() -> String:
	return "Lissajous %d:%d" % [int(_a), int(_b)]

func get_background_color() -> Color:
	return Color(0.03, 0.02, 0.05)

func get_primary_color() -> Color:
	return Color(1.0, 0.5, 0.8)

func get_initial_steps() -> int:
	return 60

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_t = 0.0
	_dt = 0.04

	# Random harmonic ratios — common pretty ones
	var ratios = [[1, 2], [2, 3], [3, 4], [3, 5], [1, 3], [5, 4], [5, 6]]
	var pick = ratios[randi() % ratios.size()]
	_a = float(pick[0])
	_b = float(pick[1])
	_delta = PI / (2.0 + randf() * 2.0)

	_color = get_primary_color()
	_trail_color = _color * 0.6

	var center = Vector2(_w / 2.0, _h / 2.0)
	_prev_pos = Vector2i(center)

func step(img: Image, _step_index: int) -> bool:
	_t += _dt

	var cx = _w / 2.0
	var cy = _h / 2.0
	var scale = min(_w, _h) * 0.42

	var x = cx + sin(_a * _t + _delta) * scale
	var y = cy + sin(_b * _t) * scale
	var pos = Vector2i(int(x), int(y))

	# Fade trail color over time for depth
	var age_factor = clampf(1.0 - fmod(_t, TAU * 4) / (TAU * 4), 0.3, 1.0)
	var c = _color * age_factor

	draw_line(img, _prev_pos, pos, c)
	_prev_pos = pos

	# After full cycle, keep going (the figure repeats but with slight drift)
	return true
