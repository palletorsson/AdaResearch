extends PaperAlgorithm
class_name PaperNoiseOctaves

## Noise octave layering — each step adds an octave.
## Watch smooth blur become detailed terrain.

var _w: int
var _h: int
var _noise: FastNoiseLite
var _current_octave: int = 0
var _max_octaves: int = 8
var _accumulated: Array[float] = []

func get_name() -> String:
	return "Noise Octaves"

func get_background_color() -> Color:
	return Color(0.0, 0.0, 0.0)

func get_initial_steps() -> int:
	return 3

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_octave = 0
	_accumulated.resize(width * height)
	_accumulated.fill(0.0)

	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.seed = randi()

func step(img: Image, _step_index: int) -> bool:
	_current_octave += 1
	if _current_octave > _max_octaves:
		return false

	var frequency = pow(2.0, _current_octave - 1) * 0.01
	var amplitude = pow(0.5, _current_octave - 1)

	_noise.frequency = frequency

	# Add this octave to accumulated
	var max_val = 0.0
	for y in range(_h):
		for x in range(_w):
			var val = _noise.get_noise_2d(x, y) * amplitude
			_accumulated[y * _w + x] += val
			max_val = maxf(max_val, abs(_accumulated[y * _w + x]))

	# Normalize and render
	if max_val > 0.0:
		for y in range(_h):
			for x in range(_w):
				var norm = (_accumulated[y * _w + x] / max_val + 1.0) / 2.0
				# Terrain-like coloring
				var c: Color
				if norm < 0.35:
					c = Color(0.05, 0.1, 0.3)       # Deep water
				elif norm < 0.45:
					c = Color(0.1, 0.25, 0.5)        # Shallow water
				elif norm < 0.5:
					c = Color(0.7, 0.7, 0.4)         # Sand
				elif norm < 0.7:
					c = Color(0.2, 0.5 + norm * 0.3, 0.15)  # Grass
				elif norm < 0.85:
					c = Color(0.4, 0.35, 0.25)       # Mountain
				else:
					c = Color(0.9, 0.9, 0.95)        # Snow
				set_pixel_safe(img, x, y, c)

	return true
