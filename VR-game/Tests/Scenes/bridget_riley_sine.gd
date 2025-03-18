extends Node2D

# Parameters for controlling the patterns
@export var pattern_type: int = 0  # 0: zigzag, 1: waves, 2: circles, 3: shifted grids
@export var line_thickness: float = 3.0
@export var pattern_spacing: float = 15.0
@export var canvas_size: Vector2 = Vector2(800, 800)
@export var mask_shape: int = 0  # 0: circle, 1: square, 2: ellipse, 3: none
@export var mask_size: Vector2 = Vector2(700, 700)
@export var color1: Color = Color.BLACK
@export var color2: Color = Color.WHITE
@export var use_color_gradient: bool = false
@export var angle: float = 0.0  # Rotation in degrees

func _ready():
	# Generate the pattern based on the selected type
	match pattern_type:
		0:
			create_zigzag_pattern()
		1:
			create_wave_pattern()
		2:
			create_concentric_pattern()
		3:
			create_grid_pattern()

func create_zigzag_pattern():
	# This creates a zigzag pattern similar to the one in the image
	var canvas = create_canvas()
	
	# Create zigzag lines
	var y_offset = 0
	while y_offset < canvas_size.y + pattern_spacing:
		var points = PackedVector2Array()
		var x = 0
		var direction = 1
		
		while x < canvas_size.x + pattern_spacing:
			points.append(Vector2(x, y_offset))
			points.append(Vector2(x + pattern_spacing/2, y_offset + pattern_spacing * direction))
			
			direction *= -1
			x += pattern_spacing/2
		
		draw_line_on_canvas(canvas, points)
		y_offset += pattern_spacing * 2
	
	apply_mask(canvas)
	add_child(canvas)

func create_wave_pattern():
	# Creates sine wave patterns
	var canvas = create_canvas()
	
	# Draw horizontal wave lines
	var y_pos = 0
	var amplitude = pattern_spacing
	var frequency = 0.02
	
	while y_pos < canvas_size.y + pattern_spacing:
		var points = PackedVector2Array()
		
		for x in range(0, int(canvas_size.x) + 1, 5):
			var y = y_pos + amplitude * sin(frequency * x)
			points.append(Vector2(x, y))
		
		draw_line_on_canvas(canvas, points)
		y_pos += pattern_spacing * 1.5
	
	apply_mask(canvas)
	add_child(canvas)

func create_concentric_pattern():
	# Create concentric circles or ellipses
	var canvas = create_canvas()
	var center = canvas_size / 2
	var max_radius = min(canvas_size.x, canvas_size.y) / 2
	
	for radius in range(0, int(max_radius) + 1, int(pattern_spacing)):
		# Fixed: Convert radius to int before using modulo
		if int(radius / pattern_spacing) % 2 == 0:
			continue
		
		var circle = CircleShape2D.new()
		circle.radius = radius
		
		var points = PackedVector2Array()
		var segments = 100
		
		for i in range(segments + 1):
			var angle_point = 2 * PI * i / segments
			var point = center + Vector2(cos(angle_point), sin(angle_point)) * radius
			points.append(point)
		
		draw_line_on_canvas(canvas, points)
	
	apply_mask(canvas)
	add_child(canvas)

func create_grid_pattern():
	# Creates a grid pattern with offset
	var canvas = create_canvas()
	
	# Vertical lines
	for x in range(0, int(canvas_size.x) + 1, int(pattern_spacing)):
		var shift = 10 * sin(x * 0.05)
		var points = PackedVector2Array()
		
		for y in range(0, int(canvas_size.y) + 1, 5):
			var shifted_y = y + shift
			points.append(Vector2(x, shifted_y))
		
		draw_line_on_canvas(canvas, points)
	
	# Horizontal lines
	for y in range(0, int(canvas_size.y) + 1, int(pattern_spacing)):
		var shift = 10 * sin(y * 0.05)
		var points = PackedVector2Array()
		
		for x in range(0, int(canvas_size.x) + 1, 5):
			var shifted_x = x + shift
			points.append(Vector2(shifted_x, y))
		
		draw_line_on_canvas(canvas, points)
	
	apply_mask(canvas)
	add_child(canvas)

func create_canvas():
	var node = Node2D.new()
	return node

# Fixed: Renamed function to avoid collision with built-in CanvasItem method
func draw_line_on_canvas(canvas: Node2D, points: PackedVector2Array):
	var line = Line2D.new()
	line.points = points
	line.width = line_thickness
	line.default_color = color1
	
	if use_color_gradient:
		var gradient = Gradient.new()
		gradient.add_point(0.0, color1)
		gradient.add_point(1.0, color2)
		
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		
		line.gradient = gradient_texture
	
	# Apply the rotation if needed
	if angle != 0:
		line.rotation_degrees = angle
		
	canvas.add_child(line)

func apply_mask(canvas: Node2D):
	if mask_shape == 3:  # No mask
		return
		
	# Create a Sprite2D with a transparent texture
	var mask_texture = Image.create(int(canvas_size.x), int(canvas_size.y), false, Image.FORMAT_RGBA8)
	mask_texture.fill(Color(0, 0, 0, 0))  # Transparent
	
	var center = canvas_size / 2
	var radius_x = mask_size.x / 2
	var radius_y = mask_size.y / 2
	
	# Draw the mask shape
	for x in range(int(canvas_size.x)):
		for y in range(int(canvas_size.y)):
			var pos = Vector2(x, y)
			var is_inside = false
			
			match mask_shape:
				0:  # Circle
					is_inside = pos.distance_to(center) <= radius_x
				1:  # Square
					is_inside = abs(pos.x - center.x) <= radius_x and abs(pos.y - center.y) <= radius_y
				2:  # Ellipse
					var normalized_x = (pos.x - center.x) / radius_x
					var normalized_y = (pos.y - center.y) / radius_y
					is_inside = normalized_x * normalized_x + normalized_y * normalized_y <= 1.0
			
			if is_inside:
				mask_texture.set_pixel(x, y, Color(1, 1, 1, 1))  # White
	
	var texture = ImageTexture.create_from_image(mask_texture)
	
	# Apply the mask using a shader
	var shader = ShaderMaterial.new()
	
	# Create shader code inline instead of loading from file
	var shader_code = """
	shader_type canvas_item;
	
	uniform sampler2D mask_texture;
	
	void fragment() {
		vec4 mask_color = texture(mask_texture, UV);
		
		if (mask_color.a < 0.5) {
			COLOR.a = 0.0;
		}
	}
	"""
	
	var shader_instance = Shader.new()
	shader_instance.code = shader_code
	shader.shader = shader_instance
	
	canvas.material = shader
	canvas.material.set_shader_parameter("mask_texture", texture)
