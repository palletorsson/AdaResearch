# AIAssistantPanel.gd
# AI Assistant panel for SongDevTools — chat interface, live state display,
# and file-based communication protocol for external AI agents.
# Built entirely in code (no .tscn).

extends Control

# ── External References (set by SongDevTools after creation) ───────────
var midi_editor: MidiPianoRoll = null
var song_dev_tools = null  # SongDevTools instance

# ── Theme Colors ───────────────────────────────────────────────────────
const COL_BG           = Color(0.12, 0.12, 0.15)
const COL_PANEL        = Color(0.16, 0.16, 0.19)
const COL_TEXT         = Color(0.85, 0.85, 0.85)
const COL_HEADER       = Color(0.5, 0.7, 1.0)
const COL_ACCENT       = Color(0.35, 0.55, 0.9)
const COL_USER_BUBBLE  = Color(0.2, 0.25, 0.35)
const COL_ASST_BUBBLE  = Color(0.18, 0.22, 0.18)
const COL_INPUT_BG     = Color(0.1, 0.1, 0.13)
const COL_INPUT_BORDER = Color(0.25, 0.27, 0.35)
const COL_MUTED        = Color(0.6, 0.3, 0.3)
const COL_SOLO         = Color(0.9, 0.75, 0.2)
const COL_DIM_TEXT     = Color(0.5, 0.5, 0.55)

# ── File Paths ─────────────────────────────────────────────────────────
const STATE_PATH    = "user://ai_state.json"
const CHAT_PATH     = "user://ai_chat.json"
const RESPONSE_PATH = "user://ai_response.json"

# ── Throttle / Polling ─────────────────────────────────────────────────
const STATE_WRITE_INTERVAL := 0.25  # max 4/second
const RESPONSE_POLL_INTERVAL := 1.0

var _state_write_cooldown: float = 0.0
var _response_poll_cooldown: float = 0.0
var _last_response_mod_time: int = 0

# ── Cached state for dirty detection ──────────────────────────────────
var _last_playing: bool = false
var _last_track_idx: int = -1
var _last_selected_count: int = 0
var _last_bar: int = -1
var _last_section: String = ""
var _last_view_bar: int = -1

# ── Chat History ───────────────────────────────────────────────────────
var _chat_messages: Array[Dictionary] = []  # [{role, text, timestamp}]

# ── UI Nodes ───────────────────────────────────────────────────────────
var _main_vbox: VBoxContainer

# Top section: live state
var _state_panel: PanelContainer
var _song_name_label: Label
var _section_label: Label
var _position_label: Label
var _playback_state_label: Label
var _bpm_label: Label

# Middle section: selected track info
var _track_panel: PanelContainer
var _track_name_label: Label
var _note_info_label: Label
var _synth_params_label: Label

# Mix overview
var _mix_panel: PanelContainer
var _mix_container: HBoxContainer
var _mix_labels: Array[Label] = []

# JSON spec panel
var _json_panel: PanelContainer
var _json_spec_label: RichTextLabel
var _json_toggle_btn: Button
var _json_collapsed: bool = true
var _last_json_song_id: String = ""
const SONGS_PATH = "res://commons/audio/parameters/songs/"

# Chat section
var _chat_panel: PanelContainer
var _chat_scroll: ScrollContainer
var _chat_vbox: VBoxContainer
var _context_bar: HFlowContainer
var _ctx_position_btn: Button
var _ctx_track_btn: Button
var _ctx_section_btn: Button
var _ctx_song_btn: Button
var _ctx_selection_btn: Button
var _word_bar: HFlowContainer
var _word_buttons: Array[Button] = []
var _last_word_track: String = ""
var _last_word_song: String = ""
var _input_hbox: HBoxContainer
var _input_field: LineEdit
var _send_btn: Button


# ── Lifecycle ──────────────────────────────────────────────────────────

func _ready():
	clip_contents = true
	_build_ui()
	# Ensure user:// directory exists for state files
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))


func _process(delta: float):
	_update_live_state_display()
	_check_state_dirty_and_write(delta)
	_poll_response_file(delta)


# ── UI Construction ────────────────────────────────────────────────────

func _build_ui():
	# Full-rect background
	var bg = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main vertical layout
	_main_vbox = VBoxContainer.new()
	_main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 10)
	_main_vbox.add_theme_constant_override("separation", 8)
	add_child(_main_vbox)

	_build_state_section()
	_build_track_section()
	_build_mix_section()
	_build_json_spec_section()
	_build_chat_section()


func _build_state_section():
	"""Live playback state display (top)"""
	_state_panel = _make_section_panel()
	_main_vbox.add_child(_state_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_state_panel.add_child(vbox)

	var header = _make_header("▶  LIVE STATE")
	vbox.add_child(header)

	# Row 1: Song name + Section
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 16)
	vbox.add_child(row1)

	_song_name_label = _make_value_label("No song loaded")
	_song_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(_song_name_label)

	_section_label = _make_value_label("")
	row1.add_child(_section_label)

	# Row 2: Position + State + BPM
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	vbox.add_child(row2)

	_position_label = _make_value_label("Bar — Beat —")
	_position_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_position_label)

	_playback_state_label = _make_value_label("⏹ Stopped")
	row2.add_child(_playback_state_label)

	_bpm_label = _make_value_label("")
	row2.add_child(_bpm_label)


func _build_track_section():
	"""Selected track / note info (middle)"""
	_track_panel = _make_section_panel()
	_main_vbox.add_child(_track_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_track_panel.add_child(vbox)

	var header = _make_header("🎹  SELECTED TRACK")
	vbox.add_child(header)

	_track_name_label = _make_value_label("No selection")
	vbox.add_child(_track_name_label)

	_note_info_label = _make_value_label("")
	_note_info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_note_info_label)

	_synth_params_label = _make_value_label("")
	_synth_params_label.add_theme_font_size_override("font_size", 11)
	_synth_params_label.add_theme_color_override("font_color", COL_DIM_TEXT)
	_synth_params_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_synth_params_label)


func _build_mix_section():
	"""Compact mix overview row"""
	_mix_panel = _make_section_panel()
	_main_vbox.add_child(_mix_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_mix_panel.add_child(vbox)

	var header = _make_header("🎚️  MIX OVERVIEW")
	vbox.add_child(header)

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 32
	vbox.add_child(scroll)

	_mix_container = HBoxContainer.new()
	_mix_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_mix_container)


func _build_json_spec_section():
	"""Collapsible panel showing current track's JSON spec data"""
	_json_panel = _make_section_panel()
	_main_vbox.add_child(_json_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_json_panel.add_child(vbox)

	# Header row with toggle
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var header = _make_header("📋  TRACK JSON SPEC")
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header)

	_json_toggle_btn = Button.new()
	_json_toggle_btn.text = "▶ Show"
	_json_toggle_btn.custom_minimum_size = Vector2(70, 24)
	_json_toggle_btn.pressed.connect(_on_json_toggle)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.22, 0.28)
	btn_style.set_corner_radius_all(4)
	btn_style.content_margin_left = 8
	btn_style.content_margin_right = 8
	_json_toggle_btn.add_theme_stylebox_override("normal", btn_style)
	_json_toggle_btn.add_theme_font_size_override("font_size", 11)
	_json_toggle_btn.add_theme_color_override("font_color", COL_DIM_TEXT)
	header_row.add_child(_json_toggle_btn)

	# Spec content (hidden by default)
	_json_spec_label = RichTextLabel.new()
	_json_spec_label.bbcode_enabled = true
	_json_spec_label.fit_content = true
	_json_spec_label.scroll_active = false
	_json_spec_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_json_spec_label.add_theme_font_size_override("normal_font_size", 11)
	_json_spec_label.add_theme_color_override("default_color", COL_TEXT)
	_json_spec_label.visible = false
	vbox.add_child(_json_spec_label)


func _on_json_toggle():
	_json_collapsed = not _json_collapsed
	_json_spec_label.visible = not _json_collapsed
	_json_toggle_btn.text = "▼ Hide" if not _json_collapsed else "▶ Show"
	if not _json_collapsed:
		_refresh_json_spec()


func _refresh_json_spec():
	"""Load and display the current track's JSON spec summary"""
	var song_id := ""
	if song_dev_tools:
		song_id = song_dev_tools._current_song_id if not song_dev_tools._current_song_id.is_empty() else song_dev_tools._current_song
	if song_id.is_empty():
		_json_spec_label.text = "No song loaded"
		return

	_last_json_song_id = song_id

	# Try loading the JSON file
	var json_path = SONGS_PATH + song_id + ".json"
	if not FileAccess.file_exists(json_path):
		_json_spec_label.text = "No JSON spec found: " + song_id + ".json"
		return

	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		_json_spec_label.text = "Cannot read: " + json_path
		return

	var json = JSON.new()
	var content = file.get_as_text()
	file.close()

	if json.parse(content) != OK:
		_json_spec_label.text = "JSON parse error"
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}

	# Build summary
	var lines: PackedStringArray = []

	# Metadata
	var meta = data.get("_metadata", {})
	if meta:
		var display = meta.get("display_name", song_id)
		var bpm_val = meta.get("bpm", "?")
		lines.append("[color=#80b0ff]%s[/color]  •  %s BPM" % [display, str(bpm_val)])
		var refs = meta.get("reference_artists", [])
		if refs.size() > 0:
			lines.append("[color=#888]Ref: %s[/color]" % ", ".join(PackedStringArray(refs)))

	# Chord progressions
	var chords = data.get("chord_progressions", {})
	if chords.size() > 0:
		var names = PackedStringArray(chords.keys())
		lines.append("\n[color=#80ff80]♯ Chords:[/color] %d (%s)" % [chords.size(), ", ".join(names)])
	else:
		lines.append("\n[color=#ff8080]♯ Chords:[/color] none")

	# Patterns
	var patterns = data.get("patterns", {})
	if patterns.size() > 0:
		var pat_names = PackedStringArray(patterns.keys())
		var total_instruments := 0
		for pname in patterns:
			if patterns[pname] is Dictionary:
				total_instruments += patterns[pname].size()
		lines.append("[color=#80ff80]🥁 Patterns:[/color] %d (%d instruments)" % [patterns.size(), total_instruments])
	else:
		lines.append("[color=#ff8080]🥁 Patterns:[/color] none — uses hardcoded fallback")

	# Bass patterns
	var bass = data.get("bass_patterns", {})
	if bass.size() > 0:
		lines.append("[color=#80ff80]🎸 Bass patterns:[/color] %d" % bass.size())
	else:
		lines.append("[color=#ff8080]🎸 Bass patterns:[/color] none")

	# Arp patterns
	var arps = data.get("arp_patterns", {})
	if arps.size() > 0:
		lines.append("[color=#80ff80]🎹 Arp patterns:[/color] %d" % arps.size())
	else:
		lines.append("[color=#888]🎹 Arp patterns:[/color] none")

	# Melodies
	var melody = data.get("melody", {})
	if melody.size() > 0:
		var mel_names = PackedStringArray(melody.keys())
		lines.append("[color=#80ff80]🎵 Melodies:[/color] %d (%s)" % [melody.size(), ", ".join(mel_names)])
	else:
		lines.append("[color=#ff8080]🎵 Melodies:[/color] none")

	# Arrangement
	var arr = data.get("arrangement", {})
	var sections = arr.get("sections", [])
	if sections.size() > 0:
		var key = arr.get("key", "?")
		var scale = arr.get("scale", "?")
		var total_bars := 0
		var section_names: PackedStringArray = []
		for sec in sections:
			total_bars += sec.get("bars", 0)
			section_names.append(sec.get("name", "?"))
		lines.append("\n[color=#80ff80]📐 Arrangement:[/color] %s %s • %d sections • %d bars" % [key, scale, sections.size(), total_bars])
		lines.append("[color=#888]  %s[/color]" % " → ".join(section_names))
	else:
		lines.append("\n[color=#ff8080]📐 Arrangement:[/color] none")

	# Groove
	var groove = data.get("groove", {})
	if groove.size() > 0:
		var swing = groove.get("swing", 0)
		var humanize = groove.get("humanize_ms", 0)
		lines.append("[color=#80ff80]🔄 Groove:[/color] swing %.0f%% • humanize %dms" % [swing * 100, humanize])

	# Sound design
	var sd = data.get("sound_design", {})
	if sd.size() > 0:
		lines.append("[color=#80ff80]🔊 Sound design:[/color] %d sections" % sd.size())

	_json_spec_label.text = "\n".join(lines)


func _build_chat_section():
	"""Chat interface (bottom, expands to fill)"""
	_chat_panel = _make_section_panel()
	_chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_vbox.add_child(_chat_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chat_panel.add_child(vbox)

	var header = _make_header("💬  CHAT WITH ADA")
	vbox.add_child(header)

	# Scrollable message history
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(_chat_scroll)

	_chat_vbox = VBoxContainer.new()
	_chat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_vbox.add_theme_constant_override("separation", 6)
	_chat_scroll.add_child(_chat_vbox)

	# Welcome message
	_add_chat_bubble("assistant", "Hi! I'm Ada, your AI music assistant. Tell me what you'd like to change about the current song, and I'll help.")

	# Context buttons — click to append context tags to your message
	_context_bar = HFlowContainer.new()
	_context_bar.add_theme_constant_override("h_separation", 4)
	_context_bar.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_context_bar)

	var ctx_label = Label.new()
	ctx_label.text = "Add context:"
	ctx_label.add_theme_font_size_override("font_size", 11)
	ctx_label.add_theme_color_override("font_color", COL_DIM_TEXT)
	_context_bar.add_child(ctx_label)

	_ctx_position_btn = _make_context_button("📍 Position")
	_ctx_position_btn.pressed.connect(_on_ctx_position)
	_context_bar.add_child(_ctx_position_btn)

	_ctx_track_btn = _make_context_button("🎹 Track")
	_ctx_track_btn.pressed.connect(_on_ctx_track)
	_context_bar.add_child(_ctx_track_btn)

	_ctx_section_btn = _make_context_button("§ Section")
	_ctx_section_btn.pressed.connect(_on_ctx_section)
	_context_bar.add_child(_ctx_section_btn)

	_ctx_song_btn = _make_context_button("🎵 Song")
	_ctx_song_btn.pressed.connect(_on_ctx_song)
	_context_bar.add_child(_ctx_song_btn)

	_ctx_selection_btn = _make_context_button("🎯 Selection")
	_ctx_selection_btn.pressed.connect(_on_ctx_selection)
	_context_bar.add_child(_ctx_selection_btn)

	# Sound word buttons — populated from song_words based on current track
	_word_bar = HFlowContainer.new()
	_word_bar.add_theme_constant_override("h_separation", 3)
	_word_bar.add_theme_constant_override("v_separation", 3)
	vbox.add_child(_word_bar)

	# Input row
	_input_hbox = HBoxContainer.new()
	_input_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(_input_hbox)

	_input_field = LineEdit.new()
	_input_field.placeholder_text = "Type a message... (e.g. 'make the bass darker')"
	_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_field.custom_minimum_size.y = 36
	_input_field.text_submitted.connect(_on_text_submitted)
	_style_input_field(_input_field)
	_input_hbox.add_child(_input_field)

	_send_btn = Button.new()
	_send_btn.text = "Send ➤"
	_send_btn.custom_minimum_size = Vector2(80, 36)
	_send_btn.pressed.connect(_on_send_pressed)
	_style_send_button(_send_btn)
	_input_hbox.add_child(_send_btn)


# ── Live State Update (every frame during playback) ────────────────────

func _update_live_state_display():
	if song_dev_tools == null:
		return

	# Song name
	var song_id: String = song_dev_tools._current_song_id if not song_dev_tools._current_song_id.is_empty() else song_dev_tools._current_song
	if song_id.is_empty():
		_song_name_label.text = "No song loaded"
	else:
		_song_name_label.text = "♪ " + song_id.replace("_", " ").capitalize()

	# Auto-refresh JSON spec when song changes
	if song_id != _last_json_song_id and not _json_collapsed:
		_refresh_json_spec()

	# Playback state
	var is_playing: bool = song_dev_tools._is_playing and song_dev_tools._player.playing
	var is_paused: bool = song_dev_tools._player.stream_paused if song_dev_tools._player else false

	if is_playing and not is_paused:
		_playback_state_label.text = "▶ Playing"
		_playback_state_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	elif is_paused:
		_playback_state_label.text = "⏸ Paused"
		_playback_state_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.2))
	else:
		_playback_state_label.text = "⏹ Stopped"
		_playback_state_label.add_theme_color_override("font_color", COL_DIM_TEXT)

	# BPM
	var bpm := 0.0
	if midi_editor:
		bpm = midi_editor._bpm
	if bpm > 0:
		_bpm_label.text = "%d BPM" % int(bpm)
	else:
		_bpm_label.text = ""

	# Section
	var section_name: String = song_dev_tools._current_section_name if song_dev_tools else ""
	if not section_name.is_empty():
		_section_label.text = "§ " + section_name
		_section_label.add_theme_color_override("font_color", COL_HEADER)
	else:
		_section_label.text = ""

	# Bar / Beat position
	if midi_editor and midi_editor._is_playing:
		var ticks_per_bar: int = midi_editor._ticks_per_quarter * 4
		var ticks_per_beat: int = midi_editor._ticks_per_quarter
		var bar: int = midi_editor._playback_tick / ticks_per_bar + 1
		var beat: int = (midi_editor._playback_tick % ticks_per_bar) / ticks_per_beat + 1
		_position_label.text = "Bar %d  Beat %d" % [bar, beat]
	elif song_dev_tools and song_dev_tools._playback_time > 0:
		# Estimate from SongDevTools playback time
		var est_bpm = bpm if bpm > 0 else 120.0
		var beats = song_dev_tools._playback_time * est_bpm / 60.0
		var bar = int(beats / 4) + 1
		var beat = int(fmod(beats, 4.0)) + 1
		_position_label.text = "Bar %d  Beat %d" % [bar, beat]
	else:
		_position_label.text = "Bar —  Beat —"

	# --- Selected Track Info ---
	_update_track_info()

	# --- Mix Overview ---
	_update_mix_overview()

	# --- Context Buttons ---
	_update_context_buttons()

	# --- Sound Word Buttons ---
	_update_word_buttons()


func _update_track_info():
	if midi_editor == null:
		_track_name_label.text = "No MIDI editor"
		_note_info_label.text = ""
		_synth_params_label.text = ""
		return

	var tracks: Array = midi_editor._tracks
	var track_idx: int = midi_editor._current_track

	if tracks.is_empty() or track_idx < 0 or track_idx >= tracks.size():
		_track_name_label.text = "No selection"
		_note_info_label.text = ""
		_synth_params_label.text = ""
		return

	var track: Dictionary = tracks[track_idx]
	var track_name: String = track.get("name", "Track %d" % (track_idx + 1))
	var program: int = track.get("program", 0)
	var is_drum: bool = track.get("is_drum", false)
	var channel: int = track.get("channel", 0)

	# Track header
	var type_str = "🥁 Drums" if is_drum else "🎹 Ch.%d  Prog.%d" % [channel, program]
	_track_name_label.text = "%s  (%s)" % [track_name, type_str]
	_track_name_label.add_theme_color_override("font_color", track.get("color", COL_TEXT))

	# Selected notes
	var sel_notes: Array = midi_editor._selected_notes
	if sel_notes.is_empty():
		_note_info_label.text = "No notes selected"
		_synth_params_label.text = ""
	else:
		var note_strs: PackedStringArray = []
		var count := 0
		for sel in sel_notes:
			if count >= 4:
				note_strs.append("… +%d more" % (sel_notes.size() - 4))
				break
			var ti: int = sel.get("track_idx", -1)
			var ni: int = sel.get("note_idx", -1)
			if ti >= 0 and ti < tracks.size():
				var notes_arr: Array = tracks[ti].get("notes", [])
				if ni >= 0 and ni < notes_arr.size():
					var n: Dictionary = notes_arr[ni]
					var note_val: int = n.get("note", 60)
					var vel: int = n.get("velocity", 100)
					var dur: int = n.get("duration", 480)
					var name_str: String = _midi_note_name(note_val)
					note_strs.append("%s  vel:%d  dur:%d" % [name_str, vel, dur])
			count += 1
		_note_info_label.text = "  ".join(note_strs) if not note_strs.is_empty() else "No notes selected"

		# Synthesis parameters for this track type
		_synth_params_label.text = _get_synth_params_text(track_name, is_drum)


func _update_mix_overview():
	if midi_editor == null:
		return

	var tracks: Array = midi_editor._tracks
	# Rebuild if track count changed
	if _mix_labels.size() != tracks.size():
		# Clear old
		for child in _mix_container.get_children():
			child.queue_free()
		_mix_labels.clear()

		for i in range(tracks.size()):
			var lbl = Label.new()
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.custom_minimum_size.x = 90
			_mix_container.add_child(lbl)
			_mix_labels.append(lbl)

	# Update values
	var any_solo := false
	for trk in tracks:
		if trk.get("solo", false):
			any_solo = true
			break

	for i in range(tracks.size()):
		if i >= _mix_labels.size():
			break
		var trk: Dictionary = tracks[i]
		var name: String = trk.get("name", "T%d" % (i + 1))
		# Truncate long names
		if name.length() > 10:
			name = name.substr(0, 9) + "…"

		var muted: bool = trk.get("muted", false)
		var solo: bool = trk.get("solo", false)
		var is_audible: bool = not muted and (not any_solo or solo)

		# Estimate volume from note density at current position
		var vol_indicator := "▁"
		var notes_arr: Array = trk.get("notes", [])
		if midi_editor._is_playing and is_audible:
			var active_count := 0
			var tick: int = midi_editor._playback_tick
			for n in notes_arr:
				if n.tick <= tick and n.tick + n.duration >= tick:
					active_count += 1
			if active_count >= 3:
				vol_indicator = "▇"
			elif active_count == 2:
				vol_indicator = "▅"
			elif active_count == 1:
				vol_indicator = "▃"
			else:
				vol_indicator = "▁"
		elif not is_audible:
			vol_indicator = "✕"

		var flags := ""
		if muted:
			flags = " [M]"
		elif solo:
			flags = " [S]"

		_mix_labels[i].text = "%s %s%s" % [vol_indicator, name, flags]

		if muted:
			_mix_labels[i].add_theme_color_override("font_color", COL_MUTED)
		elif solo:
			_mix_labels[i].add_theme_color_override("font_color", COL_SOLO)
		elif not is_audible:
			_mix_labels[i].add_theme_color_override("font_color", COL_DIM_TEXT)
		else:
			_mix_labels[i].add_theme_color_override("font_color", trk.get("color", COL_TEXT))


# ── State File Writer ──────────────────────────────────────────────────

func _check_state_dirty_and_write(delta: float):
	_state_write_cooldown -= delta
	if _state_write_cooldown > 0:
		return

	if not _is_state_dirty():
		return

	_write_state_file()
	_state_write_cooldown = STATE_WRITE_INTERVAL


func _is_state_dirty() -> bool:
	var is_playing := false
	var track_idx := -1
	var sel_count := 0
	var bar := -1
	var section := ""

	if song_dev_tools:
		is_playing = song_dev_tools._is_playing
		section = song_dev_tools._current_section_name

	if midi_editor:
		track_idx = midi_editor._current_track
		sel_count = midi_editor._selected_notes.size()
		if midi_editor._is_playing:
			var ticks_per_bar = midi_editor._ticks_per_quarter * 4
			bar = midi_editor._playback_tick / ticks_per_bar

	var view_bar := -1
	if midi_editor:
		var tpq: int = midi_editor._ticks_per_quarter
		var ticks_per_bar: int = tpq * 4
		var scroll_tick: int = int(midi_editor._scroll_x)
		view_bar = scroll_tick / ticks_per_bar

	var dirty = (
		is_playing != _last_playing or
		track_idx != _last_track_idx or
		sel_count != _last_selected_count or
		bar != _last_bar or
		section != _last_section or
		view_bar != _last_view_bar
	)

	_last_playing = is_playing
	_last_track_idx = track_idx
	_last_selected_count = sel_count
	_last_bar = bar
	_last_section = section
	_last_view_bar = view_bar

	return dirty


func _build_state_snapshot() -> Dictionary:
	var state := {}
	state["timestamp"] = Time.get_datetime_string_from_system(true)

	# Song info
	var song_id := ""
	var song_name := ""
	if song_dev_tools:
		song_id = song_dev_tools._current_song_id if not song_dev_tools._current_song_id.is_empty() else song_dev_tools._current_song
		song_name = song_id.replace("_", " ").capitalize()
	state["song_id"] = song_id
	state["song_name"] = song_name

	# Section
	state["section"] = song_dev_tools._current_section_name if song_dev_tools else ""

	# Position
	var bar := 0
	var beat := 0
	var bpm := 120.0
	var playback_seconds := 0.0
	var playing := false
	var view_bar := 0
	var view_beat := 0

	if midi_editor:
		bpm = midi_editor._bpm
		var tpq: int = midi_editor._ticks_per_quarter
		var ticks_per_bar: int = tpq * 4
		if midi_editor._is_playing:
			bar = midi_editor._playback_tick / ticks_per_bar + 1
			beat = (midi_editor._playback_tick % ticks_per_bar) / tpq + 1
			playback_seconds = float(midi_editor._playback_tick) / (bpm / 60.0 * tpq)
		playing = midi_editor._is_playing
		# Scroll position — where the user is looking in the timeline
		var scroll_tick: int = int(midi_editor._scroll_x)
		view_bar = scroll_tick / ticks_per_bar + 1
		view_beat = (scroll_tick % ticks_per_bar) / tpq + 1
	elif song_dev_tools:
		playing = song_dev_tools._is_playing
		playback_seconds = song_dev_tools._playback_time
		if bpm > 0:
			var total_beats = playback_seconds * bpm / 60.0
			bar = int(total_beats / 4) + 1
			beat = int(fmod(total_beats, 4.0)) + 1

	state["bar"] = bar
	state["beat"] = beat
	state["view_bar"] = view_bar
	state["view_beat"] = view_beat
	state["playback_seconds"] = snappedf(playback_seconds, 0.1)
	state["playing"] = playing
	state["bpm"] = bpm

	# Selected track
	var sel_track := {}
	if midi_editor and not midi_editor._tracks.is_empty():
		var ti: int = midi_editor._current_track
		if ti >= 0 and ti < midi_editor._tracks.size():
			var trk: Dictionary = midi_editor._tracks[ti]
			sel_track["name"] = trk.get("name", "Track %d" % (ti + 1))
			sel_track["index"] = ti
			sel_track["program"] = trk.get("program", 0)
			sel_track["is_drum"] = trk.get("is_drum", false)
	state["selected_track"] = sel_track

	# Selected notes
	var sel_notes_arr: Array = []
	if midi_editor:
		for sel in midi_editor._selected_notes:
			var ti: int = sel.get("track_idx", -1)
			var ni: int = sel.get("note_idx", -1)
			if ti >= 0 and ti < midi_editor._tracks.size():
				var notes: Array = midi_editor._tracks[ti].get("notes", [])
				if ni >= 0 and ni < notes.size():
					var n: Dictionary = notes[ni]
					sel_notes_arr.append({
						"note": n.get("note", 60),
						"tick": n.get("tick", 0),
						"velocity": n.get("velocity", 100),
						"duration": n.get("duration", 480)
					})
	state["selected_notes"] = sel_notes_arr

	# Mix levels (note density as proxy for volume)
	var mix_levels := {}
	var muted_tracks: Array = []
	var solo_tracks: Array = []
	if midi_editor:
		for i in range(midi_editor._tracks.size()):
			var trk: Dictionary = midi_editor._tracks[i]
			var tname: String = trk.get("name", "Track %d" % (i + 1))
			var notes: Array = trk.get("notes", [])
			var active := 0
			if midi_editor._is_playing:
				var tick: int = midi_editor._playback_tick
				for n in notes:
					if n.tick <= tick and n.tick + n.duration >= tick:
						active += 1
			mix_levels[tname] = snappedf(float(active) * 0.15, 0.01)
			if trk.get("muted", false):
				muted_tracks.append(tname)
			if trk.get("solo", false):
				solo_tracks.append(tname)

	state["mix_levels"] = mix_levels
	state["muted_tracks"] = muted_tracks
	state["solo_tracks"] = solo_tracks

	# JSON spec summary — what data the track has
	var spec_summary := {}
	if not song_id.is_empty():
		var json_path = SONGS_PATH + song_id + ".json"
		if FileAccess.file_exists(json_path):
			var spec_file = FileAccess.open(json_path, FileAccess.READ)
			if spec_file:
				var spec_json = JSON.new()
				if spec_json.parse(spec_file.get_as_text()) == OK and spec_json.data is Dictionary:
					var d: Dictionary = spec_json.data
					var arr = d.get("arrangement", {})
					var secs = arr.get("sections", [])
					var sec_names: Array = []
					for s in secs:
						sec_names.append(s.get("name", "?"))
					spec_summary = {
						"has_patterns": d.has("patterns") and d["patterns"].size() > 0,
						"has_melody": d.has("melody") and d["melody"].size() > 0,
						"has_chords": d.has("chord_progressions") and d["chord_progressions"].size() > 0,
						"has_arrangement": secs.size() > 0,
						"key": arr.get("key", ""),
						"scale": arr.get("scale", ""),
						"sections": sec_names,
						"total_bars": secs.reduce(func(acc, s): return acc + s.get("bars", 0), 0),
						"pattern_count": d.get("patterns", {}).size(),
						"melody_count": d.get("melody", {}).size(),
						"chord_count": d.get("chord_progressions", {}).size(),
					}
				spec_file.close()
	state["json_spec"] = spec_summary

	return state


func _write_state_file():
	var state = _build_state_snapshot()
	var json_str = JSON.stringify(state, "\t")
	var file = FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()


# ── Chat File Protocol ─────────────────────────────────────────────────

func _on_send_pressed():
	_send_message()


func _on_text_submitted(_text: String):
	_send_message()


func _send_message():
	var text: String = _input_field.text.strip_edges()
	if text.is_empty():
		return

	_input_field.text = ""

	# Add to local display
	_add_chat_bubble("user", text)
	_chat_messages.append({"role": "user", "text": text, "timestamp": Time.get_datetime_string_from_system(true)})

	# Write to chat file
	_write_chat_file(text)


func _write_chat_file(user_text: String):
	# Read existing messages (append)
	var existing_messages: Array = []
	if FileAccess.file_exists(CHAT_PATH):
		var file = FileAccess.open(CHAT_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				existing_messages = json.data.get("messages", [])
			file.close()

	# Build message with state snapshot
	var msg := {
		"role": "user",
		"text": user_text,
		"timestamp": Time.get_datetime_string_from_system(true),
		"state_snapshot": _build_state_snapshot()
	}
	existing_messages.append(msg)

	var chat_data := {"messages": existing_messages}
	var file = FileAccess.open(CHAT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(chat_data, "\t"))
		file.close()


func _poll_response_file(delta: float):
	_response_poll_cooldown -= delta
	if _response_poll_cooldown > 0:
		return
	_response_poll_cooldown = RESPONSE_POLL_INTERVAL

	if not FileAccess.file_exists(RESPONSE_PATH):
		return

	# Check modification time
	var mod_time := FileAccess.get_modified_time(RESPONSE_PATH)
	if mod_time == _last_response_mod_time:
		return
	_last_response_mod_time = mod_time

	# Read and parse
	var file = FileAccess.open(RESPONSE_PATH, FileAccess.READ)
	if file == null:
		return
	var json = JSON.new()
	var content = file.get_as_text()
	file.close()

	if content.strip_edges().is_empty():
		return

	if json.parse(content) != OK:
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	var role: String = data.get("role", "assistant")
	var text: String = data.get("text", "")
	var changes: Array = data.get("changes", [])

	if text.is_empty():
		return

	# Display the response
	var display_text := text
	if not changes.is_empty():
		display_text += "\n\n📝 Changes:"
		for change in changes:
			if change is Dictionary:
				display_text += "\n  • %s: %s" % [change.get("file", "?"), change.get("description", "")]

	_add_chat_bubble("assistant", display_text)
	_chat_messages.append({"role": role, "text": text, "timestamp": data.get("timestamp", "")})

	# Delete the response file (so we detect the next one)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESPONSE_PATH))


# ── Chat Bubble UI ─────────────────────────────────────────────────────

func _add_chat_bubble(role: String, text: String):
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	if role == "user":
		style.bg_color = COL_USER_BUBBLE
	else:
		style.bg_color = COL_ASST_BUBBLE
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Role label
	var role_label = Label.new()
	role_label.text = "You:" if role == "user" else "Ada:"
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", COL_HEADER if role == "assistant" else Color(0.7, 0.75, 0.9))
	vbox.add_child(role_label)

	# Message text
	var msg_label = RichTextLabel.new()
	msg_label.bbcode_enabled = false
	msg_label.text = text
	msg_label.fit_content = true
	msg_label.scroll_active = false
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_label.add_theme_font_size_override("normal_font_size", 13)
	msg_label.add_theme_color_override("default_color", COL_TEXT)
	vbox.add_child(msg_label)

	_chat_vbox.add_child(panel)

	# Auto-scroll to bottom
	await get_tree().process_frame
	_chat_scroll.scroll_vertical = _chat_scroll.get_v_scroll_bar().max_value


# ── Helper: Synth Params Text ──────────────────────────────────────────

func _get_synth_params_text(track_name: String, is_drum: bool) -> String:
	if is_drum:
		return "Bus: Master  |  Type: Percussion  |  Synthesis: Real-time drum"

	var inst = track_name.to_lower()
	var params := ""

	if song_dev_tools:
		var lp: Dictionary = song_dev_tools.live_params

		if "bass" in inst or "sub" in inst:
			params = "Filter: %d Hz  |  Resonance: %.2f  |  Volume: %.1f dB  |  Bus: Master" % [
				int(lp.get("bass_filter_cutoff", 800)),
				lp.get("bass_filter_resonance", 0.5),
				lp.get("bass_volume", 0.0)
			]
		elif "pad" in inst or "mellotron" in inst:
			params = "Filter: %d Hz  |  Detune: %.1f  |  Volume: %.1f dB  |  Bus: Master" % [
				int(lp.get("pad_filter_cutoff", 2000)),
				lp.get("pad_detune", 10.0),
				lp.get("pad_volume", 0.0)
			]
		elif "lead" in inst or "elp" in inst:
			params = "Filter: %d Hz  |  Vibrato: %.2f  |  Volume: %.1f dB  |  Bus: Master" % [
				int(lp.get("lead_filter_cutoff", 3000)),
				lp.get("lead_vibrato_depth", 0.2),
				lp.get("lead_volume", 0.0)
			]
		else:
			params = "Volume: %.1f dB  |  Reverb: %.0f%%  |  Delay: %.0f%%  |  Bus: Master" % [
				lp.get("master_volume", 0.0),
				lp.get("reverb_mix", 0.3) * 100,
				lp.get("delay_mix", 0.2) * 100
			]
	else:
		params = "Bus: Master"

	return params


# ── Context Buttons ────────────────────────────────────────────────────

func _make_context_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 26)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.18, 0.2, 0.28)
	st.set_corner_radius_all(12)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	st.border_color = Color(0.3, 0.35, 0.5)
	st.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", st)
	var hv = st.duplicate()
	hv.bg_color = Color(0.25, 0.28, 0.4)
	hv.border_color = COL_ACCENT
	btn.add_theme_stylebox_override("hover", hv)
	var pr = st.duplicate()
	pr.bg_color = COL_ACCENT.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	return btn


func _append_to_input(tag: String):
	"""Append a context tag to the chat input field."""
	var current = _input_field.text
	if current.is_empty():
		_input_field.text = tag + " "
	else:
		_input_field.text = current.strip_edges() + " " + tag + " "
	_input_field.caret_column = _input_field.text.length()
	_input_field.grab_focus()


func _on_ctx_position():
	"""Insert current playback or scroll position."""
	var bar := 0
	var beat := 0
	var source := "view"
	if midi_editor:
		var tpq: int = midi_editor._ticks_per_quarter
		var tpb: int = tpq * 4
		if midi_editor._is_playing:
			bar = midi_editor._playback_tick / tpb + 1
			beat = (midi_editor._playback_tick % tpb) / tpq + 1
			source = "playhead"
		else:
			var scroll_tick: int = int(midi_editor._scroll_x)
			bar = scroll_tick / tpb + 1
			beat = (scroll_tick % tpb) / tpq + 1
			source = "view"
	_append_to_input("[at bar:%d beat:%d (%s)]" % [bar, beat, source])


func _on_ctx_track():
	"""Insert current track name and key parameters."""
	if midi_editor == null or midi_editor._tracks.is_empty():
		_append_to_input("[track: none]")
		return
	var ti: int = midi_editor._current_track
	if ti < 0 or ti >= midi_editor._tracks.size():
		_append_to_input("[track: none]")
		return
	var trk: Dictionary = midi_editor._tracks[ti]
	var tname: String = trk.get("name", "Track %d" % (ti + 1))
	var program: int = trk.get("program", 0)
	var is_drum: bool = trk.get("is_drum", false)
	var note_count: int = trk.get("notes", []).size()
	var type_str = "drums" if is_drum else "prog:%d" % program

	# Add synth params if available
	var params_str := ""
	if song_dev_tools:
		var lp: Dictionary = song_dev_tools.live_params
		var inst = tname.to_lower()
		if "bass" in inst or "sub" in inst:
			params_str = " filter:%dHz res:%.2f" % [int(lp.get("bass_filter_cutoff", 800)), lp.get("bass_filter_resonance", 0.5)]
		elif "pad" in inst or "mellotron" in inst:
			params_str = " filter:%dHz detune:%.1f" % [int(lp.get("pad_filter_cutoff", 2000)), lp.get("pad_detune", 10.0)]
		elif "lead" in inst or "elp" in inst:
			params_str = " filter:%dHz vibrato:%.2f" % [int(lp.get("lead_filter_cutoff", 3000)), lp.get("lead_vibrato_depth", 0.2)]
	_append_to_input("[track:%s %s notes:%d%s]" % [tname, type_str, note_count, params_str])


func _on_ctx_section():
	"""Insert current section name."""
	var section := "none"
	if song_dev_tools:
		section = song_dev_tools._current_section_name if not song_dev_tools._current_section_name.is_empty() else "none"
	_append_to_input("[section:%s]" % section)


func _on_ctx_song():
	"""Insert global song info: name, key, BPM, style."""
	var song_id := ""
	var bpm := 120.0
	if song_dev_tools:
		song_id = song_dev_tools._current_song_id if not song_dev_tools._current_song_id.is_empty() else song_dev_tools._current_song
	if midi_editor:
		bpm = midi_editor._bpm

	# Try to read key from JSON
	var key_str := "?"
	if not song_id.is_empty():
		var json_path = SONGS_PATH + song_id + ".json"
		if FileAccess.file_exists(json_path):
			var file = FileAccess.open(json_path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
					var params = json.data.get("parameters", {})
					var key_data = params.get("key", {})
					key_str = key_data.get("value", "?") if key_data is Dictionary else str(key_data)
				file.close()
	_append_to_input("[song:%s key:%s bpm:%d]" % [song_id, key_str, int(bpm)])


func _on_ctx_selection():
	"""Insert info about currently selected notes."""
	if midi_editor == null or midi_editor._selected_notes.is_empty():
		_append_to_input("[selection: none]")
		return
	var sel: Array = midi_editor._selected_notes
	var note_strs: PackedStringArray = []
	var count := 0
	for s in sel:
		if count >= 4:
			note_strs.append("+%d more" % (sel.size() - 4))
			break
		var ti: int = s.get("track_idx", -1)
		var ni: int = s.get("note_idx", -1)
		if ti >= 0 and ti < midi_editor._tracks.size():
			var notes_arr: Array = midi_editor._tracks[ti].get("notes", [])
			if ni >= 0 and ni < notes_arr.size():
				var n: Dictionary = notes_arr[ni]
				var note_name = _midi_note_name(n.get("note", 60))
				note_strs.append("%s v%d d%d" % [note_name, n.get("velocity", 100), n.get("duration", 480)])
		count += 1
	_append_to_input("[selected: %s]" % " | ".join(note_strs))


func _update_word_buttons():
	"""Rebuild word buttons when track or song changes. Shows all words for the current song grouped by layer."""
	if song_dev_tools == null:
		return

	# Determine current track name and song
	var track_name := ""
	if midi_editor and not midi_editor._tracks.is_empty():
		var ti: int = midi_editor._current_track
		if ti >= 0 and ti < midi_editor._tracks.size():
			track_name = midi_editor._tracks[ti].get("name", "")
	var song_id := ""
	if song_dev_tools:
		song_id = song_dev_tools._current_song_id if not song_dev_tools._current_song_id.is_empty() else song_dev_tools._current_song

	# Only rebuild if track or song changed
	if track_name == _last_word_track and song_id == _last_word_song:
		return
	_last_word_track = track_name
	_last_word_song = song_id

	# Clear old buttons and labels
	for child in _word_bar.get_children():
		child.queue_free()
	_word_buttons.clear()

	if song_id.is_empty():
		return

	# Read words from SongDevTools._current_song_words (populated by _load_song_words)
	var song_words: Dictionary = song_dev_tools._current_song_words
	if song_words.is_empty():
		return

	# Collect all unique words, tracking which layer they belong to
	# Highlight words from the current track's matching layer
	var matched_layer := ""
	var track_lower := track_name.to_lower()
	for layer_name in song_words:
		var layer_lower: String = layer_name.to_lower()
		if layer_lower == track_lower or layer_lower in track_lower or track_lower in layer_lower:
			matched_layer = layer_name
			break

	# Build word buttons — matched layer first, then others
	var added_words: Dictionary = {}  # Track duplicates

	# Current track's words first (highlighted)
	if not matched_layer.is_empty() and song_words.has(matched_layer):
		var data: Dictionary = song_words[matched_layer]
		var words: Array = data.get("words", [])
		if not words.is_empty():
			var lbl = Label.new()
			lbl.text = matched_layer + ":"
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", COL_HEADER)
			_word_bar.add_child(lbl)
			for word in words:
				var w := str(word)
				var btn = _make_word_button(w)
				btn.pressed.connect(func(): _append_to_input("[%s]" % w))
				_word_bar.add_child(btn)
				_word_buttons.append(btn)
				added_words[w] = true

	# Other layers (dimmer)
	for layer_name in song_words:
		if layer_name == matched_layer:
			continue
		var data: Dictionary = song_words[layer_name]
		var words: Array = data.get("words", [])
		var new_words: Array = []
		for word in words:
			if not added_words.has(str(word)):
				new_words.append(word)
				added_words[str(word)] = true
		if new_words.is_empty():
			continue
		# Separator label
		var sep = Label.new()
		sep.text = layer_name + ":"
		sep.add_theme_font_size_override("font_size", 10)
		sep.add_theme_color_override("font_color", COL_DIM_TEXT)
		_word_bar.add_child(sep)
		for word in new_words:
			var w := str(word)
			var btn = _make_word_button(w)
			# Dim style for non-current layer
			var dim_st = StyleBoxFlat.new()
			dim_st.bg_color = Color(0.13, 0.15, 0.14)
			dim_st.set_corner_radius_all(10)
			dim_st.content_margin_left = 7
			dim_st.content_margin_right = 7
			dim_st.content_margin_top = 1
			dim_st.content_margin_bottom = 1
			dim_st.border_color = Color(0.25, 0.3, 0.28)
			dim_st.set_border_width_all(1)
			btn.add_theme_stylebox_override("normal", dim_st)
			btn.add_theme_color_override("font_color", Color(0.5, 0.65, 0.55))
			btn.pressed.connect(func(): _append_to_input("[%s]" % w))
			_word_bar.add_child(btn)
			_word_buttons.append(btn)


func _make_word_button(word: String) -> Button:
	var btn = Button.new()
	btn.text = word
	btn.custom_minimum_size = Vector2(0, 22)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.2, 0.18)
	st.set_corner_radius_all(10)
	st.content_margin_left = 7
	st.content_margin_right = 7
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	st.border_color = Color(0.3, 0.45, 0.35)
	st.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", st)
	var hv = st.duplicate()
	hv.bg_color = Color(0.2, 0.35, 0.25)
	hv.border_color = Color(0.4, 0.7, 0.5)
	btn.add_theme_stylebox_override("hover", hv)
	var pr = st.duplicate()
	pr.bg_color = Color(0.3, 0.5, 0.35)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.6, 0.85, 0.7))
	return btn


func _update_context_buttons():
	"""Update context button labels with current live values for quick scanning."""
	if midi_editor == null and song_dev_tools == null:
		return

	# Position button — show current bar
	var bar := 0
	if midi_editor:
		var tpq: int = midi_editor._ticks_per_quarter
		var tpb: int = tpq * 4
		if midi_editor._is_playing:
			bar = midi_editor._playback_tick / tpb + 1
		else:
			bar = int(midi_editor._scroll_x) / tpb + 1
	_ctx_position_btn.text = "📍 Bar %d" % bar if bar > 0 else "📍 Position"

	# Track button
	if midi_editor and not midi_editor._tracks.is_empty():
		var ti: int = midi_editor._current_track
		if ti >= 0 and ti < midi_editor._tracks.size():
			var tname: String = midi_editor._tracks[ti].get("name", "?")
			if tname.length() > 12:
				tname = tname.substr(0, 11) + "…"
			_ctx_track_btn.text = "🎹 %s" % tname

	# Section button
	if song_dev_tools and not song_dev_tools._current_section_name.is_empty():
		_ctx_section_btn.text = "§ %s" % song_dev_tools._current_section_name

	# Selection button — show count
	if midi_editor:
		var sel_count: int = midi_editor._selected_notes.size()
		_ctx_selection_btn.text = "🎯 %d notes" % sel_count if sel_count > 0 else "🎯 Selection"


# ── Utility ────────────────────────────────────────────────────────────

func _midi_note_name(note: int) -> String:
	const NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octave: int = note / 12 - 1
	return "%s%d" % [NAMES[note % 12], octave]


# ── Widget Factories ───────────────────────────────────────────────────

func _make_section_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = COL_PANEL
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_header(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COL_HEADER)
	return label


func _make_value_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", COL_TEXT)
	return label


func _style_input_field(field: LineEdit):
	var style = StyleBoxFlat.new()
	style.bg_color = COL_INPUT_BG
	style.set_corner_radius_all(6)
	style.border_color = COL_INPUT_BORDER
	style.set_border_width_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	field.add_theme_stylebox_override("normal", style)

	var focus = style.duplicate()
	focus.border_color = COL_ACCENT
	focus.set_border_width_all(2)
	field.add_theme_stylebox_override("focus", focus)

	field.add_theme_font_size_override("font_size", 13)
	field.add_theme_color_override("font_color", COL_TEXT)
	field.add_theme_color_override("font_placeholder_color", COL_DIM_TEXT)


func _style_send_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = COL_ACCENT
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = COL_ACCENT.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = COL_ACCENT.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
