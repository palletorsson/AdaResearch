extends PaperAlgorithm
class_name PaperJuliaSet

## Julia set — same as Mandelbrot but fixed c, variable z.
## Each paper gets a random c value → unique pattern.

var _w: int
var _h: int
var _current_y: int = 0
var _max_iter: int = 64
var _cx: float
var _cy: float
var _zoom: float = 1.6
var _palette: Array[Color] = []

func get_name() -> String:
	return "Julia (%.2f, %.2f)" % [_cx, _cy]

func get_background_color() -> Color:
	return Color(0.02, 0.0, 0.03)

func get_primary_color() -> Color:
	return Color(0.8, 0.3, 1.0)

func get_initial_steps() -> int:
	return 15

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_y = 0

	# Interesting c values for Julia sets
	var c_values = [
		Vector2(-0.7, 0.27015),      # Classic spiral
		Vector2(-0.4, 0.6),          # Dendrite
		Vector2(0.285, 0.01),        # Near parabolic
		Vector2(-0.835, -0.2321),    # Siegel disk
		Vector2(-0.8, 0.156),        # Rabbit-like
		Vector2(0.355, 0.355),       # Swirl
	]
	var pick = c_values[randi() % c_values.size()]
	_cx = pick.x
	_cy = pick.y

	_palette.clear()
	for i in range(_max_iter):
		var t = float(i) / float(_max_iter)
		var r = 0.5 + 0.5 * sin(4.0 * t * PI + 1.0)
		var g = 0.2 + 0.3 * t
		var b = 0.3 + 0.7 * sin(2.0 * t * PI)
		_palette.append(Color(r, g, b))

func step(img: Image, _step_index: int) -> bool:
	if _current_y >= _h:
		return false

	for x in range(_w):
		var zx = (float(x) / _w - 0.5) * _zoom * 2.0 * float(_w) / float(_h)
		var zy = (float(_current_y) / _h - 0.5) * _zoom * 2.0

		var iter = 0
		while zx * zx + zy * zy < 4.0 and iter < _max_iter:
			var xtemp = zx * zx - zy * zy + _cx
			zy = 2.0 * zx * zy + _cy
			zx = xtemp
			iter += 1

		if iter >= _max_iter:
			set_pixel_safe(img, x, _current_y, Color(0.02, 0.0, 0.03))
		else:
			set_pixel_safe(img, x, _current_y, _palette[iter % _palette.size()])

	_current_y += 1
	return true
