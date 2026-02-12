extends PaperAlgorithm
class_name PaperVoronoi

## Voronoi diagram — seeds appear one by one, cells form around them.
## Each new seed recomputes the whole diagram.

var _w: int
var _h: int
var _seeds: Array[Vector2i] = []
var _seed_colors: Array[Color] = []
var _max_seeds: int = 24

func get_name() -> String:
	return "Voronoi"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_primary_color() -> Color:
	return Color(0.5, 0.8, 1.0)

func get_initial_steps() -> int:
	return 5

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_seeds.clear()
	_seed_colors.clear()

func step(img: Image, _step_index: int) -> bool:
	if _seeds.size() >= _max_seeds:
		return false

	# Add a new random seed
	_seeds.append(Vector2i(randi() % _w, randi() % _h))

	# Generate a color for it — warm/cool alternating
	var hue = fmod(float(_seeds.size()) * 0.618033988749, 1.0)  # Golden ratio spacing
	var color = Color.from_hsv(hue, 0.6, 0.7)
	_seed_colors.append(color)

	# Recompute entire diagram
	for y in range(_h):
		for x in range(_w):
			var min_dist = INF
			var closest = 0
			for i in range(_seeds.size()):
				var dx = x - _seeds[i].x
				var dy = y - _seeds[i].y
				var dist = dx * dx + dy * dy
				if dist < min_dist:
					min_dist = dist
					closest = i

			# Color the cell — slightly darker at edges
			var c = _seed_colors[closest]

			# Check if near a boundary (neighbor has different closest)
			var is_edge = false
			for d in [Vector2i(1,0), Vector2i(0,1)]:
				var nx = x + d.x
				var ny = y + d.y
				if nx < _w and ny < _h:
					var min_d2 = INF
					var closest2 = 0
					for i in range(_seeds.size()):
						var ddx = nx - _seeds[i].x
						var ddy = ny - _seeds[i].y
						var dist2 = ddx * ddx + ddy * ddy
						if dist2 < min_d2:
							min_d2 = dist2
							closest2 = i
					if closest2 != closest:
						is_edge = true
						break

			if is_edge:
				c = c * 0.3  # Dark edges
			set_pixel_safe(img, x, y, c)

	# Mark seed points bright
	for i in range(_seeds.size()):
		var s = _seeds[i]
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				set_pixel_safe(img, s.x + dx, s.y + dy, Color.WHITE)

	return true
