# CoordinateSystemVisualizationControl.gd
# Visualization for Coordinate System concepts
extends Control

var visualization_type = "origin"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const ORIGIN_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const AXIS_X_COLOR = Color(0.9, 0.2, 0.2, 0.9)
const AXIS_Y_COLOR = Color(0.2, 0.9, 0.2, 0.9)
const AXIS_Z_COLOR = Color(0.2, 0.2, 0.9, 0.9)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const LABEL_COLOR = Color(0.9, 0.9, 1.0, 1.0)

const GRID_SIZE = 400
const GRID_SPACING = 40
const AXIS_LENGTH = 150

func _ready():
	custom_minimum_size = Vector2(400, 400)

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)

	# Center of the visualization
	var center = size / 2

	match visualization_type:
		"origin":
			draw_origin(center)
		"axes":
			draw_axes(center)
		"handedness":
			draw_handedness(center)
		"positions":
			draw_positions(center)

func draw_origin(center_pos: Vector2):
	"""Show the origin point"""
	draw_grid(center_pos)

	# Pulsing origin point
	var pulse = 1.0 + sin(animation_time * 2.0) * 0.3
	var origin_size = 15 * pulse

	# Draw concentric circles
	for i in range(3, 0, -1):
		var alpha = 0.3 * (float(i) / 3.0)
		draw_circle(center_pos, origin_size * i * 0.5, Color(ORIGIN_COLOR.r, ORIGIN_COLOR.g, ORIGIN_COLOR.b, alpha))

	# Main origin point
	draw_circle(center_pos, origin_size, ORIGIN_COLOR)

	# Crosshair
	var cross_size = 30
	draw_line(center_pos + Vector2(-cross_size, 0), center_pos + Vector2(cross_size, 0), Color(1, 1, 1, 0.5), 2.0)
	draw_line(center_pos + Vector2(0, -cross_size), center_pos + Vector2(0, cross_size), Color(1, 1, 1, 0.5), 2.0)

	# Label
	draw_string(get_theme_default_font(), center_pos + Vector2(25, -20), "(0, 0, 0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ORIGIN_COLOR)
	draw_string(get_theme_default_font(), center_pos + Vector2(25, 5), "ORIGIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "The center of our 3D universe", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_axes(center_pos: Vector2):
	"""Show the three coordinate axes"""
	draw_grid(center_pos)

	# Draw axes with isometric projection
	# X axis (right) - Red
	var x_dir = Vector2(1, -0.4).normalized() * AXIS_LENGTH
	draw_arrow(center_pos, center_pos + x_dir, AXIS_X_COLOR, 4.0)
	draw_string(get_theme_default_font(), center_pos + x_dir + Vector2(15, 0), "X (Right)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_X_COLOR)

	# Y axis (up) - Green
	var y_dir = Vector2(0, -1) * AXIS_LENGTH
	draw_arrow(center_pos, center_pos + y_dir, AXIS_Y_COLOR, 4.0)
	draw_string(get_theme_default_font(), center_pos + y_dir + Vector2(10, -15), "Y (Up)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_Y_COLOR)

	# Z axis (forward) - Blue
	var z_dir = Vector2(-0.8, -0.4).normalized() * AXIS_LENGTH
	draw_arrow(center_pos, center_pos + z_dir, AXIS_Z_COLOR, 4.0)
	draw_string(get_theme_default_font(), center_pos + z_dir + Vector2(-80, 0), "Z (Forward)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_Z_COLOR)

	# Draw negative directions (faded)
	draw_line(center_pos, center_pos - x_dir, AXIS_X_COLOR * Color(1, 1, 1, 0.3), 2.0)
	draw_line(center_pos, center_pos - y_dir, AXIS_Y_COLOR * Color(1, 1, 1, 0.3), 2.0)
	draw_line(center_pos, center_pos - z_dir, AXIS_Z_COLOR * Color(1, 1, 1, 0.3), 2.0)

	# Origin point
	draw_circle(center_pos, 8, ORIGIN_COLOR)

	# Draw grid ticks
	for i in range(1, 4):
		var tick_size = 8
		# X ticks
		var tick_pos = center_pos + x_dir.normalized() * (AXIS_LENGTH / 3) * i
		draw_line(tick_pos + Vector2(0, -tick_size / 2), tick_pos + Vector2(0, tick_size / 2), AXIS_X_COLOR * Color(1, 1, 1, 0.5), 2.0)
		# Y ticks
		tick_pos = center_pos + y_dir.normalized() * (AXIS_LENGTH / 3) * i
		draw_line(tick_pos + Vector2(-tick_size / 2, 0), tick_pos + Vector2(tick_size / 2, 0), AXIS_Y_COLOR * Color(1, 1, 1, 0.5), 2.0)
		# Z ticks
		tick_pos = center_pos + z_dir.normalized() * (AXIS_LENGTH / 3) * i
		draw_line(tick_pos + Vector2(0, -tick_size / 2), tick_pos + Vector2(0, tick_size / 2), AXIS_Z_COLOR * Color(1, 1, 1, 0.5), 2.0)

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Three perpendicular axes define 3D space", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_handedness(center_pos: Vector2):
	"""Show right-handed coordinate system"""
	draw_grid(center_pos)

	# Draw axes
	var axis_len = 100
	var x_dir = Vector2(1, -0.3).normalized() * axis_len
	var y_dir = Vector2(0, -1) * axis_len
	var z_dir = Vector2(-0.7, -0.3).normalized() * axis_len

	draw_arrow(center_pos, center_pos + x_dir, AXIS_X_COLOR, 3.0)
	draw_arrow(center_pos, center_pos + y_dir, AXIS_Y_COLOR, 3.0)
	draw_arrow(center_pos, center_pos + z_dir, AXIS_Z_COLOR, 3.0)

	draw_string(get_theme_default_font(), center_pos + x_dir + Vector2(10, 0), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_X_COLOR)
	draw_string(get_theme_default_font(), center_pos + y_dir + Vector2(5, -10), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_Y_COLOR)
	draw_string(get_theme_default_font(), center_pos + z_dir + Vector2(-25, 0), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AXIS_Z_COLOR)

	# Origin
	draw_circle(center_pos, 6, ORIGIN_COLOR)

	# Draw right hand visualization
	var hand_pos = center_pos + Vector2(150, 80)
	draw_right_hand(hand_pos, animation_time)

	# Draw cross product demonstration
	# X × Y = Z
	var cross_start = center_pos + Vector2(-150, 80)
	draw_string(get_theme_default_font(), cross_start, "X × Y = Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.9, 0.2))
	draw_string(get_theme_default_font(), cross_start + Vector2(0, 25), "(Right-handed)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8))

	# Animate curl direction
	var curl_center = cross_start + Vector2(50, 60)
	var curl_radius = 30
	var curl_angle = animation_time * 2.0
	for i in range(12):
		var a1 = (float(i) / 12) * TAU * 0.7 + curl_angle
		var a2 = (float(i + 1) / 12) * TAU * 0.7 + curl_angle
		var p1 = curl_center + Vector2(cos(a1), sin(a1)) * curl_radius
		var p2 = curl_center + Vector2(cos(a2), sin(a2)) * curl_radius
		draw_line(p1, p2, Color(0.9, 0.4, 0.6), 2.0)

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 40), "Determines rotation direction", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Critical for cross products", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_positions(center_pos: Vector2):
	"""Show various points in 3D space"""
	draw_grid(center_pos)

	# Draw axes (faded)
	var axis_len = 140
	var x_dir = Vector2(1, -0.3).normalized() * axis_len
	var y_dir = Vector2(0, -1) * axis_len
	var z_dir = Vector2(-0.7, -0.3).normalized() * axis_len

	draw_line(center_pos, center_pos + x_dir, AXIS_X_COLOR * Color(1, 1, 1, 0.3), 2.0)
	draw_line(center_pos, center_pos + y_dir, AXIS_Y_COLOR * Color(1, 1, 1, 0.3), 2.0)
	draw_line(center_pos, center_pos + z_dir, AXIS_Z_COLOR * Color(1, 1, 1, 0.3), 2.0)

	# Origin
	draw_circle(center_pos, 5, ORIGIN_COLOR)
	draw_string(get_theme_default_font(), center_pos + Vector2(10, -10), "(0,0,0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ORIGIN_COLOR)

	# Define some example points
	var points = [
		{"pos": Vector3(2, 1, 0), "label": "A", "color": Color(0.9, 0.3, 0.3)},
		{"pos": Vector3(-1, 2, 1), "label": "B", "color": Color(0.3, 0.9, 0.3)},
		{"pos": Vector3(1, -1, 2), "label": "C", "color": Color(0.3, 0.3, 0.9)},
		{"pos": Vector3(-2, 0, -1), "label": "D", "color": Color(0.9, 0.9, 0.3)}
	]

	# Animate point positions
	var offset = sin(animation_time) * 0.2

	for point_data in points:
		var pos_3d = point_data.pos + Vector3(offset, offset * 0.5, offset * 0.3)
		# Project to 2D
		var pos_2d = center_pos + pos_3d.x * x_dir.normalized() * 40 + pos_3d.y * y_dir.normalized() * 40 + pos_3d.z * z_dir.normalized() * 40

		# Draw line from origin
		draw_line(center_pos, pos_2d, point_data.color * Color(1, 1, 1, 0.3), 1.5)

		# Draw point
		var pulse = 1.0 + sin(animation_time * 2.0 + points.find(point_data)) * 0.2
		draw_circle(pos_2d, 8 * pulse, point_data.color)

		# Draw label
		draw_string(get_theme_default_font(), pos_2d + Vector2(15, -5), point_data.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
		var coord_text = "(%d,%d,%d)" % [int(pos_3d.x), int(pos_3d.y), int(pos_3d.z)]
		draw_string(get_theme_default_font(), pos_2d + Vector2(15, 10), coord_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, point_data.color * Color(1.2, 1.2, 1.2))

	# Info
	draw_string(get_theme_default_font(), Vector2(20, size.y - 20), "Every point = (x, y, z) from origin", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))

func draw_right_hand(pos: Vector2, time: float):
	"""Draw a simplified right hand icon"""
	# Palm
	var palm_points = PackedVector2Array([
		pos + Vector2(-15, -20),
		pos + Vector2(15, -20),
		pos + Vector2(15, 10),
		pos + Vector2(-15, 10)
	])
	draw_colored_polygon(palm_points, Color(0.9, 0.7, 0.5, 0.8))

	# Thumb
	var thumb_points = PackedVector2Array([
		pos + Vector2(-15, -10),
		pos + Vector2(-25, -5),
		pos + Vector2(-25, 5),
		pos + Vector2(-15, 0)
	])
	draw_colored_polygon(thumb_points, Color(0.9, 0.7, 0.5, 0.8))

	# Fingers (curl animation)
	var curl = abs(sin(time))
	for i in range(4):
		var finger_x = -10 + i * 7
		var finger_base = pos + Vector2(finger_x, -20)
		var finger_tip = finger_base + Vector2(curl * 5, -15 - curl * 10)
		draw_line(finger_base, finger_tip, Color(0.9, 0.7, 0.5), 4.0)

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

func draw_arrow(from: Vector2, to: Vector2, color: Color, width: float = 2.0):
	"""Draw an arrow from one point to another"""
	draw_line(from, to, color, width)

	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var arrow_size = 12

	var arrow_point1 = to - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_point2 = to - direction * arrow_size - perpendicular * arrow_size * 0.5

	var points = PackedVector2Array([to, arrow_point1, arrow_point2])
	draw_colored_polygon(points, color)
