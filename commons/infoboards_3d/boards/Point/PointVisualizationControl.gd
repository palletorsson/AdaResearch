# PointVisualizationControl.gd
# Visualization for Point concepts
extends Control

var visualization_type = "origin"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const AXIS_X_COLOR = Color(0.8, 0.2, 0.2, 0.8)
const AXIS_Y_COLOR = Color(0.2, 0.8, 0.2, 0.8)
const AXIS_Z_COLOR = Color(0.2, 0.2, 0.8, 0.8)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const LABEL_COLOR = Color(0.9, 0.9, 1.0, 1.0)

const GRID_SIZE = 400
const GRID_SPACING = 40
const AXIS_LENGTH = 180

func _ready():
	custom_minimum_size = Vector2(400, 400)

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	
	# Center of the visualization
	var center = size / 2
	
	match visualization_type:
		"origin":
			draw_origin_visualization(center)
		"point_example":
			draw_point_example(center)
		"point_sizes":
			draw_point_sizes_visualization(center)
		"instantiation":
			draw_instantiation_visualization(center)
		"labels":
			draw_labels_visualization(center)
		"dynamic":
			draw_dynamic_visualization(center)

func draw_origin_visualization(center: Vector2):
	"""Show the origin point and coordinate system"""
	# Draw grid
	draw_grid(center)
	
	# Draw axes
	draw_axes(center)
	
	# Draw origin point with pulsing effect
	var pulse = 1.0 + sin(animation_time * 2.0) * 0.3
	var origin_radius = 8 * pulse
	draw_circle(center, origin_radius, POINT_COLOR)
	
	# Draw label for origin
	var label_text = "(0, 0, 0)"
	var label_pos = center + Vector2(15, -15)
	draw_string(get_theme_default_font(), label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LABEL_COLOR)
	
	# Draw coordinate labels
	draw_string(get_theme_default_font(), center + Vector2(AXIS_LENGTH + 10, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AXIS_X_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(5, -AXIS_LENGTH - 10), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AXIS_Y_COLOR)
	
	# Draw info text
	var info = "The origin (0,0,0) is the root of all vectors"
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_point_sizes_visualization(center: Vector2):
	"""Compare different point sizes"""
	draw_grid(center)
	draw_axes(center)
	
	# Show different point sizes
	var sizes = [
		{"radius": 2, "label": "0.005m (5mm)", "offset": -120},
		{"radius": 4, "label": "0.01m (1cm)", "offset": -40},
		{"radius": 8, "label": "0.02m (2cm)", "offset": 40},
		{"radius": 12, "label": "0.03m (3cm)", "offset": 120}
	]
	
	for size_data in sizes:
		var pos = center + Vector2(size_data.offset, 0)
		
		# Draw point
		var pulse = 1.0 + sin(animation_time * 2.0 + size_data.offset * 0.01) * 0.1
		draw_circle(pos, size_data.radius * pulse, POINT_COLOR)
		
		# Draw label below
		var label_pos = pos + Vector2(0, 40)
		draw_string(get_theme_default_font(), label_pos, size_data.label, HORIZONTAL_ALIGNMENT_CENTER, 80, 12, LABEL_COLOR)

func draw_instantiation_visualization(center: Vector2):
	"""Show how a mesh resource becomes live MeshInstance3D nodes"""
	draw_grid(center)
	draw_axes(center)

	var resource_pos = center + Vector2(-150, -30)
	draw_circle(resource_pos, 20, Color(POINT_COLOR.r, POINT_COLOR.g, POINT_COLOR.b, 0.15))
	draw_circle(resource_pos, 8, Color(POINT_COLOR.r, POINT_COLOR.g, POINT_COLOR.b, 0.25))
	draw_string(get_theme_default_font(), resource_pos + Vector2(-70, 36), "SphereMesh resource", HORIZONTAL_ALIGNMENT_LEFT, 160, 12, Color(0.8, 0.8, 0.9, 0.8))

	var instance_pos = center + Vector2(40, -20)
	draw_arrow(resource_pos + Vector2(25, 0), instance_pos - Vector2(12, 0), Color(0.6, 0.75, 1.0, 0.6), 2.0)

	draw_circle(instance_pos, 10, POINT_COLOR)
	draw_string(get_theme_default_font(), instance_pos + Vector2(-40, 26), "MeshInstance3D", HORIZONTAL_ALIGNMENT_LEFT, 120, 12, LABEL_COLOR)

	var offsets = [Vector2(90, 30), Vector2(110, -20), Vector2(70, -70)]
	for extra in offsets:
		var pos = center + extra
		draw_circle(pos, 8, Color(POINT_COLOR.r, POINT_COLOR.g, POINT_COLOR.b, 0.85))
		draw_line(instance_pos, pos, Color(0.45, 0.55, 0.8, 0.35), 1.4)

	draw_string(get_theme_default_font(), center + Vector2(-110, 120), "add_child(mesh_instance) attaches nodes to the scene tree", HORIZONTAL_ALIGNMENT_LEFT, 280, 12, Color(0.75, 0.75, 0.9, 0.85))

func draw_labels_visualization(center: Vector2):
	"""Show a point with Label3D positioned using an offset"""
	draw_grid(center)
	draw_axes(center)

	var point_pos = center + Vector2(80, -40)
	draw_circle(point_pos, 8, POINT_COLOR)

	var offset = Vector2(0, -45)
	draw_line(point_pos, point_pos + offset, Color(0.5, 0.8, 1.0, 0.4), 1.5)

	var label_rect = Rect2(point_pos + offset - Vector2(70, 18), Vector2(140, 36))
	draw_rect(label_rect, Color(0.1, 0.12, 0.2, 0.85), true)
	draw_rect(label_rect, Color(0.45, 0.55, 0.8, 0.6), false, 1.0)
	draw_string(get_theme_default_font(), label_rect.position + Vector2(10, 12), "Label3D\n(0, 0.15, 0) offset", HORIZONTAL_ALIGNMENT_LEFT, 120, 12, LABEL_COLOR)

	draw_string(get_theme_default_font(), center + Vector2(-150, 120), "Label follows point thanks to billboard & offset vector", HORIZONTAL_ALIGNMENT_LEFT, 320, 12, Color(0.75, 0.8, 1.0, 0.85))

func draw_dynamic_visualization(center: Vector2):
	"""Show moving points with updating labels"""
	draw_grid(center)
	draw_axes(center)
	
	# Create moving points
	var point_count = 4
	
	for i in range(point_count):
		var angle = (float(i) / point_count) * TAU + animation_time * 0.8
		var radius = 80 + sin(animation_time * 1.5 + i) * 30
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var pos = center + offset
		
		# Draw trail
		var trail_length = 20
		for j in range(trail_length):
			var trail_angle = angle - (float(j) / trail_length) * 0.5
			var trail_offset = Vector2(cos(trail_angle), sin(trail_angle)) * (radius - j * 2)
			var trail_pos = center + trail_offset
			var trail_alpha = 1.0 - (float(j) / trail_length)
			draw_circle(trail_pos, 3 * trail_alpha, Color(POINT_COLOR.r, POINT_COLOR.g, POINT_COLOR.b, trail_alpha * 0.3))
		
		# Draw point
		draw_circle(pos, 8, POINT_COLOR)
		
		# Draw velocity vector
		var velocity = offset.normalized() * 30
		draw_arrow(pos, pos + velocity, Color(0.2, 0.8, 0.8, 0.8), 2.0)
		
		# Draw updating label
		var coord = "(" + str(snappedf(offset.x / 100, 0.1)) + ", " + str(snappedf(offset.y / 100, 0.1)) + ")"
		var label_pos = pos + Vector2(0, -20)
		draw_string(get_theme_default_font(), label_pos, coord, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, LABEL_COLOR)

func draw_grid(center: Vector2):
	"""Draw a subtle grid"""
	# Vertical lines
	var half_grid = GRID_SIZE / 2.0
	for x in range(int(-half_grid), int(half_grid), GRID_SPACING):
		var start = center + Vector2(x, -half_grid)
		var end = center + Vector2(x, half_grid)
		draw_line(start, end, GRID_COLOR, 1.0)
	
	# Horizontal lines
	for y in range(int(-half_grid), int(half_grid), GRID_SPACING):
		var start = center + Vector2(-half_grid, y)
		var end = center + Vector2(half_grid, y)
		draw_line(start, end, GRID_COLOR, 1.0)

func draw_axes(center: Vector2):
	"""Draw coordinate axes"""
	# X axis (red)
	draw_line(center, center + Vector2(AXIS_LENGTH, 0), AXIS_X_COLOR, 2.0)
	draw_line(center, center + Vector2(-AXIS_LENGTH, 0), AXIS_X_COLOR * Color(1, 1, 1, 0.3), 1.0)
	
	# Y axis (green)
	draw_line(center, center + Vector2(0, -AXIS_LENGTH), AXIS_Y_COLOR, 2.0)
	draw_line(center, center + Vector2(0, AXIS_LENGTH), AXIS_Y_COLOR * Color(1, 1, 1, 0.3), 1.0)

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


func draw_point_example(center: Vector2):
	"""Visualize a single point at a specific position with label"""
	draw_grid(center)
	draw_axes(center)

	var position = center + Vector2(120, -80)
	draw_circle(position, 8, POINT_COLOR)
	draw_line(center, position, Color(0.4, 0.4, 0.6, 0.4), 1.5)
	var label_pos = position + Vector2(10, -10)
	draw_string(get_theme_default_font(), label_pos, "Vector3(3.0, 1.5, 4.0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
