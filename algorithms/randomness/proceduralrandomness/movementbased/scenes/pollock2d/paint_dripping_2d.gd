extends Node2D

# PollockPainting.gd
# A dynamic simulation of Jackson Pollock's action painting technique

@export var canvas_size: Vector2 = Vector2(1200, 800)  # Size of the canvas
@export var background_color: Color = Color(0.85, 0.82, 0.73)  # Tan/beige background

# Drip parameters
@export var min_drip_size: float = 1.0
@export var max_drip_size: float = 15.0
@export var drip_count: int = 50  # Reduced for continuous addition
@export var splatter_chance: float = 0.3  # Chance of creating additional splatter
@export var max_splatter_count: int = 10  # Max number of splatter drops per drip

# Line parameters
@export var min_line_width: float = 0.8
@export var max_line_width: float = 6.0
@export var line_segment_length: float = 10.0  # Length of each line segment
@export var line_curviness: float = 0.3  # How much the line can curve
@export var line_count: int = 20  # Reduced for continuous addition
@export var min_line_points: int = 10
@export var max_line_points: int = 100

# Continuous painting parameters
@export var paint_interval: float = 4.0  # Add new strokes every 4 seconds

# Color palette (Pollock-inspired)
var colors = [
	Color(0.0, 0.0, 0.0),       # Black
	Color(0.2, 0.2, 0.2),       # Dark gray
	Color(1.0, 1.0, 1.0),       # White
	Color(0.55, 0.27, 0.07),    # Brown
	Color(0.0, 0.2, 0.4),       # Deep blue
	Color(0.7, 0.1, 0.1)        # Dark red
]

# Storage for our generated artwork
var canvas: Image
var texture: ImageTexture
var rng = RandomNumberGenerator.new()
var painting_timer: Timer

func _ready():
	rng.randomize()
	
	# Create the canvas
	canvas = Image.create(int(canvas_size.x), int(canvas_size.y), false, Image.FORMAT_RGBA8)
	
	# Fill background
	canvas.fill(background_color)
	
	# Create initial painting
	create_initial_painting()
	
	# Update texture
	update_texture()
	
	# Create and setup continuous painting timer
	painting_timer = Timer.new()
	add_child(painting_timer)
	painting_timer.wait_time = paint_interval
	painting_timer.one_shot = false
	painting_timer.timeout.connect(add_new_painting_strokes)
	painting_timer.start()

func update_texture():
	texture = ImageTexture.create_from_image(canvas)
	$CanvasLayer/TextureRect.texture = texture
	
func create_initial_painting():
	# Add initial drip marks
	for i in range(drip_count):
		add_drip()
	
	# Add initial flowing lines
	for i in range(line_count):
		add_line()

func add_new_painting_strokes():
	# Add some new drips and lines to continuously evolve the painting
	for i in range(rng.randi_range(1, 5)):  # 1-5 new drips
		add_drip()
	
	for i in range(rng.randi_range(1, 3)):  # 1-3 new lines
		add_line()
	
	# Update the texture to show new strokes
	update_texture()

func add_drip():
	# Random position
	var pos = Vector2(
		rng.randf_range(0, canvas_size.x),
		rng.randf_range(0, canvas_size.y)
	)
	
	# Random color from palette
	var color = colors[rng.randi() % colors.size()]
	
	# Random size
	var size = rng.randf_range(min_drip_size, max_drip_size)
	
	# Draw the drip (circle)
	paint_circle(pos, size, color)
	
	# Chance to add splatter
	if rng.randf() < splatter_chance:
		var splatter_count = rng.randi_range(1, max_splatter_count)
		
		for j in range(splatter_count):
			var direction = Vector2(
				rng.randf_range(-1, 1),
				rng.randf_range(-1, 1)
			).normalized()
			
			var distance = rng.randf_range(size, size * 4)
			var splatter_pos = pos + direction * distance
			var splatter_size = size * rng.randf_range(0.1, 0.5)
			
			paint_circle(splatter_pos, splatter_size, color)

func add_line():
	# Random starting position
	var start_pos = Vector2(
		rng.randf_range(0, canvas_size.x),
		rng.randf_range(0, canvas_size.y)
	)
	
	# Random color
	var color = colors[rng.randi() % colors.size()]
	
	# Random line width
	var line_width = rng.randf_range(min_line_width, max_line_width)
	
	# Generate a flowing line (Pollock's characteristic gesture)
	var points = []
	points.append(start_pos)
	
	# Random direction
	var direction = Vector2(
		rng.randf_range(-1, 1),
		rng.randf_range(-1, 1)
	).normalized()
	
	# Random number of points
	var point_count = rng.randi_range(min_line_points, max_line_points)
	
	for i in range(point_count):
		# Add some randomness to direction (creates the Pollock flow)
		direction = direction.rotated(
			rng.randf_range(-line_curviness, line_curviness)
		).normalized()
		
		# Calculate next point
		var next_pos = points[-1] + direction * line_segment_length
		
		# Ensure we stay within canvas
		if next_pos.x < 0 or next_pos.x >= canvas_size.x or next_pos.y < 0 or next_pos.y >= canvas_size.y:
			# Bounce off the edges
			if next_pos.x < 0 or next_pos.x >= canvas_size.x:
				direction.x *= -1
			if next_pos.y < 0 or next_pos.y >= canvas_size.y:
				direction.y *= -1
				
			next_pos = points[-1] + direction * line_segment_length
			
			# Still out of bounds? Break the line
			if next_pos.x < 0 or next_pos.x >= canvas_size.x or next_pos.y < 0 or next_pos.y >= canvas_size.y:
				break
		
		points.append(next_pos)
		
		# Add drips along the line sometimes
		if rng.randf() < 0.1: # 10% chance per point
			paint_circle(next_pos, line_width * rng.randf_range(1.0, 3.0), color)
	
	# Draw the line
	for i in range(1, points.size()):
		paint_line(points[i-1], points[i], color, line_width)

func paint_circle(center: Vector2, radius: float, color: Color):
	# Make sure we're in bounds
	if center.x < 0 or center.x >= canvas_size.x or center.y < 0 or center.y >= canvas_size.y:
		return
		
	# Calculate bounds for the circle
	var x_min = max(0, center.x - radius - 1)
	var x_max = min(canvas_size.x - 1, center.x + radius + 1)
	var y_min = max(0, center.y - radius - 1)
	var y_max = min(canvas_size.y - 1, center.y + radius + 1)
	
	# Draw filled circle pixel by pixel
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Add some noise to the edges
				if dist > radius * 0.8 and rng.randf() < 0.5:
					continue
				
				canvas.set_pixel(x, y, color)

func paint_line(from: Vector2, to: Vector2, color: Color, width: float):
	# Basic line drawing algorithm
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	
	# Draw the line as a series of circles
	var step_size = width * 0.5  # Overlap circles to make a smooth line
	var steps = max(2, int(length / step_size))
	
	for i in range(steps + 1):
		var t = float(i) / steps
		var pos = from.lerp(to, t)
		
		# Calculate fade for the ends
		var fade = 1.0
		if i == 0 or i == steps:
			fade = 0.7
			
		# Apply width variation (drips get thinner at the ends)
		var adjusted_width = width * fade
		
		# Add some random variation to make it look more natural
		adjusted_width *= rng.randf_range(0.8, 1.2)
		
		paint_circle(pos, adjusted_width, color)
