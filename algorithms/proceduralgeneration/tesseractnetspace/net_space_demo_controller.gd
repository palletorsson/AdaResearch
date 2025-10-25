class_name NetSpaceDemoController
extends Node3D

# UI References
@onready var net_space: TesseractNetSpace = $TesseractNetSpace
@onready var camera: Camera3D = $Camera3D

# UI Controls
@onready var net_type_option: OptionButton = $UI/Control/Panel/VBoxContainer/NetTypeOption
@onready var space_size_x_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeXSlider
@onready var space_size_y_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeYSlider
@onready var space_size_z_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeZSlider
@onready var cube_size_slider: HSlider = $UI/Control/Panel/VBoxContainer/CubeSizeSlider
@onready var spacing_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpacingSlider
@onready var hollow_center_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/HollowCenterCheckBox
@onready var rotation_variety_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/RotationVarietyCheckBox
@onready var offset_pattern_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/OffsetPatternCheckBox
@onready var base_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/BaseColorPicker
@onready var color_variation_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/ColorVariationCheckBox
@onready var emission_slider: HSlider = $UI/Control/Panel/VBoxContainer/EmissionSlider
@onready var wireframe_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/WireframeCheckBox
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var randomize_button: Button = $UI/Control/Panel/VBoxContainer/RandomizeButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
var camera_distance: float = 15.0
var camera_angle: float = 0.0
var camera_height: float = 10.0

func _ready():
	# Connect UI signals
	net_type_option.item_selected.connect(_on_net_type_selected)
	space_size_x_slider.value_changed.connect(_on_space_size_x_changed)
	space_size_y_slider.value_changed.connect(_on_space_size_y_changed)
	space_size_z_slider.value_changed.connect(_on_space_size_z_changed)
	cube_size_slider.value_changed.connect(_on_cube_size_changed)
	spacing_slider.value_changed.connect(_on_spacing_changed)
	hollow_center_checkbox.toggled.connect(_on_hollow_center_toggled)
	rotation_variety_checkbox.toggled.connect(_on_rotation_variety_toggled)
	offset_pattern_checkbox.toggled.connect(_on_offset_pattern_toggled)
	base_color_picker.color_changed.connect(_on_base_color_changed)
	color_variation_checkbox.toggled.connect(_on_color_variation_toggled)
	emission_slider.value_changed.connect(_on_emission_changed)
	wireframe_checkbox.toggled.connect(_on_wireframe_toggled)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	
	# Setup UI
	_setup_ui()
	_update_camera()
	_update_stats()

func _setup_ui():
	"""Initialize UI with current net space settings"""
	# Setup net type options
	net_type_option.clear()
	net_type_option.add_item("Dali Cross")
	net_type_option.add_item("Linear Chain")
	net_type_option.add_item("Folded Chain")
	net_type_option.add_item("Double Cross")
	net_type_option.selected = net_space.net_type
	
	# Setup sliders
	space_size_x_slider.min_value = 1
	space_size_x_slider.max_value = 10
	space_size_x_slider.value = net_space.space_size.x
	space_size_x_slider.step = 1
	
	space_size_y_slider.min_value = 1
	space_size_y_slider.max_value = 8
	space_size_y_slider.value = net_space.space_size.y
	space_size_y_slider.step = 1
	
	space_size_z_slider.min_value = 1
	space_size_z_slider.max_value = 10
	space_size_z_slider.value = net_space.space_size.z
	space_size_z_slider.step = 1
	
	cube_size_slider.min_value = 0.2
	cube_size_slider.max_value = 2.0
	cube_size_slider.value = net_space.cube_size
	cube_size_slider.step = 0.1
	
	spacing_slider.min_value = 0.0
	spacing_slider.max_value = 1.0
	spacing_slider.value = net_space.spacing
	spacing_slider.step = 0.05
	
	emission_slider.min_value = 0.0
	emission_slider.max_value = 2.0
	emission_slider.value = net_space.emission_strength
	emission_slider.step = 0.1
	
	# Setup checkboxes
	hollow_center_checkbox.button_pressed = net_space.create_hollow_center
	rotation_variety_checkbox.button_pressed = net_space.rotation_variety
	offset_pattern_checkbox.button_pressed = net_space.offset_pattern
	color_variation_checkbox.button_pressed = net_space.color_variation
	wireframe_checkbox.button_pressed = net_space.show_wireframe
	
	# Setup color picker
	base_color_picker.color = net_space.base_color

func _update_camera():
	"""Update camera position for optimal viewing"""
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_net_type_selected(index: int):
	net_space.net_type = index
	_update_stats()

func _on_space_size_x_changed(value: float):
	net_space.space_size.x = int(value)
	_update_stats()

func _on_space_size_y_changed(value: float):
	net_space.space_size.y = int(value)
	_update_stats()

func _on_space_size_z_changed(value: float):
	net_space.space_size.z = int(value)
	_update_stats()

func _on_cube_size_changed(value: float):
	net_space.cube_size = value
	_update_stats()

func _on_spacing_changed(value: float):
	net_space.spacing = value
	_update_stats()

func _on_hollow_center_toggled(pressed: bool):
	net_space.create_hollow_center = pressed
	_update_stats()

func _on_rotation_variety_toggled(pressed: bool):
	net_space.rotation_variety = pressed
	_update_stats()

func _on_offset_pattern_toggled(pressed: bool):
	net_space.offset_pattern = pressed
	_update_stats()

func _on_base_color_changed(color: Color):
	net_space.base_color = color
	_update_stats()

func _on_color_variation_toggled(pressed: bool):
	net_space.color_variation = pressed
	_update_stats()

func _on_emission_changed(value: float):
	net_space.emission_strength = value
	_update_stats()

func _on_wireframe_toggled(pressed: bool):
	net_space.show_wireframe = pressed
	_update_stats()

func _on_regenerate_pressed():
	net_space.regenerate()
	_update_stats()

func _on_randomize_pressed():
	_randomize_parameters()

func _update_stats():
	"""Update statistics display"""
	if not stats_label:
		return
	var stats = net_space.get_net_space_stats()
	stats_label.text = "Nets: " + str(stats["total_nets"]) + "\n"
	stats_label.text += "Cubes: " + str(stats["total_cubes"]) + "\n"
	stats_label.text += "Type: " + stats["net_type"] + "\n"
	stats_label.text += "Size: " + str(stats["space_size"]) + "\n"
	stats_label.text += "Cube Size: " + "%.1f" % stats["cube_size"] + "\n"
	stats_label.text += "Spacing: " + "%.2f" % stats["spacing"] + "\n"
	stats_label.text += "Hollow: " + ("Yes" if stats["hollow_center"] else "No")

func _randomize_parameters():
	"""Randomize net space parameters for variety"""
	net_space.net_type = randi() % 4
	net_space.space_size = Vector3i(
		randi_range(3, 8),
		randi_range(2, 6),
		randi_range(3, 8)
	)
	net_space.cube_size = randf_range(0.5, 1.5)
	net_space.spacing = randf_range(0.05, 0.3)
	net_space.create_hollow_center = randf() > 0.3
	net_space.rotation_variety = randf() > 0.2
	net_space.offset_pattern = randf() > 0.2
	net_space.color_variation = randf() > 0.1
	net_space.show_wireframe = randf() > 0.5
	
	# Randomize colors
	var hue1 = randf()
	var hue2 = fmod(hue1 + randf_range(0.2, 0.6), 1.0)
	net_space.base_color = Color.from_hsv(hue1, 0.8, 0.9)
	
	net_space.emission_strength = randf_range(0.1, 1.0)
	
	# Update UI
	_update_ui()
	net_space.regenerate()
	_update_stats()

func _update_ui():
	"""Update UI to reflect current net space settings"""
	if net_type_option:
		net_type_option.selected = net_space.net_type
	if space_size_x_slider:
		space_size_x_slider.value = net_space.space_size.x
	if space_size_y_slider:
		space_size_y_slider.value = net_space.space_size.y
	if space_size_z_slider:
		space_size_z_slider.value = net_space.space_size.z
	if cube_size_slider:
		cube_size_slider.value = net_space.cube_size
	if spacing_slider:
		spacing_slider.value = net_space.spacing
	if hollow_center_checkbox:
		hollow_center_checkbox.button_pressed = net_space.create_hollow_center
	if rotation_variety_checkbox:
		rotation_variety_checkbox.button_pressed = net_space.rotation_variety
	if offset_pattern_checkbox:
		offset_pattern_checkbox.button_pressed = net_space.offset_pattern
	if base_color_picker:
		base_color_picker.color = net_space.base_color
	if color_variation_checkbox:
		color_variation_checkbox.button_pressed = net_space.color_variation
	if emission_slider:
		emission_slider.value = net_space.emission_strength
	if wireframe_checkbox:
		wireframe_checkbox.button_pressed = net_space.show_wireframe

func _input(event):
	"""Handle input for camera control and interactions"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# R key to regenerate
				net_space.regenerate()
				_update_stats()
			KEY_SPACE:
				# Space to randomize
				_randomize_parameters()
			KEY_1, KEY_2, KEY_3, KEY_4:
				# Number keys to switch net types
				var net_type_index = event.keycode - KEY_1
				net_space.net_type = net_type_index
				if net_type_option:
					net_type_option.selected = net_type_index
				net_space.regenerate()
				_update_stats()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(30.0, camera_distance + 1.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to randomize parameters
			_randomize_parameters()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to cycle through net types
			var next_net_type = (net_space.net_type + 1) % 4
			net_space.net_type = next_net_type
			if net_type_option:
				net_type_option.selected = next_net_type
			net_space.regenerate()
			_update_stats()
	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		# Middle mouse drag to rotate camera
		camera_angle += event.relative.x * 0.01
		camera_height = clamp(camera_height - event.relative.y * 0.1, 2.0, 20.0)
		_update_camera()









