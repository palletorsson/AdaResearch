extends Node2D

# Parameters for the rotating disk
@export var rotation_speed: float = 30.0  # Degrees per second
@export var disk_radius: float = 400.0
@export var background_color: Color = Color(0.95, 0.95, 0.9, 1.0)  # Cream color

# Fish parameters
@export var fish_color: Color = Color(0.9, 0.2, 0.1, 1.0)  # Red
@export var fish_position_radius: float = 250.0
@export var fish_size: Vector2 = Vector2(60, 30)  # Increased size
@export var fish_sine_amplitude: float = 15.0  # Amplitude of sine wave
@export var fish_sine_frequency: float = 3.0   # Frequency of sine wave

# Circle parameters
@export var circle_colors: Array[Color] = [
	Color(0.2, 0.6, 0.5, 1.0),  # Teal
	Color(0.2, 0.6, 0.5, 1.0),  # Teal
	Color(0.2, 0.6, 0.5, 1.0)   # Teal
]
@export var circle_radii: Array[float] = [300.0, 250.0, 180.0]
@export var circle_line_width: float = 3.0
@export var circle_offset: Vector2 = Vector2(20, 15)  # Offset to create the displaced effect

# Rotation variables
var disk_node: Node2D
var fish_node: Node2D
var current_rotation: float = 0.0
var fish_time: float = 0.0

func _ready():
	# Create the main disk
	create_disk()
	
	# Create the circles
	create_circles()
	
	# Create the fish
	create_fish()

func _process(delta):
	# Update rotation
	current_rotation += rotation_speed * delta
	
	# Apply rotation to the disk
	disk_node.rotation_degrees = current_rotation
	
	# Update fish animation
	fish_time += delta
	update_fish_position(fish_time)

func update_fish_position(time: float):
	if fish_node:
		# Calculate base angle with increasing time
		var base_angle = time * 0.5
		
		# Calculate sine wave offset
		var sine_offset = fish_sine_amplitude * sin(time * fish_sine_frequency)
		
		# Calculate position with sine wave applied perpendicular to motion
		var radius = fish_position_radius + sine_offset
		var pos_x = cos(base_angle) * radius
		var pos_y = sin(base_angle) * radius
		fish_node.position = Vector2(pos_x, pos_y)
		
		# Rotate the fish to follow the circle tangent plus account for sine
		var tangent_angle = base_angle + PI/2
		var sine_angle = atan2(fish_sine_amplitude * fish_sine_frequency * cos(time * fish_sine_frequency), 
							  fish_position_radius)
		fish_node.rotation = tangent_angle + sine_angle

func create_disk():
	# Create a disk node
	disk_node = Node2D.new()
	add_child(disk_node)
	
	# Center the disk
	disk_node.position = get_viewport_rect().size / 2
	
	# Create the disk background
	var background = create_circle_shape(disk_radius, background_color, true)
	disk_node.add_child(background)

func create_circles():
	# Create the concentric circles
	for i in range(circle_radii.size()):
		var circle = create_circle_shape(circle_radii[i], circle_colors[i], false, circle_line_width)
		
		# Apply progressively increasing offset for inner circles
		# The innermost circle gets the most offset
		var offset_multiplier = float(circle_radii.size() - i) / circle_radii.size()
		circle.position = circle_offset * offset_multiplier
		
		disk_node.add_child(circle)

func create_fish():
	# Create a fish node
	var fish = Node2D.new()
	disk_node.add_child(fish)
	
	# We'll animate the fish in _process instead of setting a static position
	# Create the fish body
	var fish_body = draw_fish(fish_color)
	fish.add_child(fish_body)
	
	# Store reference to the fish for animation
	fish_node = fish
	
	# Initial position and rotation
	update_fish_position(0.0)

func create_circle_shape(radius: float, color: Color, filled: bool = false, line_width: float = 2.0) -> Node2D:
	var node = Node2D.new()
	
	if filled:
		# Create a filled circle using a polygon
		var polygon = Polygon2D.new()
		var points = PackedVector2Array()
		
		# Generate points around the circle
		var num_points = 64
		for i in range(num_points):
			var angle = 2 * PI * i / num_points
			points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		
		polygon.polygon = points
		polygon.color = color
		node.add_child(polygon)
	else:
		# Create an outline circle using a line
		var line = Line2D.new()
		
		# Generate points around the circle
		var num_points = 64
		for i in range(num_points + 1):
			var angle = 2 * PI * i / num_points
			line.add_point(Vector2(cos(angle) * radius, sin(angle) * radius))
		
		line.width = line_width
		line.default_color = color
		node.add_child(line)
	
	return node

func draw_fish(color: Color) -> Node2D:
	var fish_node = Node2D.new()
	
	# Fish body
	var body = Polygon2D.new()
	var body_points = PackedVector2Array([
		Vector2(-fish_size.x/2, 0),
		Vector2(-fish_size.x/4, -fish_size.y/2),
		Vector2(fish_size.x/2, 0),
		Vector2(-fish_size.x/4, fish_size.y/2)
	])
	body.polygon = body_points
	body.color = color
	
	# Fish tail
	var tail = Polygon2D.new()
	var tail_points = PackedVector2Array([
		Vector2(-fish_size.x/2, 0),
		Vector2(-fish_size.x * 0.8, -fish_size.y/3),
		Vector2(-fish_size.x * 0.9, 0),
		Vector2(-fish_size.x * 0.8, fish_size.y/3)
	])
	tail.polygon = tail_points
	tail.color = color
	
	# White details
	var details = Line2D.new()
	details.add_point(Vector2(-fish_size.x/4, 0))
	details.add_point(Vector2(fish_size.x/3, 0))
	details.width = fish_size.y / 6
	details.default_color = Color.WHITE
	
	fish_node.add_child(body)
	fish_node.add_child(tail)
	fish_node.add_child(details)
	
	return fish_node

# Alternative implementation using a sprite
func alternative_with_image():
	# This function shows how to use an actual image instead of drawing
	# In a real project, you would load the image as a texture
	
	disk_node = Node2D.new()
	add_child(disk_node)
	
	# Center the disk
	disk_node.position = get_viewport_rect().size / 2
	
	# Create a sprite
	var sprite = Sprite2D.new()
	
	# In a real project, you would load the image like this:
	# sprite.texture = load("res://koi_disk.png")
	
	disk_node.add_child(sprite)
	
	# The rotation would happen automatically in _process

# If you want to use an actual image instead of drawing, here's how to do it
func using_actual_image(image_path: String):
	disk_node = Node2D.new()
	add_child(disk_node)
	
	# Center the disk
	disk_node.position = get_viewport_rect().size / 2
	
	# Create a sprite with the image
	var sprite = Sprite2D.new()
	sprite.texture = load(image_path)
	disk_node.add_child(sprite)
