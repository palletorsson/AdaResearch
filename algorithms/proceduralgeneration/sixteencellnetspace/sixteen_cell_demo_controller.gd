class_name SixteenCellDemoController
extends Node3D

# UI References
@onready var net_space: SixteenCellNetSpace = $SixteenCellNetSpace
@onready var camera: Camera3D = $Camera3D

# UI Controls
@onready var net_pattern_option: OptionButton = $UI/Control/Panel/VBoxContainer/NetPatternOption
@onready var space_size_x_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeXSlider
@onready var space_size_y_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeYSlider
@onready var space_size_z_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpaceSizeZSlider
@onready var tetrahedron_size_slider: HSlider = $UI/Control/Panel/VBoxContainer/TetrahedronSizeSlider
@onready var spacing_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpacingSlider
@onready var hollow_center_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/HollowCenterCheckBox
@onready var hollow_radius_slider: HSlider = $UI/Control/Panel/VBoxContainer/HollowRadiusSlider
@onready var rotation_variety_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/RotationVarietyCheckBox
@onready var offset_pattern_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/OffsetPatternCheckBox
@onready var spiral_arrangement_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/SpiralArrangementCheckBox
@onready var base_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/BaseColorPicker
@onready var rainbow_gradient_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/RainbowGradientCheckBox
@onready var emission_slider: HSlider = $UI/Control/Panel/VBoxContainer/EmissionSlider
@onready var show_edges_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/ShowEdgesCheckBox
@onready var transparency_slider: HSlider = $UI/Control/Panel/VBoxContainer/TransparencySlider
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var randomize_button: Button = $UI/Control/Panel/VBoxContainer/RandomizeButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
var camera_distance: float = 18.0
var camera_angle: float = 0.0
var camera_height: float = 12.0

func _ready():
	# Connect UI signals
	net_pattern_option.item_selected.connect(_on_net_pattern_selected)
	space_size_x_slider.value_changed.connect(_on_space_size_x_changed)
	space_size_y_slider.value_changed.connect(_on_space_size_y_changed)
	space_size_z_slider.value_changed.connect(_on_space_size_z_changed)
	tetrahedron_size_slider.value_changed.connect(_on_tetrahedron_size_changed)
	spacing_slider.value_changed.connect(_on_spacing_changed)
	hollow_center_checkbox.toggled.connect(_on_hollow_center_toggled)
	hollow_radius_slider.value_changed.connect(_on_hollow_radius_changed)
	rotation_variety_checkbox.toggled.connect(_on_rotation_variety_toggled)
	offset_pattern_checkbox.toggled.connect(_on_offset_pattern_toggled)
	spiral_arrangement_checkbox.toggled.connect(_on_spiral_arrangement_toggled)
	base_color_picker.color_changed.connect(_on_base_color_changed)
	rainbow_gradient_checkbox.toggled.connect(_on_rainbow_gradient_toggled)
	emission_slider.value_changed.connect(_on_emission_changed)
	show_edges_checkbox.toggled.connect(_on_show_edges_toggled)
	transparency_slider.value_changed.connect(_on_transparency_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	
	# Setup UI
	_setup_ui()
	_update_camera()
	_update_stats()

func _setup_ui():
	"""Initialize UI with current net space settings"""
	# Setup net pattern options
	net_pattern_option.clear()
	net_pattern_option.add_item("Octahedral Core")
	net_pattern_option.add_item("Double Pyramid")
	net_pattern_option.add_item("Tetrahedral Star")
	net_pattern_option.add_item("Compact Cluster")
	net_pattern_option.selected = net_space.net_pattern
	
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
	
	tetrahedron_size_slider.min_value = 0.3
	tetrahedron_size_slider.max_value = 2.0
	tetrahedron_size_slider.value = net_space.tetrahedron_size
	tetrahedron_size_slider.step = 0.1
	
	spacing_slider.min_value = 0.0
	spacing_slider.max_value = 1.0
	spacing_slider.value = net_space.spacing
	spacing_slider.step = 0.05
	
	hollow_radius_slider.min_value = 0.5
	hollow_radius_slider.max_value = 5.0
	hollow_radius_slider.value = net_space.hollow_radius
	hollow_radius_slider.step = 0.1
	
	emission_slider.min_value = 0.0
	emission_slider.max_value = 2.0
	emission_slider.value = net_space.emission_strength
	emission_slider.step = 0.1
	
	transparency_slider.min_value = 0.0
	transparency_slider.max_value = 0.8
	transparency_slider.value = net_space.transparency
	transparency_slider.step = 0.05
	
	# Setup checkboxes
	hollow_center_checkbox.button_pressed = net_space.create_hollow_center
	rotation_variety_checkbox.button_pressed = net_space.rotation_variety
	offset_pattern_checkbox.button_pressed = net_space.offset_pattern
	spiral_arrangement_checkbox.button_pressed = net_space.spiral_arrangement
	rainbow_gradient_checkbox.button_pressed = net_space.use_rainbow_gradient
	show_edges_checkbox.button_pressed = net_space.show_edges
	
	# Setup color picker
	base_color_picker.color = net_space.base_color

func _update_camera():
	"""Update camera position for optimal viewing"""
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_net_pattern_selected(index: int):
	net_space.net_pattern = index
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

func _on_tetrahedron_size_changed(value: float):
	net_space.tetrahedron_size = value
	_update_stats()

func _on_spacing_changed(value: float):
	net_space.spacing = value
	_update_stats()

func _on_hollow_center_toggled(pressed: bool):
	net_space.create_hollow_center = pressed
	_update_stats()

func _on_hollow_radius_changed(value: float):
	net_space.hollow_radius = value
	_update_stats()

func _on_rotation_variety_toggled(pressed: bool):
	net_space.rotation_variety = pressed
	_update_stats()

func _on_offset_pattern_toggled(pressed: bool):
	net_space.offset_pattern = pressed
	_update_stats()

func _on_spiral_arrangement_toggled(pressed: bool):
	net_space.spiral_arrangement = pressed
	_update_stats()

func _on_base_color_changed(color: Color):
	net_space.base_color = color
	_update_stats()

func _on_rainbow_gradient_toggled(pressed: bool):
	net_space.use_rainbow_gradient = pressed
	_update_stats()

func _on_emission_changed(value: float):
	net_space.emission_strength = value
	_update_stats()

func _on_show_edges_toggled(pressed: bool):
	net_space.show_edges = pressed
	_update_stats()

func _on_transparency_changed(value: float):
	net_space.transparency = value
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
	var stats = net_space.get_16cell_space_stats()
	stats_label.text = "Nets: " + str(stats["total_nets"]) + "\n"
	stats_label.text += "Tetrahedra: " + str(stats["total_tetrahedra"]) + "\n"
	stats_label.text += "Pattern: " + stats["net_pattern"] + "\n"
	stats_label.text += "Size: " + str(stats["space_size"]) + "\n"
	stats_label.text += "Tetrahedron Size: " + "%.1f" % stats["tetrahedron_size"] + "\n"
	stats_label.text += "Spacing: " + "%.2f" % stats["spacing"] + "\n"
	stats_label.text += "Hollow: " + ("Yes" if stats["hollow_center"] else "No") + "\n"
	stats_label.text += "Rainbow: " + ("Yes" if stats["rainbow_gradient"] else "No")

func _randomize_parameters():
	"""Randomize net space parameters for variety"""
	net_space.net_pattern = randi() % 4
	net_space.space_size = Vector3i(
		randi_range(3, 8),
		randi_range(2, 6),
		randi_range(3, 8)
	)
	net_space.tetrahedron_size = randf_range(0.4, 1.5)
	net_space.spacing = randf_range(0.1, 0.5)
	net_space.create_hollow_center = randf() > 0.3
	net_space.hollow_radius = randf_range(1.0, 4.0)
	net_space.rotation_variety = randf() > 0.2
	net_space.offset_pattern = randf() > 0.2
	net_space.spiral_arrangement = randf() > 0.7
	net_space.use_rainbow_gradient = randf() > 0.5
	net_space.show_edges = randf() > 0.3
	
	# Randomize colors
	var hue1 = randf()
	var hue2 = fmod(hue1 + randf_range(0.2, 0.6), 1.0)
	net_space.base_color = Color.from_hsv(hue1, 0.8, 0.9)
	
	net_space.emission_strength = randf_range(0.1, 1.5)
	net_space.transparency = randf_range(0.1, 0.6)
	
	# Update UI
	_update_ui()
	net_space.regenerate()
	_update_stats()

func _update_ui():
	"""Update UI to reflect current net space settings"""
	if net_pattern_option:
		net_pattern_option.selected = net_space.net_pattern
	if space_size_x_slider:
		space_size_x_slider.value = net_space.space_size.x
	if space_size_y_slider:
		space_size_y_slider.value = net_space.space_size.y
	if space_size_z_slider:
		space_size_z_slider.value = net_space.space_size.z
	if tetrahedron_size_slider:
		tetrahedron_size_slider.value = net_space.tetrahedron_size
	if spacing_slider:
		spacing_slider.value = net_space.spacing
	if hollow_center_checkbox:
		hollow_center_checkbox.button_pressed = net_space.create_hollow_center
	if hollow_radius_slider:
		hollow_radius_slider.value = net_space.hollow_radius
	if rotation_variety_checkbox:
		rotation_variety_checkbox.button_pressed = net_space.rotation_variety
	if offset_pattern_checkbox:
		offset_pattern_checkbox.button_pressed = net_space.offset_pattern
	if spiral_arrangement_checkbox:
		spiral_arrangement_checkbox.button_pressed = net_space.spiral_arrangement
	if base_color_picker:
		base_color_picker.color = net_space.base_color
	if rainbow_gradient_checkbox:
		rainbow_gradient_checkbox.button_pressed = net_space.use_rainbow_gradient
	if emission_slider:
		emission_slider.value = net_space.emission_strength
	if show_edges_checkbox:
		show_edges_checkbox.button_pressed = net_space.show_edges
	if transparency_slider:
		transparency_slider.value = net_space.transparency

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
				# Number keys to switch net patterns
				var net_pattern_index = event.keycode - KEY_1
				net_space.net_pattern = net_pattern_index
				if net_pattern_option:
					net_pattern_option.selected = net_pattern_index
				net_space.regenerate()
				_update_stats()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(8.0, camera_distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(35.0, camera_distance + 1.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to randomize parameters
			_randomize_parameters()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to cycle through net patterns
			var next_net_pattern = (net_space.net_pattern + 1) % 4
			net_space.net_pattern = next_net_pattern
			if net_pattern_option:
				net_pattern_option.selected = next_net_pattern
			net_space.regenerate()
			_update_stats()
	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		# Middle mouse drag to rotate camera
		camera_angle += event.relative.x * 0.01
		camera_height = clamp(camera_height - event.relative.y * 0.1, 3.0, 25.0)
		_update_camera()









