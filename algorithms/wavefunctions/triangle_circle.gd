extends Node2D

@export var circle_radius: float = 200.0  # Radius of the circle
@export var triangle_side: float = 100.0  # Side length of the triangle
@export var angular_speed: float = 0.5  # Speed of the triangle's rotation around the circle
@export var trace_color: Color = Color(0.0, 1.0, 0.0, 1.0)
@export var steps_per_edge: float = 20  # Steps to divide each triangle edge

var angle: float = 0.0  # Current angle of rotation
var trace_step: float = 0.0  # Progress of the dot along the triangle's outline
var edge_index: int = 0  # Current edge the dot is tracing

var triangle_vertices: Array[Vector2]  # Triangle vertices
var trace_position: Vector2  # Position of the trace dot
var trace_image: Image = Image.new()  # Image to store the trace
var trace_texture_data: ImageTexture
@onready var drawtexture = $"../../DrawTexture"
var x = 0 
var y = 0
func _ready():
	calculate_triangle_vertices()
	trace_position = triangle_vertices[0]  # Start at the first vertex
	set_process(true)
	init_trace_image()

func init_trace_image():
	var width = 800
	var height = 800
	trace_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	trace_image.fill(Color(0, 0, 0, 0))  # Transparent background
	trace_texture_data = ImageTexture.create_from_image(trace_image)
	update_material(trace_texture_data)

func _process(delta):
	# Move triangle around the circle
	angle += angular_speed * delta
	if angle >= TAU:
		angle -= TAU

	# Move dot along the triangle's outline
	update_trace_step(delta)
	queue_redraw()

func _draw():
	var screen_center = get_viewport_rect().size / 2
	var center = screen_center + Vector2(circle_radius * cos(angle), circle_radius * sin(angle))
	var tangent = Vector2(-sin(angle), cos(angle))  # Tangent to the circle

	# Rotate and translate triangle vertices
	var transformed_vertices = []
	for vertex in triangle_vertices:
		var rotated_vertex = vertex.rotated(angle)
		var translated_vertex = center + tangent * rotated_vertex.x + Vector2(-tangent.y, tangent.x) * rotated_vertex.y
		transformed_vertices.append(translated_vertex)

	# Draw the triangle
	draw_line(transformed_vertices[0], transformed_vertices[1], Color.BLUE, 2)
	draw_line(transformed_vertices[1], transformed_vertices[2], Color.BLUE, 2)
	draw_line(transformed_vertices[2], transformed_vertices[0], Color.BLUE, 2)

	# Draw the trace dot
	draw_circle(trace_position, 5, Color.RED)

	# Draw the circle
	draw_circle(screen_center, circle_radius, Color.GRAY)

func calculate_triangle_vertices():
	var half_base = triangle_side / 2
	var height = triangle_side * sqrt(3) / 2
	triangle_vertices = [
		Vector2(-half_base, 0),  # Bottom left
		Vector2(half_base, 0),   # Bottom right
		Vector2(0, -height)      # Top
	]

func update_trace_step(delta):
	var progress_per_edge = delta * steps_per_edge
	trace_step += progress_per_edge

	if trace_step >= 1.0:
		trace_step -= 1.0
		edge_index = (edge_index + 1) % triangle_vertices.size()  # Ensure index wraps around

	# Calculate current edge
	var current_vertex = triangle_vertices[edge_index]
	var next_vertex = triangle_vertices[(edge_index + 1) % triangle_vertices.size()]  # Wrap to the first vertex if needed

	# Interpolate along the edge
	trace_position = current_vertex.lerp(next_vertex, trace_step)
	trace_position += Vector2(circle_radius * cos(angle), circle_radius * sin(angle)) * 200

		 
	# Add trace to the image
	set_pixel_block(trace_image, trace_position / Vector2(1000,1000)+ Vector2(300,300), trace_color, 3)
	print(trace_position)
	# Update texture
	trace_texture_data = ImageTexture.create_from_image(trace_image)
	update_material(trace_texture_data)


func set_pixel_block(image: Image, position: Vector2, color: Color, block_size: int):
	for y in range(-block_size / 2, block_size / 2):
		for x in range(-block_size / 2, block_size / 2):
			var block_position = position + Vector2(x, y)
			if block_position.x >= 0 and block_position.y >= 0 and block_position.x < image.get_width() and block_position.y < image.get_height():
				image.set_pixelv(block_position, color)

func update_material(tex: ImageTexture):
	if drawtexture.material_override is ShaderMaterial:
		var shader_material = drawtexture.material_override as ShaderMaterial
		shader_material.set_shader_parameter("transparancy", 1)
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		drawtexture.material_override = material
