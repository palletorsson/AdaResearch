@tool
extends Node3D

## Universal VR Audio Controller (UVAC)
## The central brain of the modular synth rack.

const SLIDER_SCENE = preload("res://commons/audio/interfaces/VRAudioControlSlider.tscn")
const DIAL_SCENE = preload("res://commons/audio/interfaces/VRAudioControlDial.tscn")

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

	var col_spacing = layout.get("col_spacing", 0.22)
	var row_spacing = layout.get("row_spacing", 0.1)

	# Iterate through grid to spawn controls
	for row_idx in range(grid.size()):
		var row = grid[row_idx]
		for col_idx in range(row.size()):
			var control_id = row[col_idx]

			# Skip empty cells
			if control_id == "" or control_id == " ":
				continue

			# Get control definition
			if not control_defs.has(control_id):
				push_warning("Control ID '" + control_id + "' in grid but not in control_definitions")
				continue

			var control_config = control_defs[control_id]

			# Determine control type
			var control_scene = null
			var control_type = control_config.get("type", "slider")
			if control_type == "knob" or control_type == "dial":
				control_scene = DIAL_SCENE
			elif control_type == "slider":
				control_scene = SLIDER_SCENE
			else:
				push_warning("Unknown control type '" + control_type + "' for " + control_id)
				continue

			# Instantiate control
			var control = control_scene.instantiate()
			parameter_container.add_child(control)

			# Calculate position from grid coordinates
			var x = col_idx * col_spacing
			var y = -row_idx * row_spacing
			control.transform.origin = Vector3(x, y, 0)

			# Set label
			var label = control_config.get("label", control_id)
			control.set_param_name(label)

			# Get range and default values
			var p_min = control_config.get("min", 0.0)
			var p_max = control_config.get("max", 1.0)
			var p_default = control_config.get("default", 0.5)

			# Set initial value (normalized)
			var norm = remap(p_default, p_min, p_max, 0.0, 1.0)
			if control.has_method("set_normalized_value"):
				control.set_normalized_value(norm)

			# Connect signals
			if control.has_signal("slider_moved"):
				control.slider_moved.connect(_on_parameter_changed_json.bind(control_id))
			elif control.has_signal("hinge_moved"):
				control.hinge_moved.connect(_on_parameter_changed_json.bind(control_id))

			# Store control with new structure
			active_controls[control_id] = {
				"instance": control,
				"parameter": control_config["parameter"],
				"config": control_config
			}

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
		# JSON config mode - use new structure
		for control_id in active_controls.keys():
			var control_data = active_controls[control_id]
			var control = control_data["instance"]
			var param_name = control_data["parameter"]
			var config = control_data["config"]

			var norm = 0.5
			if control.has_method("get_normalized_value"):
				norm = control.get_normalized_value()

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
