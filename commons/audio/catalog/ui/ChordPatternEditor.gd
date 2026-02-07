# ChordPatternEditor.gd
# Chord pattern editor extending BasePatternEditor
# Rows = chord degrees (I, ii, iii, IV, V, vi, vii°)

extends BasePatternEditor
class_name ChordPatternEditor

# Roman numeral chord degrees
const CHORD_DEGREES = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
const VOICINGS = ["Root", "1st Inv", "2nd Inv", "Open"]

const CHORD_COLORS = {
	"I": Color(0.3, 0.6, 0.85),
	"ii": Color(0.4, 0.5, 0.7),
	"iii": Color(0.5, 0.45, 0.65),
	"IV": Color(0.6, 0.5, 0.3),
	"V": Color(0.7, 0.45, 0.35),
	"vi": Color(0.55, 0.4, 0.6),
	"vii°": Color(0.5, 0.35, 0.5),
}

# Chord-specific data
var _pattern: Array = []      # 16 floats (velocities)
var _chords: Array = []       # 16 strings (chord degree or "rest")
var _voicings: Array = []     # 16 ints (voicing index)
var _sustains: Array = []     # 16 bools (sustain from previous)
var _key: String = "C"
var _scale: String = "major"

# UI
var _key_dropdown: OptionButton
var _scale_dropdown: OptionButton
var _voicing_dropdown: OptionButton

# Override cell size for wider chord blocks
const CHORD_CELL_SIZE = Vector2(50, 50)


func _get_editor_title() -> String:
	return "🎹 CHORD TIMELINE"


func _get_editor_color() -> Color:
	return Color(0.6, 0.5, 0.85)


func _get_row_count() -> int:
	return CHORD_DEGREES.size()


func _get_row_label(row: int) -> String:
	if row < CHORD_DEGREES.size():
		return CHORD_DEGREES[row]
	return "?"


func _get_row_sound(row: int) -> String:
	if row < CHORD_DEGREES.size():
		return CHORD_DEGREES[row]
	return "I"


func _get_row_color(row: int) -> Color:
	if row < CHORD_DEGREES.size():
		return CHORD_COLORS.get(CHORD_DEGREES[row], Color(0.5, 0.5, 0.6))
	return Color(0.5, 0.5, 0.6)


func _initialize_pattern():
	_pattern.clear()
	_chords.clear()
	_voicings.clear()
	_sustains.clear()
	
	for i in range(_step_count):
		_pattern.append(0.0)
		_chords.append("rest")
		_voicings.append(0)
		_sustains.append(false)


func _on_extra_controls_setup(container: HBoxContainer):
	# Key selector
	var key_label = Label.new()
	key_label.text = "Key:"
	key_label.add_theme_font_size_override("font_size", 12)
	container.add_child(key_label)
	
	_key_dropdown = OptionButton.new()
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	for note in notes:
		_key_dropdown.add_item(note)
	_key_dropdown.selected = 0
	_key_dropdown.item_selected.connect(_on_key_changed)
	container.add_child(_key_dropdown)
	
	# Scale selector
	var scale_label = Label.new()
	scale_label.text = "Scale:"
	scale_label.add_theme_font_size_override("font_size", 12)
	container.add_child(scale_label)
	
	_scale_dropdown = OptionButton.new()
	_scale_dropdown.add_item("Major")
	_scale_dropdown.add_item("Minor")
	_scale_dropdown.add_item("Dorian")
	_scale_dropdown.add_item("Mixolydian")
	_scale_dropdown.selected = 0
	_scale_dropdown.item_selected.connect(_on_scale_changed)
	container.add_child(_scale_dropdown)
	
	# Voicing selector
	var voicing_label = Label.new()
	voicing_label.text = "Voicing:"
	voicing_label.add_theme_font_size_override("font_size", 12)
	container.add_child(voicing_label)
	
	_voicing_dropdown = OptionButton.new()
	for v in VOICINGS:
		_voicing_dropdown.add_item(v)
	_voicing_dropdown.selected = 0
	container.add_child(_voicing_dropdown)


func _get_step_data(row: int, step: int) -> Dictionary:
	if step >= _pattern.size() or row >= CHORD_DEGREES.size():
		return {"active": false, "velocity": 0.0, "chord": "rest"}
	
	var chord_degree = CHORD_DEGREES[row]
	var step_chord = _chords[step] if step < _chords.size() else "rest"
	
	# Check if this row's chord is active at this step
	var is_active = _pattern[step] > 0 and step_chord == chord_degree
	
	return {
		"active": is_active,
		"velocity": _pattern[step] if is_active else 0.0,
		"chord": step_chord,
		"voicing": _voicings[step] if step < _voicings.size() else 0,
		"sustain": _sustains[step] if step < _sustains.size() else false,
		"row_chord": chord_degree
	}


func _set_step_data(row: int, step: int, data: Dictionary):
	if step >= _step_count or row >= CHORD_DEGREES.size():
		return
	
	while _pattern.size() <= step:
		_pattern.append(0.0)
	while _chords.size() <= step:
		_chords.append("rest")
	while _voicings.size() <= step:
		_voicings.append(0)
	while _sustains.size() <= step:
		_sustains.append(false)
	
	_pattern[step] = data.get("velocity", 0.0)
	if data.has("chord"):
		_chords[step] = data["chord"]
	if data.has("voicing"):
		_voicings[step] = data["voicing"]
	if data.has("sustain"):
		_sustains[step] = data["sustain"]


func _on_step_clicked(row: int, step: int, button: int):
	if row >= CHORD_DEGREES.size():
		return
	
	var chord_degree = CHORD_DEGREES[row]
	
	if button == MOUSE_BUTTON_LEFT:
		# Check if this chord is already active
		if _pattern[step] > 0 and _chords[step] == chord_degree:
			# Toggle off
			_pattern[step] = 0.0
			_chords[step] = "rest"
		else:
			# Place chord (replaces any existing)
			_pattern[step] = 1.0
			_chords[step] = chord_degree
			_voicings[step] = _voicing_dropdown.selected
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())


func _cycle_velocity(row: int, step: int, direction: int):
	"""Right-click toggles sustain instead of cycling velocity"""
	if step < _pattern.size() and _pattern[step] > 0:
		_sustains[step] = not _sustains[step]
		_rebuild_grid()  # Need full rebuild to show sustain lines
		pattern_changed.emit(_get_pattern_for_export())


func _render_step(row: int, step: int, cell: Control, data: Dictionary):
	var is_active = data.get("active", false)
	
	if is_active:
		# Add chord label
		var chord_label = cell.get_node_or_null("ChordLabel")
		if not chord_label:
			chord_label = Label.new()
			chord_label.name = "ChordLabel"
			chord_label.add_theme_font_size_override("font_size", 14)
			chord_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
			chord_label.position = Vector2(4, 2)
			cell.add_child(chord_label)
		chord_label.text = data.get("row_chord", "?")
		
		# Add voicing indicator
		var voicing_label = cell.get_node_or_null("VoicingLabel")
		if not voicing_label:
			voicing_label = Label.new()
			voicing_label.name = "VoicingLabel"
			voicing_label.add_theme_font_size_override("font_size", 9)
			voicing_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
			voicing_label.position = Vector2(4, 16)
			cell.add_child(voicing_label)
		var voicing_idx = data.get("voicing", 0)
		voicing_label.text = VOICINGS[voicing_idx].substr(0, 4) if voicing_idx < VOICINGS.size() else ""
		
		# Sustain indicator
		if data.get("sustain", false):
			var sustain_rect = cell.get_node_or_null("SustainRect")
			if not sustain_rect:
				sustain_rect = ColorRect.new()
				sustain_rect.name = "SustainRect"
				sustain_rect.size = Vector2(8, 4)
				sustain_rect.position = Vector2(CELL_SIZE.x - 10, CELL_SIZE.y / 2 - 4)
				cell.add_child(sustain_rect)
			sustain_rect.color = _get_row_color(row).lightened(0.3)
		else:
			var sustain_rect = cell.get_node_or_null("SustainRect")
			if sustain_rect:
				sustain_rect.queue_free()
	else:
		# Remove labels from inactive cells
		for label_name in ["ChordLabel", "VoicingLabel", "SustainRect"]:
			var label = cell.get_node_or_null(label_name)
			if label:
				label.queue_free()


func _get_pattern_for_export() -> Dictionary:
	return {
		"pattern": _pattern.duplicate(),
		"chords": _chords.duplicate(),
		"voicings": _voicings.duplicate(),
		"sustains": _sustains.duplicate(),
		"key": _key,
		"scale": _scale
	}


func _trigger_step_sounds(step: int):
	if step < _pattern.size() and _pattern[step] > 0:
		var chord = _chords[step] if step < _chords.size() else "I"
		preview_requested.emit(chord)


# ===== CHORD-SPECIFIC METHODS =====

func load_pattern(pattern: Array, chords: Array = [], voicings: Array = [], sustains: Array = []):
	"""Load chord pattern data"""
	_pattern.clear()
	_chords.clear()
	_voicings.clear()
	_sustains.clear()
	
	for i in range(_step_count):
		_pattern.append(pattern[i] if i < pattern.size() else 0.0)
		_chords.append(chords[i] if i < chords.size() else "rest")
		_voicings.append(voicings[i] if i < voicings.size() else 0)
		_sustains.append(sustains[i] if i < sustains.size() else false)
	
	_rebuild_grid()


func set_key(key: String):
	"""Set the musical key"""
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var idx = notes.find(key)
	if idx >= 0:
		_key = key
		_key_dropdown.selected = idx


func get_key() -> String:
	return _key


func set_music_scale(scale_name: String):
	"""Set the musical scale (renamed to avoid Control.set_scale conflict)"""
	var scales = ["major", "minor", "dorian", "mixolydian"]
	var idx = scales.find(scale_name.to_lower())
	if idx >= 0:
		_scale = scale_name.to_lower()
		_scale_dropdown.selected = idx


func get_music_scale() -> String:
	return _scale


func get_chord_at_step(step: int) -> String:
	if step < _chords.size():
		return _chords[step]
	return "rest"


func get_voicing_at_step(step: int) -> int:
	if step < _voicings.size():
		return _voicings[step]
	return 0


func has_sustain_at_step(step: int) -> bool:
	if step < _sustains.size():
		return _sustains[step]
	return false


func _on_key_changed(index: int):
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	_key = notes[index]


func _on_scale_changed(index: int):
	var scales = ["major", "minor", "dorian", "mixolydian"]
	_scale = scales[index]


# ===== CHORD PROGRESSION PRESETS =====

func load_progression(progression_name: String):
	"""Load common chord progressions"""
	var progressions = {
		"pop_1564": ["I", "V", "vi", "IV"],
		"jazz_251": ["ii", "V", "I", "I"],
		"blues": ["I", "I", "I", "I", "IV", "IV", "I", "I", "V", "IV", "I", "V"],
		"sad": ["vi", "IV", "I", "V"],
		"andalusian": ["vi", "V", "IV", "III"],
		"canon": ["I", "V", "vi", "iii", "IV", "I", "IV", "V"],
	}
	
	var prog = progressions.get(progression_name, [])
	if prog.is_empty():
		return
	
	_pattern.clear()
	_chords.clear()
	_voicings.clear()
	_sustains.clear()
	
	# Map progression to 16 steps (4 steps per chord)
	var steps_per_chord = _step_count / prog.size()
	
	for i in range(_step_count):
		var chord_idx = i / steps_per_chord
		chord_idx = mini(chord_idx, prog.size() - 1)
		
		var chord = prog[chord_idx]
		var is_first_step = (i % steps_per_chord) == 0
		
		_pattern.append(1.0 if is_first_step else 0.0)
		_chords.append(chord if is_first_step else "rest")
		_voicings.append(0)
		_sustains.append(not is_first_step and i > 0)
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())


# ===== CHORD HELPERS =====

func get_chord_notes(degree: String, key: String = "", voicing: int = 0) -> Array:
	"""Get MIDI notes for a chord degree"""
	if key.is_empty():
		key = _key
	
	# Key to root note
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var root = notes.find(key)
	if root < 0:
		root = 0
	
	# Scale intervals (major scale)
	var scale_intervals = [0, 2, 4, 5, 7, 9, 11]  # Major
	if _scale == "minor":
		scale_intervals = [0, 2, 3, 5, 7, 8, 10]
	
	# Chord degree to scale degree (0-indexed)
	var degree_map = {"I": 0, "ii": 1, "iii": 2, "IV": 3, "V": 4, "vi": 5, "vii°": 6}
	var scale_degree = degree_map.get(degree, 0)
	
	# Build triad
	var chord_root = root + scale_intervals[scale_degree]
	var third = scale_intervals[(scale_degree + 2) % 7]
	var fifth = scale_intervals[(scale_degree + 4) % 7]
	
	# Adjust for octave wrapping
	if third < scale_intervals[scale_degree]:
		third += 12
	if fifth < scale_intervals[scale_degree]:
		fifth += 12
	
	var chord_notes = [chord_root + 48, chord_root + third + 48, chord_root + fifth + 48]  # C3 base
	
	# Apply voicing
	match voicing:
		1:  # 1st inversion
			chord_notes[0] += 12
		2:  # 2nd inversion
			chord_notes[0] += 12
			chord_notes[1] += 12
		3:  # Open voicing
			chord_notes[1] += 12
	
	return chord_notes
