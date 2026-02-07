# DrumSequencer.gd
# 16-step drum pattern sequencer with velocity levels
# For kick, snare, hihat, clap, etc.
#
# ⚠️ DEPRECATED: This class is maintained for backwards compatibility.
# Please use DrumPatternEditor from the unified pattern editor architecture instead.
# See: commons/audio/catalog/ui/DrumPatternEditor.gd

extends Control
class_name DrumSequencer

signal pattern_changed(pattern: Array)
signal preview_requested(element: String)

const STEP_COUNT = 16
const CELL_SIZE = Vector2(32, 28)
const HEADER_HEIGHT = 30
const ROW_LABEL_WIDTH = 70

# Velocity levels: 0 = off, 0.5 = ghost, 1.0 = normal, 2.0 = accent
const VELOCITY_LEVELS = [0.0, 0.5, 1.0, 2.0]
const VELOCITY_COLORS = {
	0.0: Color(0.12, 0.12, 0.15),      # Off - dark
	0.5: Color(0.25, 0.35, 0.45),      # Ghost - dim blue
	1.0: Color(0.3, 0.6, 0.85),        # Normal - blue
	2.0: Color(0.85, 0.35, 0.25),      # Accent - red
}

# Pattern data: element_name -> Array[16 floats]
var _patterns: Dictionary = {}
var _elements: Array = []
var _swing: float = 0.0  # 0-30%
var _bpm: float = 120.0

# UI
var _grid_container: Control
var _cells: Dictionary = {}  # "element_step" -> ColorRect
var _swing_slider: HSlider
var _swing_label: Label
var _play_btn: Button
var _apply_btn: Button

# Playback
var _player: AudioStreamPlayer
var _is_playing: bool = false
var _current_step: int = 0
var _step_timer: Timer


func _ready():
	_setup_ui()
	_setup_playback()


func _setup_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	# Header with controls
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🥁 DRUM SEQUENCER"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	header.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Swing control
	var swing_label = Label.new()
	swing_label.text = "Swing:"
	swing_label.add_theme_font_size_override("font_size", 13)
	header.add_child(swing_label)
	
	_swing_slider = HSlider.new()
	_swing_slider.min_value = 0
	_swing_slider.max_value = 30
	_swing_slider.value = 0
	_swing_slider.step = 1
	_swing_slider.custom_minimum_size.x = 100
	_swing_slider.value_changed.connect(_on_swing_changed)
	header.add_child(_swing_slider)
	
	_swing_label = Label.new()
	_swing_label.text = "0%"
	_swing_label.add_theme_font_size_override("font_size", 12)
	_swing_label.custom_minimum_size.x = 35
	header.add_child(_swing_label)
	
	# Transport buttons
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
	
	# Legend
	var legend = _create_legend()
	main_vbox.add_child(legend)
	
	# Scroll container for grid
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	# Grid container
	_grid_container = Control.new()
	scroll.add_child(_grid_container)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Click: toggle • Right-click/Shift-click: cycle velocity (ghost → normal → accent → off)"
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	main_vbox.add_child(instructions)


func _create_legend() -> HBoxContainer:
	var legend = HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	
	var items = [
		["Off", VELOCITY_COLORS[0.0]],
		["Ghost", VELOCITY_COLORS[0.5]],
		["Normal", VELOCITY_COLORS[1.0]],
		["Accent", VELOCITY_COLORS[2.0]],
	]
	
	for item in items:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		
		var swatch = ColorRect.new()
		swatch.color = item[1]
		swatch.custom_minimum_size = Vector2(16, 16)
		hbox.add_child(swatch)
		
		var label = Label.new()
		label.text = item[0]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		hbox.add_child(label)
		
		legend.add_child(hbox)
	
	return legend


func _setup_playback():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	
	_step_timer = Timer.new()
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_on_step_tick)
	add_child(_step_timer)


func load_patterns(patterns: Dictionary, elements: Array = []):
	"""Load drum patterns from SoundbankGenerator format"""
	_patterns.clear()
	_elements.clear()
	_cells.clear()
	
	# Clear existing grid
	for child in _grid_container.get_children():
		child.queue_free()
	
	# Determine elements to show
	if elements.is_empty():
		_elements = patterns.keys()
	else:
		_elements = elements
	
	# Copy patterns
	for element in _elements:
		if patterns.has(element):
			_patterns[element] = patterns[element].duplicate()
		else:
			# Initialize with empty pattern
			_patterns[element] = []
			for i in range(STEP_COUNT):
				_patterns[element].append(0.0)
	
	_rebuild_grid()


func _rebuild_grid():
	"""Rebuild the visual grid"""
	# Clear existing
	for child in _grid_container.get_children():
		child.queue_free()
	_cells.clear()
	
	var grid_width = ROW_LABEL_WIDTH + (STEP_COUNT * CELL_SIZE.x) + 20
	var grid_height = HEADER_HEIGHT + (_elements.size() * CELL_SIZE.y) + 10
	_grid_container.custom_minimum_size = Vector2(grid_width, grid_height)
	
	# Beat markers header
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
		marker.position = Vector2(ROW_LABEL_WIDTH + step * CELL_SIZE.x + 8, 5)
		_grid_container.add_child(marker)
	
	# Rows
	for row_idx in range(_elements.size()):
		var element = _elements[row_idx]
		var y = HEADER_HEIGHT + row_idx * CELL_SIZE.y
		
		# Row label (clickable for preview)
		var label_btn = Button.new()
		label_btn.text = element.capitalize()
		label_btn.position = Vector2(0, y)
		label_btn.custom_minimum_size = Vector2(ROW_LABEL_WIDTH - 4, CELL_SIZE.y - 2)
		label_btn.add_theme_font_size_override("font_size", 11)
		label_btn.pressed.connect(_on_element_preview.bind(element))
		_style_row_button(label_btn)
		_grid_container.add_child(label_btn)
		
		# Cells
		var pattern = _patterns.get(element, [])
		for step in range(STEP_COUNT):
			var vel = pattern[step] if step < pattern.size() else 0.0
			var cell = _create_cell(element, step, vel)
			cell.position = Vector2(ROW_LABEL_WIDTH + step * CELL_SIZE.x, y)
			_grid_container.add_child(cell)
			_cells["%s_%d" % [element, step]] = cell


func _create_cell(element: String, step: int, velocity: float) -> ColorRect:
	var cell = ColorRect.new()
	cell.custom_minimum_size = CELL_SIZE - Vector2(2, 2)
	cell.size = CELL_SIZE - Vector2(2, 2)
	cell.color = _get_velocity_color(velocity)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.gui_input.connect(_on_cell_input.bind(element, step))
	
	# Beat separator highlight
	if step % 4 == 0:
		var border = ColorRect.new()
		border.color = Color(0.3, 0.3, 0.35)
		border.size = Vector2(1, CELL_SIZE.y - 2)
		border.position = Vector2(-1, 0)
		cell.add_child(border)
	
	return cell


func _get_velocity_color(velocity: float) -> Color:
	if velocity >= 2.0:
		return VELOCITY_COLORS[2.0]
	elif velocity >= 1.0:
		return VELOCITY_COLORS[1.0]
	elif velocity > 0:
		return VELOCITY_COLORS[0.5]
	else:
		return VELOCITY_COLORS[0.0]


func _on_cell_input(event: InputEvent, element: String, step: int):
	if event is InputEventMouseButton and event.pressed:
		var pattern = _patterns.get(element, [])
		if step >= pattern.size():
			return
		
		var current_vel = pattern[step]
		var new_vel: float
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				# Shift+click: cycle velocity
				new_vel = _cycle_velocity(current_vel, 1)
			else:
				# Left click: toggle on/off
				new_vel = 1.0 if current_vel == 0.0 else 0.0
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click: cycle velocity
			new_vel = _cycle_velocity(current_vel, 1)
		else:
			return
		
		pattern[step] = new_vel
		_patterns[element] = pattern
		
		# Update visual
		var cell_key = "%s_%d" % [element, step]
		if _cells.has(cell_key):
			_cells[cell_key].color = _get_velocity_color(new_vel)
		
		pattern_changed.emit(get_combined_pattern())


func _cycle_velocity(current: float, direction: int) -> float:
	var current_idx = 0
	for i in range(VELOCITY_LEVELS.size()):
		if abs(current - VELOCITY_LEVELS[i]) < 0.1:
			current_idx = i
			break
	
	var new_idx = (current_idx + direction + VELOCITY_LEVELS.size()) % VELOCITY_LEVELS.size()
	return VELOCITY_LEVELS[new_idx]


func _on_swing_changed(value: float):
	_swing = value
	_swing_label.text = "%d%%" % int(value)


func _on_play_pressed():
	if _is_playing:
		_stop_playback()
	else:
		_start_playback()


func _start_playback():
	_is_playing = true
	_current_step = 0
	_play_btn.text = "⏹ Stop"
	
	var step_duration = 60.0 / _bpm / 4.0  # 16th note
	_step_timer.wait_time = step_duration
	_step_timer.start()
	
	_highlight_step(0)


func _stop_playback():
	_is_playing = false
	_play_btn.text = "▶ Play"
	_step_timer.stop()
	_clear_highlights()


func _on_step_tick():
	_current_step = (_current_step + 1) % STEP_COUNT
	_highlight_step(_current_step)
	
	# Play sounds for this step
	for element in _elements:
		var pattern = _patterns.get(element, [])
		if _current_step < pattern.size() and pattern[_current_step] > 0:
			# TODO: Actually trigger the sound
			pass


func _highlight_step(step: int):
	_clear_highlights()
	
	for element in _elements:
		var cell_key = "%s_%d" % [element, step]
		if _cells.has(cell_key):
			var cell = _cells[cell_key]
			var vel = _patterns.get(element, [])[step] if step < _patterns.get(element, []).size() else 0.0
			# Brighten the cell
			cell.color = _get_velocity_color(vel).lightened(0.3)


func _clear_highlights():
	for element in _elements:
		for step in range(STEP_COUNT):
			var cell_key = "%s_%d" % [element, step]
			if _cells.has(cell_key):
				var vel = _patterns.get(element, [])[step] if step < _patterns.get(element, []).size() else 0.0
				_cells[cell_key].color = _get_velocity_color(vel)


func _on_element_preview(element: String):
	preview_requested.emit(element)


func _on_apply_pressed():
	pattern_changed.emit(get_combined_pattern())


func get_combined_pattern() -> Dictionary:
	"""Return the current pattern state"""
	return _patterns.duplicate(true)


func set_bpm(bpm: float):
	_bpm = bpm
	if _is_playing:
		var step_duration = 60.0 / _bpm / 4.0
		_step_timer.wait_time = step_duration


func set_swing(swing: float):
	_swing = clampf(swing, 0.0, 30.0)
	_swing_slider.value = _swing
	_swing_label.text = "%d%%" % int(_swing)


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


func _style_row_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.25, 0.25, 0.3)
	btn.add_theme_stylebox_override("hover", hover)
