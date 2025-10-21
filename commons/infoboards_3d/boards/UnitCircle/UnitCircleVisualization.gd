# UnitCircleVisualization.gd
# Visualization component for Unit Circle info board
extends Control

var visualization_type = "unit_circle"
var angle = 0.0
var animation_playing = true

const CIRCLE_RADIUS = 100
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const WAVE_SEGMENTS = 120
const WAVE_AMPLITUDE = 80
const TIME_SCALE = 3.0

func _process(delta):
	if animation_playing:
		angle += delta * 2.0
		angle = fmod(angle, 2 * PI)
		queue_redraw()

func set_animation_playing(playing: bool):
	animation_playing = playing

func _draw():
	if size.x < 10 or size.y < 10:
		return

	var center_x = size.x / 2
	var center_y = size.y / 2

	match visualization_type:
		"unit_circle":
			draw_unit_circle(center_x, center_y)
		"sine_wave":
			draw_sine_wave(center_x, center_y)
		"cosine_wave":
			draw_cosine_wave(center_x, center_y)
		"tangent_wave":
			draw_tangent_wave(center_x, center_y)
		"combined_waves":
			draw_combined_waves(center_x, center_y)

func draw_unit_circle(center_x, center_y):
	# Draw coordinate axes
	draw_line(Vector2(center_x - CIRCLE_RADIUS * 1.5, center_y),
			  Vector2(center_x + CIRCLE_RADIUS * 1.5, center_y),
			  Color.DARK_GRAY, 2)
	draw_line(Vector2(center_x, center_y - CIRCLE_RADIUS * 1.5),
			  Vector2(center_x, center_y + CIRCLE_RADIUS * 1.5),
			  Color.DARK_GRAY, 2)

	# Draw unit circle
	draw_arc(Vector2(center_x, center_y), CIRCLE_RADIUS, 0, 2 * PI, 64, Color.BLUE, 3)

	# Calculate point on circle
	var angle_end = Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS

	# Draw angle line (from center to point on circle)
	draw_line(Vector2(center_x, center_y),
			  Vector2(center_x + angle_end.x, center_y - angle_end.y),
			  Color.RED, 4)

	# Draw projections (showing sin and cos)
	draw_line(Vector2(center_x + angle_end.x, center_y),
			  Vector2(center_x + angle_end.x, center_y - angle_end.y),
			  Color.GREEN, 3)  # sin (vertical)
	draw_line(Vector2(center_x, center_y),
			  Vector2(center_x + angle_end.x, center_y),
			  Color.YELLOW, 3)  # cos (horizontal)

	# Draw point on circle
	draw_circle(Vector2(center_x + angle_end.x, center_y - angle_end.y), 6, Color.RED)

	# Draw labels
	var font = ThemeDB.fallback_font
	var font_size = 18

	# Axis labels
	draw_string(font, Vector2(center_x + CIRCLE_RADIUS * 1.6, center_y), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(center_x, center_y - CIRCLE_RADIUS * 1.6), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	# Component labels
	draw_string(font, Vector2(center_x + angle_end.x / 2, center_y + 20), "cos θ", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.YELLOW)
	draw_string(font, Vector2(center_x + angle_end.x + 20, center_y - angle_end.y / 2), "sin θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)

	# Angle value display
	var angle_deg = int(rad_to_deg(angle)) % 360
	var info_x = center_x - CIRCLE_RADIUS
	var info_y = center_y - CIRCLE_RADIUS * 1.4

	draw_string(font, Vector2(info_x, info_y),
				"Angle: " + str(angle_deg) + "° (" + str(snappedf(angle, 0.01)) + " rad)",
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(info_x, info_y + 25),
				"sin(θ) = " + str(snappedf(sin(angle), 0.001)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)
	draw_string(font, Vector2(info_x, info_y + 50),
				"cos(θ) = " + str(snappedf(cos(angle), 0.001)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)

	# Display tan only when defined
	if abs(cos(angle)) > 0.1:
		draw_string(font, Vector2(info_x, info_y + 75),
					"tan(θ) = " + str(snappedf(tan(angle), 0.001)),
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	else:
		draw_string(font, Vector2(info_x, info_y + 75),
					"tan(θ) = undefined",
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)

func draw_sine_wave(center_x, center_y):
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y

	# Draw axes
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2),
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2),
			  Color.DARK_GRAY, 2)

	# Draw reference lines
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y - WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)
	draw_line(Vector2(start_x, axis_y + WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y + WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)

	# Draw sine wave
	var points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - sin(t + angle) * WAVE_AMPLITUDE
		points.append(Vector2(x, y))

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color.GREEN, 3)

	# Draw current position marker
	var current_x = start_x
	var current_y = axis_y - sin(angle) * WAVE_AMPLITUDE
	draw_circle(Vector2(current_x, current_y), 7, Color.RED)

	# Draw mini unit circle
	var circle_center_x = start_x - 60
	var circle_center_y = axis_y
	draw_arc(Vector2(circle_center_x, circle_center_y), 35, 0, 2 * PI, 32, Color.BLUE, 2)

	var point_on_circle = Vector2(
		circle_center_x + cos(angle) * 35,
		circle_center_y - sin(angle) * 35
	)

	draw_line(Vector2(circle_center_x, circle_center_y), point_on_circle, Color.RED, 3)
	draw_circle(point_on_circle, 5, Color.RED)

	# Draw connection line
	draw_line(point_on_circle, Vector2(current_x, current_y), Color.YELLOW, 2, true)

	# Labels
	var font = ThemeDB.fallback_font
	var font_size = 18
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y - WAVE_AMPLITUDE - 15), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y + WAVE_AMPLITUDE + 15), "-1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2 - 20), "sin(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)

func draw_cosine_wave(center_x, center_y):
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y

	# Draw axes
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2),
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2),
			  Color.DARK_GRAY, 2)

	# Draw reference lines
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y - WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)
	draw_line(Vector2(start_x, axis_y + WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y + WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)

	# Draw cosine wave
	var points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - cos(t + angle) * WAVE_AMPLITUDE
		points.append(Vector2(x, y))

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color.YELLOW, 3)

	# Draw current position marker
	var current_x = start_x
	var current_y = axis_y - cos(angle) * WAVE_AMPLITUDE
	draw_circle(Vector2(current_x, current_y), 7, Color.RED)

	# Draw mini unit circle
	var circle_center_x = start_x - 60
	var circle_center_y = axis_y
	draw_arc(Vector2(circle_center_x, circle_center_y), 35, 0, 2 * PI, 32, Color.BLUE, 2)

	var point_on_circle = Vector2(
		circle_center_x + cos(angle) * 35,
		circle_center_y - sin(angle) * 35
	)

	draw_line(Vector2(circle_center_x, circle_center_y), point_on_circle, Color.RED, 3)
	draw_circle(point_on_circle, 5, Color.RED)

	# Draw connection line
	draw_line(point_on_circle, Vector2(current_x, current_y), Color.GREEN, 2, true)

	# Labels
	var font = ThemeDB.fallback_font
	var font_size = 18
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y - WAVE_AMPLITUDE - 15), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y + WAVE_AMPLITUDE + 15), "-1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2 - 20), "cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)

func draw_tangent_wave(center_x, center_y):
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y

	# Draw axes
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2),
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2),
			  Color.DARK_GRAY, 2)

	# Draw reference lines
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y - WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)
	draw_line(Vector2(start_x, axis_y + WAVE_AMPLITUDE),
			  Vector2(start_x + GRAPH_WIDTH, axis_y + WAVE_AMPLITUDE),
			  Color(0.7, 0.7, 0.7, 0.3), 1)

	# Draw tangent wave with asymptote detection
	var prev_point = null
	var asymptote_regions = []

	# Mark asymptotes
	for i in range(int(TIME_SCALE) + 1):
		var asymptote = (i + 0.5) * PI
		if asymptote < TIME_SCALE * 2 * PI:
			asymptote_regions.append(asymptote)

	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI

		# Check if near asymptote
		var near_asymptote = false
		for asymptote in asymptote_regions:
			if abs(fmod(t + angle, 2 * PI) - fmod(asymptote, 2 * PI)) < 0.2:
				near_asymptote = true
				break

		if near_asymptote:
			prev_point = null
			continue

		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var tan_value = clamp(tan(t + angle), -3, 3)
		var y = axis_y - tan_value * (WAVE_AMPLITUDE / 3)
		var current_point = Vector2(x, y)

		if prev_point != null:
			draw_line(prev_point, current_point, Color.PURPLE, 3)

		prev_point = current_point

	# Draw asymptote lines
	for asymptote in asymptote_regions:
		var x = start_x + (asymptote / (TIME_SCALE * 2 * PI)) * GRAPH_WIDTH
		draw_line(Vector2(x, axis_y - WAVE_AMPLITUDE * 1.2),
				  Vector2(x, axis_y + WAVE_AMPLITUDE * 1.2),
				  Color(1, 0, 0, 0.5), 2, true)

	# Labels
	var font = ThemeDB.fallback_font
	var font_size = 18
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y - WAVE_AMPLITUDE - 15), "3", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x - 50, axis_y + WAVE_AMPLITUDE + 15), "-3", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2 - 20), "tan(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.PURPLE)

func draw_combined_waves(center_x, center_y):
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y

	# Draw axes
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2),
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2),
			  Color.DARK_GRAY, 2)

	# Draw sine wave
	var sine_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - sin(t + angle) * (WAVE_AMPLITUDE * 0.35)
		sine_points.append(Vector2(x, y))

	for i in range(sine_points.size() - 1):
		draw_line(sine_points[i], sine_points[i + 1], Color(0, 0.8, 0, 0.6), 2)

	# Draw cosine wave
	var cosine_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - cos(t + angle) * (WAVE_AMPLITUDE * 0.35)
		cosine_points.append(Vector2(x, y))

	for i in range(cosine_points.size() - 1):
		draw_line(cosine_points[i], cosine_points[i + 1], Color(0.8, 0.8, 0, 0.6), 2)

	# Draw combined wave (sin + cos)
	var combined_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - (sin(t + angle) + cos(t + angle)) * (WAVE_AMPLITUDE * 0.35)
		combined_points.append(Vector2(x, y))

	for i in range(combined_points.size() - 1):
		draw_line(combined_points[i], combined_points[i + 1], Color(1, 0, 0, 0.8), 3)

	# Draw complex wave (sin + 0.5*sin(2x) + 0.25*sin(3x))
	var complex_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - (
			sin(t + angle) * (WAVE_AMPLITUDE * 0.35) +
			0.5 * sin(2 * (t + angle)) * (WAVE_AMPLITUDE * 0.35) +
			0.25 * sin(3 * (t + angle)) * (WAVE_AMPLITUDE * 0.35)
		)
		complex_points.append(Vector2(x, y))

	for i in range(complex_points.size() - 1):
		draw_line(complex_points[i], complex_points[i + 1], Color(0.5, 0, 0.8, 0.9), 3)

	# Draw legend
	var font = ThemeDB.fallback_font
	var font_size = 16
	var legend_x = start_x + 10
	var legend_y = axis_y - WAVE_AMPLITUDE * 1.05

	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 25, legend_y), Color(0, 0.8, 0, 0.6), 2)
	draw_string(font, Vector2(legend_x + 30, legend_y + 5), "sin(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	legend_y += 22
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 25, legend_y), Color(0.8, 0.8, 0, 0.6), 2)
	draw_string(font, Vector2(legend_x + 30, legend_y + 5), "cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	legend_y += 22
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 25, legend_y), Color(1, 0, 0, 0.8), 3)
	draw_string(font, Vector2(legend_x + 30, legend_y + 5), "sin+cos", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	legend_y += 22
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 25, legend_y), Color(0.5, 0, 0.8, 0.9), 3)
	draw_string(font, Vector2(legend_x + 30, legend_y + 5), "Fourier", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
