extends PaperAlgorithm
class_name PaperHeatDiffusion

## Heat diffusion — hot spot spreading into cold.
## Gradient from red (hot) to blue (cold).

var _w: int
var _h: int
var _temp: Array[float] = []
var _diffusion_rate: float = 0.2

func get_name() -> String:
	return "Heat Diffusion"

func get_background_color() -> Color:
	return Color(0.0, 0.0, 0.1)

func get_primary_color() -> Color:
	return Color(1.0, 0.3, 0.1)

func get_initial_steps() -> int:
	return 20

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_temp.resize(width * height)
	_temp.fill(0.0)

	# Place 2-4 hot spots
	var num_spots = randi_range(2, 4)
	for i in range(num_spots):
		var cx = randi_range(width / 4, 3 * width / 4)
		var cy = randi_range(height / 4, 3 * height / 4)
		var radius = randi_range(3, 8)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if dx * dx + dy * dy <= radius * radius:
					var nx = (cx + dx + width) % width
					var ny = (cy + dy + height) % height
					_temp[ny * width + nx] = 1.0

func step(img: Image, _step_index: int) -> bool:
	# Diffuse
	var new_temp: Array[float] = []
	new_temp.resize(_w * _h)

	for y in range(_h):
		for x in range(_w):
			var idx = y * _w + x
			var lap = (
				_temp[((y-1+_h)%_h) * _w + x] +
				_temp[((y+1)%_h) * _w + x] +
				_temp[y * _w + ((x-1+_w)%_w)] +
				_temp[y * _w + ((x+1)%_w)] -
				4.0 * _temp[idx]
			)
			new_temp[idx] = _temp[idx] + _diffusion_rate * lap
			new_temp[idx] = clampf(new_temp[idx], 0.0, 1.0)

	_temp = new_temp

	# Render with heat colormap
	for y in range(_h):
		for x in range(_w):
			var t = _temp[y * _w + x]
			var c: Color
			if t < 0.25:
				c = Color(0.0, 0.0, t * 4.0 * 0.5 + 0.05)  # Dark blue
			elif t < 0.5:
				c = Color(0.0, (t - 0.25) * 4.0, 0.5)        # Cyan
			elif t < 0.75:
				c = Color((t - 0.5) * 4.0, 1.0, 1.0 - (t - 0.5) * 4.0)  # Yellow
			else:
				c = Color(1.0, 1.0 - (t - 0.75) * 4.0, 0.0)  # Red
			set_pixel_safe(img, x, y, c)

	return true
