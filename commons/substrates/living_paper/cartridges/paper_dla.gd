extends PaperAlgorithm
class_name PaperDLA

## Diffusion Limited Aggregation — crystal growing from random walkers.
## A particle wanders randomly until it touches the growing structure.

var _w: int
var _h: int
var _grid: Array[bool] = []  # true = occupied
var _color: Color
var _particles_per_step: int = 3

func get_name() -> String:
	return "DLA Crystal"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_primary_color() -> Color:
	return Color(0.8, 0.9, 1.0)

func get_initial_steps() -> int:
	return 50

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_grid.resize(width * height)
	_grid.fill(false)
	_color = get_primary_color()

	# Seed: single point at center
	var cx = width / 2
	var cy = height / 2
	_grid[cy * width + cx] = true
	set_pixel_safe(img, cx, cy, Color.WHITE)

func step(img: Image, _step_index: int) -> bool:
	for _p in range(_particles_per_step):
		_walk_one_particle(img)
	return true

func _walk_one_particle(img: Image) -> void:
	# Spawn on random edge
	var x: int
	var y: int
	match randi() % 4:
		0: x = randi() % _w; y = 0
		1: x = randi() % _w; y = _h - 1
		2: x = 0; y = randi() % _h
		3: x = _w - 1; y = randi() % _h

	# Walk until adjacent to structure or out of bounds
	var max_steps = _w * _h
	for _i in range(max_steps):
		# Check if adjacent to occupied
		if _has_neighbor(x, y):
			_grid[y * _w + x] = true
			# Color based on distance from center
			var dist = Vector2(x, y).distance_to(Vector2(_w / 2.0, _h / 2.0))
			var t = clampf(dist / float(min(_w, _h) / 2), 0.0, 1.0)
			var c = Color(
				0.5 + 0.5 * t,
				0.7 + 0.3 * (1.0 - t),
				1.0
			)
			set_pixel_safe(img, x, y, c)
			return

		# Random step
		var dirs = [[1,0],[-1,0],[0,1],[0,-1]]
		var d = dirs[randi() % 4]
		x += d[0]
		y += d[1]

		# Bounds check — kill particle if it wanders off
		if x < 0 or x >= _w or y < 0 or y >= _h:
			return

func _has_neighbor(x: int, y: int) -> bool:
	for d in [[1,0],[-1,0],[0,1],[0,-1]]:
		var nx = x + d[0]
		var ny = y + d[1]
		if nx >= 0 and nx < _w and ny >= 0 and ny < _h:
			if _grid[ny * _w + nx]:
				return true
	return false
