extends Node
class_name AmbientSoundController

# AmbientSoundController - Per-map ambient sound management
# This node manages ambient sound playback for a specific map based on presets
# Supports non-blocking async generation and pause/resume for map teleportation

# Signals
signal ambient_started()
signal ambient_stopped()
signal ambient_paused()
signal ambient_resumed()
signal random_event_triggered(sound_id: String)
signal loading_started(preset_name: String)
signal loading_progress(progress: float, current_sound: String)
signal loading_complete(preset_name: String)

# Configuration
var preset_name: String = "silent"
var volume_adjustment: float = 0.0  # Additional volume adjustment
var crossfade_duration: float = 2.0
var persist_across_maps: bool = false  # If true, don't restart when changing maps in same sequence

# Audio players
var continuous_players: Array[AudioStreamPlayer] = []
var event_players: Array[AudioStreamPlayer] = []
var num_event_players: int = 8

# Random event system
var random_event_timers: Array[Timer] = []
var is_playing: bool = false
var is_paused: bool = false

# Async generation
var _async_generator: AsyncAudioGenerator = null
var _is_loading: bool = false
var _pending_sounds: Dictionary = {}  # sound_id -> {player, config}

# Playback position tracking (for resume)
var _paused_positions: Dictionary = {}  # player -> position

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
	
	# Connect to scene transition signals for pause/resume
	call_deferred("_connect_scene_signals")

func _connect_scene_signals():
	"""Connect to scene manager signals for pause during map teleportation"""
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		if scene_manager.has_signal("scene_transition_started"):
			if not scene_manager.scene_transition_started.is_connected(_on_scene_transition_started):
				scene_manager.scene_transition_started.connect(_on_scene_transition_started)
		if scene_manager.has_signal("scene_transition_completed"):
			if not scene_manager.scene_transition_completed.is_connected(_on_scene_transition_completed):
				scene_manager.scene_transition_completed.connect(_on_scene_transition_completed)
		print("AmbientSoundController: Connected to SceneManager signals")

func _on_scene_transition_started(_from_scene: String, _to_scene: String, _transition_type = null):
	"""Pause ambient when transitioning between maps"""
	if is_playing and not is_paused:
		pause_ambient()
		print("AmbientSoundController: 🔇 Paused for map transition")

func _on_scene_transition_completed(_scene_name: String, _user_data: Dictionary = {}):
	"""Resume ambient after map transition (if same preset)"""
	if is_paused and persist_across_maps:
		resume_ambient()
		print("AmbientSoundController: 🔊 Resumed after map transition")

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
	
	# Clean up async generator (wait for thread to finish)
	if _async_generator and is_instance_valid(_async_generator):
		_async_generator.stop_generation(true)  # Wait on exit
		_async_generator.queue_free()
		_async_generator = null

# ===== PUBLIC API =====

func load_preset(preset_id: String, volume: float = 0.0, fade_duration: float = 2.0, use_async: bool = true):
	"""Load and start playing an ambient preset (non-blocking by default)"""
	
	# Check if we should persist (don't restart if same preset and persist is enabled)
	if preset_id == preset_name and is_playing and persist_across_maps:
		print("AmbientSoundController: Preset '%s' persists across maps, not restarting" % preset_id)
		return
	
	# If paused with same preset, just resume
	if preset_id == preset_name and is_paused:
		resume_ambient()
		return
	
	# Check SoundBank for transition state - skip if same preset during transition
	if sound_bank and sound_bank.should_skip_generation(preset_id):
		print("AmbientSoundController: Same preset '%s' during transition, taking over" % preset_id)
		preset_name = preset_id
		volume_adjustment = volume
		# Take over as the new controller
		sound_bank.set_current_ambient(preset_id, self)
		# Just start playing from cache (sounds already generated)
		call_deferred("start_ambient")
		return

	preset_name = preset_id
	volume_adjustment = volume
	crossfade_duration = fade_duration
	
	# Check preset config for persistence setting
	var preset = sound_bank.get_preset(preset_name)
	if preset and "generation" in preset:
		persist_across_maps = preset["generation"].get("persist_across_maps", true)  # Default to true
	else:
		persist_across_maps = true  # Default to true for better teleportation UX

	# Stop current ambient if playing
	if is_playing:
		stop_ambient()

	# Setup buses for the preset
	sound_bank.setup_buses_for_preset(preset_name)

	if use_async:
		# Non-blocking generation
		_start_async_generation(preset)
	else:
		# Blocking generation (legacy)
		sound_bank.pregenerate_preset_sounds(preset_name)
		call_deferred("start_ambient")

func _check_all_sounds_cached(preset: Dictionary) -> bool:
	"""Quick check if all sounds for a preset are already cached"""
	if not sound_bank:
		return false
	
	# Check continuous layers
	if "continuous_layers" in preset:
		for layer in preset["continuous_layers"]:
			if "sound_id" in layer:
				if not sound_bank.sound_registry.has(layer["sound_id"]):
					return false
	
	# Check random events
	if "random_events" in preset:
		for event in preset["random_events"]:
			if "sound_pool" in event:
				for sound_id in event["sound_pool"]:
					if not sound_bank.sound_registry.has(sound_id):
						return false
	
	return true


func _start_async_generation(preset: Dictionary):
	"""Start background generation of preset sounds"""
	_pending_sounds.clear()
	
	# FAST PATH: Check if all sounds are already cached before any heavy setup
	var all_cached = _check_all_sounds_cached(preset)
	if all_cached:
		print("AmbientSoundController: All sounds cached, starting immediately (fast path)")
		_is_loading = false
		call_deferred("start_ambient")
		return
	
	# SLOW PATH: Need to generate some sounds
	_is_loading = true
	loading_started.emit(preset_name)
	
	# Cancel any existing generation (don't wait - let it finish in background)
	if _async_generator and is_instance_valid(_async_generator):
		_async_generator.stop_generation(false)  # Don't block
		_async_generator.queue_free()
		_async_generator = null
	
	# Create new generator as child node (prevents GC)
	_async_generator = AsyncAudioGenerator.new()
	_async_generator.name = "AsyncAudioGenerator"
	add_child(_async_generator)
	_async_generator.generation_progress.connect(_on_generation_progress)
	_async_generator.generation_complete.connect(_on_sound_generated_async)
	_async_generator.all_generations_complete.connect(_on_all_sounds_ready)
	
	# Collect sounds to generate
	var sounds_needed: Array = []
	
	# Continuous layers
	if "continuous_layers" in preset:
		for layer in preset["continuous_layers"]:
			if "sound_id" in layer:
				var sound_id = layer["sound_id"]
				# Check if already cached
				if not sound_bank.sound_registry.has(sound_id):
					sounds_needed.append({"id": sound_id, "config": layer, "type": "continuous"})
				else:
					# Already cached - can start immediately
					_pending_sounds[sound_id] = {"config": layer, "type": "continuous", "ready": true}
	
	# Random events
	if "random_events" in preset:
		for event in preset["random_events"]:
			if "sound_pool" in event:
				for sound_id in event["sound_pool"]:
					if not sound_bank.sound_registry.has(sound_id):
						if not sounds_needed.any(func(s): return s["id"] == sound_id):
							sounds_needed.append({"id": sound_id, "config": event, "type": "event"})
	
	if sounds_needed.is_empty():
		# All sounds cached (shouldn't reach here due to fast path, but just in case)
		print("AmbientSoundController: All sounds cached, starting immediately")
		_is_loading = false
		loading_complete.emit(preset_name)
		call_deferred("start_ambient")
		return
	
	print("AmbientSoundController: Generating %d sounds in background..." % sounds_needed.size())
	
	# Queue all sounds for generation
	for item in sounds_needed:
		var sound_id = item["id"]
		_pending_sounds[sound_id] = {"config": item["config"], "type": item["type"], "ready": false}
		
		# Create generator callable
		var gen_callable = func(): return sound_bank._generate_sound(sound_id)
		_async_generator.queue_sound(sound_id, gen_callable)
	
	# Start placeholder if configured
	if "placeholder_layer" in preset:
		_create_placeholder_player(preset["placeholder_layer"])

func _on_generation_progress(sound_id: String, progress: float):
	loading_progress.emit(progress, sound_id)

func _on_sound_generated_async(sound_id: String, stream: AudioStream):
	"""Called when a sound finishes generating in background"""
	if stream:
		# Cache in sound bank
		sound_bank.sound_registry[sound_id] = stream
		
		# Mark as ready
		if _pending_sounds.has(sound_id):
			_pending_sounds[sound_id]["ready"] = true
		
		print("✅ Async generated: ", sound_id)

func _on_all_sounds_ready():
	"""Called when all queued sounds are generated"""
	_is_loading = false
	loading_complete.emit(preset_name)
	print("AmbientSoundController: All sounds ready, starting ambient")
	
	# Fade out placeholder
	_fade_out_placeholder()
	
	# Start ambient
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
	
	# Register with SoundBank for cross-scene tracking
	if sound_bank:
		sound_bank.set_current_ambient(preset_name, self)
	
	ambient_started.emit()

func stop_ambient():
	"""Stop all ambient sounds"""

	if not is_playing and not is_paused:
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
	_paused_positions.clear()

	is_playing = false
	is_paused = false
	
	# Clear SoundBank tracking
	if sound_bank and sound_bank.current_ambient_controller == self:
		sound_bank.set_current_ambient("", null)
	
	ambient_stopped.emit()

func pause_ambient():
	"""Pause all ambient sounds (preserves playback position for resume)"""
	
	if not is_playing or is_paused:
		return
	
	print("⏸️ Pausing ambient preset: ", preset_name)
	_paused_positions.clear()
	
	# Pause continuous players and save positions
	for player in continuous_players:
		if player and is_instance_valid(player) and player.playing:
			_paused_positions[player] = player.get_playback_position()
			player.stream_paused = true
	
	# Pause event players
	for player in event_players:
		if player and is_instance_valid(player) and player.playing:
			player.stream_paused = true
	
	# Pause timers
	for timer in random_event_timers:
		if timer and is_instance_valid(timer):
			timer.paused = true
	
	is_paused = true
	ambient_paused.emit()

func resume_ambient():
	"""Resume paused ambient sounds from saved positions"""
	
	if not is_paused:
		return
	
	print("▶️ Resuming ambient preset: ", preset_name)
	
	# Resume continuous players
	for player in continuous_players:
		if player and is_instance_valid(player):
			player.stream_paused = false
			# Seek to saved position if available
			if _paused_positions.has(player):
				player.seek(_paused_positions[player])
	
	# Resume event players
	for player in event_players:
		if player and is_instance_valid(player):
			player.stream_paused = false
	
	# Resume timers
	for timer in random_event_timers:
		if timer and is_instance_valid(timer):
			timer.paused = false
	
	_paused_positions.clear()
	is_paused = false
	ambient_resumed.emit()

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
	
	# Check for placeholder layer (plays immediately while main song generates)
	if "placeholder_layer" in preset:
		var placeholder_config = preset["placeholder_layer"]
		var placeholder_player = _create_placeholder_player(placeholder_config)
		if placeholder_player:
			continuous_players.append(placeholder_player)

	if not "continuous_layers" in preset:
		return

	for layer_config in preset["continuous_layers"]:
		var player = _create_continuous_player(layer_config, preset.get("placeholder_layer"))
		if player:
			continuous_players.append(player)

var _placeholder_player: AudioStreamPlayer = null

func _create_placeholder_player(config: Dictionary) -> AudioStreamPlayer:
	"""Create a placeholder player that plays immediately while main sound generates"""
	
	if not "sound_id" in config:
		return null
	
	var sound_id = config["sound_id"]
	
	# Try cache first (non-blocking)
	var stream = sound_bank.sound_registry.get(sound_id, null)
	if not stream:
		stream = sound_bank.get_sound(sound_id)
	
	if not stream:
		print("⚠️ Placeholder sound not found: ", sound_id)
		return null
	
	var player = AudioStreamPlayer.new()
	player.name = "PlaceholderLayer"
	player.volume_db = config.get("volume_db", -10) + volume_adjustment
	player.bus = config.get("bus", "Master")
	add_child(player)
	
	player.stream = stream
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.play()
	
	_placeholder_player = player
	print("🎵 Started placeholder layer: ", sound_id, " (while main song generates)")
	
	return player

func _fade_out_placeholder(duration: float = 3.0):
	"""Fade out and remove the placeholder player"""
	
	if not _placeholder_player or not is_instance_valid(_placeholder_player):
		return
	
	var tween = create_tween()
	tween.tween_property(_placeholder_player, "volume_db", -40.0, duration)
	tween.tween_callback(_placeholder_player.queue_free)
	tween.tween_callback(func(): _placeholder_player = null)
	print("🔊→🔇 Fading out placeholder layer")

func _create_continuous_player(config: Dictionary, placeholder_config = null) -> AudioStreamPlayer:
	"""Create and configure a continuous layer player"""

	if not "sound_id" in config:
		return null

	var sound_id = config["sound_id"]

	# Try to get from cache first (non-blocking)
	var stream = sound_bank.sound_registry.get(sound_id, null)
	
	# Only call get_sound (which may generate) if not in cache
	# This should rarely happen if _check_all_sounds_cached was accurate
	if not stream:
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
		
		# Fade out placeholder if main sound is ready immediately
		if placeholder_config and placeholder_config.get("fade_out_when_ready", false):
			_fade_out_placeholder(placeholder_config.get("fade_duration", 3.0))
	else:
		print("⏳ Continuous layer waiting for sound: ", sound_id)
		# Listen for this specific sound, pass placeholder config for fade
		sound_bank.sound_generated.connect(_on_sound_generated_with_placeholder.bind(player, sound_id, placeholder_config))

	return player

func _on_sound_generated_with_placeholder(sound_id: String, player: AudioStreamPlayer, target_id: String, placeholder_config):
	if sound_id == target_id:
		var stream = sound_bank.get_sound(sound_id)
		if stream:
			player.stream = stream
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
			if is_playing:
				player.play()
				print("✅ Started delayed continuous layer: ", sound_id)
				
				# Fade out placeholder now that main sound is ready
				if placeholder_config and placeholder_config.get("fade_out_when_ready", false):
					_fade_out_placeholder(placeholder_config.get("fade_duration", 3.0))
			
			# Disconnect
			if sound_bank.sound_generated.is_connected(_on_sound_generated_with_placeholder):
				sound_bank.sound_generated.disconnect(_on_sound_generated_with_placeholder)

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
	var progress = 0.0
	if _async_generator and is_instance_valid(_async_generator):
		progress = _async_generator.get_progress()
	return {
		"preset": preset_name,
		"is_playing": is_playing,
		"is_paused": is_paused,
		"is_loading": _is_loading,
		"persist_across_maps": persist_across_maps,
		"continuous_layers": continuous_players.size(),
		"event_players": event_players.size(),
		"active_timers": random_event_timers.size(),
		"volume_adjustment": volume_adjustment,
		"loading_progress": progress
	}

func print_info():
	"""Print current state"""
	var info = get_info()
	print("🎵 AMBIENT SOUND CONTROLLER 🎵")
	print("   Preset: ", info["preset"])
	print("   Playing: ", info["is_playing"])
	print("   Paused: ", info["is_paused"])
	print("   Loading: ", info["is_loading"])
	print("   Persist across maps: ", info["persist_across_maps"])
	print("   Continuous layers: ", info["continuous_layers"])
	print("   Event players: ", info["event_players"])
	print("   Active timers: ", info["active_timers"])
	print("   Volume adjustment: %.1f dB" % info["volume_adjustment"])
	if info["is_loading"]:
		print("   Loading progress: %.0f%%" % (info["loading_progress"] * 100))
