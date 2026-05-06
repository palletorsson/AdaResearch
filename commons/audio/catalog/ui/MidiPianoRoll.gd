# MidiPianoRoll.gd
# Self-contained MIDI piano roll editor with visual grid, note editing,
# import/export, and track management. Built entirely in code (no .tscn).

extends Control
class_name MidiPianoRoll

# ── Constants ──────────────────────────────────────────────────────────
const CELL_W: float = 20.0      # Width per 16th-note (before zoom)
const CELL_H: float = 12.0      # Height per semitone
const PIANO_WIDTH: float = 60.0 # Left-side note label column
const TOOLBAR_H: float = 40.0   # Top toolbar height
const HEADER_H: float = 20.0    # Bar number header height
const RESIZE_EDGE: float = 6.0  # Right-edge drag zone for resizing

const NOTE_NAMES = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
const BLACK_KEYS = [1, 3, 6, 8, 10]  # Semitone indices that are black keys

const TRACK_COLORS: Array[Color] = [
	Color(0.3, 0.6, 0.85), Color(0.85, 0.4, 0.3), Color(0.4, 0.75, 0.4),
	Color(0.8, 0.6, 0.2), Color(0.6, 0.4, 0.8), Color(0.7, 0.55, 0.65),
	Color(0.4, 0.7, 0.7), Color(0.75, 0.45, 0.55),
]

# Grid / theme colors
const COL_BG         = Color(0.1, 0.1, 0.12)
const COL_BLACK_ROW  = Color(0.08, 0.08, 0.1)
const COL_SEMI_LINE  = Color(0.2, 0.2, 0.22)
const COL_BEAT_LINE  = Color(0.3, 0.3, 0.35)
const COL_BAR_LINE   = Color(0.5, 0.5, 0.55)
const COL_PLAYHEAD   = Color(0.3, 0.8, 1.0, 0.8)
const COL_SELECT_OUT = Color(1.0, 1.0, 1.0, 0.8)

# ── Data Model ─────────────────────────────────────────────────────────
var _tracks: Array[Dictionary] = []
var _bpm: float = 120.0
var _ticks_per_quarter: int = 480
var _snap_ticks: int = 120          # Default: 16th note
var _current_track: int = 0
var _current_velocity: int = 100

# View / scroll
var _scroll_x: float = 0.0         # In ticks
var _scroll_y: float = 0.0         # In semitone offset (from bottom)
var _zoom_x: float = 1.0
var _view_note_min: int = 48       # C3
var _view_note_max: int = 84       # C6 (3 octaves)

# Selection & interaction
var _selected_notes: Array[Dictionary] = []  # [{track_idx, note_idx}]
var _hovered_note: Dictionary = {}           # {track_idx, note_idx} or empty
var _drag_mode: int = 0  # 0=none, 1=move, 2=resize
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_tick: int = 0
var _drag_start_note_val: int = 0
var _drag_start_dur: int = 0
var _drag_active: bool = false

# Playback
var _is_playing: bool = false
var _playback_tick: int = 0
var _last_triggered: Dictionary = {}  # track_idx -> set of note indices already triggered

# Audio playback - pool of AudioStreamPlayers for polyphony
const VOICE_POOL_SIZE = 16
const SAMPLE_RATE = 44100.0
var _voice_pool: Array[AudioStreamPlayer] = []
var _voice_ages: Array[int] = []  # Frame counter for voice stealing
var _frame_counter: int = 0

# UI widgets (built in _ready)
var _toolbar: HBoxContainer
var _track_dropdown: OptionButton
var _vel_dropdown: OptionButton
var _snap_dropdown: OptionButton
var _bpm_spin: SpinBox
var _play_btn: Button
var _stop_btn: Button
var _song_dropdown: OptionButton
var _grid_area: Control   # Sub-control that receives draw/input
var _file_dialog: FileDialog

# ── Lifecycle ──────────────────────────────────────────────────────────
func _ready():
	clip_contents = true
	_build_toolbar()
	_build_grid_area()
	_build_file_dialog()
	_build_voice_pool()
	# Start with one empty track
	if _tracks.is_empty():
		_add_default_track()
	_update_track_dropdown()
	call_deferred("_layout")


func _process(delta: float):
	_frame_counter += 1
	if not _is_playing:
		return
	var ticks_per_sec = _bpm / 60.0 * _ticks_per_quarter
	var prev_tick = _playback_tick
	_playback_tick += int(delta * ticks_per_sec)
	_trigger_playback_notes(prev_tick, _playback_tick)
	_grid_area.queue_redraw()


func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
		_layout()

# ── UI Construction ────────────────────────────────────────────────────
func _build_toolbar():
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 6)
	add_child(_toolbar)

	# Track dropdown
	_add_toolbar_label("Track:")
	_track_dropdown = OptionButton.new()
	_track_dropdown.custom_minimum_size.x = 120
	_track_dropdown.item_selected.connect(func(idx): _current_track = idx; _grid_area.queue_redraw())
	_style_dropdown(_track_dropdown)
	_toolbar.add_child(_track_dropdown)

	# Add/Remove track
	var add_trk = Button.new()
	add_trk.text = "+"
	add_trk.pressed.connect(_on_add_track)
	_style_btn(add_trk, Color(0.25, 0.45, 0.3))
	_toolbar.add_child(add_trk)

	var rem_trk = Button.new()
	rem_trk.text = "−"
	rem_trk.pressed.connect(_on_remove_track)
	_style_btn(rem_trk, Color(0.45, 0.25, 0.25))
	_toolbar.add_child(rem_trk)

	_toolbar.add_child(_sep())

	# Velocity
	_add_toolbar_label("Vel:")
	_vel_dropdown = OptionButton.new()
	_vel_dropdown.add_item("Ghost (50)", 0)
	_vel_dropdown.add_item("Normal (100)", 1)
	_vel_dropdown.add_item("Accent (127)", 2)
	_vel_dropdown.select(1)
	_vel_dropdown.item_selected.connect(_on_vel_selected)
	_style_dropdown(_vel_dropdown)
	_toolbar.add_child(_vel_dropdown)

	# Snap
	_add_toolbar_label("Snap:")
	_snap_dropdown = OptionButton.new()
	for item in ["1/4", "1/8", "1/16", "1/32", "Off"]:
		_snap_dropdown.add_item(item)
	_snap_dropdown.select(2)  # Default 1/16
	_snap_dropdown.item_selected.connect(_on_snap_selected)
	_style_dropdown(_snap_dropdown)
	_toolbar.add_child(_snap_dropdown)

	# BPM
	_add_toolbar_label("BPM:")
	_bpm_spin = SpinBox.new()
	_bpm_spin.min_value = 40
	_bpm_spin.max_value = 300
	_bpm_spin.value = _bpm
	_bpm_spin.value_changed.connect(func(v): _bpm = v)
	_toolbar.add_child(_bpm_spin)

	_toolbar.add_child(_sep())

	# Transport
	_play_btn = Button.new()
	_play_btn.text = "▶ Play"
	_play_btn.pressed.connect(_on_play)
	_style_btn(_play_btn, Color(0.2, 0.5, 0.3))
	_toolbar.add_child(_play_btn)

	_stop_btn = Button.new()
	_stop_btn.text = "⏹ Stop"
	_stop_btn.pressed.connect(_on_stop)
	_style_btn(_stop_btn, Color(0.5, 0.3, 0.2))
	_toolbar.add_child(_stop_btn)

	_toolbar.add_child(_sep())

	# Import / Export
	var imp_btn = Button.new()
	imp_btn.text = "Import MIDI"
	imp_btn.pressed.connect(_on_import_pressed)
	_style_btn(imp_btn, Color(0.3, 0.35, 0.5))
	_toolbar.add_child(imp_btn)

	var exp_btn = Button.new()
	exp_btn.text = "Export MIDI"
	exp_btn.pressed.connect(_on_export_pressed)
	_style_btn(exp_btn, Color(0.35, 0.3, 0.45))
	_toolbar.add_child(exp_btn)

	# Load from Song
	_add_toolbar_label("Song:")
	_song_dropdown = OptionButton.new()
	_song_dropdown.add_item("— Load from Song —", 0)
	for sid in ["prog_odyssey", "kraftwerk", "prog_synth_70s"]:
		_song_dropdown.add_item(sid)
	_song_dropdown.item_selected.connect(_on_song_selected)
	_style_dropdown(_song_dropdown)
	_toolbar.add_child(_song_dropdown)


func _build_grid_area():
	_grid_area = Control.new()
	_grid_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_grid_area.clip_contents = true
	_grid_area.draw.connect(_on_grid_draw)
	_grid_area.gui_input.connect(_on_grid_input)
	add_child(_grid_area)


func _build_file_dialog():
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.add_filter("*.mid, *.midi ; MIDI files")
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _layout():
	var sz = size
	_toolbar.position = Vector2.ZERO
	_toolbar.size = Vector2(sz.x, TOOLBAR_H)
	_grid_area.position = Vector2(0, TOOLBAR_H)
	_grid_area.size = Vector2(sz.x, sz.y - TOOLBAR_H)

# ── Helpers for toolbar ────────────────────────────────────────────────
func _add_toolbar_label(text: String):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_toolbar.add_child(l)

func _sep() -> VSeparator:
	var s = VSeparator.new()
	s.custom_minimum_size.x = 8
	return s

func _style_btn(btn: Button, color: Color):
	var st = StyleBoxFlat.new()
	st.bg_color = color
	st.set_corner_radius_all(6)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", st)
	var hv = st.duplicate()
	hv.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hv)
	var pr = st.duplicate()
	pr.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))

func _style_dropdown(dd: OptionButton):
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.16, 0.2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 8
	st.content_margin_right = 20
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	st.border_color = Color(0.25, 0.27, 0.35)
	st.set_border_width_all(1)
	dd.add_theme_stylebox_override("normal", st)
	dd.add_theme_font_size_override("font_size", 12)
	dd.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))

# ── Grid Drawing ───────────────────────────────────────────────────────
func _on_grid_draw():
	var area = _grid_area
	var sz = area.size
	var grid_x0 = PIANO_WIDTH
	var grid_y0 = HEADER_H
	var grid_w = sz.x - grid_x0
	var grid_h = sz.y - grid_y0
	var note_range = _view_note_max - _view_note_min

	# Background
	area.draw_rect(Rect2(Vector2.ZERO, sz), COL_BG)

	# ─── Row backgrounds (black/white key distinction) ───
	for i in range(note_range):
		var midi_note = _view_note_max - 1 - i
		var y = grid_y0 + i * CELL_H
		if midi_note % 12 in BLACK_KEYS:
			area.draw_rect(Rect2(grid_x0, y, grid_w, CELL_H), COL_BLACK_ROW)

	# ─── Horizontal grid lines (semitones) ───
	for i in range(note_range + 1):
		var y = grid_y0 + i * CELL_H
		var midi_note = _view_note_max - i
		var col = COL_SEMI_LINE
		if midi_note % 12 == 0:
			col = COL_BEAT_LINE  # C notes brighter
		area.draw_line(Vector2(grid_x0, y), Vector2(sz.x, y), col, 1.0)

	# ─── Vertical grid lines (beats/bars) ───
	var ticks_per_16th = _ticks_per_quarter / 4
	var px_per_tick = (CELL_W * _zoom_x) / float(ticks_per_16th)
	var first_tick = int(_scroll_x)
	# Align to bar
	var ticks_per_bar = _ticks_per_quarter * 4
	var start_bar_tick = (first_tick / ticks_per_bar) * ticks_per_bar

	var t = start_bar_tick
	while true:
		var x = grid_x0 + (t - _scroll_x) * px_per_tick
		if x > sz.x:
			break
		if x >= grid_x0:
			var col: Color
			if t % ticks_per_bar == 0:
				col = COL_BAR_LINE
			elif t % _ticks_per_quarter == 0:
				col = COL_BEAT_LINE
			else:
				col = COL_SEMI_LINE
			area.draw_line(Vector2(x, grid_y0), Vector2(x, sz.y), col, 1.0)
		t += ticks_per_16th
		if t > first_tick + 100000:
			break  # safety

	# ─── Bar numbers ───
	var bar_t = start_bar_tick
	while true:
		var x = grid_x0 + (bar_t - _scroll_x) * px_per_tick
		if x > sz.x:
			break
		if x >= grid_x0 - 10:
			var bar_num = bar_t / ticks_per_bar + 1
			area.draw_string(ThemeDB.fallback_font, Vector2(x + 3, 14),
				str(bar_num), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.65))
		bar_t += ticks_per_bar
		if bar_t > first_tick + 100000:
			break

	# ─── Piano labels (left side) ───
	for i in range(note_range):
		var midi_note = _view_note_max - 1 - i
		var y = grid_y0 + i * CELL_H
		var name = NOTE_NAMES[midi_note % 12] + str(midi_note / 12 - 1)
		var col = Color(0.55, 0.55, 0.6) if midi_note % 12 in BLACK_KEYS else Color(0.7, 0.7, 0.75)
		if midi_note % 12 == 0:
			col = Color(0.9, 0.9, 0.95)
		area.draw_string(ThemeDB.fallback_font, Vector2(4, y + CELL_H - 2),
			name, HORIZONTAL_ALIGNMENT_LEFT, PIANO_WIDTH - 8, 10, col)

	# ─── Notes ───
	var any_solo = false
	for trk in _tracks:
		if trk.get("solo", false):
			any_solo = true
			break

	for ti in range(_tracks.size()):
		var trk = _tracks[ti]
		if trk.get("muted", false):
			continue
		if any_solo and not trk.get("solo", false):
			continue
		var base_col: Color = trk.get("color", TRACK_COLORS[0])
		var notes_arr: Array = trk.get("notes", [])
		for ni in range(notes_arr.size()):
			var n = notes_arr[ni]
			var nx = grid_x0 + (n.tick - _scroll_x) * px_per_tick
			var nw = n.duration * px_per_tick
			var ny = grid_y0 + (_view_note_max - 1 - n.note) * CELL_H
			# Skip if off-screen
			if nx + nw < grid_x0 or nx > sz.x or ny + CELL_H < grid_y0 or ny > sz.y:
				continue
			# Velocity-based color
			var col: Color
			if n.velocity >= 110:
				col = base_col.lightened(0.25)
			elif n.velocity <= 60:
				col = base_col.darkened(0.35)
			else:
				col = base_col
			if ti != _current_track:
				col.a = 0.45
			area.draw_rect(Rect2(nx, ny + 1, maxf(nw, 2), CELL_H - 2), col)
			# Selected outline
			if _is_note_selected(ti, ni):
				area.draw_rect(Rect2(nx, ny + 1, maxf(nw, 2), CELL_H - 2), COL_SELECT_OUT, false, 1.5)

	# ─── Playhead ───
	if _is_playing:
		var phx = grid_x0 + (_playback_tick - _scroll_x) * px_per_tick
		if phx >= grid_x0 and phx <= sz.x:
			area.draw_line(Vector2(phx, grid_y0), Vector2(phx, sz.y), COL_PLAYHEAD, 2.0)

	# ─── Piano column background ───
	area.draw_rect(Rect2(0, 0, PIANO_WIDTH, sz.y), Color(0.09, 0.09, 0.11))
	# Redraw piano labels on top of bg
	for i in range(note_range):
		var midi_note = _view_note_max - 1 - i
		var y = grid_y0 + i * CELL_H
		var nname = NOTE_NAMES[midi_note % 12] + str(midi_note / 12 - 1)
		var col = Color(0.55, 0.55, 0.6) if midi_note % 12 in BLACK_KEYS else Color(0.7, 0.7, 0.75)
		if midi_note % 12 == 0:
			col = Color(0.9, 0.9, 0.95)
		area.draw_string(ThemeDB.fallback_font, Vector2(4, y + CELL_H - 2),
			nname, HORIZONTAL_ALIGNMENT_LEFT, PIANO_WIDTH - 8, 10, col)

# ── Grid Input ─────────────────────────────────────────────────────────
func _on_grid_input(event: InputEvent):
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_button(ev: InputEventMouseButton):
	var pos = ev.position
	if pos.x < PIANO_WIDTH or pos.y < HEADER_H:
		return

	match ev.button_index:
		MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_on_left_press(pos, ev.shift_pressed)
			else:
				_on_left_release()
		MOUSE_BUTTON_RIGHT:
			if ev.pressed:
				_on_right_press(pos)
		MOUSE_BUTTON_WHEEL_UP:
			if ev.pressed:
				if ev.ctrl_pressed:
					_zoom_x = clampf(_zoom_x * 1.15, 0.25, 6.0)
				elif ev.shift_pressed:
					_scroll_x = maxf(0, _scroll_x - _ticks_per_quarter)
				else:
					_view_note_min = mini(_view_note_min + 3, 124 - 12)
					_view_note_max = mini(_view_note_max + 3, 127)
				_grid_area.queue_redraw()
		MOUSE_BUTTON_WHEEL_DOWN:
			if ev.pressed:
				if ev.ctrl_pressed:
					_zoom_x = clampf(_zoom_x / 1.15, 0.25, 6.0)
				elif ev.shift_pressed:
					_scroll_x = maxf(0, _scroll_x + _ticks_per_quarter)
				else:
					_view_note_min = maxi(_view_note_min - 3, 0)
					_view_note_max = maxi(_view_note_max - 3, 12)
				_grid_area.queue_redraw()

func _on_left_press(pos: Vector2, shift: bool):
	var hit = _note_at_pos(pos)
	if hit.is_empty():
		# Place a new note
		if not shift:
			_selected_notes.clear()
		var tick = _pos_to_tick(pos)
		var note_val = _pos_to_note(pos)
		if _current_track >= 0 and _current_track < _tracks.size():
			var dur = _snap_ticks * 4 if _snap_ticks > 0 else _ticks_per_quarter  # 1 beat
			var new_note = {"tick": tick, "note": note_val, "velocity": _current_velocity, "duration": dur}
			_tracks[_current_track].notes.append(new_note)
			var ni = _tracks[_current_track].notes.size() - 1
			_selected_notes.append({"track_idx": _current_track, "note_idx": ni})
			_drag_mode = 1
			_drag_start_mouse = pos
			_drag_start_tick = tick
			_drag_start_note_val = note_val
			_drag_active = false
	else:
		# Hit an existing note
		var is_resize = _is_on_resize_edge(pos, hit)
		if shift:
			if not _is_note_selected(hit.track_idx, hit.note_idx):
				_selected_notes.append(hit)
		else:
			if not _is_note_selected(hit.track_idx, hit.note_idx):
				_selected_notes = [hit]
		var n = _tracks[hit.track_idx].notes[hit.note_idx]
		_drag_mode = 2 if is_resize else 1
		_drag_start_mouse = pos
		_drag_start_tick = n.tick
		_drag_start_note_val = n.note
		_drag_start_dur = n.duration
		_drag_active = false
	_grid_area.queue_redraw()

func _on_left_release():
	_drag_mode = 0
	_drag_active = false

func _on_right_press(pos: Vector2):
	var hit = _note_at_pos(pos)
	if not hit.is_empty():
		# Delete note
		_tracks[hit.track_idx].notes.remove_at(hit.note_idx)
		# Fix selection indices
		_selected_notes = _selected_notes.filter(func(s):
			return not (s.track_idx == hit.track_idx and s.note_idx == hit.note_idx))
		for s in _selected_notes:
			if s.track_idx == hit.track_idx and s.note_idx > hit.note_idx:
				s.note_idx -= 1
		_grid_area.queue_redraw()

func _handle_mouse_motion(ev: InputEventMouseMotion):
	if _drag_mode == 0:
		return
	if not _drag_active:
		if ev.position.distance_to(_drag_start_mouse) > 4:
			_drag_active = true
		else:
			return

	var ticks_per_16th = _ticks_per_quarter / 4
	var px_per_tick = (CELL_W * _zoom_x) / float(ticks_per_16th)
	var dx_ticks = int((ev.position.x - _drag_start_mouse.x) / px_per_tick)
	var dy_notes = -int((ev.position.y - _drag_start_mouse.y) / CELL_H)

	if _snap_ticks > 0:
		dx_ticks = (dx_ticks / _snap_ticks) * _snap_ticks

	for sel in _selected_notes:
		if sel.track_idx < 0 or sel.track_idx >= _tracks.size():
			continue
		var notes_arr = _tracks[sel.track_idx].notes
		if sel.note_idx < 0 or sel.note_idx >= notes_arr.size():
			continue
		var n = notes_arr[sel.note_idx]
		if _drag_mode == 1:
			# Move
			n.tick = maxi(0, _drag_start_tick + dx_ticks)
			n.note = clampi(_drag_start_note_val + dy_notes, 0, 127)
		elif _drag_mode == 2:
			# Resize duration
			n.duration = maxi(_snap_ticks if _snap_ticks > 0 else 30, _drag_start_dur + dx_ticks)
	_grid_area.queue_redraw()

# ── Hit testing ────────────────────────────────────────────────────────
func _note_at_pos(pos: Vector2) -> Dictionary:
	var ticks_per_16th = _ticks_per_quarter / 4
	var px_per_tick = (CELL_W * _zoom_x) / float(ticks_per_16th)
	var grid_x0 = PIANO_WIDTH

	# Check current track first, then others
	var order: Array[int] = [_current_track]
	for i in range(_tracks.size()):
		if i != _current_track:
			order.append(i)

	for ti in order:
		if ti < 0 or ti >= _tracks.size():
			continue
		var notes_arr = _tracks[ti].notes
		for ni in range(notes_arr.size() - 1, -1, -1):  # Reverse for top-drawn first
			var n = notes_arr[ni]
			var nx = grid_x0 + (n.tick - _scroll_x) * px_per_tick
			var nw = maxf(n.duration * px_per_tick, 2)
			var ny = HEADER_H + (_view_note_max - 1 - n.note) * CELL_H
			if pos.x >= nx and pos.x <= nx + nw and pos.y >= ny and pos.y <= ny + CELL_H:
				return {"track_idx": ti, "note_idx": ni}
	return {}

func _is_on_resize_edge(pos: Vector2, hit: Dictionary) -> bool:
	var ticks_per_16th = _ticks_per_quarter / 4
	var px_per_tick = (CELL_W * _zoom_x) / float(ticks_per_16th)
	var n = _tracks[hit.track_idx].notes[hit.note_idx]
	var nx = PIANO_WIDTH + (n.tick - _scroll_x) * px_per_tick
	var nw = maxf(n.duration * px_per_tick, 2)
	return pos.x >= nx + nw - RESIZE_EDGE

func _is_note_selected(ti: int, ni: int) -> bool:
	for s in _selected_notes:
		if s.track_idx == ti and s.note_idx == ni:
			return true
	return false

func _pos_to_tick(pos: Vector2) -> int:
	var ticks_per_16th = _ticks_per_quarter / 4
	var px_per_tick = (CELL_W * _zoom_x) / float(ticks_per_16th)
	var raw = int((pos.x - PIANO_WIDTH) / px_per_tick + _scroll_x)
	if _snap_ticks > 0:
		raw = (raw / _snap_ticks) * _snap_ticks
	return maxi(0, raw)

func _pos_to_note(pos: Vector2) -> int:
	var row = int((pos.y - HEADER_H) / CELL_H)
	return clampi(_view_note_max - 1 - row, 0, 127)

# ── Track Management ───────────────────────────────────────────────────
func _add_default_track():
	_tracks.append({
		"name": "Track 1", "channel": 0, "program": 0, "is_drum": false,
		"color": TRACK_COLORS[0], "notes": [], "muted": false, "solo": false
	})

func _on_add_track():
	var idx = _tracks.size()
	_tracks.append({
		"name": "Track %d" % (idx + 1), "channel": mini(idx, 15),
		"program": 0, "is_drum": false,
		"color": TRACK_COLORS[idx % TRACK_COLORS.size()],
		"notes": [], "muted": false, "solo": false
	})
	_update_track_dropdown()
	_current_track = _tracks.size() - 1
	_track_dropdown.select(_current_track)
	_grid_area.queue_redraw()

func _on_remove_track():
	if _tracks.size() <= 1:
		return
	_tracks.remove_at(_current_track)
	_selected_notes.clear()
	_current_track = clampi(_current_track, 0, _tracks.size() - 1)
	_update_track_dropdown()
	_grid_area.queue_redraw()

func _update_track_dropdown():
	_track_dropdown.clear()
	for i in range(_tracks.size()):
		_track_dropdown.add_item(_tracks[i].get("name", "Track %d" % (i + 1)), i)
	if _current_track < _track_dropdown.item_count:
		_track_dropdown.select(_current_track)

# ── Toolbar Callbacks ──────────────────────────────────────────────────
func _on_vel_selected(idx: int):
	match idx:
		0: _current_velocity = 50
		1: _current_velocity = 100
		2: _current_velocity = 127

func _on_snap_selected(idx: int):
	match idx:
		0: _snap_ticks = _ticks_per_quarter          # 1/4
		1: _snap_ticks = _ticks_per_quarter / 2       # 1/8
		2: _snap_ticks = _ticks_per_quarter / 4       # 1/16
		3: _snap_ticks = _ticks_per_quarter / 8       # 1/32
		4: _snap_ticks = 0                            # Off

# ── Playback ───────────────────────────────────────────────────────────
func _on_play():
	if _is_playing:
		_is_playing = false
		_play_btn.text = "▶ Play"
		return
	_is_playing = true
	_play_btn.text = "⏸ Pause"
	_last_triggered.clear()

func _on_stop():
	_is_playing = false
	_playback_tick = 0
	_play_btn.text = "▶ Play"
	_last_triggered.clear()
	# Stop all voices
	for player in _voice_pool:
		player.stop()
	_grid_area.queue_redraw()

func _trigger_playback_notes(prev_tick: int, curr_tick: int):
	# Trigger audio for notes whose start tick falls in [prev_tick, curr_tick)
	for t_idx in range(_tracks.size()):
		var track = _tracks[t_idx]
		if track.get("muted", false):
			continue
		var track_name = track.get("name", "").to_lower()
		for note in track.get("notes", []):
			var nt: int = note.get("tick", 0)
			if nt >= prev_tick and nt < curr_tick:
				var midi_note: int = note.get("note", 60)
				var vel: int = note.get("velocity", 100)
				var dur_ticks: int = note.get("duration", _ticks_per_quarter)
				# Convert duration from ticks to seconds
				var ticks_per_sec = _bpm / 60.0 * _ticks_per_quarter
				var dur_sec = float(dur_ticks) / ticks_per_sec
				var is_drum = track.get("is_drum", false)
				_play_midi_note_on_track(midi_note, vel, dur_sec, is_drum, track_name)


# ── Audio Synthesis ────────────────────────────────────────────────────
func _build_voice_pool():
	for i in range(VOICE_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -6.0
		add_child(player)
		_voice_pool.append(player)
		_voice_ages.append(0)


func _get_free_voice() -> int:
	# Find a voice that's not playing
	for i in range(VOICE_POOL_SIZE):
		if not _voice_pool[i].playing:
			return i
	# Voice stealing: pick the oldest
	var oldest_idx = 0
	var oldest_age = _voice_ages[0]
	for i in range(1, VOICE_POOL_SIZE):
		if _voice_ages[i] < oldest_age:
			oldest_age = _voice_ages[i]
			oldest_idx = i
	_voice_pool[oldest_idx].stop()
	return oldest_idx


func _midi_to_freq(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69.0) / 12.0)


func _play_midi_note(midi_note: int, velocity: int, duration_sec: float, is_drum: bool):
	# Legacy single-note play (uses current track for instrument detection)
	var track_name = ""
	if _current_track >= 0 and _current_track < _tracks.size():
		track_name = _tracks[_current_track].get("name", "").to_lower()
	_play_midi_note_on_track(midi_note, velocity, duration_sec, is_drum, track_name)


func _play_midi_note_on_track(midi_note: int, velocity: int, duration_sec: float, is_drum: bool, track_name: String):
	var voice_idx = _get_free_voice()
	_voice_ages[voice_idx] = _frame_counter
	var player = _voice_pool[voice_idx]
	
	# Volume from velocity (0-127 -> -20dB to 0dB)
	player.volume_db = lerp(-20.0, -3.0, float(velocity) / 127.0)
	
	var stream: AudioStreamWAV
	if is_drum:
		stream = _synth_drum_real(midi_note)
	else:
		var freq = _midi_to_freq(midi_note)
		stream = _synth_instrument(freq, minf(duration_sec, 2.0), track_name, midi_note)
	
	player.stream = stream
	player.play()


func _detect_instrument_type(track_name: String) -> String:
	# Map track names to instrument types
	if "pad" in track_name or "mellotron" in track_name:
		return "pad"
	elif "bass" in track_name or "sub" in track_name:
		return "bass"
	elif "lead" in track_name or "elp" in track_name:
		return "lead"
	elif "seq" in track_name or "kraftwerk" in track_name or "arp" in track_name:
		return "sequence"
	elif "vocoder" in track_name:
		return "vocoder"
	elif "acid" in track_name or "303" in track_name:
		return "acid"
	else:
		return "default"


func _synth_instrument(freq: float, duration: float, track_name: String, _midi_note: int) -> AudioStreamWAV:
	var instrument = _detect_instrument_type(track_name)
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	data.fill(0.0)
	
	match instrument:
		"pad":
			# Use real Moog warm pad from AudioSynthesizer
			AudioSynthesizer._generate_moog_warm_pad(data, sample_count, [freq])
		"bass":
			# Use real Minimoog fat bass
			AudioSynthesizer._generate_minimoog_fat_bass(data, sample_count, freq)
		"lead":
			# Screaming Moog lead — single note with vibrato and filter
			_synth_moog_lead_note(data, sample_count, freq)
		"sequence":
			# Kraftwerk-style plucky square wave
			_synth_kraftwerk_note(data, sample_count, freq)
		"vocoder":
			# Vocoder pad — formant-like synthesis
			_synth_vocoder_note(data, sample_count, freq)
		"acid":
			# 303 acid bass — saw + resonant filter
			_synth_acid_note(data, sample_count, freq)
		_:
			# Warm default — detuned saw with filter
			_synth_default_note(data, sample_count, freq)
	
	return _float_to_wav(data)


func _synth_moog_lead_note(data: PackedFloat32Array, sample_count: int, freq: float):
	# ELP-style screaming Moog lead — single note
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		# Vibrato (delayed onset)
		var vib_amount = clampf((progress - 0.2) * 2.0, 0.0, 1.0)
		var vibrato = sin(2.0 * PI * 5.5 * t) * 0.008 * vib_amount
		var f = freq * (1.0 + vibrato)
		# Three detuned saws
		var saw1 = fmod(t * f, 1.0) * 2.0 - 1.0
		var saw2 = fmod(t * f * 1.007, 1.0) * 2.0 - 1.0
		var saw3 = fmod(t * f * 0.993, 1.0) * 2.0 - 1.0
		var osc = (saw1 + saw2 + saw3) / 3.0
		# High resonance filter
		var cutoff = 0.3 + 0.5 * exp(-t * 2.0)
		osc = tanh(osc * (1.0 + cutoff * 2.0)) * cutoff
		# Envelope
		var env = 1.0
		if t < 0.01: env = t / 0.01
		elif progress > 0.85: env = (1.0 - progress) / 0.15
		data[i] = clampf(osc * env * 0.5, -1.0, 1.0)


func _synth_kraftwerk_note(data: PackedFloat32Array, sample_count: int, freq: float):
	# Kraftwerk sequence — clean square with resonant filter, plucky envelope
	var filter_state = 0.0
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		# Square wave
		var phase = fmod(t * freq, 1.0)
		var osc = 1.0 if phase < 0.5 else -1.0
		# Resonant lowpass with envelope
		var cutoff = 0.08 + 0.4 * exp(-t * 12.0)
		var res_boost = sin(2.0 * PI * freq * 1.5 * t) * 0.25 * exp(-t * 8.0)
		filter_state += cutoff * (osc - filter_state)
		var output = filter_state + res_boost
		# Short plucky envelope
		var env = exp(-t * 10.0) * 0.7 + 0.3
		if progress > 0.9: env *= (1.0 - progress) / 0.1
		data[i] = clampf(output * env * 0.45, -1.0, 1.0)


func _synth_vocoder_note(data: PackedFloat32Array, sample_count: int, freq: float):
	# Vocoder pad — multiple formant-like harmonics with modulation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var output = 0.0
		output += sin(2.0 * PI * freq * t) * 0.5
		output += sin(2.0 * PI * freq * 2.0 * t) * 0.3
		output += sin(2.0 * PI * freq * 3.0 * t) * 0.2
		# Breathing modulation
		var mod = sin(2.0 * PI * 0.5 * t) * 0.2 + 0.8
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		data[i] = clampf(output * mod * env * 0.3, -1.0, 1.0)


func _synth_acid_note(data: PackedFloat32Array, sample_count: int, freq: float):
	# TB-303 acid bass — saw with resonant filter envelope
	var filter_state = [0.0, 0.0, 0.0]
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		# Sawtooth
		var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
		# Filter with squelchy envelope
		var f_env = exp(-t * 6.0)
		var cutoff = 300.0 + f_env * 2000.0
		var resonance = 0.55
		var f = clampf(cutoff / SAMPLE_RATE * 2.0, 0.01, 0.85)
		var fb = resonance + resonance / (1.0 - f + 0.01)
		filter_state[0] += f * (saw - filter_state[0] + fb * (filter_state[0] - filter_state[2]))
		filter_state[1] += f * (filter_state[0] - filter_state[1])
		filter_state[2] += f * (filter_state[1] - filter_state[2])
		# Amp envelope
		var env = exp(-t * 3.0) * 0.7 + 0.3
		if progress > 0.9: env *= (1.0 - progress) / 0.1
		data[i] = clampf(filter_state[2] * env * 0.5, -1.0, 1.0)


func _synth_default_note(data: PackedFloat32Array, sample_count: int, freq: float):
	# Warm default — detuned saw with gentle filter
	var filter_state = 0.0
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var phase1 = fmod(t * freq, 1.0)
		var phase2 = fmod(t * freq * 1.005, 1.0)
		var saw = (phase1 * 2.0 - 1.0) * 0.5 + (phase2 * 2.0 - 1.0) * 0.5
		var cutoff = 0.15 + 0.35 * exp(-t * 4.0)
		filter_state += cutoff * (saw - filter_state)
		var env = 1.0
		if t < 0.005: env = t / 0.005
		elif progress > 0.8: env = (1.0 - progress) / 0.2
		data[i] = clampf(filter_state * env * 0.6, -1.0, 1.0)


func _synth_drum_real(midi_note: int) -> AudioStreamWAV:
	# Real drum synthesis matching AudioSynthesizer's motorik/808 drums
	var dur = 0.2 if midi_note == 36 else 0.15
	var sample_count = int(SAMPLE_RATE * dur)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	if midi_note == 36 or midi_note == 35:
		# Kick — matches motorik: sine with pitch drop from 135Hz to 55Hz
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			var kick_freq = 55.0 + exp(-t * 40.0) * 80.0
			data[i] = sin(2.0 * PI * kick_freq * t) * exp(-t * 10.0) * 0.8
	elif midi_note == 38 or midi_note == 40:
		# Snare — matches motorik: body + noise
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			var body = sin(2.0 * PI * 180.0 * t) * exp(-t * 20.0) * 0.3
			var noise = (randf() - 0.5) * exp(-t * 20.0) * 0.5
			data[i] = clampf(body + noise, -1.0, 1.0)
	elif midi_note == 39:
		# Clap — layered noise bursts
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			var clap = 0.0
			for layer in [0.0, 0.01, 0.02]:
				if t >= layer:
					clap += (randf() - 0.5) * exp(-(t - layer) * 35.0) * 0.4
			data[i] = clampf(clap, -1.0, 1.0)
	elif midi_note == 42 or midi_note == 44:
		# Closed hi-hat — metallic noise, fast decay
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			data[i] = (randf() - 0.5) * exp(-t * 80.0) * 0.3
	elif midi_note == 46:
		# Open hi-hat — longer decay
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			data[i] = (randf() - 0.5) * exp(-t * 25.0) * 0.3
	else:
		# Generic percussion
		for i in range(sample_count):
			var t = float(i) / SAMPLE_RATE
			data[i] = (randf() - 0.5) * exp(-t * 40.0) * 0.3
	
	return _float_to_wav(data)


func _float_to_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	# Convert float samples to 16-bit AudioStreamWAV
	var byte_data = PackedByteArray()
	byte_data.resize(data.size() * 2)
	for i in range(data.size()):
		var sample_16 = int(clampf(data[i], -1.0, 1.0) * 32767.0)
		byte_data[i * 2] = sample_16 & 0xFF
		byte_data[i * 2 + 1] = (sample_16 >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.data = byte_data
	return stream


# ── Import / Export ────────────────────────────────────────────────────
func _on_import_pressed():
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Import MIDI File"
	_file_dialog.popup_centered(Vector2(700, 500))

func _on_export_pressed():
	var capture = export_to_capture()
	if capture == null or capture.tracks.is_empty():
		return
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var out_path = "user://exports/midi_editor_%s.mid" % timestamp
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://exports"))
	var ok = MidiExporter.export_from_capture(capture, out_path)
	if ok:
		print("MidiPianoRoll: Exported to %s" % ProjectSettings.globalize_path(out_path))

func _on_file_selected(path: String):
	load_from_file(path)

func _on_song_selected(idx: int):
	if idx <= 0:
		return
	var song_id = _song_dropdown.get_item_text(idx)
	var capture = AudioSynthesizer.capture_midi_for_song(song_id)
	if capture:
		load_from_capture(capture)
	_song_dropdown.select(0)

# ── Public API: Load / Export ──────────────────────────────────────────
func load_from_capture(capture) -> void:
	# Accept MidiCapture (RefCounted, can't type-hint robustly across autoloads)
	_tracks.clear()
	_selected_notes.clear()
	_bpm = capture.bpm
	_bpm_spin.value = _bpm
	_ticks_per_quarter = capture.ticks_per_quarter
	for track in capture.tracks:
		_tracks.append({
			"name": track.get("name", "Track"),
			"channel": track.get("channel", 0),
			"program": track.get("program", 0),
			"is_drum": track.get("is_drum", false),
			"color": TRACK_COLORS[_tracks.size() % TRACK_COLORS.size()],
			"notes": _dup_events(track.get("events", [])),
			"muted": false,
			"solo": false
		})
	_current_track = 0
	_update_track_dropdown()
	_auto_fit_view()
	_grid_area.queue_redraw()

func export_to_capture() -> MidiCapture:
	var capture = MidiCapture.new()
	capture.bpm = _bpm
	capture.ticks_per_quarter = _ticks_per_quarter
	capture.song_name = "MIDI Editor Export"
	for track in _tracks:
		var idx = capture.add_track(track.name, track.channel, track.program, track.get("is_drum", false))
		for note in track.notes:
			capture.add_note(idx, note.tick, note.note, note.velocity, note.duration)
	return capture

func load_from_file(path: String):
	var config = MidiImporter.import_midi(path)
	if config.is_empty():
		return
	_bpm = config.get("bpm", 120.0)
	_bpm_spin.value = _bpm
	_tracks.clear()
	_selected_notes.clear()
	for track_data in config.get("tracks", []):
		var track := {
			"name": track_data.get("name", "Track"),
			"channel": track_data.get("channel", 0),
			"program": track_data.get("program", 0),
			"is_drum": track_data.get("is_drum", false),
			"color": TRACK_COLORS[_tracks.size() % TRACK_COLORS.size()],
			"notes": [] as Array[Dictionary],
			"muted": false, "solo": false,
		}
		for note_data in track_data.get("notes", []):
			if note_data is Dictionary:
				track.notes.append({
					"tick": note_data.get("tick", 0),
					"note": note_data.get("note", 60),
					"velocity": note_data.get("velocity", 100),
					"duration": note_data.get("duration", 480),
				})
			else:
				# MidiImporter.MidiNote object
				track.notes.append({
					"tick": note_data.tick,
					"note": note_data.note,
					"velocity": note_data.velocity,
					"duration": note_data.duration,
				})
		_tracks.append(track)
	_current_track = 0
	_update_track_dropdown()
	_auto_fit_view()
	_grid_area.queue_redraw()

# ── Utilities ──────────────────────────────────────────────────────────
func _dup_events(events: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		out.append({"tick": e.tick, "note": e.note, "velocity": e.velocity, "duration": e.duration})
	return out

func _auto_fit_view():
	"""Center view on the note range present in the data."""
	var lo = 127
	var hi = 0
	for trk in _tracks:
		for n in trk.notes:
			lo = mini(lo, n.note)
			hi = maxi(hi, n.note)
	if lo > hi:
		lo = 48; hi = 72
	var margin = 6
	_view_note_min = clampi(lo - margin, 0, 115)
	_view_note_max = clampi(hi + margin, 12, 127)
	# Ensure at least 2 octaves visible
	if _view_note_max - _view_note_min < 24:
		var center = (_view_note_min + _view_note_max) / 2
		_view_note_min = clampi(center - 18, 0, 103)
		_view_note_max = clampi(center + 18, 24, 127)
	_scroll_x = 0
