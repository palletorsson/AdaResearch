# ChordTimeline.gd
# 16-step chord/pad pattern editor with chord selection and voicings
# For pads, keys, rhodes, strings
#
# ⚠️ DEPRECATED: This class is maintained for backwards compatibility.
# Please use ChordPatternEditor from the unified pattern editor architecture instead.
# See: commons/audio/catalog/ui/ChordPatternEditor.gd

extends Control
class_name ChordTimeline

signal pattern_changed(pattern: Array, chords: Array)
signal preview_requested(chord: Array)

const STEP_COUNT = 16
const CELL_WIDTH = 50
const CELL_HEIGHT = 60
const HEADER_HEIGHT = 30

# Roman numeral chord degrees
const CHORD_DEGREES = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
const CHORD_COLORS = {
	"I": Color(0.3, 0.6, 0.85),
	"ii": Color(0.4, 0.5, 0.7),
	"iii": Color(0.5, 0.45, 0.65),
	"IV": Color(0.6, 0.5, 0.3),
	"V": Color(0.7, 0.45, 0.35),
	"vi": Color(0.55, 0.4, 0.6),
	"vii°": Color(0.5, 0.35, 0.5),
	"sus": Color(0.5, 0.5, 0.4),
	"rest": Color(0.15, 0.15, 0.18),
}

const VOICINGS = ["Root", "1st Inv", "2nd Inv", "Open"]

# Pattern data
var _pattern: Array = []     # 16 floats (0 = rest, >0 = velocity)
var _chords: Array = []      # 16 strings (chord degree or "rest")
var _voicings: Array = []    # 16 ints (voicing index)
var _sustains: Array = []    # 16 bools (sustain from previous)
var _bpm: float = 120.0
var _key: String = "C"
var _scale: String = "major"

# UI
var _grid_container: Control
var _cells: Array = []
var _key_dropdown: OptionButton
var _scale_dropdown: OptionButton
var _play_btn: Button
var _apply_btn: Button

# Selection
var _selected_step: int = -1
var _chord_popup: PopupPanel

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
	_chords.clear()
	_voicings.clear()
	_sustains.clear()
	for i in range(STEP_COUNT):
		_pattern.append(0.0)
		_chords.append("rest")
		_voicings.append(0)
		_sustains.append(false)


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
	title.text = "🎹 CHORD TIMELINE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.85))
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Key selector
	var key_label = Label.new()
	key_label.text = "Key:"
	key_label.add_theme_font_size_override("font_size", 13)
	header.add_child(key_label)
	
	_key_dropdown = OptionButton.new()
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	for note in notes:
		_key_dropdown.add_item(note)
	_key_dropdown.selected = 0
	_key_dropdown.item_selected.connect(_on_key_changed)
	header.add_child(_key_dropdown)
	
	# Scale selector
	var scale_label = Label.new()
	scale_label.text = "Scale:"
	scale_label.add_theme_font_size_override("font_size", 13)
	header.add_child(scale_label)
	
	_scale_dropdown = OptionButton.new()
	_scale_dropdown.add_item("Major")
	_scale_dropdown.add_item("Minor")
	_scale_dropdown.add_item("Dorian")
	_scale_dropdown.add_item("Mixolydian")
	_scale_dropdown.selected = 0
	_scale_dropdown.item_selected.connect(_on_scale_changed)
	header.add_child(_scale_dropdown)
	
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
	
	# Grid scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	_grid_container = Control.new()
	_grid_container.custom_minimum_size = Vector2(STEP_COUNT * CELL_WIDTH + 20, CELL_HEIGHT + HEADER_HEIGHT + 20)
	scroll.add_child(_grid_container)
	
	_rebuild_grid()
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Click: select chord • Right-click: toggle sustain • Double-click: cycle voicing"
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	main_vbox.add_child(instructions)
	
	# Chord selection popup
	_create_chord_popup()


func _create_chord_popup():
	_chord_popup = PopupPanel.new()
	_chord_popup.size = Vector2(200, 280)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_chord_popup.add_child(vbox)
	
	var popup_title = Label.new()
	popup_title.text = "Select Chord"
	popup_title.add_theme_font_size_override("font_size", 14)
	popup_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(popup_title)
	
	# Chord buttons
	for degree in CHORD_DEGREES:
		var btn = Button.new()
		btn.text = degree
		btn.pressed.connect(_on_chord_selected.bind(degree))
		_style_chord_button(btn, CHORD_COLORS.get(degree, Color(0.3, 0.3, 0.4)))
		vbox.add_child(btn)
	
	# Rest button
	var rest_btn = Button.new()
	rest_btn.text = "Rest (empty)"
	rest_btn.pressed.connect(_on_chord_selected.bind("rest"))
	_style_chord_button(rest_btn, Color(0.25, 0.25, 0.28))
	vbox.add_child(rest_btn)
	
	# Voicing selector
	var voicing_label = Label.new()
	voicing_label.text = "Voicing:"
	voicing_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(voicing_label)
	
	var voicing_dropdown = OptionButton.new()
	voicing_dropdown.name = "VoicingDropdown"
	for v in VOICINGS:
		voicing_dropdown.add_item(v)
	voicing_dropdown.item_selected.connect(_on_voicing_selected)
	vbox.add_child(voicing_dropdown)
	
	add_child(_chord_popup)


func _setup_playback():
	_step_timer = Timer.new()
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_on_step_tick)
	add_child(_step_timer)


func load_pattern(pattern: Array, chords: Array = [], voicings: Array = [], sustains: Array = []):
	"""Load chord pattern data"""
	_pattern.clear()
	_chords.clear()
	_voicings.clear()
	_sustains.clear()
	
	for i in range(STEP_COUNT):
		_pattern.append(pattern[i] if i < pattern.size() else 0.0)
		_chords.append(chords[i] if i < chords.size() else "rest")
		_voicings.append(voicings[i] if i < voicings.size() else 0)
		_sustains.append(sustains[i] if i < sustains.size() else false)
	
	_rebuild_grid()


func _rebuild_grid():
	# Clear existing
	for child in _grid_container.get_children():
		child.queue_free()
	_cells.clear()
	
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
		marker.position = Vector2(step * CELL_WIDTH + 18, 5)
		_grid_container.add_child(marker)
	
	# Beat dividers
	for step in range(STEP_COUNT + 1):
		var divider = ColorRect.new()
		divider.color = Color(0.25, 0.25, 0.3) if step % 4 == 0 else Color(0.15, 0.15, 0.2)
		divider.position = Vector2(step * CELL_WIDTH, HEADER_HEIGHT)
		divider.size = Vector2(1, CELL_HEIGHT)
		_grid_container.add_child(divider)
	
	# Chord cells
	for step in range(STEP_COUNT):
		var cell = _create_chord_cell(step)
		_cells.append(cell)
		_grid_container.add_child(cell)
	
	# Draw sustain lines
	_draw_sustain_lines()


func _create_chord_cell(step: int) -> Control:
	var container = Control.new()
	container.position = Vector2(step * CELL_WIDTH, HEADER_HEIGHT)
	container.size = Vector2(CELL_WIDTH, CELL_HEIGHT)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.gui_input.connect(_on_cell_input.bind(step))
	
	var chord = _chords[step]
	var color = CHORD_COLORS.get(chord, CHORD_COLORS["rest"])
	
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = color.darkened(0.3) if _pattern[step] > 0 else CHORD_COLORS["rest"]
	bg.position = Vector2(2, 2)
	bg.size = Vector2(CELL_WIDTH - 4, CELL_HEIGHT - 4)
	container.add_child(bg)
	
	if chord != "rest" and _pattern[step] > 0:
		# Chord label
		var label = Label.new()
		label.name = "ChordLabel"
		label.text = chord
		label.position = Vector2(8, 8)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", color.lightened(0.4))
		container.add_child(label)
		
		# Voicing indicator
		var voicing_label = Label.new()
		voicing_label.name = "VoicingLabel"
		voicing_label.text = VOICINGS[_voicings[step]].substr(0, 4)
		voicing_label.position = Vector2(8, 35)
		voicing_label.add_theme_font_size_override("font_size", 9)
		voicing_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		container.add_child(voicing_label)
		
		# Sustain indicator
		if _sustains[step]:
			var sustain_line = ColorRect.new()
			sustain_line.name = "SustainLine"
			sustain_line.color = color.lightened(0.2)
			sustain_line.position = Vector2(CELL_WIDTH - 6, CELL_HEIGHT / 2 - 2)
			sustain_line.size = Vector2(8, 4)
			container.add_child(sustain_line)
	
	# Selection highlight
	if step == _selected_step:
		var highlight = ColorRect.new()
		highlight.name = "SelectHighlight"
		highlight.color = Color(1, 1, 1, 0.15)
		highlight.position = Vector2(0, 0)
		highlight.size = Vector2(CELL_WIDTH, CELL_HEIGHT)
		container.add_child(highlight)
	
	return container


func _draw_sustain_lines():
	# Draw lines connecting sustained chords
	var prev_chord_step = -1
	
	for step in range(STEP_COUNT):
		if _pattern[step] > 0 and _chords[step] != "rest":
			if _sustains[step] and prev_chord_step >= 0:
				# Draw sustain line from previous chord
				var line = ColorRect.new()
				line.color = CHORD_COLORS.get(_chords[prev_chord_step], Color(0.5, 0.5, 0.5)).darkened(0.2)
				line.position = Vector2(prev_chord_step * CELL_WIDTH + CELL_WIDTH - 2, HEADER_HEIGHT + CELL_HEIGHT / 2 - 1)
				line.size = Vector2((step - prev_chord_step) * CELL_WIDTH, 2)
				line.z_index = -1
				_grid_container.add_child(line)
			prev_chord_step = step


func _on_cell_input(event: InputEvent, step: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				# Double-click: cycle voicing
				if _pattern[step] > 0:
					_voicings[step] = (_voicings[step] + 1) % VOICINGS.size()
					_rebuild_grid()
					pattern_changed.emit(_pattern.duplicate(), _chords.duplicate())
			else:
				# Single click: show chord picker
				_selected_step = step
				_show_chord_popup(event.global_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Toggle sustain
			if _pattern[step] > 0:
				_sustains[step] = not _sustains[step]
				_rebuild_grid()
				pattern_changed.emit(_pattern.duplicate(), _chords.duplicate())


func _show_chord_popup(pos: Vector2):
	# Update voicing dropdown in popup
	var dropdown = _chord_popup.get_node_or_null("VoicingDropdown")
	if dropdown:
		dropdown.selected = _voicings[_selected_step]
	
	_chord_popup.position = pos
	_chord_popup.popup()


func _on_chord_selected(degree: String):
	if _selected_step < 0:
		return
	
	if degree == "rest":
		_pattern[_selected_step] = 0.0
		_chords[_selected_step] = "rest"
	else:
		_pattern[_selected_step] = 1.0
		_chords[_selected_step] = degree
	
	_chord_popup.hide()
	_rebuild_grid()
	pattern_changed.emit(_pattern.duplicate(), _chords.duplicate())


func _on_voicing_selected(index: int):
	if _selected_step >= 0:
		_voicings[_selected_step] = index
		_rebuild_grid()


func _on_key_changed(index: int):
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	_key = notes[index]


func _on_scale_changed(index: int):
	var scales = ["major", "minor", "dorian", "mixolydian"]
	_scale = scales[index]


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
	_rebuild_grid()


func _on_step_tick():
	_current_step = (_current_step + 1) % STEP_COUNT
	
	# Highlight current step
	for i in range(_cells.size()):
		var cell = _cells[i]
		var bg = cell.get_node_or_null("Background")
		if bg:
			var chord = _chords[i]
			var base_color = CHORD_COLORS.get(chord, CHORD_COLORS["rest"])
			if i == _current_step:
				bg.color = base_color.lightened(0.2) if _pattern[i] > 0 else CHORD_COLORS["rest"].lightened(0.1)
			else:
				bg.color = base_color.darkened(0.3) if _pattern[i] > 0 else CHORD_COLORS["rest"]
	
	# Trigger chord preview if active
	if _pattern[_current_step] > 0 and _chords[_current_step] != "rest":
		# TODO: Actually play chord
		pass


func _on_apply_pressed():
	pattern_changed.emit(_pattern.duplicate(), _chords.duplicate())


func get_pattern_data() -> Dictionary:
	return {
		"pattern": _pattern.duplicate(),
		"chords": _chords.duplicate(),
		"voicings": _voicings.duplicate(),
		"sustains": _sustains.duplicate(),
		"key": _key,
		"scale": _scale,
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


func _style_chord_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 14)
	
	var hover = style.duplicate()
	hover.bg_color = color
	btn.add_theme_stylebox_override("hover", hover)
