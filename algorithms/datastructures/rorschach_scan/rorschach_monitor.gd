@tool
extends Node3D

## Brain Scan Monitor - Rorschach Inkblot Display
## A medical monitor displaying animated mirrored brain scan patterns
## Optimized: Generates layers incrementally to avoid blocking

@export_group("Scan Settings")
@export var scan_speed: float = 0.4
@export var layer_count: int = 48
@export var resolution: int = 256
@export var auto_cycle: bool = true
@export var layers_per_frame: int = 2

@export_group("Visual Style")
@export_enum("CT", "MRI", "PET", "Thermal") var scan_mode: int = 0
@export var ink_intensity: float = 1.0
@export var glow_strength: float = 0.5

@export_group("Monitor")
@export var monitor_size: Vector2 = Vector2(1.0, 1.0)
@export var frame_color: Color = Color(0.15, 0.15, 0.18)
@export var screen_emission: float = 0.8

var scan_display: Node3D
var current_layer: float = 0.0
var noise: FastNoiseLite
var layers_cache: Array[Image] = []
var texture: ImageTexture
var screen_mesh: MeshInstance3D
var frame_mesh: MeshInstance3D
var info_label: Label3D

# Generation state
var _generation_index: int = 0
var _is_generating: bool = false
var _is_ready: bool = false

# Color presets for different scan modes
var mode_colors = {
	0: { "ink": Color(0.85, 0.9, 0.95), "bg": Color(0.0, 0.0, 0.02), "glow": Color(0.4, 0.7, 1.0) },
	1: { "ink": Color(0.95, 0.95, 0.95), "bg": Color(0.05, 0.05, 0.08), "glow": Color(0.8, 0.8, 0.9) },
	2: { "ink": Color(1.0, 0.3, 0.1), "bg": Color(0.0, 0.02, 0.05), "glow": Color(1.0, 0.5, 0.0) },
	3: { "ink": Color(1.0, 0.9, 0.2), "bg": Color(0.1, 0.0, 0.15), "glow": Color(1.0, 0.4, 0.8) }
}

func _ready() -> void:
	_setup_noise()
	_build_monitor()
	_start_incremental_generation()

func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.015
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.2
	noise.fractal_gain = 0.45
	noise.seed = randi()

func _build_monitor() -> void:
	# Create frame
	frame_mesh = MeshInstance3D.new()
	frame_mesh.name = "Frame"
	var frame_box = BoxMesh.new()
	frame_box.size = Vector3(monitor_size.x + 0.1, monitor_size.y + 0.1, 0.08)
	frame_mesh.mesh = frame_box

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.metallic = 0.3
	frame_mat.roughness = 0.7
	frame_mesh.material_override = frame_mat
	add_child(frame_mesh)

	# Create screen
	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "Screen"
	var screen_quad = QuadMesh.new()
	screen_quad.size = monitor_size
	screen_mesh.mesh = screen_quad
	screen_mesh.position.z = 0.045

	var screen_mat = StandardMaterial3D.new()
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mat.emission_enabled = true
	screen_mat.emission_energy_multiplier = screen_emission

	var image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	image.fill(mode_colors[scan_mode]["bg"])
	texture = ImageTexture.create_from_image(image)
	screen_mat.albedo_texture = texture
	screen_mat.emission_texture = texture

	screen_mesh.material_override = screen_mat
	add_child(screen_mesh)

	# Create info label
	info_label = Label3D.new()
	info_label.name = "InfoLabel"
	info_label.text = "GENERATING..."
	info_label.font_size = 24
	info_label.pixel_size = 0.002
	info_label.position = Vector3(0, -monitor_size.y / 2 - 0.08, 0.05)
	info_label.modulate = mode_colors[scan_mode]["glow"]
	info_label.outline_size = 0
	add_child(info_label)

	_add_status_leds()

func _add_status_leds() -> void:
	var led_positions = [
		Vector3(-monitor_size.x/2 - 0.04, monitor_size.y/2 + 0.04, 0.04),
		Vector3(monitor_size.x/2 + 0.04, monitor_size.y/2 + 0.04, 0.04)
	]

	for i in range(led_positions.size()):
		var led = MeshInstance3D.new()
		led.name = "LED_%d" % i
		var sphere = SphereMesh.new()
		sphere.radius = 0.015
		sphere.height = 0.03
		led.mesh = sphere
		led.position = led_positions[i]

		var led_mat = StandardMaterial3D.new()
		led_mat.emission_enabled = true
		led_mat.emission = Color.GREEN if i == 0 else mode_colors[scan_mode]["glow"]
		led_mat.emission_energy_multiplier = 2.0
		led_mat.albedo_color = led_mat.emission
		led.material_override = led_mat
		add_child(led)

func _start_incremental_generation() -> void:
	layers_cache.clear()
	layers_cache.resize(layer_count)
	_generation_index = 0
	_is_generating = true
	_is_ready = false

func _process(delta: float) -> void:
	# Incremental generation
	if _is_generating:
		var layers_this_frame = mini(layers_per_frame, layer_count - _generation_index)
		var colors = mode_colors[scan_mode]

		for i in range(layers_this_frame):
			layers_cache[_generation_index] = _generate_layer(_generation_index, colors)
			_generation_index += 1

		# Update progress display
		var progress = float(_generation_index) / float(layer_count) * 100.0
		info_label.text = "LOADING: %d%%" % int(progress)

		if _generation_index >= layer_count:
			_is_generating = false
			_is_ready = true
			info_label.text = "LAYER: 01/%02d" % layer_count
		return

	if not _is_ready or Engine.is_editor_hint() or not auto_cycle:
		return

	current_layer += delta * scan_speed * layer_count

	if current_layer >= layer_count:
		current_layer = 0.0
		# Occasionally regenerate
		if randf() < 0.2:
			noise.seed = randi()
			_start_incremental_generation()
			return

	_update_display()

func _generate_layer(layer_idx: int, colors: Dictionary) -> Image:
	var img = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	img.fill(colors["bg"])

	var z_offset = float(layer_idx) / float(layer_count) * 8.0
	var half = resolution / 2
	var center = resolution / 2.0

	var layer_t = float(layer_idx) / float(layer_count)
	var shape_mod = sin(layer_t * PI)

	for y in range(resolution):
		for x in range(half, resolution):
			var nx = float(x - half) / float(half)
			var ny = float(y - center) / center

			var n1 = noise.get_noise_3d(nx * 25, ny * 25, z_offset)
			var n2 = noise.get_noise_3d(nx * 50, ny * 50, z_offset * 1.5) * 0.4

			var combined = (n1 + n2) * 0.5 + 0.5

			var dist = sqrt(nx * nx + ny * ny)
			var threshold = 0.42 + dist * 0.25

			var mask_x = nx / (0.75 + shape_mod * 0.2)
			var mask_y = ny / (0.85 + shape_mod * 0.1)
			var brain_dist = sqrt(mask_x * mask_x + mask_y * mask_y)

			if brain_dist < 1.0 and combined > threshold:
				var intensity = (combined - threshold) / (1.0 - threshold)
				intensity *= ink_intensity

				var pixel_color = colors["ink"]
				if intensity < 0.3:
					pixel_color = colors["ink"].lerp(colors["glow"], 0.5)
					pixel_color.a = 0.6 + intensity

				if brain_dist > 0.8:
					var edge_fade = (brain_dist - 0.8) / 0.2
					pixel_color.a *= (1.0 - edge_fade)

				img.set_pixel(x, y, pixel_color)
				img.set_pixel(resolution - 1 - x, y, pixel_color)

	_add_artifacts(img, layer_idx)
	return img

func _add_artifacts(img: Image, layer_idx: int) -> void:
	# Sparse scan lines
	for y in range(0, resolution, 6):
		var intensity = 0.015
		for x in range(resolution):
			var c = img.get_pixel(x, y)
			c = c.lightened(intensity)
			img.set_pixel(x, y, c)

	# Fewer speckles
	for i in range(randi() % 8 + 3):
		var sx = randi() % resolution
		var sy = randi() % resolution
		var speckle = Color(0.4, 0.5, 0.6, 0.2)
		img.set_pixel(sx, sy, img.get_pixel(sx, sy).blend(speckle))

func _update_display() -> void:
	if layers_cache.is_empty() or not _is_ready:
		return

	var idx = int(current_layer) % layers_cache.size()
	var layer_image = layers_cache[idx]
	if layer_image:
		texture.update(layer_image)
		info_label.text = "LAYER: %02d/%02d" % [idx + 1, layer_count]

func set_mode(mode_idx: int) -> void:
	scan_mode = clamp(mode_idx, 0, 3)
	if info_label:
		info_label.modulate = mode_colors[scan_mode]["glow"]
	_start_incremental_generation()

func regenerate() -> void:
	noise.seed = randi()
	_start_incremental_generation()

func is_ready() -> bool:
	return _is_ready

func get_generation_progress() -> float:
	if layer_count == 0:
		return 1.0
	return float(_generation_index) / float(layer_count)

func apply_grid_config(config: Dictionary) -> void:
	if config.has("scan_mode"):
		set_mode(int(config["scan_mode"]))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

