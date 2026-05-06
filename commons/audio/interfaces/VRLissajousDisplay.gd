# VRLissajousDisplay.gd - Lissajous figure visualization from two frequency parameters
# Creates an XY plot where X = sin(freq1*t) and Y = sin(freq2*t) with phase offset
# Uses Ada palette constants for display colors
extends Control
class_name VRLissajousDisplay

const _P = preload("res://commons/ui/ada_palette.gd")

@export var line_color: Color = Color(0, 0.78, 0.85, 1)  # Ada ACCENT_CYAN
@export var glow_color: Color = Color(0.2, 0.55, 0.95, 0.3)  # Ada ACCENT_BLUE faded
@export var background_color: Color = Color(0.02, 0.04, 0.08, 1)  # Ada SCREEN_BG
@export var grid_color: Color = Color(0.10, 0.18, 0.22, 0.5)  # Ada SCREEN_GRID
@export var line_width: float = 2.5
@export var sample_count: int = 512  # More samples = smoother curve
@export var trail_length: float = 1.0  # Seconds of trail to show
@export var phase_speed: float = 0.5  # How fast the phase shifts (creates animation)

# Frequency parameters (updated by rack controller)
var freq_x: float = 540.0  # start_freq
var freq_y: float = 880.0  # end_freq
var amplitude: float = 0.8  # Overall amplitude

# Animation state
var phase_offset: float = 0.0
var time_offset: float = 0.0

# Display properties
var display_rect: Rect2
var center: Vector2
var radius: float
var is_initialized: bool = false

# History for fade trail effect
var point_history: Array[PackedVector2Array] = []
var history_max: int = 8

func _ready() -> void:
	_initialize_display()
	resized.connect(_on_resized)
	print("VRLissajousDisplay: Ready with freq_x=%.1f, freq_y=%.1f" % [freq_x, freq_y])

func _initialize_display():
	##Initialize display geometry##
	display_rect = Rect2(Vector2.ZERO, size)
	center = size / 2.0
	radius = min(size.x, size.y) * 0.4
	is_initialized = true

func _process(delta: float):
	##Update animation and redraw##
	if not is_initialized:
		return
	
	# Animate phase for dynamic pattern
	phase_offset += delta * phase_speed * PI
	time_offset += delta
	
	queue_redraw()

func set_frequency_x(freq: float):
	##Set the X-axis frequency (e.g., start_freq)##
	freq_x = clamp(freq, 20.0, 5000.0)

func set_frequency_y(freq: float):
	##Set the Y-axis frequency (e.g., end_freq)##
	freq_y = clamp(freq, 20.0, 5000.0)

func set_frequencies(freq1: float, freq2: float):
	##Set both frequencies at once##
	freq_x = clamp(freq1, 20.0, 5000.0)
	freq_y = clamp(freq2, 20.0, 5000.0)

func set_amplitude(amp: float):
	##Set display amplitude##
	amplitude = clamp(amp, 0.0, 1.0)

func _draw():
	##Draw the Lissajous figure##
	if not is_initialized:
		return
	
	# Draw background
	draw_rect(display_rect, background_color)
	
	# Draw grid
	_draw_grid()
	
	# Generate and draw Lissajous curve
	var points = _generate_lissajous_points()
	
	# Store in history for trail effect
	point_history.push_front(points)
	if point_history.size() > history_max:
		point_history.pop_back()
	
	# Draw trail (older = dimmer)
	for i in range(point_history.size() - 1, -1, -1):
		var alpha = 1.0 - (float(i) / float(history_max))
		var trail_color = Color(line_color.r, line_color.g, line_color.b, alpha * 0.3)
		_draw_curve(point_history[i], trail_color, line_width * 0.5)
	
	# Draw glow layer
	_draw_curve(points, glow_color, line_width * 3.0)
	
	# Draw main curve
	_draw_curve(points, line_color, line_width)
	
	# Draw info text
	_draw_info()

func _generate_lissajous_points() -> PackedVector2Array:
	##Generate points for the Lissajous figure##
	var points = PackedVector2Array()
	
	# Normalize frequencies to create ratio
	# Using actual Hz values but scaled for visual appeal
	var ratio = freq_y / freq_x
	
	# Reduce to reasonable oscillation speed for display
	var base_freq = 1.0  # 1 cycle per second base
	var display_freq_x = base_freq
	var display_freq_y = base_freq * ratio
	
	# Generate points over one or more complete cycles
	var cycles = 2.0 * trail_length
	for i in range(sample_count):
		var t = (float(i) / float(sample_count - 1)) * cycles * PI * 2.0
		t += time_offset * 2.0  # Animation
		
		# Lissajous parametric equations: x = sin(at + phase), y = sin(bt)
		var x = sin(display_freq_x * t + phase_offset) * radius * amplitude
		var y = sin(display_freq_y * t) * radius * amplitude
		
		# Transform to screen coordinates
		var screen_pos = center + Vector2(x, -y)  # Invert Y for screen coords
		points.append(screen_pos)
	
	return points

func _draw_curve(points: PackedVector2Array, color: Color, width: float):
	##Draw a curve from points with antialiasing##
	if points.size() < 2:
		return
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)

func _draw_grid():
	##Draw oscilloscope-style grid##
	var grid_divisions = 4
	
	# Draw circular guides
	for i in range(1, grid_divisions + 1):
		var guide_radius = radius * (float(i) / float(grid_divisions))
		var alpha = 0.3 if i == grid_divisions else 0.15
		var guide_color = Color(grid_color.r, grid_color.g, grid_color.b, alpha)
		draw_arc(center, guide_radius, 0, TAU, 64, guide_color, 1.0)
	
	# Draw crosshairs
	draw_line(Vector2(center.x, 0), Vector2(center.x, size.y), grid_color, 1.0)
	draw_line(Vector2(0, center.y), Vector2(size.x, center.y), grid_color, 1.0)
	
	# Draw diagonal guides
	var diag_color = Color(grid_color.r, grid_color.g, grid_color.b, 0.1)
	draw_line(center + Vector2(-radius, -radius), center + Vector2(radius, radius), diag_color, 1.0)
	draw_line(center + Vector2(-radius, radius), center + Vector2(radius, -radius), diag_color, 1.0)

func _draw_info():
	##Draw frequency information##
	var font = get_theme_default_font()
	var info_color = Color(0.6, 0.8, 0.9, 0.9)
	var value_color = Color(0, 1, 1, 1)
	
	# Title
	draw_string(font, Vector2(8, 18), "LISSAJOUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, info_color)
	
	# Frequency ratio
	var ratio = freq_y / freq_x
	var ratio_text = "Ratio: %.2f:1" % ratio
	draw_string(font, Vector2(8, 34), ratio_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)
	
	# X frequency (start_freq)
	var freq_x_text = "X: %.0f Hz" % freq_x
	draw_string(font, Vector2(8, size.y - 22), freq_x_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 1, 1, 0.9))
	
	# Y frequency (end_freq)
	var freq_y_text = "Y: %.0f Hz" % freq_y
	draw_string(font, Vector2(8, size.y - 8), freq_y_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.5, 1, 0.9))

func _on_resized():
	##Handle resize##
	if is_initialized:
		_initialize_display()
		print("VRLissajousDisplay: Resized to ", size)
