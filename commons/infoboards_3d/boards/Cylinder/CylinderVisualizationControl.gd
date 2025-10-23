# CylinderVisualizationControl.gd
# Visualization for Cylinder concepts
extends Control

var visualization_type = "basic_cylinder"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const CYLINDER_SIDE = Color(0.5, 0.7, 0.9, 0.7)
const CYLINDER_CAP_TOP = Color(0.6, 0.8, 1.0, 0.8)
const CYLINDER_CAP_BOTTOM = Color(0.4, 0.6, 0.8, 0.6)
const CYLINDER_EDGE = Color(0.6, 0.8, 1.0, 1.0)
const AXIS_COLOR = Color(1.0, 0.9, 0.2, 0.9)
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
		"basic_cylinder":
			draw_basic_cylinder(center)
		"cylinder_parts":
			draw_cylinder_parts(center)
		"cylinder_segments":
			draw_cylinder_segments(center)

func draw_basic_cylinder(center: Vector2):
	"""Show a basic cylinder with rotation"""
	draw_grid(center)

	var height = 160
	var radius = 70
	var angle = animation_time * 0.4

	# Top and bottom center points
	var top_center = center + Vector2(0, -height / 2)
	var bottom_center = center + Vector2(0, height / 2)

	# Draw bottom cap first (painter's algorithm)
	draw_ellipse(bottom_center, radius, radius * 0.4, CYLINDER_CAP_BOTTOM)

	# Draw cylinder side
	var segments = 32
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU + angle
		var angle2 = (float(i + 1) / segments) * TAU + angle

		# Only draw visible segments (back half)
		var cos1 = cos(angle1)
		var cos2 = cos(angle2)

		# Side vertices
		var top1 = top_center + Vector2(radius * cos1, radius * sin(angle1) * 0.4)
		var top2 = top_center + Vector2(radius * cos2, radius * sin(angle2) * 0.4)
		var bottom1 = bottom_center + Vector2(radius * cos1, radius * sin(angle1) * 0.4)
		var bottom2 = bottom_center + Vector2(radius * cos2, radius * sin(angle2) * 0.4)

		# Draw quad (side face)
		var points = PackedVector2Array([bottom1, bottom2, top2, top1])
		draw_colored_polygon(points, CYLINDER_SIDE)
		draw_line(bottom1, top1, CYLINDER_EDGE, 1.0)

	# Draw top cap
	draw_ellipse(top_center, radius, radius * 0.4, CYLINDER_CAP_TOP)

	# Draw outlines
	draw_arc_ellipse(top_center, radius, radius * 0.4, 0, TAU, 32, CYLINDER_EDGE, 2.0)
	draw_arc_ellipse(bottom_center, radius, radius * 0.4, 0, TAU, 32, CYLINDER_EDGE, 2.0)

	# Draw axis
	draw_line(top_center, bottom_center, AXIS_COLOR, 2.0)
	draw_circle(top_center, 5, AXIS_COLOR)
	draw_circle(bottom_center, 5, AXIS_COLOR)

	# Labels
	draw_string(get_theme_default_font(), top_center + Vector2(radius + 15, 0), "top", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LABEL_COLOR)
	draw_string(get_theme_default_font(), bottom_center + Vector2(radius + 15, 0), "bottom", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LABEL_COLOR)

	# Radius line
	var radius_end = bottom_center + Vector2(radius, 0)
	draw_line(bottom_center, radius_end, Color(1.0, 0.9, 0.2, 0.6), 1.5)
	draw_string(get_theme_default_font(), (bottom_center + radius_end) / 2 + Vector2(0, -10), "r", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.9, 0.2))

	# Height line
	var height_x = center.x + radius + 40
	draw_line(Vector2(height_x, top_center.y), Vector2(height_x, bottom_center.y), Color(1.0, 0.9, 0.2, 0.6), 1.5)
	draw_string(get_theme_default_font(), Vector2(height_x + 10, center.y), "h", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Extruded circle along axis", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_cylinder_parts(center: Vector2):
	"""Show cylinder with varying radii (cone)"""
	draw_grid(center)

	var height = 160
	var angle = animation_time * 0.3

	# Animate between cylinder and cone
	var top_radius = 60 + sin(animation_time * 0.5) * 30
	var bottom_radius = 80

	var top_center = center + Vector2(0, -height / 2)
	var bottom_center = center + Vector2(0, height / 2)

	# Draw bottom cap
	draw_ellipse(bottom_center, bottom_radius, bottom_radius * 0.4, CYLINDER_CAP_BOTTOM)

	# Draw side
	var segments = 32
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU + angle
		var angle2 = (float(i + 1) / segments) * TAU + angle

		var cos1 = cos(angle1)
		var cos2 = cos(angle2)

		var top1 = top_center + Vector2(top_radius * cos1, top_radius * sin(angle1) * 0.4)
		var top2 = top_center + Vector2(top_radius * cos2, top_radius * sin(angle2) * 0.4)
		var bottom1 = bottom_center + Vector2(bottom_radius * cos1, bottom_radius * sin(angle1) * 0.4)
		var bottom2 = bottom_center + Vector2(bottom_radius * cos2, bottom_radius * sin(angle2) * 0.4)

		var points = PackedVector2Array([bottom1, bottom2, top2, top1])
		draw_colored_polygon(points, CYLINDER_SIDE)
		draw_line(bottom1, top1, CYLINDER_EDGE, 1.0)

	# Draw top cap
	draw_ellipse(top_center, top_radius, top_radius * 0.4, CYLINDER_CAP_TOP)

	# Draw outlines
	draw_arc_ellipse(top_center, top_radius, top_radius * 0.4, 0, TAU, 32, CYLINDER_EDGE, 2.0)
	draw_arc_ellipse(bottom_center, bottom_radius, bottom_radius * 0.4, 0, TAU, 32, CYLINDER_EDGE, 2.0)

	# Labels
	draw_string(get_theme_default_font(), top_center + Vector2(top_radius + 15, 0), "top_radius", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), bottom_center + Vector2(bottom_radius + 15, 0), "bottom_radius", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.2))

	# Radius lines
	draw_line(top_center, top_center + Vector2(top_radius, 0), Color(1.0, 0.9, 0.2, 0.6), 1.5)
	draw_line(bottom_center, bottom_center + Vector2(bottom_radius, 0), Color(1.0, 0.9, 0.2, 0.6), 1.5)

	# Info
	var is_cone = abs(top_radius - bottom_radius) > 10
	var shape_name = "Cone" if is_cone else "Cylinder"
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Shape: %s (varying radii)" % shape_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))

func draw_cylinder_segments(center: Vector2):
	"""Show cylinder tessellation with segments"""
	draw_grid(center)

	var height = 140
	var radius = 70

	# Animate segment count
	var radial_segments = int(6 + (sin(animation_time * 0.4) + 1) * 10)  # 6 to 26
	radial_segments = clampi(radial_segments, 6, 26)

	var rings = 6

	var top_center = center + Vector2(0, -height / 2)
	var bottom_center = center + Vector2(0, height / 2)

	# Draw wireframe tessellation
	# Horizontal rings
	for ring in range(rings + 1):
		var y = lerp(top_center.y, bottom_center.y, float(ring) / rings)
		var ring_center = Vector2(center.x, y)
		draw_arc_ellipse(ring_center, radius, radius * 0.4, 0, TAU, 32, CYLINDER_EDGE, 1.5)

	# Vertical segments
	for i in range(radial_segments):
		var angle = (float(i) / radial_segments) * TAU
		var x_offset = radius * cos(angle)
		var z_offset = radius * sin(angle) * 0.4

		# Draw line from top to bottom
		var top_point = top_center + Vector2(x_offset, z_offset)
		var bottom_point = bottom_center + Vector2(x_offset, z_offset)
		draw_line(top_point, bottom_point, CYLINDER_EDGE, 1.5)

		# Draw vertices
		for ring in range(rings + 1):
			var y = lerp(top_center.y, bottom_center.y, float(ring) / rings)
			var vertex_pos = Vector2(center.x + x_offset, y + z_offset)
			draw_circle(vertex_pos, 2, Color(1.0, 0.9, 0.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 60), "Radial segments: %d" % radial_segments, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Rings: %d" % rings, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "More segments = smoother", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_ellipse(pos: Vector2, radius_x: float, radius_y: float, color: Color):
	"""Draw a filled ellipse"""
	var segments = 32
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		var x = radius_x * cos(angle)
		var y = radius_y * sin(angle)
		points.append(pos + Vector2(x, y))
	draw_colored_polygon(points, color)

func draw_arc_ellipse(center_pos: Vector2, radius_x: float, radius_y: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float = 1.0):
	"""Draw an elliptical arc"""
	var points = PackedVector2Array()
	for i in range(point_count + 1):
		var angle = start_angle + (end_angle - start_angle) * (float(i) / point_count)
		var x = radius_x * cos(angle)
		var y = radius_y * sin(angle)
		points.append(center_pos + Vector2(x, y))
	draw_polyline(points, color, width)

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
