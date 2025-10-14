extends Node2D

@export var angle_acceleration: float = 0.01  # Angular acceleration
@export var angle_velocity: float = 0.0  # Angular velocity
@export var angle: float = 0.0  # Current angle

@export var line_length: float = 60.0  # Length of the line on both sides
@export var circle_radius: float = 12.0  # Radius of the circles

var trail_points: Array[Vector2] = []  # Stores the trail points
@export var max_trail_points: int = 20  # Maximum number of trail points

var trace_image: Image = Image.new()  # Image to store the trace

var trace_texture_data: ImageTexture
var right_pos : Vector2
var left_pos : Vector2
# Initialize the trace texture
@onready var drawtexture = get_node_or_null("../../DrawTexture")

func _ready():
	# Initialize the trace image
	if drawtexture and drawtexture is MeshInstance3D:
		print("DrawTexture is a valid MeshInstance3D node.")
	else:
		print("DrawTexture is not found or has the wrong type.")
	init_trace_image()
	queue_redraw()

func init_trace_image():
	# Define the dimensions for the trace image
	var width = 800  # Adjust to your desired size
	var height = 800

	trace_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	trace_image.fill(Color(0, 0, 0, 0))  # Transparent background
	trace_texture_data = ImageTexture.create_from_image(trace_image)
	
	update_material(trace_texture_data)
	
func _process(delta: float):
	# Update angular motion
	angle_velocity += angle_acceleration * delta
	angle += angle_velocity * delta


	# Calculate the position of the circles
	right_pos = Vector2(cos(angle), sin(angle)) * line_length
	left_pos = Vector2(-cos(angle), -sin(angle)) * line_length

	# Add the trail point (one of the circles)
	trail_points.append(right_pos)
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()

	# Draw to the trace image
	draw_to_trace(right_pos)
	line_length = line_length + 0.01
	# Trigger a redraw
	queue_redraw()

func draw_to_trace(position: Vector2):
	# Map the position to the image coordinates
	var image_center = Vector2(trace_image.get_width() / 2, trace_image.get_height() / 2)
	var draw_pos = image_center + position

	# Ensure the position is within the image bounds
	if draw_pos.x >= 0 and draw_pos.y >= 0 and draw_pos.x < trace_image.get_width() and draw_pos.y < trace_image.get_height():
		trace_image.set_pixelv(draw_pos, Color(0.0, 1.0, 0.0, 1.0))  # Green trail dot

	trace_texture_data = ImageTexture.create_from_image(trace_image)
	
	update_material(trace_texture_data)

func _draw():
	# Get the center of the canvas
	var canvas_center = get_viewport_rect().size / 2

	# Manually calculate the translated positions
	var translated_right_pos = canvas_center + right_pos
	var translated_left_pos = canvas_center + left_pos

	# Rotate around the center by applying rotation to positions
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)

	translated_right_pos = canvas_center + Vector2(
	cos_angle * right_pos.x - sin_angle * right_pos.y,
	sin_angle * right_pos.x + cos_angle * right_pos.y
	)

	translated_left_pos = canvas_center + Vector2(
	cos_angle * left_pos.x - sin_angle * left_pos.y,
	sin_angle * left_pos.x + cos_angle * left_pos.y
	)

	# Draw the main line
	draw_line(translated_right_pos, translated_left_pos, Color(0, 0, 0), 2)

	# Draw the circles
	draw_circle(translated_right_pos, circle_radius, Color(0.5, 0.5, 0.5))  # Right circle
	draw_circle(translated_left_pos, circle_radius, Color(0.5, 0.5, 0.5))  # Left circle



func update_material(tex: ImageTexture):
	if drawtexture.material_override is ShaderMaterial:
		var shader_material = drawtexture.material_override as ShaderMaterial
		shader_material.set_shader_parameter("transparency", 1)
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		drawtexture.material_override = material
