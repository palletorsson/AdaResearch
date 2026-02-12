extends PaperAlgorithm
class_name PaperMandelbrot

## Mandelbrot set computed row by row, revealing itself scanline by scanline.

var _w: int
var _h: int
var _current_y: int = 0
var _max_iter: int = 64
var _center_x: float = -0.5
var _center_y: float = 0.0
var _zoom: float = 1.5
var _palette: Array[Color] = []

func get_name() -> String:
	return "Mandelbrot Set"

func get_background_color() -> Color:
	return Color(0.0, 0.0, 0.02)

func get_primary_color() -> Color:
	return Color(0.2, 0.5, 1.0)

func get_initial_steps() -> int:
	return 15

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_y = 0

	# Build color palette — deep blues to bright cyan to white
	_palette.clear()
	for i in range(_max_iter):
		var t = float(i) / float(_max_iter)
		var r = 0.1 + 0.5 * sin(3.0 * t * PI) * t
		var g = 0.1 + 0.8 * sin(3.5 * t * PI + 0.5) * t
		var b = 0.3 + 0.7 * t
		_palette.append(Color(r, g, b))

func step(img: Image, _step_index: int) -> bool:
	if _current_y >= _h:
		return false

	# Compute one row
	for x in range(_w):
		var cx = _center_x + (float(x) / _w - 0.5) * _zoom * 2.0 * float(_w) / float(_h)
		var cy = _center_y + (float(_current_y) / _h - 0.5) * _zoom * 2.0

		var zx = 0.0
		var zy = 0.0
		var iter = 0
		while zx * zx + zy * zy < 4.0 and iter < _max_iter:
			var xtemp = zx * zx - zy * zy + cx
			zy = 2.0 * zx * zy + cy
			zx = xtemp
			iter += 1

		if iter >= _max_iter:
			set_pixel_safe(img, x, _current_y, Color(0.0, 0.0, 0.02))
		else:
			# Smooth coloring
			var color_idx = iter % _palette.size()
			set_pixel_safe(img, x, _current_y, _palette[color_idx])

	_current_y += 1
	return true
