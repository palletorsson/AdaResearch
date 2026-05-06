# BassTimeline.gd
# 16-step bass pattern editor with pitch control
# For bass, sub sounds
#
# ⚠️ DEPRECATED: This class is maintained for backwards compatibility.
# Please use BassPatternEditor from the unified pattern editor architecture instead.
# See: commons/audio/catalog/ui/BassPatternEditor.gd

extends Control
class_name BassTimeline

signal pattern_changed(pattern: Array, notes: Array)
signal preview_requested(note: int)

const STEP_COUNT = 16
const CELL_WIDTH = 40
const CELL_HEIGHT = 24
const HEADER_HEIGHT = 30
const PIANO_WIDTH = 50

# Note names (chromatic)
const NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Pattern data
var _pattern: Array = []  # 16 floats (0 = rest, >0 = velocity)
var _notes: Array = []    # 16 ints (MIDI note numbers, 0-127)
var _glides: Array = []   # 16 bools (glide to next note)
var _root_note: int = 36  # C2 by default
var _octave: int = 2
var _bpm: float = 120.0

# UI
var _grid_container: Control
var _cells: Array = []
var _root_dropdown: OptionButton
var _octave_spin: SpinBox
var _play_btn: Button
var _apply_btn: Button

# Dragging state
var _dragging: bool = false
var _drag_step: int = -1
var _drag_start_y: float = 0.0
var _drag_start_note: int = 0

# Playback
var _is_playing: bool = false
var _current_step: int = 0
var _step_timer: Timer


func _ready():
	_init_pattern()
	_setup_ui()
	_setup_playback()


func _init_pattern():
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	for i in range(STEP_COUNT):
		_pattern.append(0.0)
		_notes.append(_root_note)
		_glides.append(false)


func _setup_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🎸 BASS TIMELINE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 0.6))
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Root note selector
	var root_label = Label.new()
	root_label.text = "Root:"
	root_label.add_theme_font_size_override("font_size", 13)
	header.add_child(root_label)
	
	_root_dropdown = OptionButton.new()
	for note in NOTE_NAMES:
		_root_dropdown.add_item(note)
	_root_dropdown.selected = 0  # C
	_root_dropdown.item_selected.connect(_on_root_changed)
	header.add_child(_root_dropdown)
	
	# Octave selector
	var oct_label = Label.new()
	oct_label.text = "Octave:"
	oct_label.add_theme_font_size_override("font_size", 13)
	header.add_child(oct_label)
	
	_octave_spin = SpinBox.new()
	_octave_spin.min_value = 0
	_octave_spin.max_value = 5
	_octave_spin.value = 2
	_octave_spin.value_changed.connect(_on_octave_changed)
	header.add_child(_octave_spin)
	
	# Transport
	_play_btn = Button.new()
	_play_btn.text = "▶ Play"
	_play_btn.pressed.connect(_on_play_pressed)
	_style_button(_play_btn, Color(0.2, 0.5, 0.3))
	header.add_child(_play_btn)
	
	_apply_btn = Button.new()
	_apply_btn.text = "✓ Apply"
	_apply_btn.pressed.connect(_on_apply_pressed)
	_style_button(_apply_btn, Color(0.3, 0.4, 0.6))
	header.add_child(_apply_btn)
	
	# Grid area with scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	_grid_container = Control.new()
	_grid_container.custom_minimum_size = Vector2(STEP_COUNT * CELL_WIDTH + PIANO_WIDTH + 20, 300)
	scroll.add_child(_grid_container)
	
	_rebuild_grid()
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Click: add/remove note • Drag vertically: change pitch • Right-click: toggle glide"
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	main_vbox.add_child(instructions)


func _setup_playback():
	_step_timer = Timer.new()
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_on_step_tick)
	add_child(_step_timer)


func load_pattern(pattern: Array, notes: Array = [], glides: Array = []):
	"""Load bass pattern data"""
	_pattern.clear()
	_notes.clear()
	_glides.clear()
	
	for i in range(STEP_COUNT):
		_pattern.append(pattern[i] if i < pattern.size() else 0.0)
		_notes.append(notes[i] if i < notes.size() else _root_note)
		_glides.append(glides[i] if i < glides.size() else false)
	
	_rebuild_grid()


func _rebuild_grid():
	# Clear existing
	for child in _grid_container.get_children():
		child.queue_free()
	_cells.clear()
	
	# Piano roll background (simplified)
	var piano_bg = ColorRect.new()
	piano_bg.color = Color(0.1, 0.1, 0.12)
	piano_bg.position = Vector2(0, HEADER_HEIGHT)
	piano_bg.size = Vector2(PIANO_WIDTH, 250)
	_grid_container.add_child(piano_bg)
	
	# Draw octave markers on piano
	for oct in range(4):
		var y = 250 - (oct * 60 + 30)
		var label = Label.new()
		label.text = "C%d" % (oct + 1)
		label.position = Vector2(5, HEADER_HEIGHT + y - 8)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		_grid_container.add_child(label)
	
	# Beat markers
	for step in range(STEP_COUNT):
		var marker = Label.new()
		if step % 4 == 0:
			marker.text = str(step / 4 + 1)
			marker.add_theme_font_size_override("font_size", 14)
			marker.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		else:
			marker.text = "·"
			marker.add_theme_font_size_override("font_size", 10)
			marker.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		marker.position = Vector2(PIANO_WIDTH + step * CELL_WIDTH + 12, 5)
		_grid_container.add_child(marker)
	
	# Grid background
	var grid_bg = ColorRect.new()
	grid_bg.color = Color(0.06, 0.06, 0.08)
	grid_bg.position = Vector2(PIANO_WIDTH, HEADER_HEIGHT)
	grid_bg.size = Vector2(STEP_COUNT * CELL_WIDTH, 250)
	grid_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	grid_bg.gui_input.connect(_on_grid_input)
	_grid_container.add_child(grid_bg)
	
	# Beat dividers
	for step in range(STEP_COUNT + 1):
		var divider = ColorRect.new()
		divider.color = Color(0.25, 0.25, 0.3) if step % 4 == 0 else Color(0.15, 0.15, 0.2)
		divider.position = Vector2(PIANO_WIDTH + step * CELL_WIDTH, HEADER_HEIGHT)
		divider.size = Vector2(1, 250)
		_grid_container.add_child(divider)
	
	# Note cells
	for step in range(STEP_COUNT):
		var cell = _create_note_cell(step)
		_cells.append(cell)
		_grid_container.add_child(cell)
	
	# Glide indicators
	_update_glide_indicators()


func _create_note_cell(step: int) -> Control:
	var container = Control.new()
	container.position = Vector2(PIANO_WIDTH + step * CELL_WIDTH, HEADER_HEIGHT)
	container.size = Vector2(CELL_WIDTH, 250)
	
	if _pattern[step] > 0:
		# Note block
		var note = _notes[step]
		var y = _note_to_y(note)
		var height = CELL_HEIGHT
		
		var block = ColorRect.new()
		block.name = "NoteBlock"
		block.color = _get_velocity_color(_pattern[step])
		block.position = Vector2(2, y)
		block.size = Vector2(CELL_WIDTH - 4, height)
		container.add_child(block)
		
		# Note name label
		var label = Label.new()
		label.name = "NoteLabel"
		label.text = _get_note_name(note)
		label.position = Vector2(4, y + 4)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
		container.add_child(label)
		
		# Glide indicator
		if _glides[step]:
			var glide = Label.new()
			glide.name = "GlideIndicator"
			glide.text = "~"
			glide.position = Vector2(CELL_WIDTH - 14, y + 4)
			glide.add_theme_font_size_override("font_size", 12)
			glide.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
			container.add_child(glide)
	
	return container


func _note_to_y(note: int) -> float:
	# Map MIDI note to Y position (higher notes at top)
	var min_note = 24  # C1
	var max_note = 72  # C5
	var range_size = max_note - min_note
	var normalized = clampf(float(note - min_note) / range_size, 0.0, 1.0)
	return 250 - (normalized * 250) - CELL_HEIGHT / 2


func _y_to_note(y: float) -> int:
	# Map Y position to MIDI note
	var min_note = 24
	var max_note = 72
	var range_size = max_note - min_note
	var normalized = clampf(1.0 - (y / 250.0), 0.0, 1.0)
	return int(min_note + normalized * range_size)


func _get_note_name(midi_note: int) -> String:
	var note_idx = midi_note % 12
	var octave = midi_note / 12 - 1
	return "%s%d" % [NOTE_NAMES[note_idx], octave]


func _get_velocity_color(velocity: float) -> Color:
	if velocity >= 2.0:
		return Color(0.4, 0.7, 0.5)  # Accent - bright green
	elif velocity >= 1.0:
		return Color(0.25, 0.55, 0.4)  # Normal - green
	elif velocity > 0:
		return Color(0.18, 0.35, 0.3)  # Ghost - dim green
	else:
		return Color(0.12, 0.12, 0.15)


func _update_glide_indicators():
	# Already handled in _create_note_cell
	pass


func _on_grid_input(event: InputEvent):
	if event is InputEventMouseButton:
		var local_pos = event.position
		var step = int(local_pos.x / CELL_WIDTH)
		step = clampi(step, 0, STEP_COUNT - 1)
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_dragging = true
				_drag_step = step
				_drag_start_y = local_pos.y
				_drag_start_note = _notes[step]
				
				# Toggle note on/off if clicking on empty step
				if _pattern[step] == 0:
					_pattern[step] = 1.0
					_notes[step] = _y_to_note(local_pos.y)
				
				_rebuild_grid()
				pattern_changed.emit(_pattern.duplicate(), _notes.duplicate())
				
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Toggle glide
				if _pattern[step] > 0:
					_glides[step] = not _glides[step]
					_rebuild_grid()
					pattern_changed.emit(_pattern.duplicate(), _notes.duplicate())
		else:
			_dragging = false
			_drag_step = -1
	
	elif event is InputEventMouseMotion and _dragging and _drag_step >= 0:
		var local_pos = event.position
		var delta_y = _drag_start_y - local_pos.y
		var note_delta = int(delta_y / 8)  # 8 pixels per semitone
		
		var new_note = clampi(_drag_start_note + note_delta, 24, 72)
		if new_note != _notes[_drag_step]:
			_notes[_drag_step] = new_note
			_rebuild_grid()


func _on_root_changed(index: int):
	_root_note = 12 + index + (_octave * 12)
	# Update default note for new notes
	for i in range(STEP_COUNT):
		if _pattern[i] == 0:
			_notes[i] = _root_note


func _on_octave_changed(value: float):
	_octave = int(value)
	_root_note = 12 + (_root_dropdown.selected) + (_octave * 12)


func _on_play_pressed():
	if _is_playing:
		_stop_playback()
	else:
		_start_playback()


func _start_playback():
	_is_playing = true
	_current_step = 0
	_play_btn.text = "⏹ Stop"
	
	var step_duration = 60.0 / _bpm / 4.0
	_step_timer.wait_time = step_duration
	_step_timer.start()


func _stop_playback():
	_is_playing = false
	_play_btn.text = "▶ Play"
	_step_timer.stop()
	_rebuild_grid()  # Clear highlights


func _on_step_tick():
	_current_step = (_current_step + 1) % STEP_COUNT
	
	# Highlight current step
	for i in range(_cells.size()):
		var cell = _cells[i]
		var block = cell.get_node_or_null("NoteBlock")
		if block:
			if i == _current_step:
				block.color = _get_velocity_color(_pattern[i]).lightened(0.3)
			else:
				block.color = _get_velocity_color(_pattern[i])
	
	# Play note if active
	if _pattern[_current_step] > 0:
		preview_requested.emit(_notes[_current_step])


func _on_apply_pressed():
	pattern_changed.emit(_pattern.duplicate(), _notes.duplicate())


func get_pattern_data() -> Dictionary:
	return {
		"pattern": _pattern.duplicate(),
		"notes": _notes.duplicate(),
		"glides": _glides.duplicate(),
		"root": _root_note,
		"octave": _octave,
	}


func set_bpm(bpm: float):
	_bpm = bpm
	if _is_playing:
		_step_timer.wait_time = 60.0 / _bpm / 4.0


func _style_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 13)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
