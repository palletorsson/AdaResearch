extends Node2D

@export var length1: float = 100.0  # Length of the first pendulum
@export var length2: float = 100.0  # Length of the second pendulum
@export var mass1: float = 14.0  # Mass of the first pendulum
@export var mass2: float = 10.0  # Mass of the second pendulum
@export var gravity: float = 9.81  # Gravitational acceleration
@export var damping: float = 1.0001  # Damping factor for energy loss

@export var trail_color: Color = Color(0.5, 0.5, 0.5)  # Color of the trail
@export var max_trail_points: int = 200  # Maximum number of trail points
@export var trail_radius: float = 2.0  # Radius of the trail dots

@export var trace_color: Color = Color(0.0, 1.0, 0.0, 1.0)  # Color of the trace
@export var trace_thickness: int = 2  # Thickness of the trace

var angle1: float = PI / 4  # Initial angle of the first pendulum
var angle2: float = PI / 2  # Initial angle of the second pendulum
var angular_velocity1: float = 0.0  # Angular velocity of the first pendulum
var angular_velocity2: float = 0.0  # Angular velocity of the second pendulum

var pivot = Vector2(300, 200)  # Position of the pendulum's pivot
var pos1 = Vector2()  # Position of the first pendulum's mass
var pos2 = Vector2()  # Position of the second pendulum's mass
var trail_points: Array[Vector2] = []  # Stores the trail points of the second pendulum

var trace_image: Image = Image.new()  # Image to store the trace
var trace_texture_data: ImageTexture
@onready var drawtexture = $"../../DrawTexture"

func _ready():
	# Initial positions
	init_trace_image()
	calculate_positions()
	queue_redraw()

func init_trace_image():
	# Define the dimensions for the trace image
	var width = 800  # Adjust to your desired size
	var height = 800

	# Initialize the trace image

	trace_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	trace_image.fill(Color(0, 0, 0, 0))  # Transparent background
	trace_texture_data = ImageTexture.create_from_image(trace_image)
	
	update_material(trace_texture_data)
	# Initialize the trace texture

	
func _process(delta: float):
	update_pendulum(delta)
	calculate_positions()

	# Add the position of the second pendulum to the trail
	trail_points.append(pos2)

	# Limit the number of trail points
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()

	# Draw the trace
	draw_to_trace(pos2)
	
	# Trigger a redraw of the pendulum
	queue_redraw()

func _draw():
	# Draw the pendulum arms
	draw_line(pivot, pos1, Color(1, 1, 1), 2)  # Line to the first pendulum
	draw_line(pos1, pos2, Color(1, 1, 1), 2)  # Line to the second pendulum

	# Draw the pendulum masses
	draw_circle(pos1, mass1, Color(1, 0, 0))  # First pendulum mass (red)
	draw_circle(pos2, mass2, Color(0, 0, 1))  # Second pendulum mass (blue)

	# Draw the trail
	for point in trail_points:
		draw_circle(point, trail_radius, trail_color)

func update_pendulum(delta: float):
	var num1 = -gravity * (2 * mass1 + mass2) * sin(angle1)
	var num2 = -mass2 * gravity * sin(angle1 - 2 * angle2)
	var num3 = -2 * sin(angle1 - angle2) * mass2
	var num4 = angular_velocity2 ** 2 * length2 + angular_velocity1 ** 2 * length1 * cos(angle1 - angle2)
	var denom1 = length1 * (2 * mass1 + mass2 - mass2 * cos(2 * angle1 - 2 * angle2))
	var acceleration1 = (num1 + num2 + num3 * num4) / denom1

	var num5 = 2 * sin(angle1 - angle2)
	var num6 = angular_velocity1 ** 2 * length1 * (mass1 + mass2)
	var num7 = gravity * (mass1 + mass2) * cos(angle1)
	var num8 = angular_velocity2 ** 2 * length2 * mass2 * cos(angle1 - angle2)
	var denom2 = length2 * (2 * mass1 + mass2 - mass2 * cos(2 * angle1 - 2 * angle2))
	var acceleration2 = (num5 * (num6 + num7 + num8)) / denom2

	angular_velocity1 += acceleration1 * delta
	angular_velocity2 += acceleration2 * delta

	angular_velocity1 *= damping
	angular_velocity2 *= damping

	angle1 += angular_velocity1 * delta
	angle2 += angular_velocity2 * delta

func calculate_positions():
	# Calculate the positions of the pendulum masses
	pos1 = pivot + Vector2(length1 * sin(angle1), length1 * cos(angle1))
	pos2 = pos1 + Vector2(length2 * sin(angle2), length2 * cos(angle2))

func draw_to_trace(position: Vector2):
	# Ensure position is within the bounds of the trace_image
	if position.x < 0 or position.y < 0 or position.x >= trace_image.get_width() or position.y >= trace_image.get_height():
		return

	# Draw the trace onto the image
	for y in range(-trace_thickness, trace_thickness + 1):
		for x in range(-trace_thickness, trace_thickness + 1):
			var draw_pos = position + Vector2(x, y)
			if draw_pos.x >= 0 and draw_pos.y >= 0 and draw_pos.x < trace_image.get_width() and draw_pos.y < trace_image.get_height():
				trace_image.set_pixelv(draw_pos, trace_color)

	# Update the texture with the modified image
	trace_texture_data = ImageTexture.create_from_image(trace_image)
	
	update_material(trace_texture_data)
# Function to update the material's albedo texture
func update_material(tex: ImageTexture):
	if drawtexture.material_override is ShaderMaterial:
		var shader_material = drawtexture.material_override as ShaderMaterial
		shader_material.set_shader_parameter("transparancy", 1)
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		drawtexture.material_override = material
