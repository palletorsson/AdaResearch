@tool
extends Node3D

## Universal VR Audio Controller (UVAC)
## The central brain of the modular synth rack.
## Supports Ableton-style controls: sliders, knobs, XY pads, buttons

# Control scene preloads
const SLIDER_SCENE = preload("res://commons/audio/interfaces/VRAudioControlSlider.tscn")
const DIAL_SCENE = preload("res://commons/audio/interfaces/VRAudioControlDial.tscn")

# Additional Ableton-style controls from interactables
const SLIDER_VERTICAL_SCENE = preload("res://commons/interactables/slider_axis.tscn")
const SLIDER_SNAP_SCENE = preload("res://commons/interactables/slider_snap.tscn")
const SLIDER_ZERO_SCENE = preload("res://commons/interactables/slider_zero.tscn")
const XY_PAD_SCENE = preload("res://commons/interactables/slider_plane.tscn")
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const JOYSTICK_SCENE = preload("res://commons/interactables/joystick_smooth.tscn")
const LEVER_SCENE = preload("res://commons/interactables/lever_smooth.tscn")
const WHEEL_SCENE = preload("res://commons/interactables/wheel_smooth.tscn")

# Monitors and meters
const WAVEFORM_MONITOR_SCENE = preload("res://commons/audio/interfaces/VRAudioMonitor.tscn")

# Default spacing by control type (width, height in meters)
const CONTROL_SIZES = {
	"slider": Vector2(0.22, 0.06),
	"slv": Vector2(0.06, 0.15),
	"knob": Vector2(0.08, 0.08),
	"xy": Vector2(0.15, 0.15),
	"btn": Vector2(0.06, 0.06),
	"monitor": Vector2(0.30, 0.22),
	"meter": Vector2(0.04, 0.12),
	"label": Vector2(0.20, 0.03),
	"default": Vector2(0.10, 0.08)
}

# Control type mapping
# Prefixes:
#   slh_N  = Horizontal slider (fader)
#   slv_N  = Vertical slider (fader)
#   sls_N  = Snap slider (discrete steps)
#   slz_N  = Zero-centered slider (bipolar)
#   nb_N   = Knob/dial (rotary)
#   xy_N   = XY Pad (2D control, maps to 2 parameters)
#   btn_N  = Button (trigger/toggle)
#   js_N   = Joystick (alternative 2D control)
#   lv_N   = Lever (vertical throw)
#   whl_N  = Wheel (scroll/pitch bend style)
#   mon_N  = Monitor (waveform/spectrum display)
#   mtr_N  = Meter (VU/level meter)
#   lbl_N  = Label (text display)
#   grp_N  = Group container

signal sound_played(stream)

@export_file("*.json") var rack_config_path: String = ""

@onready var parameter_container = $ParameterGrid
@onready var preview_player = $AudioStreamPlayer3D
@onready var category_label = $SelectionPanel/CategoryLabel
@onready var sound_label = $SelectionPanel/SoundLabel

var current_category: String = "basic"
var current_sound_key: String = "basic_sine_wave"
var active_controls: Dictionary = {}
var rack_config: Dictionary = {}
var use_json_config: bool = false

var categories = ["basic", "synth", "noir", "trap"]
var sounds_in_category = []

const RACK_CONFIG_BASE_PATH = "res://commons/audio/rack_configs/"

func _ready():
	# Connect buttons
	$Buttons/PlayButton/InteractableAreaButton.button_pressed.connect(_on_play_pressed)
	$Buttons/SaveButton/InteractableAreaButton.button_pressed.connect(_on_save_pressed)

	# Connect selection dials
	$SelectionPanel/CategoryDial.hinge_moved.connect(_on_category_dial_moved)
	$SelectionPanel/SoundDial.hinge_moved.connect(_on_sound_dial_moved)

	# Check if we should use JSON config or traditional mode
	if rack_config_path != "" and FileAccess.file_exists(rack_config_path):
		load_rack_config(rack_config_path)
	else:
		# Traditional mode
		_update_category(0)
		load_sound(current_sound_key)

# Called by GridInteractablesComponent when using # syntax
# Supported parameters:
#   #config:synth_rack       → Load rack config from rack_configs folder
#   #sound:laser_shot        → Override sound type
#   #autoplay:true           → Auto-play sound on ready
#   #col_spacing:0.25        → Override column spacing
#   #row_spacing:0.12        → Override row spacing
#   #hide_selection:true     → Hide category/sound selection panel
#   #hide_buttons:true       → Hide play/save buttons
#
# Example: AudioContr#config:synth_rack#sound:pickup_mario#autoplay:true
func apply_grid_config(config_data: Dictionary):
	print("UniversalVRAudioController: Applying grid config: %s" % str(config_data))

	# Load rack config first (if specified)
	if config_data.has("config"):
		var config_name = str(config_data["config"])
		var full_path = RACK_CONFIG_BASE_PATH + config_name + ".json"

		if FileAccess.file_exists(full_path):
			load_rack_config(full_path)
			print("  → Loaded rack config: %s" % config_name)
		else:
			push_error("UniversalVRAudioController: Rack config not found: %s" % full_path)
			_list_available_configs()

	# Override sound type
	if config_data.has("sound"):
		var sound_type = str(config_data["sound"])
		current_sound_key = sound_type
		if rack_config.has("rack_info"):
			rack_config["rack_info"]["sound_type"] = sound_type
		print("  → Sound type override: %s" % sound_type)

	# Override layout spacing
	if config_data.has("col_spacing"):
		var spacing = float(config_data["col_spacing"])
		if rack_config.has("layout"):
			rack_config["layout"]["col_spacing"] = spacing
		_respawn_controls_if_needed()
		print("  → Column spacing: %s" % spacing)

	if config_data.has("row_spacing"):
		var spacing = float(config_data["row_spacing"])
		if rack_config.has("layout"):
			rack_config["layout"]["row_spacing"] = spacing
		_respawn_controls_if_needed()
		print("  → Row spacing: %s" % spacing)

	# Hide selection panel
	if config_data.has("hide_selection"):
		var should_hide = str(config_data["hide_selection"]).to_lower() == "true"
		if has_node("SelectionPanel"):
			$SelectionPanel.visible = not should_hide
			print("  → Selection panel visible: %s" % (not should_hide))

	# Hide buttons
	if config_data.has("hide_buttons"):
		var should_hide = str(config_data["hide_buttons"]).to_lower() == "true"
		if has_node("Buttons"):
			$Buttons.visible = not should_hide
			print("  → Buttons visible: %s" % (not should_hide))

	# Auto-play on ready
	if config_data.has("autoplay"):
		var should_autoplay = str(config_data["autoplay"]).to_lower() == "true"
		if should_autoplay:
			# Defer to ensure controls are spawned
			call_deferred("play_current_sound")
			print("  → Autoplay enabled")

func _list_available_configs():
	var dir = DirAccess.open(RACK_CONFIG_BASE_PATH)
	if dir:
		var configs = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				configs.append(file_name.replace(".json", ""))
			file_name = dir.get_next()
		print("UniversalVRAudioController: Available configs: %s" % str(configs))

func _respawn_controls_if_needed():
	if use_json_config and not rack_config.is_empty():
		_clear_controls()
		_spawn_controls_from_json()

func load_rack_config(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open rack config file: " + path)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse rack config JSON: " + json.get_error_message())
		return

	var data = json.data
	if not _validate_rack_config(data):
		push_error("Invalid rack config structure in: " + path)
		return

	rack_config = data
	use_json_config = true

	# Update rack info
	if rack_config.has("rack_info"):
		var info = rack_config["rack_info"]
		if info.has("name"):
			sound_label.text = info["name"]
		if info.has("sound_type"):
			current_sound_key = info["sound_type"]

	# Spawn controls from JSON config
	_clear_controls()
	_spawn_controls_from_json()

	print("Loaded rack config: ", rack_config.get("rack_info", {}).get("name", "Unknown"))

func _validate_rack_config(data: Dictionary) -> bool:
	# Check for required top-level keys
	if not data.has("grid"):
		push_error("Rack config missing 'grid' section")
		return false

	if not data.has("control_definitions"):
		push_error("Rack config missing 'control_definitions' section")
		return false

	# Validate grid structure
	var grid = data["grid"]
	if not grid is Array:
		push_error("'grid' must be an Array")
		return false

	# Validate control_definitions structure
	var control_defs = data["control_definitions"]
	if not control_defs is Dictionary:
		push_error("'control_definitions' must be a Dictionary")
		return false

	# Validate each control definition has required fields
	for control_id in control_defs.keys():
		var control = control_defs[control_id]
		if not control is Dictionary:
			push_error("Control definition '" + control_id + "' must be a Dictionary")
			return false

		if not control.has("type"):
			push_error("Control '" + control_id + "' missing 'type' field")
			return false

		if not control.has("parameter"):
			push_error("Control '" + control_id + "' missing 'parameter' field")
			return false

	return true

func _spawn_controls_from_json():
	if not rack_config.has("grid") or not rack_config.has("control_definitions"):
		return

	var grid = rack_config["grid"]
	var control_defs = rack_config["control_definitions"]
	var layout = rack_config.get("layout", {})

	# Layout settings
	var col_spacing = layout.get("col_spacing", 0.0)  # 0 = auto-spacing
	var row_spacing = layout.get("row_spacing", 0.0)  # 0 = auto-spacing
	var auto_spacing = layout.get("auto_spacing", col_spacing == 0.0)
	var padding = layout.get("padding", 0.02)
	var gap = layout.get("gap", 0.02)  # Gap between controls

	# First pass: calculate row heights and column widths for auto-spacing
	var row_heights = []
	var col_widths = []

	if auto_spacing:
		for row_idx in range(grid.size()):
			var max_height = 0.0
			var row = grid[row_idx]
			for col_idx in range(row.size()):
				var control_id = row[col_idx]
				if control_id == "" or control_id == " ":
					continue
				if control_defs.has(control_id):
					var control_type = control_defs[control_id].get("type", "slider")
					var size = _get_control_size(control_type)
					max_height = max(max_height, size.y)
					# Expand col_widths array if needed
					while col_widths.size() <= col_idx:
						col_widths.append(0.0)
					col_widths[col_idx] = max(col_widths[col_idx], size.x)
			row_heights.append(max_height)

	# Second pass: spawn controls with calculated positions
	var y_offset = 0.0
	for row_idx in range(grid.size()):
		var row = grid[row_idx]
		var x_offset = 0.0

		for col_idx in range(row.size()):
			var control_id = row[col_idx]

			# Skip empty cells but still advance x position
			if control_id == "" or control_id == " ":
				if auto_spacing and col_idx < col_widths.size():
					x_offset += col_widths[col_idx] + gap
				elif col_spacing > 0:
					x_offset += col_spacing
				continue

			# Get control definition
			if not control_defs.has(control_id):
				push_warning("Control ID '" + control_id + "' in grid but not in control_definitions")
				continue

			var control_config = control_defs[control_id]

			# Get control type and instantiate appropriate scene
			var control_type = control_config.get("type", "slider")
			var control = _instantiate_control(control_type, control_id)
			if not control:
				continue

			parameter_container.add_child(control)

			# Calculate position
			var x: float
			var y: float

			if auto_spacing:
				x = x_offset + padding
				y = -y_offset - padding
				# Center control within its cell
				if col_idx < col_widths.size():
					var cell_width = col_widths[col_idx]
					var control_size = _get_control_size(control_type)
					x += (cell_width - control_size.x) / 2.0
			else:
				x = col_idx * col_spacing
				y = -row_idx * row_spacing

			control.transform.origin = Vector3(x, y, 0)

			# Apply control-specific configuration
			_configure_control(control, control_config, control_type)

			# Connect signals based on control type
			_connect_control_signals(control, control_id, control_type, control_config)

			# Store control with structure
			active_controls[control_id] = {
				"instance": control,
				"parameter": control_config.get("parameter", ""),
				"parameter_x": control_config.get("parameter_x", ""),  # For XY pads
				"parameter_y": control_config.get("parameter_y", ""),  # For XY pads
				"config": control_config,
				"type": control_type
			}

			# Advance x position
			if auto_spacing and col_idx < col_widths.size():
				x_offset += col_widths[col_idx] + gap
			elif col_spacing > 0:
				x_offset += col_spacing

		# Advance y position for next row
		if auto_spacing and row_idx < row_heights.size():
			y_offset += row_heights[row_idx] + gap
		elif row_spacing > 0:
			y_offset += row_spacing

# Instantiate the correct control scene based on type
func _instantiate_control(control_type: String, control_id: String) -> Node:
	var control_scene = null

	match control_type:
		# Sliders
		"slider", "slh", "slider_horizontal", "fader":
			control_scene = SLIDER_SCENE
		"slv", "slider_vertical", "vfader":
			control_scene = SLIDER_VERTICAL_SCENE
		"sls", "slider_snap", "stepped":
			control_scene = SLIDER_SNAP_SCENE
		"slz", "slider_zero", "bipolar":
			control_scene = SLIDER_ZERO_SCENE

		# Rotary controls
		"knob", "dial", "nb", "rotary":
			control_scene = DIAL_SCENE
		"wheel", "whl", "pitchbend":
			control_scene = WHEEL_SCENE

		# 2D controls
		"xy", "xypad", "2df", "pad":
			control_scene = XY_PAD_SCENE
		"js", "joystick":
			control_scene = JOYSTICK_SCENE

		# Discrete controls
		"btn", "button", "trigger":
			control_scene = BUTTON_SCENE
		"lv", "lever", "throw":
			control_scene = LEVER_SCENE

		# Monitors and displays
		"mon", "monitor", "waveform", "scope":
			control_scene = WAVEFORM_MONITOR_SCENE
		"mtr", "meter", "vu", "level":
			return _create_meter(control_id)
		"lbl", "label", "text":
			return _create_label(control_id)
		"grp", "group", "container":
			return _create_group(control_id)

		_:
			push_warning("Unknown control type '%s' for %s. Available: slider, slv, sls, slz, knob, wheel, xy, js, btn, lv, mon, mtr, lbl, grp" % [control_type, control_id])
			return null

	if control_scene:
		return control_scene.instantiate()
	return null

# Create a VU/level meter
func _create_meter(control_id: String) -> Node3D:
	var meter = Node3D.new()
	meter.name = control_id

	# Background bar
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.03, 0.12, 0.01)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1)
	bg.material_override = bg_mat
	meter.add_child(bg)

	# Level indicator (green to red gradient)
	var level = MeshInstance3D.new()
	level.name = "LevelBar"
	var level_mesh = BoxMesh.new()
	level_mesh.size = Vector3(0.025, 0.11, 0.015)
	level.mesh = level_mesh
	var level_mat = StandardMaterial3D.new()
	level_mat.albedo_color = Color(0.2, 0.8, 0.2)
	level_mat.emission_enabled = true
	level_mat.emission = Color(0.2, 0.8, 0.2)
	level_mat.emission_energy_multiplier = 0.5
	level.material_override = level_mat
	level.position.z = 0.005
	meter.add_child(level)

	# Peak indicator
	var peak = MeshInstance3D.new()
	peak.name = "PeakIndicator"
	var peak_mesh = BoxMesh.new()
	peak_mesh.size = Vector3(0.025, 0.005, 0.02)
	peak.mesh = peak_mesh
	var peak_mat = StandardMaterial3D.new()
	peak_mat.albedo_color = Color(1.0, 0.2, 0.2)
	peak_mat.emission_enabled = true
	peak_mat.emission = Color(1.0, 0.2, 0.2)
	peak.material_override = peak_mat
	peak.position = Vector3(0, 0.05, 0.01)
	meter.add_child(peak)

	# Add meter script for animation
	var script = GDScript.new()
	script.source_code = """
extends Node3D

var level: float = 0.0 : set = set_level
var peak_level: float = 0.0
var peak_hold_time: float = 0.0

func set_level(val: float):
	level = clamp(val, 0.0, 1.0)
	if level > peak_level:
		peak_level = level
		peak_hold_time = 1.0
	_update_display()

func _process(delta):
	peak_hold_time -= delta
	if peak_hold_time <= 0:
		peak_level = max(peak_level - delta * 0.5, level)
	_update_display()

func _update_display():
	var level_bar = get_node_or_null(\"LevelBar\")
	var peak_ind = get_node_or_null(\"PeakIndicator\")
	if level_bar:
		level_bar.scale.y = max(level, 0.01)
		level_bar.position.y = -0.055 + (level * 0.055)
		# Color gradient: green -> yellow -> red
		var mat = level_bar.material_override
		if mat:
			var color = Color.GREEN.lerp(Color.YELLOW, clamp(level * 2, 0, 1))
			color = color.lerp(Color.RED, clamp((level - 0.5) * 2, 0, 1))
			mat.albedo_color = color
			mat.emission = color
	if peak_ind:
		peak_ind.position.y = -0.055 + (peak_level * 0.11)
"""
	script.reload()
	meter.set_script(script)

	return meter

# Create a text label
func _create_label(control_id: String) -> Node3D:
	var label_container = Node3D.new()
	label_container.name = control_id

	var label = Label3D.new()
	label.name = "Text"
	label.text = control_id.to_upper()
	label.font_size = 32
	label.pixel_size = 0.0008
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color(0.9, 0.9, 0.9)
	label.outline_size = 4
	label_container.add_child(label)

	return label_container

# Create a group container with background
func _create_group(control_id: String) -> Node3D:
	var group = Node3D.new()
	group.name = control_id

	# Background panel
	var bg = MeshInstance3D.new()
	bg.name = "Background"
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.25, 0.2, 0.005)  # Will be resized based on contents
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.08, 0.08, 0.12, 0.9)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg.material_override = bg_mat
	bg.position.z = -0.01
	group.add_child(bg)

	# Group label
	var label = Label3D.new()
	label.name = "GroupLabel"
	label.text = control_id.to_upper()
	label.font_size = 24
	label.pixel_size = 0.0006
	label.modulate = Color(0.7, 0.7, 0.8)
	label.outline_size = 2
	label.position.y = 0.09
	group.add_child(label)

	# Border (top accent line)
	var border = MeshInstance3D.new()
	border.name = "Border"
	var border_mesh = BoxMesh.new()
	border_mesh.size = Vector3(0.25, 0.003, 0.008)
	border.mesh = border_mesh
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.3, 0.5, 0.8)
	border_mat.emission_enabled = true
	border_mat.emission = Color(0.3, 0.5, 0.8)
	border_mat.emission_energy_multiplier = 0.3
	border.material_override = border_mat
	border.position = Vector3(0, 0.098, 0)
	group.add_child(border)

	return group

# Get control size for spacing calculations
func _get_control_size(control_type: String) -> Vector2:
	# Normalize type name
	var base_type = control_type
	match control_type:
		"slh", "slider_horizontal", "fader":
			base_type = "slider"
		"slider_vertical", "vfader":
			base_type = "slv"
		"dial", "nb", "rotary":
			base_type = "knob"
		"xypad", "2df", "pad", "joystick", "js":
			base_type = "xy"
		"button", "trigger":
			base_type = "btn"
		"waveform", "scope", "mon":
			base_type = "monitor"
		"vu", "level", "mtr":
			base_type = "meter"
		"text", "lbl":
			base_type = "label"

	return CONTROL_SIZES.get(base_type, CONTROL_SIZES["default"])

# Configure control properties based on type and config
func _configure_control(control: Node, config: Dictionary, control_type: String):
	# Set label if control supports it
	var label = config.get("label", "")
	if control.has_method("set_param_name"):
		control.set_param_name(label)
	elif "label" in control:
		control.label = label

	# Get range and default values
	var p_min = config.get("min", 0.0)
	var p_max = config.get("max", 1.0)
	var p_default = config.get("default", 0.5)

	# Apply range to controls that support it
	if "limit_min" in control:
		control.limit_min = p_min
	if "limit_max" in control:
		control.limit_max = p_max

	# Set initial value
	var norm = remap(p_default, p_min, p_max, 0.0, 1.0)
	if control.has_method("set_normalized_value"):
		control.set_normalized_value(norm)
	elif "slider_value" in control:
		control.slider_value = lerp(p_min, p_max, norm)

	# Control-specific configuration
	match control_type:
		"sls", "slider_snap", "stepped":
			# Set step size for snap sliders
			var step = config.get("step", 0.1)
			if "step" in control:
				control.step = step

		"slz", "slider_zero", "bipolar":
			# Zero-centered sliders return to center on release
			if "default_on_release" in control:
				control.default_on_release = config.get("return_to_zero", true)

		"btn", "button", "trigger":
			# Button configuration
			if config.has("toggle") and "toggle_mode" in control:
				control.toggle_mode = config.get("toggle", false)
			if config.has("color") and "pressed_color" in control:
				control.pressed_color = Color(config.get("color"))

		"xy", "xypad", "2df", "pad", "js", "joystick":
			# XY pad size configuration
			if config.has("size") and "limit_min" in control:
				var size = config.get("size", 0.1)
				control.limit_min = -size
				control.limit_max = size

		"lbl", "label", "text":
			# Label text configuration
			var text_node = control.get_node_or_null("Text")
			if text_node:
				text_node.text = config.get("text", config.get("label", ""))
				if config.has("font_size"):
					text_node.font_size = int(config.get("font_size", 32))
				if config.has("color"):
					text_node.modulate = Color(config.get("color"))

		"grp", "group", "container":
			# Group configuration
			var group_label = control.get_node_or_null("GroupLabel")
			if group_label:
				group_label.text = config.get("label", config.get("name", "")).to_upper()

			# Set group color
			if config.has("color"):
				var border = control.get_node_or_null("Border")
				if border and border.material_override:
					var color = Color(config.get("color"))
					border.material_override.albedo_color = color
					border.material_override.emission = color

			# Set group size
			var bg = control.get_node_or_null("Background")
			if bg and bg.mesh:
				var width = config.get("width", 0.25)
				var height = config.get("height", 0.2)
				bg.mesh.size = Vector3(width, height, 0.005)
				# Adjust border width
				var border = control.get_node_or_null("Border")
				if border and border.mesh:
					border.mesh.size.x = width

		"mon", "monitor", "waveform", "scope":
			# Monitor configuration
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "MONITOR").to_upper()

		"mtr", "meter", "vu", "level":
			# Meter connects to audio output for level
			if config.has("source"):
				control.set_meta("audio_source", config.get("source"))

# Connect appropriate signals for each control type
func _connect_control_signals(control: Node, control_id: String, control_type: String, config: Dictionary):
	match control_type:
		"xy", "xypad", "2df", "pad", "js", "joystick":
			# 2D controls emit position (Vector2)
			if control.has_signal("slider_moved"):
				control.slider_moved.connect(_on_xy_control_changed.bind(control_id))
			elif control.has_signal("joystick_moved"):
				control.joystick_moved.connect(_on_xy_control_changed.bind(control_id))

		"btn", "button", "trigger":
			# Buttons emit pressed signal
			if control.has_signal("pressed"):
				control.pressed.connect(_on_button_pressed.bind(control_id))
			if control.has_signal("button_pressed"):
				control.button_pressed.connect(_on_button_pressed.bind(control_id))

		_:
			# Standard 1D controls (sliders, knobs, wheels, levers)
			if control.has_signal("slider_moved"):
				control.slider_moved.connect(_on_parameter_changed_json.bind(control_id))
			elif control.has_signal("hinge_moved"):
				control.hinge_moved.connect(_on_parameter_changed_json.bind(control_id))
			elif control.has_signal("lever_moved"):
				control.lever_moved.connect(_on_parameter_changed_json.bind(control_id))
			elif control.has_signal("wheel_moved"):
				control.wheel_moved.connect(_on_parameter_changed_json.bind(control_id))

# Handle XY pad / joystick movement (2 parameters)
func _on_xy_control_changed(position, control_id: String):
	if not active_controls.has(control_id):
		return

	var control_data = active_controls[control_id]
	var config = control_data["config"]

	# Get X and Y parameter names
	var param_x = config.get("parameter_x", config.get("parameter", "") + "_x")
	var param_y = config.get("parameter_y", config.get("parameter", "") + "_y")

	# Store the XY values for later retrieval
	control_data["last_x"] = position.x if position is Vector2 else position.x
	control_data["last_y"] = position.y if position is Vector2 else position.z

	# Trigger sound update with debounce
	_trigger_sound_update()

# Handle button press
func _on_button_pressed(control_id: String):
	if not active_controls.has(control_id):
		return

	var control_data = active_controls[control_id]
	var config = control_data["config"]

	# Button action - could trigger sound, toggle effect, etc.
	var action = config.get("action", "play")
	match action:
		"play":
			play_current_sound()
		"stop":
			if preview_player:
				preview_player.stop()
		"toggle":
			# Toggle a parameter between 0 and 1
			var param = config.get("parameter", "")
			if param != "":
				var current = control_data.get("toggle_state", false)
				control_data["toggle_state"] = not current
				_trigger_sound_update()

	print("Button pressed: %s (action: %s)" % [control_id, action])

func _trigger_sound_update():
	if _update_timer:
		return
	_update_timer = get_tree().create_timer(0.05)
	_update_timer.timeout.connect(func():
		_update_timer = null
		play_current_sound()
	)

func _on_parameter_changed_json(_value, control_id: String):
	# Real-time tweak with debounce for JSON-based controls
	if _update_timer: return

	_update_timer = get_tree().create_timer(0.05)
	_update_timer.timeout.connect(func():
		_update_timer = null
		play_current_sound()
	)

func _on_category_dial_moved(angle):
	var idx = int(remap(angle, -150, 150, 0, categories.size() - 1))
	if categories[idx] != current_category:
		_update_category(idx)

func _on_sound_dial_moved(angle):
	if sounds_in_category.is_empty(): return
	var idx = int(remap(angle, -150, 150, 0, sounds_in_category.size() - 1))
	if sounds_in_category[idx] != current_sound_key:
		load_sound(sounds_in_category[idx])

func _update_category(idx: int):
	current_category = categories[idx]
	category_label.text = current_category.to_upper()
	# Get all available sound types and filter by category (or just show all for now)
	sounds_in_category = SoundParameterManager.get_available_sound_types()
	
	# Simple filter for demo purposes
	if current_category != "all":
		var filtered = []
		for s in sounds_in_category:
			if current_category in s.to_lower():
				filtered.append(s)
		if filtered.is_empty(): filtered = [sounds_in_category[0]]
		sounds_in_category = filtered
		
	current_sound_key = sounds_in_category[0]
	sound_label.text = current_sound_key.capitalize().replace("_", " ")
	load_sound(current_sound_key)

func _on_play_pressed(_btn):
	play_current_sound()

func _on_save_pressed(_btn):
	var values = _get_current_values()
	SoundParameterManager.save_sound_parameters(current_sound_key, values)

func _get_mock_sounds_for_category(_cat: String) -> Array:
	return SoundParameterManager.get_available_sound_types()

func load_sound(sound_key: String):
	current_sound_key = sound_key
	var params = SoundParameterManager.get_sound_parameters(sound_key)
	_clear_controls()
	_spawn_controls(params)

func _clear_controls():
	for child in parameter_container.get_children():
		child.queue_free()
	active_controls.clear()

func _spawn_controls(params: Dictionary):
	var count = 0
	# Get defaults to fill in missing min/max if we have flat params
	var defaults = SoundParameterManager.get_sound_parameters(current_sound_key)
	
	for p_name in params.keys():
		var p_data = params[p_name]
		
		# Define range and current value
		var val = 0.5
		var p_min = 0.0
		var p_max = 1.0
		
		if p_data is Dictionary:
			val = p_data.get("value", 0.5)
			p_min = p_data.get("min", 0.0)
			p_max = p_data.get("max", 1.0)
		else:
			# Flat param, try to find range in defaults
			val = float(p_data)
			var d_data = defaults.get(p_name, {})
			if d_data is Dictionary:
				p_min = d_data.get("min", 0.0)
				p_max = d_data.get("max", 1.0)
			else:
				# Fallback range logic
				if "freq" in p_name: p_max = 2000.0
				elif "amp" in p_name: p_max = 1.0
				elif "dur" in p_name: p_max = 10.0
		
		# Choose Dial for specific keywords
		var control
		if _is_dial_param(p_name):
			control = DIAL_SCENE.instantiate()
		else:
			control = SLIDER_SCENE.instantiate()
			
		parameter_container.add_child(control)
		control.transform.origin = _get_layout_position(count)
		control.set_param_name(p_name)
		
		# Set initial values
		var norm = remap(val, p_min, p_max, 0.0, 1.0)
		if control.has_method("set_normalized_value"):
			control.set_normalized_value(norm)
			
		# Connect real-time updates
		if control.has_signal("slider_moved"):
			control.slider_moved.connect(_on_parameter_changed.bind(p_name))
		elif control.has_signal("hinge_moved"):
			control.hinge_moved.connect(_on_parameter_changed.bind(p_name))
			
		active_controls[p_name] = control
		count += 1

var _update_timer: SceneTreeTimer = null

func _on_parameter_changed(_value, _p_name: String):
	# Real-time tweak with debounce to prevent stuttering
	if _update_timer: return
	
	_update_timer = get_tree().create_timer(0.05) # 50ms is enough for snappy feedback
	_update_timer.timeout.connect(func(): 
		_update_timer = null
		play_current_sound()
	)

func _is_dial_param(p_name: String) -> bool:
	var dial_keywords = ["hard", "qual", "ring", "mod", "detune", "blend", "category", "sound"]
	for k in dial_keywords:
		if k in p_name.to_lower(): return true
	return false

func _get_layout_position(index: int) -> Vector3:
	# 2 columns for wider horizontal sliders
	var col_spacing = 0.22
	var row_spacing = 0.1
	var cols = 2
	
	var x = (index % cols) * col_spacing
	var y = -floor(index / float(cols)) * row_spacing
	
	# Center the grid and move up towards the display
	return Vector3(x - ((cols-1) * col_spacing * 0.5), y + 0.05, 0)

func play_current_sound():
	var values = _get_current_values()
	var sound_type = _resolve_sound_type(current_sound_key)
	
	var stream = CustomSoundGenerator.generate_custom_sound(sound_type, values)
	if stream:
		preview_player.stream = stream
		preview_player.play()
		sound_played.emit(stream)

func _get_current_values() -> Dictionary:
	var values = {}

	if use_json_config:
		# JSON config mode - use new structure with support for all control types
		for control_id in active_controls.keys():
			var control_data = active_controls[control_id]
			var control = control_data["instance"]
			var config = control_data["config"]
			var control_type = control_data.get("type", "slider")

			# Handle different control types
			match control_type:
				"xy", "xypad", "2df", "pad", "js", "joystick":
					# XY controls map to two parameters
					var param_x = config.get("parameter_x", config.get("parameter", "") + "_x")
					var param_y = config.get("parameter_y", config.get("parameter", "") + "_y")
					var min_x = config.get("min_x", config.get("min", 0.0))
					var max_x = config.get("max_x", config.get("max", 1.0))
					var min_y = config.get("min_y", config.get("min", 0.0))
					var max_y = config.get("max_y", config.get("max", 1.0))

					# Get stored XY values or read from control
					var x_val = control_data.get("last_x", 0.0)
					var y_val = control_data.get("last_y", 0.0)

					# Normalize and remap
					var size = config.get("size", 0.1)
					var norm_x = remap(x_val, -size, size, 0.0, 1.0)
					var norm_y = remap(y_val, -size, size, 0.0, 1.0)

					values[param_x] = lerp(min_x, max_x, norm_x)
					values[param_y] = lerp(min_y, max_y, norm_y)

				"btn", "button", "trigger":
					# Buttons - check toggle state or skip if momentary
					var param_name = config.get("parameter", "")
					if param_name != "" and control_data.has("toggle_state"):
						values[param_name] = 1.0 if control_data["toggle_state"] else 0.0

				_:
					# Standard 1D controls (sliders, knobs, wheels, levers)
					var param_name = control_data["parameter"]
					if param_name == "":
						continue

					var norm = 0.5
					if control.has_method("get_normalized_value"):
						norm = control.get_normalized_value()
					elif "slider_value" in control:
						var p_min = config.get("min", 0.0)
						var p_max = config.get("max", 1.0)
						norm = remap(control.slider_value, p_min, p_max, 0.0, 1.0)

					# Get range from config
					var p_min = config.get("min", 0.0)
					var p_max = config.get("max", 1.0)

					values[param_name] = lerp(p_min, p_max, norm)
	else:
		# Traditional mode - old structure
		var defaults = SoundParameterManager.get_sound_parameters(current_sound_key)

		for p_name in active_controls.keys():
			var control = active_controls[p_name]
			var norm = 0.5
			if control.has_method("get_normalized_value"):
				norm = control.get_normalized_value()

			# Map back to real range
			var p_min = 0.0
			var p_max = 1.0

			# Look for range in defaults
			var d_data = defaults.get(p_name, {})
			if d_data is Dictionary:
				p_min = d_data.get("min", 0.0)
				p_max = d_data.get("max", 1.0)
			else:
				# Fallback if not in defaults
				if "freq" in p_name: p_max = 2000.0
				elif "amp" in p_name: p_max = 1.0
				elif "dur" in p_name: p_max = 10.0

			values[p_name] = lerp(p_min, p_max, norm)

	return values

func _resolve_sound_type(key: String):
	# Basic lookup, in a real app this would be more robust
	var s_type = key.to_upper()
	if AudioSynthesizer.SoundType.has(s_type):
		return AudioSynthesizer.SoundType[s_type]
	return AudioSynthesizer.SoundType.BASIC_SINE_WAVE
