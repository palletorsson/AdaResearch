# BasePatternEditor.gd
# Shared base class for all pattern editors (drum, bass, chord, arp)
# Provides common grid rendering, transport, and interaction

extends Control
class_name BasePatternEditor

# Signals
signal pattern_changed(pattern_data: Dictionary)
signal preview_requested(element)
signal playback_started()
signal playback_stopped()

# Constants
const STEP_COUNT = 16
const CELL_SIZE = Vector2(32, 28)
const HEADER_HEIGHT = 30
const ROW_LABEL_WIDTH = 70
const PLAYHEAD_COLOR = Color(0.3, 0.8, 1.0, 0.8)

# Velocity levels and colors
const VELOCITY_LEVELS = [0.0, 0.5, 1.0, 2.0]
const VELOCITY_COLORS = {
	0.0: Color(0.12, 0.12, 0.15),      # Off - dark
	0.5: Color(0.25, 0.35, 0.45),      # Ghost - dim blue
	1.0: Color(0.3, 0.6, 0.85),        # Normal - blue
	2.0: Color(0.85, 0.35, 0.25),      # Accent - red
}

# Pattern data (to be populated by subclasses)
var _pattern_data: Dictionary = {}
var _step_count: int = STEP_COUNT

# Settings
var _swing: float = 0.0           # 0-30%
var _humanize: float = 0.0        # 0-20ms
var _bpm: float = 120.0

# UI Components
var _main_container: VBoxContainer
var _header: HBoxContainer
var _title_label: Label
var _controls_container: HBoxContainer
var _grid_scroll: ScrollContainer
var _grid_container: Control
var _cells: Dictionary = {}       # "row_step" -> Control
var _row_labels: Dictionary = {}  # row -> Control
var _footer: HBoxContainer

# Transport
var _play_btn: Button
var _stop_btn: Button
var _swing_slider: HSlider
var _swing_label: Label
var _humanize_slider: HSlider
var _humanize_label: Label
var _bpm_spin: SpinBox
var _apply_btn: Button

# Playback state
var _player: AudioStreamPlayer
var _is_playing: bool = false
var _current_step: int = 0
var _step_timer: Timer
var _playhead: ColorRect

# Dragging
var _is_dragging: bool = false
var _drag_start_row: int = -1
var _drag_start_step: int = -1
var _drag_button: int = MOUSE_BUTTON_LEFT


func _ready():
	_setup_ui()
	_setup_playback()
	_initialize_pattern()
	_rebuild_grid()


# ===== ABSTRACT METHODS (Override in subclasses) =====

func _get_row_count() -> int:
	"""Override: Return number of rows"""
	return 4


func _get_row_label(row: int) -> String:
	"""Override: Return label for row"""
	return "Row %d" % row


func _get_row_sound(row: int) -> String:
	"""Override: Return sound name for row"""
	return "sound_%d" % row


func _get_row_color(row: int) -> Color:
	"""Override: Return custom color for row (or null for default velocity colors)"""
	return Color.WHITE  # Return WHITE to use default velocity colors


func _render_step(row: int, step: int, cell: Control, data: Dictionary) -> void:
	"""Override: Custom step rendering"""
	pass


func _on_step_clicked(row: int, step: int, button: int) -> void:
	"""Override: Handle step click"""
	pass


func _on_step_drag(row: int, step: int, button: int) -> void:
	"""Override: Handle step drag"""
	pass


func _get_default_step_data() -> Dictionary:
	"""Override: Return default data for a step"""
	return {"active": false, "velocity": 0.0}


func _get_editor_title() -> String:
	"""Override: Return editor title"""
	return "🎵 PATTERN EDITOR"


func _get_editor_color() -> Color:
	"""Override: Return editor accent color"""
	return Color(0.4, 0.6, 0.8)


func _initialize_pattern() -> void:
	"""Override: Initialize pattern data structure"""
	pass


func _get_pattern_for_export() -> Dictionary:
	"""Override: Return pattern data for export"""
	return _pattern_data.duplicate(true)


func _on_extra_controls_setup(container: HBoxContainer) -> void:
	"""Override: Add extra controls to header"""
	pass


# ===== UI SETUP =====

func _setup_ui():
	# Main container
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 8)
	add_child(_main_container)
	
	# Header with title and transport
	_setup_header()
	
	# Extra controls row (for subclass-specific controls)
	_setup_controls()
	
	# Legend
	var legend = _create_legend()
	_main_container.add_child(legend)
	
	# Grid area with scroll
	_grid_scroll = ScrollContainer.new()
	_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_main_container.add_child(_grid_scroll)
	
	_grid_container = Control.new()
	_grid_scroll.add_child(_grid_container)
	
	# Playhead
	_playhead = ColorRect.new()
	_playhead.color = PLAYHEAD_COLOR
	_playhead.custom_minimum_size = Vector2(2, 0)
	_playhead.visible = false
	_playhead.z_index = 100
	_grid_container.add_child(_playhead)
	
	# Footer with instructions
	_setup_footer()


func _setup_header():
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 12)
	_main_container.add_child(_header)
	
	# Title
	_title_label = Label.new()
	_title_label.text = _get_editor_title()
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", _get_editor_color())
	_header.add_child(_title_label)
	
	# Spacer
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
	
	# Transport buttons
	_play_btn = Button.new()
	_play_btn.text = "▶ Play"
	_play_btn.pressed.connect(_on_play_pressed)
	_style_button(_play_btn, Color(0.2, 0.5, 0.3))
	_header.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "⏹ Stop"
	_stop_btn.pressed.connect(_on_stop_pressed)
	_style_button(_stop_btn, Color(0.5, 0.3, 0.2))
	_header.add_child(_stop_btn)
	
	# Apply button
	_apply_btn = Button.new()
	_apply_btn.text = "✓ Apply"
	_apply_btn.pressed.connect(_on_apply_pressed)
	_style_button(_apply_btn, Color(0.3, 0.4, 0.6))
	_header.add_child(_apply_btn)


func _setup_controls():
	_controls_container = HBoxContainer.new()
	_controls_container.add_theme_constant_override("separation", 16)
	_main_container.add_child(_controls_container)
	
	# Swing control
	var swing_hbox = HBoxContainer.new()
	swing_hbox.add_theme_constant_override("separation", 4)
	_controls_container.add_child(swing_hbox)
	
	var swing_title = Label.new()
	swing_title.text = "Swing:"
	swing_title.add_theme_font_size_override("font_size", 12)
	swing_hbox.add_child(swing_title)
	
	_swing_slider = HSlider.new()
	_swing_slider.min_value = 0
	_swing_slider.max_value = 30
	_swing_slider.value = 0
	_swing_slider.step = 1
	_swing_slider.custom_minimum_size.x = 80
	_swing_slider.value_changed.connect(_on_swing_changed)
	swing_hbox.add_child(_swing_slider)
	
	_swing_label = Label.new()
	_swing_label.text = "0%"
	_swing_label.add_theme_font_size_override("font_size", 11)
	_swing_label.custom_minimum_size.x = 30
	swing_hbox.add_child(_swing_label)
	
	# Humanize control
	var humanize_hbox = HBoxContainer.new()
	humanize_hbox.add_theme_constant_override("separation", 4)
	_controls_container.add_child(humanize_hbox)
	
	var humanize_title = Label.new()
	humanize_title.text = "Humanize:"
	humanize_title.add_theme_font_size_override("font_size", 12)
	humanize_hbox.add_child(humanize_title)
	
	_humanize_slider = HSlider.new()
	_humanize_slider.min_value = 0
	_humanize_slider.max_value = 20
	_humanize_slider.value = 0
	_humanize_slider.step = 1
	_humanize_slider.custom_minimum_size.x = 80
	_humanize_slider.value_changed.connect(_on_humanize_changed)
	humanize_hbox.add_child(_humanize_slider)
	
	_humanize_label = Label.new()
	_humanize_label.text = "0ms"
	_humanize_label.add_theme_font_size_override("font_size", 11)
	_humanize_label.custom_minimum_size.x = 35
	humanize_hbox.add_child(_humanize_label)
	
	# Spacer for subclass controls
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 20
	_controls_container.add_child(spacer)
	
	# Allow subclasses to add controls
	_on_extra_controls_setup(_controls_container)


func _setup_footer():
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	_main_container.add_child(_footer)
	
	var instructions = Label.new()
	instructions.text = "Click: toggle • Right-click/Shift-click: cycle velocity (ghost → normal → accent → off)"
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	_footer.add_child(instructions)


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


# ===== GRID BUILDING =====

func _rebuild_grid():
	"""Rebuild the visual grid from pattern data"""
	# Clear existing (except playhead)
	for child in _grid_container.get_children():
		if child != _playhead:
			child.queue_free()
	_cells.clear()
	_row_labels.clear()
	
	var row_count = _get_row_count()
	var grid_width = ROW_LABEL_WIDTH + (_step_count * CELL_SIZE.x) + 20
	var grid_height = HEADER_HEIGHT + (row_count * CELL_SIZE.y) + 10
	_grid_container.custom_minimum_size = Vector2(grid_width, grid_height)
	
	# Beat markers header
	_draw_beat_markers()
	
	# Rows
	for row in range(row_count):
		_draw_row(row)
	
	# Update playhead size
	_playhead.size = Vector2(2, grid_height)
	_playhead.position = Vector2(ROW_LABEL_WIDTH, 0)


func _draw_beat_markers():
	for step in range(_step_count):
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


func _draw_row(row: int):
	var y = HEADER_HEIGHT + row * CELL_SIZE.y
	var row_name = _get_row_label(row)
	
	# Row label (clickable for preview)
	var label_btn = Button.new()
	label_btn.text = row_name
	label_btn.position = Vector2(0, y)
	label_btn.custom_minimum_size = Vector2(ROW_LABEL_WIDTH - 4, CELL_SIZE.y - 2)
	label_btn.add_theme_font_size_override("font_size", 11)
	label_btn.pressed.connect(_on_row_preview.bind(row))
	_style_row_button(label_btn)
	_grid_container.add_child(label_btn)
	_row_labels[row] = label_btn
	
	# Cells
	for step in range(_step_count):
		var cell = _create_cell(row, step)
		cell.position = Vector2(ROW_LABEL_WIDTH + step * CELL_SIZE.x, y)
		_grid_container.add_child(cell)
		_cells["%d_%d" % [row, step]] = cell


func _create_cell(row: int, step: int) -> Control:
	var cell = Control.new()
	cell.custom_minimum_size = CELL_SIZE - Vector2(2, 2)
	cell.size = CELL_SIZE - Vector2(2, 2)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.gui_input.connect(_on_cell_input.bind(row, step))
	
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = cell.size
	bg.color = _get_cell_color(row, step)
	cell.add_child(bg)
	
	# Beat separator highlight
	if step % 4 == 0:
		var border = ColorRect.new()
		border.name = "BeatBorder"
		border.color = Color(0.3, 0.3, 0.35)
		border.size = Vector2(1, CELL_SIZE.y - 2)
		border.position = Vector2(-1, 0)
		cell.add_child(border)
	
	# Allow subclasses to add custom rendering
	var data = _get_step_data(row, step)
	_render_step(row, step, cell, data)
	
	return cell


func _get_cell_color(row: int, step: int) -> Color:
	var data = _get_step_data(row, step)
	var velocity = data.get("velocity", 0.0)
	
	# Check if subclass wants custom color
	var custom_color = _get_row_color(row)
	if custom_color != Color.WHITE:
		if velocity <= 0:
			return VELOCITY_COLORS[0.0]
		elif velocity < 1.0:
			return custom_color.darkened(0.5)
		elif velocity >= 2.0:
			return custom_color.lightened(0.3)
		else:
			return custom_color
	
	# Default velocity coloring
	return _get_velocity_color(velocity)


func _get_velocity_color(velocity: float) -> Color:
	if velocity >= 2.0:
		return VELOCITY_COLORS[2.0]
	elif velocity >= 1.0:
		return VELOCITY_COLORS[1.0]
	elif velocity > 0:
		return VELOCITY_COLORS[0.5]
	else:
		return VELOCITY_COLORS[0.0]


func _get_step_data(row: int, step: int) -> Dictionary:
	"""Get step data - override in subclasses for custom data structure"""
	return _get_default_step_data()


func _set_step_data(row: int, step: int, data: Dictionary):
	"""Set step data - override in subclasses"""
	pass


# ===== CELL UPDATE =====

func _update_cell(row: int, step: int):
	"""Update a single cell's appearance"""
	var cell_key = "%d_%d" % [row, step]
	if not _cells.has(cell_key):
		return
	
	var cell = _cells[cell_key]
	var bg = cell.get_node_or_null("Background")
	if bg:
		bg.color = _get_cell_color(row, step)
	
	# Re-render custom content
	var data = _get_step_data(row, step)
	_render_step(row, step, cell, data)


func _highlight_step(step: int):
	"""Highlight the current playhead step"""
	for row in range(_get_row_count()):
		for s in range(_step_count):
			var cell_key = "%d_%d" % [row, s]
			if _cells.has(cell_key):
				var cell = _cells[cell_key]
				var bg = cell.get_node_or_null("Background")
				if bg:
					var base_color = _get_cell_color(row, s)
					if s == step:
						bg.color = base_color.lightened(0.3)
					else:
						bg.color = base_color
	
	# Update playhead position
	_playhead.position.x = ROW_LABEL_WIDTH + step * CELL_SIZE.x
	_playhead.visible = true


func _clear_highlights():
	"""Clear all step highlights"""
	for row in range(_get_row_count()):
		for step in range(_step_count):
			_update_cell(row, step)
	_playhead.visible = false


# ===== INPUT HANDLING =====

func _on_cell_input(event: InputEvent, row: int, step: int):
	if event is InputEventMouseButton:
		if event.pressed:
			_drag_button = event.button_index
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.shift_pressed:
					# Shift+click: cycle velocity
					_cycle_velocity(row, step, 1)
				else:
					# Start drag and handle click
					_is_dragging = true
					_drag_start_row = row
					_drag_start_step = step
					_on_step_clicked(row, step, MOUSE_BUTTON_LEFT)
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Right click: cycle velocity
				_cycle_velocity(row, step, 1)
		else:
			# End drag
			_is_dragging = false
			_drag_start_row = -1
			_drag_start_step = -1
	
	elif event is InputEventMouseMotion and _is_dragging:
		_on_step_drag(row, step, _drag_button)


func _cycle_velocity(row: int, step: int, direction: int):
	"""Cycle through velocity levels"""
	var data = _get_step_data(row, step)
	var current = data.get("velocity", 0.0)
	
	var current_idx = 0
	for i in range(VELOCITY_LEVELS.size()):
		if abs(current - VELOCITY_LEVELS[i]) < 0.1:
			current_idx = i
			break
	
	var new_idx = (current_idx + direction + VELOCITY_LEVELS.size()) % VELOCITY_LEVELS.size()
	var new_vel = VELOCITY_LEVELS[new_idx]
	
	data["velocity"] = new_vel
	data["active"] = new_vel > 0
	_set_step_data(row, step, data)
	
	_update_cell(row, step)
	pattern_changed.emit(_get_pattern_for_export())


func _on_row_preview(row: int):
	"""Preview the sound for a row"""
	var sound = _get_row_sound(row)
	preview_requested.emit(sound)


# ===== TRANSPORT CONTROLS =====

func _on_play_pressed():
	if _is_playing:
		_pause_playback()
	else:
		_start_playback()


func _on_stop_pressed():
	_stop_playback()


func _start_playback():
	_is_playing = true
	_current_step = 0
	_play_btn.text = "⏸ Pause"
	
	var step_duration = 60.0 / _bpm / 4.0  # 16th note
	_step_timer.wait_time = step_duration
	_step_timer.start()
	
	_highlight_step(0)
	playback_started.emit()


func _pause_playback():
	_is_playing = false
	_play_btn.text = "▶ Play"
	_step_timer.stop()


func _stop_playback():
	_is_playing = false
	_play_btn.text = "▶ Play"
	_step_timer.stop()
	_current_step = 0
	_clear_highlights()
	playback_stopped.emit()


func _on_step_tick():
	_current_step = (_current_step + 1) % _step_count
	_highlight_step(_current_step)
	
	# Trigger sounds for active steps
	_trigger_step_sounds(_current_step)


func _trigger_step_sounds(step: int):
	"""Trigger sounds for active steps - override in subclasses"""
	for row in range(_get_row_count()):
		var data = _get_step_data(row, step)
		if data.get("active", false) or data.get("velocity", 0.0) > 0:
			preview_requested.emit(_get_row_sound(row))


# ===== CONTROL CALLBACKS =====

func _on_swing_changed(value: float):
	_swing = value
	_swing_label.text = "%d%%" % int(value)


func _on_humanize_changed(value: float):
	_humanize = value
	_humanize_label.text = "%dms" % int(value)


func _on_bpm_changed(value: float):
	_bpm = value
	if _is_playing:
		var step_duration = 60.0 / _bpm / 4.0
		_step_timer.wait_time = step_duration


func _on_apply_pressed():
	pattern_changed.emit(_get_pattern_for_export())


# ===== PUBLIC API =====

func set_bpm(bpm: float):
	_bpm = bpm
	_bpm_spin.value = bpm
	if _is_playing:
		var step_duration = 60.0 / _bpm / 4.0
		_step_timer.wait_time = step_duration


func get_bpm() -> float:
	return _bpm


func set_swing(swing: float):
	_swing = clampf(swing, 0.0, 30.0)
	_swing_slider.value = _swing
	_swing_label.text = "%d%%" % int(_swing)


func get_swing() -> float:
	return _swing


func set_humanize(humanize: float):
	_humanize = clampf(humanize, 0.0, 20.0)
	_humanize_slider.value = _humanize
	_humanize_label.text = "%dms" % int(_humanize)


func get_humanize() -> float:
	return _humanize


func get_pattern_data() -> Dictionary:
	"""Return the current pattern data"""
	return _get_pattern_for_export()


func is_playing() -> bool:
	return _is_playing


func play():
	_start_playback()


func stop():
	_stop_playback()


# ===== STYLING HELPERS =====

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
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)


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
