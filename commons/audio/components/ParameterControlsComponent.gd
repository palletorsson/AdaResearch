# ParameterControlsComponent.gd
# Modular component for sound parameter controls
# Handles sliders, options, and real-time parameter updates

extends Control

class_name ParameterControlsComponent

@export_group("Layout")
@export var column_count: int = 3
@export var compact_mode: bool = true
@export var show_value_labels: bool = true

# UI References
var parameters_container: VBoxContainer
var columns_container: HBoxContainer
var columns: Array[VBoxContainer] = []

# Control references
var parameter_controls: Dictionary = {}
var value_labels: Dictionary = {}

# Current parameters data
var current_parameters: Dictionary = {}
var current_sound_key: String = ""

# Signals
signal parameter_changed(param_name: String, value)
signal parameters_updated(sound_key: String, parameters: Dictionary)

func _ready():
	_setup_ui()

func _setup_ui():
	"""Setup the parameter controls UI"""
	# Main parameters container
	parameters_container = VBoxContainer.new()
	parameters_container.name = "ParametersContainer"
	parameters_container.add_theme_constant_override("separation", 12)
	parameters_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(parameters_container)

	# Title
	if not compact_mode:
		var title = Label.new()
		title.text = "🎛️ Parameters"
		title.add_theme_font_size_override("font_size", 14)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_color_override("font_color", Color.WHITE)
		parameters_container.add_child(title)

	# Columns container
	columns_container = HBoxContainer.new()
	columns_container.add_theme_constant_override("separation", 15)
	columns_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters_container.add_child(columns_container)

	# Create columns
	_create_columns()

func _create_columns():
	"""Create the parameter columns"""
	columns.clear()

	# Clear existing columns
	for child in columns_container.get_children():
		child.queue_free()

	# Create new columns
	for i in range(column_count):
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 8)
		columns_container.add_child(column)
		columns.append(column)

func create_parameter_controls(sound_key: String, parameters: Dictionary):
	"""Create parameter controls for a sound type"""
	print("🎛️ Creating parameter controls for: %s" % sound_key)
	print("📊 Parameters received: %s" % str(parameters))

	current_sound_key = sound_key
	current_parameters = parameters.duplicate()

	# Clear existing controls
	_clear_controls()

	# Distribute parameters across columns
	var param_names = parameters.keys()
	#print("🔧 Creating controls for parameters: %s" % str(param_names))

	for i in range(param_names.size()):
		var param_name = param_names[i]
		var param_config = parameters[param_name]
		var column_index = i % column_count
		print("🎚️ Creating control for %s: %s" % [param_name, str(param_config)])
		_create_parameter_control_in_column(columns[column_index], param_name, param_config)

	print("✅ ParameterControlsComponent: Created %d parameter controls for %s" % [param_names.size(), sound_key])

func _clear_controls():
	"""Clear all existing parameter controls"""
	for column in columns:
		for child in column.get_children():
			child.queue_free()

	parameter_controls.clear()
	value_labels.clear()

func _create_parameter_control_in_column(column: VBoxContainer, param_name: String, param_config: Dictionary):
	"""Create a parameter control in the specified column"""
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 3)

	# Add background to parameter group
	var param_bg = StyleBoxFlat.new()
	param_bg.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	param_bg.corner_radius_top_left = 4
	param_bg.corner_radius_top_right = 4
	param_bg.corner_radius_bottom_left = 4
	param_bg.corner_radius_bottom_right = 4
	param_bg.content_margin_left = 8
	param_bg.content_margin_right = 8
	param_bg.content_margin_top = 6
	param_bg.content_margin_bottom = 6
	main_container.add_theme_stylebox_override("panel", param_bg)

	column.add_child(main_container)

	# Header with name and value
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 2)
	main_container.add_child(header_container)

	# Parameter label
	var label = Label.new()
	label.text = _format_parameter_name(param_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.WHITE)
	header_container.add_child(label)

	# Value label
	if show_value_labels:
		var value_label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.add_theme_color_override("font_color", Color.CYAN)
		header_container.add_child(value_label)
		value_labels[param_name] = value_label
		value_label.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_request_exact_value(param_name)
		)


	# Control container
	var control_container = VBoxContainer.new()
	main_container.add_child(control_container)

	# Parameter control based on type
	if param_config.has("options"):
		_create_option_control(control_container, param_name, param_config)
	else:
		_create_slider_control(control_container, param_name, param_config)

func _create_slider_control(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create a slider control for numeric parameters"""
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("value", 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 20)

	# Style the slider
	_style_slider(slider)

	# Connect signal
	slider.value_changed.connect(func(value): _on_slider_changed(value, param_name))
	print("🔌 Connected slider signal for %s (value: %s)" % [param_name, slider.value])

	container.add_child(slider)
	parameter_controls[param_name] = slider

	# Update value label
	if show_value_labels:
		_update_value_label(param_name, slider.value)

func _create_option_control(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create an option control for enumerated parameters"""
	var option_button = OptionButton.new()
	var options = config.get("options", [])
	var current_value = config.get("value", "")

	option_button.custom_minimum_size = Vector2(150, 25)

	for option in options:
		option_button.add_item(option)

	# Select current value
	for i in range(option_button.get_item_count()):
		if option_button.get_item_text(i) == current_value:
			option_button.selected = i
			break

	# Style the option button
	_style_option_button(option_button)

	# Connect signal
	option_button.item_selected.connect(func(index): _on_option_changed(index, param_name))

	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(option_button)
	parameter_controls[param_name] = option_button

	# Update value label
	if show_value_labels:
		_update_value_label(param_name, current_value)

func _style_slider(slider: HSlider):
	"""Apply consistent styling to sliders"""
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_style.corner_radius_top_left = 3
	slider_style.corner_radius_top_right = 3
	slider_style.corner_radius_bottom_left = 3
	slider_style.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", slider_style)

	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.8, 1.0, 1.0)
	grabber_style.corner_radius_top_left = 6
	grabber_style.corner_radius_top_right = 6
	grabber_style.corner_radius_bottom_left = 6
	grabber_style.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_area", grabber_style)

func _style_option_button(option_button: OptionButton):
	"""Apply consistent styling to option buttons"""
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.25, 0.25, 0.35, 1.0)
	button_style.corner_radius_top_left = 4
	button_style.corner_radius_top_right = 4
	button_style.corner_radius_bottom_left = 4
	button_style.corner_radius_bottom_right = 4
	option_button.add_theme_stylebox_override("normal", button_style)

func _format_parameter_name(param_name: String) -> String:
	"""Format parameter name for display"""
	return param_name.capitalize().replace("_", " ")

func _update_value_label(param_name: String, value):
	"""Update the value label for a parameter"""
	if not show_value_labels or not value_labels.has(param_name):
		return

	var label = value_labels[param_name]
	if value is float:
		label.text = "%.2f" % value
	else:
		label.text = str(value)

func _on_slider_changed(arg1: Variant, arg2: Variant = null) -> void:
	var param_name: String
	var value: float
	if arg1 is String:
		param_name = arg1
		value = float(arg2)
	else:
		value = float(arg1)
		param_name = String(arg2)
	print("🎚️ ParameterControls: Slider changed - %s = %s" % [param_name, value])
	if current_parameters.has(param_name) and current_parameters[param_name] is Dictionary:
		current_parameters[param_name]["value"] = value
	else:
		current_parameters[param_name] = value
	if show_value_labels:
		_update_value_label(param_name, value)
	parameter_changed.emit(param_name, value)
	parameters_updated.emit(current_sound_key, get_current_parameter_values())

func _on_option_changed(arg1: Variant, arg2: Variant = null) -> void:
	var index: int
	var param_name: String
	if arg1 is String:
		param_name = arg1
		index = int(arg2)
	else:
		index = int(arg1)
		param_name = String(arg2)
	var option_button = parameter_controls[param_name] as OptionButton
	var value = option_button.get_item_text(index)
	if current_parameters.has(param_name) and current_parameters[param_name] is Dictionary:
		current_parameters[param_name]["value"] = value
	if show_value_labels:
		_update_value_label(param_name, value)
	parameter_changed.emit(param_name, value)
	parameters_updated.emit(current_sound_key, get_current_parameter_values())

func get_current_parameter_values() -> Dictionary:
	"""Get current parameter values as a simple dictionary"""
	var values = {}
	for param_name in current_parameters.keys():
		if current_parameters[param_name] is Dictionary and current_parameters[param_name].has("value"):
			values[param_name] = current_parameters[param_name]["value"]
		else:
			# Fallback: use the whole value if it's not a dictionary structure
			values[param_name] = current_parameters[param_name]
	return values

func set_parameter_value(param_name: String, value):
	"""Set a parameter value programmatically"""
	if not current_parameters.has(param_name):
		return

	# Update internal data
	if current_parameters[param_name] is Dictionary:
		current_parameters[param_name]["value"] = value
	else:
		current_parameters[param_name] = value

	# Update UI control
	if parameter_controls.has(param_name):
		var control = parameter_controls[param_name]
		if control is HSlider:
			control.value = value
		elif control is OptionButton:
			# Find the option index
			for i in range(control.get_item_count()):
				if control.get_item_text(i) == str(value):
					control.selected = i
					break

	# Update value label
	if show_value_labels:
		_update_value_label(param_name, value)

func apply_parameter_preset(preset: Dictionary):
	"""Apply a preset of parameter values"""
	for param_name in preset.keys():
		set_parameter_value(param_name, preset[param_name])

	# Emit update signal
	parameters_updated.emit(current_sound_key, get_current_parameter_values())

func get_parameter_control(param_name: String) -> Control:
	"""Get a specific parameter control"""
	return parameter_controls.get(param_name)

func set_column_count(count: int):
	"""Change the number of columns"""
	if count != column_count and count > 0:
		column_count = count
		_create_columns()
		if current_parameters.size() > 0:
			create_parameter_controls(current_sound_key, current_parameters)

func set_compact_mode(enabled: bool):
	"""Enable/disable compact mode"""
	compact_mode = enabled
	# Recreate UI to apply changes
	_setup_ui()
	if current_parameters.size() > 0:
		create_parameter_controls(current_sound_key, current_parameters)

func enable_value_labels(enabled: bool):
	"""Enable/disable value labels"""
	show_value_labels = enabled
	# Update visibility of existing labels
	for label in value_labels.values():
		if label:
			label.visible = enabled



func _request_exact_value(param_name: String) -> void:
	if not parameter_controls.has(param_name):
		return
	var control = parameter_controls[param_name]
	var min_value = 0.0
	var max_value = 1.0
	var step_value = 0.01
	var current_value = 0.0
	if control is HSlider:
		min_value = control.min_value
		max_value = control.max_value
		step_value = control.step
		current_value = control.value
	elif current_parameters.has(param_name) and current_parameters[param_name] is Dictionary:
		var cfg = current_parameters[param_name]
		min_value = cfg.get("min", min_value)
		max_value = cfg.get("max", max_value)
		step_value = cfg.get("step", step_value)
		current_value = cfg.get("value", current_value)
	else:
		current_value = float(current_parameters.get(param_name, 0.0))
	var dialog = Window.new()
	dialog.title = "Set %s" % _format_parameter_name(param_name)
	dialog.min_size = Vector2(260, 140)
	add_child(dialog)
	var background = MarginContainer.new()
	background.add_theme_constant_override("margin_left", 12)
	background.add_theme_constant_override("margin_top", 12)
	background.add_theme_constant_override("margin_right", 12)
	background.add_theme_constant_override("margin_bottom", 12)
	dialog.add_child(background)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	background.add_child(content)
	var input_line = SpinBox.new()
	input_line.min_value = min_value
	input_line.max_value = max_value
	input_line.step = max(step_value, 0.0001)
	input_line.value = current_value
	input_line.allow_greater = false
	input_line.allow_lesser = false
	content.add_child(input_line)
	var line_edit = input_line.get_line_edit()

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(button_row)
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	button_row.add_child(cancel_button)
	var apply_button = Button.new()
	apply_button.text = "Apply"
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(apply_button)
	var close_dialog := func():
		dialog.queue_free()
	cancel_button.pressed.connect(close_dialog)
	var apply_value := func():
		var parsed: float = clamp(input_line.value, min_value, max_value)
		if step_value > 0.0:
			parsed = round(parsed / step_value) * step_value
		set_parameter_value(param_name, parsed)
		close_dialog.call()
	apply_button.pressed.connect(apply_value)
	input_line.value_changed.connect(func(value: float):
		var parsed: float = clamp(value, min_value, max_value)
		if step_value > 0.0:
			parsed = round(parsed / step_value) * step_value
		if not is_equal_approx(parsed, input_line.value):
			input_line.value = parsed
	)
	if line_edit:
		line_edit.text_submitted.connect(func(text: String):
			var submitted: String = text.strip_edges()
			if submitted.is_empty():
				submitted = str(input_line.value)
			var parsed_text: float = submitted.to_float()
			input_line.value = parsed_text
			apply_value.call()
		)
	dialog.close_requested.connect(close_dialog)
	input_line.grab_focus()
	dialog.popup_centered()
