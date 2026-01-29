extends Node3D

# UI References
@onready var portal: TessellatingPortal = $TessellatingPortal
@onready var portal_type_label: Label = $UI/Control/Panel/VBoxContainer/PortalTypeLabel
@onready var portal_type_option: OptionButton = $UI/Control/Panel/VBoxContainer/PortalTypeOption
@onready var radius_label: Label = $UI/Control/Panel/VBoxContainer/RadiusLabel
@onready var radius_slider: HSlider = $UI/Control/Panel/VBoxContainer/RadiusSlider
@onready var thickness_label: Label = $UI/Control/Panel/VBoxContainer/ThicknessLabel
@onready var thickness_slider: HSlider = $UI/Control/Panel/VBoxContainer/ThicknessSlider
@onready var block_size_label: Label = $UI/Control/Panel/VBoxContainer/BlockSizeLabel
@onready var block_size_slider: HSlider = $UI/Control/Panel/VBoxContainer/BlockSizeSlider
@onready var color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/ColorPicker
@onready var emission_label: Label = $UI/Control/Panel/VBoxContainer/EmissionLabel
@onready var emission_slider: HSlider = $UI/Control/Panel/VBoxContainer/EmissionSlider
@onready var animation_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/AnimationCheckBox
@onready var speed_label: Label = $UI/Control/Panel/VBoxContainer/SpeedLabel
@onready var speed_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpeedSlider
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var randomize_button: Button = $UI/Control/Panel/VBoxContainer/RandomizeButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
@onready var camera: Camera3D = $Camera3D
var camera_distance: float = 8.0
var camera_angle: float = 0.0
var camera_height: float = 5.0

func _ready():
	# Connect UI signals
	portal_type_option.item_selected.connect(_on_portal_type_selected)
	radius_slider.value_changed.connect(_on_radius_changed)
	thickness_slider.value_changed.connect(_on_thickness_changed)
	block_size_slider.value_changed.connect(_on_block_size_changed)
	color_picker.color_changed.connect(_on_color_changed)
	emission_slider.value_changed.connect(_on_emission_changed)
	animation_checkbox.toggled.connect(_on_animation_toggled)
	speed_slider.value_changed.connect(_on_speed_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	
	# Update initial UI
	_update_ui()
	_update_stats()

func _process(delta):
	# Rotate camera around the portal
	camera_angle += delta * 0.2
	_update_camera_position()

func _update_camera_position():
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_portal_type_selected(index: int):
	portal.portal_type = index
	if portal_type_label:
		portal_type_label.text = "Portal Type: " + portal_type_option.get_item_text(index)
	_update_stats()

func _on_radius_changed(value: float):
	portal.portal_radius = value
	if radius_label:
		radius_label.text = "Radius: " + "%.1f" % value
	_update_stats()

func _on_thickness_changed(value: float):
	portal.portal_thickness = value
	if thickness_label:
		thickness_label.text = "Thickness: " + "%.1f" % value
	_update_stats()

func _on_block_size_changed(value: float):
	portal.block_size = value
	if block_size_label:
		block_size_label.text = "Block Size: " + "%.2f" % value
	_update_stats()

func _on_color_changed(color: Color):
	portal.portal_color = color

func _on_emission_changed(value: float):
	portal.emission_strength = value
	if emission_label:
		emission_label.text = "Emission Strength: " + "%.1f" % value

func _on_animation_toggled(pressed: bool):
	portal.animate_rotation = pressed

func _on_speed_changed(value: float):
	portal.rotation_speed = value
	if speed_label:
		speed_label.text = "Rotation Speed: " + "%.1f" % value

func _on_regenerate_pressed():
	portal.regenerate()
	_update_stats()

func _on_randomize_pressed():
	_randomize_parameters()

func _update_ui():
	"""Update UI to reflect current portal settings"""
	portal_type_option.selected = portal.portal_type
	radius_slider.value = portal.portal_radius
	thickness_slider.value = portal.portal_thickness
	block_size_slider.value = portal.block_size
	color_picker.color = portal.portal_color
	emission_slider.value = portal.emission_strength
	animation_checkbox.button_pressed = portal.animate_rotation
	speed_slider.value = portal.rotation_speed

func _update_stats():
	"""Update statistics display"""
	if not stats_label:
		return
	var stats = portal.get_portal_stats()
	stats_label.text = "Blocks: " + str(stats["total_blocks"]) + "\n"
	stats_label.text += "Type: " + stats["portal_type"] + "\n"
	stats_label.text += "Radius: " + "%.1f" % stats["portal_radius"] + "\n"
	stats_label.text += "Thickness: " + "%.1f" % stats["portal_thickness"] + "\n"
	stats_label.text += "Block Size: " + "%.2f" % stats["block_size"]

func _randomize_parameters():
	"""Randomize portal parameters for variety"""
	portal.portal_type = randi() % 6
	portal.portal_radius = randf_range(2.0, 8.0)
	portal.portal_thickness = randf_range(0.8, 3.0)
	portal.block_size = randf_range(0.2, 1.0)
	portal.emission_strength = randf_range(0.5, 3.0)
	portal.rotation_speed = randf_range(0.1, 2.0)
	
	# Randomize color
	var hue = randf()
	portal.portal_color = Color.from_hsv(hue, 0.7, 0.9)
	
	portal.regenerate()
	_update_ui()
	_update_stats()

# Input handling for camera control
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(3.0, camera_distance - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(15.0, camera_distance + 0.5)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to randomize parameters
			_randomize_parameters()
