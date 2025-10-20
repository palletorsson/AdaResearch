extends Node3D

# UI References
@onready var tunnel: TesseractTunnel = $TesseractTunnel
@onready var projection_label: Label = $UI/Control/Panel/VBoxContainer/ProjectionLabel
@onready var projection_option: OptionButton = $UI/Control/Panel/VBoxContainer/ProjectionOption
@onready var radius_label: Label = $UI/Control/Panel/VBoxContainer/RadiusLabel
@onready var radius_slider: HSlider = $UI/Control/Panel/VBoxContainer/RadiusSlider
@onready var length_label: Label = $UI/Control/Panel/VBoxContainer/LengthLabel
@onready var length_slider: HSlider = $UI/Control/Panel/VBoxContainer/LengthSlider
@onready var density_label: Label = $UI/Control/Panel/VBoxContainer/DensityLabel
@onready var density_slider: HSlider = $UI/Control/Panel/VBoxContainer/DensitySlider
@onready var size_label: Label = $UI/Control/Panel/VBoxContainer/SizeLabel
@onready var size_slider: HSlider = $UI/Control/Panel/VBoxContainer/SizeSlider
@onready var w_offset_label: Label = $UI/Control/Panel/VBoxContainer/WOffsetLabel
@onready var w_offset_slider: HSlider = $UI/Control/Panel/VBoxContainer/WOffsetSlider
@onready var animation_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/AnimationCheckBox
@onready var w_speed_label: Label = $UI/Control/Panel/VBoxContainer/WSpeedLabel
@onready var w_speed_slider: HSlider = $UI/Control/Panel/VBoxContainer/WSpeedSlider
@onready var rotation_label: Label = $UI/Control/Panel/VBoxContainer/RotationLabel
@onready var rotation_slider: HSlider = $UI/Control/Panel/VBoxContainer/RotationSlider
@onready var edge_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/EdgeColorPicker
@onready var emission_label: Label = $UI/Control/Panel/VBoxContainer/EmissionLabel
@onready var emission_slider: HSlider = $UI/Control/Panel/VBoxContainer/EmissionSlider
@onready var inner_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/InnerColorPicker
@onready var outer_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/OuterColorPicker
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var randomize_button: Button = $UI/Control/Panel/VBoxContainer/RandomizeButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
@onready var camera: Camera3D = $Camera3D
var camera_distance: float = 12.0
var camera_angle: float = 0.0
var camera_height: float = 8.0

func _ready():
	# Connect UI signals
	projection_option.item_selected.connect(_on_projection_selected)
	radius_slider.value_changed.connect(_on_radius_changed)
	length_slider.value_changed.connect(_on_length_changed)
	density_slider.value_changed.connect(_on_density_changed)
	size_slider.value_changed.connect(_on_size_changed)
	w_offset_slider.value_changed.connect(_on_w_offset_changed)
	animation_checkbox.toggled.connect(_on_animation_toggled)
	w_speed_slider.value_changed.connect(_on_w_speed_changed)
	rotation_slider.value_changed.connect(_on_rotation_changed)
	edge_color_picker.color_changed.connect(_on_edge_color_changed)
	emission_slider.value_changed.connect(_on_emission_changed)
	inner_color_picker.color_changed.connect(_on_inner_color_changed)
	outer_color_picker.color_changed.connect(_on_outer_color_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	
	# Update initial UI
	_update_ui()
	_update_stats()

func _process(delta):
	# Rotate camera around the tunnel
	camera_angle += delta * 0.15
	_update_camera_position()

func _update_camera_position():
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_projection_selected(index: int):
	tunnel.projection_type = index
	if projection_label:
		projection_label.text = "Projection: " + projection_option.get_item_text(index)
	_update_stats()

func _on_radius_changed(value: float):
	tunnel.tunnel_radius = value
	if radius_label:
		radius_label.text = "Tunnel Radius: " + "%.1f" % value
	_update_stats()

func _on_length_changed(value: float):
	tunnel.tunnel_length = value
	if length_label:
		length_label.text = "Tunnel Length: " + "%.1f" % value
	_update_stats()

func _on_density_changed(value: float):
	tunnel.tesseract_grid_density = int(value)
	if density_label:
		density_label.text = "Grid Density: " + str(int(value))
	_update_stats()

func _on_size_changed(value: float):
	tunnel.tesseract_size = value
	if size_label:
		size_label.text = "Tesseract Size: " + "%.1f" % value
	_update_stats()

func _on_w_offset_changed(value: float):
	tunnel.w_offset = value
	if w_offset_label:
		w_offset_label.text = "W Offset: " + "%.1f" % value

func _on_animation_toggled(pressed: bool):
	tunnel.animate_w = pressed

func _on_w_speed_changed(value: float):
	tunnel.w_speed = value
	if w_speed_label:
		w_speed_label.text = "W Speed: " + "%.1f" % value

func _on_rotation_changed(value: float):
	tunnel.rotation_4d = value
	if rotation_label:
		rotation_label.text = "4D Rotation: " + "%.1f" % value

func _on_edge_color_changed(color: Color):
	tunnel.edge_color = color

func _on_emission_changed(value: float):
	tunnel.emission_strength = value
	if emission_label:
		emission_label.text = "Emission: " + "%.1f" % value

func _on_inner_color_changed(color: Color):
	tunnel.inner_color = color

func _on_outer_color_changed(color: Color):
	tunnel.outer_color = color

func _on_regenerate_pressed():
	tunnel.regenerate()
	_update_stats()

func _on_randomize_pressed():
	_randomize_parameters()

func _update_ui():
	"""Update UI to reflect current tunnel settings"""
	if projection_option:
		projection_option.selected = tunnel.projection_type
	if radius_slider:
		radius_slider.value = tunnel.tunnel_radius
	if length_slider:
		length_slider.value = tunnel.tunnel_length
	if density_slider:
		density_slider.value = tunnel.tesseract_grid_density
	if size_slider:
		size_slider.value = tunnel.tesseract_size
	if w_offset_slider:
		w_offset_slider.value = tunnel.w_offset
	if animation_checkbox:
		animation_checkbox.button_pressed = tunnel.animate_w
	if w_speed_slider:
		w_speed_slider.value = tunnel.w_speed
	if rotation_slider:
		rotation_slider.value = tunnel.rotation_4d
	if edge_color_picker:
		edge_color_picker.color = tunnel.edge_color
	if emission_slider:
		emission_slider.value = tunnel.emission_strength
	if inner_color_picker:
		inner_color_picker.color = tunnel.inner_color
	if outer_color_picker:
		outer_color_picker.color = tunnel.outer_color

func _update_stats():
	"""Update statistics display"""
	if not stats_label:
		return
	var stats = tunnel.get_tunnel_stats()
	stats_label.text = "Tesseracts: " + str(stats["total_tesseracts"]) + "\n"
	stats_label.text += "Projection: " + stats["projection_type"] + "\n"
	stats_label.text += "Radius: " + "%.1f" % stats["tunnel_radius"] + "\n"
	stats_label.text += "Length: " + "%.1f" % stats["tunnel_length"] + "\n"
	stats_label.text += "Size: " + "%.1f" % stats["tesseract_size"] + "\n"
	stats_label.text += "W Offset: " + "%.1f" % stats["w_offset"] + "\n"
	stats_label.text += "4D Rotation: " + "%.1f" % stats["rotation_4d"]

func _randomize_parameters():
	"""Randomize tunnel parameters for variety"""
	tunnel.projection_type = randi() % 4
	tunnel.tunnel_radius = randf_range(3.0, 12.0)
	tunnel.tunnel_length = randf_range(15.0, 40.0)
	tunnel.tesseract_grid_density = randi_range(2, 6)
	tunnel.tesseract_size = randf_range(0.8, 3.0)
	tunnel.w_speed = randf_range(0.2, 1.5)
	tunnel.emission_strength = randf_range(1.0, 4.0)
	
	# Randomize colors
	var hue1 = randf()
	var hue2 = fmod(hue1 + randf_range(0.2, 0.8), 1.0)
	var hue3 = fmod(hue2 + randf_range(0.2, 0.8), 1.0)
	
	tunnel.edge_color = Color.from_hsv(hue1, 0.8, 0.9)
	tunnel.inner_color = Color.from_hsv(hue2, 0.9, 0.8)
	tunnel.outer_color = Color.from_hsv(hue3, 0.7, 0.7)
	
	tunnel.regenerate()
	_update_ui()
	_update_stats()

# Input handling for camera control
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(25.0, camera_distance + 1.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to randomize parameters
			_randomize_parameters()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to cycle through projection types
			var next_projection = (tunnel.projection_type + 1) % 4
			tunnel.set_projection_type(next_projection)
			if projection_option:
				projection_option.selected = next_projection
			if projection_label:
				projection_label.text = "Projection: " + projection_option.get_item_text(next_projection)
			_update_stats()
