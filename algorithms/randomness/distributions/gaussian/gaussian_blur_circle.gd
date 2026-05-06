extends MeshInstance3D
class_name GaussianBlurCircle

# Constants
const DEFAULT_WIDTH := 128  # Was 640 — CPU blur is O(w*h*kernel), must be small
const DEFAULT_HEIGHT := 128
const CIRCLE_RADIUS := 40

# Image properties
var original_image := Image.new()
var current_image := Image.new()
var texture := ImageTexture.new()
var width := DEFAULT_WIDTH
var height := DEFAULT_HEIGHT

# Animation control
var blur_time := 0.0
var blur_duration := 10.0  # Duration to go from sharp to fully blurred
var max_blur_radius := 8.0  # Maximum blur kernel radius (keep small for CPU blur)
var current_blur_radius := 0.0
var active := true

func _ready() -> void:
	_initialize_image()
	_setup_material()

# Initialize the image with a sharp circle
func _initialize_image() -> void:
	original_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	current_image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	if original_image.get_data().size() == 0:
		push_error("Failed to create image for Gaussian blur circle")
		return

	# Fill with white background
	original_image.fill(Color.WHITE)

	# Draw a sharp black circle in the center
	var center_x := width / 2
	var center_y := height / 2

	for y in range(height):
		for x in range(width):
			var dx := x - center_x
			var dy := y - center_y
			var distance := sqrt(dx * dx + dy * dy)

			# Hard edge circle
			if distance <= CIRCLE_RADIUS:
				original_image.set_pixel(x, y, Color.BLACK)

	# Copy to current image
	current_image.copy_from(original_image)

	# Create texture
	texture = ImageTexture.create_from_image(current_image)
	print("GaussianBlurCircle: Initialized with sharp circle")

# Setup the material with the texture
func _setup_material() -> void:
	var new_material := StandardMaterial3D.new()
	new_material.albedo_texture = texture
	new_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material_override = new_material

var _frame_skip: int = 0

func _process(delta: float) -> void:
	if not active:
		return

	# Only update blur every 4th frame (CPU blur is expensive)
	_frame_skip += 1
	if _frame_skip < 4:
		return
	_frame_skip = 0

	if blur_time < blur_duration:
		blur_time += delta * 4.0  # Compensate for frame skip
		var progress = min(blur_time / blur_duration, 1.0)

		current_blur_radius = ease(progress, 0.5) * max_blur_radius

		_apply_gaussian_blur()
		texture.update(current_image)

# Apply Gaussian blur to the image
func _apply_gaussian_blur() -> void:
	if current_blur_radius < 0.5:
		# No blur needed yet, just copy original
		current_image.copy_from(original_image)
		return

	# Reset current image
	current_image.copy_from(original_image)

	# Create temporary image for blur result
	var temp_image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	var kernel_size := int(ceil(current_blur_radius * 2))
	var sigma := current_blur_radius / 2.0

	# Generate Gaussian kernel
	var kernel := _generate_gaussian_kernel(kernel_size, sigma)

	# Apply horizontal blur
	for y in range(height):
		for x in range(width):
			var color_sum := Color(0, 0, 0, 0)
			var weight_sum := 0.0

			for i in range(-kernel_size, kernel_size + 1):
				var sample_x = clamp(x + i, 0, width - 1)
				var weight = kernel[i + kernel_size]
				color_sum += original_image.get_pixel(sample_x, y) * weight
				weight_sum += weight

			if weight_sum > 0:
				temp_image.set_pixel(x, y, color_sum / weight_sum)

	# Apply vertical blur
	for y in range(height):
		for x in range(width):
			var color_sum := Color(0, 0, 0, 0)
			var weight_sum := 0.0

			for i in range(-kernel_size, kernel_size + 1):
				var sample_y = clamp(y + i, 0, height - 1)
				var weight = kernel[i + kernel_size]
				color_sum += temp_image.get_pixel(x, sample_y) * weight
				weight_sum += weight

			if weight_sum > 0:
				current_image.set_pixel(x, y, color_sum / weight_sum)

# Generate 1D Gaussian kernel
func _generate_gaussian_kernel(radius: int, sigma: float) -> Array:
	var kernel := []
	var sum := 0.0

	for i in range(-radius, radius + 1):
		var value := exp(-(i * i) / (2.0 * sigma * sigma))
		kernel.append(value)
		sum += value

	# Normalize kernel
	for i in range(kernel.size()):
		kernel[i] /= sum

	return kernel

# Public API
func reset() -> void:
	"""Reset the animation"""
	blur_time = 0.0
	current_blur_radius = 0.0
	current_image.copy_from(original_image)
	texture.update(current_image)
	print("GaussianBlurCircle: Reset to sharp circle")

func pause() -> void:
	"""Pause the blur animation"""
	active = false

func resume() -> void:
	"""Resume the blur animation"""
	active = true

func set_blur_duration(duration: float) -> void:
	"""Set the duration of the blur animation"""
	blur_duration = duration

func set_max_blur_radius(radius: float) -> void:
	"""Set the maximum blur radius"""
	max_blur_radius = radius

func apply_grid_config(config: Dictionary) -> void:
	pass
