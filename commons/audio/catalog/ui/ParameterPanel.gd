# ParameterPanel.gd
# Dynamic parameter editing panel with sliders
# Used in AudioCatalogUI

extends Control
class_name ParameterPanel

signal parameter_changed(param_name: String, value: float)
signal parameters_updated(all_values: Dictionary)

@export var label_color: Color = Color(0.7, 0.7, 0.8)
@export var value_color: Color = Color(0.2, 0.85, 1.0)
@export var slider_color: Color = Color(0.3, 0.3, 0.4)
@export var grabber_color: Color = Color(0.2, 0.85, 1.0)
@export var max_visible_params: int = 8

var _scroll_container: ScrollContainer
var _params_container: VBoxContainer
var _sliders: Dictionary = {}  # param_name -> {slider: HSlider, label: Label}
var _current_values: Dictionary = {}


func _ready():
	_setup_ui()


func _setup_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	_params_container = VBoxContainer.new()
	_params_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_params_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_params_container.add_theme_constant_override("separation", 8)
	_scroll_container.add_child(_params_container)


func build_controls(parameters: Dictionary) -> void:
	# Clear existing
	for child in _params_container.get_children():
		child.queue_free()
	_sliders.clear()
	_current_values.clear()

	if parameters.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No parameters"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_params_container.add_child(empty_label)
		return

	# Sort parameters by name
	var param_names: Array[String] = []
	for key in parameters.keys():
		param_names.append(str(key))
	param_names.sort()

	# Build slider for each numeric parameter
	var count := 0
	for param_name: String in param_names:
		if count >= max_visible_params:
			break

		var raw_value: Variant = parameters[param_name]

		if raw_value is Dictionary:
			var config: Dictionary = raw_value

			# Skip non-numeric parameters
			if not config.has("min") or not config.has("max"):
				# Check for options (dropdown)
				if config.has("options"):
					_add_option_control(param_name, config)
					count += 1
				continue

			_add_slider(param_name, config)
			count += 1
		elif raw_value is int or raw_value is float:
			var inferred := _infer_numeric_config(param_name, float(raw_value))
			_add_slider(param_name, inferred)
			count += 1
		else:
			# Unsupported parameter format (string, array, etc.)
			continue


func _infer_numeric_config(param_name: String, value: float) -> Dictionary:
	var name: String = param_name.to_lower()
	var min_val: float = 0.0
	var max_val: float = max(1.0, value * 2.0)
	var step_val: float = max(0.01, (max_val - min_val) / 100.0)

	if name.contains("freq"):
		min_val = max(0.0, value * 0.5)
		max_val = max(200.0, value * 4.0)
		step_val = 1.0
	elif name.contains("duration"):
		min_val = 0.1
		max_val = max(10.0, value * 2.0)
		step_val = 0.1
	elif name.contains("attack") or name.contains("decay") or name.contains("release"):
		min_val = 0.0
		max_val = max(5.0, value * 2.0)
		step_val = 0.01
	elif name.contains("rate"):
		min_val = 0.0
		max_val = max(10.0, value * 2.0)
		step_val = 0.01
	elif name.contains("depth") or name.contains("amount") or name.contains("mix"):
		min_val = 0.0
		max_val = 1.0
		step_val = 0.01

	return {
		"value": value,
		"min": min_val,
		"max": max_val,
		"step": step_val
	}


func _add_slider(param_name: String, config: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_theme_constant_override("separation", 4)

	# Label row
	var label_hbox := HBoxContainer.new()
	label_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_child(label_hbox)

	var name_label := Label.new()
	name_label.text = _format_param_name(param_name)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", label_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_hbox.add_child(name_label)

	var value_label := Label.new()
	value_label.text = _format_value(config.get("value", config.get("min", 0)))
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", value_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 120
	label_hbox.add_child(value_label)

	# Slider
	var slider := HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", (slider.max_value - slider.min_value) / 100.0)
	slider.value = config.get("value", slider.min_value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 40)

	# Style slider
	var slider_style := StyleBoxFlat.new()
	slider_style.bg_color = slider_color
	slider_style.corner_radius_top_left = 2
	slider_style.corner_radius_top_right = 2
	slider_style.corner_radius_bottom_left = 2
	slider_style.corner_radius_bottom_right = 2
	slider.add_theme_stylebox_override("slider", slider_style)

	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = grabber_color
	grabber_style.corner_radius_top_left = 4
	grabber_style.corner_radius_top_right = 4
	grabber_style.corner_radius_bottom_left = 4
	grabber_style.corner_radius_bottom_right = 4
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_style)

	slider.value_changed.connect(_on_slider_changed.bind(param_name, value_label))
	container.add_child(slider)

	_params_container.add_child(container)
	_sliders[param_name] = {"slider": slider, "label": value_label}
	_current_values[param_name] = slider.value


func _add_option_control(param_name: String, config: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = _format_param_name(param_name)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", label_color)
	container.add_child(name_label)

	var option_btn := OptionButton.new()
	var options: Array = config.get("options", [])
	var current_value = config.get("value", options[0] if options.size() > 0 else "")

	for i in range(options.size()):
		option_btn.add_item(str(options[i]))
		if str(options[i]) == str(current_value):
			option_btn.select(i)

	option_btn.item_selected.connect(_on_option_changed.bind(param_name, options))

	# Style
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = slider_color
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	option_btn.add_theme_stylebox_override("normal", btn_style)

	container.add_child(option_btn)
	_params_container.add_child(container)
	_current_values[param_name] = current_value


func _format_param_name(name: String) -> String:
	return name.replace("_", " ").capitalize()


func _format_value(value) -> String:
	if value is float:
		if abs(value) >= 100:
			return "%.0f" % value
		elif abs(value) >= 10:
			return "%.1f" % value
		else:
			return "%.2f" % value
	return str(value)


func _on_slider_changed(value: float, param_name: String, value_label: Label) -> void:
	value_label.text = _format_value(value)
	_current_values[param_name] = value
	parameter_changed.emit(param_name, value)
	parameters_updated.emit(_current_values.duplicate())


func _on_option_changed(index: int, param_name: String, options: Array) -> void:
	if index >= 0 and index < options.size():
		var value = options[index]
		_current_values[param_name] = value
		parameter_changed.emit(param_name, value)
		parameters_updated.emit(_current_values.duplicate())


func get_current_values() -> Dictionary:
	return _current_values.duplicate()


func set_parameter_value(param_name: String, value: float) -> void:
	if _sliders.has(param_name):
		var slider_data: Dictionary = _sliders[param_name]
		slider_data.slider.value = value
		slider_data.label.text = _format_value(value)
		_current_values[param_name] = value
