extends Node3D

## SoundscapeRadioRack - VR Radio with wheel dials for tuning through soundscape presets
## Uses wheel controls for station tuning and volume adjustment
## Loads soundscape presets from res://commons/audio/presets/


# @identity
# essence: station = floor(angle / station_width), clarity = 1 - |offset| / threshold
# desire: Turn a physical wheel in VR to tune between soundscape radio stations
# critical_parameter: station_width (degrees per station) — determines tuning precision
# triggers: wheel rotation angle maps to station index; proximity to center determines signal clarity
# emerges: static noise between stations, clean signal at center — analog radio metaphor
# needs: VR hinge wheel [has], volume wheel [has]
# relationships: depends on SciFiLoFiSoundscape presets; contrasts with audio_catalog_tablet (browsing vs tuning); unlocks ambient audio curation
# truth: Every frequency band is a station; tuning is selecting which resonance to amplify.

const PRESETS_PATH = "res://commons/audio/presets/"

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# face: what the front panel claims the spectrum IS. The tuning maths never
#   changes — station = round(angle / 40°), clarity = 1 - |offset| — but the
#   panel's account of it does, and the account is the argument:
#     scale   the shipped printed band 88 … 108 with a sliding needle. Stations
#             are POINTS ON A CONTINUUM; the between is a real place with a
#             number, and static is a position you can read off the dial.
#     presets one lit lamp per station in a row, no scale, no needle. Stations
#             are DISCRETE OBJECTS and the between does not appear on the face
#             at all — you still hear it, and the panel denies it exists.
#     list    the station names in a column, the tuned one lit. The spectrum is
#             a CURATED MENU: tuning is choosing from what someone stocked, and
#             the continuum has been replaced by nine proper nouns.
#     void    no scale, no needle, no readout — only the two wheels and a dark
#             display. There is NO MAP; the receiver tells you nothing and the
#             only way to find a station is to listen for one.
@export_enum("scale", "presets", "list", "void") var face: String = "scale"
const FACE_MODES: Array = ["scale", "presets", "list", "void"]

# Wheel controls
@onready var tuning_wheel = $TuningWheel/HingeOrigin/InteractableHinge
@onready var volume_wheel = $VolumeWheel/HingeOrigin/InteractableHinge
@onready var station_display = $StationDisplay/Label3D
@onready var volume_display = $VolumeDisplay/Label3D
@onready var indicator_mesh = $FrequencyIndicator
@onready var frequency_scale = $FrequencyScale

# Face state (built only for the non-default values)
var _face_root: Node3D = null
var _preset_lamps: Array = []
var _list_labels: Array = []
var _built: bool = false

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
	_build_face()
	_update_display()
	_built = true

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

# ===== FACE =====

func _build_face() -> void:
	"""Build whatever the current face value needs, and put back what it doesn't.

	face == "scale" adds NOTHING and hides NOTHING — the .tscn's own printed band
	and needle are exactly what they always were, so every existing placement is
	untouched."""
	if _face_root != null:
		_face_root.queue_free()
	_face_root = null
	_preset_lamps.clear()
	_list_labels.clear()

	# The printed band and its needle belong to "scale" alone. Both are leaf
	# nodes with no children, so hiding them hides nothing else (visibility in
	# Godot is hierarchical — this is the safe case for it).
	var show_scale: bool = (face == "scale")
	if frequency_scale != null:
		frequency_scale.visible = show_scale
	if indicator_mesh != null:
		indicator_mesh.visible = show_scale

	if face == "scale" or face == "void":
		return

	_face_root = Node3D.new()
	_face_root.name = "FacePanel"
	add_child(_face_root)

	if face == "presets":
		_build_preset_lamps()
	elif face == "list":
		_build_station_list()

func _build_preset_lamps() -> void:
	"""One lamp per station, in a row where the printed band used to be."""
	var count: int = max(1, station_presets.size())
	var span: float = 0.40
	var lamp_mesh: BoxMesh = BoxMesh.new()
	lamp_mesh.size = Vector3(span / float(count) * 0.68, 0.024, 0.012)
	for i in range(count):
		var lamp: MeshInstance3D = MeshInstance3D.new()
		lamp.name = "StationLamp_%d" % i
		lamp.mesh = lamp_mesh
		lamp.material_override = _lamp_material(false)
		var x: float = -span * 0.5 + span * (float(i) + 0.5) / float(count)
		lamp.position = Vector3(x, 0.042, 0.044)
		_face_root.add_child(lamp)
		_preset_lamps.append(lamp)
	_refresh_face_state()

func _build_station_list() -> void:
	"""The stations as a stocked list — nine proper nouns instead of a band."""
	var count: int = station_presets.size()
	if count == 0:
		return
	var top: float = 0.045
	var step: float = 0.013
	for i in range(count):
		var row: Label3D = Label3D.new()
		row.name = "StationRow_%d" % i
		row.text = _station_label(i)
		row.font_size = 18
		row.pixel_size = 0.0003
		row.outline_size = 2
		row.position = Vector3(-0.12, top - step * float(i), 0.044)
		_face_root.add_child(row)
		_list_labels.append(row)
	_refresh_face_state()

func _lamp_material(lit: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.emission_enabled = true
	_paint_lamp(mat, lit)
	return mat

func _paint_lamp(mat: StandardMaterial3D, lit: bool) -> void:
	# Mutates in place: _refresh_face_state runs on every wheel move, and
	# allocating nine materials per frame while tuning is not a look, it is litter.
	if lit:
		mat.albedo_color = Color(0.15, 0.85, 1.0, 1.0)
		mat.emission = Color(0.15, 0.85, 1.0)
		mat.emission_energy_multiplier = 2.2
	else:
		mat.albedo_color = Color(0.04, 0.09, 0.11, 1.0)
		mat.emission = Color(0.0, 0.35, 0.5)
		mat.emission_energy_multiplier = 0.25

func _station_label(index: int) -> String:
	if index < 0 or index >= station_presets.size():
		return ""
	return station_presets[index].replace(".json", "").replace("_", " ").to_upper()

func _refresh_face_state() -> void:
	"""Light whichever station is tuned. No-op for scale and void."""
	for i in range(_preset_lamps.size()):
		var lamp: MeshInstance3D = _preset_lamps[i]
		if lamp == null:
			continue
		var mat: StandardMaterial3D = lamp.material_override as StandardMaterial3D
		if mat == null:
			continue
		_paint_lamp(mat, i == current_station)
	for i in range(_list_labels.size()):
		var row: Label3D = _list_labels[i]
		if row == null:
			continue
		if i == current_station:
			row.modulate = Color(0.2, 1.0, 1.0, 1.0)
		else:
			row.modulate = Color(0.35, 0.45, 0.5, 1.0)

func _update_display():
	"""Update the station display"""
	_refresh_face_state()

	if not station_display:
		return

	if face == "void":
		# No map. The receiver reports nothing and you tune by ear alone.
		station_display.text = ""
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

func apply_grid_config(config_data: Dictionary) -> void:
	# GUARDED. A map token that does not name `face` returns immediately, and the
	# panel is only rebuilt when the value actually differs AND _ready has already
	# built it once. GridInteractablesComponent calls this deferred, after _ready,
	# so an unguarded rebuild would tear the face off all five shipped placements
	# on their first frame in exchange for nothing.
	if not config_data.has("face"):
		return
	var want: String = str(config_data["face"]).strip_edges().to_lower()
	if not FACE_MODES.has(want) or want == face:
		return
	face = want
	if _built:
		_build_face()
		_update_display()
