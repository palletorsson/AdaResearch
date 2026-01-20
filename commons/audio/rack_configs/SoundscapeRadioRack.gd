extends Node3D

## SoundscapeRadioRack - VR Radio with wheel dials for tuning through soundscape presets
## Uses wheel controls for station tuning and volume adjustment
## Loads soundscape presets from res://commons/audio/presets/

const PRESETS_PATH = "res://commons/audio/presets/"

# Wheel controls
@onready var tuning_wheel = $TuningWheel/HingeOrigin/InteractableHinge
@onready var volume_wheel = $VolumeWheel/HingeOrigin/InteractableHinge
@onready var station_display = $StationDisplay/Label3D
@onready var volume_display = $VolumeDisplay/Label3D
@onready var indicator_mesh = $FrequencyIndicator

# Soundscape player
var soundscape_player: Node3D = null

# Station presets - curated selection for "radio stations"
@export var station_presets: Array[String] = [
	"space_station_isolation.json",
	"quantum_lab.json",
	"underwater_research_lab.json",
	"half_life_science.json",
	"nostromo_corridors.json",
	"blade_runner_minimal.json",
	"cyberpunk_night_market.json",
	"abandoned_factory.json",
	"deep_void.json"
]

# Static noise path
@export var noise_preset: String = "minimal_drone.json"

# Radio state
var current_station: int = -1
var current_angle: float = 0.0
var target_volume_db: float = -6.0

# Volume range
var volume_min_db: float = -40.0
var volume_max_db: float = 0.0

# Station tuning
var station_width: float = 40.0  # Degrees per station
var proximity_threshold: float = 0.3  # How close to center for clear signal

# Preload the soundscape system
const SciFiLoFiSoundscapeScene = preload("res://commons/audio/systems/SciFiLoFiSoundscape.gd")

signal station_changed(station_index: int, station_name: String)
signal volume_changed(volume_db: float)

func _ready():
	_setup_soundscape_player()
	_connect_wheel_signals()
	_update_display()
	
	# Start with noise (between stations)
	_play_noise()

func _setup_soundscape_player():
	"""Create the soundscape player node"""
	soundscape_player = Node3D.new()
	soundscape_player.name = "SoundscapePlayer"
	soundscape_player.set_script(SciFiLoFiSoundscapeScene)
	add_child(soundscape_player)

func _connect_wheel_signals():
	"""Connect wheel hinge signals"""
	if tuning_wheel and tuning_wheel.has_signal("hinge_moved"):
		tuning_wheel.hinge_moved.connect(_on_tuning_wheel_moved)
	
	if volume_wheel and volume_wheel.has_signal("hinge_moved"):
		volume_wheel.hinge_moved.connect(_on_volume_wheel_moved)

func _on_tuning_wheel_moved(angle: float):
	"""Handle tuning wheel rotation"""
	current_angle = angle
	_update_radio_station()

func _on_volume_wheel_moved(angle: float):
	"""Handle volume wheel rotation"""
	# Map 0-360 degrees to volume range
	var normalized = clamp(angle / 360.0, 0.0, 1.0)
	target_volume_db = lerp(volume_min_db, volume_max_db, normalized)
	
	_apply_volume()
	_update_volume_display()
	volume_changed.emit(target_volume_db)

func _update_radio_station():
	"""Determine which station we're tuned to based on angle"""
	# Calculate station position from angle
	var station_position = current_angle / station_width
	var target_station = int(round(station_position))
	
	# Clamp to valid station range
	target_station = clamp(target_station, 0, station_presets.size() - 1)
	
	# Check if we're close enough to the station center
	var distance_from_center = abs(station_position - target_station)
	
	if distance_from_center < proximity_threshold:
		# Clear signal - tune to station
		if target_station != current_station:
			current_station = target_station
			_tune_to_station(current_station)
	else:
		# Between stations - play noise
		if current_station >= 0:
			current_station = -1
			_play_noise()
	
	_update_display()
	_update_indicator(station_position)

func _tune_to_station(station_index: int):
	"""Tune to a specific station"""
	if station_index < 0 or station_index >= station_presets.size():
		return
	
	var preset_name = station_presets[station_index]
	var preset_path = PRESETS_PATH + preset_name
	
	print("📻 Tuning to station %d: %s" % [station_index, preset_name])
	
	# Stop current soundscape
	if soundscape_player.has_method("stop"):
		soundscape_player.stop()
	
	# Load and start new preset
	if soundscape_player.has_method("load_config_from_file"):
		if soundscape_player.load_config_from_file(preset_path):
			if soundscape_player.has_method("start"):
				soundscape_player.start()
				_apply_volume()
	
	station_changed.emit(station_index, preset_name.replace(".json", ""))

func _play_noise():
	"""Play static noise between stations"""
	print("📻 Between stations - static noise")
	
	# Stop current soundscape
	if soundscape_player.has_method("stop"):
		soundscape_player.stop()
	
	# Load minimal drone as "static"
	var noise_path = PRESETS_PATH + noise_preset
	if soundscape_player.has_method("load_config_from_file"):
		if soundscape_player.load_config_from_file(noise_path):
			if soundscape_player.has_method("start"):
				soundscape_player.start()

func _apply_volume():
	"""Apply volume to soundscape player"""
	if soundscape_player:
		soundscape_player.volume_adjustment = target_volume_db

func _update_display():
	"""Update the station display"""
	if not station_display:
		return
	
	if current_station >= 0 and current_station < station_presets.size():
		var preset_name = station_presets[current_station].replace(".json", "").replace("_", " ")
		station_display.text = "📻 %s" % preset_name.to_upper()
	else:
		var freq = (current_angle / station_width + 88.0)  # Fake FM frequency
		station_display.text = "%.1f MHz" % freq

func _update_volume_display():
	"""Update the volume display"""
	if volume_display:
		var volume_percent = remap(target_volume_db, volume_min_db, volume_max_db, 0, 100)
		volume_display.text = "VOL: %d%%" % int(volume_percent)

func _update_indicator(station_position: float):
	"""Update the frequency indicator position"""
	if indicator_mesh:
		# Move indicator mesh based on station position
		var x_pos = (station_position / float(station_presets.size())) * 0.4 - 0.2
		indicator_mesh.position.x = x_pos

# ===== PUBLIC API =====

func next_station():
	"""Tune to next station"""
	var next_idx = (current_station + 1) % station_presets.size()
	current_angle = next_idx * station_width
	_update_radio_station()

func previous_station():
	"""Tune to previous station"""
	var prev_idx = current_station - 1
	if prev_idx < 0:
		prev_idx = station_presets.size() - 1
	current_angle = prev_idx * station_width
	_update_radio_station()

func set_station(index: int):
	"""Directly tune to a station index"""
	if index >= 0 and index < station_presets.size():
		current_angle = index * station_width
		_update_radio_station()

func get_station_name() -> String:
	"""Get current station name"""
	if current_station >= 0 and current_station < station_presets.size():
		return station_presets[current_station].replace(".json", "")
	return "Static"

func get_station_count() -> int:
	"""Get total number of stations"""
	return station_presets.size()
