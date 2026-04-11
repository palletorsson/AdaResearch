# FlowerLab.gd
# Interactive VR laboratory for exploring procedural flower morphology.
#
# Wraps the BotanicalFlower generator with VR slider controls, letting
# learners manipulate the most impactful parameters in real time and see
# how each one shapes the flower's anatomy.
#
# Educational notes on each parameter:
#   - Petal count: Fibonacci numbers (3, 5, 8, 13) dominate in nature due to
#     optimal packing via the golden angle (~137.5 degrees). Non-Fibonacci counts
#     create visually distinct, less "natural" looking flowers.
#   - Petal length/width: Together these define the aspect ratio. Long narrow
#     petals (like daisies) vs. short wide petals (like roses) dramatically
#     change flower silhouette.
#   - Petal curve: Controls lengthwise curvature of each petal. Low values
#     give flat, open petals (like daisies); high values curl petals inward
#     (like tulips) or create dramatic recurving (like lilies).
#   - Stem height: Determines how tall the plant grows. In nature, stem height
#     is an adaptation to light competition and pollinator access.
#   - Primary color hue: Maps to the HSV color wheel. Flower color in nature
#     is driven by pigments (anthocyanins for reds/blues, carotenoids for
#     yellows/oranges) and serves as pollinator signaling.
#   - Leaf count: Number of leaves along the stem. More leaves = more
#     photosynthetic surface area but also more weight and wind resistance.
#   - Symmetry: Radial symmetry (like daisies) is ancestral; bilateral
#     symmetry (like orchids) evolved for specialized pollinator relationships.
#
# Usage:
#   Place in a map via the grid system (lookup_name: "flower_lab") or
#   instance directly in a scene. VR users can grab sliders and press
#   buttons to explore flower space.

extends Node3D
class_name FlowerLab


# ── Preloaded scenes ──────────────────────────────────────────────────

const BOTANICAL_FLOWER := preload("res://commons/flora/botanical_flower.tscn")
const SLIDER_HORIZONTAL := preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON := preload("res://commons/interactables/push_button.tscn")


# ── Parameter ranges ─────────────────────────────────────────────────
# Each entry: [min, max, default, param_key_in_BotanicalFlower]
# These ranges are chosen to cover the visually interesting region of
# each parameter without producing degenerate geometry.

const PARAM_DEFS := {
	"petal_count":  { "min": 3.0,  "max": 20.0, "default": 5.0,   "key": "petal_count",  "integer": true },
	"petal_length": { "min": 0.05, "max": 0.5,  "default": 0.08,  "key": "petal_length", "integer": false },
	"petal_width":  { "min": 0.02, "max": 0.15, "default": 0.04,  "key": "petal_width",  "integer": false },
	"petal_curve":  { "min": 0.0,  "max": 1.0,  "default": 0.2,   "key": "petal_curve",  "integer": false },
	"stem_height":  { "min": 0.1,  "max": 1.0,  "default": 0.25,  "key": "stem_height",  "integer": false },
	"color_hue":    { "min": 0.0,  "max": 1.0,  "default": 0.9,   "key": "_hue",         "integer": false },
	"leaf_count":   { "min": 0.0,  "max": 8.0,  "default": 4.0,   "key": "leaf_count",   "integer": true },
}

# Slider display labels (short names that fit on the VR slider frame)
const SLIDER_LABELS := {
	"petal_count":  "PETALS",
	"petal_length": "P.LEN",
	"petal_width":  "P.WID",
	"petal_curve":  "CURVE",
	"stem_height":  "STEM",
	"color_hue":    "HUE",
	"leaf_count":   "LEAVES",
}

# Order of slider placement (left to right, top to bottom)
const SLIDER_ORDER := [
	"petal_count", "petal_length", "petal_width", "petal_curve",
	"stem_height", "color_hue", "leaf_count",
]


# ── State ─────────────────────────────────────────────────────────────

var _flower: Node3D = null
var _control_panel: Node3D = null
var _sliders: Dictionary = {}       # param_name -> slider node
var _title_label: Label3D = null
var _info_label: Label3D = null
var _symmetry_radial: bool = true    # true = radial, false = bilateral
var _current_params: Dictionary = {} # current flower config values
var _rng := RandomNumberGenerator.new()


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_rng.randomize()
	_init_params()
	_build_flower()
	_create_title()
	_create_info_label()
	_create_vr_controls()
	call_deferred("_sync_sliders")


# ── Parameter initialization ─────────────────────────────────────────

func _init_params() -> void:
	# Start with defaults from PARAM_DEFS
	for param_name in PARAM_DEFS:
		var def: Dictionary = PARAM_DEFS[param_name]
		_current_params[param_name] = def["default"]
	_symmetry_radial = true


# ── Flower construction ──────────────────────────────────────────────

func _build_flower() -> void:
	# Remove old flower if rebuilding
	if _flower and is_instance_valid(_flower):
		_flower.queue_free()
		_flower = null

	_flower = BOTANICAL_FLOWER.instantiate()
	# Position the flower at center, slightly elevated so stem base sits on floor
	_flower.position = Vector3(0, 0, 0)
	add_child(_flower)

	# Apply current parameters via BotanicalFlower.configure()
	var config := _build_flower_config()
	_flower.configure(config)
	_flower.rebuild()


## Build a BotanicalFlower-compatible config dictionary from our slider state.
## The color hue slider maps to HSV with fixed saturation/value for vibrant petals.
func _build_flower_config() -> Dictionary:
	var hue: float = _current_params.get("color_hue", 0.9)
	# Convert hue to a vivid petal color (high saturation, medium-high value)
	# This mapping lets learners sweep through the entire visible spectrum
	var petal_color := Color.from_hsv(hue, 0.75, 0.85)

	var config := {
		"petal_count":  int(_current_params["petal_count"]),
		"petal_length": _current_params["petal_length"],
		"petal_width":  _current_params["petal_width"],
		"petal_curve":  _current_params["petal_curve"],
		"stem_height":  _current_params["stem_height"],
		"petal_color":  petal_color,
		"leaf_count":   int(_current_params["leaf_count"]),
		"symmetry":     BotanicalFlower.Symmetry.RADIAL if _symmetry_radial else BotanicalFlower.Symmetry.BILATERAL,
	}
	return config


# ── Title label ───────────────────────────────────────────────────────

func _create_title() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "Flower Lab"
	_title_label.font_size = 48
	_title_label.pixel_size = 0.001
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Float above the tallest possible flower
	_title_label.position = Vector3(0, 1.2, 0)
	_title_label.modulate = Color(0.95, 0.92, 0.85)
	_title_label.outline_size = 8
	_title_label.outline_modulate = Color(0.15, 0.12, 0.1)
	add_child(_title_label)


# ── Info label ────────────────────────────────────────────────────────
# Shows current parameter values as text below the control panel

func _create_info_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 20
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, 0.55, 0.5)
	_info_label.rotation_degrees = Vector3(-15, 0, 0)
	_info_label.modulate = Color(0.8, 0.85, 0.8)
	_info_label.outline_size = 4
	_info_label.outline_modulate = Color(0.05, 0.05, 0.05)
	add_child(_info_label)
	_update_info()


func _update_info() -> void:
	if not _info_label:
		return
	var sym_text := "Radial" if _symmetry_radial else "Bilateral"
	_info_label.text = "Petals: %d  Len: %.2f  Wid: %.2f  Curve: %.1f\nStem: %.2f  Leaves: %d  Symmetry: %s" % [
		int(_current_params["petal_count"]),
		_current_params["petal_length"],
		_current_params["petal_width"],
		_current_params["petal_curve"],
		_current_params["stem_height"],
		int(_current_params["leaf_count"]),
		sym_text,
	]


# ── VR Controls ──────────────────────────────────────────────────────
# Arranged in two rows on an angled panel in front of the flower.
# Top row: 4 sliders    Bottom row: 3 sliders + 2 buttons

func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.35, 0.45)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Dark backing panel for visual grouping
	var panel_back := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.72, 0.22, 0.008)
	panel_back.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.06, 0.07, 0.08)
	panel_mat.metallic = 0.2
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)

	# Create sliders in two rows
	# Row 1 (top): petal_count, petal_length, petal_width, petal_curve
	# Row 2 (bottom): stem_height, color_hue, leaf_count
	var row1 := SLIDER_ORDER.slice(0, 4)
	var row2 := SLIDER_ORDER.slice(4, 7)

	var x_start_row1 := -0.27
	var x_spacing := 0.18
	var y_top := 0.05
	var y_bottom := -0.03

	for i in range(row1.size()):
		var param_name: String = row1[i]
		var x := x_start_row1 + i * x_spacing
		_sliders[param_name] = _add_slider(
			SLIDER_LABELS[param_name], Vector3(x, y_top, 0),
			_make_slider_callback(param_name)
		)

	var x_start_row2 := -0.18
	for i in range(row2.size()):
		var param_name: String = row2[i]
		var x := x_start_row2 + i * x_spacing
		_sliders[param_name] = _add_slider(
			SLIDER_LABELS[param_name], Vector3(x, y_bottom, 0),
			_make_slider_callback(param_name)
		)

	# Symmetry toggle button (radial / bilateral)
	# Bilateral symmetry is a key evolutionary innovation — most advanced
	# flowers develop it for specialized pollinator relationships (e.g. orchids)
	var sym_btn := PUSH_BUTTON.instantiate()
	sym_btn.name = "SymmetryBtn"
	sym_btn.position = Vector3(0.26, y_bottom, 0)
	sym_btn.scale = Vector3(0.55, 0.55, 0.55)
	_control_panel.add_child(sym_btn)
	_add_button_label(sym_btn, "SYM")
	var sym_area = sym_btn.get_node_or_null("InteractableAreaButton")
	if sym_area:
		sym_area.button_pressed.connect(_on_symmetry_toggle)

	# Randomize button — generates a random flower by sampling all params
	var rand_btn := PUSH_BUTTON.instantiate()
	rand_btn.name = "RandomBtn"
	rand_btn.position = Vector3(-0.30, -0.09, 0)
	rand_btn.scale = Vector3(0.55, 0.55, 0.55)
	_control_panel.add_child(rand_btn)
	_add_button_label(rand_btn, "RANDOM")
	var rand_area = rand_btn.get_node_or_null("InteractableAreaButton")
	if rand_area:
		rand_area.button_pressed.connect(_on_randomize)

	# Save Preset button — writes current config to user:// JSON
	var save_btn := PUSH_BUTTON.instantiate()
	save_btn.name = "SaveBtn"
	save_btn.position = Vector3(-0.12, -0.09, 0)
	save_btn.scale = Vector3(0.55, 0.55, 0.55)
	_control_panel.add_child(save_btn)
	_add_button_label(save_btn, "SAVE")
	var save_area = save_btn.get_node_or_null("InteractableAreaButton")
	if save_area:
		save_area.button_pressed.connect(_on_save_preset)


## Create a single VR slider and add it to the control panel.
func _add_slider(label_text: String, pos: Vector3, callback: Callable) -> Node:
	var slider := SLIDER_HORIZONTAL.instantiate()
	slider.name = label_text.replace(".", "") + "Slider"
	slider.position = pos
	slider.rotation_degrees.x = -30
	slider.scale = Vector3(0.7, 0.7, 0.7)
	var lbl = slider.get_node_or_null("Frame/LabelName")
	if lbl:
		lbl.text = label_text
	_control_panel.add_child(slider)
	slider.slider_moved.connect(callback)
	return slider


## Add a small text label beneath a push button.
func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)


# ── Slider sync ──────────────────────────────────────────────────────
# Set slider positions to match current parameter values on startup.

func _sync_sliders() -> void:
	for param_name in _sliders:
		var slider = _sliders[param_name]
		if slider and slider.has_method("set_normalized_value"):
			var def: Dictionary = PARAM_DEFS[param_name]
			var norm := inverse_lerp(def["min"], def["max"], _current_params[param_name])
			slider.set_normalized_value(clampf(norm, 0.0, 1.0))


# ── Slider callback factory ─────────────────────────────────────────
# Returns a Callable that reads the normalized slider value and maps it
# to the appropriate parameter range. Integer params are rounded.

func _make_slider_callback(param_name: String) -> Callable:
	return func(_pos) -> void:
		var slider = _sliders.get(param_name)
		if slider and slider.has_method("get_normalized_value"):
			var def: Dictionary = PARAM_DEFS[param_name]
			var norm: float = slider.get_normalized_value()
			var value: float = lerp(def["min"], def["max"], norm)
			if def["integer"]:
				value = round(value)
			_current_params[param_name] = value
			_rebuild_flower()


# ── Button callbacks ─────────────────────────────────────────────────

## Toggle between radial and bilateral symmetry.
## Radial: petals arranged in a circle (most common — daisies, roses).
## Bilateral: mirror symmetry on one axis (orchids, snapdragons).
func _on_symmetry_toggle(_b = null) -> void:
	_symmetry_radial = not _symmetry_radial
	_rebuild_flower()


## Randomize all parameters within their valid ranges.
## This is a great way to discover unexpected flower morphologies
## that might not arise from manual slider exploration.
func _on_randomize(_b = null) -> void:
	for param_name in PARAM_DEFS:
		var def: Dictionary = PARAM_DEFS[param_name]
		var value: float = _rng.randf_range(def["min"], def["max"])
		if def["integer"]:
			value = round(value)
		_current_params[param_name] = value
	# Random symmetry (weighted toward radial since it's more common in nature)
	_symmetry_radial = _rng.randf() > 0.3
	_sync_sliders()
	_rebuild_flower()


## Save the current flower configuration to a JSON file in user://.
## Each save gets a unique timestamp filename so presets accumulate.
func _on_save_preset(_b = null) -> void:
	var config := _build_flower_config()
	# Convert Color to hex string for JSON serialization
	var save_data := {}
	for k in config:
		if config[k] is Color:
			save_data[k] = (config[k] as Color).to_html()
		elif config[k] is int:
			save_data[k] = config[k]
		else:
			save_data[k] = config[k]
	save_data["symmetry_name"] = "radial" if _symmetry_radial else "bilateral"
	save_data["color_hue"] = _current_params["color_hue"]

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://flower_lab_preset_%s.json" % timestamp
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("FlowerLab: Preset saved to %s" % path)
		# Brief visual feedback via info label
		if _info_label:
			_info_label.text = "Preset saved!"
			# Restore info after a short delay
			get_tree().create_timer(1.5).timeout.connect(_update_info)
	else:
		push_warning("FlowerLab: Failed to save preset to %s" % path)


# ── Rebuild ──────────────────────────────────────────────────────────

func _rebuild_flower() -> void:
	if _flower and is_instance_valid(_flower):
		var config := _build_flower_config()
		_flower.configure(config)
		_flower.rebuild()
	_update_info()


# ── Grid system integration ──────────────────────────────────────────
# Accepts configuration from map_data.json when placed via the grid system.
# Supports all slider-controllable params plus a "preset" key for
# BotanicalFlower's built-in species presets.

func apply_grid_config(config_data: Dictionary) -> void:
	# Apply a named preset first if specified (e.g. "bluebell", "iris")
	if config_data.has("preset") and _flower:
		_flower.preset = str(config_data["preset"])

	# Override individual params from map config
	for param_name in PARAM_DEFS:
		if config_data.has(param_name):
			var def: Dictionary = PARAM_DEFS[param_name]
			var value = config_data[param_name]
			if def["integer"]:
				value = clampi(int(value), int(def["min"]), int(def["max"]))
			else:
				value = clampf(float(value), def["min"], def["max"])
			_current_params[param_name] = value

	if config_data.has("symmetry"):
		var sym = config_data["symmetry"]
		if sym is String:
			_symmetry_radial = sym.to_lower() != "bilateral"
		else:
			_symmetry_radial = int(sym) == 0  # 0 = radial

	_rebuild_flower()
	call_deferred("_sync_sliders")
