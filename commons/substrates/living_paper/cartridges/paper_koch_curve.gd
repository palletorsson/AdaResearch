extends PaperAlgorithm
class_name PaperKochCurve

## Koch snowflake — each step adds an iteration.
## Watch the coastline become infinitely detailed.

var _w: int
var _h: int
var _current_iteration: int = 0
var _max_iterations: int = 6
var _color: Color

func get_name() -> String:
	return "Koch Snowflake"

func get_background_color() -> Color:
	return Color(0.02, 0.03, 0.06)

func get_primary_color() -> Color:
	return Color(0.3, 0.9, 1.0)

func get_initial_steps() -> int:
	return 2

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_iteration = 0
	_color = get_primary_color()

func step(img: Image, _step_index: int) -> bool:
	_current_iteration += 1
	if _current_iteration > _max_iterations:
		return false

	# Clear and redraw at current iteration
	img.fill(get_background_color())

	# Starting triangle points
	var cx = _w / 2.0
	var cy = _h / 2.0
	var size = min(_w, _h) * 0.4
	var h_offset = size * sqrt(3.0) / 2.0

	var p1 = Vector2(cx, cy - h_offset * 0.7)
	var p2 = Vector2(cx - size / 2.0, cy + h_offset * 0.3)
	var p3 = Vector2(cx + size / 2.0, cy + h_offset * 0.3)

	# Draw Koch curve for each side
	var iter_color = _color * (0.5 + 0.5 * float(_current_iteration) / float(_max_iterations))
	_draw_koch(img, p1, p2, _current_iteration, iter_color)
	_draw_koch(img, p2, p3, _current_iteration, iter_color)
	_draw_koch(img, p3, p1, _current_iteration, iter_color)

	return true

func _draw_koch(img: Image, a: Vector2, b: Vector2, depth: int, color: Color) -> void:
	if depth == 0:
		draw_line(img, Vector2i(a), Vector2i(b), color)
		return

	var dx = b - a
	var p1 = a + dx / 3.0
	var p3 = a + dx * 2.0 / 3.0

	# Peak point (equilateral triangle)
	var mid = (a + b) / 2.0
	var perp = Vector2(-dx.y, dx.x) * sqrt(3.0) / 6.0
	var p2 = mid + perp

	_draw_koch(img, a, p1, depth - 1, color)
	_draw_koch(img, p1, p2, depth - 1, color)
	_draw_koch(img, p2, p3, depth - 1, color)
	_draw_koch(img, p3, b, depth - 1, color)
