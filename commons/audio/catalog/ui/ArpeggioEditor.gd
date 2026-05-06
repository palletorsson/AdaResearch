# ArpeggioEditor.gd
# Arpeggio pattern editor with pattern type, rate, and octave controls
# For arp, sequence sounds
#
# ⚠️ DEPRECATED: This class is maintained for backwards compatibility.
# Please use ArpPatternEditor from the unified pattern editor architecture instead.
# See: commons/audio/catalog/ui/ArpPatternEditor.gd

extends Control
class_name ArpeggioEditor

signal pattern_changed(settings: Dictionary)
signal preview_requested()

const PATTERNS = {
	"up": "▲ Up",
	"down": "▼ Down",
	"up_down": "◆ Up-Down",
	"down_up": "◇ Down-Up",
	"random": "🎲 Random",
	"as_played": "✋ As Played",
	"chord": "▬ Chord",
}

const RATES = {
	"1/1": 1.0,
	"1/2": 0.5,
	"1/4": 0.25,
	"1/8": 0.125,
	"1/16": 0.0625,
	"1/32": 0.03125,
	"1/4T": 0.167,  # Triplet
	"1/8T": 0.083,
	"1/16T": 0.042,
}

# Current settings
var _pattern: String = "up"
var _rate: String = "1/8"
var _octave_range: int = 1
var _gate_length: float = 0.8  # 0.1 - 1.0
var _swing: float = 0.0
var _velocity_curve: String = "flat"  # flat, crescendo, decrescendo, accent
var _bpm: float = 120.0

# UI
var _pattern_buttons: Dictionary = {}
var _rate_buttons: Dictionary = {}
var _octave_slider: HSlider
var _gate_slider: HSlider
var _swing_slider: HSlider
var _velocity_dropdown: OptionButton
var _visualization: Control
var _play_btn: Button
var _apply_btn: Button

# Playback
var _is_playing: bool = false
var _current_note: int = 0
var _step_timer: Timer


func _ready():
	_setup_ui()
	_setup_playback()


func _setup_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🎹 ARPEGGIO EDITOR"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.7))
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
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
	
	# Main content in columns
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)
	
	# Left column - Pattern and Rate
	var left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 16)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left_col)
	
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
		btn.button_pressed = (key == _pattern)
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
	
	# Right column - Octave, Gate, Swing, Velocity
	var right_col = VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 16)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right_col)
	
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
	
	var octave_label = Label.new()
	octave_label.name = "OctaveValue"
	octave_label.text = "%d oct" % _octave_range
	octave_label.add_theme_font_size_override("font_size", 13)
	octave_label.custom_minimum_size.x = 50
	octave_row.add_child(octave_label)
	
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
	
	var gate_label = Label.new()
	gate_label.name = "GateValue"
	gate_label.text = "%d%%" % int(_gate_length * 100)
	gate_label.add_theme_font_size_override("font_size", 13)
	gate_label.custom_minimum_size.x = 50
	gate_row.add_child(gate_label)
	
	# Swing
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
	
	var swing_label = Label.new()
	swing_label.name = "SwingValue"
	swing_label.text = "%d%%" % int(_swing)
	swing_label.add_theme_font_size_override("font_size", 13)
	swing_label.custom_minimum_size.x = 50
	swing_row.add_child(swing_label)
	
	# Velocity curve
	var velocity_section = _create_section("Velocity Curve")
	right_col.add_child(velocity_section)
	
	_velocity_dropdown = OptionButton.new()
	_velocity_dropdown.add_item("Flat")
	_velocity_dropdown.add_item("Crescendo ▲")
	_velocity_dropdown.add_item("Decrescendo ▼")
	_velocity_dropdown.add_item("Accent First")
	_velocity_dropdown.add_item("Accent Last")
	_velocity_dropdown.selected = 0
	_velocity_dropdown.item_selected.connect(_on_velocity_curve_changed)
	velocity_section.add_child(_velocity_dropdown)
	
	# Visualization
	var viz_panel = PanelContainer.new()
	var viz_style = StyleBoxFlat.new()
	viz_style.bg_color = Color(0.06, 0.06, 0.08)
	viz_style.set_corner_radius_all(6)
	viz_panel.add_theme_stylebox_override("panel", viz_style)
	viz_panel.custom_minimum_size.y = 100
	main_vbox.add_child(viz_panel)
	
	_visualization = Control.new()
	_visualization.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_visualization.draw.connect(_on_visualization_draw)
	viz_panel.add_child(_visualization)


func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	section.add_child(label)
	
	return section


func _setup_playback():
	_step_timer = Timer.new()
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_on_step_tick)
	add_child(_step_timer)


func load_settings(settings: Dictionary):
	"""Load arpeggio settings"""
	_pattern = settings.get("pattern", "up")
	_rate = settings.get("rate", "1/8")
	_octave_range = settings.get("octave_range", 1)
	_gate_length = settings.get("gate_length", 0.8)
	_swing = settings.get("swing", 0.0)
	_velocity_curve = settings.get("velocity_curve", "flat")
	
	# Update UI
	_update_pattern_buttons()
	_update_rate_buttons()
	_octave_slider.value = _octave_range
	_gate_slider.value = _gate_length
	_swing_slider.value = _swing
	
	var curves = ["flat", "crescendo", "decrescendo", "accent_first", "accent_last"]
	_velocity_dropdown.selected = curves.find(_velocity_curve)
	
	_visualization.queue_redraw()


func _update_pattern_buttons():
	for key in _pattern_buttons.keys():
		_pattern_buttons[key].button_pressed = (key == _pattern)


func _update_rate_buttons():
	for key in _rate_buttons.keys():
		_rate_buttons[key].button_pressed = (key == _rate)


func _on_pattern_selected(pattern_key: String):
	_pattern = pattern_key
	_update_pattern_buttons()
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_rate_selected(rate_key: String):
	_rate = rate_key
	_update_rate_buttons()
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_octave_changed(value: float):
	_octave_range = int(value)
	var label = _octave_slider.get_parent().get_node("OctaveValue")
	if label:
		label.text = "%d oct" % _octave_range
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_gate_changed(value: float):
	_gate_length = value
	var label = _gate_slider.get_parent().get_node("GateValue")
	if label:
		label.text = "%d%%" % int(_gate_length * 100)
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_swing_changed(value: float):
	_swing = value
	var label = _swing_slider.get_parent().get_node("SwingValue")
	if label:
		label.text = "%d%%" % int(_swing)
	pattern_changed.emit(get_settings())


func _on_velocity_curve_changed(index: int):
	var curves = ["flat", "crescendo", "decrescendo", "accent_first", "accent_last"]
	_velocity_curve = curves[index]
	_visualization.queue_redraw()
	pattern_changed.emit(get_settings())


func _on_visualization_draw():
	"""Draw arpeggio pattern visualization"""
	var size = _visualization.size
	var margin = 20
	var width = size.x - margin * 2
	var height = size.y - margin * 2
	
	# Generate note sequence based on pattern
	var notes = _generate_note_sequence()
	if notes.is_empty():
		return
	
	var step_width = width / float(notes.size())
	var note_height = height / float(_octave_range * 12 + 1)
	
	# Draw notes
	for i in range(notes.size()):
		var note = notes[i]
		var x = margin + i * step_width
		var y = margin + height - (note * note_height)
		
		# Note bar
		var bar_width = step_width * _gate_length * 0.9
		var bar_height = note_height * 0.8
		
		# Velocity-based color
		var vel = _get_velocity_at_step(i, notes.size())
		var color = Color.from_hsv(0.85 - vel * 0.15, 0.6, 0.5 + vel * 0.4)
		
		# Highlight current note if playing
		if _is_playing and i == _current_note:
			color = color.lightened(0.3)
		
		_visualization.draw_rect(Rect2(x, y - bar_height, bar_width, bar_height), color)
		
		# Connect notes with lines
		if i < notes.size() - 1:
			var next_note = notes[i + 1]
			var next_x = margin + (i + 1) * step_width
			var next_y = margin + height - (next_note * note_height) - bar_height / 2
			_visualization.draw_line(
				Vector2(x + bar_width, y - bar_height / 2),
				Vector2(next_x, next_y),
				Color(0.4, 0.4, 0.45, 0.5),
				1.0
			)


func _generate_note_sequence() -> Array:
	"""Generate note sequence based on pattern type and octave range"""
	var base_notes = [0, 4, 7]  # Major triad intervals
	var all_notes = []
	
	# Build notes across octaves
	for oct in range(_octave_range):
		for note in base_notes:
			all_notes.append(note + oct * 12)
	
	# Apply pattern
	var sequence = []
	match _pattern:
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
				down = down.slice(1, down.size() - 1)  # Remove endpoints to avoid repetition
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


func _get_velocity_at_step(step: int, total: int) -> float:
	match _velocity_curve:
		"crescendo":
			return 0.4 + 0.6 * (float(step) / float(total - 1)) if total > 1 else 1.0
		"decrescendo":
			return 1.0 - 0.6 * (float(step) / float(total - 1)) if total > 1 else 1.0
		"accent_first":
			return 1.0 if step == 0 else 0.6
		"accent_last":
			return 1.0 if step == total - 1 else 0.6
		_:  # flat
			return 0.8


func _on_play_pressed():
	if _is_playing:
		_stop_playback()
	else:
		_start_playback()


func _start_playback():
	_is_playing = true
	_current_note = 0
	_play_btn.text = "⏹ Stop"
	
	var step_duration = 60.0 / _bpm * RATES[_rate] * 4
	_step_timer.wait_time = step_duration
	_step_timer.start()
	_visualization.queue_redraw()


func _stop_playback():
	_is_playing = false
	_play_btn.text = "▶ Play"
	_step_timer.stop()
	_visualization.queue_redraw()


func _on_step_tick():
	var notes = _generate_note_sequence()
	if notes.size() > 0:
		_current_note = (_current_note + 1) % notes.size()
	_visualization.queue_redraw()


func _on_apply_pressed():
	pattern_changed.emit(get_settings())


func get_settings() -> Dictionary:
	return {
		"pattern": _pattern,
		"rate": _rate,
		"octave_range": _octave_range,
		"gate_length": _gate_length,
		"swing": _swing,
		"velocity_curve": _velocity_curve,
	}


func set_bpm(bpm: float):
	_bpm = bpm
	if _is_playing:
		var step_duration = 60.0 / _bpm * RATES[_rate] * 4
		_step_timer.wait_time = step_duration


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


func _style_toggle_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.4)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 12)
	
	var hover = style.duplicate()
	hover.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color
	pressed.border_color = color.lightened(0.3)
	pressed.set_border_width_all(2)
	btn.add_theme_stylebox_override("pressed", pressed)
