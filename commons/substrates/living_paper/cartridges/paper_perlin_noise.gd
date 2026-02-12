extends PaperAlgorithm
class_name PaperPerlinNoise

## Perlin noise terrain rendered row by row.

var _w: int
var _h: int
var _current_y: int = 0
var _noise: FastNoiseLite
var _offset_x: float
var _offset_y: float

func get_name() -> String:
	return "Perlin Noise"

func get_background_color() -> Color:
	return Color(0.0, 0.0, 0.0)

func get_primary_color() -> Color:
	return Color(0.5, 0.7, 0.3)

func get_initial_steps() -> int:
	return 20

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_y = 0
	_offset_x = randf() * 1000.0
	_offset_y = randf() * 1000.0

	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.03
	_noise.seed = randi()

func step(img: Image, _step_index: int) -> bool:
	if _current_y >= _h:
		return false

	for x in range(_w):
		var val = _noise.get_noise_2d(x + _offset_x, _current_y + _offset_y)
		val = (val + 1.0) / 2.0  # normalize to 0-1
		var c = Color(val * 0.4, val * 0.7 + 0.1, val * 0.3)
		set_pixel_safe(img, x, _current_y, c)

	_current_y += 1
	return true
