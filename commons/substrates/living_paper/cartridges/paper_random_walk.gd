extends PaperAlgorithm
class_name PaperRandomWalk

## Random walk cartridge — wraps the existing RandomWalk types
## into the PaperAlgorithm interface.

enum WalkMode { SIMPLE, DIAGONAL, BROWNIAN, FRACTAL, FIBONACCI_SPIRAL, SELF_AVOIDING, LEVY_FLIGHT }

var walk_mode: WalkMode = WalkMode.SIMPLE
var _pos: Vector2
var _w: int
var _h: int
var _area_size: int = 2
var _visited: Dictionary = {}
var _color: Color

var _walk_names = {
	WalkMode.SIMPLE: "Simple Walk",
	WalkMode.DIAGONAL: "Diagonal Walk",
	WalkMode.BROWNIAN: "Brownian Motion",
	WalkMode.FRACTAL: "Fractal Walk",
	WalkMode.FIBONACCI_SPIRAL: "Fibonacci Spiral",
	WalkMode.SELF_AVOIDING: "Self-Avoiding Walk",
	WalkMode.LEVY_FLIGHT: "Lévy Flight",
}

func get_name() -> String:
	return _walk_names.get(walk_mode, "Random Walk")

func get_primary_color() -> Color:
	match walk_mode:
		WalkMode.SIMPLE: return Color(1.0, 0.4, 0.7)
		WalkMode.BROWNIAN: return Color(0.4, 1.0, 0.6)
		WalkMode.LEVY_FLIGHT: return Color(1.0, 0.8, 0.2)
		WalkMode.SELF_AVOIDING: return Color(0.3, 0.7, 1.0)
		WalkMode.FRACTAL: return Color(0.9, 0.3, 0.3)
		WalkMode.FIBONACCI_SPIRAL: return Color(1.0, 0.6, 0.1)
		_: return Color(1.0, 0.4, 0.7)

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_pos = Vector2(width / 2, height / 2)
	_visited.clear()
	_color = get_primary_color()

func step(img: Image, _step_index: int) -> bool:
	var old_pos = _pos
	match walk_mode:
		WalkMode.SIMPLE:
			_pos = _simple(_pos)
		WalkMode.DIAGONAL:
			_pos = _diagonal(_pos)
		WalkMode.BROWNIAN:
			_pos = _brownian(_pos)
		WalkMode.FRACTAL:
			_pos = _fractal(img, _pos)
		WalkMode.FIBONACCI_SPIRAL:
			_pos = _fibonacci(_pos, _step_index)
		WalkMode.SELF_AVOIDING:
			_pos = _self_avoiding(_pos)
		WalkMode.LEVY_FLIGHT:
			_pos = _levy(_pos)
	draw_line(img, Vector2i(old_pos), Vector2i(_pos), _color)
	return true

func _simple(pos: Vector2) -> Vector2:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	return _clamp_pos(pos + dirs[randi() % 4] * _area_size)

func _diagonal(pos: Vector2) -> Vector2:
	var dirs = [Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1),
				Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	return _clamp_pos(pos + dirs[randi() % 8] * _area_size)

func _brownian(pos: Vector2) -> Vector2:
	var angle = randf() * TAU
	var step_size = randf_range(0.5, _area_size)
	return _clamp_pos(pos + Vector2(cos(angle), sin(angle)) * step_size)

func _fractal(img: Image, pos: Vector2) -> Vector2:
	if randf() < 0.3:
		var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		for i in range(2):
			var branch = _clamp_pos(pos + dirs[randi() % 4] * _area_size)
			draw_line(img, Vector2i(pos), Vector2i(branch), _color * 0.7)
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	return _clamp_pos(pos + dirs[randi() % 4] * _area_size)

func _fibonacci(pos: Vector2, step: int) -> Vector2:
	var fib_a = 1
	var fib_b = 1
	for i in range(min(step, 20)):
		var temp = fib_b
		fib_b = fib_a + fib_b
		fib_a = temp
	var step_size = min(fib_a, 30) * _area_size * 0.1
	var golden_angle = 137.5 * PI / 180.0
	return _clamp_pos(pos + Vector2(cos(golden_angle * step), sin(golden_angle * step)) * step_size)

func _self_avoiding(pos: Vector2) -> Vector2:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	dirs.shuffle()
	for d in dirs:
		var np = _clamp_pos(pos + d * _area_size)
		var key = "%d_%d" % [int(np.x), int(np.y)]
		if not _visited.has(key):
			_visited[key] = true
			return np
	return _simple(pos)  # fallback

func _levy(pos: Vector2) -> Vector2:
	var beta = 1.5
	var u = randf()
	var step_size = clampf(float(_area_size) / pow(u, 1.0 / (beta - 1.0)), _area_size, _area_size * 10)
	var angle = randf() * TAU
	return _clamp_pos(pos + Vector2(cos(angle), sin(angle)) * step_size)

func _clamp_pos(pos: Vector2) -> Vector2:
	pos.x = clampf(pos.x, 0, _w - 1)
	pos.y = clampf(pos.y, 0, _h - 1)
	return pos
