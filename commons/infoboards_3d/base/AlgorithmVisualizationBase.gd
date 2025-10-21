# AlgorithmVisualizationBase.gd
# Base class for all algorithm visualizations
# Provides common animation controls and drawing infrastructure
extends Control
class_name AlgorithmVisualizationBase

# Export parameters
@export var visualization_type: String = "default"
@export var animation_speed: float = 1.0
@export var update_interval: float = 0.1

# State variables
var animation_playing: bool = true
var time_elapsed: float = 0.0
var time_since_last_update: float = 0.0

# Random number generator
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Constants
const PI_2 = PI * 2.0

func _ready():
	rng.randomize()
	custom_minimum_size = Vector2(400, 400)  # Minimum visualization size
	reset_simulation()

func _process(delta):
	if animation_playing:
		time_elapsed += delta * animation_speed
		time_since_last_update += delta

		# Periodic updates
		if time_since_last_update >= update_interval:
			time_since_last_update = 0.0
			on_periodic_update()

		# Continuous updates
		on_animation_update(delta)

	queue_redraw()

# Virtual functions - override in child classes

# Called when simulation should reset to initial state
func reset_simulation() -> void:
	time_elapsed = 0.0
	time_since_last_update = 0.0
	on_reset()

# Called once per update_interval
func on_periodic_update() -> void:
	pass

# Called every frame when animation is playing
func on_animation_update(delta: float) -> void:
	pass

# Called when reset_simulation is triggered
func on_reset() -> void:
	pass

# Main drawing function
func _draw():
	if size.x < 10 or size.y < 10:
		return

	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08), true)

	# Call child class drawing
	draw_visualization()

# Virtual - override in child classes to draw custom visualizations
func draw_visualization() -> void:
	# Default: draw placeholder text
	var center = size / 2
	var text = "Visualization: " + visualization_type
	draw_string(get_theme_default_font(), center - Vector2(100, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

# Public API

func set_animation_playing(playing: bool) -> void:
	animation_playing = playing

func set_animation_speed(speed: float) -> void:
	animation_speed = clamp(speed, 0.1, 5.0)

func set_visualization_type(type: String) -> void:
	visualization_type = type
	reset_simulation()

# Utility drawing functions

func draw_grid(cell_size: float, line_color: Color = Color(0.2, 0.2, 0.25, 0.5)) -> void:
	"""Draw a grid overlay"""
	var cols = int(size.x / cell_size)
	var rows = int(size.y / cell_size)

	# Vertical lines
	for i in range(cols + 1):
		var x = i * cell_size
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 1.0)

	# Horizontal lines
	for i in range(rows + 1):
		var y = i * cell_size
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1.0)

func draw_axis(origin: Vector2, axis_length: float = 100.0, axis_color: Color = Color.WHITE) -> void:
	"""Draw X and Y axes"""
	# X axis (red)
	draw_line(origin, origin + Vector2(axis_length, 0), Color.RED, 2.0)
	draw_string(get_theme_default_font(), origin + Vector2(axis_length + 5, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

	# Y axis (green)
	draw_line(origin, origin + Vector2(0, -axis_length), Color.GREEN, 2.0)
	draw_string(get_theme_default_font(), origin + Vector2(5, -axis_length - 5), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GREEN)

func draw_circle_outline(center: Vector2, radius: float, color: Color, segments: int = 32, width: float = 2.0) -> void:
	"""Draw a circle outline"""
	var points = PackedVector2Array()
	for i in range(segments + 1):
		var angle = (float(i) / segments) * PI_2
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

	for i in range(segments):
		draw_line(points[i], points[i + 1], color, width)

func draw_arrow(from: Vector2, to: Vector2, color: Color, width: float = 2.0, arrow_size: float = 10.0) -> void:
	"""Draw an arrow from point to point"""
	draw_line(from, to, color, width)

	# Arrow head
	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)

	var tip1 = to - direction * arrow_size + perpendicular * (arrow_size * 0.5)
	var tip2 = to - direction * arrow_size - perpendicular * (arrow_size * 0.5)

	draw_line(to, tip1, color, width)
	draw_line(to, tip2, color, width)

func draw_text_centered(text: String, position: Vector2, font_size: int = 16, color: Color = Color.WHITE) -> void:
	"""Draw text centered at position"""
	var font = get_theme_default_font()
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var offset = text_size / 2
	draw_string(font, position - offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func draw_label(text: String, position: Vector2, font_size: int = 12, color: Color = Color.WHITE) -> void:
	"""Draw a simple label"""
	draw_string(get_theme_default_font(), position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func lerp_color(from: Color, to: Color, weight: float) -> Color:
	"""Linear interpolation between colors"""
	return from.lerp(to, weight)

func oscillate(amplitude: float = 1.0, frequency: float = 1.0, phase: float = 0.0) -> float:
	"""Oscillating value using sine wave"""
	return sin(time_elapsed * frequency + phase) * amplitude

func pulse(min_val: float = 0.0, max_val: float = 1.0, frequency: float = 1.0) -> float:
	"""Pulsing value between min and max"""
	var t = (sin(time_elapsed * frequency) + 1.0) * 0.5
	return lerp(min_val, max_val, t)

func get_center() -> Vector2:
	"""Get center point of control"""
	return size / 2

func get_random_point() -> Vector2:
	"""Get random point within control bounds"""
	return Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))

func get_random_color() -> Color:
	"""Get random color"""
	return Color(rng.randf(), rng.randf(), rng.randf())
