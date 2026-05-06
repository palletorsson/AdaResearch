extends Control

var visualization_type = "unit_circle"
var angle = 0.0
var animation_playing = true
var animation_speed = 2.0

const CIRCLE_RADIUS = 100
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const WAVE_SEGMENTS = 120
const WAVE_AMPLITUDE = 80
const TIME_SCALE = 3.0

func _process(delta):
	if animation_playing:
		angle += delta * animation_speed
		angle = fmod(angle, 2 * PI)
		queue_redraw()

func _draw():
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
	draw_arc(Vector2(center_x, center_y), CIRCLE_RADIUS, 0, 2 * PI, 64, Color.BLUE, 2)
	
	# Draw angle
	var angle_end = Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS
	draw_line(Vector2(center_x, center_y), 
			  Vector2(center_x + angle_end.x, center_y - angle_end.y), 
			  Color.RED, 3)
	
	# Draw sin and cos projections
	draw_line(Vector2(center_x + angle_end.x, center_y), 
			  Vector2(center_x + angle_end.x, center_y - angle_end.y), 
			  Color.GREEN, 2)  # sin
	draw_line(Vector2(center_x, center_y), 
			  Vector2(center_x + angle_end.x, center_y), 
			  Color.YELLOW, 2)  # cos
	
	# Draw labels
	var font = get_theme_default_font()
	var font_size = 16
	draw_string(font, Vector2(center_x + CIRCLE_RADIUS * 1.6, center_y), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(center_x, center_y - CIRCLE_RADIUS * 1.6), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(center_x + angle_end.x / 2, center_y + 15), "cos θ", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(center_x + angle_end.x + 15, center_y - angle_end.y / 2), "sin θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(center_x + angle_end.x * 0.7, center_y - angle_end.y * 0.7), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Draw angle value
	var angle_deg = int(rad_to_deg(angle)) % 360
	draw_string(font, Vector2(center_x - CIRCLE_RADIUS, center_y - CIRCLE_RADIUS * 1.3), 
				"Angle: " + str(angle_deg) + "° (" + str(snappedf(angle, 0.01)) + " rad)", 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(center_x - CIRCLE_RADIUS, center_y - CIRCLE_RADIUS * 1.1), 
				"sin(θ) = " + str(snappedf(sin(angle), 0.001)), 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(center_x - CIRCLE_RADIUS, center_y - CIRCLE_RADIUS * 0.9), 
				"cos(θ) = " + str(snappedf(cos(angle), 0.001)), 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Display tan only when it's not approaching infinity
	if abs(cos(angle)) > 0.1:
		draw_string(font, Vector2(center_x - CIRCLE_RADIUS, center_y - CIRCLE_RADIUS * 0.7), 
					"tan(θ) = " + str(snappedf(tan(angle), 0.001)), 
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	else:
		draw_string(font, Vector2(center_x - CIRCLE_RADIUS, center_y - CIRCLE_RADIUS * 0.7), 
					"tan(θ) = undefined", 
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

func draw_sine_wave(center_x, center_y):
	# Draw horizontal axis (time)
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	
	# Draw vertical axis
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2), 
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2), 
			  Color.DARK_GRAY, 2)
	
	# Draw horizontal reference lines
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
		draw_line(points[i], points[i + 1], Color.GREEN, 2)
	
	# Draw marker for current angle
	var current_x = start_x
	var current_y = axis_y - sin(angle) * WAVE_AMPLITUDE
	draw_circle(Vector2(current_x, current_y), 5, Color.RED)
	
	# Connect to unit circle
	var circle_center_x = start_x - 50
	var circle_center_y = axis_y
	draw_arc(Vector2(circle_center_x, circle_center_y), 30, 0, 2 * PI, 32, Color.BLUE, 2)
	
	var point_on_circle = Vector2(
		circle_center_x + cos(angle) * 30,
		circle_center_y - sin(angle) * 30
	)
	
	# Draw angle line
	draw_line(
		Vector2(circle_center_x, circle_center_y),
		point_on_circle,
		Color.RED, 2
	)
	
	# Draw projection to sine wave
	draw_line(
		point_on_circle,
		Vector2(current_x, current_y),
		Color.YELLOW, 1, true
	)
	
	# Draw labels
	var font = get_theme_default_font()
	var font_size = 16
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y - WAVE_AMPLITUDE - 10), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y + WAVE_AMPLITUDE + 10), "-1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2), "sin(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

func draw_cosine_wave(center_x, center_y):
	# Draw horizontal axis (time)
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	
	# Draw vertical axis
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2), 
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2), 
			  Color.DARK_GRAY, 2)
	
	# Draw horizontal reference lines
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
		draw_line(points[i], points[i + 1], Color.YELLOW, 2)
	
	# Draw marker for current angle
	var current_x = start_x
	var current_y = axis_y - cos(angle) * WAVE_AMPLITUDE
	draw_circle(Vector2(current_x, current_y), 5, Color.RED)
	
	# Connect to unit circle
	var circle_center_x = start_x - 50
	var circle_center_y = axis_y
	draw_arc(Vector2(circle_center_x, circle_center_y), 30, 0, 2 * PI, 32, Color.BLUE, 2)
	
	var point_on_circle = Vector2(
		circle_center_x + cos(angle) * 30,
		circle_center_y - sin(angle) * 30
	)
	
	# Draw angle line
	draw_line(
		Vector2(circle_center_x, circle_center_y),
		point_on_circle,
		Color.RED, 2
	)
	
	# Draw projection to cosine wave
	draw_line(
		point_on_circle,
		Vector2(current_x, current_y),
		Color.GREEN, 1, true
	)
	
	# Draw labels
	var font = get_theme_default_font()
	var font_size = 16
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y - WAVE_AMPLITUDE - 10), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y + WAVE_AMPLITUDE + 10), "-1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2), "cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

func draw_tangent_wave(center_x, center_y):
	# Draw horizontal axis (time)
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	
	# Draw vertical axis
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2), 
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2), 
			  Color.DARK_GRAY, 2)
	
	# Draw horizontal reference lines
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE), 
			  Vector2(start_x + GRAPH_WIDTH, axis_y - WAVE_AMPLITUDE), 
			  Color(0.7, 0.7, 0.7, 0.3), 1)
	draw_line(Vector2(start_x, axis_y + WAVE_AMPLITUDE), 
			  Vector2(start_x + GRAPH_WIDTH, axis_y + WAVE_AMPLITUDE), 
			  Color(0.7, 0.7, 0.7, 0.3), 1)
	
	# Draw tangent wave
	var prev_point = null
	var asymptote_regions = []
	
	# Define asymptote regions (where tangent approaches infinity)
	for i in range(int(TIME_SCALE) + 1):
		var asymptote = (i + 0.5) * PI
		if asymptote < TIME_SCALE * 2 * PI:
			asymptote_regions.append(asymptote)
	
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		
		# Check if we're near an asymptote
		var near_asymptote = false
		for asymptote in asymptote_regions:
			if abs(fmod(t + angle, 2 * PI) - fmod(asymptote, 2 * PI)) < 0.2:
				near_asymptote = true
				break
		
		if near_asymptote:
			prev_point = null
			continue
		
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		
		# Clamp tangent value to keep visualization in bounds
		var tan_value = tan(t + angle)
		tan_value = clamp(tan_value, -3, 3)
		
		var y = axis_y - tan_value * (WAVE_AMPLITUDE / 3)
		var current_point = Vector2(x, y)
		
		if prev_point != null:
			draw_line(prev_point, current_point, Color.PURPLE, 2)
		
		prev_point = current_point
	
	# Draw asymptote markers
	for asymptote in asymptote_regions:
		var x = start_x + (asymptote / (TIME_SCALE * 2 * PI)) * GRAPH_WIDTH
		draw_line(Vector2(x, axis_y - WAVE_AMPLITUDE * 1.2), 
				  Vector2(x, axis_y + WAVE_AMPLITUDE * 1.2), 
				  Color(1, 0, 0, 0.3), 1, true)
	
	# Draw labels
	var font = get_theme_default_font()
	var font_size = 16
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y - WAVE_AMPLITUDE - 10), "3", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y + WAVE_AMPLITUDE + 10), "-3", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x - 40, axis_y), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2), "tan(θ) = sin(θ)/cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(start_x, axis_y - GRAPH_HEIGHT / 2 + 20), "Red lines: asymptotes where cos(θ)=0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

func draw_combined_waves(center_x, center_y):
	# Draw horizontal axis (time)
	var start_x = center_x - GRAPH_WIDTH / 2
	var axis_y = center_y
	draw_line(Vector2(start_x, axis_y), Vector2(start_x + GRAPH_WIDTH, axis_y), Color.DARK_GRAY, 2)
	
	# Draw vertical axis
	draw_line(Vector2(start_x, axis_y - WAVE_AMPLITUDE * 1.2), 
			  Vector2(start_x, axis_y + WAVE_AMPLITUDE * 1.2), 
			  Color.DARK_GRAY, 2)
	
	# Draw sine wave
	var sine_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - sin(t + angle) * (WAVE_AMPLITUDE * 0.3)
		sine_points.append(Vector2(x, y))
	
	for i in range(sine_points.size() - 1):
		draw_line(sine_points[i], sine_points[i + 1], Color(0, 0.8, 0, 0.5), 2)
	
	# Draw cosine wave
	var cosine_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - cos(t + angle) * (WAVE_AMPLITUDE * 0.3)
		cosine_points.append(Vector2(x, y))
	
	for i in range(cosine_points.size() - 1):
		draw_line(cosine_points[i], cosine_points[i + 1], Color(0.8, 0.8, 0, 0.5), 2)
	
	# Draw combined wave (sin + cos)
	var combined_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - (sin(t + angle) + cos(t + angle)) * (WAVE_AMPLITUDE * 0.3)
		combined_points.append(Vector2(x, y))
	
	for i in range(combined_points.size() - 1):
		draw_line(combined_points[i], combined_points[i + 1], Color(1, 0, 0, 0.8), 2)
	
	# Draw complex wave (sin + 0.5*sin(2x) + 0.25*sin(3x))
	var complex_points = PackedVector2Array()
	for i in range(WAVE_SEGMENTS + 1):
		var t = float(i) / WAVE_SEGMENTS * TIME_SCALE * 2 * PI
		var x = start_x + (float(i) / WAVE_SEGMENTS) * GRAPH_WIDTH
		var y = axis_y - (
			sin(t + angle) * (WAVE_AMPLITUDE * 0.3) + 
			0.5 * sin(2 * (t + angle)) * (WAVE_AMPLITUDE * 0.3) + 
			0.25 * sin(3 * (t + angle)) * (WAVE_AMPLITUDE * 0.3)
		)
		complex_points.append(Vector2(x, y))
	
	for i in range(complex_points.size() - 1):
		draw_line(complex_points[i], complex_points[i + 1], Color(0.5, 0, 0.8, 0.8), 2)
	
	# Draw labels
	var font = get_theme_default_font()
	var font_size = 16
	draw_string(font, Vector2(start_x + GRAPH_WIDTH + 10, axis_y), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Draw legend
	var legend_x = start_x
	var legend_y = axis_y - WAVE_AMPLITUDE * 1.1
	
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 20, legend_y), Color(0, 0.8, 0, 0.5), 2)
	draw_string(font, Vector2(legend_x + 25, legend_y), "sin(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	legend_y += 20
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 20, legend_y), Color(0.8, 0.8, 0, 0.5), 2)
	draw_string(font, Vector2(legend_x + 25, legend_y), "cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	legend_y += 20
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 20, legend_y), Color(1, 0, 0, 0.8), 2)
	draw_string(font, Vector2(legend_x + 25, legend_y), "sin(θ) + cos(θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	legend_y += 20
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 20, legend_y), Color(0.5, 0, 0.8, 0.8), 2)
	draw_string(font, Vector2(legend_x + 25, legend_y), "sin(θ) + 0.5sin(2θ) + 0.25sin(3θ)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
