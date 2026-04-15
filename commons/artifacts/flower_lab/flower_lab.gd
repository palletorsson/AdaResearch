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
var _info_label: Label3D = null
var _symmetry_radial: bool = true    # true = radial, false = bilateral
var _current_params: Dictionary = {} # current flower config values
var _rng := RandomNumberGenerator.new()


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_rng.randomize()
	_init_params()
	_build_flower()
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
# Built via RackTemplates for Dieter Rams aesthetic.

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

	# Row 1: 4 sliders, Row 2: 3 sliders, Row 3: 3 buttons
	var defaults := {}
	for param_name in SLIDER_ORDER:
		var def: Dictionary = PARAM_DEFS[param_name]
		defaults[param_name] = inverse_lerp(def["min"], def["max"], _current_params[param_name])

	_control_panel = RackTpl.create_panel("FLOWER LAB", [
		[
			{"type": "slider_h", "label": SLIDER_LABELS["petal_count"],  "default": defaults["petal_count"]},
			{"type": "slider_h", "label": SLIDER_LABELS["petal_length"], "default": defaults["petal_length"]},
			{"type": "slider_h", "label": SLIDER_LABELS["petal_width"],  "default": defaults["petal_width"]},
			{"type": "slider_h", "label": SLIDER_LABELS["petal_curve"],  "default": defaults["petal_curve"]},
		],
		[
			{"type": "slider_h", "label": SLIDER_LABELS["stem_height"], "default": defaults["stem_height"]},
			{"type": "slider_h", "label": SLIDER_LABELS["color_hue"],   "default": defaults["color_hue"]},
			{"type": "slider_h", "label": SLIDER_LABELS["leaf_count"],  "default": defaults["leaf_count"]},
		],
		[
			{"type": "button", "label": "SYM"},
			{"type": "button", "label": "RANDOM"},
			{"type": "button", "label": "SAVE"},
		],
	])
	_control_panel.position = Vector3(0, 0.35, 0.45)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Map slider references by param order
	var slider_index := 0
	for param_name in SLIDER_ORDER:
		var slider = _control_panel.find_child("Param_%d" % slider_index, true, false)
		if slider:
			_sliders[param_name] = slider
			slider.slider_moved.connect(_make_slider_callback(param_name))
		slider_index += 1

	# Button callbacks
	var sym_btn = _control_panel.find_child("Btn_0", true, false)
	if sym_btn:
		var area = sym_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_symmetry_toggle)

	var rand_btn = _control_panel.find_child("Btn_1", true, false)
	if rand_btn:
		var area = rand_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_randomize)

	var save_btn = _control_panel.find_child("Btn_2", true, false)
	if save_btn:
		var area = save_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_save_preset)


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
