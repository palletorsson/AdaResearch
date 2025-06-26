# CubeAudioPlayer.gd
# Chapter: Audio - Modular Audio Component for Cubes
# Handles sound playback with automatic loading and caching

extends Node3D
class_name CubeAudioPlayer

# Audio configuration
@export_group("Audio Settings")
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var max_distance: float = 10.0
@export var auto_play_on_ready: bool = false

# Sound type selection - Updated import path
@export_group("Sound Selection")
@export var primary_sound: AudioSynthesizer.SoundType = AudioSynthesizer.SoundType.PICKUP_MARIO
@export var secondary_sound: AudioSynthesizer.SoundType = AudioSynthesizer.SoundType.TELEPORT_DRONE

# Audio players
var audio_player_3d: AudioStreamPlayer3D
var audio_player_2d: AudioStreamPlayer  # For UI sounds

# Sound cache
static var sound_cache: Dictionary = {}

# Signals
signal sound_started(sound_type: AudioSynthesizer.SoundType)
signal sound_finished(sound_type: AudioSynthesizer.SoundType)

func _ready():
	_setup_audio_players()
	_load_sounds()
	
	if auto_play_on_ready:
		play_primary_sound()
	
	print("CubeAudioPlayer: Ready with sounds loaded")

func _setup_audio_players():
	# Create 3D audio player for spatial sounds
	audio_player_3d = AudioStreamPlayer3D.new()
	audio_player_3d.name = "AudioPlayer3D"
	audio_player_3d.volume_db = volume_db
	audio_player_3d.pitch_scale = pitch_scale
	audio_player_3d.max_distance = max_distance
	audio_player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	
	# VR-specific audio settings
	var xr_interface = XRServer.get_primary_interface()
	if xr_interface and xr_interface.is_initialized():
		print("CubeAudioPlayer: Configuring for VR audio")
		audio_player_3d.volume_db = volume_db + 6.0  # Louder for VR
		audio_player_3d.max_distance = max_distance * 2.0  # Larger range for VR
		# Use logarithmic attenuation for better VR experience
		audio_player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	
	add_child(audio_player_3d)
	
	# Create 2D audio player for non-spatial sounds
	audio_player_2d = AudioStreamPlayer.new()
	audio_player_2d.name = "AudioPlayer2D"
	audio_player_2d.volume_db = volume_db - 3.0  # Less reduction in VR
	audio_player_2d.pitch_scale = pitch_scale
	audio_player_2d.bus = "Master"  # Force to Master bus
	add_child(audio_player_2d)
	
	# Connect signals
	audio_player_3d.finished.connect(_on_audio_finished)
	audio_player_2d.finished.connect(_on_audio_finished)

func _load_sounds():
	# Load sounds from cache or generate if needed
	_ensure_sound_cached(primary_sound)
	_ensure_sound_cached(secondary_sound)

func _ensure_sound_cached(sound_type: AudioSynthesizer.SoundType):
	# Check if sound is already cached
	if sound_cache.has(sound_type):
		return
	
	# Check if we're in VR mode
	var xr_interface = XRServer.get_primary_interface()
	var is_vr = xr_interface and xr_interface.is_initialized()
	
	# Try to load from disk first
	var sound_name = _get_sound_filename(sound_type)
	var file_path = "res://commons/audio/" + sound_name + ".tres"
	
	print("CubeAudioPlayer: Checking for %s at %s (VR: %s)" % [sound_name, file_path, is_vr])
	
	if ResourceLoader.exists(file_path):
		var loaded_sound = load(file_path)
		if loaded_sound:
			sound_cache[sound_type] = loaded_sound
			print("CubeAudioPlayer: ✅ Loaded %s from disk successfully" % sound_name)
		else:
			print("CubeAudioPlayer: ❌ Failed to load %s from disk" % sound_name)
			_generate_fallback_sound(sound_type, sound_name)
	else:
		print("CubeAudioPlayer: ❌ File not found: %s" % file_path)
		_generate_fallback_sound(sound_type, sound_name)

func _generate_fallback_sound(sound_type: AudioSynthesizer.SoundType, sound_name: String):
	# Generate sound if not found
	var duration = _get_sound_duration(sound_type)
	sound_cache[sound_type] = AudioSynthesizer.generate_sound(sound_type, duration)
	print("CubeAudioPlayer: Generated %s dynamically" % sound_name)

func _get_sound_filename(sound_type: AudioSynthesizer.SoundType) -> String:
	match sound_type:
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
		_:
			return "unknown"

func _get_sound_duration(sound_type: AudioSynthesizer.SoundType) -> float:
	match sound_type:
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			return 0.5
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			return 10.0
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			return 2.0
		AudioSynthesizer.SoundType.GHOST_DRONE:
			return 4.0
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			return 5.0
		_:
			return 1.0

# Public interface
func play_primary_sound(spatial: bool = true):
	_play_sound(primary_sound, spatial)

func play_secondary_sound(spatial: bool = true):
	_play_sound(secondary_sound, spatial)

func play_sound_type(sound_type: AudioSynthesizer.SoundType, spatial: bool = true):
	_ensure_sound_cached(sound_type)
	_play_sound(sound_type, spatial)

func _play_sound(sound_type: AudioSynthesizer.SoundType, spatial: bool):
	if not sound_cache.has(sound_type):
		print("CubeAudioPlayer: Sound not cached: %s" % sound_type)
		return
	
	var player = audio_player_3d if spatial else audio_player_2d
	var stream = sound_cache[sound_type]
	player.stream = stream
	
	# Check if we're in VR and add extra debugging
	var xr_interface = XRServer.get_primary_interface()
	var is_vr = xr_interface and xr_interface.is_initialized()
	
	if is_vr:
		print("CubeAudioPlayer: VR Mode - Audio Player Volume: %s dB, Bus: %s" % [player.volume_db, player.bus])
		
		# Check audio server state in VR
		var master_bus = AudioServer.get_bus_index("Master")
		var master_volume = AudioServer.get_bus_volume_db(master_bus)
		print("CubeAudioPlayer: VR Audio Server Master: %s dB" % master_volume)
	
	# Debug looping info
	if stream is AudioStreamWAV:
		print("CubeAudioPlayer: Stream loop mode: %s, data size: %s" % [stream.loop_mode, stream.data.size()])
	
	player.play()
	
	# Give VR a moment to process then check if actually playing
	if is_vr:
		await get_tree().create_timer(0.2).timeout
		print("CubeAudioPlayer: VR Audio Status - Playing: %s, Position: %s" % [player.playing, player.get_playback_position()])
	
	sound_started.emit(sound_type)
	print("CubeAudioPlayer: Playing %s (%s)" % [_get_sound_filename(sound_type), "3D" if spatial else "2D"])

func stop_all_sounds():
	audio_player_3d.stop()
	audio_player_2d.stop()

func is_playing() -> bool:
	return audio_player_3d.playing or audio_player_2d.playing

# Configuration methods
func set_volume(new_volume_db: float):
	volume_db = new_volume_db
	audio_player_3d.volume_db = volume_db
	audio_player_2d.volume_db = volume_db - 6.0

func set_pitch(new_pitch: float):
	pitch_scale = new_pitch
	audio_player_3d.pitch_scale = pitch_scale
	audio_player_2d.pitch_scale = pitch_scale

func set_max_distance(distance: float):
	max_distance = distance
	audio_player_3d.max_distance = max_distance

# Signal handlers
func _on_audio_finished():
	# Determine which sound finished based on current stream
	var finished_type = primary_sound  # Default
	
	if audio_player_3d.stream and sound_cache.has(primary_sound):
		if audio_player_3d.stream == sound_cache[primary_sound]:
			finished_type = primary_sound
		elif audio_player_3d.stream == sound_cache[secondary_sound]:
			finished_type = secondary_sound
	
	sound_finished.emit(finished_type)

# Static utility for generating all sounds
static func generate_all_sounds_to_disk():
	"""Call this once to generate all sounds and save them"""
	AudioSynthesizer.generate_and_save_all_sounds()
