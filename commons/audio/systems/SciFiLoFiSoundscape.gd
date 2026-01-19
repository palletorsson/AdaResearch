extends Node3D
class_name SciFiLoFiSoundscape

## SciFiLoFiSoundscape - Lightweight orchestrator for sci-fi lo-fi ambient soundscapes
## Composes existing generators (TechnoNoirGenerator, TrapBeatsGenerator, etc.)
## instead of implementing new synthesis from scratch.

# Signals
signal soundscape_started()
signal soundscape_stopped()
signal parameter_changed(param_name: String, value: float)

# Configuration loaded from JSON or set directly
var soundscape_config: Dictionary = {}

# Audio players
var continuous_players: Array[AudioStreamPlayer3D] = []
var effect_players: Array[AudioStreamPlayer3D] = []

# Abstract parameters (0.0 - 1.0 range)
var abstract_params: Dictionary = {
	"intensity": 0.5,
	"tension": 0.3,
	"space": 0.5,
	"darkness": 0.4
}

# Timers for random events
var event_timers: Array[Timer] = []

# State
var is_playing: bool = false
var volume_adjustment: float = 0.0

# Generator references (static classes)
const TechnoNoirGenerator = preload("res://commons/audio/generators/TechnoNoirGenerator.gd")
const TrapBeatsGenerator = preload("res://commons/audio/generators/TrapBeatsGenerator.gd")

# Optional generators (may not exist)
var GranularWindGenerator = null
var CinematicMusicGenerator = null

# RNG for event timing
var rng = RandomNumberGenerator.new()

# Number of effect player pool
@export var num_effect_players: int = 5

@export_file("*.json") var config_path: String = ""

func _ready():
	rng.randomize()
	
	# Try to load optional generators
	_load_optional_generators()
	
	# Create effect player pool
	_create_effect_player_pool()
	
	# Load config if path specified
	if not config_path.is_empty():
		load_config_from_file(config_path)

func _load_optional_generators():
	# Try to load generators that may not exist
	if ResourceLoader.exists("res://commons/audio/generators/GranularWindGenerator.gd"):
		GranularWindGenerator = load("res://commons/audio/generators/GranularWindGenerator.gd")
	if ResourceLoader.exists("res://commons/audio/generators/CinematicMusicGenerator.gd"):
		CinematicMusicGenerator = load("res://commons/audio/generators/CinematicMusicGenerator.gd")

func _create_effect_player_pool():
	for i in range(num_effect_players):
		var player = AudioStreamPlayer3D.new()
		player.name = "EffectPlayer_%d" % i
		player.volume_db = -15
		add_child(player)
		effect_players.append(player)

# ===== PUBLIC API =====

func load_config_from_file(path: String) -> bool:
	"""Load soundscape configuration from JSON file"""
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SciFiLoFiSoundscape: Failed to open config: " + path)
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("SciFiLoFiSoundscape: JSON parse error: " + json.get_error_message())
		return false
	
	soundscape_config = json.data
	print("🎵 Loaded soundscape config: ", soundscape_config.get("name", "Unknown"))
	return true

func load_config(config: Dictionary):
	"""Set soundscape configuration directly"""
	soundscape_config = config
	print("🎵 Applied soundscape config: ", soundscape_config.get("name", "Unknown"))

func start():
	"""Start the soundscape"""
	if is_playing:
		return
	
	if soundscape_config.is_empty():
		push_warning("SciFiLoFiSoundscape: No config loaded")
		return
	
	print("▶️ Starting soundscape: ", soundscape_config.get("name", "Unknown"))
	
	_start_continuous_layers()
	_start_random_events()
	
	is_playing = true
	soundscape_started.emit()

func stop():
	"""Stop the soundscape"""
	if not is_playing:
		return
	
	print("⏹️ Stopping soundscape")
	
	# Stop continuous players
	for player in continuous_players:
		if player and is_instance_valid(player):
			player.stop()
			player.queue_free()
	continuous_players.clear()
	
	# Stop effect players
	for player in effect_players:
		if player and is_instance_valid(player):
			player.stop()
	
	# Stop timers
	for timer in event_timers:
		if timer and is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	event_timers.clear()
	
	is_playing = false
	soundscape_stopped.emit()

func set_parameter(param_name: String, value: float):
	"""Set an abstract parameter (0.0 - 1.0)"""
	value = clamp(value, 0.0, 1.0)
	abstract_params[param_name] = value
	_apply_parameter(param_name, value)
	parameter_changed.emit(param_name, value)

func get_parameter(param_name: String) -> float:
	return abstract_params.get(param_name, 0.5)

# ===== INTERNAL: CONTINUOUS LAYERS =====

func _start_continuous_layers():
	if not "continuous_layers" in soundscape_config:
		return
	
	for layer_config in soundscape_config["continuous_layers"]:
		var player = _create_continuous_player(layer_config)
		if player:
			continuous_players.append(player)

func _create_continuous_player(config: Dictionary) -> AudioStreamPlayer3D:
	"""Create and start a continuous layer player"""
	var generator_name = config.get("generator", "TechnoNoirGenerator")
	var method_name = config.get("method", "create_endless_drone")
	var params = config.get("params", {})
	var volume_db = config.get("volume_db", -12.0)
	var bus = config.get("bus", "Master")
	
	# Generate the audio stream
	var stream = _call_generator(generator_name, method_name, params)
	if not stream:
		push_warning("SciFiLoFiSoundscape: Failed to generate sound for layer")
		return null
	
	# Create player
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db + volume_adjustment
	player.bus = bus
	player.max_distance = 50.0
	player.unit_size = 5.0
	
	# Enable looping if the stream supports it
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 4  # 16-bit stereo
	
	add_child(player)
	player.play()
	
	print("  ✓ Started layer: %s.%s" % [generator_name, method_name])
	return player

# ===== INTERNAL: RANDOM EVENTS =====

func _start_random_events():
	if not "random_events" in soundscape_config:
		return
	
	for event_config in soundscape_config["random_events"]:
		var timer = Timer.new()
		timer.one_shot = true
		
		var interval_range = event_config.get("interval_range", [10.0, 30.0])
		timer.wait_time = rng.randf_range(interval_range[0], interval_range[1])
		
		timer.timeout.connect(_on_event_timeout.bind(event_config))
		add_child(timer)
		event_timers.append(timer)
		timer.start()

func _on_event_timeout(config: Dictionary):
	if not is_playing:
		return
	
	# Find available effect player
	var player = _get_available_effect_player()
	if not player:
		_reschedule_event(config)
		return
	
	# Generate the sound
	var generator_name = config.get("generator", "TechnoNoirGenerator")
	var method_name = config.get("method", "create_static_burst")
	var params = config.get("params", {})
	
	var stream = _call_generator(generator_name, method_name, params)
	if stream:
		var volume_range = config.get("volume_range", [-20, -10])
		player.stream = stream
		player.volume_db = rng.randf_range(volume_range[0], volume_range[1]) + volume_adjustment
		player.bus = config.get("bus", "Effects")
		player.play()
	
	# Reschedule
	_reschedule_event(config)

func _reschedule_event(config: Dictionary):
	var interval_range = config.get("interval_range", [10.0, 30.0])
	var wait_time = rng.randf_range(interval_range[0], interval_range[1])
	
	# Adjust by intensity parameter
	wait_time *= (2.0 - abstract_params["intensity"])
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = wait_time
	timer.timeout.connect(_on_event_timeout.bind(config))
	add_child(timer)
	event_timers.append(timer)
	timer.start()

func _get_available_effect_player() -> AudioStreamPlayer3D:
	for player in effect_players:
		if player and is_instance_valid(player) and not player.playing:
			return player
	return null

# ===== INTERNAL: GENERATOR DISPATCH =====

func _call_generator(generator_name: String, method_name: String, params: Dictionary) -> AudioStream:
	"""Call a static generator method and return the AudioStream"""
	
	match generator_name:
		"TechnoNoirGenerator":
			return _call_techno_noir(method_name, params)
		"TrapBeatsGenerator":
			return _call_trap_beats(method_name, params)
		"GranularWindGenerator":
			return _call_granular_wind(method_name, params)
		"CinematicMusicGenerator":
			return _call_cinematic(method_name, params)
		_:
			push_warning("SciFiLoFiSoundscape: Unknown generator: " + generator_name)
			return null

func _call_techno_noir(method_name: String, params: Dictionary) -> AudioStream:
	match method_name:
		"create_endless_drone":
			return TechnoNoirGenerator.create_endless_drone(params)
		"create_city_ambience":
			return TechnoNoirGenerator.create_city_ambience(params)
		"create_distant_siren":
			return TechnoNoirGenerator.create_distant_siren(params)
		"create_static_burst":
			return TechnoNoirGenerator.create_static_burst(params)
		"create_rain_segment":
			return TechnoNoirGenerator.create_rain_segment(params)
		_:
			push_warning("TechnoNoirGenerator has no method: " + method_name)
			return null

func _call_trap_beats(method_name: String, params: Dictionary) -> AudioStream:
	match method_name:
		"create_808_kick":
			return TrapBeatsGenerator.create_808_kick(params)
		"create_trap_snare":
			return TrapBeatsGenerator.create_trap_snare(params)
		"create_hihat_closed":
			return TrapBeatsGenerator.create_hihat_closed(params)
		"create_hihat_open":
			return TrapBeatsGenerator.create_hihat_open(params)
		"create_clap":
			return TrapBeatsGenerator.create_clap(params)
		_:
			push_warning("TrapBeatsGenerator has no method: " + method_name)
			return null

func _call_granular_wind(method_name: String, params: Dictionary) -> AudioStream:
	if not GranularWindGenerator:
		push_warning("GranularWindGenerator not available")
		return null
	return GranularWindGenerator.call(method_name, params)

func _call_cinematic(method_name: String, params: Dictionary) -> AudioStream:
	if not CinematicMusicGenerator:
		push_warning("CinematicMusicGenerator not available")
		return null
	return CinematicMusicGenerator.call(method_name, params)

# ===== INTERNAL: ABSTRACT PARAMETERS =====

func _apply_parameter(param_name: String, value: float):
	"""Apply abstract parameter changes to the soundscape"""
	
	match param_name:
		"intensity":
			# Intensity affects event frequency (handled in _reschedule_event)
			# and drone volume
			for player in continuous_players:
				if player and is_instance_valid(player):
					# Boost by up to 6dB at full intensity
					player.volume_db += (value - 0.5) * 12.0
		
		"tension":
			# Tension could modulate filter cutoff if we had real-time DSP
			# For now, this is a placeholder for future audio bus manipulation
			pass
		
		"space":
			# Space affects reverb - would need audio bus access
			pass
		
		"darkness":
			# Darkness affects low-pass filter
			pass
