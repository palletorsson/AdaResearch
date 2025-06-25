# FileManagerComponent.gd
# Modular component for file operations
# Handles save/load presets and audio export

extends Control
class_name FileManagerComponent

@export_group("File Settings")
@export var auto_save_presets: bool = false
@export var preset_directory: String = "user://audio_presets/"
@export var export_directory: String = "user://exported_audio/"

# UI References
var save_button: Button
var load_button: Button
var export_button: Button
var copy_json_button: Button

# Current data
var current_sound_type: AudioSynthesizer.SoundType
var current_parameters: Dictionary = {}
var all_sound_parameters: Dictionary = {}

# Signals
signal preset_saved(file_path: String)
signal preset_loaded(parameters: Dictionary)
signal audio_exported(file_path: String)
signal json_ready(json_string: String)

func _ready():
	_setup_ui()
	_create_directories()

func _setup_ui():
	"""Setup the file management UI"""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(container)
	
	# Save button
	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "💾 Save Preset"
	save_button.custom_minimum_size = Vector2(120, 30)
	_style_button(save_button, Color(0.2, 0.6, 0.2, 1.0))
	save_button.pressed.connect(_on_save_pressed)
	container.add_child(save_button)
	
	# Load button
	load_button = Button.new()
	load_button.name = "LoadButton"
	load_button.text = "📂 Load Preset"
	load_button.custom_minimum_size = Vector2(120, 30)
	_style_button(load_button, Color(0.2, 0.4, 0.6, 1.0))
	load_button.pressed.connect(_on_load_pressed)
	container.add_child(load_button)
	
	# Export button
	export_button = Button.new()
	export_button.name = "ExportButton"
	export_button.text = "📤 Export Audio"
	export_button.custom_minimum_size = Vector2(130, 30)
	_style_button(export_button, Color(0.6, 0.4, 0.2, 1.0))
	export_button.pressed.connect(_on_export_pressed)
	container.add_child(export_button)
	
	# Copy JSON button
	copy_json_button = Button.new()
	copy_json_button.name = "CopyJsonButton"
	copy_json_button.text = "📋 Copy JSON"
	copy_json_button.custom_minimum_size = Vector2(100, 30)
	_style_button(copy_json_button, Color(0.4, 0.3, 0.6, 1.0))
	copy_json_button.pressed.connect(_on_copy_json_pressed)
	container.add_child(copy_json_button)

func _style_button(button: Button, color: Color):
	"""Apply consistent styling to buttons"""
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = color
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", button_style)
	
	# Hover effect
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, color.a)
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("hover", hover_style)

func _create_directories():
	"""Create necessary directories for file operations"""
	DirAccess.open("user://").make_dir_recursive(preset_directory.get_base_dir())
	DirAccess.open("user://").make_dir_recursive(export_directory.get_base_dir())

func set_current_sound_data(sound_type: AudioSynthesizer.SoundType, parameters: Dictionary):
	"""Set the current sound data for file operations"""
	current_sound_type = sound_type
	current_parameters = parameters

func set_all_sound_parameters(all_parameters: Dictionary):
	"""Set all sound parameters for complete presets"""
	all_sound_parameters = all_parameters

func _on_save_pressed():
	"""Handle save button press"""
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.json", "JSON Preset Files")
	file_dialog.current_dir = preset_directory
	file_dialog.current_file = _generate_preset_filename()
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_save_to_file)
	file_dialog.close_requested.connect(file_dialog.queue_free)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_load_pressed():
	"""Handle load button press"""
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.json", "JSON Preset Files")
	file_dialog.current_dir = preset_directory
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_load_from_file)
	file_dialog.close_requested.connect(file_dialog.queue_free)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_export_pressed():
	"""Handle export button press"""
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.tres", "Godot Resource Files")
	file_dialog.add_filter("*.wav", "WAV Audio Files")
	file_dialog.current_dir = export_directory
	file_dialog.current_file = _generate_audio_filename()
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_export_to_file)
	file_dialog.close_requested.connect(file_dialog.queue_free)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_copy_json_pressed():
	"""Handle copy JSON button press"""
	var json_string = _generate_json_string()
	_show_json_popup(json_string)
	json_ready.emit(json_string)

func _generate_preset_filename() -> String:
	"""Generate a default filename for presets"""
	var sound_name = _get_sound_name_from_type(current_sound_type)
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	return "%s_preset_%s.json" % [sound_name.to_lower().replace(" ", "_"), timestamp]

func _generate_audio_filename() -> String:
	"""Generate a default filename for audio export"""
	var sound_name = _get_sound_name_from_type(current_sound_type)
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	return "%s_audio_%s" % [sound_name.to_lower().replace(" ", "_"), timestamp]

func _save_to_file(file_path: String):
	"""Save current parameters to file"""
	var save_data = _prepare_save_data()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("FileManagerComponent: Saved preset to %s" % file_path)
		preset_saved.emit(file_path)
		
		# Auto-save to clipboard as well
		if copy_json_button:
			_show_json_popup(json_string)
	else:
		print("FileManagerComponent: Failed to save file: %s" % file_path)

func _load_from_file(file_path: String):
	"""Load parameters from file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var loaded_data = json.data
			preset_loaded.emit(loaded_data)
			print("FileManagerComponent: Loaded preset from %s" % file_path)
		else:
			print("FileManagerComponent: Failed to parse JSON from %s" % file_path)
	else:
		print("FileManagerComponent: Failed to open file: %s" % file_path)

func _export_to_file(file_path: String):
	"""Export current audio to file"""
	var extension = file_path.get_extension().to_lower()
	
	match extension:
		"tres":
			_export_to_tres(file_path)
		"wav":
			_export_to_wav(file_path)
		_:
			print("FileManagerComponent: Unsupported export format: %s" % extension)

func _export_to_tres(file_path: String):
	"""Export as Godot resource file"""
	var audio_stream = CustomSoundGenerator.generate_custom_sound(current_sound_type, current_parameters)
	if audio_stream:
		var save_result = ResourceSaver.save(audio_stream, file_path)
		if save_result == OK:
			print("FileManagerComponent: Exported audio to %s" % file_path)
			audio_exported.emit(file_path)
		else:
			print("FileManagerComponent: Failed to export audio to %s" % file_path)
	else:
		print("FileManagerComponent: Failed to generate audio stream")

func _export_to_wav(file_path: String):
	"""Export as WAV file"""
	# Note: This would require additional implementation for WAV file format
	# For now, fall back to .tres export
	var tres_path = file_path.get_basename() + ".tres"
	_export_to_tres(tres_path)
	print("FileManagerComponent: WAV export not yet implemented, saved as %s instead" % tres_path)

func _prepare_save_data() -> Dictionary:
	"""Prepare data for saving"""
	var save_data = {}
	
	if all_sound_parameters.size() > 0:
		# Save all sound parameters
		for sound_key in all_sound_parameters.keys():
			save_data[sound_key] = {}
			for param_name in all_sound_parameters[sound_key].keys():
				save_data[sound_key][param_name] = all_sound_parameters[sound_key][param_name].duplicate()
	else:
		# Save only current sound parameters
		var sound_key = _get_sound_key_from_type(current_sound_type)
		save_data[sound_key] = {}
		for param_name in current_parameters.keys():
			save_data[sound_key][param_name] = {
				"value": current_parameters[param_name],
				"min": 0.0,  # Default values
				"max": 1.0,
				"step": 0.01
			}
	
	# Add metadata
	save_data["_metadata"] = {
		"created_at": Time.get_datetime_string_from_system(),
		"sound_type": _get_sound_name_from_type(current_sound_type),
		"version": "1.0"
	}
	
	return save_data

func _generate_json_string() -> String:
	"""Generate JSON string for current parameters"""
	var save_data = _prepare_save_data()
	return JSON.stringify(save_data, "\t")

func _show_json_popup(json_string: String):
	"""Show popup with JSON for copying"""
	var popup = AcceptDialog.new()
	var sound_name = _get_sound_name_from_type(current_sound_type)
	popup.title = "📋 JSON Parameters - " + sound_name
	popup.dialog_text = "Copy the JSON for " + sound_name + " and paste it into your code:"
	
	# Create content
	var vbox = VBoxContainer.new()
	
	var instructions = Label.new()
	instructions.text = "Select all text (Ctrl+A) and copy (Ctrl+C):"
	instructions.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(instructions)
	
	var text_edit = TextEdit.new()
	text_edit.text = json_string
	text_edit.editable = true
	text_edit.custom_minimum_size = Vector2(700, 400)
	text_edit.placeholder_text = "JSON parameter structure..."
	
	# Style the text editor
	text_edit.add_theme_color_override("font_color", Color.WHITE)
	text_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.15, 1.0))
	vbox.add_child(text_edit)
	
	# Add copy hint
	var hint = Label.new()
	hint.text = "💡 Tip: This contains the current sound's parameters with your custom values!"
	hint.add_theme_color_override("font_color", Color.CYAN)
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)
	
	popup.add_child(vbox)
	add_child(popup)
	popup.popup_centered(Vector2i(750, 500))
	
	# Auto-select all text for easy copying
	text_edit.select_all()
	text_edit.grab_focus()
	
	# Clean up when closed
	popup.close_requested.connect(popup.queue_free)

func _get_sound_key_from_type(sound_type: AudioSynthesizer.SoundType) -> String:
	"""Convert sound type to key string"""
	match sound_type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			return "basic_sine_wave"
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			return "pickup_mario"
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			return "teleport_drone"
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			return "lift_bass_pulse"
		AudioSynthesizer.SoundType.GHOST_DRONE:
			return "ghost_drone"
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			return "melodic_drone"
		AudioSynthesizer.SoundType.LASER_SHOT:
			return "laser_shot"
		AudioSynthesizer.SoundType.POWER_UP_JINGLE:
			return "power_up_jingle"
		AudioSynthesizer.SoundType.EXPLOSION:
			return "explosion"
		AudioSynthesizer.SoundType.RETRO_JUMP:
			return "retro_jump"
		AudioSynthesizer.SoundType.SHIELD_HIT:
			return "shield_hit"
		AudioSynthesizer.SoundType.AMBIENT_WIND:
			return "ambient_wind"
		_:
			return "basic_sine_wave"

func _get_sound_name_from_type(sound_type: AudioSynthesizer.SoundType) -> String:
	"""Convert sound type to display name"""
	match sound_type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			return "Basic Sine Wave"
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			return "Mario Pickup"
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			return "Teleport Drone"
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			return "Bass Pulse"
		AudioSynthesizer.SoundType.GHOST_DRONE:
			return "Ghost Drone"
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			return "Melodic Drone"
		AudioSynthesizer.SoundType.LASER_SHOT:
			return "Laser Shot"
		AudioSynthesizer.SoundType.POWER_UP_JINGLE:
			return "Power-Up Jingle"
		AudioSynthesizer.SoundType.EXPLOSION:
			return "Explosion"
		AudioSynthesizer.SoundType.RETRO_JUMP:
			return "Retro Jump"
		AudioSynthesizer.SoundType.SHIELD_HIT:
			return "Shield Hit"
		AudioSynthesizer.SoundType.AMBIENT_WIND:
			return "Ambient Wind"
		_:
			return "Unknown Sound"

# Quick save/load functions
func quick_save(slot_name: String = "default"):
	"""Quick save to a named slot"""
	var file_path = preset_directory + "quick_save_%s.json" % slot_name
	_save_to_file(file_path)

func quick_load(slot_name: String = "default"):
	"""Quick load from a named slot"""
	var file_path = preset_directory + "quick_save_%s.json" % slot_name
	if FileAccess.file_exists(file_path):
		_load_from_file(file_path)
	else:
		print("FileManagerComponent: Quick save slot '%s' not found" % slot_name)

func get_available_presets() -> Array[String]:
	"""Get list of available preset files"""
	var presets: Array[String] = []
	var dir = DirAccess.open(preset_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				presets.append(file_name)
			file_name = dir.get_next()
	return presets

func delete_preset(preset_name: String):
	"""Delete a preset file"""
	var file_path = preset_directory + preset_name
	if FileAccess.file_exists(file_path):
		DirAccess.open("user://").remove(file_path)
		print("FileManagerComponent: Deleted preset %s" % preset_name) 