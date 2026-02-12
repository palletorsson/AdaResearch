extends PaperAlgorithm
class_name PaperReactionDiffusion

## Gray-Scott reaction-diffusion — spots and stripes self-organizing.
## Turing patterns from two chemical concentrations.

var _w: int
var _h: int
var _u: Array[float] = []  # Chemical A concentration
var _v: Array[float] = []  # Chemical B concentration
var _feed: float = 0.055
var _kill: float = 0.062
var _du: float = 0.16
var _dv: float = 0.08

func get_name() -> String:
	return "Reaction-Diffusion"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_primary_color() -> Color:
	return Color(0.2, 0.6, 0.9)

func get_initial_steps() -> int:
	return 50

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height

	# Random feed/kill parameters for variety
	var params = [
		[0.055, 0.062],  # Spots
		[0.042, 0.063],  # Stripes
		[0.035, 0.065],  # Coral/maze
		[0.025, 0.060],  # Worms
		[0.050, 0.065],  # Fingerprints
	]
	var pick = params[randi() % params.size()]
	_feed = pick[0]
	_kill = pick[1]

	# Initialize: A=1 everywhere, B=0 except seeded spots
	var size = width * height
	_u.resize(size)
	_v.resize(size)
	_u.fill(1.0)
	_v.fill(0.0)

	# Seed B in random spots
	for i in range(8):
		var cx = randi_range(width / 4, 3 * width / 4)
		var cy = randi_range(height / 4, 3 * height / 4)
		var radius = randi_range(2, 5)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if dx * dx + dy * dy <= radius * radius:
					var idx = ((cy + dy + height) % height) * width + ((cx + dx + width) % width)
					_v[idx] = 1.0

func step(img: Image, _step_index: int) -> bool:
	# Run multiple simulation steps per visual step
	for _sub in range(10):
		var new_u: Array[float] = []
		var new_v: Array[float] = []
		new_u.resize(_w * _h)
		new_v.resize(_w * _h)

		for y in range(_h):
			for x in range(_w):
				var idx = y * _w + x

				# Laplacian (5-point stencil)
				var lap_u = _laplacian(_u, x, y)
				var lap_v = _laplacian(_v, x, y)

				var u_val = _u[idx]
				var v_val = _v[idx]
				var uvv = u_val * v_val * v_val

				new_u[idx] = u_val + _du * lap_u - uvv + _feed * (1.0 - u_val)
				new_v[idx] = v_val + _dv * lap_v + uvv - (_feed + _kill) * v_val

				new_u[idx] = clampf(new_u[idx], 0.0, 1.0)
				new_v[idx] = clampf(new_v[idx], 0.0, 1.0)

		_u = new_u
		_v = new_v

	# Render
	for y in range(_h):
		for x in range(_w):
			var idx = y * _w + x
			var val = _v[idx]
			var c = Color(
				val * 0.15,
				val * 0.5 + 0.02,
				val * 0.9 + 0.04
			)
			set_pixel_safe(img, x, y, c)

	return true

func _laplacian(arr: Array[float], x: int, y: int) -> float:
	var idx = y * _w + x
	var up = ((y - 1 + _h) % _h) * _w + x
	var down = ((y + 1) % _h) * _w + x
	var left = y * _w + ((x - 1 + _w) % _w)
	var right = y * _w + ((x + 1) % _w)
	return arr[up] + arr[down] + arr[left] + arr[right] - 4.0 * arr[idx]
