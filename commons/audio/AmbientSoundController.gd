extends Node
class_name AmbientSoundController

# AmbientSoundController - Per-map ambient sound management
# This node manages ambient sound playback for a specific map based on presets

# Signals
signal ambient_started()
signal ambient_stopped()
signal random_event_triggered(sound_id: String)

# Configuration
var preset_name: String = "silent"
var volume_adjustment: float = 0.0  # Additional volume adjustment
var crossfade_duration: float = 2.0

# Audio players
var continuous_players: Array[AudioStreamPlayer] = []
var event_players: Array[AudioStreamPlayer] = []
var num_event_players: int = 8

# Random event system
var random_event_timers: Array[Timer] = []
var is_playing: bool = false

# Reference to SoundBank
var sound_bank: Node = null

func _ready():
	# Get reference to SoundBankSingleton
	sound_bank = get_node_or_null("/root/SoundBank")
	if not sound_bank:
		print("⚠️ AmbientSoundController: SoundBank singleton not found!")
		return

	# Create event players
	_create_event_players()
	
	# Connect to global ambient change request
	if sound_bank.has_signal("request_ambient_change"):
		sound_bank.request_ambient_change.connect(_on_global_ambient_request)

func _on_global_ambient_request(new_preset: String):
	print("AmbientSoundController: Received global request for: ", new_preset)
	# Only switch if different
	if new_preset != preset_name:
		crossfade_to_preset(new_preset)

func _exit_tree():
	# Clean up
	stop_ambient()
	_cleanup_players()
	_cleanup_timers()

# ===== PUBLIC API =====

func load_preset(preset_id: String, volume: float = 0.0, fade_duration: float = 2.0):
	"""Load and start playing an ambient preset"""

	preset_name = preset_id
	volume_adjustment = volume
	crossfade_duration = fade_duration

	# Stop current ambient if playing
	if is_playing:
		stop_ambient()

	# Setup buses for the preset
	sound_bank.setup_buses_for_preset(preset_name)

	# Pre-generate sounds for this preset
	sound_bank.pregenerate_preset_sounds(preset_name)

	# Start the ambient
	call_deferred("start_ambient")

func start_ambient():
	"""Start playing the ambient preset"""

	if is_playing:
		return

	var preset = sound_bank.get_preset(preset_name)
	if preset.is_empty():
		print("⚠️ AmbientSoundController: Preset not found: ", preset_name)
		return

	print("🎵 Starting ambient preset: ", preset_name)

	# Start continuous layers
	_start_continuous_layers(preset)

	# Start random event system
	_start_random_events(preset)

	is_playing = true
	ambient_started.emit()

func stop_ambient():
	"""Stop all ambient sounds"""

	if not is_playing:
		return

	print("⏹️ Stopping ambient preset: ", preset_name)

	# Stop all continuous players
	for player in continuous_players:
		if player and is_instance_valid(player):
			player.stop()

	# Stop all event players
	for player in event_players:
		if player and is_instance_valid(player):
			player.stop()

	# Stop and clear all timers
	for timer in random_event_timers:
		if timer and is_instance_valid(timer):
			timer.stop()

	_cleanup_players()
	_cleanup_timers()

	is_playing = false
	ambient_stopped.emit()

func set_volume(volume_db: float):
	"""Adjust the volume of all ambient sounds"""

	volume_adjustment = volume_db

	# Update all continuous players
	for player in continuous_players:
		if player and is_instance_valid(player):
			# Apply relative volume adjustment
			player.volume_db += volume_db

	# Update all event players
	for player in event_players:
		if player and is_instance_valid(player):
			player.volume_db += volume_db

func crossfade_to_preset(new_preset: String, duration: float = 2.0):
	"""Crossfade from current preset to a new one"""

	# TODO: Implement proper crossfading
	# For now, just stop and start
	stop_ambient()
	await get_tree().create_timer(0.1).timeout
	load_preset(new_preset, volume_adjustment, duration)

# ===== INTERNAL METHODS =====

func _create_event_players():
	"""Create a pool of audio players for random events"""

	for i in range(num_event_players):
		var player = AudioStreamPlayer.new()
		player.name = "EventPlayer_%d" % i
		player.volume_db = -15
		add_child(player)
		event_players.append(player)

func _start_continuous_layers(preset: Dictionary):
	"""Start continuous ambient layers"""

	if not "continuous_layers" in preset:
		return

	for layer_config in preset["continuous_layers"]:
		var player = _create_continuous_player(layer_config)
		if player:
			continuous_players.append(player)

func _create_continuous_player(config: Dictionary) -> AudioStreamPlayer:
	"""Create and configure a continuous layer player"""

	if not "sound_id" in config:
		return null

	var sound_id = config["sound_id"]
	var params = config.get("parameters", {})

	# Get sound from bank (with parameters if applicable)
	var stream = null
	if params.is_empty():
		stream = sound_bank.get_sound(sound_id)
	else:
		# For parametric sounds, we need to pass parameters
		# TODO: Implement parameter passing to sound bank
		stream = sound_bank.get_sound(sound_id)

	# Create player (even if stream is missing initially)
	var player = AudioStreamPlayer.new()
	player.name = "ContinuousLayer_%s" % sound_id.replace(".", "_")
	player.volume_db = config.get("volume_db", -10) + volume_adjustment
	player.bus = config.get("bus", "Master")
	add_child(player)

	if stream:
		player.stream = stream
		# Enable looping for continuous sounds
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		player.play()
		print("✅ Started continuous layer: ", sound_id, " on bus ", player.bus)
	else:
		print("⏳ Continuous layer waiting for sound: ", sound_id)
		# Listen for this specific sound
		sound_bank.sound_generated.connect(_on_sound_generated.bind(player, sound_id))

	return player

func _on_sound_generated(sound_id: String, player: AudioStreamPlayer, target_id: String):
	if sound_id == target_id:
		var stream = sound_bank.get_sound(sound_id)
		if stream:
			player.stream = stream
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
			if is_playing: # Only play if we are still in playing state
				player.play()
				print("✅ Started delayed continuous layer: ", sound_id)
			
			# Disconnect to avoid double handling
			if sound_bank.sound_generated.is_connected(_on_sound_generated):
				sound_bank.sound_generated.disconnect(_on_sound_generated)

func _start_random_events(preset: Dictionary):
	"""Start random event system"""

	if not "random_events" in preset:
		return

	for event_config in preset["random_events"]:
		_create_random_event_timer(event_config)

func _create_random_event_timer(config: Dictionary):
	"""Create a timer for random event triggering"""

	if not "sound_pool" in config or not "interval_range" in config:
		return

	var timer = Timer.new()
	timer.one_shot = false
	timer.autostart = true

	# Set initial random interval
	var interval_range = config["interval_range"]
	timer.wait_time = randf_range(interval_range[0], interval_range[1])

	# Connect timeout
	timer.timeout.connect(_on_random_event_timeout.bind(config))

	add_child(timer)
	random_event_timers.append(timer)
	timer.start()

func _on_random_event_timeout(config: Dictionary):
	"""Handle random event trigger"""

	if not is_playing:
		return

	# Find available event player
	var available_player = null
	for player in event_players:
		if player and is_instance_valid(player) and not player.playing:
			available_player = player
			break

	if not available_player:
		return  # All players busy

	# Pick random sound from pool
	var sound_pool = config["sound_pool"]
	var sound_id = sound_pool[randi() % sound_pool.size()]

	# Get sound from bank
	var stream = sound_bank.get_sound(sound_id)
	if not stream:
		print("⚠️ Failed to get event sound: ", sound_id)
		return

	# Configure player
	available_player.stream = stream
	available_player.bus = config.get("bus", "Master")

	# Random volume within range
	if "volume_range" in config:
		var vol_range = config["volume_range"]
		available_player.volume_db = randf_range(vol_range[0], vol_range[1]) + volume_adjustment
	else:
		available_player.volume_db = -15 + volume_adjustment

	# Play
	available_player.play()
	random_event_triggered.emit(sound_id)

	# Randomize next interval
	var interval_range = config["interval_range"]
	
	# Find the timer that's connected to this specific config
	var timer = null
	for t in random_event_timers:
		if t and t.timeout.is_connected(_on_random_event_timeout.bind(config)):
			timer = t
			break
	
	if timer:
		timer.wait_time = randf_range(interval_range[0], interval_range[1])

func _cleanup_players():
	"""Clean up audio players"""

	for player in continuous_players:
		if player and is_instance_valid(player):
			player.queue_free()
	continuous_players.clear()

func _cleanup_timers():
	"""Clean up event timers"""

	for timer in random_event_timers:
		if timer and is_instance_valid(timer):
			timer.queue_free()
	random_event_timers.clear()

# ===== UTILITY =====

func get_current_preset() -> String:
	"""Get the currently loaded preset name"""
	return preset_name

func is_ambient_playing() -> bool:
	"""Check if ambient is currently playing"""
	return is_playing

func get_info() -> Dictionary:
	"""Get current state information"""
	return {
		"preset": preset_name,
		"is_playing": is_playing,
		"continuous_layers": continuous_players.size(),
		"event_players": event_players.size(),
		"active_timers": random_event_timers.size(),
		"volume_adjustment": volume_adjustment
	}

func print_info():
	"""Print current state"""
	var info = get_info()
	print("🎵 AMBIENT SOUND CONTROLLER 🎵")
	print("   Preset: ", info["preset"])
	print("   Playing: ", info["is_playing"])
	print("   Continuous layers: ", info["continuous_layers"])
	print("   Event players: ", info["event_players"])
	print("   Active timers: ", info["active_timers"])
	print("   Volume adjustment: %.1f dB" % info["volume_adjustment"])
