# SongPreviewDesktop.gd
# Standalone desktop scene for previewing full interactive songs
# Now with timeline, annotations, and parameter display for discussing sounds

extends Control

var _player: AudioStreamPlayer
var _current_song: String = ""
var _is_playing: bool = false
var _current_stream: AudioStreamInteractive = null

var _title_label: Label
var _status_label: Label
var _song_buttons: Dictionary = {}
var _play_btn: Button
var _stop_btn: Button
var _export_btn: Button
var _midi_export_btn: Button
var _stem_editor_btn: Button
var _section_label: Label
var _stem_editor: Control = null

# Timeline component
var _timeline: SongTimeline
var _timeline_container: PanelContainer
var _show_timeline: bool = true

# Song metadata for timeline (maps song_id to metadata)
var _song_metadata: Dictionary = {}


func _ready():
	get_tree().root.title = "AdaResearch Song Preview"
	_setup_ui()
	_setup_audio()
	print("Song Preview ready - click a song to generate and play!")


func _setup_audio():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.finished.connect(_on_song_finished)
	add_child(_player)


func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 20)
	add_child(vbox)
	
	# Title
	_title_label = Label.new()
	_title_label.text = "🎹 SONG PREVIEW"
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Full procedural songs with multiple sections"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	# === SCROLLABLE SONG GRID ===
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 3  # 3 columns of cards
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	
	# Song buttons - 18 full songs including hybrids!
	var songs = [
		["chromatic_story", "🎹 Chromatic Story", "Jazz → Pop emotional journey"],
		["nineties_rnb", "🎵 90s R&B", "Dm slow jam - Rhodes + 808"],
		["computer_love", "🤖 Computer Love", "Kraftwerk - robotic romance"],
		["aphex_twin_digital_amber", "💛 Digital Amber", "Aphex Twin - SAW meets Syro"],
		["ada_theme", "🎤 Ada Theme", "Warm backing for Ada voice"],
		["prog_synth_70s", "🎸 70s Prog", "ELP, Kraftwerk, Yes"],
		["pop_generative", "🎤 Pop Gen", "Verse-Chorus structure"],
		["ambient_works", "🌊 Ambient", "Aphex Twin style"],
		["i_feel_love", "💜 I Feel Love", "Donna Summer + synth voice"],
		["detroit_techno", "🔩 Detroit", "Cold machine funk"],
		["midnight_metroplex", "🌃 Metroplex", "909 + 808 researched"],
		["synthwave", "🌆 Synthwave", "80s gated drums"],
		["rave", "⚡ Rave", "Breakbeats + hoover"],
		["replicants_dawn", "🌅 Replicant", "Vangelis × Detroit"],
		["foggy_frequencies", "🌫️ Foggy", "BoC × Burial"],
		["chicago_dusseldorf", "🚂 Chi→Düss", "House × Kraftwerk"],
		["dub_house_sb", "Dub House", "Dub chord stabs + tape space"],
		["moroder_disco", "🪩 Moroder", "Instrumental version"],
		["k_bass", "🇰🇷 K-Bass", "Seoul jungle/DnB - sub pressure"]
	]
	
	for song in songs:
		var song_card = _create_song_card(song[0], song[1], song[2])
		grid.add_child(song_card)
	
	# Control buttons
	var controls = HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 20)
	vbox.add_child(controls)
	
	_play_btn = Button.new()
	_play_btn.text = "  ⏸ PAUSE  "
	_play_btn.disabled = true
	_play_btn.pressed.connect(_toggle_pause)
	_style_button(_play_btn, Color(0.5, 0.4, 0.2))
	controls.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "  ⏹ STOP  "
	_stop_btn.disabled = true
	_stop_btn.pressed.connect(_stop_song)
	_style_button(_stop_btn, Color(0.6, 0.2, 0.2))
	controls.add_child(_stop_btn)
	
	_export_btn = Button.new()
	_export_btn.text = "  💾 EXPORT WAV  "
	_export_btn.disabled = true
	_export_btn.pressed.connect(_export_wav)
	_style_button(_export_btn, Color(0.3, 0.4, 0.6))
	controls.add_child(_export_btn)
	
	# MIDI Export button
	var midi_btn = Button.new()
	midi_btn.text = "  🎹 MIDI  "
	midi_btn.disabled = true
	midi_btn.pressed.connect(_export_midi)
	_style_button(midi_btn, Color(0.4, 0.35, 0.5))
	controls.add_child(midi_btn)
	_midi_export_btn = midi_btn
	
	# Stem Editor button
	var stem_btn = Button.new()
	stem_btn.text = "  🎚️ STEMS  "
	stem_btn.disabled = true
	stem_btn.pressed.connect(_open_stem_editor)
	_style_button(stem_btn, Color(0.35, 0.45, 0.4))
	controls.add_child(stem_btn)
	_stem_editor_btn = stem_btn
	
	# Status
	_status_label = Label.new()
	_status_label.text = "Select a song to generate..."
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)
	
	# Section label (shows current section)
	_section_label = Label.new()
	_section_label.text = ""
	_section_label.add_theme_font_size_override("font_size", 20)
	_section_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.4))
	_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_section_label)
	
	# === TIMELINE PANEL ===
	_timeline_container = PanelContainer.new()
	var tl_style = StyleBoxFlat.new()
	tl_style.bg_color = Color(0.08, 0.08, 0.1)
	tl_style.border_color = Color(0.2, 0.2, 0.25)
	tl_style.set_border_width_all(1)
	tl_style.set_corner_radius_all(8)
	tl_style.content_margin_left = 16
	tl_style.content_margin_right = 16
	tl_style.content_margin_top = 12
	tl_style.content_margin_bottom = 12
	_timeline_container.add_theme_stylebox_override("panel", tl_style)
	_timeline_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_timeline_container.custom_minimum_size.y = 300
	_timeline_container.visible = false  # Hidden until song loads
	vbox.add_child(_timeline_container)
	
	_timeline = SongTimeline.new()
	_timeline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_timeline.seek_requested.connect(_on_timeline_seek)
	_timeline_container.add_child(_timeline)


func _create_song_box(id: String, title: String, desc: String) -> Control:
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.border_color = Color(0.2, 0.2, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	box.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	box.add_child(hbox)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	text_vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	text_vbox.add_child(desc_lbl)
	
	var play_btn = Button.new()
	play_btn.text = "  ▶ PLAY  "
	play_btn.pressed.connect(_on_song_selected.bind(id))
	_style_button(play_btn, Color(0.2, 0.5, 0.3))
	hbox.add_child(play_btn)
	
	_song_buttons[id] = play_btn
	
	return box


func _create_song_card(id: String, title: String, desc: String) -> Control:
	"""Compact card for grid layout"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.border_color = Color(0.25, 0.25, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	# Title
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	vbox.add_child(title_lbl)
	
	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)
	
	# Play button
	var play_btn = Button.new()
	play_btn.text = "▶ PLAY"
	play_btn.pressed.connect(_on_song_selected.bind(id))
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_card_button(play_btn)
	vbox.add_child(play_btn)
	
	_song_buttons[id] = play_btn
	
	return card


func _style_card_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.45, 0.3)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 14)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.25, 0.55, 0.35)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.15, 0.35, 0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var disabled = style.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.2)
	btn.add_theme_stylebox_override("disabled", disabled)


func _style_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var disabled = style.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.2)
	btn.add_theme_stylebox_override("disabled", disabled)


func _on_song_selected(song_id: String):
	_stop_song()
	_current_song = song_id
	_status_label.text = "Generating " + song_id + "... (this may take a moment)"
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	# Disable all play buttons during generation
	for btn in _song_buttons.values():
		btn.disabled = true
	
	# Generate async
	call_deferred("_generate_and_play", song_id)


func _generate_and_play(song_id: String):
	var stream: AudioStream = null
	
	match song_id:
		"chromatic_story":
			stream = SoundbankGenerator.generate_song("chromatic_story", {"bpm": 100})
		"nineties_rnb":
			stream = SoundbankGenerator.generate_song("nineties_rnb", {"bpm": 92})
		"computer_love":
			stream = SoundbankGenerator.generate_song("kraftwerk", {"bpm": 129})
		"aphex_twin_digital_amber":
			stream = SoundbankGenerator.generate_song("aphex_twin", {"bpm": 108})
		"ada_theme":
			stream = SoundbankGenerator.generate_song("ada_theme", {"bpm": 100})
		"prog_synth_70s":
			stream = AudioSynthesizer.generate_prog_synth_song({})
		"pop_generative":
			stream = AudioSynthesizer.generate_pop_interactive_song({})
		"ambient_works":
			stream = AudioSynthesizer.generate_ambient_works_song({})
		"moroder_disco":
			stream = AudioSynthesizer.generate_moroder_disco_song({})
		"detroit_techno":
			stream = AudioSynthesizer.generate_detroit_techno_song({})
		"midnight_metroplex":
			stream = SoundbankGenerator.generate_song("detroit_techno", {})
		"synthwave":
			stream = AudioSynthesizer.generate_synthwave_song({})
		"rave":
			stream = AudioSynthesizer.generate_rave_song({})
		# === NEW: I Feel Love with singing ===
		"i_feel_love":
			stream = SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})
		"moroder_disco":
			stream = SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})
		# === HYBRID SONGS ===
		"replicants_dawn":
			stream = SoundbankGenerator.generate_hybrid_song("replicants_dawn", {})
		"foggy_frequencies":
			stream = SoundbankGenerator.generate_hybrid_song("foggy_frequencies", {})
		"chicago_dusseldorf":
			stream = SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", {})
		"dub_house_sb":
			stream = SoundbankGenerator.generate_song("dub_house", {"bpm": 122})
		"k_bass":
			stream = SoundbankGenerator.generate_song("k_bass", {"bpm": 170})
	
	if stream == null:
		_status_label.text = "Failed to generate song!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_enable_buttons()
		_timeline_container.visible = false
		return
	
	_current_stream = stream as AudioStreamInteractive
	_player.stream = stream
	_player.play()
	_is_playing = true
	
	_status_label.text = "Now playing: " + song_id
	_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_play_btn.disabled = false
	_play_btn.text = "  ⏸ PAUSE  "
	_stop_btn.disabled = false
	_export_btn.disabled = false
	_midi_export_btn.disabled = false
	_stem_editor_btn.disabled = false
	_enable_buttons()
	
	# Load timeline with song metadata
	_load_timeline_for_song(song_id, stream)
	_timeline_container.visible = true


func _toggle_pause():
	if _player.stream_paused:
		# Resume
		_player.stream_paused = false
		_play_btn.text = "  ⏸ PAUSE  "
		_status_label.text = "Playing: " + _current_song
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		_timeline.set_playing(true)
	else:
		# Pause
		_player.stream_paused = true
		_play_btn.text = "  ▶ RESUME  "
		_status_label.text = "Paused: " + _current_song
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		_timeline.set_playing(false)


func _stop_song():
	_player.stop()
	_player.stream_paused = false
	_is_playing = false
	_current_stream = null
	_status_label.text = "Stopped"
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_play_btn.text = "  ⏸ PAUSE  "
	_play_btn.disabled = true
	_stop_btn.disabled = true
	_export_btn.disabled = true
	_midi_export_btn.disabled = true
	_stem_editor_btn.disabled = true
	_section_label.text = ""
	_timeline.set_current_time(0.0)
	_timeline.set_playing(false)


func _on_song_finished():
	_is_playing = false
	_status_label.text = "Finished"
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_play_btn.disabled = true
	_play_btn.text = "  ⏸ PAUSE  "
	_stop_btn.disabled = true
	# Keep export/midi/stems enabled after finished - user may want to export
	_section_label.text = ""
	_timeline.set_playing(false)


func _export_wav():
	"""Export current song to WAV file"""
	if _player.stream == null:
		_status_label.text = "No song to export!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = _current_song + "_" + timestamp + ".wav"
	var export_path = "user://exports/"
	
	# Ensure export directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_path))
	
	var full_path = export_path + filename
	
	_status_label.text = "Exporting..."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_export_btn.disabled = true
	
	# Use SongExporter if available
	if ClassDB.class_exists("SongExporter") or ResourceLoader.exists("res://commons/audio/generators/SongExporter.gd"):
		call_deferred("_do_export", full_path)
	else:
		# Fallback: export the stream directly if it's a WAV
		_export_stream_directly(full_path)


func _do_export(path: String):
	var result = SongExporter.export_interactive_to_wav(_current_stream, path)
	if result == OK:
		var global_path = ProjectSettings.globalize_path(path)
		_status_label.text = "Exported: " + global_path
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		print("Song exported to: ", global_path)
	else:
		_status_label.text = "Export failed!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_export_btn.disabled = false


func _export_stream_directly(path: String):
	"""Fallback export for non-interactive streams"""
	if _player.stream is AudioStreamWAV:
		var wav: AudioStreamWAV = _player.stream
		var err = wav.save_to_wav(path)
		if err == OK:
			var global_path = ProjectSettings.globalize_path(path)
			_status_label.text = "Exported: " + global_path
			_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			_status_label.text = "Export failed!"
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_status_label.text = "Cannot export this stream type directly"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	_export_btn.disabled = false


func _export_midi():
	"""Export current song patterns to MIDI file"""
	if _current_song.is_empty():
		_status_label.text = "No song selected!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = _current_song + "_" + timestamp + ".mid"
	var export_path = "user://exports/"
	
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_path))
	
	var full_path = export_path + filename
	var bpm = _get_song_bpm(_current_song)
	
	_status_label.text = "Exporting MIDI..."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_midi_export_btn.disabled = true
	
	call_deferred("_do_midi_export", full_path, bpm)


func _do_midi_export(path: String, bpm: float):
	"""Perform MIDI export"""
	# Map song IDs to pattern IDs (some songs use different pattern names)
	var pattern_id = _current_song
	match _current_song:
		"midnight_metroplex":
			pattern_id = "detroit_techno"
		"computer_love":
			pattern_id = "kraftwerk"
		"aphex_twin_digital_amber":
			pattern_id = "boards_of_canada"  # Using closest match
		"i_feel_love":
			pattern_id = "moroder_disco"
		"dub_house_sb":
			pattern_id = "dub_house"
	
	if MidiExporter.export_song(pattern_id, path, {"bpm": bpm, "bars": 4}):
		var global_path = ProjectSettings.globalize_path(path)
		_status_label.text = "MIDI exported: " + global_path
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		print("MIDI exported to: ", global_path)
	else:
		_status_label.text = "MIDI export failed!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	_midi_export_btn.disabled = false


func _open_stem_editor():
	"""Open the stem editor for current song"""
	if _current_song.is_empty():
		_status_label.text = "No song selected!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	
	# Pause current playback
	if _is_playing:
		_player.stream_paused = true
		_play_btn.text = "  ▶ RESUME  "
		_timeline.set_playing(false)
	
	# Create stem editor
	var StemEditorScene = load("res://commons/audio/catalog/StemEditor.tscn")
	_stem_editor = StemEditorScene.instantiate()
	_stem_editor.editor_closed.connect(_on_stem_editor_closed)
	add_child(_stem_editor)
	
	# Map song ID to pattern ID
	var pattern_id = _current_song
	match _current_song:
		"midnight_metroplex":
			pattern_id = "detroit_techno"
		"computer_love":
			pattern_id = "kraftwerk"
		"aphex_twin_digital_amber":
			pattern_id = "boards_of_canada"
		"i_feel_love":
			pattern_id = "moroder_disco"
		"dub_house_sb":
			pattern_id = "dub_house"
	
	var bpm = _get_song_bpm(_current_song)
	_stem_editor.load_song(pattern_id, bpm)
	
	_status_label.text = "Editing stems for: " + _current_song
	_status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))


func _on_stem_editor_closed():
	"""Handle stem editor closing"""
	_stem_editor = null
	_status_label.text = "Stem editor closed"
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))


func _get_song_bpm(song_id: String) -> float:
	"""Get the BPM for a song"""
	var bpm_map = {
		"chromatic_story": 100.0,
		"nineties_rnb": 92.0,
		"computer_love": 129.0,
		"aphex_twin_digital_amber": 108.0,
		"ada_theme": 100.0,
		"prog_synth_70s": 110.0,
		"pop_generative": 118.0,
		"ambient_works": 90.0,
		"moroder_disco": 126.0,
		"detroit_techno": 126.0,
		"midnight_metroplex": 126.0,
		"synthwave": 118.0,
		"rave": 145.0,
		"i_feel_love": 126.0,
		"replicants_dawn": 120.0,
		"foggy_frequencies": 130.0,
		"chicago_dusseldorf": 122.0,
		"dub_house_sb": 122.0,
		"k_bass": 170.0,
	}
	return bpm_map.get(song_id, 120.0)


func _enable_buttons():
	for btn in _song_buttons.values():
		btn.disabled = false


func _process(_delta):
	if _is_playing and _player.playing:
		# Update timeline playhead
		var pos = _player.get_playback_position()
		_timeline.set_current_time(pos)


func _on_timeline_seek(time: float):
	"""Handle seek from timeline click"""
	if _player.stream:
		_player.seek(time)
		_timeline.set_current_time(time)


func _load_timeline_for_song(song_id: String, stream: AudioStream):
	"""Load detailed metadata for the timeline"""
	
	# If it's an interactive stream, extract sections automatically
	if stream is AudioStreamInteractive:
		var metadata = _get_song_metadata(song_id, stream as AudioStreamInteractive)
		_timeline.load_song_metadata(metadata)
	else:
		# Simple stream - just show duration
		_timeline.load_song_metadata({
			"name": song_id,
			"sections": [{"name": "Full Track", "start": 0.0, "end": stream.get_length(), "layers": []}],
			"total_duration": stream.get_length()
		})


func _get_song_metadata(song_id: String, stream: AudioStreamInteractive) -> Dictionary:
	"""Build detailed metadata for a song including layers and parameters"""
	
	var metadata = {
		"name": song_id,
		"sections": [],
		"total_duration": 0.0
	}
	
	var clip_count = stream.clip_count
	var time_offset = 0.0
	
	# Get detailed layer info based on song type
	var song_layers = _get_layers_for_song(song_id)
	
	for i in range(clip_count):
		var clip_name = stream.get_clip_name(i)
		var clip_stream = stream.get_clip_stream(i)
		var duration = 8.0
		
		if clip_stream:
			duration = clip_stream.get_length()
		
		# Get layers for this section
		var section_layers = song_layers.get(clip_name.to_lower(), song_layers.get("default", []))
		
		metadata["sections"].append({
			"name": clip_name if clip_name else "Section %d" % (i + 1),
			"start": time_offset,
			"end": time_offset + duration,
			"index": i,
			"layers": section_layers
		})
		
		time_offset += duration
	
	metadata["total_duration"] = time_offset
	return metadata


func _get_layers_for_song(song_id: String) -> Dictionary:
	"""Return detailed layer/parameter info per section for each song type"""
	
	match song_id:
		"chromatic_story":
			return {
				"uncertainty": [
					{"name": "Jazz Pad", "type": "pad", "params": "warm | slow attack | Am atmosphere"},
					{"name": "Walking Bass", "type": "bass", "params": "upright style | chromatic walk A→G→F→E"},
				],
				"searching": [
					{"name": "Jazz Pad", "type": "pad", "params": "exploratory"},
					{"name": "Walking Bass", "type": "bass", "params": "ii-V-I motion"},
					{"name": "Rhodes Piano", "type": "keys", "params": "jazz voicings | warm bell"},
					{"name": "Brush Hi-Hat", "type": "drums", "params": "swung 8ths | soft"},
				],
				"darkness": [
					{"name": "Jazz Pad", "type": "pad", "params": "tension building"},
					{"name": "Walking Bass", "type": "bass", "params": "chromatic descent"},
					{"name": "Rhodes Piano", "type": "keys", "params": "E7#9 Hendrix chord | moll/dur clash"},
					{"name": "Soft Kick", "type": "drums", "params": "acoustic feel"},
					{"name": "Brush Snare", "type": "drums", "params": "whispered"},
				],
				"hope": [
					{"name": "Jazz Pad", "type": "pad", "params": "opening up | C major light"},
					{"name": "Walking Bass", "type": "bass", "params": "bass walk C→B→A→G"},
					{"name": "Gentle Arpeggio", "type": "seq", "params": "shimmering | hopeful"},
					{"name": "Brush Hi-Hat", "type": "drums", "params": "light groove"},
				],
				"jazz": [
					{"name": "Rhodes Piano", "type": "keys", "params": "Dm9→G13→Cmaj9→A7alt | full extensions"},
					{"name": "Walking Bass", "type": "bass", "params": "jazz walking | chromatic approach"},
					{"name": "Soft Kick", "type": "drums", "params": "jazz club"},
					{"name": "Brush Hi-Hat", "type": "drums", "params": "swung | intricate"},
					{"name": "Rimshot", "type": "drums", "params": "woody click | jazz touch"},
				],
				"breakthrough": [
					{"name": "Jazz Pad", "type": "pad", "params": "triumphant | full"},
					{"name": "Walking Bass", "type": "bass", "params": "driving"},
					{"name": "Rhodes Piano", "type": "keys", "params": "clean triads | liberating"},
					{"name": "Full Kit", "type": "drums", "params": "kick + snare + hihat"},
					{"name": "Gentle Arpeggio", "type": "seq", "params": "celebratory"},
				],
				"resolution": [
					{"name": "Jazz Pad", "type": "pad", "params": "peaceful | settling"},
					{"name": "Walking Bass", "type": "bass", "params": "I-V-vi-IV | pop resolution"},
					{"name": "Rhodes Piano", "type": "keys", "params": "warm | earned"},
					{"name": "Soft Kit", "type": "drums", "params": "kick + hihat | gentle"},
				],
				"celebration": [
					{"name": "Jazz Pad", "type": "pad", "params": "fadeout | warm 7ths"},
					{"name": "Walking Bass", "type": "bass", "params": "home | settled"},
					{"name": "Gentle Arpeggio", "type": "seq", "params": "fading | joyful"},
				],
				"default": [{"name": "Chromatic Story", "type": "mix", "params": "100 BPM | Am→C | jazz brain, pop heart"}]
			}
		
		"nineties_rnb":
			return {
				"intro": [
					{"name": "Rhodes EP", "type": "keys", "params": "tremolo 5.5Hz | warm | Dm9 floating"},
					{"name": "Silky Pad", "type": "pad", "params": "6-voice detuned | slow attack"},
					{"name": "Light Percussion", "type": "drums", "params": "shaker 16ths | setting mood"},
				],
				"verse1": [
					{"name": "Rhodes EP", "type": "keys", "params": "jazz voicings | i7-v7-bVImaj7"},
					{"name": "Silky Pad", "type": "pad", "params": "warm support"},
					{"name": "Moog Sub Bass", "type": "bass", "params": "deep round | filter envelope"},
					{"name": "808 Kick", "type": "drums", "params": "55Hz | 500ms decay | deep"},
					{"name": "Snare+Clap", "type": "drums", "params": "layered | 2&4"},
					{"name": "Swung Hi-Hat", "type": "drums", "params": "15% swing | New Jack feel"},
				],
				"prechorus1": [
					{"name": "Rhodes EP", "type": "keys", "params": "building | bVImaj9 descent"},
					{"name": "Lush Strings", "type": "pad", "params": "swelling | vibrato"},
					{"name": "Moog Sub Bass", "type": "bass", "params": "chromatic walk Bb→A→G"},
					{"name": "Full Kit", "type": "drums", "params": "intensifying | fingersnaps 2&4"},
				],
				"chorus1": [
					{"name": "Rhodes EP", "type": "keys", "params": "full voicings | Dm9-Gm9-Bbmaj7"},
					{"name": "Silky Pad", "type": "pad", "params": "wide | euphoric"},
					{"name": "Lush Strings", "type": "pad", "params": "90s string machine"},
					{"name": "Moog Sub Bass", "type": "bass", "params": "driving | octaves"},
					{"name": "Full Kit", "type": "drums", "params": "808 + clap + swung hats"},
					{"name": "Synth Stabs", "type": "lead", "params": "filtered | rhythmic"},
				],
				"bridge": [
					{"name": "Rhodes EP", "type": "keys", "params": "Ebmaj7 key shift | chromatic"},
					{"name": "Lush Strings", "type": "pad", "params": "emotional peak"},
					{"name": "Moog Sub Bass", "type": "bass", "params": "Db7 tritone sub | sophisticated"},
					{"name": "Full Kit", "type": "drums", "params": "building to peak"},
				],
				"outro": [
					{"name": "Rhodes EP", "type": "keys", "params": "vamp | Dm9-Gm9 loop"},
					{"name": "Silky Pad", "type": "pad", "params": "fading"},
					{"name": "Moog Sub Bass", "type": "bass", "params": "settling"},
					{"name": "Sparse Kit", "type": "drums", "params": "winding down | could loop forever"},
				],
				"default": [{"name": "90s R&B", "type": "mix", "params": "85 BPM | Dm | silky smooth"}]
			}
		
		"computer_love":
			return {
				"intro": [
					{"name": "Kraftwerk Arpeggio", "type": "seq", "params": "F-A-C-F ascending | pulse wave | ZERO detune | 2500Hz filter"},
				],
				"verse": [
					{"name": "Kraftwerk Arpeggio", "type": "seq", "params": "iconic pattern | mechanical precision"},
					{"name": "Motorik Kick", "type": "drums", "params": "4-on-floor | unwavering | 129 BPM"},
					{"name": "Motorik Snare", "type": "drums", "params": "backbeat 2 & 4 | electronic"},
					{"name": "Motorik Hi-Hat", "type": "drums", "params": "driving 8ths | machine perfect"},
					{"name": "Kraftwerk Bass", "type": "bass", "params": "clean sine | root following | 2¢ drift max"},
					{"name": "Kraftwerk Pad", "type": "pad", "params": "warm strings | vocoder-style | 6 voices"},
				],
				"chorus": [
					{"name": "Kraftwerk Lead", "type": "lead", "params": "melodic theme | triangle+square | 50ms portamento"},
					{"name": "Kraftwerk Arpeggio", "type": "seq", "params": "foundation | hypnotic"},
					{"name": "Full Motorik Drums", "type": "drums", "params": "kick + snare + hihat | robotic"},
					{"name": "Kraftwerk Bass", "type": "bass", "params": "locked to kick"},
					{"name": "Kraftwerk Pad", "type": "pad", "params": "full warmth | supporting"},
				],
				"breakdown": [
					{"name": "Kraftwerk Pad", "type": "pad", "params": "exposed | emotional machine"},
					{"name": "Kraftwerk Arpeggio", "type": "seq", "params": "solo | melancholic"},
				],
				"outro": [
					{"name": "Kraftwerk Arpeggio", "type": "seq", "params": "fading | digital loneliness"},
					{"name": "Kraftwerk Pad", "type": "pad", "params": "long release | acceptance"},
				],
				"default": [{"name": "Computer Love", "type": "mix", "params": "129 BPM | F Major | robotic romance"}]
			}
		
		"ada_theme":
			return {
				"intro": [
					{"name": "Warm Pad", "type": "pad", "params": "5 voices | ±8 cents detune | LPF 2kHz | slow attack"},
				],
				"verse": [
					{"name": "Warm Pad", "type": "pad", "params": "supportive | leaves space for vocal"},
					{"name": "Sine Bass", "type": "bass", "params": "deep | sustained root notes"},
					{"name": "Soft Drums", "type": "drums", "params": "minimal | pillow kick | brush snare"},
				],
				"chorus": [
					{"name": "Warm Pad", "type": "pad", "params": "fuller | filter opening"},
					{"name": "Sine Bass", "type": "bass", "params": "following chords"},
					{"name": "Gentle Arp", "type": "seq", "params": "twinkling | up-down | delay"},
					{"name": "Soft Drums", "type": "drums", "params": "adding hi-hat"},
				],
				"bridge": [
					{"name": "Warm Pad", "type": "pad", "params": "extended chords | dreamy"},
					{"name": "Gentle Arp", "type": "seq", "params": "exposed | reverb"},
				],
				"outro": [
					{"name": "Warm Pad", "type": "pad", "params": "fade | long release"},
				],
				"default": [{"name": "Ada Theme", "type": "mix", "params": "100 BPM | A major | space for vocals"}]
			}
		
		"prog_synth_70s":
			return {
				"intro": [
					{"name": "Moog Pad", "type": "pad", "params": "voices: 7 | detune: ±10 cents | filter: LPF 2kHz | attack: 2s"},
				],
				"verse": [
					{"name": "Moog Pad", "type": "pad", "params": "filter: LPF sweep 500-2kHz"},
					{"name": "Minimoog Bass", "type": "bass", "params": "osc: saw+square | glide: 50ms | filter: 24dB LPF"},
					{"name": "Motorik Drums", "type": "drums", "params": "pattern: 4/4 NEU! style | tempo: 110 BPM"},
				],
				"build": [
					{"name": "Moog Pad", "type": "pad", "params": "filter: opening"},
					{"name": "Minimoog Bass", "type": "bass", "params": "filter: resonant sweep"},
					{"name": "Kraftwerk Seq", "type": "seq", "params": "16th notes | filter: LPF+resonance | pattern: arpeggiated"},
					{"name": "Motorik Drums", "type": "drums", "params": "pattern: driving"},
				],
				"solo": [
					{"name": "ELP Lead", "type": "lead", "params": "osc: saw | portamento: 80ms | vibrato: 5Hz ±20 cents | filter: bandpass"},
					{"name": "Moog Pad", "type": "pad", "params": "sustained bed"},
					{"name": "Minimoog Bass", "type": "bass", "params": "following root"},
					{"name": "Motorik Drums", "type": "drums", "params": "fills | driving"},
				],
				"outro": [
					{"name": "Moog Pad", "type": "pad", "params": "fade out | filter closing"},
					{"name": "Kraftwerk Seq", "type": "seq", "params": "fading | filter closing"},
				],
				"default": [{"name": "Mix", "type": "mix", "params": ""}]
			}
		
		"ambient_works":
			return {
				"intro": [
					{"name": "Tape Keys", "type": "keys", "params": "FM piano | lo-fi tape saturation | wow/flutter"},
					{"name": "Tape Noise", "type": "noise", "params": "pink noise | filtered | subtle crackle"},
				],
				"build": [
					{"name": "Tape Keys", "type": "keys", "params": "sustained chords"},
					{"name": "Warm Pad", "type": "pad", "params": "voices: 5 | detuned | slow attack | chorus"},
					{"name": "Acid Bass", "type": "bass", "params": "303 style | resonant filter | accent"},
					{"name": "Breakbeat", "type": "drums", "params": "Amen break | lo-fi | timestretched"},
					{"name": "Tape Hiss", "type": "noise", "params": "constant bed"},
				],
				"main": [
					{"name": "Tape Keys", "type": "keys", "params": "melodic phrases"},
					{"name": "Warm Pad", "type": "pad", "params": "evolving | filter sweep"},
					{"name": "Acid Bass", "type": "bass", "params": "squelchy | 16th patterns"},
					{"name": "Breakbeat", "type": "drums", "params": "full groove | chopped"},
					{"name": "Atmosphere", "type": "noise", "params": "vinyl crackle | room tone"},
				],
				"outro": [
					{"name": "Warm Pad", "type": "pad", "params": "fade | long release"},
					{"name": "Tape Noise", "type": "noise", "params": "fading"},
				],
				"default": [{"name": "Ambient Texture", "type": "pad", "params": ""}]
			}
		
		"moroder_disco":
			return {
				"intro": [
					{"name": "Hi-Hat Pattern", "type": "drums", "params": "16th notes | 909 open/closed"},
					{"name": "Filter Sweep", "type": "pad", "params": "rising | resonant"},
				],
				"verse": [
					{"name": "Sequencer", "type": "seq", "params": "16th Moog | hypnotic pattern | filter modulation"},
					{"name": "Four-on-Floor", "type": "drums", "params": "kick every beat | hi-hat 16ths | clap on 2&4"},
					{"name": "Disco Bass", "type": "bass", "params": "octave jumps | Moog style"},
				],
				"chorus": [
					{"name": "Sequencer", "type": "seq", "params": "filter fully open"},
					{"name": "Disco Strings", "type": "pad", "params": "lush | string machine | sustained"},
					{"name": "Bass", "type": "bass", "params": "driving octaves"},
					{"name": "Full Drums", "type": "drums", "params": "fills | tom rolls"},
				],
				"breakdown": [
					{"name": "Sequencer Solo", "type": "seq", "params": "exposed | filter sweep"},
					{"name": "Hi-Hats Only", "type": "drums", "params": "16ths building"},
				],
				"default": [{"name": "Disco Mix", "type": "mix", "params": ""}]
			}
		
		"detroit_techno":
			return {
				"intro": [
					{"name": "Machine Pad", "type": "pad", "params": "cold | digital | slow attack"},
					{"name": "Hi-Hats", "type": "drums", "params": "909 | offbeat open hats"},
				],
				"verse": [
					{"name": "Techno Stab", "type": "lead", "params": "short decay | filtered | rhythmic"},
					{"name": "Sub Bass", "type": "bass", "params": "sine sub | 808 style"},
					{"name": "909 Kit", "type": "drums", "params": "kick | snare | hats | ride"},
					{"name": "Machine Pad", "type": "pad", "params": "background texture"},
				],
				"main": [
					{"name": "Strings", "type": "pad", "params": "Detroit strings | lush but cold"},
					{"name": "Bass Sequence", "type": "bass", "params": "funky | syncopated"},
					{"name": "Full Drums", "type": "drums", "params": "driving | machine funk"},
					{"name": "Stabs", "type": "lead", "params": "chord stabs | gated"},
				],
				"breakdown": [
					{"name": "Strings", "type": "pad", "params": "exposed | emotional"},
					{"name": "Minimal Drums", "type": "drums", "params": "kick + ride only"},
				],
				"default": [{"name": "Detroit Mix", "type": "mix", "params": ""}]
			}
		
		"midnight_metroplex":
			return {
				"intro": [
					{"name": "Digital Pad", "type": "pad", "params": "Juno-106 DCO | ZERO detune | filter 3500Hz | cold"},
				],
				"build": [
					{"name": "Digital Pad", "type": "pad", "params": "sustained | clean"},
					{"name": "808 Sub Bass", "type": "bass", "params": "sine+square | 150Hz cutoff | +3dB sub"},
					{"name": "909 Hi-Hat", "type": "drums", "params": "6-oscillator metallic | 263-845Hz | offbeat"},
				],
				"main": [
					{"name": "909 Kick", "type": "drums", "params": "130→50Hz pitch | 25ms decay | click transient"},
					{"name": "909 Snare", "type": "drums", "params": "dual-osc 180+330Hz | ring-mod character"},
					{"name": "909 Hi-Hat", "type": "drums", "params": "6-osc metallic synthesis"},
					{"name": "909 Clap", "type": "drums", "params": "4-burst layered | 12ms spacing"},
					{"name": "808 Sub", "type": "bass", "params": "locked to kick | deep sub"},
					{"name": "Digital Pad", "type": "pad", "params": "Juno DCO | stable pitch | cold"},
					{"name": "FM Stab", "type": "lead", "params": "DX7 Alg.5 | mod ratio 3.0 | metallic"},
				],
				"breakdown": [
					{"name": "Digital Pad", "type": "pad", "params": "exposed | atmospheric"},
					{"name": "808 Sub", "type": "bass", "params": "minimal | breathing room"},
				],
				"outro": [
					{"name": "Digital Pad", "type": "pad", "params": "fade | filter closing"},
					{"name": "909 Hi-Hat", "type": "drums", "params": "fading metallic"},
				],
				"default": [{"name": "Midnight Metroplex", "type": "mix", "params": "126 BPM | Am | machine precision"}]
			}
		
		"dub_house_sb":
			return {
				"intro": [
					{"name": "Pad", "type": "pad", "params": "warm bed | slow attack"},
					{"name": "Siren Drone", "type": "pad", "params": "cinematic | slow sweep"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat | low intensity"},
				],
				"build": [
					{"name": "Kick", "type": "drums", "params": "deep 4-on-floor"},
					{"name": "Sub Bass", "type": "bass", "params": "round | sustained"},
					{"name": "Pad", "type": "pad", "params": "wide | distant"},
					{"name": "Siren Drone", "type": "pad", "params": "long sweep | distant"},
				],
				"main": [
					{"name": "Kick", "type": "drums", "params": "deep"},
					{"name": "Snare", "type": "drums", "params": "short | airy"},
					{"name": "Clap", "type": "drums", "params": "roomy"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat swing"},
					{"name": "Dub Stab", "type": "keys", "params": "filtered | delay tails"},
					{"name": "Sub Bass", "type": "bass", "params": "sub-forward"},
					{"name": "Pad", "type": "pad", "params": "warm support"},
				],
				"breakdown": [
					{"name": "Dub Stab", "type": "keys", "params": "space and decay"},
					{"name": "Pad", "type": "pad", "params": "long release"},
					{"name": "Siren Drone", "type": "pad", "params": "slow rise | cinematic"},
				],
				"drop": [
					{"name": "Kick", "type": "drums", "params": "deep"},
					{"name": "Snare", "type": "drums", "params": "short"},
					{"name": "Clap", "type": "drums", "params": "roomy"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat"},
					{"name": "Dub Stab", "type": "keys", "params": "tape-delay"},
					{"name": "Sub Bass", "type": "bass", "params": "pulse"},
				],
				"outro": [
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat"},
					{"name": "Pad", "type": "pad", "params": "fade"},
					{"name": "Siren Drone", "type": "pad", "params": "distant | tail"},
				],
				"default": [{"name": "Dub House", "type": "mix", "params": "122 BPM | minor/dorian"}]
			}
		
		"i_feel_love", "moroder_disco":
			return {
				"intro": [
					{"name": "Space Pad", "type": "pad", "params": "ARP Odyssey | reverb | slow filter"},
					{"name": "16th Sequencer", "type": "seq", "params": "Moog | constant 16ths | THE motor"},
				],
				"build": [
					{"name": "16th Sequencer", "type": "seq", "params": "filter opening"},
					{"name": "Space Pad", "type": "pad", "params": "building"},
					{"name": "Hi-Hat", "type": "drums", "params": "constant 16ths | driving"},
					{"name": "Minimoog Bass", "type": "bass", "params": "pulsing | follows root"},
				],
				"main": [
					{"name": "4-on-Floor Kick", "type": "drums", "params": "CR-78 | punchy | foundation"},
					{"name": "Hi-Hat", "type": "drums", "params": "relentless 16ths"},
					{"name": "16th Sequencer", "type": "seq", "params": "hypnotic | never stops"},
					{"name": "Minimoog Bass", "type": "bass", "params": "locked to root"},
					{"name": "Space Pad", "type": "pad", "params": "floating above"},
				],
				"vocal": [
					{"name": "Donna Summer Voice", "type": "vocal", "params": "breathy | high | 'I feel love'"},
					{"name": "Full Groove", "type": "drums", "params": "kick + hihat + sequencer"},
					{"name": "Bass", "type": "bass", "params": "pulsing foundation"},
				],
				"breakdown": [
					{"name": "16th Sequencer", "type": "seq", "params": "exposed | filter sweep"},
					{"name": "Space Pad", "type": "pad", "params": "ethereal | building tension"},
				],
				"drop": [
					{"name": "Full Kit", "type": "drums", "params": "kick + snare + hihat"},
					{"name": "16th Sequencer", "type": "seq", "params": "filter fully open"},
					{"name": "Bass", "type": "bass", "params": "driving"},
					{"name": "Space Pad", "type": "pad", "params": "euphoric"},
					{"name": "Donna Summer Voice", "type": "vocal", "params": "ecstatic | repeating"},
				],
				"outro": [
					{"name": "Space Pad", "type": "pad", "params": "fading"},
					{"name": "16th Sequencer", "type": "seq", "params": "filter closing"},
					{"name": "Donna Summer Voice", "type": "vocal", "params": "fading 'love...'"},
				],
				"default": [{"name": "I Feel Love", "type": "mix", "params": "126 BPM | Cmaj | Donna Summer × Moroder"}]
			}
		
		"synthwave":
			return {
				"intro": [
					{"name": "Arpeggio", "type": "seq", "params": "Juno-style | 16th notes | chorus"},
					{"name": "Gated Reverb", "type": "drums", "params": "snare only | 80s gated reverb"},
				],
				"verse": [
					{"name": "Arpeggio", "type": "seq", "params": "driving pattern"},
					{"name": "Bass", "type": "bass", "params": "saw bass | sidechained | pumping"},
					{"name": "80s Drums", "type": "drums", "params": "LinnDrum style | gated snare | electronic toms"},
					{"name": "Pad", "type": "pad", "params": "lush | detuned | slow filter"},
				],
				"chorus": [
					{"name": "Lead", "type": "lead", "params": "detuned saw | vibrato | delay"},
					{"name": "Power Chords", "type": "pad", "params": "stacked fifths | distorted"},
					{"name": "Bass", "type": "bass", "params": "octave pattern"},
					{"name": "Full Drums", "type": "drums", "params": "tom fills | crash cymbals"},
				],
				"bridge": [
					{"name": "Pad Only", "type": "pad", "params": "atmospheric | reverb wash"},
					{"name": "Arpeggio", "type": "seq", "params": "filtered down"},
				],
				"default": [{"name": "Synthwave Mix", "type": "mix", "params": ""}]
			}
		
		"rave":
			return {
				"intro": [
					{"name": "Build Noise", "type": "noise", "params": "white noise sweep | rising"},
					{"name": "Kick Teaser", "type": "drums", "params": "sparse kicks | building"},
				],
				"verse": [
					{"name": "Breakbeat", "type": "drums", "params": "chopped breaks | Amen/Think | 140+ BPM"},
					{"name": "Hoover Bass", "type": "bass", "params": "saw stack | PWM | pitch bend | MASSIVE"},
					{"name": "Stabs", "type": "lead", "params": "short | filtered | rhythmic"},
				],
				"drop": [
					{"name": "Breakbeat", "type": "drums", "params": "full force | fills | rolls"},
					{"name": "Hoover", "type": "bass", "params": "screaming | filter open"},
					{"name": "Rave Stab", "type": "lead", "params": "classic Mentasm | chord stabs"},
					{"name": "Vocal Chop", "type": "vocal", "params": "chopped 'yeah' | pitched"},
				],
				"breakdown": [
					{"name": "Pad", "type": "pad", "params": "dreamy | reverb"},
					{"name": "Vocal", "type": "vocal", "params": "pitched sample | ethereal"},
					{"name": "Build Noise", "type": "noise", "params": "rising for next drop"},
				],
				"default": [{"name": "Rave Mix", "type": "mix", "params": ""}]
			}
		
		"pop_generative":
			return {
				"intro": [
					{"name": "Pad", "type": "pad", "params": "soft | filtered | establishing key"},
				],
				"verse": [
					{"name": "Bass", "type": "bass", "params": "synth bass | root notes | simple pattern"},
					{"name": "Keys", "type": "keys", "params": "electric piano | chord stabs"},
					{"name": "Drums", "type": "drums", "params": "basic pattern | kick-snare"},
				],
				"chorus": [
					{"name": "Bass", "type": "bass", "params": "busier pattern | octaves"},
					{"name": "Keys", "type": "keys", "params": "fuller voicings"},
					{"name": "Pad", "type": "pad", "params": "lush | supporting"},
					{"name": "Lead", "type": "lead", "params": "melodic hook | catchy"},
					{"name": "Drums", "type": "drums", "params": "full kit | energy"},
				],
				"default": [{"name": "Pop Mix", "type": "mix", "params": ""}]
			}
		
		# === HYBRID SONGS ===
		
		"replicants_dawn":
			return {
				"intro": [
					{"name": "VP-330 Choir", "type": "pad", "params": "ethereal | slow attack | Vangelis signature"},
					{"name": "Prophet Pad", "type": "pad", "params": "warm analog | sustained"},
				],
				"build": [
					{"name": "CS-80 Strings", "type": "pad", "params": "lush | dual filter sweep"},
					{"name": "Jupiter Arpeggio", "type": "seq", "params": "shimmering | 16th notes"},
					{"name": "Prophet Pad", "type": "pad", "params": "bed layer"},
				],
				"main": [
					{"name": "909 Kick", "type": "drums", "params": "4-on-floor | Detroit precision"},
					{"name": "909 Hi-Hat", "type": "drums", "params": "offbeat | metallic"},
					{"name": "808 Sub", "type": "bass", "params": "locked to kick | deep"},
					{"name": "CS-80 Brass", "type": "lead", "params": "expressive | aftertouch | wide intervals"},
					{"name": "Prophet Pad", "type": "pad", "params": "foundation"},
				],
				"breakdown": [
					{"name": "Prophet Pad", "type": "pad", "params": "exposed | emotional"},
					{"name": "909 Snare", "type": "drums", "params": "ghost hits | sparse"},
				],
				"climax": [
					{"name": "909 Full Kit", "type": "drums", "params": "kick + snare + hihat + clap"},
					{"name": "808 Sub", "type": "bass", "params": "driving"},
					{"name": "CS-80 Lead", "type": "lead", "params": "soaring | vibrato | high register"},
					{"name": "CS-80 Strings", "type": "pad", "params": "swelling"},
					{"name": "VP-330 Choir", "type": "pad", "params": "triumphant"},
				],
				"outro": [
					{"name": "VP-330 Choir", "type": "pad", "params": "fading | ethereal"},
					{"name": "Prophet Pad", "type": "pad", "params": "single note | fade"},
				],
				"default": [{"name": "Replicant's Dawn", "type": "mix", "params": "120 BPM | Dm | Vangelis × Detroit"}]
			}
		
		"foggy_frequencies":
			return {
				"intro": [
					{"name": "BoC Texture", "type": "noise", "params": "tape hiss | warped | nostalgic"},
					{"name": "Vinyl Crackle", "type": "noise", "params": "Burial signature | 3am vibes"},
				],
				"build": [
					{"name": "BoC Sequence", "type": "seq", "params": "detuned | pitch drift | 8th notes"},
					{"name": "BoC Pad", "type": "pad", "params": "warm | lo-fi | slow filter"},
					{"name": "Burial Atmosphere", "type": "pad", "params": "reverb wash | nocturnal"},
				],
				"main": [
					{"name": "2-Step Kick", "type": "drums", "params": "displaced | never on beat 1"},
					{"name": "2-Step Snare", "type": "drums", "params": "ghost notes | shuffled"},
					{"name": "Shuffled Hi-Hat", "type": "drums", "params": "swung | varying velocity"},
					{"name": "BoC Pad", "type": "pad", "params": "nostalgic bed"},
					{"name": "BoC Bass", "type": "bass", "params": "warm | sparse"},
				],
				"breakdown": [
					{"name": "Burial Vocal", "type": "vocal", "params": "pitched | reverb | ghostly"},
					{"name": "BoC Sequence", "type": "seq", "params": "exposed | haunting"},
					{"name": "Vinyl Crackle", "type": "noise", "params": "intimate"},
				],
				"outro": [
					{"name": "BoC Texture", "type": "noise", "params": "fading memories"},
					{"name": "Vinyl Crackle", "type": "noise", "params": "fade to silence"},
				],
				"default": [{"name": "Foggy Frequencies", "type": "mix", "params": "130 BPM | Fm | BoC × Burial"}]
			}
		
		"aphex_twin", "aphex_twin_digital_amber":
			return {
				"intro": [
					{"name": "Tape Texture", "type": "noise", "params": "hiss | warmth | memory surface"},
					{"name": "Warm Pad", "type": "pad", "params": "detuned ±8 cents | SAW85 character | filter sweep"},
				],
				"build": [
					{"name": "Warm Pad", "type": "pad", "params": "evolving | LFO drift 0.08Hz"},
					{"name": "Sub Bass", "type": "bass", "params": "sine | gentle pulse"},
					{"name": "Hi-Hat Pattern", "type": "drums", "params": "sparse | humanized | emerging from noise"},
					{"name": "Sequence", "type": "seq", "params": "bell-like | detuned fifths"},
				],
				"main": [
					{"name": "Kick", "type": "drums", "params": "pillow 808 | warm punch"},
					{"name": "Snare", "type": "drums", "params": "lo-fi breakbeat | ghost notes"},
					{"name": "Hi-Hat", "type": "drums", "params": "intricate | velocity variation"},
					{"name": "Acid Bass", "type": "bass", "params": "303 squelch | resonant filter"},
					{"name": "Warm Pad", "type": "pad", "params": "wooly nostalgic"},
					{"name": "Lead", "type": "lead", "params": "detuned fifth | RDJ signature"},
					{"name": "Tape Texture", "type": "noise", "params": "constant warmth"},
				],
				"breakdown": [
					{"name": "Prepared Piano", "type": "keys", "params": "Avril 14th intimacy | muted strings"},
					{"name": "Granular Pad", "type": "pad", "params": "fractured | crystalline"},
					{"name": "Ghostly Vocal", "type": "vocal", "params": "pitched | reverb heavy | human traces"},
					{"name": "Field Recording", "type": "noise", "params": "distant children | fragments of world"},
				],
				"outro": [
					{"name": "Warm Pad", "type": "pad", "params": "filter closing | amber hardens"},
					{"name": "Tape Texture", "type": "noise", "params": "returning | fade to silence"},
					{"name": "Vinyl Crackle", "type": "noise", "params": "memory surface noise"},
				],
				"default": [{"name": "Digital Amber", "type": "mix", "params": "108 BPM | F#m | SAW meets Syro"}]
			}
		
		"chicago_dusseldorf":
			return {
				"intro": [
					{"name": "House Piano", "type": "keys", "params": "jazz voicings | soulful | warm"},
					{"name": "House Organ", "type": "keys", "params": "sustained | filter sweep"},
					{"name": "House Pad", "type": "pad", "params": "establishing mood"},
				],
				"verse": [
					{"name": "House Kick", "type": "drums", "params": "4-on-floor | bouncy"},
					{"name": "House Clap", "type": "drums", "params": "2 and 4 | punchy"},
					{"name": "Motorik Hi-Hat", "type": "drums", "params": "8th notes | transitioning"},
					{"name": "Chicago Bass", "type": "bass", "params": "offbeat | bouncy | short notes"},
					{"name": "House Piano", "type": "keys", "params": "offbeat stabs | THE sound"},
				],
				"transition": [
					{"name": "House Piano", "type": "keys", "params": "fading | morphing"},
					{"name": "Kraftwerk Sequence", "type": "seq", "params": "emerging | cold | precise"},
				],
				"robotic": [
					{"name": "Motorik Kick", "type": "drums", "params": "unwavering | machine"},
					{"name": "Motorik Hi-Hat", "type": "drums", "params": "perfect 8ths | no variation"},
					{"name": "Kraftwerk Snare", "type": "drums", "params": "electronic | precise"},
					{"name": "Chicago Bass", "type": "bass", "params": "now locked to kick"},
					{"name": "Kraftwerk Vocoder", "type": "vocal", "params": "'Trans Europa' | robotic"},
				],
				"breakdown": [
					{"name": "House Piano", "type": "keys", "params": "ghost | memory of soul"},
					{"name": "Kraftwerk Pad", "type": "pad", "params": "cold | digital"},
				],
				"finale": [
					{"name": "Hybrid Drums", "type": "drums", "params": "kick + hihat + clap"},
					{"name": "House Organ", "type": "keys", "params": "stabs | hybrid groove"},
					{"name": "Kraftwerk Sequence", "type": "seq", "params": "driving | hypnotic"},
					{"name": "Kraftwerk Vocoder", "type": "vocal", "params": "full robotic choir"},
				],
				"outro": [
					{"name": "Kraftwerk Sequence", "type": "seq", "params": "mechanical | fading"},
					{"name": "Kraftwerk Pad", "type": "pad", "params": "cold ending"},
				],
				"default": [{"name": "Chicago → Düsseldorf", "type": "mix", "params": "122 BPM | Am | House × Kraftwerk"}]
			}
		
		_:
			return {"default": [{"name": "Audio", "type": "mix", "params": ""}]}
