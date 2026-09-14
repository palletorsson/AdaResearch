# GridAudioComponent.gd
# Manages ambient audio for grid-based maps
# Integrates with SoundBankSingleton and AmbientSoundController

extends Node
class_name GridAudioComponent

# References
var grid_system: Node3D
var data_component: GridDataComponent
var ambient_controller: AmbientSoundController

# Configuration
var audio_config: Dictionary = {}
var sequence_id: String = ""
var map_name: String = ""

# State
var is_initialized: bool = false
var is_playing: bool = false

# Signals
signal audio_initialized()
signal ambient_started(preset_name: String)
signal ambient_stopped()
signal audio_error(error_message: String)

func _ready():
	pass

# Initialize component with grid system and data component
func initialize(grid_sys: Node3D, data_comp: GridDataComponent):
	grid_system = grid_sys
	data_component = data_comp

	if not data_component:
		print("GridAudioComponent: WARNING - No data component provided")
		return

	# Get map name
	map_name = data_component.get_current_map_name()

	is_initialized = true
	audio_initialized.emit()

# Resolve audio configuration from hierarchy (Global â†’ Sequence â†’ Map)
func resolve_audio_config() -> Dictionary:
	"""
	Resolve audio configuration with three-level hierarchy:
	1. Global defaults from map_sequences.json
	2. Sequence-level audio config
	3. Map-level audio config (highest priority)
	"""

	var config = {}

	# Try to get sequence data from MapProgressionManager
	var sequence_data = {}
	if MapProgressionManager and "sequences" in MapProgressionManager:
		var full_sequences = MapProgressionManager.sequences
		
		# 1. Apply global audio defaults (if available in MapProgressionManager or hardcoded fallback)
		if MapProgressionManager.get("progression_config") and "audio_defaults" in MapProgressionManager.progression_config:
			config = MapProgressionManager.progression_config["audio_defaults"].duplicate(true)
			
		# 2. Apply sequence-level config
		if not sequence_id.is_empty():
			if sequence_id in full_sequences:
				var sequence = full_sequences[sequence_id]
				
				# Check for direct ambient_preset in sequence (new format)
				if "ambient_preset" in sequence:
					config["ambient_preset"] = sequence["ambient_preset"]
				
				# Check for audio object (old format)
				if "audio" in sequence:
					config.merge(sequence["audio"], true)
			else:
				print("ðŸ” Sequence '%s' not found in MapProgressionManager" % sequence_id)
	else:
		print("GridAudioComponent: WARNING - MapProgressionManager not available")
		
		# Fallback to local load (legacy)
		var sequences_data = _load_map_sequences()
		if sequences_data:
			if "audio_defaults" in sequences_data:
				config = sequences_data["audio_defaults"].duplicate(true)
			
			if not sequence_id.is_empty() and "sequences" in sequences_data and sequence_id in sequences_data["sequences"]:
				var sequence = sequences_data["sequences"][sequence_id]
				if "audio" in sequence:
					config.merge(sequence["audio"], true)

	# 3. Apply map-level config (highest priority)
	if data_component:
		var settings = data_component.get_settings()
		if "audio" in settings:
			config.merge(settings["audio"], true)

	# Store resolved config
	audio_config = config

	if audio_config.is_empty():
		print("GridAudioComponent: No audio configuration found, using silent preset")
		audio_config = {"ambient_preset": "silent"}


	return audio_config

# Load map_sequences.json
func _load_map_sequences() -> Dictionary:
	var sequences_path = "res://commons/maps/map_sequences.json"

	var file = FileAccess.open(sequences_path, FileAccess.READ)
	if not file:
		print("GridAudioComponent: Could not load map_sequences.json")
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("GridAudioComponent: JSON parse error in map_sequences.json")
		return {}

	return json.data

# Set the sequence ID for proper audio resolution
func set_sequence_id(seq_id: String):
	sequence_id = seq_id

# Start ambient audio for the current map
func start_ambient():

	if is_playing:
		return

	if not is_initialized:
		print("GridAudioComponent: ERROR - Component not initialized")
		audio_error.emit("Component not initialized")
		return

	# Check if SoundBank singleton exists
	var sound_bank = get_node_or_null("/root/SoundBank")
	if not sound_bank:
		print("GridAudioComponent: ERROR - SoundBank singleton not found!")
		print("  Please add SoundBankSingleton to AutoLoad:")
		print("  Project â†’ Project Settings â†’ AutoLoad")
		print("  Name: SoundBank")
		print("  Path: res://commons/audio/SoundBankSingleton.gd")
		audio_error.emit("SoundBank singleton not found")
		return

	# Resolve audio configuration
	resolve_audio_config()

	# Get preset and settings
	var preset = audio_config.get("ambient_preset", "silent")
	var volume = audio_config.get("volume", 0.0)
	var fade_duration = audio_config.get("crossfade_duration", 2.0)


	# Skip if silent preset
	if preset == "silent":
		print("GridAudioComponent: âš ï¸ Silent preset - no audio will play")
		print("ðŸŽµ ========================================")
		return

	# Create ambient controller if it doesn't exist
	if not ambient_controller:
		ambient_controller = AmbientSoundController.new()
		ambient_controller.name = "AmbientSoundController"
		add_child(ambient_controller)

		# Connect signals
		ambient_controller.ambient_started.connect(_on_ambient_started)
		ambient_controller.ambient_stopped.connect(_on_ambient_stopped)
		ambient_controller.random_event_triggered.connect(_on_random_event)

	# Load and start the preset
	ambient_controller.load_preset(preset, volume, fade_duration)

	is_playing = true

# Stop ambient audio
func stop_ambient():
	if not is_playing:
		return

	print("GridAudioComponent: Stopping ambient audio")

	if ambient_controller:
		ambient_controller.stop_ambient()

	is_playing = false

# Adjust volume
func set_volume(volume_db: float):
	if ambient_controller:
		ambient_controller.set_volume(volume_db)
		audio_config["volume"] = volume_db

# Crossfade to new preset
func crossfade_to_preset(new_preset: String, duration: float = 2.0):
	if not ambient_controller:
		print("GridAudioComponent: No ambient controller - cannot crossfade")
		return

	ambient_controller.crossfade_to_preset(new_preset, duration)
	audio_config["ambient_preset"] = new_preset

# Cleanup
func cleanup():
	stop_ambient()

	if ambient_controller:
		ambient_controller.queue_free()
		ambient_controller = null

# Signal handlers
func _on_ambient_started():
	var preset = audio_config.get("ambient_preset", "unknown")
	ambient_started.emit(preset)

func _on_ambient_stopped():
	ambient_stopped.emit()

func _on_random_event(_sound_id: String):
	# Optional: Log or handle random audio events
	pass

# Get audio info for debugging
func get_audio_info() -> Dictionary:
	return {
		"map_name": map_name,
		"sequence_id": sequence_id,
		"is_playing": is_playing,
		"preset": audio_config.get("ambient_preset", "none"),
		"volume": audio_config.get("volume", 0.0),
		"has_controller": ambient_controller != null,
		"controller_info": ambient_controller.get_info() if ambient_controller else {}
	}

func print_info():
	var info = get_audio_info()
	print("ðŸŽµ GRID AUDIO COMPONENT INFO ðŸŽµ")
	print("   Map: %s" % info["map_name"])
	print("   Sequence: %s" % info["sequence_id"])
	print("   Playing: %s" % info["is_playing"])
	print("   Preset: %s" % info["preset"])
	print("   Volume: %.1f dB" % info["volume"])
	print("   Has controller: %s" % info["has_controller"])
	if info["has_controller"]:
		print("   Controller layers: %d" % info["controller_info"].get("continuous_layers", 0))
		print("   Controller events: %d" % info["controller_info"].get("active_timers", 0))
