@tool
extends Node3D

## Animated Brain Layer Scan - Rorschach Test Style
## Generates mirrored inkblot patterns that animate like brain CT/MRI slices
## Optimized: Generates layers incrementally to avoid blocking

@export var scan_speed: float = 0.5
@export var layer_count: int = 64
@export var resolution: int = 256
@export var ink_color: Color = Color(0.9, 0.95, 1.0)
@export var background_color: Color = Color(0.02, 0.02, 0.05)
@export var noise_scale: float = 3.0
@export var threshold: float = 0.45
@export var edge_glow: Color = Color(0.3, 0.8, 1.0, 0.5)
@export var layers_per_frame: int = 2  # How many layers to generate per frame

var current_layer: float = 0.0
var noise: FastNoiseLite
var image: Image
var texture: ImageTexture
var sprite: Sprite3D
var layers_cache: Array[Image] = []

# Generation state
var _generation_index: int = 0
var _is_generating: bool = false
var _is_ready: bool = false

func _ready() -> void:
	_setup_noise()
	_setup_display()
	_start_incremental_generation()

func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

func _setup_display() -> void:
	sprite = Sprite3D.new()
	sprite.name = "RorschachDisplay"
	sprite.pixel_size = 0.004
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.shaded = false
	sprite.double_sided = true
	add_child(sprite)

	image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	image.fill(background_color)
	texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func _start_incremental_generation() -> void:
	layers_cache.clear()
	layers_cache.resize(layer_count)
	_generation_index = 0
	_is_generating = true
	_is_ready = false

func _process(delta: float) -> void:
	# Incremental generation - generate a few layers per frame
	if _is_generating:
		var layers_this_frame = mini(layers_per_frame, layer_count - _generation_index)
		for i in range(layers_this_frame):
			layers_cache[_generation_index] = _generate_layer(_generation_index)
			_generation_index += 1

		if _generation_index >= layer_count:
			_is_generating = false
			_is_ready = true
		return

	if not _is_ready or Engine.is_editor_hint():
		return

	current_layer += delta * scan_speed * layer_count
	if current_layer >= layer_count:
		current_layer = 0.0

	_update_display()

func _generate_layer(layer_idx: int) -> Image:
	var img = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	img.fill(background_color)
	var z_offset = float(layer_idx) / float(layer_count) * 10.0

	var half_width = resolution / 2
	var center_y = resolution / 2

	# Generate right half, then mirror
	for y in range(resolution):
		for x in range(half_width, resolution):
			var pixel_color = _calculate_pixel(x, y, z_offset, half_width, center_y)
			img.set_pixel(x, y, pixel_color)
			img.set_pixel(resolution - 1 - x, y, pixel_color)

	_apply_brain_mask(img, layer_idx)
	_add_scan_artifacts(img, layer_idx)

	return img

func _calculate_pixel(x: int, y: int, z_offset: float, half_width: int, center_y: int) -> Color:
	var nx = float(x - half_width) / float(half_width) * noise_scale
	var ny = float(y - center_y) / float(center_y) * noise_scale

	var n1 = noise.get_noise_3d(nx * 20, ny * 20, z_offset)
	var n2 = noise.get_noise_3d(nx * 40, ny * 40, z_offset * 2) * 0.5
	var n3 = noise.get_noise_3d(nx * 80, ny * 80, z_offset * 0.5) * 0.25

	var combined = (n1 + n2 + n3) * 0.5 + 0.5

	var dist_from_center = sqrt(nx * nx + ny * ny) / noise_scale
	var adjusted_threshold = threshold + dist_from_center * 0.3

	if combined > adjusted_threshold:
		var intensity = (combined - adjusted_threshold) / (1.0 - adjusted_threshold)
		intensity = clamp(intensity, 0.0, 1.0)

		var varied_color = ink_color.lerp(edge_glow, (1.0 - intensity) * 0.5)
		varied_color.a = 0.7 + intensity * 0.3
		return varied_color
	else:
		return background_color

func _apply_brain_mask(img: Image, layer_idx: int) -> void:
	var center = resolution / 2.0
	var layer_progress = float(layer_idx) / float(layer_count)
	var vertical_scale = sin(layer_progress * PI) * 0.3 + 0.7
	var horizontal_scale = sin(layer_progress * PI) * 0.2 + 0.8

	for y in range(resolution):
		for x in range(resolution):
			var nx = (x - center) / center
			var ny = (y - center) / center

			var dist = sqrt((nx / horizontal_scale) ** 2 + (ny / vertical_scale) ** 2)
			var wobble = noise.get_noise_2d(x * 0.1, y * 0.1) * 0.1

			if dist > 0.85 + wobble:
				var fade = clamp((dist - 0.85) / 0.15, 0.0, 1.0)
				var current = img.get_pixel(x, y)
				current.a *= (1.0 - fade)
				img.set_pixel(x, y, current)

func _add_scan_artifacts(img: Image, layer_idx: int) -> void:
	# Sparse scan lines (every 8 pixels instead of 4)
	for y in range(0, resolution, 8):
		var line_intensity = 0.02
		for x in range(resolution):
			var current = img.get_pixel(x, y)
			current = current.lightened(line_intensity)
			img.set_pixel(x, y, current)

	# Fewer speckles
	var speckle_count = randi() % 10 + 5
	for i in range(speckle_count):
		var sx = randi() % resolution
		var sy = randi() % resolution
		var speckle_color = Color(0.5, 0.6, 0.7, 0.3)
		img.set_pixel(sx, sy, img.get_pixel(sx, sy).blend(speckle_color))

func _update_display() -> void:
	if layers_cache.is_empty() or not _is_ready:
		return

	var layer_idx = int(current_layer) % layers_cache.size()
	var layer_image = layers_cache[layer_idx]
	if layer_image:
		texture.update(layer_image)

func set_scan_speed(speed: float) -> void:
	scan_speed = speed

func set_layer(layer_idx: int) -> void:
	current_layer = clamp(layer_idx, 0, layer_count - 1)
	_update_display()

func regenerate() -> void:
	_setup_noise()
	noise.seed = randi()
	_start_incremental_generation()

func is_ready() -> bool:
	return _is_ready

func get_generation_progress() -> float:
	if layer_count == 0:
		return 1.0
	return float(_generation_index) / float(layer_count)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

