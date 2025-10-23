# TorusVisualizationControl.gd
# Visualization for Torus concepts
extends Control

var visualization_type = "basic_torus"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const TORUS_FILL = Color(0.5, 0.7, 0.9, 0.6)
const TORUS_EDGE = Color(0.6, 0.8, 1.0, 1.0)
const INNER_CIRCLE_COLOR = Color(0.9, 0.4, 0.6, 0.8)
const OUTER_CIRCLE_COLOR = Color(0.4, 0.9, 0.6, 0.8)
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
		"basic_torus":
			draw_basic_torus(center)
		"torus_ring_segments":
			draw_torus_ring_segments(center)
		"torus_radial_segments":
			draw_torus_radial_segments(center)
		"torus_tessellation":
			draw_torus_tessellation(center)

func draw_basic_torus(center_pos: Vector2):
	"""Show a torus with labeled radii"""
	draw_grid(center_pos)

	var inner_radius = 80  # Major radius
	var outer_radius = 30  # Minor radius (tube thickness)
	var angle = animation_time * 0.3

	# Draw torus as circles
	# Outer edge of torus
	var max_radius = inner_radius + outer_radius
	draw_circle(center_pos, max_radius, TORUS_FILL)

	# Inner hole
	var min_radius = inner_radius - outer_radius
	if min_radius > 0:
		draw_circle(center_pos, min_radius, BG_COLOR)

	# Draw center circle (major radius path)
	draw_circle(center_pos, inner_radius, Color(0, 0, 0, 0), false, 2.0)
	draw_dashed_circle(center_pos, inner_radius, INNER_CIRCLE_COLOR, 2.0)

	# Draw edges
	draw_circle(center_pos, max_radius, TORUS_EDGE, false, 3.0)
	if min_radius > 0:
		draw_circle(center_pos, min_radius, TORUS_EDGE, false, 3.0)

	# Draw cross-section circle (tube)
	var tube_center = center_pos + Vector2(cos(angle), sin(angle)) * inner_radius
	draw_circle(tube_center, outer_radius, OUTER_CIRCLE_COLOR * Color(1, 1, 1, 0.4))
	draw_circle(tube_center, outer_radius, OUTER_CIRCLE_COLOR, false, 2.0)

	# Draw radii
	# Inner radius (major)
	draw_line(center_pos, center_pos + Vector2(inner_radius, 0), Color(0.9, 0.4, 0.6), 2.0)
	draw_string(get_theme_default_font(), center_pos + Vector2(inner_radius / 2, -15), "inner_radius", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.9, 0.4, 0.6))

	# Outer radius (minor)
	draw_line(tube_center, tube_center + Vector2(0, -outer_radius), Color(0.4, 0.9, 0.6), 2.0)
	draw_string(get_theme_default_font(), tube_center + Vector2(10, -outer_radius / 2), "outer", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.9, 0.6))

	# Center point
	draw_circle(center_pos, 5, Color(1.0, 0.9, 0.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Donut = big ring + small tube", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_torus_ring_segments(center_pos: Vector2):
	"""Show torus with animated ring segments"""
	draw_grid(center_pos)

	var inner_radius = 80
	var outer_radius = 30

	# Animate segment count
	var ring_segments = int(6 + (sin(animation_time * 0.5) + 1) * 10)  # 6 to 26
	ring_segments = clampi(ring_segments, 6, 26)

	# Draw torus outline
	var max_radius = inner_radius + outer_radius
	var min_radius = inner_radius - outer_radius

	# Draw tube cross-sections around the ring
	for i in range(ring_segments):
		var angle = (float(i) / ring_segments) * TAU
		var tube_center = center_pos + Vector2(cos(angle), sin(angle)) * inner_radius

		# Draw tube polygon
		var tube_points = PackedVector2Array()
		var tube_detail = 12
		for j in range(tube_detail):
			var tube_angle = (float(j) / tube_detail) * TAU
			var point = tube_center + Vector2(cos(tube_angle), sin(tube_angle)) * outer_radius
			tube_points.append(point)

		draw_colored_polygon(tube_points, TORUS_FILL)
		draw_circle(tube_center, outer_radius, TORUS_EDGE, false, 1.5)

		# Draw connection to center
		if i % 4 == 0:  # Only every 4th for clarity
			draw_line(center_pos, tube_center, Color(0.9, 0.4, 0.6, 0.3), 1.0)

	# Draw center reference
	draw_dashed_circle(center_pos, inner_radius, INNER_CIRCLE_COLOR, 2.0)
	draw_circle(center_pos, 4, Color(1.0, 0.9, 0.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Ring segments: %d" % ring_segments, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Defines tube smoothness", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_torus_radial_segments(center_pos: Vector2):
	"""Show torus with animated radial segments"""
	draw_grid(center_pos)

	var inner_radius = 80
	var outer_radius = 30

	# Animate radial segment count
	var radial_segments = int(6 + (sin(animation_time * 0.5) + 1) * 10)  # 6 to 26
	radial_segments = clampi(radial_segments, 6, 26)

	# Draw torus with radial divisions
	var max_radius = inner_radius + outer_radius
	var min_radius = max(inner_radius - outer_radius, 0)

	# Draw filled torus
	draw_circle(center_pos, max_radius, TORUS_FILL)
	if min_radius > 0:
		draw_circle(center_pos, min_radius, BG_COLOR)

	# Draw radial lines
	for i in range(radial_segments):
		var angle = (float(i) / radial_segments) * TAU
		var inner_point = center_pos + Vector2(cos(angle), sin(angle)) * min_radius
		var outer_point = center_pos + Vector2(cos(angle), sin(angle)) * max_radius
		draw_line(inner_point, outer_point, TORUS_EDGE, 2.0)

	# Draw edges
	draw_circle(center_pos, max_radius, TORUS_EDGE, false, 3.0)
	if min_radius > 0:
		draw_circle(center_pos, min_radius, TORUS_EDGE, false, 3.0)

	# Draw center
	draw_circle(center_pos, 5, Color(1.0, 0.9, 0.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Radial segments: %d" % radial_segments, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Defines ring smoothness", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_torus_tessellation(center_pos: Vector2):
	"""Show complete tessellation"""
	draw_grid(center_pos)

	var inner_radius = 80
	var outer_radius = 30

	# Animate between low and high resolution
	var t = (sin(animation_time * 0.5) + 1.0) / 2.0
	var ring_segments = int(lerp(4.0, 24.0, t))
	var radial_segments = int(lerp(6.0, 18.0, t))

	# Draw simplified 2D torus with grid
	var max_radius = inner_radius + outer_radius
	var min_radius = max(inner_radius - outer_radius, 0)

	# Draw tube cross-sections
	for i in range(radial_segments):
		var angle = (float(i) / radial_segments) * TAU
		var tube_center = center_pos + Vector2(cos(angle), sin(angle)) * inner_radius

		# Draw tube with ring segments
		var prev_point = Vector2.ZERO
		for j in range(ring_segments + 1):
			var tube_angle = (float(j) / ring_segments) * TAU
			var point = tube_center + Vector2(cos(tube_angle), sin(tube_angle)) * outer_radius

			if j > 0:
				draw_line(prev_point, point, TORUS_EDGE, 1.0)

			prev_point = point

	# Draw radial lines
	for i in range(radial_segments):
		var angle = (float(i) / radial_segments) * TAU
		var inner_point = center_pos + Vector2(cos(angle), sin(angle)) * min_radius
		var outer_point = center_pos + Vector2(cos(angle), sin(angle)) * max_radius
		draw_line(inner_point, outer_point, Color(0.9, 0.4, 0.6, 0.5), 1.0)

	# Highlight a few vertices
	for i in range(0, radial_segments, max(radial_segments / 6, 1)):
		var angle = (float(i) / radial_segments) * TAU
		var tube_center = center_pos + Vector2(cos(angle), sin(angle)) * inner_radius
		for j in range(0, ring_segments, max(ring_segments / 4, 1)):
			var tube_angle = (float(j) / ring_segments) * TAU
			var point = tube_center + Vector2(cos(tube_angle), sin(tube_angle)) * outer_radius
			draw_circle(point, 3, Color(1.0, 0.9, 0.2))

	# Draw outer edges
	draw_circle(center_pos, max_radius, TORUS_EDGE, false, 2.0)
	if min_radius > 0:
		draw_circle(center_pos, min_radius, TORUS_EDGE, false, 2.0)

	# Center
	draw_circle(center_pos, 4, Color(1.0, 0.9, 0.2))

	# Calculate triangle count
	var triangle_count = ring_segments * radial_segments * 2

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 60), "Ring: %d, Radial: %d" % [ring_segments, radial_segments], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Triangles: %d" % triangle_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Low res reveals structure", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_grid(center_pos: Vector2):
	"""Draw a subtle grid"""
	var half_size = GRID_SIZE / 2

	# Vertical lines
	for x in range(-int(half_size), int(half_size), GRID_SPACING):
		var start = center_pos + Vector2(x, -half_size)
		var end = center_pos + Vector2(x, half_size)
		draw_line(start, end, GRID_COLOR, 1.0)

	# Horizontal lines
	for y in range(-int(half_size), int(half_size), GRID_SPACING):
		var start = center_pos + Vector2(-half_size, y)
		var end = center_pos + Vector2(half_size, y)
		draw_line(start, end, GRID_COLOR, 1.0)

func draw_dashed_circle(center_pos: Vector2, radius: float, color: Color, width: float):
	"""Draw a dashed circle"""
	var segments = 32
	var dash_length = 0.7  # 70% line, 30% gap
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU
		var angle2 = (float(i) + dash_length) / segments * TAU
		var p1 = center_pos + Vector2(cos(angle1), sin(angle1)) * radius
		var p2 = center_pos + Vector2(cos(angle2), sin(angle2)) * radius
		draw_line(p1, p2, color, width)
