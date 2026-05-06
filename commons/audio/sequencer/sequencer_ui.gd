extends Control
class_name SequencerUI

## 2D Step Sequencer UI
## A simple grid of toggle buttons for step sequencing
## Designed to be embedded in 3D via Viewport2Din3D

signal cell_toggled(track: int, step: int, active: bool)
signal playback_toggled(playing: bool)
signal bpm_changed(bpm: float)
signal preset_changed(preset_name: String)
signal pattern_preset_changed(preset_name: String)

## Grid dimensions
@export var num_tracks: int = 4
@export var num_steps: int = 16

## Timing
@export var bpm: float = 120.0

## Sound preset
@export var sound_preset: String = "808_kit"

## Colors for each track - saturated colors for active cells
const TRACK_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.2),   # Red - Kick
	Color(0.9, 0.7, 0.1),   # Orange/Yellow - Snare
	Color(0.2, 0.7, 0.6),   # Teal - Hi-hat
	Color(0.6, 0.3, 0.7),   # Purple - Bass
]

## Background color - Light theme
const BG_COLOR: Color = Color(0.85, 0.85, 0.88)  # Light gray
const HEADER_BG_COLOR: Color = Color(0.9, 0.9, 0.92)  # Slightly lighter

const SOUND_PRESETS: Array[String] = [
	"808_kit", "trap_beats", "synth_kit", "tech_noir", "retro", "90s_house", "juno_pads",
	"kraftwerk", "disco", "ambient_works", "jazz_fusion", "chiptune",
	"sci_fi_lab", "cinematic", "breakbeat", "cosmic", "lo_fi"
]

const PATTERN_PRESETS: Array[String] = [
	"empty", "four_on_floor", "techno", "house", "trap", "breakbeat",
	"minimal", "disco", "dnb", "ambient"
]

## Internal state
var _grid_data: Array = []  # 2D array: _grid_data[track][step] = bool
var _buttons: Array = []    # 2D array of Button nodes
var _playhead_position: int = 0
var _is_playing: bool = false

## UI references
var _grid_container: GridContainer
var _play_button: Button
var _bpm_slider: HSlider
var _bpm_label: Label
var _preset_button: OptionButton
var _pattern_button: OptionButton
var _step_label: Label
var _playhead_indicators: Array[Panel] = []


func _ready() -> void:
	_initialize_grid_data()
	_create_ui()
	_update_step_label()


func _initialize_grid_data() -> void:
	_grid_data.clear()
	for track in range(num_tracks):
		var track_data: Array[bool] = []
		for step in range(num_steps):
			track_data.append(false)
		_grid_data.append(track_data)


func _create_ui() -> void:
	# Background panel
	var bg_panel = Panel.new()
	bg_panel.name = "Background"
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = BG_COLOR
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.content_margin_left = 12
	bg_style.content_margin_right = 12
	bg_style.content_margin_top = 8
	bg_style.content_margin_bottom = 8
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)

	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	bg_panel.add_child(main_vbox)

	# Header with controls
	var header = HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)

	# Play/Stop button
	_play_button = Button.new()
	_play_button.name = "PlayButton"
	_play_button.text = "▶ Play"
	_play_button.custom_minimum_size = Vector2(90, 36)
	_play_button.pressed.connect(_on_play_pressed)

	# Style play button - Light theme
	var play_style = StyleBoxFlat.new()
	play_style.bg_color = Color(0.95, 0.95, 0.97)  # Light
	play_style.corner_radius_top_left = 3
	play_style.corner_radius_top_right = 3
	play_style.corner_radius_bottom_left = 3
	play_style.corner_radius_bottom_right = 3
	play_style.border_width_left = 1
	play_style.border_width_right = 1
	play_style.border_width_top = 1
	play_style.border_width_bottom = 1
	play_style.border_color = Color(0.7, 0.7, 0.72)
	_play_button.add_theme_stylebox_override("normal", play_style)

	var play_hover = StyleBoxFlat.new()
	play_hover.bg_color = Color(0.9, 0.9, 0.92)
	play_hover.corner_radius_top_left = 3
	play_hover.corner_radius_top_right = 3
	play_hover.corner_radius_bottom_left = 3
	play_hover.corner_radius_bottom_right = 3
	play_hover.border_width_left = 1
	play_hover.border_width_right = 1
	play_hover.border_width_top = 1
	play_hover.border_width_bottom = 1
	play_hover.border_color = Color(0.3, 0.6, 0.4)  # Green border on hover
	_play_button.add_theme_stylebox_override("hover", play_hover)

	_play_button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
	_play_button.add_theme_font_size_override("font_size", 14)

	header.add_child(_play_button)

	# BPM controls
	var bpm_box = HBoxContainer.new()
	bpm_box.add_theme_constant_override("separation", 4)
	header.add_child(bpm_box)

	_bpm_label = Label.new()
	_bpm_label.text = "BPM: %d" % int(bpm)
	_bpm_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))  # Dark text
	bpm_box.add_child(_bpm_label)

	_bpm_slider = HSlider.new()
	_bpm_slider.min_value = 60
	_bpm_slider.max_value = 200
	_bpm_slider.value = bpm
	_bpm_slider.custom_minimum_size = Vector2(100, 20)
	_bpm_slider.value_changed.connect(_on_bpm_changed)
	bpm_box.add_child(_bpm_slider)

	# Sound preset selector
	_preset_button = OptionButton.new()
	_preset_button.name = "PresetButton"
	for preset in SOUND_PRESETS:
		_preset_button.add_item(preset)
	_preset_button.selected = SOUND_PRESETS.find(sound_preset)
	_preset_button.item_selected.connect(_on_preset_selected)
	header.add_child(_preset_button)

	# Pattern preset selector
	_pattern_button = OptionButton.new()
	_pattern_button.name = "PatternButton"
	for pattern in PATTERN_PRESETS:
		_pattern_button.add_item(pattern)
	_pattern_button.selected = 0  # Default to "empty"
	_pattern_button.item_selected.connect(_on_pattern_selected)
	header.add_child(_pattern_button)

	# Step label
	_step_label = Label.new()
	_step_label.name = "StepLabel"
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))  # Muted dark text
	header.add_child(_step_label)

	# Playhead indicator row
	var playhead_row = HBoxContainer.new()
	playhead_row.name = "PlayheadRow"
	playhead_row.add_theme_constant_override("separation", 2)
	main_vbox.add_child(playhead_row)

	# Spacer for track labels
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(60, 10)
	playhead_row.add_child(spacer)

	# Playhead indicators - Light theme
	for step in range(num_steps):
		var indicator = Panel.new()
		indicator.custom_minimum_size = Vector2(28, 6)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.75, 0.75, 0.78)  # Light gray inactive
		style.corner_radius_top_left = 1
		style.corner_radius_top_right = 1
		style.corner_radius_bottom_left = 1
		style.corner_radius_bottom_right = 1
		indicator.add_theme_stylebox_override("panel", style)
		playhead_row.add_child(indicator)
		_playhead_indicators.append(indicator)

	# Grid with track labels
	var grid_hbox = HBoxContainer.new()
	grid_hbox.name = "GridHBox"
	grid_hbox.add_theme_constant_override("separation", 4)
	main_vbox.add_child(grid_hbox)

	# Track labels column
	var labels_vbox = VBoxContainer.new()
	labels_vbox.add_theme_constant_override("separation", 2)
	grid_hbox.add_child(labels_vbox)

	var track_names = ["Kick", "Snare", "HiHat", "Bass"]
	for track in range(num_tracks):
		var label = Label.new()
		label.text = track_names[track] if track < track_names.size() else "T%d" % track
		label.custom_minimum_size = Vector2(60, 30)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Use track color for labels
		label.add_theme_color_override("font_color", TRACK_COLORS[track % TRACK_COLORS.size()].darkened(0.2))
		label.add_theme_font_size_override("font_size", 14)
		labels_vbox.add_child(label)

	# Button grid
	_grid_container = GridContainer.new()
	_grid_container.name = "ButtonGrid"
	_grid_container.columns = num_steps
	_grid_container.add_theme_constant_override("h_separation", 2)
	_grid_container.add_theme_constant_override("v_separation", 2)
	grid_hbox.add_child(_grid_container)

	_buttons.clear()
	for track in range(num_tracks):
		var track_buttons: Array[Button] = []
		for step in range(num_steps):
			var btn = Button.new()
			btn.name = "Cell_%d_%d" % [track, step]
			btn.custom_minimum_size = Vector2(28, 30)
			btn.toggle_mode = true
			# Note: flat = false to allow StyleBoxFlat rendering

			# Style - Light theme: white inactive, colored when active
			var track_color = TRACK_COLORS[track % TRACK_COLORS.size()]

			# Normal (inactive) - white with subtle border
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.98, 0.98, 1.0)  # White
			style_normal.corner_radius_top_left = 2
			style_normal.corner_radius_top_right = 2
			style_normal.corner_radius_bottom_left = 2
			style_normal.corner_radius_bottom_right = 2
			style_normal.border_width_left = 1
			style_normal.border_width_right = 1
			style_normal.border_width_top = 1
			style_normal.border_width_bottom = 1
			style_normal.border_color = Color(0.7, 0.7, 0.72)
			btn.add_theme_stylebox_override("normal", style_normal)

			# Pressed (active/toggled ON) - track color
			var style_pressed = StyleBoxFlat.new()
			style_pressed.bg_color = track_color
			style_pressed.corner_radius_top_left = 2
			style_pressed.corner_radius_top_right = 2
			style_pressed.corner_radius_bottom_left = 2
			style_pressed.corner_radius_bottom_right = 2
			style_pressed.border_width_left = 1
			style_pressed.border_width_right = 1
			style_pressed.border_width_top = 1
			style_pressed.border_width_bottom = 1
			style_pressed.border_color = track_color.darkened(0.2)
			btn.add_theme_stylebox_override("pressed", style_pressed)

			# Hover (over inactive cell) - subtle gray highlight
			var style_hover = StyleBoxFlat.new()
			style_hover.bg_color = Color(0.9, 0.9, 0.92)
			style_hover.corner_radius_top_left = 2
			style_hover.corner_radius_top_right = 2
			style_hover.corner_radius_bottom_left = 2
			style_hover.corner_radius_bottom_right = 2
			style_hover.border_width_left = 1
			style_hover.border_width_right = 1
			style_hover.border_width_top = 1
			style_hover.border_width_bottom = 1
			style_hover.border_color = Color(0.6, 0.6, 0.62)
			btn.add_theme_stylebox_override("hover", style_hover)

			# Hover pressed (over active/toggled ON cell) - brighter track color
			var style_hover_pressed = StyleBoxFlat.new()
			style_hover_pressed.bg_color = track_color.lightened(0.15)
			style_hover_pressed.corner_radius_top_left = 2
			style_hover_pressed.corner_radius_top_right = 2
			style_hover_pressed.corner_radius_bottom_left = 2
			style_hover_pressed.corner_radius_bottom_right = 2
			style_hover_pressed.border_width_left = 1
			style_hover_pressed.border_width_right = 1
			style_hover_pressed.border_width_top = 1
			style_hover_pressed.border_width_bottom = 1
			style_hover_pressed.border_color = track_color
			btn.add_theme_stylebox_override("hover_pressed", style_hover_pressed)

			btn.toggled.connect(_on_cell_toggled.bind(track, step))
			_grid_container.add_child(btn)
			track_buttons.append(btn)
		_buttons.append(track_buttons)


func _on_cell_toggled(button_pressed: bool, track: int, step: int) -> void:
	_grid_data[track][step] = button_pressed
	cell_toggled.emit(track, step, button_pressed)


func _on_play_pressed() -> void:
	_is_playing = not _is_playing
	_play_button.text = "⏹ Stop" if _is_playing else "▶ Play"
	_update_play_button_style()
	playback_toggled.emit(_is_playing)
	_update_step_label()


func _update_play_button_style() -> void:
	# Light theme: green when playing, light when stopped
	var bg_color = Color(0.3, 0.7, 0.4) if _is_playing else Color(0.95, 0.95, 0.97)
	var border_color = Color(0.2, 0.5, 0.3) if _is_playing else Color(0.7, 0.7, 0.72)
	var text_color = Color(1.0, 1.0, 1.0) if _is_playing else Color(0.2, 0.2, 0.25)

	var style_normal = _play_button.get_theme_stylebox("normal") as StyleBoxFlat
	if style_normal:
		style_normal.bg_color = bg_color
		style_normal.border_color = border_color

	_play_button.add_theme_color_override("font_color", text_color)


func _on_bpm_changed(value: float) -> void:
	bpm = value
	_bpm_label.text = "BPM: %d" % int(bpm)
	bpm_changed.emit(bpm)


func _on_preset_selected(index: int) -> void:
	sound_preset = SOUND_PRESETS[index]
	preset_changed.emit(sound_preset)


func _on_pattern_selected(index: int) -> void:
	var pattern_name = PATTERN_PRESETS[index]
	pattern_preset_changed.emit(pattern_name)


func _update_step_label() -> void:
	if _step_label:
		var status = "Playing" if _is_playing else "Stopped"
		_step_label.text = "Step %d/%d | %s" % [_playhead_position + 1, num_steps, status]


## Called by parent to update playhead position
func set_playhead(step: int) -> void:
	# Clear previous
	if _playhead_position < _playhead_indicators.size():
		var prev_style = _playhead_indicators[_playhead_position].get_theme_stylebox("panel") as StyleBoxFlat
		if prev_style:
			prev_style.bg_color = Color(0.75, 0.75, 0.78)  # Light gray inactive

	_playhead_position = step % num_steps

	# Highlight current - TE orange
	if _playhead_position < _playhead_indicators.size():
		var curr_style = _playhead_indicators[_playhead_position].get_theme_stylebox("panel") as StyleBoxFlat
		if curr_style:
			curr_style.bg_color = Color(0.3, 0.7, 0.4)  # Green active

	_update_step_label()


## Get cell state
func get_cell(track: int, step: int) -> bool:
	if track < 0 or track >= num_tracks:
		return false
	if step < 0 or step >= num_steps:
		return false
	return _grid_data[track][step]


## Set cell state
func set_cell(track: int, step: int, active: bool) -> void:
	if track < 0 or track >= num_tracks:
		return
	if step < 0 or step >= num_steps:
		return
	_grid_data[track][step] = active
	if track < _buttons.size() and step < _buttons[track].size():
		_buttons[track][step].button_pressed = active


## Get all active cells for a step
func get_active_tracks(step: int) -> Array[int]:
	var active: Array[int] = []
	for track in range(num_tracks):
		if get_cell(track, step):
			active.append(track)
	return active


## Clear all cells
func clear_pattern() -> void:
	for track in range(num_tracks):
		for step in range(num_steps):
			set_cell(track, step, false)


## Check if playing
func is_playing() -> bool:
	return _is_playing


## Set playing state (from external control)
func set_playing(playing: bool) -> void:
	_is_playing = playing
	_play_button.text = "⏹ Stop" if _is_playing else "▶ Play"
	_update_step_label()
