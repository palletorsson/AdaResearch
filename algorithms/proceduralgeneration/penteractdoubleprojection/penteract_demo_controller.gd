extends Node3D

# UI References
@onready var penteract: PenteractDoubleProjection = $PenteractDoubleProjection
@onready var projection_label: Label = $UI/Control/Panel/VBoxContainer/ProjectionLabel
@onready var projection_option: OptionButton = $UI/Control/Panel/VBoxContainer/ProjectionOption
@onready var size_label: Label = $UI/Control/Panel/VBoxContainer/SizeLabel
@onready var size_slider: HSlider = $UI/Control/Panel/VBoxContainer/SizeSlider
@onready var dist_5d_label: Label = $UI/Control/Panel/VBoxContainer/Dist5DLabel
@onready var dist_5d_slider: HSlider = $UI/Control/Panel/VBoxContainer/Dist5DSlider
@onready var dist_4d_label: Label = $UI/Control/Panel/VBoxContainer/Dist4DLabel
@onready var dist_4d_slider: HSlider = $UI/Control/Panel/VBoxContainer/Dist4DSlider
@onready var rot_5d_vw_label: Label = $UI/Control/Panel/VBoxContainer/Rot5DVWLabel
@onready var rot_5d_vw_slider: HSlider = $UI/Control/Panel/VBoxContainer/Rot5DVWSlider
@onready var rot_4d_xw_label: Label = $UI/Control/Panel/VBoxContainer/Rot4DXWLabel
@onready var rot_4d_xw_slider: HSlider = $UI/Control/Panel/VBoxContainer/Rot4DXWSlider
@onready var rot_4d_yw_label: Label = $UI/Control/Panel/VBoxContainer/Rot4DYWLabel
@onready var rot_4d_yw_slider: HSlider = $UI/Control/Panel/VBoxContainer/Rot4DYWSlider
@onready var rot_4d_zw_label: Label = $UI/Control/Panel/VBoxContainer/Rot4DZWLabel
@onready var rot_4d_zw_slider: HSlider = $UI/Control/Panel/VBoxContainer/Rot4DZWSlider
@onready var animation_checkbox: CheckBox = $UI/Control/Panel/VBoxContainer/AnimationCheckBox
@onready var speed_label: Label = $UI/Control/Panel/VBoxContainer/SpeedLabel
@onready var speed_slider: HSlider = $UI/Control/Panel/VBoxContainer/SpeedSlider
@onready var inner_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/InnerColorPicker
@onready var middle_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/MiddleColorPicker
@onready var outer_color_picker: ColorPicker = $UI/Control/Panel/VBoxContainer/OuterColorPicker
@onready var emission_label: Label = $UI/Control/Panel/VBoxContainer/EmissionLabel
@onready var emission_slider: HSlider = $UI/Control/Panel/VBoxContainer/EmissionSlider
@onready var regenerate_button: Button = $UI/Control/Panel/VBoxContainer/RegenerateButton
@onready var randomize_button: Button = $UI/Control/Panel/VBoxContainer/RandomizeButton
@onready var stats_label: Label = $UI/Control/Panel/VBoxContainer/StatsLabel

# Camera control
@onready var camera: Camera3D = $Camera3D
var camera_distance: float = 10.0
var camera_angle: float = 0.0
var camera_height: float = 6.0

func _ready():
	# Connect UI signals
	projection_option.item_selected.connect(_on_projection_selected)
	size_slider.value_changed.connect(_on_size_changed)
	dist_5d_slider.value_changed.connect(_on_dist_5d_changed)
	dist_4d_slider.value_changed.connect(_on_dist_4d_changed)
	rot_5d_vw_slider.value_changed.connect(_on_rot_5d_vw_changed)
	rot_4d_xw_slider.value_changed.connect(_on_rot_4d_xw_changed)
	rot_4d_yw_slider.value_changed.connect(_on_rot_4d_yw_changed)
	rot_4d_zw_slider.value_changed.connect(_on_rot_4d_zw_changed)
	animation_checkbox.toggled.connect(_on_animation_toggled)
	speed_slider.value_changed.connect(_on_speed_changed)
	inner_color_picker.color_changed.connect(_on_inner_color_changed)
	middle_color_picker.color_changed.connect(_on_middle_color_changed)
	outer_color_picker.color_changed.connect(_on_outer_color_changed)
	emission_slider.value_changed.connect(_on_emission_changed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	
	# Update initial UI
	_update_ui()
	_update_stats()

func _process(delta):
	# Rotate camera around the penteract
	camera_angle += delta * 0.1
	_update_camera_position()

func _update_camera_position():
	var x = cos(camera_angle) * camera_distance
	var z = sin(camera_angle) * camera_distance
	camera.position = Vector3(x, camera_height, z)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_projection_selected(index: int):
	penteract.projection_mode = index
	if projection_label:
		projection_label.text = "Projection: " + projection_option.get_item_text(index)
	_update_stats()

func _on_size_changed(value: float):
	penteract.penteract_size = value
	if size_label:
		size_label.text = "Penteract Size: " + "%.1f" % value
	_update_stats()

func _on_dist_5d_changed(value: float):
	penteract.projection_distance_5d = value
	if dist_5d_label:
		dist_5d_label.text = "5D Projection Distance: " + "%.1f" % value

func _on_dist_4d_changed(value: float):
	penteract.projection_distance_4d = value
	if dist_4d_label:
		dist_4d_label.text = "4D Projection Distance: " + "%.1f" % value

func _on_rot_5d_vw_changed(value: float):
	penteract.rotation_5d_vw = value
	if rot_5d_vw_label:
		rot_5d_vw_label.text = "5D VW Rotation: " + "%.1f" % value

func _on_rot_4d_xw_changed(value: float):
	penteract.rotation_4d_xw = value
	if rot_4d_xw_label:
		rot_4d_xw_label.text = "4D XW Rotation: " + "%.1f" % value

func _on_rot_4d_yw_changed(value: float):
	penteract.rotation_4d_yw = value
	if rot_4d_yw_label:
		rot_4d_yw_label.text = "4D YW Rotation: " + "%.1f" % value

func _on_rot_4d_zw_changed(value: float):
	penteract.rotation_4d_zw = value
	if rot_4d_zw_label:
		rot_4d_zw_label.text = "4D ZW Rotation: " + "%.1f" % value

func _on_animation_toggled(pressed: bool):
	penteract.animate_rotation = pressed

func _on_speed_changed(value: float):
	penteract.rotation_speed = value
	if speed_label:
		speed_label.text = "Rotation Speed: " + "%.2f" % value

func _on_inner_color_changed(color: Color):
	penteract.inner_color = color

func _on_middle_color_changed(color: Color):
	penteract.middle_color = color

func _on_outer_color_changed(color: Color):
	penteract.outer_color = color

func _on_emission_changed(value: float):
	penteract.emission_strength = value
	if emission_label:
		emission_label.text = "Emission: " + "%.1f" % value

func _on_regenerate_pressed():
	penteract.regenerate()
	_update_stats()

func _on_randomize_pressed():
	_randomize_parameters()

func _update_ui():
	"""Update UI to reflect current penteract settings"""
	if projection_option:
		projection_option.selected = penteract.projection_mode
	if size_slider:
		size_slider.value = penteract.penteract_size
	if dist_5d_slider:
		dist_5d_slider.value = penteract.projection_distance_5d
	if dist_4d_slider:
		dist_4d_slider.value = penteract.projection_distance_4d
	if rot_5d_vw_slider:
		rot_5d_vw_slider.value = penteract.rotation_5d_vw
	if rot_4d_xw_slider:
		rot_4d_xw_slider.value = penteract.rotation_4d_xw
	if rot_4d_yw_slider:
		rot_4d_yw_slider.value = penteract.rotation_4d_yw
	if rot_4d_zw_slider:
		rot_4d_zw_slider.value = penteract.rotation_4d_zw
	if animation_checkbox:
		animation_checkbox.button_pressed = penteract.animate_rotation
	if speed_slider:
		speed_slider.value = penteract.rotation_speed
	if inner_color_picker:
		inner_color_picker.color = penteract.inner_color
	if middle_color_picker:
		middle_color_picker.color = penteract.middle_color
	if outer_color_picker:
		outer_color_picker.color = penteract.outer_color
	if emission_slider:
		emission_slider.value = penteract.emission_strength

func _update_stats():
	"""Update statistics display"""
	if not stats_label:
		return
	var stats = penteract.get_penteract_stats()
	stats_label.text = "Vertices: " + str(stats["total_vertices"]) + "\n"
	stats_label.text += "Edges: " + str(stats["total_edges"]) + "\n"
	stats_label.text += "Projection: " + stats["projection_mode"] + "\n"
	stats_label.text += "Size: " + "%.1f" % stats["penteract_size"] + "\n"
	stats_label.text += "5D Distance: " + "%.1f" % stats["projection_distance_5d"] + "\n"
	stats_label.text += "4D Distance: " + "%.1f" % stats["projection_distance_4d"] + "\n"
	stats_label.text += "5D VW: " + "%.1f" % stats["rotation_5d_vw"] + "\n"
	stats_label.text += "4D XW: " + "%.1f" % stats["rotation_4d_xw"] + "\n"
	stats_label.text += "4D YW: " + "%.1f" % stats["rotation_4d_yw"] + "\n"
	stats_label.text += "4D ZW: " + "%.1f" % stats["rotation_4d_zw"]

func _randomize_parameters():
	"""Randomize penteract parameters for variety"""
	penteract.projection_mode = randi() % 4
	penteract.penteract_size = randf_range(1.0, 4.0)
	penteract.projection_distance_5d = randf_range(3.0, 8.0)
	penteract.projection_distance_4d = randf_range(3.0, 8.0)
	penteract.rotation_5d_vw = randf_range(0.0, TAU)
	penteract.rotation_4d_xw = randf_range(0.0, TAU)
	penteract.rotation_4d_yw = randf_range(0.0, TAU)
	penteract.rotation_4d_zw = randf_range(0.0, TAU)
	penteract.rotation_speed = randf_range(0.1, 1.0)
	penteract.emission_strength = randf_range(0.5, 3.0)
	
	# Randomize colors
	var hue1 = randf()
	var hue2 = fmod(hue1 + randf_range(0.2, 0.6), 1.0)
	var hue3 = fmod(hue2 + randf_range(0.2, 0.6), 1.0)
	
	penteract.inner_color = Color.from_hsv(hue1, 0.8, 0.9)
	penteract.middle_color = Color.from_hsv(hue2, 0.9, 0.8)
	penteract.outer_color = Color.from_hsv(hue3, 0.7, 0.7)
	
	penteract.regenerate()
	_update_ui()
	_update_stats()

# Input handling for camera control
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(4.0, camera_distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(20.0, camera_distance + 1.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click to randomize parameters
			_randomize_parameters()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to cycle through projection modes
			var next_projection = (penteract.projection_mode + 1) % 4
			penteract.set_projection_mode(next_projection)
			if projection_option:
				projection_option.selected = next_projection
			if projection_label:
				projection_label.text = "Projection: " + projection_option.get_item_text(next_projection)
			_update_stats()
