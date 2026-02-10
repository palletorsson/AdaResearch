# ArpPatternEditor.gd
# Arpeggio pattern editor extending BasePatternEditor
# Shows note order visualization with direction/rate/octave controls

extends BasePatternEditor
class_name ArpPatternEditor

# Arp patterns and rates
const PATTERNS = {
	"up": "â–² Up",
	"down": "â–¼ Down",
	"up_down": "â—† Up-Down",
	"down_up": "â—‡ Down-Up",
	"random": "ðŸŽ² Random",
	"as_played": "âœ‹ As Played",
	"chord": "â–¬ Chord",
}

const RATES = {
	"1/1": 1.0,
	"1/2": 0.5,
	"1/4": 0.25,
	"1/8": 0.125,
	"1/16": 0.0625,
	"1/32": 0.03125,
	"1/4T": 0.167,
	"1/8T": 0.083,
	"1/16T": 0.042,
}

const VELOCITY_CURVES = ["flat", "crescendo", "decrescendo", "accent_first", "accent_last"]

# Arp-specific settings
var _direction: String = "up"
var _rate: String = "1/8"
var _octave_range: int = 1
var _gate_length: float = 0.8
var _velocity_curve: String = "flat"

# Generated note sequence for visualization
var _note_sequence: Array = []
var _base_chord: Array = [0, 4, 7]  # Major triad intervals

# UI
var _pattern_buttons: Dictionary = {}
var _rate_buttons: Dictionary = {}
var _octave_slider: HSlider
var _octave_label: Label
var _gate_slider: HSlider
var _gate_label: Label
var _velocity_dropdown: OptionButton
var _visualization: Control


func _get_editor_title() -> String:
	return "ðŸŽµ ARPEGGIO EDITOR"


func _get_editor_color() -> Color:
	return Color(0.9, 0.5, 0.7)


func _get_row_count() -> int:
	# For arp, rows represent note order in the sequence
	return mini(8, _generate_note_sequence().size())


func _get_row_label(row: int) -> String:
	var sequence = _generate_note_sequence()
	if row < sequence.size():
		return _note_to_name(sequence[row])
	return ""


func _get_row_sound(_row: int) -> String:
	return "arp"


func _get_row_color(row: int) -> Color:
	# Color based on velocity curve
	var vel = _get_velocity_at_position(row, _get_row_count())
	return Color.from_hsv(0.85 - vel * 0.15, 0.6, 0.5 + vel * 0.4)


func _initialize_pattern():
	_note_sequence = _generate_note_sequence()


func _setup_ui():
	# Override to use custom layout
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 12)
	add_child(_main_container)
	
	# Header
	_setup_arp_header()
	
	# Main content in columns
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_container.add_child(content)
	
	# Left column - Pattern and Rate
	var left_col = _create_left_column()
	content.add_child(left_col)
	
	# Right column - Octave, Gate, Velocity
	var right_col = _create_right_column()
	content.add_child(right_col)
	
	# Visualization panel
	var viz_panel = _create_visualization_panel()
	_main_container.add_child(viz_panel)


func _setup_arp_header():
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 12)
	_main_container.add_child(_header)
	
	_title_label = Label.new()
	_title_label.text = _get_editor_title()
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", _get_editor_color())
	_header.add_child(_title_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(spacer)
	
	# BPM
	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.add_theme_font_size_override("font_size", 13)
	_header.add_child(bpm_label)
	
	_bpm_spin = SpinBox.new()
	_bpm_spin.min_value = 60
	_bpm_spin.max_value = 200
	_bpm_spin.value = 120
	_bpm_spin.value_changed.connect(_on_bpm_changed)
	_header.add_child(_bpm_spin)
	
	# Transport
	_play_btn = Button.new()
	_play_btn.text = "â–¶ Play"
	_play_btn.pressed.connect(_on_play_pressed)
	_style_button(_play_btn, Color(0.2, 0.5, 0.3))
	_header.add_child(_play_btn)
	
	_apply_btn = Button.new()
	_apply_btn.text = "âœ“ Apply"
	_apply_btn.pressed.connect(_on_apply_pressed)
	_style_button(_apply_btn, Color(0.3, 0.4, 0.6))
	_header.add_child(_apply_btn)


func _create_left_column() -> VBoxContainer:
	var left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 16)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Pattern section
	var pattern_section = _create_section("Pattern Type")
	left_col.add_child(pattern_section)
	
	var pattern_grid = GridContainer.new()
	pattern_grid.columns = 2
	pattern_grid.add_theme_constant_override("h_separation", 6)
	pattern_grid.add_theme_constant_override("v_separation", 6)
	pattern_section.add_child(pattern_grid)
	
	for key in PATTERNS.keys():
		var btn = Button.new()
		btn.text = PATTERNS[key]
		btn.toggle_mode = true
		btn.button_pressed = (key == _direction)
		btn.custom_minimum_size.x = 100
		btn.pressed.connect(_on_pattern_selected.bind(key))
		_style_toggle_button(btn, Color(0.5, 0.35, 0.55))
		_pattern_buttons[key] = btn
		pattern_grid.add_child(btn)
	
	# Rate section
	var rate_section = _create_section("Rate (Note Value)")
	left_col.add_child(rate_section)
	
	var rate_grid = GridContainer.new()
	rate_grid.columns = 3
	rate_grid.add_theme_constant_override("h_separation", 6)
	rate_grid.add_theme_constant_override("v_separation", 6)
	rate_section.add_child(rate_grid)
	
	for key in RATES.keys():
		var btn = Button.new()
		btn.text = key
		btn.toggle_mode = true
		btn.button_pressed = (key == _rate)
		btn.custom_minimum_size.x = 60
		btn.pressed.connect(_on_rate_selected.bind(key))
		_style_toggle_button(btn, Color(0.35, 0.45, 0.55))
		_rate_buttons[key] = btn
		rate_grid.add_child(btn)
	
	return left_col


func _create_right_column() -> VBoxContainer:
	var right_col = VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 16)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Octave range
	var octave_section = _create_section("Octave Range")
	right_col.add_child(octave_section)
	
	var octave_row = HBoxContainer.new()
	octave_row.add_theme_constant_override("separation", 8)
	octave_section.add_child(octave_row)
	
	_octave_slider = HSlider.new()
	_octave_slider.min_value = 1
	_octave_slider.max_value = 4
	_octave_slider.value = _octave_range
	_octave_slider.step = 1
	_octave_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_octave_slider.value_changed.connect(_on_octave_changed)
	octave_row.add_child(_octave_slider)
	
	_octave_label = Label.new()
	_octave_label.text = "%d oct" % _octave_range
	_octave_label.add_theme_font_size_override("font_size", 13)
	_octave_label.custom_minimum_size.x = 50
	octave_row.add_child(_octave_label)
	
	# Gate length
	var gate_section = _create_section("Gate Length")
	right_col.add_child(gate_section)
	
	var gate_row = HBoxContainer.new()
	gate_row.add_theme_constant_override("separation", 8)
	gate_section.add_child(gate_row)
	
	_gate_slider = HSlider.new()
	_gate_slider.min_value = 0.1
	_gate_slider.max_value = 1.0
	_gate_slider.value = _gate_length
	_gate_slider.step = 0.05
	_gate_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate_slider.value_changed.connect(_on_gate_changed)
	gate_row.add_child(_gate_slider)
	
	_gate_label = Label.new()
	_gate_label.text = "%d%%" % int(_gate_length * 100)
	_gate_label.add_theme_font_size_override("font_size", 13)
	_gate_label.custom_minimum_size.x = 50
	gate_row.add_child(_gate_label)
	
	# Swing (reuse from base)
	var swing_section = _create_section("Swing")
	right_col.add_child(swing_section)
	
	var swing_row = HBoxContainer.new()
	swing_row.add_theme_constant_override("separation", 8)
	swing_section.add_child(swing_row)
	
	_swing_slider = HSlider.new()
	_swing_slider.min_value = 0
	_swing_slider.max_value = 30
	_swing_slider.value = _swing
	_swing_slider.step = 1
	_swing_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_swing_slider.value_changed.connect(_on_swing_changed)
	swing_row.add_child(_swing_slider)
	
	_swing_label = Label.new()
	_swing_label.text = "0%"
	_swing_label.add_theme_font_size_override("font_size", 13)
	_swing_label.custom_minimum_size.x = 50
	swing_row.add_child(_swing_label)
	
	# Velocity curve
	var velocity_section = _create_section("Velocity Curve")
	right_col.add_child(velocity_section)
	
	_velocity_dropdown = OptionButton.new()
	_velocity_dropdown.add_item("Flat")
	_velocity_dropdown.add_item("Crescendo â–²")
	_velocity_dropdown.add_item("Decrescendo â–¼")
	_velocity_dropdown.add_item("Accent First")
	_velocity_dropdown.add_item("Accent Last")
	_velocity_dropdown.selected = 0
	_velocity_dropdown.item_selected.connect(_on_velocity_curve_changed)
	velocity_section.add_child(_velocity_dropdown)
	
	return right_col


func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	section.add_child(label)
	
	return section


func _create_visualization_panel() -> PanelContainer:
	var viz_panel = PanelContainer.new()
	var viz_style = StyleBoxFlat.new()
	viz_style.bg_color = Color(0.06, 0.06, 0.08)
	viz_style.set_corner_radius_all(6)
	viz_panel.add_theme_stylebox_override("panel", viz_style)
	viz_panel.custom_minimum_size.y = 120
	
	_visualization = Control.new()
	_visualization.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visualization.draw.connect(_on_visualization_draw)
	viz_panel.add_child(_visualization)
	
	return viz_panel


func _setup_playback():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	
	_step_timer = Timer.new()
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_on_arp_step_tick)
	add_child(_step_timer)


# ===== PATTERN GENERATION =====

func _generate_note_sequence() -> Array:
	"""Generate note sequence based on pattern type and octave range"""
	var all_notes = []
	
	# Build notes across octaves
	for oct in range(_octave_range):
		for note in _base_chord:
			all_notes.append(note + oct * 12)
	
	# Apply pattern
	var sequence = []
	match _direction:
		"up":
			sequence = all_notes.duplicate()
		"down":
			sequence = all_notes.duplicate()
			sequence.reverse()
		"up_down":
			sequence = all_notes.duplicate()
			var down = all_notes.duplicate()
			down.reverse()
			if down.size() > 1:
				down = down.slice(1, down.size() - 1)
			sequence.append_array(down)
		"down_up":
			sequence = all_notes.duplicate()
			sequence.reverse()
			var up = all_notes.duplicate()
			if up.size() > 1:
				up = up.slice(1, up.size() - 1)
			sequence.append_array(up)
		"random":
			sequence = all_notes.duplicate()
			sequence.shuffle()
		"as_played", "chord":
			sequence = all_notes.duplicate()
	
	return sequence


func _get_velocity_at_position(pos: int, total: int) -> float:
	match _velocity_curve:
		"crescendo":
			return 0.4 + 0.6 * (float(pos) / float(total - 1)) if total > 1 else 1.0
		"decrescendo":
			return 1.0 - 0.6 * (float(pos) / float(total - 1)) if total > 1 else 1.0
		"accent_first":
			return 1.0 if pos == 0 else 0.6
		"accent_last":
			return 1.0 if pos == total - 1 else 0.6
		_:  # flat
			return 0.8


func _note_to_name(semitones: int) -> String:
	var note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octave = semitones / 12
	var note = semitones % 12
	return "%s%d" % [note_names[note], octave]


# ===== VISUALIZATION =====

func _on_visualization_draw():
	var size = _visualization.size
	var margin = 20
	var width = size.x - margin * 2
	var height = size.y - margin * 2
	
	var notes = _generate_note_sequence()
	if notes.is_empty():
		return
	
	var step_width = width / float(notes.size())
	var max_note = notes.max() if not notes.is_empty() else 12
	var min_note = notes.min() if not notes.is_empty() else 0
	var note_range = max(max_note - min_note, 1)
	var note_height = height / float(note_range + 1)
	
	# Draw notes
	for i in range(notes.size()):
		var note = notes[i]
		var x = margin + i * step_width
		var y = margin + height - ((note - min_note) * note_height)
		
		var bar_width = step_width * _gate_length * 0.9
		var bar_height = note_height * 0.8
		
		var vel = _get_velocity_at_position(i, notes.size())
		var color = Color.from_hsv(0.85 - vel * 0.15, 0.6, 0.5 + vel * 0.4)
		
		# Highlight current note if playing
		if _is_playing and i == _current_step:
			color = color.lightened(0.3)
		
		_visualization.draw_rect(Rect2(x, y - bar_height, bar_width, bar_height), color)
		
		# Connect notes with lines
		if i < notes.size() - 1:
			var next_note = notes[i + 1]
			var next_x = margin + (i + 1) * step_width
			var next_y = margin + height - ((next_note - min_note) * note_height) - bar_height / 2
			_visualization.draw_line(
				Vector2(x + bar_width, y - bar_height / 2),
				Vector2(next_x, next_y),
				Color(0.4, 0.4, 0.45, 0.5),
				1.0
			)


# ===== CALLBACKS =====

func _on_pattern_selected(pattern_key: String):
	_direction = pattern_key
	_update_pattern_buttons()
	_note_sequence = _generate_note_sequence()
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_rate_selected(rate_key: String):
	_rate = rate_key
	_update_rate_buttons()
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_octave_changed(value: float):
	_octave_range = int(value)
	_octave_label.text = "%d oct" % _octave_range
	_note_sequence = _generate_note_sequence()
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_gate_changed(value: float):
	_gate_length = value
	_gate_label.text = "%d%%" % int(_gate_length * 100)
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_velocity_curve_changed(index: int):
	_velocity_curve = VELOCITY_CURVES[index]
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _update_pattern_buttons():
	for key in _pattern_buttons.keys():
		_pattern_buttons[key].button_pressed = (key == _direction)


func _update_rate_buttons():
	for key in _rate_buttons.keys():
		_rate_buttons[key].button_pressed = (key == _rate)


# ===== PLAYBACK =====

func _on_arp_step_tick():
	var notes = _generate_note_sequence()
	if notes.size() > 0:
		_current_step = (_current_step + 1) % notes.size()
	_visualization.queue_redraw()
	
	# Trigger note
	if _current_step < notes.size():
		preview_requested.emit(notes[_current_step])


func _start_playback():
	_is_playing = true
	_current_step = 0
	_play_btn.text = "â¸ Pause"
	
	var step_duration = 60.0 / _bpm * RATES[_rate] * 4
	_step_timer.wait_time = step_duration
	_step_timer.start()
	_visualization.queue_redraw()
	playback_started.emit()


func _stop_playback():
	_is_playing = false
	_play_btn.text = "â–¶ Play"
	_step_timer.stop()
	_visualization.queue_redraw()
	playback_stopped.emit()


# ===== PUBLIC API =====

func get_settings() -> Dictionary:
	return {
		"direction": _direction,
		"rate": _rate,
		"octave_range": _octave_range,
		"gate_length": _gate_length,
		"swing": _swing,
		"velocity_curve": _velocity_curve,
	}


func load_settings(settings: Dictionary):
	"""Load arpeggio settings"""
	_direction = settings.get("direction", "up")
	_rate = settings.get("rate", "1/8")
	_octave_range = settings.get("octave_range", 1)
	_gate_length = settings.get("gate_length", 0.8)
	_swing = settings.get("swing", 0.0)
	_velocity_curve = settings.get("velocity_curve", "flat")
	
	# Update UI
	_update_pattern_buttons()
	_update_rate_buttons()
	_octave_slider.value = _octave_range
	_octave_label.text = "%d oct" % _octave_range
	_gate_slider.value = _gate_length
	_gate_label.text = "%d%%" % int(_gate_length * 100)
	_swing_slider.value = _swing
	_swing_label.text = "%d%%" % int(_swing)
	
	var curve_idx = VELOCITY_CURVES.find(_velocity_curve)
	if curve_idx >= 0:
		_velocity_dropdown.selected = curve_idx
	
	_note_sequence = _generate_note_sequence()
	_visualization.queue_redraw()


func set_chord(chord_intervals: Array):
	"""Set the base chord intervals for the arp"""
	_base_chord = chord_intervals
	_note_sequence = _generate_note_sequence()
	_visualization.queue_redraw()


func _get_pattern_for_export() -> Dictionary:
	return get_settings()


# Disable base class grid (we use custom visualization)
func _rebuild_grid():
	pass
