# QuadVisualizationControl.gd
# Visualization for Quad concepts
extends Control

var visualization_type = "basic_quad"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const QUAD_FILL_COLOR = Color(0.3, 0.7, 0.9, 0.4)
const QUAD_EDGE_COLOR = Color(0.3, 0.8, 1.0, 1.0)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const DIAGONAL_COLOR = Color(0.9, 0.3, 0.6, 0.8)
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
		"basic_quad":
			draw_basic_quad(center)
		"quad_triangulation":
			draw_quad_triangulation(center)
		"quad_topology":
			draw_quad_topology(center)

func draw_basic_quad(center: Vector2):
	"""Show a basic quad with four coplanar vertices"""
	draw_grid(center)

	# Define four vertices of a quad
	var scale = 1.0 + sin(animation_time * 0.5) * 0.1
	var v0 = center + Vector2(-100, -80) * scale
	var v1 = center + Vector2(100, -80) * scale
	var v2 = center + Vector2(100, 80) * scale
	var v3 = center + Vector2(-100, 80) * scale

	# Draw filled quad
	var points = PackedVector2Array([v0, v1, v2, v3])
	draw_colored_polygon(points, QUAD_FILL_COLOR)

	# Draw edges
	draw_line(v0, v1, QUAD_EDGE_COLOR, 3.0)
	draw_line(v1, v2, QUAD_EDGE_COLOR, 3.0)
	draw_line(v2, v3, QUAD_EDGE_COLOR, 3.0)
	draw_line(v3, v0, QUAD_EDGE_COLOR, 3.0)

	# Draw vertices with pulse
	var pulse = 1.0 + sin(animation_time * 2.0) * 0.2
	draw_circle(v0, 8 * pulse, POINT_COLOR)
	draw_circle(v1, 8 * pulse, POINT_COLOR)
	draw_circle(v2, 8 * pulse, POINT_COLOR)
	draw_circle(v3, 8 * pulse, POINT_COLOR)

	# Draw labels
	draw_string(get_theme_default_font(), v0 + Vector2(-30, -15), "v0", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), v1 + Vector2(15, -15), "v1", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), v2 + Vector2(15, 20), "v2", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), v3 + Vector2(-30, 20), "v3", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

	# Info text
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Four coplanar points define a quad", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_quad_triangulation(center: Vector2):
	"""Show how a quad is triangulated into two triangles"""
	draw_grid(center)

	# Define quad vertices
	var v0 = center + Vector2(-100, -80)
	var v1 = center + Vector2(100, -80)
	var v2 = center + Vector2(100, 80)
	var v3 = center + Vector2(-100, 80)

	# Animate between showing triangulation and full quad
	var show_split = sin(animation_time * 0.8) > 0

	if show_split:
		# Draw Triangle 1: v0, v1, v2
		var tri1 = PackedVector2Array([v0, v1, v2])
		draw_colored_polygon(tri1, Color(0.3, 0.7, 0.9, 0.4))
		draw_line(v0, v1, Color(0.3, 0.8, 1.0), 3.0)
		draw_line(v1, v2, Color(0.3, 0.8, 1.0), 3.0)
		draw_line(v2, v0, DIAGONAL_COLOR, 3.0)  # Diagonal

		# Draw Triangle 2: v0, v2, v3
		var tri2 = PackedVector2Array([v0, v2, v3])
		draw_colored_polygon(tri2, Color(0.7, 0.3, 0.9, 0.4))
		draw_line(v0, v2, DIAGONAL_COLOR, 3.0)  # Diagonal
		draw_line(v2, v3, Color(0.7, 0.3, 0.9), 3.0)
		draw_line(v3, v0, Color(0.7, 0.3, 0.9), 3.0)

		# Label triangles
		var center1 = (v0 + v1 + v2) / 3
		var center2 = (v0 + v2 + v3) / 3
		draw_string(get_theme_default_font(), center1, "Tri 1", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.3, 0.8, 1.0))
		draw_string(get_theme_default_font(), center2, "Tri 2", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.7, 0.3, 0.9))

		# Diagonal label
		var mid_diag = (v0 + v2) / 2
		draw_string(get_theme_default_font(), mid_diag + Vector2(15, -15), "diagonal", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, DIAGONAL_COLOR)
	else:
		# Draw as whole quad
		var points = PackedVector2Array([v0, v1, v2, v3])
		draw_colored_polygon(points, QUAD_FILL_COLOR)
		draw_line(v0, v1, QUAD_EDGE_COLOR, 3.0)
		draw_line(v1, v2, QUAD_EDGE_COLOR, 3.0)
		draw_line(v2, v3, QUAD_EDGE_COLOR, 3.0)
		draw_line(v3, v0, QUAD_EDGE_COLOR, 3.0)

		# Center label
		draw_string(get_theme_default_font(), center, "Quad", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, LABEL_COLOR)

	# Draw vertices
	draw_circle(v0, 6, POINT_COLOR)
	draw_circle(v1, 6, POINT_COLOR)
	draw_circle(v2, 6, POINT_COLOR)
	draw_circle(v3, 6, POINT_COLOR)

	# Info
	var mode = "TRIANGULATED" if show_split else "UNIFIED"
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Mode: %s (2 triangles)" % mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))

func draw_quad_topology(center: Vector2):
	"""Show quads in mesh topology with subdivision"""
	draw_grid(center)

	# Create a grid of quads
	var cols = 3
	var rows = 3
	var quad_size = 60
	var spacing = 10

	# Animate subdivision level
	var subdiv_level = int(animation_time * 0.3) % 2

	for row in range(rows):
		for col in range(cols):
			var x_offset = (col - 1) * (quad_size + spacing)
			var y_offset = (row - 1) * (quad_size + spacing)

			var base_pos = center + Vector2(x_offset, y_offset)

			if subdiv_level == 0:
				# Draw single quad
				draw_single_quad(base_pos, quad_size)
			else:
				# Draw subdivided (4 smaller quads)
				var half = quad_size / 2.0
				draw_single_quad(base_pos + Vector2(-half/2, -half/2), half)
				draw_single_quad(base_pos + Vector2(half/2, -half/2), half)
				draw_single_quad(base_pos + Vector2(half/2, half/2), half)
				draw_single_quad(base_pos + Vector2(-half/2, half/2), half)

	# Info
	var subdiv_text = "Subdivision Level: %d" % subdiv_level
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), subdiv_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Quads enable clean topology", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_single_quad(pos: Vector2, size_val: float):
	"""Helper to draw a single quad centered at pos"""
	var half = size_val / 2.0
	var v0 = pos + Vector2(-half, -half)
	var v1 = pos + Vector2(half, -half)
	var v2 = pos + Vector2(half, half)
	var v3 = pos + Vector2(-half, half)

	# Draw filled quad
	var points = PackedVector2Array([v0, v1, v2, v3])
	draw_colored_polygon(points, QUAD_FILL_COLOR)

	# Draw edges
	draw_line(v0, v1, QUAD_EDGE_COLOR, 2.0)
	draw_line(v1, v2, QUAD_EDGE_COLOR, 2.0)
	draw_line(v2, v3, QUAD_EDGE_COLOR, 2.0)
	draw_line(v3, v0, QUAD_EDGE_COLOR, 2.0)

	# Draw vertices
	draw_circle(v0, 3, POINT_COLOR)
	draw_circle(v1, 3, POINT_COLOR)
	draw_circle(v2, 3, POINT_COLOR)
	draw_circle(v3, 3, POINT_COLOR)

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
