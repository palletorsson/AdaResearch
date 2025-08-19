extends MeshInstance3D
class_name RandomGaussianTexture

# Constants
const DEFAULT_WIDTH := 640
const DEFAULT_HEIGHT := 240
const DOT_RADIUS := 8
const DOT_ALPHA := 0.004

# Image properties
var image := Image.new()
var texture := ImageTexture.create_from_image(image)
var width := DEFAULT_WIDTH
var height := DEFAULT_HEIGHT
var mean := DEFAULT_WIDTH / 2
var stddev := 60.0

# Animation control
var update_interval := 0.01  # Time between dots in seconds
var timer: Timer
var active := true

# Distribution properties
var vertical_spread := 100  # Range of vertical randomness

func _init(p_width: int = DEFAULT_WIDTH, p_height: int = DEFAULT_HEIGHT, p_stddev: float = 60.0):
	width = p_width
	height = p_height
	stddev = p_stddev
	mean = width / 2
	_initialize_image()

func _ready():
	randomize()  # Initialize random number generator with different seed each run
	_setup_timer()

# Initialize the image with a white background
func _initialize_image() -> void:
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	if image.get_data().size() == 0:
		push_error("Failed to create image for Gaussian texture")
		return
		
	# Fill with white background
	image.fill(Color.YELLOW)
	
	# Create texture from the image
	texture = ImageTexture.create_from_image(image)
	
	# Apply the texture to this MeshInstance3D
	_update_material(texture)

# Set up the timer for periodic updates
func _setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = update_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func _on_timer_timeout() -> void:
	if active:
		_add_gaussian_dot()
		_update_texture()

# Add a new dot at a position determined by Gaussian distribution
func _add_gaussian_dot() -> void:
	# Sample x-position from Gaussian distribution
	var x_pos := _random_gaussian(mean, stddev)
	
	# Randomize y-position in the middle area with some spread
	var y_pos := height / 2 + randi_range(-vertical_spread, vertical_spread)
	
	# Draw a circular dot
	_draw_dot(int(x_pos), int(y_pos), DOT_RADIUS, Color(0, 0, 0, DOT_ALPHA))

# Draw a circular dot on the image
func _draw_dot(center_x: int, center_y: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			# Check if point is inside the circle
			if dx*dx + dy*dy <= radius*radius:
				var px = clamp(center_x + dx, 0, width - 1)
				var py = clamp(center_y + dy, 0, height - 1)
				
				# Blend the new dot with existing color
				var current_color := image.get_pixel(px, py)
				var new_color := current_color.blend(color)
				image.set_pixel(px, py, new_color)

# Update the texture after modifying the image
func _update_texture() -> void:
	texture.update(image)

# Update the material with the texture
func _update_material(tex: ImageTexture) -> void:
	if material_override is ShaderMaterial:
		var shader_material := material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	elif material_override is StandardMaterial3D:
		var std_material := material_override as StandardMaterial3D
		std_material.albedo_texture = tex
	else:
		# Create a new material if none exists
		var new_material := StandardMaterial3D.new()
		new_material.albedo_texture = tex
		material_override = new_material

# Generate a random number with Gaussian distribution using Box-Muller transform
func _random_gaussian(mean: float, stddev: float) -> float:
	# Use Box-Muller transform to generate Gaussian distribution
	var u1 := randf()
	var u2 := randf()
	
	# Prevent logarithm of zero
	if u1 < 0.0001:
		u1 = 0.0001
		
	var z0 := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + stddev * z0

# Public methods for controlling the visualization

# Start the animation
func start() -> void:
	active = true
	if not timer.is_stopped():
		timer.start()

# Pause the animation
func pause() -> void:
	active = false

# Clear the image and restart
func reset() -> void:
	_initialize_image()
	
# Set the standard deviation (spread) of the distribution
func set_standard_deviation(new_stddev: float) -> void:
	stddev = new_stddev

# Set the update interval (speed)
func set_update_interval(interval: float) -> void:
	update_interval = interval
	if timer:
		timer.wait_time = interval

# Set the vertical spread of dots
func set_vertical_spread(spread: int) -> void:
	vertical_spread = spread
