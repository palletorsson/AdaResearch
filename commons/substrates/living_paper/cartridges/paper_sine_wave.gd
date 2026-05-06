extends PaperAlgorithm
class_name PaperSineWave

## Sine wave drawing itself across the page, pixel by pixel.
## Like a seismograph needle on paper.

var _x: int = 0
var _w: int
var _h: int
var _frequency: float
var _amplitude: float
var _phase: float
var _color: Color
var _prev_y: int = -1

func get_name() -> String:
	return "Sine Wave"

func get_background_color() -> Color:
	return Color(0.02, 0.03, 0.06)

func get_primary_color() -> Color:
	return Color(0.2, 1.0, 0.6)

func get_initial_steps() -> int:
	return 20

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_x = 0
	_prev_y = -1
	_color = get_primary_color()
	_frequency = randf_range(0.03, 0.08)
	_amplitude = randf_range(0.2, 0.4)
	_phase = randf() * TAU

	# Draw center line (zero crossing) faintly
	var center_y = height / 2
	var dim = Color(0.1, 0.12, 0.15)
	for x in range(width):
		set_pixel_safe(img, x, center_y, dim)

func step(img: Image, step_index: int) -> bool:
	if _x >= _w:
		# Scroll left, draw new column on right
		_scroll_left(img)
		_x = _w - 1

	var center = _h / 2.0
	var y_val = sin(_phase + step_index * _frequency) * _amplitude * _h
	var y = int(center - y_val)
	y = clampi(y, 0, _h - 1)

	if _prev_y >= 0:
		draw_line(img, Vector2i(_x - 1 if _x > 0 else 0, _prev_y), Vector2i(_x, y), _color)
	else:
		set_pixel_safe(img, _x, y, _color)

	_prev_y = y
	_x += 1
	return true

func _scroll_left(img: Image) -> void:
	for y in range(_h):
		for x in range(1, _w):
			img.set_pixel(x - 1, y, img.get_pixel(x, y))
	# Clear rightmost column
	for y in range(_h):
		set_pixel_safe(img, _w - 1, y, get_background_color())
	# Redraw center line on last column
	set_pixel_safe(img, _w - 1, _h / 2, Color(0.1, 0.12, 0.15))
