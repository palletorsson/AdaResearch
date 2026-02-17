@tool
extends Node3D

## Universal VR Audio Controller (UVAC)
## The central brain of the modular synth rack.
## Supports Ableton-style controls: sliders, knobs, XY pads, buttons

# Load PickupCube for shared Mario parameter sync
const PickupCube = preload("res://commons/scenes/mapobjects/pick_up_cube.gd")

# Control scene preloads
const SLIDER_SCENE = preload("res://commons/interactables/slider_smooth.tscn")
const SLIDER_HORIZONTAL_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const DIAL_SCENE = preload("res://commons/interactables/dial_smooth.tscn")

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
const SPECTRUM_DISPLAY_SCENE = preload("res://commons/audio/interfaces/VRSpectrumDisplay.tscn")
const WAVEFORM_DISPLAY_SCENE = preload("res://commons/audio/interfaces/VRWaveformDisplay.tscn")
const LISSAJOUS_DISPLAY_SCENE = preload("res://commons/audio/interfaces/VRLissajousDisplay.tscn")
const SIMPLE_WAVEFORM_SCENE = preload("res://commons/audio/interfaces/VRSimpleWaveform.tscn")

# Default spacing by control type (width, height in meters)
const CONTROL_SIZES = {
	"slider": Vector2(0.08, 0.22),
	"slh": Vector2(0.22, 0.08),
	"slv": Vector2(0.08, 0.22),
	"knob": Vector2(0.10, 0.10),
	"wheel": Vector2(0.12, 0.12),
	"xy": Vector2(0.16, 0.16),
	"btn": Vector2(0.08, 0.08),
	"lv": Vector2(0.08, 0.15),
	"monitor": Vector2(0.30, 0.22),
	"spectrum": Vector2(0.32, 0.24),
	"waveform": Vector2(0.32, 0.24),
	"simple_waveform": Vector2(0.32, 0.24),
	"lissajous": Vector2(0.30, 0.30),
	"meter": Vector2(0.04, 0.12),
	"label": Vector2(0.20, 0.04),
	"grp": Vector2(0.25, 0.20),
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

var current_sound_key: String = "basic_sine_wave"
var active_controls: Dictionary = {}
var active_buttons: Dictionary = {}
var rack_config: Dictionary = {}
var use_json_config: bool = true

# Dedicated audio bus for this rack's output (allows waveform display to show only rack audio)
var dedicated_bus_name: String = ""
var _dedicated_bus_index: int = -1

# Auto-save timer for syncing Mario parameters (like MarioSoundController)
var _auto_save_timer: Timer
var _auto_save_interval: float = 2.0

const RACK_CONFIG_BASE_PATH = "res://commons/audio/rack_configs/"

func _ready():
	# Setup dedicated audio bus for this rack
	_setup_dedicated_bus()

	# Setup auto-save timer for parameter syncing
	_setup_auto_save_timer()

	# Check if we should use JSON config
	if rack_config_path != "" and FileAccess.file_exists(rack_config_path):
		load_rack_config(rack_config_path)
	elif rack_config_path != "":
		push_warning("UniversalVRAudioController: Config path set but file not found: %s" % rack_config_path)

func _setup_dedicated_bus():
	"""Create a dedicated audio bus for this rack's output"""
	# Generate unique bus name based on instance ID
	dedicated_bus_name = "RackBus_%d" % get_instance_id()

	# Check if bus already exists
	_dedicated_bus_index = AudioServer.get_bus_index(dedicated_bus_name)
	if _dedicated_bus_index != -1:
		print("UniversalVRAudioController: Using existing bus '%s'" % dedicated_bus_name)
	else:
		# Create new bus
		var bus_count = AudioServer.bus_count
		AudioServer.add_bus(bus_count)
		AudioServer.set_bus_name(bus_count, dedicated_bus_name)
		AudioServer.set_bus_send(bus_count, "Master")  # Route to Master
		_dedicated_bus_index = bus_count
		print("UniversalVRAudioController: Created dedicated bus '%s' (index %d)" % [dedicated_bus_name, _dedicated_bus_index])

	# Route preview player to dedicated bus
	if preview_player:
		preview_player.bus = dedicated_bus_name
		print("UniversalVRAudioController: Routed audio player to '%s'" % dedicated_bus_name)

func get_dedicated_bus_name() -> String:
	"""Return the dedicated bus name for this rack"""
	return dedicated_bus_name

func _setup_auto_save_timer():
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = _auto_save_interval
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)

func _on_auto_save_timeout():
	# Sync Mario parameters globally so pickup cubes always use current settings
	if current_sound_key == "pickup_mario":
		_sync_mario_parameters()

func _sync_mario_parameters():
	var values = _get_current_values()
	var start_freq = values.get("start_freq", 540.0)
	var end_freq = values.get("end_freq", 880.0)
	var decay_rate = values.get("decay_rate", 8.0)
	var duration = values.get("duration", 0.36)
	PickupCube.set_shared_mario_parameters(start_freq, end_freq, decay_rate, duration)

# Audio level for meters
var _rack_spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var _rack_spectrum_setup: bool = false

func _process(_delta: float):
	_update_rack_meters()

func _update_rack_meters():
	"""Update any meters that monitor the rack bus"""
	# Setup spectrum analyzer on rack bus if needed
	if not _rack_spectrum_setup and _dedicated_bus_index >= 0:
		_setup_rack_spectrum_analyzer()

	if not _rack_spectrum_instance:
		return

	# Get audio level from rack bus
	var total_magnitude = 0.0
	for freq in [100.0, 200.0, 400.0, 800.0, 1600.0, 3200.0]:
		var mag = _rack_spectrum_instance.get_magnitude_for_frequency_range(freq * 0.8, freq * 1.2)
		total_magnitude += mag.length()
	var audio_level = clamp(total_magnitude * 10.0, 0.0, 1.0)

	# Update all rack meters
	for control_id in active_controls:
		var control_data = active_controls[control_id]
		var control = control_data.get("instance")  # Controls stored as "instance"
		if not control:
			continue
		if control.has_meta("audio_source") and control.get_meta("audio_source") == "rack":
			if "level" in control:
				control.level = audio_level

func _setup_rack_spectrum_analyzer():
	"""Setup spectrum analyzer on the dedicated rack bus"""
	_rack_spectrum_setup = true

	# Find existing or create spectrum analyzer
	for i in range(AudioServer.get_bus_effect_count(_dedicated_bus_index)):
		var effect = AudioServer.get_bus_effect(_dedicated_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_rack_spectrum_instance = AudioServer.get_bus_effect_instance(_dedicated_bus_index, i)
			return

	# Create new analyzer
	var analyzer = AudioEffectSpectrumAnalyzer.new()
	analyzer.buffer_length = 0.1
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_512
	AudioServer.add_bus_effect(_dedicated_bus_index, analyzer)

	var effect_idx = AudioServer.get_bus_effect_count(_dedicated_bus_index) - 1
	_rack_spectrum_instance = AudioServer.get_bus_effect_instance(_dedicated_bus_index, effect_idx)
	print("UniversalVRAudioController: Created spectrum analyzer for rack meters")

# Called by GridInteractablesComponent when using # syntax
# Supported parameters:
#   #config:synth_rack       â†’ Load rack config from rack_configs folder
#   #sound:laser_shot        â†’ Override sound type
#   #autoplay:true           â†’ Auto-play sound on ready
#   #col_spacing:0.25        â†’ Override column spacing
#   #row_spacing:0.12        â†’ Override row spacing
#   #hide_selection:true     â†’ Hide category/sound selection panel
#   #hide_buttons:true       â†’ Hide play/save buttons
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
			print("  â†’ Loaded rack config: %s" % config_name)
		else:
			push_error("UniversalVRAudioController: Rack config not found: %s" % full_path)
			_list_available_configs()

	# Override sound type
	if config_data.has("sound"):
		var sound_type = str(config_data["sound"])
		current_sound_key = sound_type
		if rack_config.has("rack_info"):
			rack_config["rack_info"]["sound_type"] = sound_type
		print("  â†’ Sound type override: %s" % sound_type)

	# Override layout spacing
	if config_data.has("col_spacing"):
		var spacing = float(config_data["col_spacing"])
		if rack_config.has("layout"):
			rack_config["layout"]["col_spacing"] = spacing
		_respawn_controls_if_needed()
		print("  â†’ Column spacing: %s" % spacing)

	if config_data.has("row_spacing"):
		var spacing = float(config_data["row_spacing"])
		if rack_config.has("layout"):
			rack_config["layout"]["row_spacing"] = spacing
		_respawn_controls_if_needed()
		print("  â†’ Row spacing: %s" % spacing)

	# Hide selection panel
	if config_data.has("hide_selection"):
		var should_hide = str(config_data["hide_selection"]).to_lower() == "true"
		if has_node("SelectionPanel"):
			$SelectionPanel.visible = not should_hide
			print("  â†’ Selection panel visible: %s" % (not should_hide))

	# Hide buttons
	if config_data.has("hide_buttons"):
		var should_hide = str(config_data["hide_buttons"]).to_lower() == "true"
		if has_node("Buttons"):
			$Buttons.visible = not should_hide
			print("  â†’ Buttons visible: %s" % (not should_hide))

	# Auto-play on ready
	if config_data.has("autoplay"):
		var should_autoplay = str(config_data["autoplay"]).to_lower() == "true"
		if should_autoplay:
			# Defer to ensure controls are spawned
			call_deferred("play_current_sound")
			print("  â†’ Autoplay enabled")

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
		if info.has("sound_type"):
			current_sound_key = info["sound_type"]

	# Spawn controls from JSON config
	_clear_controls()
	_spawn_controls_from_json()

	# Apply layout visibility settings
	var layout = rack_config.get("layout", {})
	if layout.has("hide_selection"):
		var should_hide = layout["hide_selection"]
		if has_node("SelectionPanel"):
			$SelectionPanel.visible = not should_hide
	if layout.has("hide_buttons"):
		var should_hide = layout["hide_buttons"]
		if has_node("Buttons"):
			$Buttons.visible = not should_hide

	# Configure cable case colors from layout
	_configure_cable_case(layout)

	print("Loaded rack config: ", rack_config.get("rack_info", {}).get("name", "Unknown"))

func _configure_cable_case(layout: Dictionary):
	"""Configure cable case decoration colors based on layout settings"""
	var cable_case = get_node_or_null("CableCase")
	if not cable_case:
		return

	# Set accent color from layout (matches button colors, etc.)
	if layout.has("cable_accent_color"):
		var color = Color(layout["cable_accent_color"])
		if "accent_color" in cable_case:
			cable_case.accent_color = color

	# Check for cable visibility toggle
	if layout.has("show_cables"):
		cable_case.visible = layout["show_cables"]

	# Set glow intensity
	if layout.has("cable_glow"):
		if "glow_intensity" in cable_case:
			cable_case.glow_intensity = float(layout["cable_glow"])

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

		# Visual/display controls don't need parameters
		var type = control.get("type", "slider")
		if type in ["label", "lbl", "text", "group", "grp", "container", "monitor", "mon", "scope", "spectrum", "spec", "fft", "waveform", "wave", "osc", "simple_waveform", "srcwave", "rack_wave", "lissajous", "liss", "xy_wave", "paramwave", "meter", "mtr", "vu", "level"]:
			continue
			
		# XY controls need parameter_x and parameter_y (or just parameter)
		if type in ["xy", "xypad", "2df", "pad", "js", "joystick"]:
			if not control.has("parameter") and (not control.has("parameter_x") or not control.has("parameter_y")):
				push_error("Control '" + control_id + "' must have 'parameter' OR 'parameter_x' and 'parameter_y'")
				return false
			continue

		# Standard controls need parameter
		if not control.has("parameter"):
			# Buttons can have 'action' instead of 'parameter'
			if type in ["btn", "button", "trigger"] and control.has("action"):
				continue
			
			push_error("Control '" + control_id + "' missing 'parameter' field")
			return false

	return true

func _spawn_controls_from_json():
	if not rack_config.has("grid") or not rack_config.has("control_definitions"):
		return

	var control_defs = rack_config["control_definitions"]
	var layout = rack_config.get("layout", {})

	# Check for legacy manual spacing mode
	var use_legacy = layout.has("col_spacing") and layout.get("col_spacing", 0.0) > 0
	if use_legacy:
		_spawn_controls_legacy()
		return

	# Use new blueprint-based layout calculator
	var layout_result = RackLayoutCalculator.calculate_layout(rack_config)

	print("RackLayout: Total size %.2fm x %.2fm, %d controls" % [
		layout_result.total_width,
		layout_result.total_height,
		layout_result.positions.size()
	])

	# Spawn controls at calculated positions
	for control_id in layout_result.positions.keys():
		if not control_defs.has(control_id):
			continue

		var control_config = control_defs[control_id]
		var control_type = control_config.get("type", "slider")
		var control = _instantiate_control(control_type, control_id)
		if not control:
			continue

		parameter_container.add_child(control)

		# Apply calculated position
		var pos: Vector3 = layout_result.positions[control_id]
		control.transform.origin = pos

		# Apply control-specific configuration
		_configure_control(control, control_config, control_type)

		# Connect signals based on control type
		_connect_control_signals(control, control_id, control_type, control_config)

		# Store control with structure
		active_controls[control_id] = {
			"instance": control,
			"parameter": control_config.get("parameter", ""),
			"parameter_x": control_config.get("parameter_x", ""),
			"parameter_y": control_config.get("parameter_y", ""),
			"config": control_config,
			"type": control_type
		}

# Legacy spawn method for configs with explicit col_spacing/row_spacing
func _spawn_controls_legacy():
	var grid = rack_config["grid"]
	var control_defs = rack_config["control_definitions"]
	var layout = rack_config.get("layout", {})

	var col_spacing = layout.get("col_spacing", 0.12)
	var row_spacing = layout.get("row_spacing", 0.10)

	for row_idx in range(grid.size()):
		var row = grid[row_idx]
		for col_idx in range(row.size()):
			var control_id = row[col_idx]
			if control_id == "" or control_id == " ":
				continue
			if not control_defs.has(control_id):
				continue

			var control_config = control_defs[control_id]
			var control_type = control_config.get("type", "slider")
			var control = _instantiate_control(control_type, control_id)
			if not control:
				continue

			parameter_container.add_child(control)

			var x = col_idx * col_spacing
			var y = -row_idx * row_spacing
			control.transform.origin = Vector3(x, y, 0.03)

			_configure_control(control, control_config, control_type)
			_connect_control_signals(control, control_id, control_type, control_config)

			active_controls[control_id] = {
				"instance": control,
				"parameter": control_config.get("parameter", ""),
				"parameter_x": control_config.get("parameter_x", ""),
				"parameter_y": control_config.get("parameter_y", ""),
				"config": control_config,
				"type": control_type
			}

# Instantiate the correct control scene based on type
func _instantiate_control(control_type: String, control_id: String) -> Node:
	var control_scene = null

	match control_type:
		# Sliders
		"slider", "slv", "slider_vertical", "vfader", "fader":
			control_scene = SLIDER_SCENE
		"slh", "slider_horizontal":
			control_scene = SLIDER_HORIZONTAL_SCENE
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
		"mon", "monitor", "scope":
			control_scene = WAVEFORM_MONITOR_SCENE
		"spectrum", "spec", "fft":
			control_scene = SPECTRUM_DISPLAY_SCENE
		"waveform", "wave", "osc":
			control_scene = WAVEFORM_DISPLAY_SCENE
		"simple_waveform", "srcwave", "rack_wave":
			control_scene = SIMPLE_WAVEFORM_SCENE
		"lissajous", "liss", "xy_wave", "paramwave":
			control_scene = LISSAJOUS_DISPLAY_SCENE
		"mtr", "meter", "vu", "level":
			return _create_meter(control_id)
		"lbl", "label", "text":
			return _create_label(control_id)
		"grp", "group", "container":
			return _create_group(control_id)

		_:
			push_warning("Unknown control type '%s' for %s. Available: slider, slv, sls, slz, knob, wheel, xy, js, btn, lv, mon, spectrum, waveform, lissajous, mtr, lbl, grp" % [control_type, control_id])
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
	bg_mat.albedo_color = Color(0.18, 0.18, 0.22, 1)
	bg.material_override = bg_mat
	meter.add_child(bg)

	# Level indicator (green to red gradient)
	var level = MeshInstance3D.new()
	level.name = "LevelBar"
	var level_mesh = BoxMesh.new()
	level_mesh.size = Vector3(0.025, 0.11, 0.015)
	level.mesh = level_mesh
	var level_mat = StandardMaterial3D.new()
	level_mat.albedo_color = Color(0.25, 0.78, 0.35, 1)
	level_mat.emission_enabled = true
	level_mat.emission = Color(0.25, 0.78, 0.35, 1)
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
	peak_mat.albedo_color = Color(0.90, 0.22, 0.22, 1)
	peak_mat.emission_enabled = true
	peak_mat.emission = Color(0.90, 0.22, 0.22, 1)
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
	label.modulate = Color(0.12, 0.12, 0.14, 1)
	label.outline_size = 0
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
	bg_mat.albedo_color = Color(0.90, 0.90, 0.92, 0.95)
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
	label.modulate = Color(0.40, 0.40, 0.44, 1)
	label.outline_size = 0
	label.position.y = 0.09
	group.add_child(label)

	# Border (top accent line)
	var border = MeshInstance3D.new()
	border.name = "Border"
	var border_mesh = BoxMesh.new()
	border_mesh.size = Vector3(0.25, 0.003, 0.008)
	border.mesh = border_mesh
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.95, 0.45, 0.15, 1)
	border_mat.emission_enabled = true
	border_mat.emission = Color(0.95, 0.45, 0.15, 1)
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
		"wheel", "whl", "pitchbend":
			base_type = "wheel"
		"lv", "lever", "throw":
			base_type = "lv"
		"grp", "group", "container":
			base_type = "grp"
		"monitor", "mon", "waveform", "scope":
			base_type = "monitor"
		"lissajous", "liss", "xy_wave", "paramwave":
			base_type = "lissajous"
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

	# Set display range if supported (for custom controls like slider_smooth)
	if control.has_method("set_range"):
		control.set_range(p_min, p_max)

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
			if config.has("color"):
				var base_color = Color(config.get("color"))
				# Released color = the config color (visible when not pressed)
				if "released_color" in control:
					control.released_color = base_color
				# Pressed color = brighter version when pressed
				if "pressed_color" in control:
					control.pressed_color = base_color.lightened(0.3)
				# Force update the visual state with new colors
				if control.has_method("update_colors"):
					control.update_colors()

		"xy", "xypad", "2df", "pad", "js", "joystick":
			# XY pad size configuration
			if config.has("size") and "limit_min" in control:
				var size = config.get("size", 0.1)
				control.limit_min = -size
				control.limit_max = size

		"wheel", "whl", "pitchbend":
			# Rotate wheel to face forward (if it's a flat wheel)
			# Assuming wheel_smooth is flat on XZ, rotate 90 deg on X
			control.rotation_degrees.x = 90
		
		"lv", "lever", "throw":
			# Rotate lever to face forward
			# Assuming lever_smooth is vertical (Y-up), rotate -90 on X so it sticks out Z
			control.rotation_degrees.x = -90

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

		"mon", "monitor", "scope":
			# Monitor configuration
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "MONITOR").to_upper()

		"spectrum", "spec", "fft":
			# Spectrum display configuration
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "SPECTRUM").to_upper()

		"waveform", "wave", "osc":
			# Waveform display configuration
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "WAVEFORM").to_upper()

			# Configure audio source: "rack" = dedicated bus, "master" or omitted = Master bus
			var source = config.get("source", "master")
			if source == "rack" and dedicated_bus_name != "":
				if control.has_method("set_source_bus"):
					control.set_source_bus(dedicated_bus_name)
				elif "source_bus" in control:
					control.source_bus = dedicated_bus_name
				print("UniversalVRAudioController: Waveform display set to monitor rack bus '%s'" % dedicated_bus_name)

		"simple_waveform", "srcwave", "rack_wave":
			# Simple waveform display - shows only the rack's audio
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "WAVEFORM").to_upper()

			# Always use rack bus for simple_waveform (that's its purpose)
			var source = config.get("source", "rack")
			if source == "rack" and dedicated_bus_name != "":
				if control.has_method("set_source_bus"):
					control.set_source_bus(dedicated_bus_name)
				print("UniversalVRAudioController: Simple waveform set to rack bus '%s'" % dedicated_bus_name)

			# Store parameter bindings for frequency/amplitude display
			if config.has("freq_param"):
				control.set_meta("freq_param", config.get("freq_param"))
			if config.has("amp_param"):
				control.set_meta("amp_param", config.get("amp_param"))
			control.set_meta("is_simple_waveform", true)

		"lissajous", "liss", "xy_wave", "paramwave":
			# Lissajous display configuration
			if config.has("label"):
				var label_node = control.get_node_or_null("Chassis/LabelName")
				if label_node:
					label_node.text = config.get("label", "LISSAJOUS").to_upper()
			
			# Store param bindings for frequency updates
			if config.has("params"):
				var params = config.get("params", [])
				control.set_meta("param_x", params[0] if params.size() > 0 else "")
				control.set_meta("param_y", params[1] if params.size() > 1 else "")
			
			# Store control reference for updates
			control.set_meta("is_lissajous", true)

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
	# Time-based debounce for auto-play
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_play_time < min_play_interval:
		return
	_last_play_time = current_time
	play_current_sound()

func _on_parameter_changed_json(_value, _control_id: String):
	# Update any waveform displays that are bound to this parameter
	_update_waveform_displays()

	# Real-time tweak with time-based debounce to prevent rapid firing
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_play_time < min_play_interval:
		return
	_last_play_time = current_time
	play_current_sound()

func _update_waveform_displays():
	"""Update any waveform displays with current parameter values"""
	var values = _get_current_values()

	for control_id in active_controls:
		var control_data = active_controls[control_id]
		var control = control_data.get("instance")  # Controls stored as "instance", not "node"
		if not control:
			continue

		# Update simple waveform displays
		if control.has_meta("is_simple_waveform"):
			var freq_param = control.get_meta("freq_param") if control.has_meta("freq_param") else ""
			var amp_param = control.get_meta("amp_param") if control.has_meta("amp_param") else ""

			if freq_param != "" and values.has(freq_param):
				var freq_val = values[freq_param]
				if control.has_method("set_frequency"):
					control.set_frequency(freq_val)
			if amp_param != "" and values.has(amp_param):
				var amp_val = values[amp_param]
				if control.has_method("set_amplitude"):
					control.set_amplitude(amp_val)



func _on_play_pressed(_btn):
	play_current_sound()

func _on_save_pressed(_btn):
	var values = _get_current_values()
	SoundParameterManager.save_sound_parameters(current_sound_key, values)

func _get_mock_sounds_for_category(_cat: String) -> Array:
	return SoundParameterManager.get_available_sound_types()

func load_sound(sound_key: String):
	current_sound_key = sound_key
	
	# Traditional mode is deprecated. Ensure we are using JSON config or just update the sound key.
	print("UniversalVRAudioController: Switched sound to %s" % current_sound_key)

func _clear_controls():
	for child in parameter_container.get_children():
		child.queue_free()
	active_controls.clear()



var _update_timer: SceneTreeTimer = null
var _last_play_time: float = 0.0
var min_play_interval: float = 0.5  # 500ms between auto-plays (like MarioSoundController)

func _on_parameter_changed(_value, _p_name: String):
	# Real-time tweak with time-based debounce to prevent rapid firing
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_play_time < min_play_interval:
		return
	_last_play_time = current_time
	play_current_sound()



func play_current_sound():
	var values = _get_current_values()
	var sound_type = _resolve_sound_type(current_sound_key)

	print("UVAC: Playing sound - key: %s, type: %s" % [current_sound_key, sound_type])
	print("UVAC: Values: %s" % str(values))

	# Sync Mario parameters globally so pickup cubes use them too
	if current_sound_key == "pickup_mario":
		var start_freq = values.get("start_freq", 540.0)
		var end_freq = values.get("end_freq", 880.0)
		var decay_rate = values.get("decay_rate", 8.0)
		var duration = values.get("duration", 0.36)
		PickupCube.set_shared_mario_parameters(start_freq, end_freq, decay_rate, duration)
		print("UVAC: Synced Mario params - start: %s, end: %s, decay: %s, dur: %s" % [start_freq, end_freq, decay_rate, duration])

	var stream = CustomSoundGenerator.generate_custom_sound(sound_type, values)
	if stream:
		preview_player.stream = stream
		preview_player.play()
		sound_played.emit(stream)
	else:
		push_warning("UVAC: Failed to generate sound stream")

func _get_current_values() -> Dictionary:
	var values = {}

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

	return values

func _resolve_sound_type(key: String):
	# Basic lookup, in a real app this would be more robust
	var s_type = key.to_upper()
	if AudioSynthesizer.SoundType.has(s_type):
		return AudioSynthesizer.SoundType[s_type]
	return AudioSynthesizer.SoundType.BASIC_SINE_WAVE
