extends MeshInstance3D
class_name GaussianBlurShader

# Animation control
@export var blur_duration: float = 10.0  # Duration to go from sharp to fully blurred
@export var max_blur_radius: float = 40.0  # Maximum blur kernel radius
@export var auto_start: bool = true

var blur_time: float = 0.0
var current_blur_radius: float = 0.0
var active: bool = false
var shader_material: ShaderMaterial

func _ready():
	_setup_shader_material()

	if auto_start:
		start()

	print("GaussianBlurShader: Initialized (GPU-accelerated)")

func _setup_shader_material():
	"""Setup the shader material"""
	# Create the circle texture
	var img = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)

	# Draw black circle in center
	var center = Vector2(256, 256)
	var radius = 150

	for y in range(512):
		for x in range(512):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= radius:
				img.set_pixel(x, y, Color.BLACK)

	var circle_texture = ImageTexture.create_from_image(img)

	# Load the spatial shader
	var shader = load("res://algorithms/randomness/distributions/gaussian/gaussian_blur_shader_3d.gdshader")

	# Create shader material
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Set shader parameters
	shader_material.set_shader_parameter("blur_amount", 0.0)
	shader_material.set_shader_parameter("circle_texture", circle_texture)

	# Apply to mesh
	material_override = shader_material

func _process(delta: float) -> void:
	if not active or not shader_material:
		return

	if blur_time < blur_duration:
		blur_time += delta
		var progress = min(blur_time / blur_duration, 1.0)

		# Calculate current blur radius with easing (exponential ease-in for more intensity)
		current_blur_radius = ease(progress, -2.0) * max_blur_radius

		# Update shader parameter
		shader_material.set_shader_parameter("blur_amount", current_blur_radius)

		# Debug output every 0.5 seconds
		if int(blur_time * 2) != int((blur_time - delta) * 2):
			print("GaussianBlurShader: Blur progress: %.1f%%, radius: %.2f" % [progress * 100, current_blur_radius])
	else:
		active = false
		print("GaussianBlurShader: Animation complete")

# Public API
func start() -> void:
	"""Start the blur animation"""
	active = true
	blur_time = 0.0
	current_blur_radius = 0.0
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", 0.0)
	print("GaussianBlurShader: Started")

func reset() -> void:
	"""Reset to sharp circle"""
	blur_time = 0.0
	current_blur_radius = 0.0
	active = false
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", 0.0)
	print("GaussianBlurShader: Reset to sharp circle")

func pause() -> void:
	"""Pause the blur animation"""
	active = false

func resume() -> void:
	"""Resume the blur animation"""
	active = true

func set_blur_amount(amount: float) -> void:
	"""Manually set blur amount"""
	current_blur_radius = clamp(amount, 0.0, max_blur_radius)
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", current_blur_radius)

func set_blur_duration(duration: float) -> void:
	"""Set the duration of the blur animation"""
	blur_duration = duration

func set_max_blur_radius(radius: float) -> void:
	"""Set the maximum blur radius"""
	max_blur_radius = radius
