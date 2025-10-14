extends Node2D

@export var angle_acceleration: float = 0.0001  # Angular acceleration
@export var angle_velocity: float = 0.0  # Angular velocity
@export var angle: float = 0.0  # Current angle

@export var radius: float = 100.0  # Radius of the unit circle
@export var angular_velocity: float = 2 * PI  # Angular speed in radians per second
@export var wave_amplitude: float = 100.0  # Amplitude of the sine wave
@export var wave_length: float = 200.0  # Distance between peaks of the sine wave
@export var wave_speed: float = 50.0  # Horizontal speed of the wave
@export var line_color: Color = Color(0.0, 1.0, 0.0)  # Color of the sine wave
@export var circle_color: Color = Color(1.0, 0.0, 0.0)  # Color of the point

var time: float = 0.0  # Time tracker for wave progression
var wave_points: Array[Vector2] = []  # Stores points for the sine wave

# Texture-related variables
var trace_image: Image = Image.new()  # Image to store the sine wave
var trace_texture: ImageTexture = ImageTexture.new()  # Texture to render the sine wave
@onready var drawtexture = $"../../DrawTexture"

func _ready():
	# Initialize the trace image
	init_trace_image()

func init_trace_image():
	# Define the dimensions for the trace image
	var width = 800  # Adjust to your desired size
	var height = 800

	# Initialize the trace image
	trace_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	trace_image.fill(Color(0, 0, 0, 0))  # Transparent background
	trace_texture = ImageTexture.create_from_image(trace_image)
	
	update_material(trace_texture)

func _process(delta: float):
	# Update angular motion
	angle_velocity += angle_acceleration * delta
	angle += angular_velocity * delta

	# Calculate the sine wave progression
	time += wave_speed * delta
	if time >= wave_length:
		time -= wave_length

	var y = wave_amplitude * sin(angle)
	wave_points.append(Vector2(time, y))
	if wave_points.size() > trace_image.get_width():
		wave_points.pop_front()

	# Update the sine wave on the texture
	draw_to_trace()

	# Trigger a redraw for the _draw() function
	queue_redraw()

func _draw():
	# Translate to the center of the canvas
	var center = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)

	# Draw the unit circle
	for angle_step in range(0, 360, 5):
		var radians = deg_to_rad(angle_step)
		var circle_point = center + Vector2(radius * cos(radians), radius * sin(radians))
		draw_circle(circle_point, 1, Color(0.5, 0.5, 0.5))  # Small gray dots for the circle

	# Draw the sine wave
	if wave_points.size() > 1:
		for i in range(wave_points.size() - 1):
			var p1 = center + wave_points[i]
			var p2 = center + wave_points[i + 1]
			draw_line(p1, p2, line_color, 2)

	# Draw the rotating points
	var right_pos = center + Vector2(cos(angle), sin(angle)) * radius
	var left_pos = center + Vector2(-cos(angle), -sin(angle)) * radius
	draw_circle(right_pos, 5, circle_color)  # Right point
	draw_circle(left_pos, 5, circle_color)  # Left point

func draw_to_trace():
	# Map the image center
	var image_center = Vector2(trace_image.get_width() / 2, trace_image.get_height() / 2)

	# Clear the image
	trace_image.fill(Color(0, 0, 0, 0))  # Clear the image

	# Draw the sine wave onto the texture
	for i in range(wave_points.size() - 1):
		var p1 = image_center + wave_points[i]
		var p2 = image_center + wave_points[i + 1]
		draw_line_to_image(p1, p2, line_color)

	# Update the texture with the modified image
	trace_texture = ImageTexture.create_from_image(trace_image)
	update_material(trace_texture)

func draw_line_to_image(start: Vector2, end: Vector2, color: Color):
	var diff = end - start
	var length = diff.length()
	for i in range(int(length)):
		var lerp_point = start + diff.normalized() * i
		trace_image.set_pixelv(lerp_point, color)

func update_material(tex: ImageTexture):
	if drawtexture.material_override is ShaderMaterial:
		var shader_material = drawtexture.material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		drawtexture.material_override = material
