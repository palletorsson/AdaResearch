extends PaperAlgorithm
class_name PaperQuadtree

## Quadtree subdivision — points added one by one, space splits recursively.

var _w: int
var _h: int
var _points: Array[Vector2i] = []
var _max_points: int = 80
var _capacity: int = 4  # Points per cell before split
var _line_color: Color = Color(0.3, 0.8, 0.5)
var _point_color: Color = Color(1.0, 0.9, 0.3)

func get_name() -> String:
	return "Quadtree"

func get_background_color() -> Color:
	return Color(0.02, 0.03, 0.05)

func get_initial_steps() -> int:
	return 8

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_points.clear()

func step(img: Image, _step_index: int) -> bool:
	if _points.size() >= _max_points:
		return false

	# Add a new random point
	_points.append(Vector2i(randi() % _w, randi() % _h))

	# Clear and redraw
	img.fill(get_background_color())

	# Build and draw quadtree
	_subdivide(img, 0, 0, _w, _h, _points.duplicate())

	# Draw all points on top
	for p in _points:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				set_pixel_safe(img, p.x + dx, p.y + dy, _point_color)

	return true

func _subdivide(img: Image, x: int, y: int, w: int, h: int, points: Array[Vector2i]) -> void:
	# Count points in this region
	var contained: Array[Vector2i] = []
	for p in points:
		if p.x >= x and p.x < x + w and p.y >= y and p.y < y + h:
			contained.append(p)

	if contained.size() <= _capacity or w < 4 or h < 4:
		return

	# Draw subdivision lines
	var mx = x + w / 2
	var my = y + h / 2

	# Vertical line
	for py in range(y, y + h):
		set_pixel_safe(img, mx, py, _line_color * 0.5)
	# Horizontal line
	for px in range(x, x + w):
		set_pixel_safe(img, px, my, _line_color * 0.5)

	# Recurse into quadrants
	var hw = w / 2
	var hh = h / 2
	_subdivide(img, x, y, hw, hh, contained)
	_subdivide(img, mx, y, hw, hh, contained)
	_subdivide(img, x, my, hw, hh, contained)
	_subdivide(img, mx, my, hw, hh, contained)
