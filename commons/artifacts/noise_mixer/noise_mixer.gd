extends Node3D
class_name NoiseMixer

## Noise Mixer — layered procedural noise with controllable octaves, lacunarity,
## and persistence. Blends multiple sin-based noise layers via fractal summation:
## total = Σ amplitude^i * noise(frequency * lacunarity^i * pos).
## Floor display with 128x128 procedural texture and earth-tone color mapping.
## VR sliders let you explore how octave stacking builds complexity from simple waves.

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.8, 0.8)
@export var octaves: int = 4
@export var lacunarity: float = 2.0
@export var persistence: float = 0.5
@export var base_frequency: float = 4.0
@export var seed_value: int = 42

const IMAGE_SIZE: int = 128

# --- Earth-tone color ramp (low → high) ---

var _color_ramp: Array[Color] = [
	Color(0.12, 0.18, 0.28),  # Deep water blue-grey
	Color(0.18, 0.30, 0.22),  # Dark moss
	Color(0.28, 0.42, 0.20),  # Forest green
	Color(0.52, 0.55, 0.30),  # Olive
	Color(0.68, 0.58, 0.35),  # Dry grass / sand
	Color(0.75, 0.65, 0.45),  # Light sand
	Color(0.55, 0.45, 0.35),  # Brown rock
	Color(0.72, 0.70, 0.68),  # Light grey stone
	Color(0.88, 0.86, 0.84),  # Near-white peak
]

# --- Nodes ---

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _title_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D
var _octaves_slider: Node
var _lacunarity_slider: Node
var _persistence_slider: Node
var _rng: RandomNumberGenerator
var _grid_config: Dictionary = {}  # Stored for case fitting

# Random offsets per octave for variety
var _octave_offsets: Array[Vector2] = []


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_generate_octave_offsets()
	_build_floor_quad()
	_generate_texture()
	_create_labels()
	_create_vr_controls()


# --- Octave offsets for pseudo-random variation ---

func _generate_octave_offsets() -> void:
	_octave_offsets.clear()
	for i in range(8):  # Max 8 octaves
		_octave_offsets.append(Vector2(
			_rng.randf_range(-100.0, 100.0),
			_rng.randf_range(-100.0, 100.0)
		))


# --- Floor quad setup ---

func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "NoiseMesh"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


# --- Noise generation ---

func _generate_texture() -> void:
	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)

	# First pass: compute raw noise values and track range for normalisation
	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(IMAGE_SIZE * IMAGE_SIZE)
	var min_val: float = INF
	var max_val: float = -INF

	for py in range(IMAGE_SIZE):
		for px in range(IMAGE_SIZE):
			var nx: float = float(px) / float(IMAGE_SIZE)
			var ny: float = float(py) / float(IMAGE_SIZE)
			var val: float = _fbm(nx, ny)
			var idx: int = py * IMAGE_SIZE + px
			raw[idx] = val
			if val < min_val:
				min_val = val
			if val > max_val:
				max_val = val

	# Second pass: normalise to [0, 1] and map to color ramp
	var range_val: float = max_val - min_val
	if range_val < 0.0001:
		range_val = 1.0

	for py in range(IMAGE_SIZE):
		for px in range(IMAGE_SIZE):
			var idx: int = py * IMAGE_SIZE + px
			var t: float = (raw[idx] - min_val) / range_val
			var color: Color = _sample_color_ramp(t)
			image.set_pixel(px, py, color)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


func _fbm(nx: float, ny: float) -> float:
	## Fractal Brownian Motion: sum of octaves with increasing frequency
	## and decreasing amplitude. total = Σ persistence^i * noise(lacunarity^i * freq * pos)
	var total: float = 0.0
	var amplitude: float = 1.0
	var frequency: float = base_frequency

	for i in range(octaves):
		var offset: Vector2 = _octave_offsets[i] if i < _octave_offsets.size() else Vector2.ZERO
		var sample_x: float = nx * frequency + offset.x
		var sample_y: float = ny * frequency + offset.y
		var noise_val: float = _sin_noise(sample_x, sample_y)
		total += amplitude * noise_val
		amplitude *= persistence
		frequency *= lacunarity

	return total


func _sin_noise(x: float, y: float) -> float:
	## Sin-based pseudo-noise: combines multiple sin waves at irrational angles
	## to create noise-like patterns without requiring a Perlin noise table.
	## Returns value roughly in [-1, 1].
	var v: float = 0.0
	v += sin(x * 1.0 + y * 1.7)
	v += sin(x * 2.3 - y * 0.9)
	v += sin((x + y) * 1.3 + 0.5)
	v += sin((x - y) * 1.8 - 0.3)
	v += sin(x * 0.7 + y * 2.1 + x * y * 0.15)
	return v / 5.0  # Normalise to roughly [-1, 1]


func _sample_color_ramp(t: float) -> Color:
	## Sample the earth-tone color ramp at position t in [0, 1].
	t = clampf(t, 0.0, 1.0)
	var segments: int = _color_ramp.size() - 1
	var segment_t: float = t * float(segments)
	var seg_idx: int = mini(int(segment_t), segments - 1)
	var seg_frac: float = segment_t - float(seg_idx)
	return _color_ramp[seg_idx].lerp(_color_ramp[seg_idx + 1], seg_frac)


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "NOISE MIXER"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.06, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, 0.03, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)
	_update_info()


func _update_info() -> void:
	if _info_label:
		_info_label.text = "fbm(x) = Σ p^i · noise(f · L^i · x)  ·  oct=%d  lac=%.1f  per=%.2f" % [
			octaves, lacunarity, persistence
		]


# --- VR Controls ---

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var mount: String = str(_grid_config.get("mount", ""))
	var use_csg := mount in ["shelf", "wall", "floor"]

	var panel: Node3D = RackTpl.create_panel("NOISE MIXER", [
		[
			{"type": "slider_h", "label": "OCT", "default": float(octaves - 1) / 7.0},
			{"type": "slider_h", "label": "LAC", "default": (lacunarity - 1.5) / 1.5},
			{"type": "slider_h", "label": "PER", "default": (persistence - 0.3) / 0.4},
		],
		[
			{"type": "button", "label": "SEED"},
		],
	], use_csg)

	if use_csg:
		var tilt := 35.0
		var color := Color(0.12, 0.12, 0.12)
		if mount == "wall":
			tilt = 0.0
		elif mount == "floor":
			tilt = 25.0
			color = Color(0.55, 0.38, 0.22)
		_control_panel = RackTpl.create_csg_case(0.28, 0.18, 0.16, tilt, panel, color)
		_control_panel.position = Vector3(0, 0.02, quad_size.y / 2.0 + 0.15)
	else:
		_control_panel = panel
		_control_panel.position = Vector3(0, 0.02, quad_size.y / 2.0 + 0.15)
		_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_octaves_slider = _control_panel.find_child("Param_0", true, false)
	_lacunarity_slider = _control_panel.find_child("Param_1", true, false)
	_persistence_slider = _control_panel.find_child("Param_2", true, false)

	if _octaves_slider and _octaves_slider.has_signal("slider_moved"):
		_octaves_slider.slider_moved.connect(_on_octaves_changed)
	if _lacunarity_slider and _lacunarity_slider.has_signal("slider_moved"):
		_lacunarity_slider.slider_moved.connect(_on_lacunarity_changed)
	if _persistence_slider and _persistence_slider.has_signal("slider_moved"):
		_persistence_slider.slider_moved.connect(_on_persistence_changed)

	var seed_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if seed_btn:
		var area = seed_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_randomise)


func _sync_sliders() -> void:
	if _octaves_slider and _octaves_slider.has_method("set_normalized_value"):
		# Octaves: 1–8 → normalised (octaves-1)/7
		_octaves_slider.set_normalized_value(float(octaves - 1) / 7.0)
	if _lacunarity_slider and _lacunarity_slider.has_method("set_normalized_value"):
		# Lacunarity: 1.5–3.0 → normalised (lac-1.5)/1.5
		_lacunarity_slider.set_normalized_value((lacunarity - 1.5) / 1.5)
	if _persistence_slider and _persistence_slider.has_method("set_normalized_value"):
		# Persistence: 0.3–0.7 → normalised (per-0.3)/0.4
		_persistence_slider.set_normalized_value((persistence - 0.3) / 0.4)


# --- Slider callbacks ---

func _on_octaves_changed(_pos) -> void:
	if _octaves_slider and _octaves_slider.has_method("get_normalized_value"):
		octaves = 1 + int(_octaves_slider.get_normalized_value() * 7.0)
		_regenerate()


func _on_lacunarity_changed(_pos) -> void:
	if _lacunarity_slider and _lacunarity_slider.has_method("get_normalized_value"):
		lacunarity = 1.5 + _lacunarity_slider.get_normalized_value() * 1.5
		_regenerate()


func _on_persistence_changed(_pos) -> void:
	if _persistence_slider and _persistence_slider.has_method("get_normalized_value"):
		persistence = 0.3 + _persistence_slider.get_normalized_value() * 0.4
		_regenerate()


func _on_randomise(_b = null) -> void:
	seed_value = randi()
	_rng.seed = seed_value
	_generate_octave_offsets()
	_regenerate()


func _regenerate() -> void:
	_generate_texture()
	_update_info()


## Grid system integration — accept configuration from map data.
## Supports: mount, tilt, case_style for grid-fitted case housing.
func apply_grid_config(config_data: Dictionary) -> void:
	_grid_config = config_data
	if config_data.has("octaves"):
		octaves = clampi(int(config_data["octaves"]), 1, 8)
	if config_data.has("lacunarity"):
		lacunarity = clampf(float(config_data["lacunarity"]), 1.5, 3.0)
	if config_data.has("persistence"):
		persistence = clampf(float(config_data["persistence"]), 0.3, 0.7)
	if config_data.has("base_frequency"):
		base_frequency = float(config_data["base_frequency"])
	if config_data.has("seed"):
		seed_value = int(config_data["seed"])
		_rng.seed = seed_value
		_generate_octave_offsets()
	_regenerate()
