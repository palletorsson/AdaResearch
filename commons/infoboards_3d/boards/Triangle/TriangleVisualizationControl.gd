# TriangleVisualizationControl.gd
# Visualization for Triangle concepts
extends Control

var visualization_type = "basic_triangle"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const TRIANGLE_FILL_COLOR = Color(0.2, 0.6, 0.9, 0.3)
const TRIANGLE_EDGE_COLOR = Color(0.2, 0.8, 1.0, 1.0)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const NORMAL_COLOR = Color(0.8, 0.2, 0.8, 0.8)
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
		"basic_triangle":
			draw_basic_triangle(center)
		"triangle_normal":
			draw_triangle_normal(center)
		"triangle_area":
			draw_triangle_area(center)
		"triangle_mesh":
			draw_triangle_mesh(center)
		"triangle_foundation":
			draw_triangle_foundation(center)

func draw_basic_triangle(center: Vector2):
	"""Show a basic triangle with three vertices and edges"""
	draw_grid(center)

	# Define three vertices with animation
	var scale_factor = 1.0 + sin(animation_time * 0.5) * 0.1
	var vertex_a = center + Vector2(-100, 80) * scale_factor
	var vertex_b = center + Vector2(100, 80) * scale_factor
	var vertex_c = center + Vector2(0, -80) * scale_factor

	# Draw filled triangle
	var points = PackedVector2Array([vertex_a, vertex_b, vertex_c])
	draw_colored_polygon(points, TRIANGLE_FILL_COLOR)

	# Draw edges
	draw_line(vertex_a, vertex_b, TRIANGLE_EDGE_COLOR, 3.0)
	draw_line(vertex_b, vertex_c, TRIANGLE_EDGE_COLOR, 3.0)
	draw_line(vertex_c, vertex_a, TRIANGLE_EDGE_COLOR, 3.0)

	# Draw vertices
	var pulse = 1.0 + sin(animation_time * 2.0) * 0.2
	draw_circle(vertex_a, 8 * pulse, POINT_COLOR)
	draw_circle(vertex_b, 8 * pulse, POINT_COLOR)
	draw_circle(vertex_c, 8 * pulse, POINT_COLOR)

	# Draw labels
	draw_string(get_theme_default_font(), vertex_a + Vector2(-30, 20), "A (Left)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), vertex_b + Vector2(10, 20), "B (Right)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), vertex_c + Vector2(-20, -15), "C (Top)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

	# Draw edge labels
	var mid_ab = (vertex_a + vertex_b) / 2
	var mid_bc = (vertex_b + vertex_c) / 2
	var mid_ca = (vertex_c + vertex_a) / 2

	draw_string(get_theme_default_font(), mid_ab + Vector2(0, 20), "edge AB", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.7, 0.7, 0.8, 0.8))
	draw_string(get_theme_default_font(), mid_bc + Vector2(20, 0), "edge BC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.8, 0.8))
	draw_string(get_theme_default_font(), mid_ca + Vector2(-50, 0), "edge CA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.8, 0.8))

func draw_triangle_normal(center: Vector2):
	"""Show triangle orientation and normal vector"""
	draw_grid(center)

	# Two triangles with different winding orders
	var offset_x = 120

	# Triangle 1: Counter-clockwise (CCW) - front facing
	var v1a = center + Vector2(-offset_x - 60, 60)
	var v1b = center + Vector2(-offset_x + 60, 60)
	var v1c = center + Vector2(-offset_x, -60)

	# Triangle 2: Clockwise (CW) - back facing
	var v2a = center + Vector2(offset_x - 60, 60)
	var v2b = center + Vector2(offset_x, -60)
	var v2c = center + Vector2(offset_x + 60, 60)

	# Animate rotation
	var angle = animation_time * 0.3
	v1a = rotate_point(v1a, center + Vector2(-offset_x, 0), angle)
	v1b = rotate_point(v1b, center + Vector2(-offset_x, 0), angle)
	v1c = rotate_point(v1c, center + Vector2(-offset_x, 0), angle)

	v2a = rotate_point(v2a, center + Vector2(offset_x, 0), -angle)
	v2b = rotate_point(v2b, center + Vector2(offset_x, 0), -angle)
	v2c = rotate_point(v2c, center + Vector2(offset_x, 0), -angle)

	# Draw CCW triangle
	var points1 = PackedVector2Array([v1a, v1b, v1c])
	draw_colored_polygon(points1, Color(0.2, 0.8, 0.4, 0.4))
	draw_line(v1a, v1b, Color(0.2, 0.8, 0.4), 3.0)
	draw_line(v1b, v1c, Color(0.2, 0.8, 0.4), 3.0)
	draw_line(v1c, v1a, Color(0.2, 0.8, 0.4), 3.0)

	# Draw normal for CCW
	var centroid1 = (v1a + v1b + v1c) / 3
	var normal1 = centroid1 + Vector2(0, -60)
	draw_arrow(centroid1, normal1, Color(0.2, 1.0, 0.4), 3.0)
	draw_string(get_theme_default_font(), normal1 + Vector2(-25, -10), "normal", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.4))

	# Draw CW triangle
	var points2 = PackedVector2Array([v2a, v2b, v2c])
	draw_colored_polygon(points2, Color(0.8, 0.2, 0.4, 0.4))
	draw_line(v2a, v2b, Color(0.8, 0.2, 0.4), 3.0)
	draw_line(v2b, v2c, Color(0.8, 0.2, 0.4), 3.0)
	draw_line(v2c, v2a, Color(0.8, 0.2, 0.4), 3.0)

	# Draw normal for CW (flipped)
	var centroid2 = (v2a + v2b + v2c) / 3
	var normal2 = centroid2 + Vector2(0, 60)
	draw_arrow(centroid2, normal2, Color(1.0, 0.2, 0.4), 3.0)
	draw_string(get_theme_default_font(), normal2 + Vector2(-25, 20), "normal", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.2, 0.4))

	# Labels
	draw_string(get_theme_default_font(), center + Vector2(-offset_x, 120), "CCW (Front)", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.2, 1.0, 0.4))
	draw_string(get_theme_default_font(), center + Vector2(offset_x, 120), "CW (Back)", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1.0, 0.2, 0.4))

func draw_triangle_area(center: Vector2):
	"""Show triangle area calculation with cross product"""
	draw_grid(center)

	# Interactive triangle that changes size
	var scale = 1.0 + sin(animation_time * 0.8) * 0.3
	var vertex_a = center + Vector2(-100, 60)
	var vertex_b = center + Vector2(100 * scale, 80)
	var vertex_c = center + Vector2(20, -80 * scale)

	# Draw filled triangle
	var points = PackedVector2Array([vertex_a, vertex_b, vertex_c])
	draw_colored_polygon(points, TRIANGLE_FILL_COLOR)

	# Draw edges
	draw_line(vertex_a, vertex_b, TRIANGLE_EDGE_COLOR, 3.0)
	draw_line(vertex_b, vertex_c, TRIANGLE_EDGE_COLOR, 3.0)
	draw_line(vertex_c, vertex_a, TRIANGLE_EDGE_COLOR, 3.0)

	# Draw edge vectors from A
	draw_arrow(vertex_a, vertex_b, Color(0.8, 0.4, 0.2), 2.5)
	draw_arrow(vertex_a, vertex_c, Color(0.2, 0.8, 0.4), 2.5)

	# Draw vertices
	draw_circle(vertex_a, 8, POINT_COLOR)
	draw_circle(vertex_b, 8, POINT_COLOR)
	draw_circle(vertex_c, 8, POINT_COLOR)

	# Calculate area (using 2D cross product magnitude)
	var edge1 = vertex_b - vertex_a
	var edge2 = vertex_c - vertex_a
	var cross_magnitude = abs(edge1.x * edge2.y - edge1.y * edge2.x)
	var area = cross_magnitude * 0.5 / 100.0  # Scale down for display

	# Draw area info
	var info_y = size.y - 60
	draw_string(get_theme_default_font(), Vector2(20, info_y), "edge1 × edge2 = %.1f" % cross_magnitude, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
	draw_string(get_theme_default_font(), Vector2(20, info_y + 25), "Area = %.2f (scaled)" % area, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.2))

	# Labels
	draw_string(get_theme_default_font(), vertex_a + Vector2(-30, 5), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), (vertex_a + vertex_b) / 2 + Vector2(0, -15), "edge1", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.4, 0.2))
	draw_string(get_theme_default_font(), (vertex_a + vertex_c) / 2 + Vector2(-40, 0), "edge2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.8, 0.4))

func draw_triangle_mesh(center: Vector2):
	"""Show triangles being added to create a mesh"""
	draw_grid(center)

	# Show sequential triangle building
	var tri_count = int(animation_time * 0.5) % 4 + 1

	# Define triangles for a simple quad (2 triangles)
	var triangles = [
		# Triangle 1
		{
			"vertices": [
				center + Vector2(-80, -60),
				center + Vector2(80, -60),
				center + Vector2(-80, 60)
			],
			"color": Color(0.2, 0.6, 0.9, 0.4)
		},
		# Triangle 2
		{
			"vertices": [
				center + Vector2(80, -60),
				center + Vector2(80, 60),
				center + Vector2(-80, 60)
			],
			"color": Color(0.6, 0.2, 0.9, 0.4)
		},
		# Triangle 3 (extra decoration)
		{
			"vertices": [
				center + Vector2(-80, 60),
				center + Vector2(0, 120),
				center + Vector2(80, 60)
			],
			"color": Color(0.9, 0.6, 0.2, 0.4)
		},
		# Triangle 4 (extra decoration)
		{
			"vertices": [
				center + Vector2(-80, -60),
				center + Vector2(0, -120),
				center + Vector2(80, -60)
			],
			"color": Color(0.2, 0.9, 0.6, 0.4)
		}
	]

	# Draw triangles up to current count
	for i in range(tri_count):
		var tri = triangles[i]
		var points = PackedVector2Array(tri.vertices)
		draw_colored_polygon(points, tri.color)

		# Draw edges
		for j in range(3):
			var v1 = tri.vertices[j]
			var v2 = tri.vertices[(j + 1) % 3]
			draw_line(v1, v2, tri.color * Color(2, 2, 2, 1), 3.0)

		# Draw vertices
		for v in tri.vertices:
			draw_circle(v, 6, POINT_COLOR)

		# Draw triangle number
		var centroid = (tri.vertices[0] + tri.vertices[1] + tri.vertices[2]) / 3
		draw_string(get_theme_default_font(), centroid, str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, 0.9))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Building mesh: %d triangles" % tri_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

func draw_triangle_foundation(center: Vector2):
	"""Show that complex shapes are made of triangles"""
	draw_grid(center)

	# Create a circle approximation using triangles
	var segment_count = 12
	var radius = 120
	var show_triangles = sin(animation_time * 0.5) > 0  # Toggle visibility

	# Draw center point
	draw_circle(center, 6, POINT_COLOR)

	for i in range(segment_count):
		var angle1 = (float(i) / segment_count) * TAU
		var angle2 = (float(i + 1) / segment_count) * TAU

		var p1 = center + Vector2(cos(angle1), sin(angle1)) * radius
		var p2 = center + Vector2(cos(angle2), sin(angle2)) * radius

		if show_triangles:
			# Draw individual triangles
			var points = PackedVector2Array([center, p1, p2])
			var hue = float(i) / segment_count
			var color = Color.from_hsv(hue, 0.6, 0.8, 0.4)
			draw_colored_polygon(points, color)

			# Draw triangle edges
			draw_line(center, p1, color * Color(2, 2, 2, 1), 2.0)
			draw_line(p1, p2, color * Color(2, 2, 2, 1), 2.0)
			draw_line(p2, center, color * Color(2, 2, 2, 1), 2.0)
		else:
			# Draw as smooth circle
			draw_line(p1, p2, TRIANGLE_EDGE_COLOR, 3.0)
			draw_circle(p1, 4, POINT_COLOR)

	# Info
	var mode_text = "TRIANGULATED" if show_triangles else "SMOOTH"
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "%d triangles" % segment_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Mode: %s" % mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))

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

func rotate_point(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
	"""Rotate a point around a pivot"""
	var s = sin(angle)
	var c = cos(angle)
	var p = point - pivot
	return Vector2(p.x * c - p.y * s, p.x * s + p.y * c) + pivot
