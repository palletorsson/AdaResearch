# LineVisualizationControl.gd
# Visualization for Line concepts
extends Control

var visualization_type = "basic_line"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const LINE_COLOR = Color(0.2, 0.8, 1.0, 1.0)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const DIRECTION_COLOR = Color(0.8, 0.2, 0.8, 0.8)
const LABEL_COLOR = Color(0.9, 0.9, 1.0, 1.0)

const GRID_SIZE = 400
const GRID_SPACING = 40

func _ready():
	custom_minimum_size = Vector2(400, 400)

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	
	# Center of the visualization
	var center = size / 2
	
	match visualization_type:
		"basic_line":
			draw_basic_line(center)
		"drawing_lines":
			draw_drawing_lines(center)
		"direction_magnitude":
			draw_direction_magnitude(center)
		"cylinder_lines":
			draw_cylinder_lines(center)
		"multiple_lines":
			draw_multiple_lines(center)

func draw_basic_line(center: Vector2):
	"""Show a simple line between two points"""
	draw_grid(center)
	
	# Define two points
	var point_a = center + Vector2(-100, 50)
	var point_b = center + Vector2(100, -50)
	
	# Animate points
	var offset = sin(animation_time) * 20
	point_b.x += offset
	point_b.y += cos(animation_time * 0.7) * 20
	
	# Draw the line
	draw_line(point_a, point_b, LINE_COLOR, 3.0)
	
	# Draw points
	draw_circle(point_a, 8, POINT_COLOR)
	draw_circle(point_b, 8, POINT_COLOR)
	
	# Draw labels
	draw_string(get_theme_default_font(), point_a + Vector2(-40, -15), "Point A", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), point_b + Vector2(15, -15), "Point B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	
	# Draw direction vector
	var direction = (point_b - point_a).normalized() * 40
	var mid = (point_a + point_b) / 2
	draw_arrow(mid, mid + direction, DIRECTION_COLOR, 2.0)
	draw_string(get_theme_default_font(), mid + direction + Vector2(10, 0), "direction", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIRECTION_COLOR)
	
	# Draw distance
	var dist = point_a.distance_to(point_b)
	var info = "Distance: %.1f" % (dist / 10)
	draw_string(get_theme_default_font(), center + Vector2(0, 180), info, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, LABEL_COLOR)

func draw_drawing_lines(center: Vector2):
	"""Show different line drawing methods"""
	draw_grid(center)
	
	# Multiple lines using different styles
	var points_a = [
		center + Vector2(-150, -80),
		center + Vector2(-50, -80),
		center + Vector2(50, -80),
		center + Vector2(150, -80)
	]
	
	var points_b = [
		center + Vector2(-150, 80),
		center + Vector2(-50, 80),
		center + Vector2(50, 80),
		center + Vector2(150, 80)
	]
	
	# Animate
	var wave_offset = sin(animation_time * 2.0) * 30
	for i in range(points_b.size()):
		points_b[i].y += sin(animation_time * 2.0 + i * 0.5) * 20
	
	# Draw lines with varying thickness
	for i in range(points_a.size()):
		var thickness = 2.0 + i * 1.5
		draw_line(points_a[i], points_b[i], LINE_COLOR, thickness)
		
		# Draw endpoints
		draw_circle(points_a[i], 5, POINT_COLOR)
		draw_circle(points_b[i], 5, POINT_COLOR)
		
		# Labels
		draw_string(get_theme_default_font(), points_a[i] + Vector2(-15, -10), str(i+1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LABEL_COLOR)

func draw_direction_magnitude(center: Vector2):
	"""Show line interpolation and direction"""
	draw_grid(center)
	
	var point_a = center + Vector2(-120, 0)
	var point_b = center + Vector2(120, 0)
	
	# Draw main line
	draw_line(point_a, point_b, LINE_COLOR, 2.0)
	draw_circle(point_a, 6, POINT_COLOR)
	draw_circle(point_b, 6, POINT_COLOR)
	
	# Animate a point moving along the line
	var t = (sin(animation_time) + 1.0) / 2.0  # 0 to 1
	var lerp_point = point_a.lerp(point_b, t)
	
	# Draw moving point
	draw_circle(lerp_point, 10, Color(0.8, 0.2, 0.8, 1.0))
	
	# Draw progress line
	draw_line(point_a, lerp_point, Color(0.8, 0.2, 0.8, 0.6), 4.0)
	
	# Draw t value
	var t_text = "t = %.2f" % t
	draw_string(get_theme_default_font(), lerp_point + Vector2(0, -20), t_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.8, 0.2, 0.8, 1.0))
	
	# Draw percentage marks
	for i in range(5):
		var mark_t = i / 4.0
		var mark_pos = point_a.lerp(point_b, mark_t)
		draw_line(mark_pos + Vector2(0, -10), mark_pos + Vector2(0, 10), Color(0.5, 0.5, 0.6, 0.5), 1.0)
		draw_string(get_theme_default_font(), mark_pos + Vector2(0, 25), str(int(mark_t * 100)) + "%", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, LABEL_COLOR * Color(1,1,1,0.6))

func draw_cylinder_lines(center: Vector2):
	"""Show thick lines represented as cylinders"""
	draw_grid(center)
	
	# Multiple thick lines at different angles
	var line_count = 6
	var radius = 100
	
	for i in range(line_count):
		var angle = (float(i) / line_count) * TAU + animation_time * 0.5
		var length = 80 + sin(animation_time * 1.5 + i) * 20
		
		var start = center + Vector2(cos(angle), sin(angle)) * 30
		var end = center + Vector2(cos(angle), sin(angle)) * (30 + length)
		
		# Draw thick line (simulating cylinder)
		var thickness = 6 + sin(animation_time + i) * 2
		draw_line(start, end, LINE_COLOR, thickness)
		
		# Draw endpoints
		draw_circle(start, thickness / 2 + 2, POINT_COLOR)
		draw_circle(end, thickness / 2 + 2, Color(0.8, 0.2, 0.8, 1.0))
	
	# Center point
	draw_circle(center, 8, Color(1.0, 1.0, 1.0, 1.0))

func draw_multiple_lines(center: Vector2):
	"""Show connected lines forming paths"""
	draw_grid(center)
	
	# Create a path with multiple points
	var point_count = 8
	var points = []
	
	for i in range(point_count):
		var angle = (float(i) / point_count) * TAU
		var radius = 80 + sin(animation_time + i * 0.5) * 30
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	# Draw connected lines (LINE_STRIP)
	for i in range(points.size()):
		var next_i = (i + 1) % points.size()
		draw_line(points[i], points[next_i], LINE_COLOR, 3.0)
	
	# Draw points
	for i in range(points.size()):
		draw_circle(points[i], 6, POINT_COLOR)
		
		# Draw point number
		var label = str(i)
		draw_string(get_theme_default_font(), points[i] + Vector2(15, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LABEL_COLOR)
	
	# Draw center reference
	draw_circle(center, 4, Color(0.5, 0.5, 0.6, 0.5))

func draw_grid(center: Vector2):
	"""Draw a subtle grid"""
	var half_size = GRID_SIZE / 2
	
	# Vertical lines
	for x in range(-int(half_size), int(half_size), GRID_SPACING):
		var start = center + Vector2(x, -half_size)
		var end = center + Vector2(x, half_size)
		draw_line(start, end, GRID_COLOR, 1.0)
	
	# Horizontal lines
	for y in range(-int(half_size), int(half_size), GRID_SPACING):
		var start = center + Vector2(-half_size, y)
		var end = center + Vector2(half_size, y)
		draw_line(start, end, GRID_COLOR, 1.0)

func draw_arrow(from: Vector2, to: Vector2, color: Color, width: float = 2.0):
	"""Draw an arrow from one point to another"""
	draw_line(from, to, color, width)
	
	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var arrow_size = 8
	
	var arrow_point1 = to - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_point2 = to - direction * arrow_size - perpendicular * arrow_size * 0.5
	
	var points = PackedVector2Array([to, arrow_point1, arrow_point2])
	draw_colored_polygon(points, color)



