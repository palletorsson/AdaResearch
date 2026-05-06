# SphereVisualizationControl.gd
# Visualization for Sphere concepts
extends Control

var visualization_type = "basic_sphere"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const SPHERE_COLOR = Color(0.5, 0.7, 1.0, 0.8)
const SPHERE_OUTLINE = Color(0.6, 0.8, 1.0, 1.0)
const WIREFRAME_COLOR = Color(0.3, 0.6, 0.9, 0.7)
const NORMAL_COLOR = Color(0.9, 0.4, 0.6, 0.9)
const CENTER_COLOR = Color(1.0, 0.9, 0.2, 1.0)
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
		"basic_sphere":
			draw_basic_sphere(center)
		"sphere_tessellation":
			draw_sphere_tessellation(center)
		"sphere_normals":
			draw_sphere_normals(center)

func draw_basic_sphere(center: Vector2):
	"""Show a basic sphere with radius"""
	draw_grid(center)

	# Pulsing sphere
	var base_radius = 100
	var radius = base_radius + sin(animation_time * 2.0) * 15

	# Draw sphere
	draw_circle(center, radius, SPHERE_COLOR)
	draw_circle(center, radius, SPHERE_OUTLINE, false, 3.0)

	# Draw center point
	draw_circle(center, 6, CENTER_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(15, -10), "center", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CENTER_COLOR)

	# Draw radius line
	var radius_end = center + Vector2(cos(animation_time * 0.5), sin(animation_time * 0.5)) * radius
	draw_line(center, radius_end, Color(1.0, 0.9, 0.2, 0.8), 2.0)
	draw_circle(radius_end, 5, Color(1.0, 0.9, 0.2))

	# Radius label
	var mid_radius = (center + radius_end) / 2
	draw_string(get_theme_default_font(), mid_radius + Vector2(10, -10), "radius", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.2))

	# Draw cross-section circles to show 3D
	var ellipse_scale = 0.4
	draw_arc(center, radius, 0, TAU, 32, WIREFRAME_COLOR, 2.0)
	draw_arc_ellipse(center, radius, radius * ellipse_scale, 0, TAU, 32, WIREFRAME_COLOR, 2.0)

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "All points equidistant from center", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Radius: %.1f" % (radius / 10.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))

func draw_sphere_tessellation(center: Vector2):
	"""Show sphere tessellation with lat/long lines"""
	draw_grid(center)

	var radius = 110
	var angle = animation_time * 0.3

	# Animate segment count
	var segments = int(8 + (sin(animation_time * 0.4) + 1) * 8)  # 8 to 24
	segments = clampi(segments, 8, 24)

	# Draw tessellation as wireframe
	# Latitude lines
	var lat_count = segments / 2
	for i in range(1, lat_count):
		var lat_angle = (float(i) / lat_count) * PI
		var lat_radius = radius * sin(lat_angle)
		var lat_y = -radius * cos(lat_angle)
		draw_circle(center + Vector2(0, lat_y), lat_radius, WIREFRAME_COLOR, false, 1.5)

	# Longitude lines (great circles)
	var lon_count = segments
	for i in range(lon_count):
		var lon_angle = (float(i) / lon_count) * TAU + angle
		var points = PackedVector2Array()
		for j in range(segments + 1):
			var lat_angle = (float(j) / segments) * PI
			var x = radius * sin(lat_angle) * cos(lon_angle)
			var y = -radius * cos(lat_angle)
			var z = radius * sin(lat_angle) * sin(lon_angle)
			# Simple 3D to 2D projection
			var proj_x = x
			var proj_y = y + z * 0.3
			points.append(center + Vector2(proj_x, proj_y))
		draw_polyline(points, WIREFRAME_COLOR, 1.5)

	# Draw outer circle
	draw_circle(center, radius, SPHERE_OUTLINE, false, 3.0)

	# Draw vertices at intersections (sample)
	var vertex_count = 0
	for lat_i in range(lat_count + 1):
		var lat_angle = (float(lat_i) / lat_count) * PI
		for lon_i in range(lon_count):
			var lon_angle = (float(lon_i) / lon_count) * TAU + angle
			var x = radius * sin(lat_angle) * cos(lon_angle)
			var y = -radius * cos(lat_angle)
			var z = radius * sin(lat_angle) * sin(lon_angle)
			if z > 0:  # Only front vertices
				var proj_x = x
				var proj_y = y + z * 0.3
				draw_circle(center + Vector2(proj_x, proj_y), 2, CENTER_COLOR)
				vertex_count += 1

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 60), "Segments: %d" % segments, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Approx. triangles: %d" % (segments * segments * 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "More segments = smoother", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_sphere_normals(center: Vector2):
	"""Show sphere with surface normals pointing outward"""
	draw_grid(center)

	var radius = 100

	# Draw sphere
	draw_circle(center, radius, SPHERE_COLOR)
	draw_circle(center, radius, SPHERE_OUTLINE, false, 2.0)

	# Draw center
	draw_circle(center, 5, CENTER_COLOR)

	# Draw normals at various points
	var normal_count = 12
	for i in range(normal_count):
		var angle = (float(i) / normal_count) * TAU + animation_time * 0.5
		var surface_point = center + Vector2(cos(angle), sin(angle)) * radius

		# Normal direction (points away from center)
		var normal_dir = (surface_point - center).normalized()
		var normal_end = surface_point + normal_dir * 40

		# Draw normal vector
		draw_arrow(surface_point, normal_end, NORMAL_COLOR, 2.0)

		# Draw surface point
		draw_circle(surface_point, 4, Color(1.0, 0.9, 0.2))

	# Highlight one normal with label
	var highlight_angle = animation_time * 0.5
	var highlight_point = center + Vector2(cos(highlight_angle), sin(highlight_angle)) * radius
	var highlight_normal = (highlight_point - center).normalized()
	var highlight_end = highlight_point + highlight_normal * 50

	draw_arrow(highlight_point, highlight_end, Color(1.0, 0.3, 0.6), 3.0)
	draw_circle(highlight_point, 6, Color(1.0, 0.9, 0.2))

	# Label
	draw_string(get_theme_default_font(), highlight_end + Vector2(5, -5), "normal", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.3, 0.6))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Normal = (P - center).normalized()", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Always points radially outward", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

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

func draw_arc_ellipse(center_pos: Vector2, radius_x: float, radius_y: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float = 1.0):
	"""Draw an elliptical arc"""
	var points = PackedVector2Array()
	for i in range(point_count + 1):
		var angle = start_angle + (end_angle - start_angle) * (float(i) / point_count)
		var x = radius_x * cos(angle)
		var y = radius_y * sin(angle)
		points.append(center_pos + Vector2(x, y))
	draw_polyline(points, color, width)
