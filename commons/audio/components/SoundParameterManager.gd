# SoundParameterManager.gd
# Manages loading and saving sound parameters from individual JSON files
# Each sound type gets its own file for better organization

extends RefCounted
class_name SoundParameterManager

@export var parameters_directory: String = "res://commons/audio/sound_parameters/"
@export var user_parameters_directory: String = "user://sound_parameters/"

# Cache for loaded parameters
static var parameter_cache: Dictionary = {}
static var is_initialized: bool = false

# Sound type mappings
static var sound_type_files = {
	"basic_sine_wave": "basic_sine_wave.json",
	"pickup_mario": "pickup_mario.json", 
	"teleport_drone": "teleport_drone.json",
	"lift_bass_pulse": "lift_bass_pulse.json",
	"ghost_drone": "ghost_drone.json",
	"melodic_drone": "melodic_drone.json",
	"laser_shot": "laser_shot.json",
	"power_up_jingle": "power_up_jingle.json",
	"explosion": "explosion.json",
	"retro_jump": "retro_jump.json",
	"shield_hit": "shield_hit.json",
	"ambient_wind": "ambient_wind.json"
}

# Default parameters as fallback
static var default_parameters = {
	"basic_sine_wave": {
		"duration": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"frequency": {"value": 440.0, "min": 20.0, "max": 2000.0, "step": 1.0},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_in_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_out_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"pickup_mario": {
		"duration": {"value": 0.5, "min": 0.1, "max": 3.0, "step": 0.01},
		"start_freq": {"value": 440.0, "min": 100.0, "max": 1000.0, "step": 5.0},
		"end_freq": {"value": 880.0, "min": 200.0, "max": 2000.0, "step": 5.0},
		"decay_rate": {"value": 8.0, "min": 1.0, "max": 20.0, "step": 0.1},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "square", "options": ["sine", "square", "sawtooth"]}
	},
	"teleport_drone": {
		"duration": {"value": 3.0, "min": 1.0, "max": 10.0, "step": 0.1},
		"base_freq": {"value": 220.0, "min": 50.0, "max": 500.0, "step": 5.0},
		"mod_freq": {"value": 0.5, "min": 0.1, "max": 5.0, "step": 0.1},
		"mod_depth": {"value": 30.0, "min": 0.0, "max": 100.0, "step": 1.0},
		"noise_amount": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_in_time": {"value": 0.05, "min": 0.0, "max": 0.5, "step": 0.01},
		"fade_out_time": {"value": 0.08, "min": 0.0, "max": 0.5, "step": 0.01},
		"wave_type": {"value": "sawtooth", "options": ["sine", "square", "sawtooth"]}
	},
	"lift_bass_pulse": {
		"duration": {"value": 2.0, "min": 0.5, "max": 5.0, "step": 0.1},
		"base_freq": {"value": 120.0, "min": 60.0, "max": 200.0, "step": 1.0},
		"pulse_rate": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"decay_rate": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"amplitude": {"value": 0.6, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "sine", "options": ["sine", "square", "sawtooth"]}
	},
	"ghost_drone": {
		"duration": {"value": 4.0, "min": 2.0, "max": 10.0, "step": 0.1},
		"freq1": {"value": 110.0, "min": 50.0, "max": 300.0, "step": 5.0},
		"freq2": {"value": 165.0, "min": 80.0, "max": 400.0, "step": 5.0},
		"freq3": {"value": 220.0, "min": 100.0, "max": 500.0, "step": 5.0},
		"mod_cycles": {"value": 2.0, "min": 0.5, "max": 8.0, "step": 0.1},
		"amplitude1": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude2": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude3": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"overall_amplitude": {"value": 0.35, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"melodic_drone": {
		"duration": {"value": 5.0, "min": 2.0, "max": 10.0, "step": 0.1},
		"fundamental": {"value": 220.0, "min": 100.0, "max": 500.0, "step": 5.0},
		"tremolo_rate": {"value": 4.0, "min": 0.5, "max": 15.0, "step": 0.1},
		"tremolo_depth": {"value": 0.1, "min": 0.0, "max": 0.5, "step": 0.01},
		"harmonic1_mult": {"value": 1.0, "min": 0.5, "max": 3.0, "step": 0.1},
		"harmonic2_mult": {"value": 1.5, "min": 0.5, "max": 3.0, "step": 0.1},
		"harmonic3_mult": {"value": 2.0, "min": 0.5, "max": 4.0, "step": 0.1},
		"harmonic4_mult": {"value": 3.0, "min": 0.5, "max": 5.0, "step": 0.1},
		"harmonic1_amp": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic2_amp": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic3_amp": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic4_amp": {"value": 0.1, "min": 0.0, "max": 1.0, "step": 0.01},
		"overall_amplitude": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01}
	}
}

func _init(params_dir: String = "", user_dir: String = ""):
	if params_dir != "":
		parameters_directory = params_dir
	if user_dir != "":
		user_parameters_directory = user_dir

static func initialize():
	"""Initialize the parameter manager and create directories"""
	if is_initialized:
		return
	
	# Create user directory for custom parameters
	DirAccess.open("user://").make_dir_recursive("sound_parameters")
	
	is_initialized = true
	print("SoundParameterManager: Initialized")

static func get_sound_parameters(sound_key: String) -> Dictionary:
	"""Get parameters for a specific sound type"""
	initialize()
	
	# Check cache first
	if parameter_cache.has(sound_key):
		return parameter_cache[sound_key]
	
	# Try to load from user directory first, then resource directory
	var parameters = _load_sound_parameters(sound_key)
	
	# Cache the loaded parameters
	parameter_cache[sound_key] = parameters
	
	return parameters

static func _load_sound_parameters(sound_key: String) -> Dictionary:
	"""Load parameters from JSON file with fallback to defaults"""
	var filename = sound_type_files.get(sound_key, sound_key + ".json")
	
	# Try user directory first
	var user_path = "user://sound_parameters/" + filename
	var params = _load_json_file(user_path)
	
	if not params.is_empty():
		print("SoundParameterManager: Loaded user parameters for %s" % sound_key)
		return params
	
	# Try resource directory
	var resource_path = "res://commons/audio/sound_parameters/" + filename
	params = _load_json_file(resource_path)
	
	if not params.is_empty():
		print("SoundParameterManager: Loaded default parameters for %s" % sound_key)
		return params
	
	# Fall back to built-in defaults
	if default_parameters.has(sound_key):
		print("SoundParameterManager: Using built-in defaults for %s" % sound_key)
		return default_parameters[sound_key]
	
	print("SoundParameterManager: No parameters found for %s, using basic sine wave" % sound_key)
	return default_parameters["basic_sine_wave"]

static func _load_json_file(file_path: String) -> Dictionary:
	"""Load and parse a JSON file"""
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("SoundParameterManager: Could not open file: %s" % file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("SoundParameterManager: JSON parse error in %s: %s" % [file_path, json.get_error_message()])
		return {}
	
	var json_data = json.data
	
	# If the JSON has a "parameters" key, return just the parameters
	if json_data is Dictionary and json_data.has("parameters"):
		return json_data["parameters"]
	
	# Otherwise return the whole structure (for backward compatibility)
	return json_data

static func save_sound_parameters(sound_key: String, parameters: Dictionary):
	"""Save parameters to user directory as individual JSON file"""
	initialize()
	
	var filename = sound_type_files.get(sound_key, sound_key + ".json")
	var file_path = "user://sound_parameters/" + filename
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("SoundParameterManager: Could not create file: %s" % file_path)
		return
	
	# Add metadata
	var save_data = {
		"_metadata": {
			"sound_type": sound_key,
			"created_at": Time.get_datetime_string_from_system(),
			"version": "1.0"
		},
		"parameters": parameters
	}
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	# Update cache
	parameter_cache[sound_key] = parameters
	
	print("SoundParameterManager: Saved parameters for %s to %s" % [sound_key, file_path])

static func get_all_sound_parameters() -> Dictionary:
	"""Get parameters for all sound types"""
	initialize()
	
	var all_params = {}
	for sound_key in sound_type_files.keys():
		all_params[sound_key] = get_sound_parameters(sound_key)
	
	return all_params

static func create_default_parameter_files():
	"""Create default parameter files in the resource directory"""
	var base_path = "res://commons/audio/sound_parameters/"
	
	for sound_key in default_parameters.keys():
		var filename = sound_type_files.get(sound_key, sound_key + ".json")
		var file_path = base_path + filename
		
		# Don't overwrite existing files
		if FileAccess.file_exists(file_path):
			continue
		
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if not file:
			print("SoundParameterManager: Could not create default file: %s" % file_path)
			continue
		
		var save_data = {
			"_metadata": {
				"sound_type": sound_key,
				"description": _get_sound_description(sound_key),
				"created_at": Time.get_datetime_string_from_system(),
				"version": "1.0",
				"is_default": true
			},
			"parameters": default_parameters[sound_key]
		}
		
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		
		print("SoundParameterManager: Created default file: %s" % file_path)

static func _get_sound_description(sound_key: String) -> String:
	"""Get a description for each sound type"""
	var descriptions = {
		"basic_sine_wave": "Pure sine wave with fundamental frequency control",
		"pickup_mario": "Classic video game pickup sound with frequency sweep",
		"teleport_drone": "Sci-fi teleportation sound with modulation and noise",
		"lift_bass_pulse": "Mechanical bass pulse for elevators and machinery",
		"ghost_drone": "Atmospheric drone with multiple harmonic layers",
		"melodic_drone": "Complex harmonic drone with tremolo modulation",
		"laser_shot": "Sci-fi laser weapon sound with frequency decay",
		"power_up_jingle": "Uplifting musical power-up sound",
		"explosion": "Multi-layered explosion with low/mid/high frequency components",
		"retro_jump": "8-bit style jump sound with duty cycle modulation",
		"shield_hit": "Impact sound with metallic ring characteristics",
		"ambient_wind": "Natural wind ambience with filtered noise"
	}
	return descriptions.get(sound_key, "Custom sound parameters")

static func get_available_sound_types() -> Array[String]:
	"""Get list of all available sound types"""
	var keys = sound_type_files.keys()
	var string_array: Array[String] = []
	for key in keys:
		string_array.append(key)
	return string_array

static func reload_parameters(sound_key: String = ""):
	"""Reload parameters from files (clears cache)"""
	if sound_key == "":
		parameter_cache.clear()
		print("SoundParameterManager: Cleared all parameter cache")
	else:
		parameter_cache.erase(sound_key)
		print("SoundParameterManager: Cleared cache for %s" % sound_key)

static func get_parameter_file_path(sound_key: String, user_directory: bool = true) -> String:
	"""Get the file path for a sound type's parameters"""
	var filename = sound_type_files.get(sound_key, sound_key + ".json")
	if user_directory:
		return "user://sound_parameters/" + filename
	else:
		return "res://commons/audio/sound_parameters/" + filename

static func export_all_parameters_to_directory(export_path: String):
	"""Export all current parameters to a directory"""
	DirAccess.open("user://").make_dir_recursive(export_path.get_base_dir())
	
	for sound_key in sound_type_files.keys():
		var params = get_sound_parameters(sound_key)
		var filename = sound_type_files[sound_key]
		var file_path = export_path + "/" + filename
		
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			var save_data = {
				"_metadata": {
					"sound_type": sound_key,
					"description": _get_sound_description(sound_key),
					"exported_at": Time.get_datetime_string_from_system(),
					"version": "1.0"
				},
				"parameters": params
			}
			file.store_string(JSON.stringify(save_data, "\t"))
			file.close()
	
	print("SoundParameterManager: Exported all parameters to %s" % export_path) 
