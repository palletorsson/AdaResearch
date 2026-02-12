extends PaperAlgorithm
class_name PaperFourier

## Fourier series building up — each step adds a harmonic.
## Watch a simple sine become a complex waveform.

var _w: int
var _h: int
var _num_harmonics: int = 0
var _max_harmonics: int = 16
var _target: String  # "square", "sawtooth", "triangle"
var _color_base: Color
var _color_sum: Color

func get_name() -> String:
	return "Fourier Series"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.06)

func get_primary_color() -> Color:
	return Color(0.4, 0.8, 1.0)

func get_initial_steps() -> int:
	return 3

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_num_harmonics = 0
	_color_base = Color(0.15, 0.2, 0.3)
	_color_sum = get_primary_color()

	# Random target waveform
	var targets = ["square", "sawtooth", "triangle"]
	_target = targets[randi() % targets.size()]

func step(img: Image, _step_index: int) -> bool:
	_num_harmonics += 1
	if _num_harmonics > _max_harmonics:
		return false

	# Clear and redraw with current number of harmonics
	img.fill(get_background_color())

	# Draw zero line
	var center = _h / 2
	for x in range(_w):
		set_pixel_safe(img, x, center, Color(0.08, 0.08, 0.12))

	# Draw individual harmonics faintly
	for h in range(1, _num_harmonics + 1):
		var prev_y = -1
		var harmonic_color = _color_base * (1.0 - float(h) / float(_max_harmonics + 1))
		for x in range(_w):
			var t = float(x) / float(_w) * TAU * 2.0
			var y_val = _harmonic_value(h, t)
			var y = int(center - y_val * _h * 0.35)
			y = clampi(y, 0, _h - 1)
			if prev_y >= 0:
				draw_line(img, Vector2i(x - 1, prev_y), Vector2i(x, y), harmonic_color)
			prev_y = y

	# Draw summed waveform bright
	var prev_y = -1
	for x in range(_w):
		var t = float(x) / float(_w) * TAU * 2.0
		var sum = 0.0
		for h in range(1, _num_harmonics + 1):
			sum += _harmonic_value(h, t)
		var y = int(center - sum * _h * 0.35)
		y = clampi(y, 0, _h - 1)
		if prev_y >= 0:
			# Brighter with more harmonics
			var intensity = 0.5 + 0.5 * float(_num_harmonics) / float(_max_harmonics)
			draw_line(img, Vector2i(x - 1, prev_y), Vector2i(x, y), _color_sum * intensity)
		prev_y = y

	return true

func _harmonic_value(n: int, t: float) -> float:
	match _target:
		"square":
			# Square wave: sum of odd harmonics: sin(nt)/n for odd n
			if n % 2 == 0:
				return 0.0
			return sin(float(n) * t) / float(n)
		"sawtooth":
			# Sawtooth: sum of all: (-1)^(n+1) * sin(nt)/n
			var sign_val = -1.0 if n % 2 == 0 else 1.0
			return sign_val * sin(float(n) * t) / float(n)
		"triangle":
			# Triangle: sum of odd harmonics: (-1)^((n-1)/2) * sin(nt)/n^2
			if n % 2 == 0:
				return 0.0
			var sign_val = -1.0 if ((n - 1) / 2) % 2 == 1 else 1.0
			return sign_val * sin(float(n) * t) / float(n * n)
	return 0.0
