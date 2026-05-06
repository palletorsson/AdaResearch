# CubeVisualizationControl.gd
# Visualization for Cube concepts
extends Control

var visualization_type = "basic_cube"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const CUBE_FILL_COLOR = Color(0.4, 0.6, 0.9, 0.5)
const CUBE_EDGE_COLOR = Color(0.5, 0.8, 1.0, 1.0)
const CUBE_FACE_FRONT = Color(0.6, 0.7, 1.0, 0.8)
const CUBE_FACE_SIDE = Color(0.4, 0.5, 0.8, 0.6)
const CUBE_FACE_TOP = Color(0.5, 0.6, 0.9, 0.7)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const COLLISION_COLOR = Color(0.2, 0.9, 0.4, 0.4)
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
		"basic_cube":
			draw_basic_cube(center)
		"cube_wireframe":
			draw_cube_wireframe(center)
		"cube_collision":
			draw_cube_collision(center)

func draw_basic_cube(center: Vector2):
	"""Show a basic cube in isometric view"""
	draw_grid(center)

	# Isometric projection
	var angle = animation_time * 0.3
	var cube_size = 100

	# Define 8 vertices of a cube
	var vertices_3d = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),  # Back face
		Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)  # Front face
	]

	# Project to 2D with rotation
	var vertices_2d = []
	for v in vertices_3d:
		# Rotate around Y axis
		var rotated = Vector3(
			v.x * cos(angle) + v.z * sin(angle),
			v.y,
			-v.x * sin(angle) + v.z * cos(angle)
		)
		# Isometric projection
		var projected = Vector2(
			rotated.x - rotated.z * 0.5,
			rotated.y - rotated.z * 0.3
		) * cube_size * 0.7 + center
		vertices_2d.append(projected)

	# Draw back faces first (painter's algorithm)
	# Back face
	var back_face = PackedVector2Array([vertices_2d[0], vertices_2d[1], vertices_2d[2], vertices_2d[3]])
	draw_colored_polygon(back_face, CUBE_FACE_SIDE * Color(0.7, 0.7, 0.7))

	# Top face
	var top_face = PackedVector2Array([vertices_2d[3], vertices_2d[2], vertices_2d[6], vertices_2d[7]])
	draw_colored_polygon(top_face, CUBE_FACE_TOP)

	# Right face
	var right_face = PackedVector2Array([vertices_2d[1], vertices_2d[5], vertices_2d[6], vertices_2d[2]])
	draw_colored_polygon(right_face, CUBE_FACE_SIDE)

	# Draw edges
	# Back face edges
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[(i + 1) % 4], CUBE_EDGE_COLOR, 2.0)
	# Front face edges
	for i in range(4, 8):
		draw_line(vertices_2d[i], vertices_2d[4 + (i + 1) % 4], CUBE_EDGE_COLOR, 2.0)
	# Connecting edges
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[i + 4], CUBE_EDGE_COLOR, 2.0)

	# Draw vertices
	for v in vertices_2d:
		draw_circle(v, 4, POINT_COLOR)

	# Labels
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "8 vertices", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "6 faces, 12 edges", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_cube_wireframe(center: Vector2):
	"""Show cube mesh structure with triangles"""
	draw_grid(center)

	var angle = animation_time * 0.2
	var cube_size = 90

	# Define vertices
	var vertices_3d = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)
	]

	# Project to 2D
	var vertices_2d = []
	for v in vertices_3d:
		var rotated = Vector3(
			v.x * cos(angle) + v.z * sin(angle),
			v.y,
			-v.x * sin(angle) + v.z * cos(angle)
		)
		var projected = Vector2(
			rotated.x - rotated.z * 0.5,
			rotated.y - rotated.z * 0.3
		) * cube_size * 0.7 + center
		vertices_2d.append(projected)

	# Animate showing triangulation
	var show_triangles = sin(animation_time * 0.5) > 0

	if show_triangles:
		# Draw triangles for front face
		# Triangle 1: 4, 5, 6
		var tri1 = PackedVector2Array([vertices_2d[4], vertices_2d[5], vertices_2d[6]])
		draw_colored_polygon(tri1, Color(0.6, 0.3, 0.9, 0.4))
		draw_line(vertices_2d[4], vertices_2d[5], Color(0.6, 0.3, 0.9), 2.0)
		draw_line(vertices_2d[5], vertices_2d[6], Color(0.6, 0.3, 0.9), 2.0)
		draw_line(vertices_2d[6], vertices_2d[4], Color(0.6, 0.3, 0.9), 2.0)

		# Triangle 2: 4, 6, 7
		var tri2 = PackedVector2Array([vertices_2d[4], vertices_2d[6], vertices_2d[7]])
		draw_colored_polygon(tri2, Color(0.3, 0.6, 0.9, 0.4))
		draw_line(vertices_2d[4], vertices_2d[6], Color(0.3, 0.6, 0.9), 2.0)
		draw_line(vertices_2d[6], vertices_2d[7], Color(0.3, 0.6, 0.9), 2.0)
		draw_line(vertices_2d[7], vertices_2d[4], Color(0.3, 0.6, 0.9), 2.0)

		# Draw triangle labels
		var center1 = (vertices_2d[4] + vertices_2d[5] + vertices_2d[6]) / 3
		var center2 = (vertices_2d[4] + vertices_2d[6] + vertices_2d[7]) / 3
		draw_string(get_theme_default_font(), center1, "1", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.6, 0.3, 0.9))
		draw_string(get_theme_default_font(), center2, "2", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.3, 0.6, 0.9))
	else:
		# Draw solid face
		var front_face = PackedVector2Array([vertices_2d[4], vertices_2d[5], vertices_2d[6], vertices_2d[7]])
		draw_colored_polygon(front_face, CUBE_FACE_FRONT)

	# Draw all edges as wireframe
	# Back face
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[(i + 1) % 4], CUBE_EDGE_COLOR, 1.5)
	# Front face
	for i in range(4, 8):
		draw_line(vertices_2d[i], vertices_2d[4 + (i + 1) % 4], CUBE_EDGE_COLOR, 1.5)
	# Connecting edges
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[i + 4], CUBE_EDGE_COLOR, 1.5)

	# Draw vertices
	for v in vertices_2d:
		draw_circle(v, 3, POINT_COLOR)

	# Info
	var mode = "TRIANGULATED" if show_triangles else "SOLID FACE"
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Mode: %s" % mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "2 triangles per face = 12 total", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_cube_collision(center: Vector2):
	"""Show cube with collision box and intersecting object"""
	draw_grid(center)

	var cube_size = 80
	var angle = animation_time * 0.25

	# Main cube vertices
	var vertices_3d = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)
	]

	# Project main cube
	var vertices_2d = []
	for v in vertices_3d:
		var rotated = Vector3(
			v.x * cos(angle) + v.z * sin(angle),
			v.y,
			-v.x * sin(angle) + v.z * cos(angle)
		)
		var projected = Vector2(
			rotated.x - rotated.z * 0.5,
			rotated.y - rotated.z * 0.3
		) * cube_size * 0.6 + center
		vertices_2d.append(projected)

	# Draw main cube faces
	var front_face = PackedVector2Array([vertices_2d[4], vertices_2d[5], vertices_2d[6], vertices_2d[7]])
	draw_colored_polygon(front_face, CUBE_FILL_COLOR)
	var top_face = PackedVector2Array([vertices_2d[3], vertices_2d[2], vertices_2d[6], vertices_2d[7]])
	draw_colored_polygon(top_face, CUBE_FACE_TOP)

	# Draw collision bounds (slightly larger)
	var collision_scale = 1.2 + sin(animation_time * 2.0) * 0.1
	var collision_verts = []
	for v in vertices_3d:
		var rotated = Vector3(
			v.x * cos(angle) + v.z * sin(angle),
			v.y,
			-v.x * sin(angle) + v.z * cos(angle)
		) * collision_scale
		var projected = Vector2(
			rotated.x - rotated.z * 0.5,
			rotated.y - rotated.z * 0.3
		) * cube_size * 0.6 + center
		collision_verts.append(projected)

	# Draw collision box wireframe
	for i in range(4):
		draw_line(collision_verts[i], collision_verts[(i + 1) % 4], COLLISION_COLOR, 2.0)
	for i in range(4, 8):
		draw_line(collision_verts[i], collision_verts[4 + (i + 1) % 4], COLLISION_COLOR, 2.0)
	for i in range(4):
		draw_line(collision_verts[i], collision_verts[i + 4], COLLISION_COLOR, 2.0)

	# Draw cube edges
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[(i + 1) % 4], CUBE_EDGE_COLOR, 2.0)
	for i in range(4, 8):
		draw_line(vertices_2d[i], vertices_2d[4 + (i + 1) % 4], CUBE_EDGE_COLOR, 2.0)
	for i in range(4):
		draw_line(vertices_2d[i], vertices_2d[i + 4], CUBE_EDGE_COLOR, 2.0)

	# Animated intersecting sphere
	var sphere_pos = center + Vector2(sin(animation_time) * 100, -50)
	var sphere_radius = 30
	draw_circle(sphere_pos, sphere_radius, Color(0.9, 0.4, 0.3, 0.6))
	draw_circle(sphere_pos, sphere_radius, Color(0.9, 0.4, 0.3), false, 2.0)

	# Check if intersecting (simplified 2D check)
	var is_intersecting = sphere_pos.distance_to(center) < (cube_size + sphere_radius)
	var status_color = Color(0.2, 0.9, 0.4) if not is_intersecting else Color(0.9, 0.2, 0.4)
	var status_text = "NO COLLISION" if not is_intersecting else "COLLISION!"

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, status_color)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Volume enables physics", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

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
