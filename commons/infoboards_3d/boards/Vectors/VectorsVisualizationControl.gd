# VectorsVisualizationControl.gd
# Visualization for basic Vector concepts
# Visual IDs: duality, subtraction, magnitude, normalization, line_definition
extends Control

var visualization_type = "duality"
var animation_time = 0.0
var animation_speed = 1.0
var animation_playing = true

# Visual constants matching Point/Line board style
const BG_COLOR = Color(0.05, 0.05, 0.07)
const GRID_COLOR = Color(0.15, 0.15, 0.2, 0.3)
const AXIS_X_COLOR = Color(0.8, 0.2, 0.2, 0.8)
const AXIS_Y_COLOR = Color(0.2, 0.8, 0.2, 0.8)
const VECTOR_COLOR = Color(0.2, 0.7, 1.0, 1.0)
const VECTOR_B_COLOR = Color(1.0, 0.5, 0.2, 1.0)
const POINT_COLOR = Color(1.0, 0.9, 0.2, 1.0)
const RESULT_COLOR = Color(0.8, 0.2, 0.8, 1.0)
const LABEL_COLOR = Color(0.9, 0.9, 1.0, 1.0)
const DIM_COLOR = Color(0.5, 0.5, 0.6, 0.5)

const GRID_SIZE = 400
const GRID_SPACING = 40
const AXIS_LENGTH = 180
const SCALE = 40  # pixels per unit

func _ready():
	custom_minimum_size = Vector2(400, 400)

func _process(delta):
	if animation_playing:
		animation_time += delta * animation_speed
		queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	var center = size / 2

	match visualization_type:
		"duality":
			draw_duality(center)
		"subtraction":
			draw_subtraction(center)
		"magnitude":
			draw_magnitude(center)
		"normalization":
			draw_normalization(center)
		"line_definition":
			draw_line_definition(center)

# --- Slide 1: Vector Duality (position vs direction) ---
func draw_duality(center: Vector2):
	draw_grid(center)
	draw_axes(center)

	# A vector shown as POSITION (rooted at origin)
	var vec = Vector2(3.0, 2.0) * SCALE
	var pulse = sin(animation_time * 1.5) * 0.08

	# Position interpretation — arrow from origin
	var pos_end = center + Vector2(vec.x, -vec.y) * (1.0 + pulse)
	draw_arrow(center, pos_end, VECTOR_COLOR, 3.0)
	draw_circle(pos_end, 6, POINT_COLOR)
	draw_string(get_theme_default_font(), pos_end + Vector2(10, -8),
		"Position (3, 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, POINT_COLOR)

	# Direction interpretation — same arrow placed elsewhere
	var offset_origin = center + Vector2(-100, 80)
	var dir_end = offset_origin + Vector2(vec.x, -vec.y) * (1.0 + pulse)
	draw_arrow(offset_origin, dir_end, VECTOR_B_COLOR, 3.0)
	draw_circle(offset_origin, 4, DIM_COLOR)
	draw_string(get_theme_default_font(), dir_end + Vector2(10, -8),
		"Direction (3, 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VECTOR_B_COLOR)

	# Dashed equal sign between the two
	var mid_a = (center + pos_end) / 2 + Vector2(0, 20)
	var mid_b = (offset_origin + dir_end) / 2 + Vector2(0, -20)
	draw_dashed_line(mid_a, mid_b, Color(1, 1, 1, 0.25), 1.0)

	# Labels
	draw_string(get_theme_default_font(), center + Vector2(-180, -170),
		"Same vector, two meanings", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(-180, 170),
		"Context determines whether it's a place or a displacement",
		HORIZONTAL_ALIGNMENT_LEFT, 380, 12, Color(0.7, 0.7, 0.8, 0.8))

# --- Slide 2: Vector Subtraction (B - A) ---
func draw_subtraction(center: Vector2):
	draw_grid(center)
	draw_axes(center)

	# Points A and B
	var a = Vector2(1.0, 1.0) * SCALE
	var b = Vector2(3.5, 3.0) * SCALE

	var pos_a = center + Vector2(a.x, -a.y)
	var pos_b = center + Vector2(b.x, -b.y)

	# Animate B slightly
	var bob = sin(animation_time * 1.2) * 8
	pos_b += Vector2(bob * 0.5, -bob)

	# Draw position vectors from origin (dimmed)
	draw_arrow(center, pos_a, Color(VECTOR_COLOR, 0.35), 1.5)
	draw_arrow(center, pos_b, Color(VECTOR_B_COLOR, 0.35), 1.5)

	# Draw B - A vector (the main result)
	draw_arrow(pos_a, pos_b, RESULT_COLOR, 3.0)

	# Points
	draw_circle(pos_a, 7, POINT_COLOR)
	draw_circle(pos_b, 7, POINT_COLOR)

	# Labels
	draw_string(get_theme_default_font(), pos_a + Vector2(-35, 18),
		"A (1, 1)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, POINT_COLOR)
	draw_string(get_theme_default_font(), pos_b + Vector2(10, -8),
		"B (3.5, 3)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, POINT_COLOR)

	# Result label at midpoint of B-A
	var mid = (pos_a + pos_b) / 2
	draw_string(get_theme_default_font(), mid + Vector2(-60, -15),
		"B - A = (2.5, 2)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, RESULT_COLOR)

	draw_string(get_theme_default_font(), center + Vector2(-180, -170),
		"Subtraction: direction from A to B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(-180, 170),
		"B - A gives the vector that moves you from A to B",
		HORIZONTAL_ALIGNMENT_LEFT, 380, 12, Color(0.7, 0.7, 0.8, 0.8))

# --- Slide 3: Vector Magnitude (.length()) ---
func draw_magnitude(center: Vector2):
	draw_grid(center)
	draw_axes(center)

	# Animated vector that changes length
	var t = animation_time * 0.6
	var angle = 0.6
	var len_val = 2.5 + sin(t) * 1.5  # oscillates between 1.0 and 4.0
	var vec = Vector2(cos(angle), -sin(angle)) * len_val * SCALE
	var end = center + vec

	# Draw vector
	draw_arrow(center, end, VECTOR_COLOR, 3.0)

	# Draw component decomposition (right triangle)
	var corner = center + Vector2(vec.x, 0)
	draw_line(center, corner, Color(AXIS_X_COLOR, 0.5), 2.0)
	draw_line(corner, end, Color(AXIS_Y_COLOR, 0.5), 2.0)

	# Right angle marker
	var marker_size = 8
	var sx = sign(vec.x)
	var sy = sign(vec.y)
	draw_line(corner + Vector2(-marker_size * sx, 0), corner + Vector2(-marker_size * sx, sy * -marker_size), DIM_COLOR, 1.0)
	draw_line(corner + Vector2(-marker_size * sx, sy * -marker_size), corner + Vector2(0, sy * -marker_size), DIM_COLOR, 1.0)

	# Component labels
	var x_val = len_val * cos(angle)
	var y_val = len_val * sin(angle)
	draw_string(get_theme_default_font(), center + Vector2(vec.x / 2, 18),
		"x = %.1f" % x_val, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, AXIS_X_COLOR)
	draw_string(get_theme_default_font(), corner + Vector2(10, vec.y / 2),
		"y = %.1f" % y_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AXIS_Y_COLOR)

	# Magnitude value
	draw_string(get_theme_default_font(), (center + end) / 2 + Vector2(-70, -18),
		"|v| = %.2f" % len_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, POINT_COLOR)

	# Pythagorean formula
	draw_string(get_theme_default_font(), center + Vector2(-180, 140),
		"length = sqrt(x*x + y*y + z*z)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, LABEL_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(-180, -170),
		"Magnitude: the distance a vector spans", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

# --- Slide 4: Vector Normalization (.normalized()) ---
func draw_normalization(center: Vector2):
	draw_grid(center)
	draw_axes(center)

	# Animated angle for the vector direction
	var t = animation_time * 0.4
	var angle = t * 0.8

	# Original vector with varying length
	var len_val = 3.0 + sin(t * 1.3) * 1.5
	var dir = Vector2(cos(angle), -sin(angle))
	var vec = dir * len_val * SCALE
	var end = center + vec

	# Normalized vector (unit length, shown at fixed visual scale)
	var unit_visual = dir * 1.0 * SCALE
	var norm_end = center + unit_visual

	# Draw original vector (dimmed)
	draw_arrow(center, end, Color(VECTOR_COLOR, 0.4), 2.0)
	draw_string(get_theme_default_font(), end + Vector2(8, -8),
		"v (len %.1f)" % len_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(VECTOR_COLOR, 0.6))

	# Draw normalized vector (bright)
	draw_arrow(center, norm_end, RESULT_COLOR, 3.0)
	draw_string(get_theme_default_font(), norm_end + Vector2(8, -8),
		"normalized (len 1.0)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RESULT_COLOR)

	# Draw unit circle to show length = 1
	var circle_points = 64
	for i in range(circle_points):
		var a1 = float(i) / circle_points * TAU
		var a2 = float(i + 1) / circle_points * TAU
		var p1 = center + Vector2(cos(a1), sin(a1)) * SCALE
		var p2 = center + Vector2(cos(a2), sin(a2)) * SCALE
		draw_line(p1, p2, Color(1, 1, 1, 0.15), 1.0)

	draw_string(get_theme_default_font(), center + Vector2(SCALE + 5, 15),
		"r = 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM_COLOR)

	draw_string(get_theme_default_font(), center + Vector2(-180, -170),
		"Normalization: pure direction, length = 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(-180, 170),
		".normalized() removes distance, keeps only direction",
		HORIZONTAL_ALIGNMENT_LEFT, 380, 12, Color(0.7, 0.7, 0.8, 0.8))

# --- Slide 5: Line Definition (point + direction) ---
func draw_line_definition(center: Vector2):
	draw_grid(center)
	draw_axes(center)

	# A point on the line
	var point = Vector2(1.0, 1.5) * SCALE
	var pos_point = center + Vector2(point.x, -point.y)

	# Direction vector (animated rotation)
	var t = animation_time * 0.3
	var dir_angle = 0.4 + sin(t) * 0.3
	var dir = Vector2(cos(dir_angle), -sin(dir_angle))

	# Draw the infinite line through the point
	var line_extent = 300
	var line_start = pos_point - dir * line_extent
	var line_end_pos = pos_point + dir * line_extent
	draw_line(line_start, line_end_pos, Color(VECTOR_COLOR, 0.3), 2.0)

	# Draw the point
	draw_circle(pos_point, 7, POINT_COLOR)
	draw_string(get_theme_default_font(), pos_point + Vector2(10, -12),
		"P (1, 1.5)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, POINT_COLOR)

	# Draw direction vector from the point
	var dir_vis = dir * 2.5 * SCALE
	draw_arrow(pos_point, pos_point + dir_vis, RESULT_COLOR, 3.0)
	draw_string(get_theme_default_font(), pos_point + dir_vis + Vector2(8, -8),
		"d (direction)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, RESULT_COLOR)

	# Animate a point traveling along the line
	var travel_t = sin(animation_time * 0.8) * 2.5
	var traveler = pos_point + dir * travel_t * SCALE
	draw_circle(traveler, 5, Color(0.2, 1.0, 0.4, 0.9))
	var param_text = "t = %.1f" % travel_t
	draw_string(get_theme_default_font(), traveler + Vector2(8, 15),
		param_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.4, 0.8))

	# Formula
	draw_string(get_theme_default_font(), center + Vector2(-180, 140),
		"line(t) = P + t * d", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(-180, -170),
		"A line: one point + one direction", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LABEL_COLOR)

# --- Shared helpers (matching Point/Line board pattern) ---
func draw_grid(center: Vector2):
	var half_grid = GRID_SIZE / 2.0
	for x in range(int(-half_grid), int(half_grid), GRID_SPACING):
		draw_line(center + Vector2(x, -half_grid), center + Vector2(x, half_grid), GRID_COLOR, 1.0)
	for y in range(int(-half_grid), int(half_grid), GRID_SPACING):
		draw_line(center + Vector2(-half_grid, y), center + Vector2(half_grid, y), GRID_COLOR, 1.0)

func draw_axes(center: Vector2):
	draw_line(center, center + Vector2(AXIS_LENGTH, 0), AXIS_X_COLOR, 2.0)
	draw_line(center, center + Vector2(-AXIS_LENGTH, 0), AXIS_X_COLOR * Color(1, 1, 1, 0.3), 1.0)
	draw_line(center, center + Vector2(0, -AXIS_LENGTH), AXIS_Y_COLOR, 2.0)
	draw_line(center, center + Vector2(0, AXIS_LENGTH), AXIS_Y_COLOR * Color(1, 1, 1, 0.3), 1.0)
	draw_string(get_theme_default_font(), center + Vector2(AXIS_LENGTH + 10, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AXIS_X_COLOR)
	draw_string(get_theme_default_font(), center + Vector2(5, -AXIS_LENGTH - 10), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AXIS_Y_COLOR)

func draw_arrow(from: Vector2, to: Vector2, color: Color, width: float = 2.0):
	draw_line(from, to, color, width)
	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var arrow_size = 8
	var arrow_point1 = to - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_point2 = to - direction * arrow_size - perpendicular * arrow_size * 0.5
	var points = PackedVector2Array([to, arrow_point1, arrow_point2])
	draw_colored_polygon(points, color)
