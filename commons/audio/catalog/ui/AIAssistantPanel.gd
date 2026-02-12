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

# Chat section
var _chat_panel: PanelContainer
var _chat_scroll: ScrollContainer
var _chat_vbox: VBoxContainer
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

	var dirty = (
		is_playing != _last_playing or
		track_idx != _last_track_idx or
		sel_count != _last_selected_count or
		bar != _last_bar or
		section != _last_section
	)

	_last_playing = is_playing
	_last_track_idx = track_idx
	_last_selected_count = sel_count
	_last_bar = bar
	_last_section = section

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

	if midi_editor:
		bpm = midi_editor._bpm
		var tpq: int = midi_editor._ticks_per_quarter
		var ticks_per_bar: int = tpq * 4
		if midi_editor._is_playing:
			bar = midi_editor._playback_tick / ticks_per_bar + 1
			beat = (midi_editor._playback_tick % ticks_per_bar) / tpq + 1
			playback_seconds = float(midi_editor._playback_tick) / (bpm / 60.0 * tpq)
		playing = midi_editor._is_playing
	elif song_dev_tools:
		playing = song_dev_tools._is_playing
		playback_seconds = song_dev_tools._playback_time
		if bpm > 0:
			var total_beats = playback_seconds * bpm / 60.0
			bar = int(total_beats / 4) + 1
			beat = int(fmod(total_beats, 4.0)) + 1

	state["bar"] = bar
	state["beat"] = beat
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
