# ModularSoundDesignerInterface.gd
# Enhanced modular interface with working parameter controls and master bus visualization
# Educational Sound Synthesis Learning Platform

extends Control
class_name ModularSoundDesignerInterface

# Core UI References
var sound_type_option: OptionButton
var preview_button: Button
var stop_button: Button
var save_button: Button
var load_button: Button
var export_button: Button
var realtime_toggle: CheckBox
var parameters_container: VBoxContainer

# Audio Player for previewing sounds
var audio_player: AudioStreamPlayer
var current_sound_type: AudioSynthesizer.SoundType = AudioSynthesizer.SoundType.BASIC_SINE_WAVE

# Real-time update system
var realtime_enabled: bool = true
var update_timer: Timer
var needs_audio_update: bool = false

# Parameter tracking (direct approach like working version)
var parameter_controls = {}
var value_labels = {}

# Audio Visualization Component
var audio_visualization: Node
var master_bus_index: int

# Sound Parameters - Loaded dynamically from JSON files
var sound_parameters = {}
var sound_names = {}
var sound_type_mapping = {}
var ordered_sound_types = []  # Track the order of sound types for dropdown mapping

func _load_sound_parameters_from_folder():
	"""Load all sound parameter files from all parameter categories"""
	print("📂 Loading sound parameters from all categories...")
	
	# Clear existing data
	sound_parameters.clear()
	sound_names.clear()
	sound_type_mapping.clear()
	
	# Use the enhanced parameter loader to get all parameters
	sound_parameters = EnhancedParameterLoader.load_all_parameters()
	
	if sound_parameters.size() == 0:
		print("❌ No parameters loaded, using fallback")
		_load_fallback_parameters()
		return
	
	# Create display names for all loaded sounds
	for sound_key in sound_parameters.keys():
		_create_display_name_for_sound(sound_key)
	
	# Create sound type mappings based on loaded parameters
	_create_sound_type_mappings()
	
	print("✅ Loaded %d sound types from all categories" % sound_parameters.size())

func _create_display_name_for_sound(sound_key: String):
	"""Create a display name with emoji for a sound"""
	var display_name = sound_key.capitalize().replace("_", " ")
	
	# Add emoji based on sound type
	var emoji_map = {
		"kick": "🥁", "808": "🥁", "drum": "🥁",
		"hihat": "🔥", "hat": "🔥", "606": "🔥",
		"bass": "🎵", "sub": "🎵",
		"drone": "🌌", "ambient": "🌌", "amiga": "🌌",
		"laser": "🔫", "shot": "🔫",
		"pickup": "🪙", "mario": "🪙",
		"explosion": "💥", "bomb": "💥",
		"jump": "🟢", "retro": "🟢",
		"shield": "🛡️", "hit": "🛡️",
		"wind": "🌬️", "atmospheric": "🌬️",
		"sine": "〰️", "basic": "〰️",
		"disco": "🕺", "tom": "🥁", "synare": "🥁",
		"cosmic": "🛸", "fx": "🌌", "ufo": "🛸", "space": "🚀",
		"moog": "🎹", "kraftwerk": "🤖", "sequencer": "🎼", "analog": "🎛️",
		"herbie": "🎺", "hancock": "🎹", "fusion": "🌟", "jazz": "🎷",
		"aphex": "🔬", "twin": "🎛️", "modular": "🔧", "experimental": "⚗️",
		"flying": "🚁", "lotus": "🪷", "sampler": "🎛️", "beats": "🥁"
	}
	
	for keyword in emoji_map.keys():
		if sound_key.to_lower().contains(keyword):
			display_name = emoji_map[keyword] + " " + display_name
			break
	
	sound_names[sound_key] = display_name

func _load_sound_parameter_file(file_path: String):
	"""Load a single sound parameter JSON file - handles both old and new JSON structures"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Could not read file: %s" % file_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ JSON parse error in %s: %s" % [file_path, json.error_string])
		return
	
	var data = json.data
	
	var sound_key: String
	var parameters: Dictionary
	var metadata: Dictionary
	
	# Handle new structure: {_metadata: {...}, parameters: {...}}
	if data.has("_metadata") and data.has("parameters"):
		metadata = data["_metadata"]
		parameters = data["parameters"]
		
		if metadata.has("sound_type"):
			sound_key = metadata["sound_type"]
		else:
			print("❌ Missing sound_type in metadata for %s" % file_path)
			return
	
	# Handle old structure: {sound_key: {_metadata: {...}, parameters: {...}}}
	else:
		var found_sound = false
		for key in data.keys():
			if not key.begins_with("_"):  # Skip metadata at root level
				var sound_data = data[key]
				if sound_data.has("parameters"):
					sound_key = key
					parameters = sound_data["parameters"]
					
					# Extract metadata if available
					if sound_data.has("_metadata"):
						metadata = sound_data["_metadata"]
					else:
						metadata = {}
					
					found_sound = true
					break
		
		if not found_sound:
			print("❌ No valid sound data found in %s" % file_path)
			return
	
	# Store the parameters
	sound_parameters[sound_key] = parameters
	
	# Create display name from metadata or sound key
	var display_name = sound_key.capitalize().replace("_", " ")
	if metadata.has("description"):
		display_name = metadata["description"]
	
	# Add emoji based on sound type
	var emoji_map = {
		"kick": "🥁", "808": "🥁", "drum": "🥁",
		"hihat": "🔥", "hat": "🔥", "606": "🔥",
		"bass": "🎵", "sub": "🎵",
		"drone": "🌌", "ambient": "🌌", "amiga": "🌌",
		"laser": "🔫", "shot": "🔫",
		"pickup": "🪙", "mario": "🪙",
		"explosion": "💥", "bomb": "💥",
		"jump": "🟢", "retro": "🟢",
		"shield": "🛡️", "hit": "🛡️",
		"wind": "🌬️", "atmospheric": "🌬️",
		"sine": "〰️", "basic": "〰️",
		"disco": "🕺", "tom": "🥁", "synare": "🥁",
		"cosmic": "🛸", "fx": "🌌", "ufo": "🛸", "space": "🚀",
		"moog": "🎹", "kraftwerk": "🤖", "sequencer": "🎼", "analog": "🎛️",
		"herbie": "🎺", "hancock": "🎹", "fusion": "🌟", "jazz": "🎷",
		"aphex": "🔬", "twin": "🎛️", "modular": "🔧", "experimental": "⚗️",
		"flying": "🚁", "lotus": "🪷", "sampler": "🎛️", "beats": "🥁"
	}
	
	for keyword in emoji_map.keys():
		if sound_key.to_lower().contains(keyword):
			display_name = emoji_map[keyword] + " " + display_name
			break
	
	sound_names[sound_key] = display_name
	
	print("📄 Loaded sound: %s -> %s" % [sound_key, display_name])

func _create_sound_type_mappings():
	"""Create mappings between sound keys and AudioSynthesizer.SoundType enum"""
	# Map sound keys to enum values
	var enum_mapping = {
		"basic_sine_wave": AudioSynthesizer.SoundType.BASIC_SINE_WAVE,
		"pickup_mario": AudioSynthesizer.SoundType.PICKUP_MARIO,
		"teleport_drone": AudioSynthesizer.SoundType.TELEPORT_DRONE,
		"lift_bass_pulse": AudioSynthesizer.SoundType.LIFT_BASS_PULSE,
		"ghost_drone": AudioSynthesizer.SoundType.GHOST_DRONE,
		"melodic_drone": AudioSynthesizer.SoundType.MELODIC_DRONE,
		"laser_shot": AudioSynthesizer.SoundType.LASER_SHOT,
		"power_up_jingle": AudioSynthesizer.SoundType.POWER_UP_JINGLE,
		"explosion": AudioSynthesizer.SoundType.EXPLOSION,
		"retro_jump": AudioSynthesizer.SoundType.RETRO_JUMP,
		"shield_hit": AudioSynthesizer.SoundType.SHIELD_HIT,
		"ambient_wind": AudioSynthesizer.SoundType.AMBIENT_WIND,
		"dark_808_kick": AudioSynthesizer.SoundType.DARK_808_KICK,
		"acid_606_hihat": AudioSynthesizer.SoundType.ACID_606_HIHAT,
		"dark_808_sub_bass": AudioSynthesizer.SoundType.DARK_808_SUB_BASS,
		"ambient_amiga_drone": AudioSynthesizer.SoundType.AMBIENT_AMIGA_DRONE,
		"moog_bass_lead": AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		"tb303_acid_bass": AudioSynthesizer.SoundType.TB303_ACID_BASS,
		"dx7_electric_piano": AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		"c64_sid_lead": AudioSynthesizer.SoundType.C64_SID_LEAD,
		"amiga_mod_sample": AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		"ppg_wave_pad": AudioSynthesizer.SoundType.PPG_WAVE_PAD,
		"tr909_kick": AudioSynthesizer.SoundType.TR909_KICK,
		"jupiter_8_strings": AudioSynthesizer.SoundType.JUPITER_8_STRINGS,
		"korg_m1_piano": AudioSynthesizer.SoundType.KORG_M1_PIANO,
		"arp_2600_lead": AudioSynthesizer.SoundType.ARP_2600_LEAD,
		"synare_3_disco_tom": AudioSynthesizer.SoundType.SYNARE_3_DISCO_TOM,
		"synare_3_cosmic_fx": AudioSynthesizer.SoundType.SYNARE_3_COSMIC_FX,
		"moog_kraftwerk_sequencer": AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER,
		"herbie_hancock_moog_fusion": AudioSynthesizer.SoundType.HERBIE_HANCOCK_MOOG_FUSION,
		"aphex_twin_modular": AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR,
		"flying_lotus_sampler": AudioSynthesizer.SoundType.FLYING_LOTUS_SAMPLER
	}
	
	# Create reverse mapping for loaded sounds
	for sound_key in sound_parameters.keys():
		if enum_mapping.has(sound_key):
			sound_type_mapping[enum_mapping[sound_key]] = sound_key
		else:
			print("⚠️ No enum mapping found for sound: %s" % sound_key)

func _load_fallback_parameters():
	"""Load basic fallback parameters if folder loading fails"""
	print("🔄 Loading fallback parameters...")
	
	sound_parameters = {
		"basic_sine_wave": {
			"duration": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
			"frequency": {"value": 440.0, "min": 20.0, "max": 2000.0, "step": 1.0},
			"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
			"fade_in_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01},
			"fade_out_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01}
		}
	}
	
	sound_names = {
		"basic_sine_wave": "Basic Sine Wave"
	}
	
	sound_type_mapping = {
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE: "basic_sine_wave"
	}

func _ready():
	print("🎛️ ModularSoundDesignerInterface initializing...")
	_load_sound_parameters_from_folder()
	_setup_audio_system()
	_initialize_interface()
	_setup_master_bus_visualization()
	_connect_signals()
	print("✅ ModularSoundDesignerInterface ready!")

func _setup_audio_system():
	"""Initialize audio components"""
	# Create audio player
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Create real-time update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # 10 updates per second
	update_timer.timeout.connect(_on_realtime_update)
	add_child(update_timer)
	update_timer.start()
	
	print("🔊 Audio system setup complete")

func _initialize_interface():
	"""Create the main interface layout"""
	# Main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)
	
	# Top controls
	var controls_container = HBoxContainer.new()
	controls_container.add_theme_constant_override("separation", 10)
	main_container.add_child(controls_container)
	
	# Sound type selection
	var sound_label = Label.new()
	sound_label.text = "Sound Type:"
	controls_container.add_child(sound_label)
	
	sound_type_option = OptionButton.new()
	sound_type_option.custom_minimum_size = Vector2(200, 30)
	controls_container.add_child(sound_type_option)
	
	# Buttons
	preview_button = Button.new()
	preview_button.text = "🔊 Preview"
	controls_container.add_child(preview_button)
	
	stop_button = Button.new()
	stop_button.text = "⏹️ Stop"
	controls_container.add_child(stop_button)
	
	# Real-time toggle
	realtime_toggle = CheckBox.new()
	realtime_toggle.text = "🔄 Real-time Updates"
	realtime_toggle.button_pressed = true
	controls_container.add_child(realtime_toggle)
	
	# Content area with splitter
	var splitter = HSplitContainer.new()
	splitter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(splitter)
	
	# Left side - Parameters
	var params_scroll = ScrollContainer.new()
	params_scroll.custom_minimum_size = Vector2(400, 300)
	params_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splitter.add_child(params_scroll)
	
	parameters_container = VBoxContainer.new()
	parameters_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	params_scroll.add_child(parameters_container)
	
	# Right side - Audio Visualization
	var viz_container = VBoxContainer.new()
	viz_container.custom_minimum_size = Vector2(400, 300)
	viz_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splitter.add_child(viz_container)
	
	# Visualization title
	var viz_title = Label.new()
	viz_title.text = "🌊 Master Bus Audio Visualization"
	viz_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viz_title.add_theme_font_size_override("font_size", 16)
	viz_container.add_child(viz_title)
	
	# Create visualization area
	var viz_panel = Panel.new()
	viz_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viz_container.add_child(viz_panel)
	
	# Add visualization component
	audio_visualization = preload("res://commons/audio/components/AudioVisualizationComponent.gd").new()
	viz_panel.add_child(audio_visualization)
	
	# Populate sound types
	_populate_sound_types()
	
	# Create initial parameter controls
	create_parameter_controls()
	
	print("🎨 Interface layout created")

func _setup_master_bus_visualization():
	"""Initialize master bus monitoring"""
	master_bus_index = AudioServer.get_bus_index("Master")
	
	if audio_visualization and audio_visualization.has_method("setup_master_bus_monitoring"):
		audio_visualization.setup_master_bus_monitoring(master_bus_index)
		print("📡 Master bus visualization connected")
	else:
		print("⚠️ Audio visualization component not ready")

func _connect_signals():
	"""Connect UI signals"""
	if sound_type_option:
		sound_type_option.item_selected.connect(_on_sound_type_changed)
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if realtime_toggle:
		realtime_toggle.toggled.connect(_on_realtime_toggled)
	
	print("🔗 Signals connected")

func _populate_sound_types():
	"""Add sound types to the dropdown in the correct order"""
	# Use the same order as AudioSynthesizer.get_all_sound_types()
	ordered_sound_types = AudioSynthesizer.get_all_sound_types()
	
	# Clear the dropdown first
	sound_type_option.clear()
	
	for sound_type in ordered_sound_types:
		var sound_key = get_sound_key_from_type(sound_type)
		if sound_key != "" and sound_names.has(sound_key):
			var display_name = sound_names[sound_key]
			sound_type_option.add_item(display_name)
			print("✅ Added to dropdown: %s" % display_name)
		else:
			# This sound type doesn't have a corresponding JSON file
			var fallback_name = AudioSynthesizer.get_sound_type_name(sound_type)
			sound_type_option.add_item(fallback_name + " (No Parameters)")
			print("⚠️ Added fallback: %s" % fallback_name)

func create_parameter_controls():
	"""Create parameter controls using the working approach from SoundDesignerInterface"""
	if not parameters_container:
		print("❌ Parameters container not ready yet")
		return
		
	# Clear existing controls
	for child in parameters_container.get_children():
		child.queue_free()
	parameter_controls.clear()
	value_labels.clear()
	
	var sound_key = get_sound_key_from_type(current_sound_type)
	var params = sound_parameters[sound_key]
	
	# Create title
	var title = Label.new()
	var display_name = "Unknown Sound"
	if sound_names.has(sound_key):
		display_name = sound_names[sound_key]
	title.text = "🎛️ Parameters for " + display_name
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parameters_container.add_child(title)
	
	# Create column container
	var columns_container = HBoxContainer.new()
	columns_container.add_theme_constant_override("separation", 15)
	columns_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters_container.add_child(columns_container)
	
	# Create 3 columns for parameters
	var column1 = VBoxContainer.new()
	var column2 = VBoxContainer.new()
	var column3 = VBoxContainer.new()
	
	column1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	column1.add_theme_constant_override("separation", 8)
	column2.add_theme_constant_override("separation", 8)
	column3.add_theme_constant_override("separation", 8)
	
	columns_container.add_child(column1)
	columns_container.add_child(column2)
	columns_container.add_child(column3)
	
	# Wait a frame for UI to update
	await get_tree().process_frame
	
	# Distribute parameters across columns
	var param_names = params.keys()
	var columns = [column1, column2, column3]
	
	for i in range(param_names.size()):
		var param_name = param_names[i]
		var param_config = params[param_name]
		var column_index = i % 3  # Distribute evenly across 3 columns
		create_parameter_control_in_column(columns[column_index], param_name, param_config)
	
	print("✅ Parameter controls created for %s" % sound_key)

func create_parameter_control_in_column(column: VBoxContainer, param_name: String, param_config: Dictionary):
	"""Create a parameter control in the specified column - Same as working version"""
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 3)
	
	# Add background to parameter group
	var param_bg = StyleBoxFlat.new()
	param_bg.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	param_bg.corner_radius_top_left = 4
	param_bg.corner_radius_top_right = 4
	param_bg.corner_radius_bottom_left = 4
	param_bg.corner_radius_bottom_right = 4
	param_bg.content_margin_left = 8
	param_bg.content_margin_right = 8
	param_bg.content_margin_top = 6
	param_bg.content_margin_bottom = 6
	main_container.add_theme_stylebox_override("panel", param_bg)
	
	column.add_child(main_container)
	
	# Header with name and value
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 2)
	main_container.add_child(header_container)
	
	# Parameter label
	var label = Label.new()
	label.text = param_name.capitalize().replace("_", " ")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.WHITE)
	header_container.add_child(label)
	
	# Value label
	var value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.CYAN)
	header_container.add_child(value_label)
	value_labels[param_name] = value_label
	
	# Control container
	var control_container = VBoxContainer.new()
	main_container.add_child(control_container)
	
	# Parameter control based on type
	if param_config.has("options"):
		create_option_control_compact(control_container, param_name, param_config)
	else:
		create_slider_control_compact(control_container, param_name, param_config)
	
	print("✅ Created compact parameter control for: %s" % param_name)

func create_slider_control_compact(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create a compact slider control - Same as working version"""
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("value", 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 20)
	
	# Style the slider
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_style.corner_radius_top_left = 3
	slider_style.corner_radius_top_right = 3
	slider_style.corner_radius_bottom_left = 3
	slider_style.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.8, 1.0, 1.0)
	grabber_style.corner_radius_top_left = 6
	grabber_style.corner_radius_top_right = 6
	grabber_style.corner_radius_bottom_left = 6
	grabber_style.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	# Connect signal - Same working approach
	slider.value_changed.connect(func(value): _on_slider_changed(param_name, value))
	print("🎛️ Created compact slider for %s (%.2f to %.2f, current: %.2f)" % [param_name, slider.min_value, slider.max_value, slider.value])
	
	container.add_child(slider)
	parameter_controls[param_name] = slider
	
	# Update value label
	update_value_label(param_name, slider.value)

func create_option_control_compact(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create a compact option control - Same as working version"""
	var option_button = OptionButton.new()
	var options = config.get("options", [])
	var current_value = config.get("value", "")
	
	option_button.custom_minimum_size = Vector2(150, 25)
	
	for option in options:
		option_button.add_item(option)
	
	# Select current value
	for i in range(option_button.get_item_count()):
		if option_button.get_item_text(i) == current_value:
			option_button.selected = i
			break
	
	option_button.item_selected.connect(func(index): _on_option_changed(param_name, index))
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(option_button)
	parameter_controls[param_name] = option_button
	
	print("🎛️ Created compact option control for %s (options: %s, current: %s)" % [param_name, options, current_value])
	
	# Update value label
	update_value_label(param_name, current_value)

# Signal handlers - Same as working version
func _on_slider_changed(param_name: String, value: float):
	print("🎛️ SLIDER MOVED: %s changed to %.2f" % [param_name, value])
	var sound_key = get_sound_key_from_type(current_sound_type)
	print("🔑 Sound key: %s" % sound_key)
	
	# Safety check before accessing nested dictionary
	if sound_parameters.has(sound_key) and sound_parameters[sound_key].has(param_name):
		if sound_parameters[sound_key][param_name] is Dictionary:
			sound_parameters[sound_key][param_name]["value"] = value
		else:
			print("⚠️ Invalid parameter structure for %s.%s" % [sound_key, param_name])
			return
	update_value_label(param_name, value)
	print("✅ Slider changed: %s = %.2f" % [param_name, value])
	
	# Force immediate audio update if real-time is enabled
	if realtime_enabled:
		print("🔄 Triggering real-time audio update...")
		needs_audio_update = false
		update_audio_immediately()
	else:
		print("⏸️ Real-time disabled, no audio update")

func _on_option_changed(param_name: String, index: int):
	print("🎚️ OPTION CHANGED: %s to index %d" % [param_name, index])
	var option_button = parameter_controls[param_name] as OptionButton
	var value = option_button.get_item_text(index)
	var sound_key = get_sound_key_from_type(current_sound_type)
	
	print("🔑 Sound key: %s" % sound_key)
	print("📝 Setting %s.%s = %s" % [sound_key, param_name, value])
	
	# Safety check before accessing nested dictionary
	if sound_parameters.has(sound_key) and sound_parameters[sound_key].has(param_name):
		if sound_parameters[sound_key][param_name] is Dictionary:
			sound_parameters[sound_key][param_name]["value"] = value
		else:
			print("⚠️ Invalid parameter structure for %s.%s" % [sound_key, param_name])
			return
	update_value_label(param_name, value)
	print("✅ Option changed: %s = %s" % [param_name, value])
	
	# Force immediate audio update if real-time is enabled
	if realtime_enabled:
		print("🔄 Real-time enabled, triggering immediate audio update...")
		needs_audio_update = false
		update_audio_immediately()
	else:
		print("⏸️ Real-time disabled, no audio update")

func _on_sound_type_changed(index: int):
	"""Handle sound type selection change"""
	if index >= 0 and index < ordered_sound_types.size():
		current_sound_type = ordered_sound_types[index]
		var sound_key = get_sound_key_from_type(current_sound_type)
		
		if sound_names.has(sound_key):
			print("🎵 Sound type changed to: %s (%s)" % [sound_names[sound_key], sound_key])
		else:
			print("🎵 Sound type changed to: %s (fallback)" % AudioSynthesizer.get_sound_type_name(current_sound_type))
		
		create_parameter_controls()

func _on_preview_pressed():
	print("🔊 Preview button pressed!")
	update_audio_immediately()

func _on_stop_pressed():
	print("⏹️ Stop button pressed!")
	if audio_player and audio_player.playing:
		audio_player.stop()
		print("🛑 Audio stopped")
	else:
		print("🔇 No audio playing")

func _on_realtime_toggled(enabled: bool):
	realtime_enabled = enabled
	print("🔄 Real-time updates: %s" % ("ENABLED" if enabled else "DISABLED"))
	if enabled:
		update_audio_immediately()
	else:
		if audio_player and audio_player.playing:
			audio_player.stop()
			print("⏹️ Audio stopped (real-time disabled)")

func _on_realtime_update():
	if needs_audio_update and realtime_enabled:
		needs_audio_update = false
		update_audio_immediately()

func update_audio_immediately():
	"""Immediately update and play audio with current parameters - Same as working version"""
	print("🎵 Immediate audio update... (Real-time: %s)" % realtime_enabled)
	
	if not audio_player:
		print("❌ Audio player not found")
		return
		
	# Stop current audio
	if audio_player.playing:
		audio_player.stop()
		print("⏸️ Stopped previous audio")
	
	var sound_key = get_sound_key_from_type(current_sound_type)
	var params = get_current_parameter_values(sound_key)
	
	print("🎛️ Using parameters for %s: %s" % [sound_key, params])
	
	# Generate new audio with current parameters - Same working approach
	var audio_stream = CustomSoundGenerator.generate_custom_sound(current_sound_type, params)
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()
		print("▶️ Real-time audio started playing (Duration: %.2fs)" % params.get("duration", 0.0))
	else:
		print("❌ Failed to generate audio stream")

func get_current_parameter_values(sound_key: String) -> Dictionary:
	"""Extract parameter values with safety checks"""
	var params = {}
	
	if not sound_parameters.has(sound_key):
		print("⚠️ No parameters found for sound key: %s" % sound_key)
		return params
	
	var sound_config = sound_parameters[sound_key]
	
	for param_name in sound_config.keys():
		var param_config = sound_config[param_name]
		
		# Defensive check for parameter structure
		if param_config is Dictionary and param_config.has("value"):
			params[param_name] = param_config["value"]
		else:
			print("⚠️ Invalid parameter structure for %s.%s: %s" % [sound_key, param_name, param_config])
			# Provide a safe default
			params[param_name] = 0.0
	
	print("📊 Current %s parameters: %s" % [sound_key, params])
	return params

func get_sound_key_from_type(sound_type: AudioSynthesizer.SoundType) -> String:
	"""Convert sound type enum to string key using dynamic mapping"""
	if sound_type_mapping.has(sound_type):
		return sound_type_mapping[sound_type]
	
	# Fallback to first available sound or basic sine wave
	if sound_parameters.size() > 0:
		return sound_parameters.keys()[0]
	
	return "basic_sine_wave"

func update_value_label(param_name: String, value):
	"""Update the value display label"""
	if value_labels.has(param_name):
		if value is String:
			value_labels[param_name].text = str(value)
		else:
			value_labels[param_name].text = "%.3f" % value
