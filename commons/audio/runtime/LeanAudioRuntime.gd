# LeanAudioRuntime.gd
# Minimal audio runtime for game - loads sounds from JSON configurations
# Designed to work with external audio development tools

extends RefCounted
class_name LeanAudioRuntime

# Audio configuration constants
const SAMPLE_RATE = 44100
const CHANNELS = 1

# Simplified sound type enum - only game-essential sounds
enum GameSoundType {
	PICKUP,           # Item collection
	TELEPORT,         # Portal/teleport effects
	AMBIENT_DRONE,    # Background ambience
	UI_CLICK,         # Interface sounds
	POWER_UP,         # Achievement sounds
	IMPACT,           # Collision/hit sounds
	NOTIFICATION      # Alert/notification sounds
}

# JSON parameter cache
static var sound_parameters: Dictionary = {}
static var sound_cache: Dictionary = {}
static var is_initialized: bool = false

# Initialize the audio runtime
static func initialize():
	if is_initialized:
		return
		
	print("🎵 LeanAudioRuntime: Initializing...")
	_load_sound_configurations()
	is_initialized = true
	print("✅ LeanAudioRuntime: Ready")

# Load sound configurations from JSON files
static func _load_sound_configurations():
	var json_directory = "res://commons/audio/parameters/basic/"
	var config_files = [
		"pickup_mario.json",
		"teleport_drone.json", 
		"ghost_drone.json",
		"power_up_jingle.json",
		"shield_hit.json",
		"basic_sine_wave.json"  # fallback
	]
	
	for config_file in config_files:
		var file_path = json_directory + config_file
		var sound_config = _load_json_config(file_path)
		if sound_config:
			var sound_key = config_file.get_basename()
			sound_parameters[sound_key] = sound_config
			print("📄 Loaded config: %s" % sound_key)

# Load a single JSON configuration file
static func _load_json_config(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("⚠️ Config file not found: %s" % file_path)
		return {}
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Cannot open config file: %s" % file_path)
		return {}
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ JSON parse error in %s: %s" % [file_path, json.error_string])
		return {}
	
	var data = json.data
	
	# Handle both single sound and metadata + parameters structure
	if data.has("parameters"):
		return data["parameters"]  # New format with metadata
	else:
		return data  # Direct parameters format

# Generate a game sound using JSON parameters
static func generate_game_sound(sound_type: GameSoundType, custom_params: Dictionary = {}) -> AudioStreamWAV:
	if not is_initialized:
		initialize()
	
	var sound_key = _get_sound_key(sound_type)
	var base_params = sound_parameters.get(sound_key, {})
	
	# Merge custom parameters with base parameters
	var final_params = _merge_parameters(base_params, custom_params)
	
	# Generate the audio
	return _generate_audio_from_params(sound_key, final_params)

# Convert game sound type to configuration key
static func _get_sound_key(sound_type: GameSoundType) -> String:
	match sound_type:
		GameSoundType.PICKUP:
			return "pickup_mario"
		GameSoundType.TELEPORT:
			return "teleport_drone"
		GameSoundType.AMBIENT_DRONE:
			return "ghost_drone"
		GameSoundType.UI_CLICK:
			return "basic_sine_wave"
		GameSoundType.POWER_UP:
			return "power_up_jingle"
		GameSoundType.IMPACT:
			return "shield_hit"
		GameSoundType.NOTIFICATION:
			return "basic_sine_wave"
		_:
			return "basic_sine_wave"

# Merge custom parameters with base parameters
static func _merge_parameters(base_params: Dictionary, custom_params: Dictionary) -> Dictionary:
	var result = {}
	
	# Start with base parameters (extract values from parameter definitions)
	for param_name in base_params.keys():
		var param_config = base_params[param_name]
		if param_config is Dictionary and param_config.has("value"):
			result[param_name] = param_config["value"]
		else:
			result[param_name] = param_config
	
	# Override with custom parameters
	for param_name in custom_params.keys():
		result[param_name] = custom_params[param_name]
	
	return result

# Generate audio from processed parameters
static func _generate_audio_from_params(sound_key: String, params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 1.0)
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	# Route to appropriate generation function
	match sound_key:
		"pickup_mario":
			_generate_pickup_sound(data, sample_count, params)
		"teleport_drone":
			_generate_teleport_drone(data, sample_count, params)
		"ghost_drone":
			_generate_ghost_drone(data, sample_count, params)
		"power_up_jingle":
			_generate_power_up_jingle(data, sample_count, params)
		"shield_hit":
			_generate_shield_hit(data, sample_count, params)
		"basic_sine_wave":
			_generate_basic_sine_wave(data, sample_count, params)
		_:
			_generate_basic_sine_wave(data, sample_count, params)
	
	return _create_audio_stream(data)

# Simplified generation functions (core game sounds only)
static func _generate_pickup_sound(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var start_freq = params.get("start_freq", 440.0)
	var end_freq = params.get("end_freq", 880.0)
	var decay_rate = params.get("decay_rate", 8.0)
	var amplitude = params.get("amplitude", 0.3)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var freq = start_freq + (end_freq - start_freq) * progress
		var envelope = exp(-progress * decay_rate)
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0  # Square wave
		data[i] = wave * envelope * amplitude

static func _generate_teleport_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var base_freq = params.get("base_freq", 220.0)
	var mod_freq = params.get("mod_freq", 0.5)
	var mod_depth = params.get("mod_depth", 30.0)
	var amplitude = params.get("amplitude", 0.2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var modulation = sin(2.0 * PI * mod_freq * t) * mod_depth
		var freq = base_freq + modulation
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0  # Sawtooth
		data[i] = wave * amplitude

static func _generate_ghost_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var freq1 = params.get("freq1", 110.0)
	var freq2 = params.get("freq2", 165.0)
	var freq3 = params.get("freq3", 220.0)
	var amp1 = params.get("amplitude1", 0.4)
	var amp2 = params.get("amplitude2", 0.3)
	var amp3 = params.get("amplitude3", 0.2)
	var overall_amp = params.get("overall_amplitude", 0.15)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var wave = sin(2.0 * PI * freq1 * t) * amp1
		wave += sin(2.0 * PI * freq2 * t) * amp2
		wave += sin(2.0 * PI * freq3 * t) * amp3
		data[i] = wave * overall_amp

static func _generate_power_up_jingle(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var root_note = params.get("root_note", 262.0)
	var note_count = params.get("note_count", 4)
	var note_decay = params.get("note_decay", 3.0)
	var amplitude = params.get("amplitude", 0.3)
	
	var duration = float(sample_count) / SAMPLE_RATE
	var note_duration = duration / note_count
	var intervals = [0, 4, 7, 12]  # Major chord intervals
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_index = clamp(int(t / note_duration), 0, note_count - 1)
		var note_t = fmod(t, note_duration) / note_duration
		
		var semitone_offset = intervals[note_index]
		var freq = root_note * pow(2.0, semitone_offset / 12.0)
		var envelope = exp(-note_t * note_decay) * sin(PI * note_t)
		var wave = sin(2.0 * PI * freq * t)
		
		data[i] = wave * envelope * amplitude

static func _generate_shield_hit(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var main_freq = params.get("main_freq", 800.0)
	var decay_rate = params.get("decay_rate", 6.0)
	var amplitude = params.get("amplitude", 0.3)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var envelope = exp(-progress * decay_rate)
		var wave = sin(2.0 * PI * main_freq * t) * sin(2.0 * PI * 60.0 * t)  # Ring modulation
		data[i] = wave * envelope * amplitude

static func _generate_basic_sine_wave(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	var frequency = params.get("frequency", 440.0)
	var amplitude = params.get("amplitude", 0.3)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		data[i] = amplitude * sin(2.0 * PI * frequency * t)

# Create audio stream from PCM data
static func _create_audio_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var byte_array = PackedByteArray()
	byte_array.resize(data.size() * 2)
	
	for i in range(data.size()):
		var sample = int(clamp(data[i], -1.0, 1.0) * 32767.0)
		var byte_index = i * 2
		byte_array[byte_index] = sample & 0xFF
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF
	
	stream.data = byte_array
	return stream

# Convenience functions for game integration
static func play_pickup_sound(custom_params: Dictionary = {}) -> AudioStreamWAV:
	return generate_game_sound(GameSoundType.PICKUP, custom_params)

static func play_teleport_sound(custom_params: Dictionary = {}) -> AudioStreamWAV:
	return generate_game_sound(GameSoundType.TELEPORT, custom_params)

static func play_ambient_drone(custom_params: Dictionary = {}) -> AudioStreamWAV:
	return generate_game_sound(GameSoundType.AMBIENT_DRONE, custom_params)

static func play_ui_click(custom_params: Dictionary = {}) -> AudioStreamWAV:
	return generate_game_sound(GameSoundType.UI_CLICK, custom_params) 