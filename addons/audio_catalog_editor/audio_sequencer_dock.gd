@tool
extends Control

const PARAMETERS_BASE_DIR := "res://commons/audio/parameters/"
const CATEGORY_SEPARATOR := "/"

const TechnoNoirGenerator := preload("res://commons/audio/generators/TechnoNoirGenerator.gd")
const TrapBeatsGenerator := preload("res://commons/audio/generators/TrapBeatsGenerator.gd")
const CustomSoundGenerator := preload("res://commons/audio/generators/CustomSoundGenerator.gd")
const AudioSynthesizer := preload("res://commons/audio/generators/AudioSynthesizer.gd")
const CinematicMusicGenerator := preload("res://commons/audio/generators/CinematicMusicGenerator.gd")
const EpicSynthEngine := preload("res://commons/audio/engines/EpicSynthEngine.gd")
const SciFiPreviewGenerator := preload("res://commons/audio/generators/SciFiPreviewGenerator.gd")
const LiturgicalAmbientGenerator := preload("res://algorithms/wavefunctions/liturgicalambientgenerator/liturgicalambientgenerator.gd")
const FourierSpaceGenerator := preload("res://commons/audio/generators/FourierSpaceGenerator.gd")

# UI Elements
var play_button: Button
var stop_button: Button
var clear_button: Button
var tempo_slider: HSlider
var tempo_label: Label
var sequencer_grid: GridContainer
var melody_timeline: Control
var preset_buttons: HBoxContainer

# Sequencer data
var sequencer_data: Dictionary = {}  # Track name -> Array of bools (16 steps)
var melody_data: Array = []  # Array of {step: int, note: String, preset_id: String}
var current_step: int = 0
var is_playing: bool = false
var tempo: float = 120.0  # BPM
var steps_per_beat: int = 4  # 16th notes
var total_steps: int = 16
var step_timer: Timer

# Audio players for each track
var track_players: Dictionary = {}  # Track name -> AudioStreamPlayer
var melody_player: AudioStreamPlayer

# Preset catalog
var catalog_entries: Array = []
var entries_by_id: Dictionary = {}
var preset_entries: Dictionary = {}  # Track name -> entry_id

# Track definitions
var drum_tracks: Array = ["KICK", "SNARE", "HIHAT", "OPENHAT", "CLAP"]

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_build_ui()
	_setup_audio_players()
	_load_catalog()
	_initialize_sequencer()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.custom_minimum_size = Vector2(0, 720)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "RHYTHM MACHINE"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main_vbox.add_child(title)
	
	# Top controls
	var controls_row = HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(controls_row)
	
	# Playback controls
	play_button = Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_pressed)
	controls_row.add_child(play_button)
	
	stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_stop_pressed)
	controls_row.add_child(stop_button)
	
	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(_on_clear_pressed)
	controls_row.add_child(clear_button)
	
	# Tempo control
	controls_row.add_child(HSeparator.new())
	
	var tempo_container = HBoxContainer.new()
	tempo_container.add_theme_constant_override("separation", 8)
	controls_row.add_child(tempo_container)
	
	var tempo_label_container = Label.new()
	tempo_label_container.text = "TEMPO"
	tempo_container.add_child(tempo_label_container)
	
	tempo_slider = HSlider.new()
	tempo_slider.min_value = 60.0
	tempo_slider.max_value = 200.0
	tempo_slider.value = tempo
	tempo_slider.step = 1.0
	tempo_slider.custom_minimum_size = Vector2(200, 0)
	tempo_slider.value_changed.connect(_on_tempo_changed)
	tempo_container.add_child(tempo_slider)
	
	tempo_label = Label.new()
	tempo_label.text = str(int(tempo)) + " BPM"
	tempo_label.custom_minimum_size = Vector2(80, 0)
	tempo_container.add_child(tempo_label)
	
	controls_row.add_child(Control.new())  # Spacer
	
	# Sequencer grid
	var grid_container = PanelContainer.new()
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(grid_container)
	
	var grid_vbox = VBoxContainer.new()
	grid_vbox.add_theme_constant_override("separation", 4)
	grid_container.add_child(grid_vbox)
	
	# Create grid header (step numbers)
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	grid_vbox.add_child(header_row)
	
	var track_label_spacer = Label.new()
	track_label_spacer.text = ""
	track_label_spacer.custom_minimum_size = Vector2(100, 0)
	header_row.add_child(track_label_spacer)
	
	for step in range(total_steps):
		var step_label = Label.new()
		step_label.text = str(step + 1)
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_label.custom_minimum_size = Vector2(30, 0)
		header_row.add_child(step_label)
	
	# Create sequencer grid
	sequencer_grid = GridContainer.new()
	sequencer_grid.columns = total_steps + 1  # +1 for track labels
	sequencer_grid.add_theme_constant_override("h_separation", 4)
	sequencer_grid.add_theme_constant_override("v_separation", 4)
	grid_vbox.add_child(sequencer_grid)
	
	# Create rows for each drum track
	for track in drum_tracks:
		_create_track_row(track)
	
	# Melody timeline section
	var melody_label = Label.new()
	melody_label.text = "Melody Timeline"
	melody_label.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(melody_label)
	
	melody_timeline = Control.new()
	melody_timeline.custom_minimum_size = Vector2(0, 150)
	melody_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	melody_timeline.draw.connect(_draw_melody_timeline)
	main_vbox.add_child(melody_timeline)
	
	# Preset buttons
	preset_buttons = HBoxContainer.new()
	preset_buttons.add_theme_constant_override("separation", 8)
	main_vbox.add_child(preset_buttons)
	
	_create_preset_buttons()

func _create_track_row(track_name: String) -> void:
	# Initialize sequencer data for this track
	sequencer_data[track_name] = []
	for i in range(total_steps):
		sequencer_data[track_name].append(false)
	
	# Track label
	var track_label = Label.new()
	track_label.text = track_name
	track_label.custom_minimum_size = Vector2(100, 30)
	track_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sequencer_grid.add_child(track_label)
	
	# Step buttons
	for step in range(total_steps):
		var step_button = Button.new()
		step_button.toggle_mode = true
		step_button.custom_minimum_size = Vector2(30, 30)
		step_button.pressed.connect(_create_step_toggle_callback(track_name, step))
		sequencer_grid.add_child(step_button)

func _create_step_toggle_callback(track_name: String, step: int) -> Callable:
	return func():
		sequencer_data[track_name][step] = not sequencer_data[track_name][step]
		_update_grid_visuals()

func _update_grid_visuals() -> void:
	var child_index = 0
	for track in drum_tracks:
		child_index += 1  # Skip track label
		for step in range(total_steps):
			var button = sequencer_grid.get_child(child_index) as Button
			if button:
				button.button_pressed = sequencer_data[track][step]
				# Highlight current step
				if is_playing and step == current_step:
					button.modulate = Color(1.2, 1.2, 1.2)
				else:
					button.modulate = Color.WHITE
			child_index += 1

func _create_preset_buttons() -> void:
	var genres = ["TECHNO", "HOUSE", "TRAP", "BREAKBEAT", "MINIMAL"]
	for genre in genres:
		var preset_btn = Button.new()
		preset_btn.text = genre
		preset_btn.pressed.connect(_create_preset_callback(genre))
		preset_buttons.add_child(preset_btn)

func _create_preset_callback(genre: String) -> Callable:
	return func(): _load_genre_preset(genre)

func _load_genre_preset(genre: String) -> void:
	_clear_sequencer()
	
	# Load genre-specific patterns
	match genre.to_upper():
		"TECHNO":
			_load_techno_pattern()
		"HOUSE":
			_load_house_pattern()
		"TRAP":
			_load_trap_pattern()
		"BREAKBEAT":
			_load_breakbeat_pattern()
		"MINIMAL":
			_load_minimal_pattern()
	
	_update_grid_visuals()

func _load_techno_pattern() -> void:
	# Techno: Kick on 1, 5, 9, 13; Hihat on off-beats
	_set_step("KICK", 0, true)
	_set_step("KICK", 4, true)
	_set_step("KICK", 8, true)
	_set_step("KICK", 12, true)
	for i in range(16):
		if i % 2 == 1:
			_set_step("HIHAT", i, true)

func _load_house_pattern() -> void:
	# House: Kick on 1, 5, 9, 13; Snare on 4, 12
	_set_step("KICK", 0, true)
	_set_step("KICK", 4, true)
	_set_step("KICK", 8, true)
	_set_step("KICK", 12, true)
	_set_step("SNARE", 3, true)
	_set_step("SNARE", 11, true)
	for i in range(16):
		if i % 4 == 2:
			_set_step("HIHAT", i, true)

func _load_trap_pattern() -> void:
	# Trap: Kick on 1, 3, 7, 11; Snare on 4, 12
	_set_step("KICK", 0, true)
	_set_step("KICK", 2, true)
	_set_step("KICK", 6, true)
	_set_step("KICK", 10, true)
	_set_step("SNARE", 3, true)
	_set_step("SNARE", 11, true)
	_set_step("HIHAT", 1, true)
	_set_step("HIHAT", 5, true)
	_set_step("HIHAT", 9, true)
	_set_step("HIHAT", 13, true)

func _load_breakbeat_pattern() -> void:
	# Breakbeat: Complex kick pattern
	_set_step("KICK", 0, true)
	_set_step("KICK", 3, true)
	_set_step("KICK", 6, true)
	_set_step("KICK", 10, true)
	_set_step("KICK", 14, true)
	_set_step("SNARE", 4, true)
	_set_step("SNARE", 12, true)

func _load_minimal_pattern() -> void:
	# Minimal: Sparse pattern
	_set_step("KICK", 0, true)
	_set_step("KICK", 8, true)
	_set_step("HIHAT", 4, true)
	_set_step("HIHAT", 12, true)

func _set_step(track: String, step: int, value: bool) -> void:
	if sequencer_data.has(track) and step >= 0 and step < total_steps:
		sequencer_data[track][step] = value

func _setup_audio_players() -> void:
	# Create audio players for each track
	for track in drum_tracks:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		track_players[track] = player
		add_child(player)
	
	# Create melody player
	melody_player = AudioStreamPlayer.new()
	melody_player.bus = "Master"
	add_child(melody_player)

func _load_catalog() -> void:
	catalog_entries.clear()
	entries_by_id.clear()
	_scan_directory("")

func _scan_directory(relative_path: String) -> void:
	var full_path = PARAMETERS_BASE_DIR + relative_path
	var dir = DirAccess.open(full_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var entry_name = dir.get_next()
	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue
		var sub_path = relative_path + entry_name
		if dir.current_is_dir():
			_scan_directory(sub_path + CATEGORY_SEPARATOR)
		elif entry_name.to_lower().ends_with(".json"):
			var entry = _parse_parameter_file(full_path + entry_name, relative_path, entry_name)
			if not entry.is_empty():
				catalog_entries.append(entry)
				entries_by_id[entry["id"]] = entry
		entry_name = dir.get_next()
	dir.list_dir_end()

func _parse_parameter_file(file_path: String, relative_dir: String, file_name: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var json_text = file.get_as_text()
	file.close()
	var parser = JSON.new()
	var parse_error = parser.parse(json_text)
	if parse_error != OK:
		return {}
	var data = parser.data
	var metadata := {}
	var parameters := {}
	if data.has("parameters") and data.has("_metadata"):
		metadata = data.get("_metadata", {})
		parameters = data.get("parameters", {})
	elif _has_nested_parameters(data):
		for key in data.keys():
			if key.begins_with("_"):
				continue
			var payload = data[key]
			if payload is Dictionary and payload.has("parameters"):
				metadata = payload.get("_metadata", {})
				parameters = payload.get("parameters", {})
				break
	else:
		parameters = data
	if parameters.is_empty():
		return {}
	var sound_key = _resolve_sound_key(metadata, file_name, "")
	return {
		"id": relative_dir + file_name,
		"file_path": file_path,
		"sound_key": sound_key,
		"metadata": metadata,
		"parameters": parameters.duplicate(true),
		"raw_data": data
	}

func _has_nested_parameters(data: Dictionary) -> bool:
	for key in data.keys():
		if key.begins_with("_"):
			continue
		var payload = data[key]
		if payload is Dictionary and payload.has("parameters"):
			return true
	return false

func _resolve_sound_key(metadata: Dictionary, file_name: String, nested_key: String) -> String:
	if metadata.has("sound_type"):
		return String(metadata["sound_type"]).to_lower()
	return file_name.get_basename().to_lower()

func _initialize_sequencer() -> void:
	for track in drum_tracks:
		sequencer_data[track] = []
		for i in range(total_steps):
			sequencer_data[track].append(false)
	melody_data.clear()

func _on_play_pressed() -> void:
	if is_playing:
		stop_button.pressed.emit()
	else:
		is_playing = true
		play_button.disabled = true
		stop_button.disabled = false
		current_step = 0
		_start_playback()

func _on_stop_pressed() -> void:
	is_playing = false
	play_button.disabled = false
	stop_button.disabled = true
	current_step = 0
	if step_timer:
		step_timer.stop()
	_stop_playback()
	_update_playhead()

func _on_clear_pressed() -> void:
	_clear_sequencer()
	_update_grid_visuals()

func _on_tempo_changed(value: float) -> void:
	tempo = value
	tempo_label.text = str(int(tempo)) + " BPM"
	# Update timer if playing
	if is_playing and step_timer:
		step_timer.wait_time = 60.0 / (tempo * steps_per_beat)

func _clear_sequencer() -> void:
	for track in sequencer_data.keys():
		for i in range(sequencer_data[track].size()):
			sequencer_data[track][i] = false
	melody_data.clear()

func _start_playback() -> void:
	if not is_playing:
		return
	
	# Create timer for step playback
	if step_timer:
		step_timer.queue_free()
	
	step_timer = Timer.new()
	step_timer.wait_time = 60.0 / (tempo * steps_per_beat)
	step_timer.one_shot = false
	step_timer.timeout.connect(_on_step_timer)
	add_child(step_timer)
	
	_process_step()
	step_timer.start()

func _on_step_timer() -> void:
	if not is_playing:
		return
	current_step = (current_step + 1) % total_steps
	_process_step()
	_update_playhead()

func _process_step() -> void:
	# Play drum tracks
	for track in drum_tracks:
		if sequencer_data.has(track) and sequencer_data[track][current_step]:
			_play_track_sound(track)
	
	# Play melody notes at this step
	for melody_note in melody_data:
		if melody_note.get("step", -1) == current_step:
			_play_melody_note(melody_note)

func _play_track_sound(track: String) -> void:
	if not track_players.has(track):
		return
	
	var player = track_players[track]
	if player.playing:
		player.stop()
	
	# Find appropriate preset for this track
	var entry_id = _find_preset_for_track(track)
	if entry_id.is_empty():
		return
	
	var entry = entries_by_id.get(entry_id, {})
	if entry.is_empty():
		return
	
	var stream = _generate_sound_stream(entry)
	if stream:
		player.stream = stream
		player.play()

func _find_preset_for_track(track: String) -> String:
	# Check if we have a preset assigned
	if preset_entries.has(track):
		return preset_entries[track]
	
	# Try to find a matching preset in catalog
	var track_lower = track.to_lower()
	for entry in catalog_entries:
		var sound_key = entry.get("sound_key", "").to_lower()
		if track_lower.contains(sound_key) or sound_key.contains(track_lower):
			preset_entries[track] = entry["id"]
			return entry["id"]
	
	return ""

func _generate_sound_stream(entry: Dictionary) -> AudioStreamWAV:
	var params = entry.get("parameters", {})
	var sound_key = entry.get("sound_key", "").to_lower()
	
	# Convert parameters to the format expected by generators
	var param_values = {}
	for key in params.keys():
		if params[key] is Dictionary and params[key].has("value"):
			param_values[key] = params[key]["value"]
		else:
			param_values[key] = params[key]
	
	# Detect generator type
	var generator_type = _detect_generator_type(entry)
	
	if generator_type == "TechnoNoir":
		return TechnoNoirGenerator.generate_sound(sound_key, param_values)
	elif generator_type == "TrapBeats":
		return TrapBeatsGenerator.generate_sound(sound_key, param_values)
	elif generator_type == "Cinematic":
		return CinematicMusicGenerator.generate_sound(sound_key, param_values)
	elif generator_type == "Epic":
		return EpicSynthEngine.generate_patch(sound_key, param_values)
	elif generator_type == "SciFi":
		return SciFiPreviewGenerator.generate_preview(sound_key)
	elif generator_type == "Liturgical":
		return _generate_liturgical_sound(sound_key)
	elif generator_type == "Fourier":
		return _generate_fourier_sound(sound_key)
	else:
		var sound_type = _resolve_sound_type(entry)
		if sound_type != null:
			return CustomSoundGenerator.generate_custom_sound(sound_type, param_values)
	
	return null

func _is_trap_beats_sound(sound_key: String) -> bool:
	var trap_sounds = [
		"808_kick", "kick", "bass_drum",
		"trap_snare", "snare",
		"hihat_closed", "hh_closed", "closed_hat",
		"hihat_open", "hh_open", "open_hat",
		"clap", "handclap"
	]
	return sound_key.to_lower() in trap_sounds

func _is_tech_noir_sound(sound_key: String) -> bool:
	var tech_noir_sounds = [
		"endless_drone", "drone",
		"city_ambience", "city", "urban"
	]
	return sound_key.to_lower() in tech_noir_sounds

func _resolve_sound_type(entry: Dictionary):
	var enum_name = entry.get("sound_key", "").to_upper().replace("-", "_").replace(" ", "_")
	if AudioSynthesizer.SoundType.has(enum_name):
		return AudioSynthesizer.SoundType[enum_name]
	return null

func _play_melody_note(melody_note: Dictionary) -> void:
	var entry_id = melody_note.get("preset_id", "")
	if entry_id.is_empty():
		return
	
	var entry = entries_by_id.get(entry_id, {})
	if entry.is_empty():
		return
	
	var stream = _generate_sound_stream(entry)
	if stream:
		melody_player.stream = stream
		melody_player.play()

func _draw_melody_timeline() -> void:
	var rect = Rect2(Vector2.ZERO, melody_timeline.size)
	
	# Draw background
	melody_timeline.draw_rect(rect, Color(0.2, 0.2, 0.2), true)
	
	# Draw grid lines
	var step_width = rect.size.x / float(total_steps)
	for i in range(total_steps + 1):
		var x = i * step_width
		var color = Color(0.4, 0.4, 0.4) if i % 4 == 0 else Color(0.3, 0.3, 0.3)
		melody_timeline.draw_line(Vector2(x, 0), Vector2(x, rect.size.y), color, 1.0)
	
	# Draw playhead
	if is_playing:
		var playhead_x = current_step * step_width
		melody_timeline.draw_line(
			Vector2(playhead_x, 0),
			Vector2(playhead_x, rect.size.y),
			Color(1.0, 0.5, 0.0),
			2.0
		)
	
	# Draw melody notes
	for melody_note in melody_data:
		var step = melody_note.get("step", 0)
		var x = step * step_width
		var note_rect = Rect2(x + 2, 10, step_width - 4, rect.size.y - 20)
		melody_timeline.draw_rect(note_rect, Color(0.4, 0.7, 1.0), true)
		melody_timeline.draw_rect(note_rect, Color(0.2, 0.5, 0.8), false, 2.0)
		
		var note_text = melody_note.get("note", "")
		if note_text != "":
			# Draw note text using theme font
			var font = ThemeDB.fallback_font
			var font_size = ThemeDB.fallback_font_size
			if font:
				melody_timeline.draw_string(
					font,
					Vector2(x + 5, rect.size.y / 2),
					note_text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_size,
					Color.WHITE
				)

func _update_playhead() -> void:
	if melody_timeline:
		melody_timeline.queue_redraw()
	# Also update grid to show current step
	_update_grid_visuals()

func _stop_playback() -> void:
	for player in track_players.values():
		if player.playing:
			player.stop()
	if melody_player.playing:
		melody_player.stop()

func _detect_generator_type(entry: Dictionary) -> String:
	# 1. Check explicit metadata
	if entry.get("metadata", {}).has("generator"):
		return entry["metadata"]["generator"]

	# 2. Check directory structure
	var relative_dir = entry.get("id", "") # Sequencer uses ID as relative path
	if relative_dir.begins_with("tech_noir"): return "TechnoNoir"
	if relative_dir.begins_with("trap_beats"): return "TrapBeats"
	if relative_dir.begins_with("cinematic"): return "Cinematic"
	if relative_dir.begins_with("epic"): return "Epic"
	if relative_dir.begins_with("sci_fi"): return "SciFi"
	if relative_dir.begins_with("liturgical"): return "Liturgical"
	if relative_dir.begins_with("fourier"): return "Fourier"

	# 3. Check sound key (Legacy)
	var key = entry.get("sound_key", "")
	if _is_tech_noir_sound(key): return "TechnoNoir"
	if _is_trap_beats_sound(key): return "TrapBeats"
	
	if key in ["blade_runner_pad", "vangelis_brass_lead", "hans_zimmer_braam"]: return "Cinematic"
	if key in ["epic_brass_swarm", "trailer_rise"]: return "Epic"
	if key in ["space_ambience", "dystopian_alarm"]: return "SciFi"
	if key in ["cathedral_bell", "pipe_organ_swell", "sacred_whisper", "gregorian_phrase"]: return "Liturgical"

	return "Default"

func _generate_liturgical_sound(sound_key: String) -> AudioStreamWAV:
	var lit_gen = LiturgicalAmbientGenerator.new()
	match sound_key.to_lower():
		"cathedral_bell", "cathedral_bells": return lit_gen.create_cathedral_bell()
		"pipe_organ_swell": return lit_gen.create_pipe_organ_swell()
		"sacred_whisper", "sacred_whispers": return lit_gen.create_sacred_whisper()
		"choral_texture", "angelic_texture": return lit_gen.create_angelic_texture()
		"gregorian_phrase": return lit_gen.create_gregorian_phrase()
		"divine_breath": return lit_gen.create_divine_breath()
		_: return lit_gen.create_angelic_texture()

func _generate_fourier_sound(sound_key: String) -> AudioStreamWAV:
	var gen = FourierSpaceGenerator.new()
	match sound_key.to_lower():
		"drone":
			var wheels = [
				{"freq": 1.0, "radius": 2.0, "phase": 0.0},
				{"freq": 3.0, "radius": 0.8, "phase": 0.0},
				{"freq": 5.0, "radius": 0.4, "phase": PI / 2},
				{"freq": 7.0, "radius": 0.2, "phase": PI / 4}
			]
			return gen.create_fourier_drone(wheels)
		"nebula": return gen.create_nebula_pad()
		_: return gen.create_fourier_drone([])
