extends PaperAlgorithm
class_name PaperSierpinski

## Sierpinski triangle via chaos game.
## Pick random vertex, move halfway there, plot point.
## The triangle emerges from randomness.

var _w: int
var _h: int
var _pos: Vector2
var _vertices: Array[Vector2]
var _color: Color
var _points_per_step: int = 5

func get_name() -> String:
	return "Sierpinski Triangle"

func get_background_color() -> Color:
	return Color(0.02, 0.02, 0.04)

func get_primary_color() -> Color:
	return Color(0.9, 0.4, 0.2)

func get_initial_steps() -> int:
	return 80

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_color = get_primary_color()

	# Triangle vertices filling the page
	var margin = 4
	_vertices = [
		Vector2(width / 2.0, margin),                  # Top center
		Vector2(margin, height - margin),               # Bottom left
		Vector2(width - margin, height - margin),       # Bottom right
	]

	# Start at random position inside triangle
	_pos = (_vertices[0] + _vertices[1] + _vertices[2]) / 3.0

func step(img: Image, _step_index: int) -> bool:
	for i in range(_points_per_step):
		# Pick random vertex
		var vertex = _vertices[randi() % 3]
		# Move halfway
		_pos = (_pos + vertex) / 2.0
		# Plot — color varies slightly by which vertex
		set_pixel_safe(img, int(_pos.x), int(_pos.y), _color)
	return true
