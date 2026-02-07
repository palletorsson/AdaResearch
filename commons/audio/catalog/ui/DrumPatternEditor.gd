# DrumPatternEditor.gd
# Drum pattern editor extending BasePatternEditor
# Rows = drum elements (kick, snare, hihat, clap, etc.)

extends BasePatternEditor
class_name DrumPatternEditor

# Drum-specific data
var _elements: Array = ["kick", "snare", "hihat", "clap"]
var _element_patterns: Dictionary = {}  # element -> Array[16 floats]
var _element_mutes: Dictionary = {}     # element -> bool
var _element_solos: Dictionary = {}     # element -> bool
var _kit_name: String = "808_kit"

# UI
var _kit_dropdown: OptionButton
var _mute_buttons: Dictionary = {}
var _solo_buttons: Dictionary = {}

# Available kits
const DRUM_KITS = [
	"808_kit", "909_kit", "cr78_kit", "linndrum_kit", 
	"trap_kit", "acoustic_kit", "breakbeat_kit"
]


func _get_editor_title() -> String:
	return "🥁 DRUM SEQUENCER"


func _get_editor_color() -> Color:
	return Color(0.9, 0.7, 0.3)


func _get_row_count() -> int:
	return _elements.size()


func _get_row_label(row: int) -> String:
	if row < _elements.size():
		return _elements[row].capitalize()
	return "Row %d" % row


func _get_row_sound(row: int) -> String:
	if row < _elements.size():
		return _elements[row]
	return "kick"


func _get_row_color(row: int) -> Color:
	# Use default velocity colors
	return Color.WHITE


func _initialize_pattern():
	_element_patterns.clear()
	_element_mutes.clear()
	_element_solos.clear()
	
	for element in _elements:
		_element_patterns[element] = []
		_element_mutes[element] = false
		_element_solos[element] = false
		for i in range(_step_count):
			_element_patterns[element].append(0.0)


func _on_extra_controls_setup(container: HBoxContainer):
	# Kit selector
	var kit_label = Label.new()
	kit_label.text = "Kit:"
	kit_label.add_theme_font_size_override("font_size", 12)
	container.add_child(kit_label)
	
	_kit_dropdown = OptionButton.new()
	for kit in DRUM_KITS:
		_kit_dropdown.add_item(kit.replace("_", " ").capitalize())
	_kit_dropdown.selected = 0
	_kit_dropdown.item_selected.connect(_on_kit_changed)
	container.add_child(_kit_dropdown)


func _get_step_data(row: int, step: int) -> Dictionary:
	if row >= _elements.size():
		return {"active": false, "velocity": 0.0}
	
	var element = _elements[row]
	var velocity = 0.0
	
	if _element_patterns.has(element) and step < _element_patterns[element].size():
		velocity = _element_patterns[element][step]
	
	return {
		"active": velocity > 0,
		"velocity": velocity,
		"element": element
	}


func _set_step_data(row: int, step: int, data: Dictionary):
	if row >= _elements.size():
		return
	
	var element = _elements[row]
	if not _element_patterns.has(element):
		_element_patterns[element] = []
		for i in range(_step_count):
			_element_patterns[element].append(0.0)
	
	if step < _element_patterns[element].size():
		_element_patterns[element][step] = data.get("velocity", 0.0)


func _on_step_clicked(row: int, step: int, button: int):
	if row >= _elements.size():
		return
	
	var data = _get_step_data(row, step)
	var current_vel = data.get("velocity", 0.0)
	
	# Toggle on/off
	var new_vel = 1.0 if current_vel == 0 else 0.0
	
	data["velocity"] = new_vel
	data["active"] = new_vel > 0
	_set_step_data(row, step, data)
	
	_update_cell(row, step)
	pattern_changed.emit(_get_pattern_for_export())


func _on_step_drag(row: int, step: int, button: int):
	# Apply same action as drag start
	if _drag_start_row >= 0 and _drag_start_step >= 0:
		var start_data = _get_step_data(_drag_start_row, _drag_start_step)
		var start_vel = start_data.get("velocity", 0.0)
		
		# Apply to current cell
		var data = _get_step_data(row, step)
		data["velocity"] = start_vel
		data["active"] = start_vel > 0
		_set_step_data(row, step, data)
		
		_update_cell(row, step)


func _get_pattern_for_export() -> Dictionary:
	return _element_patterns.duplicate(true)


func _trigger_step_sounds(step: int):
	"""Trigger sounds for active drum elements at this step"""
	var any_solo = false
	for element in _elements:
		if _element_solos.get(element, false):
			any_solo = true
			break
	
	for row in range(_elements.size()):
		var element = _elements[row]
		
		# Check mute/solo
		if _element_mutes.get(element, false):
			continue
		if any_solo and not _element_solos.get(element, false):
			continue
		
		var data = _get_step_data(row, step)
		if data.get("velocity", 0.0) > 0:
			preview_requested.emit(element)


# ===== DRUM-SPECIFIC METHODS =====

func load_patterns(patterns: Dictionary, elements: Array = []):
	"""Load drum patterns from SoundbankGenerator format"""
	_element_patterns.clear()
	_elements.clear()
	_element_mutes.clear()
	_element_solos.clear()
	
	# Determine elements to show
	if elements.is_empty():
		_elements = patterns.keys()
	else:
		_elements = elements
	
	# Copy patterns
	for element in _elements:
		_element_mutes[element] = false
		_element_solos[element] = false
		
		if patterns.has(element):
			_element_patterns[element] = []
			for i in range(_step_count):
				var val = patterns[element][i] if i < patterns[element].size() else 0.0
				_element_patterns[element].append(val)
		else:
			_element_patterns[element] = []
			for i in range(_step_count):
				_element_patterns[element].append(0.0)
	
	_rebuild_grid()


func set_kit(kit_name: String):
	"""Set the drum kit"""
	_kit_name = kit_name
	var kit_idx = DRUM_KITS.find(kit_name)
	if kit_idx >= 0:
		_kit_dropdown.selected = kit_idx


func get_kit() -> String:
	return _kit_name


func set_element_mute(element: String, muted: bool):
	"""Mute/unmute an element"""
	_element_mutes[element] = muted
	_update_row_label_for_element(element)


func set_element_solo(element: String, solo: bool):
	"""Solo/unsolo an element"""
	_element_solos[element] = solo
	_update_row_label_for_element(element)


func _update_row_label_for_element(element: String):
	var row = _elements.find(element)
	if row >= 0 and _row_labels.has(row):
		var label_btn = _row_labels[row]
		var text = element.capitalize()
		if _element_mutes.get(element, false):
			text += " [M]"
		elif _element_solos.get(element, false):
			text += " [S]"
		label_btn.text = text


func _on_kit_changed(index: int):
	if index >= 0 and index < DRUM_KITS.size():
		_kit_name = DRUM_KITS[index]


# ===== ROW DRAWING (add mute/solo buttons) =====

func _draw_row(row: int):
	# Call parent's row drawing first
	super._draw_row(row)
	
	# Add mute/solo buttons if we have elements
	if row >= _elements.size():
		return
	
	var element = _elements[row]
	var y = HEADER_HEIGHT + row * CELL_SIZE.y
	
	# Mute button (position after row label)
	# We'll add these inline with the label button


func _rebuild_grid():
	super._rebuild_grid()
	
	# Add mute/solo controls per row
	for row in range(_elements.size()):
		var element = _elements[row]
		var y = HEADER_HEIGHT + row * CELL_SIZE.y
		
		# Add M/S buttons to the left of the grid
		# These go inside the row label area
		if _row_labels.has(row):
			_add_mute_solo_to_row(row, element)


func _add_mute_solo_to_row(row: int, element: String):
	# The row label button already exists, we'll add M/S to the right of it
	# For now, we'll append [M] or [S] to the label text based on state
	_update_row_label_for_element(element)


# ===== PATTERN PRESETS =====

func load_preset(preset_name: String):
	"""Load a pattern preset"""
	var presets = {
		"four_on_floor": {
			"kick":  [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
			"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
			"hihat": [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0],
			"clap":  [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
		},
		"trap": {
			"kick":  [1,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0],
			"snare": [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0],
			"hihat": [1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1],
			"clap":  [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0],
		},
		"breakbeat": {
			"kick":  [1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0],
			"snare": [0,0,0,0,1,0,0,0,0,1,0,0,1,0,0,0],
			"hihat": [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
			"clap":  [0,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0],
		},
		"minimal": {
			"kick":  [1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
			"snare": [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0],
			"hihat": [0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1],
			"clap":  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		},
		"empty": {
			"kick":  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			"snare": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			"hihat": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
			"clap":  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		},
	}
	
	if presets.has(preset_name):
		load_patterns(presets[preset_name])


func generate_euclidean(element: String, pulses: int, steps: int = 16, rotation: int = 0):
	"""Generate Euclidean rhythm for an element"""
	if not _element_patterns.has(element):
		return
	
	# Euclidean algorithm
	var bucket = []
	for i in range(steps):
		if i < pulses:
			bucket.append([1])
		else:
			bucket.append([0])
	
	while bucket.size() > 1:
		var ones = []
		var zeros = []
		
		for group in bucket:
			if group[0] == 1:
				ones.append(group)
			else:
				zeros.append(group)
		
		if zeros.is_empty():
			break
		
		bucket.clear()
		var min_count = min(ones.size(), zeros.size())
		
		for i in range(min_count):
			bucket.append(ones[i] + zeros[i])
		for i in range(min_count, ones.size()):
			bucket.append(ones[i])
		for i in range(min_count, zeros.size()):
			bucket.append(zeros[i])
	
	# Flatten
	var flat = []
	for group in bucket:
		flat.append_array(group)
	
	# Apply rotation
	for i in range(rotation):
		flat.append(flat.pop_front())
	
	# Apply to pattern
	for i in range(mini(steps, _element_patterns[element].size())):
		_element_patterns[element][i] = float(flat[i] if i < flat.size() else 0)
	
	_rebuild_grid()
	pattern_changed.emit(_get_pattern_for_export())
