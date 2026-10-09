extends Node3D
## The same tuning rule has four accounts: band, discrete lamps, list, or no map.
const PRESETS_PATH = "res://commons/audio/presets/"
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
const SciFiLoFiSoundscapeScene = preload("res://commons/audio/systems/SciFiLoFiSoundscape.gd")
const FACE_MODES: Array = ["scale", "presets", "list", "void"]
@export_enum("scale", "presets", "list", "void") var face: String = "scale"
@export var station_presets: Array[String] = [
	"space_station_isolation.json", "quantum_lab.json", "underwater_research_lab.json",
	"half_life_science.json", "nostromo_corridors.json", "blade_runner_minimal.json",
	"cyberpunk_night_market.json", "abandoned_factory.json", "deep_void.json"
]
@export var noise_preset: String = "minimal_drone.json"
@onready var tuning_control: Node3D = $TuningWheel
@onready var volume_control: Node3D = $VolumeWheel
@onready var tuning_wheel = $TuningWheel/HingeOrigin/InteractableHinge
@onready var volume_wheel = $VolumeWheel/HingeOrigin/InteractableHinge
var soundscape_player: Node3D
var current_station := -1
var current_angle := 0.0
var target_volume_db := -6.0
var volume_min_db := -40.0
var volume_max_db := 0.0
var station_width := 40.0
var proximity_threshold := .3
var _built := false
var _panel: Dictionary = {}
var _face_root: Control
var _status: Label
var _station_reading: Label
var _needle: ColorRect
var _preset_lamps: Array[ColorRect] = []
var _list_labels: Array[Label] = []
var _audio_timer: Timer
var _requested_preset := ""
var _loaded_preset := ""
var _audio_error := false
signal station_changed(station_index: int, station_name: String)
signal volume_changed(volume_db: float)

func _ready() -> void:
	_setup_soundscape_player()
	if soundscape_player.has_signal("generation_complete"):
		soundscape_player.generation_complete.connect(_update_display)
	_audio_timer = Timer.new()
	_audio_timer.one_shot = true
	_audio_timer.wait_time = .18
	_audio_timer.timeout.connect(_flush_audio_request)
	add_child(_audio_timer)
	_build_housing_text()
	tuning_wheel.hinge_limit_min = 0
	tuning_wheel.hinge_limit_max = _band_end()
	volume_wheel.hinge_limit_min = -135
	volume_wheel.hinge_limit_max = 135
	tuning_control.set_caption("TUNE")
	volume_control.set_caption("LEVEL")
	volume_control.set_display_range(volume_min_db, volume_max_db, " dB")
	# Start between two station centres, as the sound has always claimed to do.
	current_angle = station_width * .5
	tuning_control.set_angle_degrees(current_angle)
	volume_control.set_angle_degrees(remap(target_volume_db, volume_min_db, volume_max_db, -135, 135))
	tuning_wheel.hinge_moved.connect(_on_tuning_wheel_moved)
	volume_wheel.hinge_moved.connect(_on_volume_wheel_moved)
	_apply_volume()
	_build_face()
	_built = true
	_play_noise()
	_update_display()

func _setup_soundscape_player():
	soundscape_player = Node3D.new()
	soundscape_player.name = "SoundscapePlayer"
	soundscape_player.set_script(SciFiLoFiSoundscapeScene)
	add_child(soundscape_player)

func _band_end() -> float:
	return maxf(station_width, station_presets.size() * station_width)

func _on_tuning_wheel_moved(angle: float) -> void:
	current_angle = angle
	_update_radio_station()

func _on_volume_wheel_moved(angle: float) -> void:
	target_volume_db = remap(clampf(angle, -135, 135), -135, 135, volume_min_db, volume_max_db)
	_apply_volume()
	volume_changed.emit(target_volume_db)

func _update_radio_station() -> void:
	var station_position := current_angle / station_width
	var candidate := clampi(roundi(station_position), 0, maxi(0, station_presets.size()-1))
	var selected := candidate if not station_presets.is_empty() and absf(station_position-candidate) < proximity_threshold else -1
	if selected != current_station:
		current_station = selected
		if selected >= 0: _tune_to_station(selected)
		else: _play_noise()
	_update_display()

func _tune_to_station(index: int) -> void:
	if index < 0 or index >= station_presets.size(): return
	_request_audio(station_presets[index])
	station_changed.emit(index, station_presets[index].trim_suffix(".json"))

func _play_noise() -> void:
	_request_audio(noise_preset)

func _request_audio(preset: String) -> void:
	_requested_preset = preset
	_audio_error = false
	if _requested_preset != _loaded_preset: _audio_timer.start()
	else: _audio_timer.stop()

func _flush_audio_request() -> void:
	if _requested_preset == _loaded_preset: return
	# Never join an in-flight generator from a wheel callback. Keep the latest request.
	if soundscape_player.get("is_generating") == true:
		_audio_timer.start()
		return
	soundscape_player.stop()
	if soundscape_player.load_config_from_file(PRESETS_PATH + _requested_preset):
		_loaded_preset = _requested_preset
		_apply_volume()
		soundscape_player.start()
	else:
		_audio_error = true
	_update_display()

func _apply_volume() -> void:
	if soundscape_player: soundscape_player.volume_adjustment = target_volume_db

func _build_housing_text() -> void:
	var title := BakedText.make_label_mesh("SOUNDSCAPE RADIO", Color(.88,.93,.86), Vector2(.51,.033), 2200, true)
	title.position = Vector3(0,.329,.047)
	add_child(title)
	_panel = ValueSurface.build(self, Vector2(.51,.235), Vector3(0,.16,.056))
	_panel.viewport.size = Vector2i(1100,500)
	_panel.label.hide()
	_panel.viewport.get_child(0).size = Vector2(1100,500)

func _build_face() -> void:
	if is_instance_valid(_face_root):
		_panel.viewport.remove_child(_face_root)
		_face_root.queue_free()
	_face_root = Control.new()
	_face_root.size = Vector2(1100,500)
	_panel.viewport.add_child(_face_root)
	_preset_lamps.clear()
	_list_labels.clear()
	_station_reading = null
	_needle = null
	_status = null
	tuning_control.set_readout_visible(face == "scale")
	volume_control.set_readout_visible(face != "void")
	if face == "void":
		_panel.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	if face == "list":
		_print("STATION LIST", Vector2(38,12), Vector2(1024,40), 28)
		var step := minf(42, 390.0/maxi(1,station_presets.size()))
		for i in station_presets.size():
			var row := _print("%02d  %s" % [i+1,_station_label(i)], Vector2(38,66+i*step), Vector2(1024,step), 29)
			_list_labels.append(row)
	else:
		_print("PRESET BAND · DEGREES" if face == "scale" else "STATIONS", Vector2(38,22), Vector2(1024,42), 28)
		_station_reading = _print("", Vector2(38,86), Vector2(1024,86), 43)
		if face == "scale":
			for i in range(station_presets.size()+1):
				var x := 60.0 + 980.0*i/maxi(1,station_presets.size())
				_rect(Vector2(x-1,230),Vector2(2,37),Color(.4,.55,.52))
				if i % 2 == 0 or i == station_presets.size():
					_print("%d°" % (i*station_width),Vector2(x-43,277),Vector2(86,40),27,HORIZONTAL_ALIGNMENT_CENTER)
			_needle = _rect(Vector2(60,212),Vector2(5,62),Color(1,.58,.20))
			_print("Turn through the gaps. Listen for a station.",Vector2(38,359),Vector2(1024,46),28)
		else:
			var count := maxi(1,station_presets.size())
			for i in station_presets.size():
				var x := 60.0+980.0*(i+.5)/count
				_preset_lamps.append(_rect(Vector2(x-29,245),Vector2(58,40),Color(.12,.18,.19)))
				_print("%02d" % (i+1),Vector2(x-30,300),Vector2(60,40),29,HORIZONTAL_ALIGNMENT_CENTER)
	_status = _print("",Vector2(38,450),Vector2(1024,32),23)
	_update_display()

func _print(text: String, at: Vector2, size: Vector2, pixels: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",BakedText.project_font("medium"))
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",Color(.80,.90,.84))
	_face_root.add_child(label)
	return label

func _rect(at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.color = color
	_face_root.add_child(rect)
	return rect

func _station_label(index: int) -> String:
	if index < 0 or index >= station_presets.size(): return ""
	return station_presets[index].trim_suffix(".json").replace("_"," ").to_upper()

func _update_display() -> void:
	if _panel.is_empty(): return
	if is_instance_valid(_station_reading):
		_station_reading.text = "%02d  %s" % [current_station+1,_station_label(current_station)] if current_station >= 0 else ("BETWEEN STATIONS" if face == "scale" else "")
	if is_instance_valid(_needle): _needle.position.x = 60 + 980*current_angle/_band_end()
	for i in _preset_lamps.size():
		_preset_lamps[i].color = Color(.25,.94,.80) if i == current_station else Color(.12,.18,.19)
	for i in _list_labels.size():
		_list_labels[i].add_theme_color_override("font_color",Color(.35,1,.83) if i == current_station else Color(.56,.65,.62))
	if is_instance_valid(_status):
		_status.text = ""
		if _audio_error: _status.text = "SOUND UNAVAILABLE"
		elif _requested_preset != _loaded_preset: _status.text = "TUNING…"
		elif soundscape_player.get("is_generating") == true: _status.text = "PREPARING SOUND…"
		elif soundscape_player.get("unavailable_sounds") != null and not soundscape_player.unavailable_sounds.is_empty(): _status.text = "SOME SOUNDS UNAVAILABLE"
	_panel.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func next_station() -> void:
	if not station_presets.is_empty(): set_station((current_station+1)%station_presets.size())
func previous_station() -> void:
	if not station_presets.is_empty(): set_station(posmod(current_station-1,station_presets.size()))
func set_station(index: int) -> void:
	if index < 0 or index >= station_presets.size(): return
	tuning_control.set_angle_degrees(index*station_width)
	_on_tuning_wheel_moved(tuning_wheel.hinge_position)
func get_station_name() -> String:
	return station_presets[current_station].trim_suffix(".json") if current_station >= 0 else "Static"
func get_station_count() -> int: return station_presets.size()
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("face"): return
	var want := str(config_data["face"]).strip_edges().to_lower()
	if want not in FACE_MODES or want == face: return
	face = want
	if _built: _build_face()
