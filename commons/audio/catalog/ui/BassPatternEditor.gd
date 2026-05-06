# BassPatternEditor.gd
# Bass pattern editor extending BasePatternEditor
# Piano roll style - rows = pitches (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)

extends BasePatternEditor
class_name BassPatternEditor

# Note names (chromatic)
const NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Bass-specific data
var _pattern: Array = []       # 16 floats (velocities)
var _notes: Array = []         # 16 ints (MIDI note numbers)
var _glides: Array = []        # 16 bools
var _root_note: int = 36       # C2
var _octave: int = 2
var _visible_octaves: int = 2  # How many octaves to show in piano roll
var _base_octave: int = 1      # Starting octave for display

# UI
var _root_dropdown: OptionButton
var _octave_spin: SpinBox

# Dragging for pitch change
var _pitch_drag_active: bool = false
var _pitch_drag_step: int = -1
var _pitch_drag_start_note: int = 0
var _pitch_drag_start_y: float = 0


func _get_editor_title() -> String:
	return "ðŸŽ¸ BASS TIMELINE"


func _get_editor_color() -> Color:
	return Color(0.3, 0.8, 0.6)


func _get_row_count() -> int:
	# Piano roll: show 2 octaves (24 semitones)
	return _visible_octaves * 12


func _get_row_label(row: int) -> String:
	# Row 0 = highest note, going down
	var note_offset = (_get_row_count() - 1) - row
	var note_name = NOTE_NAMES[note_offset % 12]
	var octave = _base_octave + (note_offset / 12)
	return "%s%d" % [note_name, octave]


func _get_row_sound(_row: int) -> String:
	return "bass"


func _get_row_color(row: int) -> Color:
	# Color white keys and black keys differently
	var note_offset = (_get_row_count() - 1) - row
	var note_in_octave = note_offset % 12
	var is_black_key = note_in_octave in [1, 3, 6, 8, 10]  # C#, D#, F#, G#, A#
	
	if is_black_key:
		return Color(0.2, 0.45, 0.35)  # Darker green for black keys
	else:
		return Color(0.3, 0.6, 0.45)   # Normal green for white keys


func _initialize_pattern():
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	
	for i in range(_step_count):
		_pattern.append(0.0)
		_notes.append(_root_note)
		_glides.append(false)


func _on_extra_controls_setup(container: HBoxContainer):
	# Root note selector
	var root_label = Label.new()
	root_label.text = "Root:"
	root_label.add_theme_font_size_override("font_size", 12)
	container.add_child(root_label)
	
	_root_dropdown = OptionButton.new()
	for note in NOTE_NAMES:
		_root_dropdown.add_item(note)
	_root_dropdown.selected = 0  # C
	_root_dropdown.item_selected.connect(_on_root_changed)
	container.add_child(_root_dropdown)
	
	# Octave selector
	var oct_label = Label.new()
	oct_label.text = "Octave:"
	oct_label.add_theme_font_size_override("font_size", 12)
	container.add_child(oct_label)
	
	_octave_spin = SpinBox.new()
	_octave_spin.min_value = 0
	_octave_spin.max_value = 5
	_octave_spin.value = 2
	_octave_spin.value_changed.connect(_on_octave_changed)
	container.add_child(_octave_spin)


func _get_step_data(row: int, step: int) -> Dictionary:
	if step >= _pattern.size():
		return {"active": false, "velocity": 0.0, "note": _root_note, "glide": false}
	
	# Check if this row matches the note for this step
	var step_note = _notes[step] if step < _notes.size() else _root_note
	var row_note = _row_to_note(row)
	
	var is_active = _pattern[step] > 0 and step_note == row_note
	
	return {
		"active": is_active,
		"velocity": _pattern[step] if is_active else 0.0,
		"note": step_note,
		"glide": _glides[step] if step < _glides.size() else false,
		"row_note": row_note
	}


func _set_step_data(_row: int, step: int, data: Dictionary):
	if step >= _step_count:
		return
	
	while _pattern.size() <= step:
		_pattern.append(0.0)
	while _notes.size() <= step:
		_notes.append(_root_note)
	while _glides.size() <= step:
		_glides.append(false)
	
	_pattern[step] = data.get("velocity", 0.0)
	if data.has("note"):
		_notes[step] = data["note"]
	if data.has("glide"):
		_glides[step] = data["glide"]


func _row_to_note(row: int) -> int:
	"""Convert row index to MIDI note number"""
	var note_offset = (_get_row_count() - 1) - row
	return (_base_octave * 12) + 12 + note_offset  # +12 for MIDI offset


func _note_to_row(midi_note: int) -> int:
	"""Convert MIDI note to row index"""
	var note_offset = midi_note - ((_base_octave * 12) + 12)
	return (_get_row_count() - 1) - note_offset


func _on_step_clicked(row: int, step: int, button: int):
	var current_data = _get_step_data(row, step)
	var row_note = _row_to_note(row)
	
	if button == MOUSE_BUTTON_LEFT:
		# Check if there's already a note at this step
		if _pattern[step] > 0:
			# If clicking on the same note, remove it
			if _notes[step] == row_note:
				_pattern[step] = 0.0
			else:
				# Move note to this row (monophonic - only one note per step)
				_notes[step] = row_note
		else:
			# Place new note
			_pattern[step] = 1.0
			_notes[step] = row_note
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())


func _on_step_drag(row: int, step: int, button: int):
	# For bass, dragging changes the pitch of the note at the step
	if _drag_start_step >= 0 and _pattern[_drag_start_step] > 0:
		var new_note = _row_to_note(row)
		_notes[_drag_start_step] = new_note
		_rebuild_grid()


func _render_step(_row: int, step: int, cell: Control, data: Dictionary):
	# Add glide indicator if active
	if data.get("active", false) and data.get("glide", false):
		var glide_label = cell.get_node_or_null("GlideLabel")
		if not glide_label:
			glide_label = Label.new()
			glide_label.name = "GlideLabel"
			glide_label.text = "~"
			glide_label.add_theme_font_size_override("font_size", 12)
			glide_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
			glide_label.position = Vector2(CELL_SIZE.x - 14, 4)
			cell.add_child(glide_label)
	else:
		var glide_label = cell.get_node_or_null("GlideLabel")
		if glide_label:
			glide_label.queue_free()


func _cycle_velocity(row: int, step: int, direction: int):
	"""Right-click toggles glide instead of cycling velocity"""
	if step < _pattern.size() and _pattern[step] > 0:
		_glides[step] = not _glides[step]
		_update_cell(row, step)
		pattern_changed.emit(_get_pattern_for_export())


func _get_pattern_for_export() -> Dictionary:
	return {
		"pattern": _pattern.duplicate(),
		"notes": _notes.duplicate(),
		"glides": _glides.duplicate(),
		"root": _root_note,
		"octave": _octave
	}


func _trigger_step_sounds(step: int):
	if step < _pattern.size() and _pattern[step] > 0:
		preview_requested.emit(_notes[step])


# ===== BASS-SPECIFIC METHODS =====

func load_pattern(pattern: Array, notes: Array = [], glides: Array = []):
	"""Load bass pattern data"""
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	
	for i in range(_step_count):
		_pattern.append(pattern[i] if i < pattern.size() else 0.0)
		_notes.append(notes[i] if i < notes.size() else _root_note)
		_glides.append(glides[i] if i < glides.size() else false)
	
	_rebuild_grid()


func set_root_note(note_name: String, octave: int = -1):
	"""Set root note by name"""
	var idx = NOTE_NAMES.find(note_name)
	if idx >= 0:
		if octave >= 0:
			_octave = octave
		_root_note = 12 + idx + (_octave * 12)
		_root_dropdown.selected = idx
		if octave >= 0:
			_octave_spin.value = octave


func get_root_note() -> int:
	return _root_note


func get_note_at_step(step: int) -> int:
	if step < _notes.size():
		return _notes[step]
	return _root_note


func has_glide_at_step(step: int) -> bool:
	if step < _glides.size():
		return _glides[step]
	return false


func _on_root_changed(index: int):
	_root_note = 12 + index + (_octave * 12)
	# Update default notes for empty steps
	for i in range(_step_count):
		if _pattern[i] == 0:
			_notes[i] = _root_note


func _on_octave_changed(value: float):
	_octave = int(value)
	_root_note = 12 + (_root_dropdown.selected) + (_octave * 12)
	_base_octave = maxi(0, _octave - 1)
	_rebuild_grid()


# ===== SCALE-AWARE NOTE HELPERS =====

const SCALES = {
	"major": [0, 2, 4, 5, 7, 9, 11],
	"minor": [0, 2, 3, 5, 7, 8, 10],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
	"lydian": [0, 2, 4, 6, 7, 9, 11],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"aeolian": [0, 2, 3, 5, 7, 8, 10],
	"locrian": [0, 1, 3, 5, 6, 8, 10],
	"pentatonic_major": [0, 2, 4, 7, 9],
	"pentatonic_minor": [0, 3, 5, 7, 10],
	"blues": [0, 3, 5, 6, 7, 10],
}


func generate_walking_bass(scale_name: String = "minor", bars: int = 1):
	"""Generate a walking bass line"""
	var scale = SCALES.get(scale_name, SCALES["minor"])
	var root = _root_note % 12
	
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	
	for bar in range(bars):
		for beat in range(4):
			var step = bar * 4 + beat
			if step >= _step_count:
				break
			
			# Walking bass typically moves stepwise
			var scale_degree = (beat % scale.size())
			var note = root + scale[scale_degree] + (_octave * 12)
			
			_pattern.append(1.0 if beat == 0 else 0.8)  # Accent on beat 1
			_notes.append(note)
			_glides.append(beat == 3)  # Glide into next bar
	
	# Fill remaining steps
	while _pattern.size() < _step_count:
		_pattern.append(0.0)
		_notes.append(_root_note)
		_glides.append(false)
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())


func generate_octave_bass(accent_on: Array = [0, 8]):
	"""Generate octave-based bass pattern"""
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	
	for i in range(_step_count):
		if i in accent_on:
			_pattern.append(1.0)
			_notes.append(_root_note)
		elif (i + 2) in accent_on:
			_pattern.append(0.7)
			_notes.append(_root_note + 12)  # Octave up
		else:
			_pattern.append(0.0)
			_notes.append(_root_note)
		_glides.append(false)
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())
