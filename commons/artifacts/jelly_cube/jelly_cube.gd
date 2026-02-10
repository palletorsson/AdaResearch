# jelly_cube.gd
# A soft, deformable cube that jiggles when touched
# VR-enabled with physics parameter controls

extends Node3D

class_name JellyCube

## Size of the cube
@export var cube_size: float = 0.3

## Subdivisions (more = smoother deformation, slower)
@export_range(1, 8) var subdivisions: int = 4

## Jelly color
@export var jelly_color: Color = Color(0.2, 0.9, 0.5, 0.8):
	set(value):
		jelly_color = value
		if _material:
			_material.albedo_color = value
			if emission_strength > 0:
				_material.emission = value

## Physics properties
@export_group("Physics")
@export var stiffness: float = 0.5:
	set(value):
		stiffness = clampf(value, 0.0, 1.0)
		if _soft_body:
			_soft_body.linear_stiffness = stiffness
		_sync_stiffness_slider()

@export var damping: float = 0.01:
	set(value):
		damping = clampf(value, 0.0, 0.1)
		if _soft_body:
			_soft_body.damping_coefficient = damping
		_sync_damping_slider()

@export var pressure: float = 1.0:
	set(value):
		pressure = clampf(value, 0.0, 5.0)
		if _soft_body:
			_soft_body.pressure_coefficient = pressure
		_sync_pressure_slider()

@export var mass: float = 1.0

## Appearance
@export_group("Appearance")
@export var emission_strength: float = 0.2
@export var use_transparency: bool = true

var _soft_body: SoftBody3D
var _material: StandardMaterial3D
var _info_label: Label3D
var _color_index: int = 0

# VR Controls
var _stiffness_slider: Node
var _damping_slider: Node
var _pressure_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

const JELLY_COLORS = [
	Color(0.2, 0.9, 0.5, 0.8),   # Green
	Color(0.9, 0.3, 0.5, 0.8),   # Pink
	Color(0.3, 0.5, 0.9, 0.8),   # Blue
	Color(0.9, 0.7, 0.2, 0.8),   # Orange
	Color(0.7, 0.3, 0.9, 0.8),   # Purple
]

func _ready():
	_create_soft_body()
	_create_pedestal()
	_create_labels()
	_create_vr_controls()

func _create_soft_body():
	_soft_body = SoftBody3D.new()
	_soft_body.name = "JellySoftBody"
	
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	box.subdivide_width = subdivisions
	box.subdivide_height = subdivisions
	box.subdivide_depth = subdivisions
	_soft_body.mesh = box
	
	_soft_body.simulation_precision = 5
	_soft_body.total_mass = mass
	_soft_body.linear_stiffness = stiffness
	_soft_body.pressure_coefficient = pressure
	_soft_body.damping_coefficient = damping
	_soft_body.drag_coefficient = 0.0
	
	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 393217  # Include hand layers
	
	_material = StandardMaterial3D.new()
	_material.albedo_color = jelly_color
	
	if use_transparency:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if emission_strength > 0:
		_material.emission_enabled = true
		_material.emission = jelly_color
		_material.emission_energy_multiplier = emission_strength
	
	_material.roughness = 0.2
	_material.metallic = 0.0
	
	_soft_body.material_override = _material
	_soft_body.position = Vector3(0, cube_size / 2 + 0.05, 0)
	
	add_child(_soft_body)

func _create_pedestal():
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cube_size * 0.6
	cylinder.bottom_radius = cube_size * 0.7
	cylinder.height = 0.04
	pedestal.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.8
	mat.roughness = 0.3
	pedestal.material_override = mat
	
	pedestal.position = Vector3(0, -0.02, 0)
	add_child(pedestal)
	
	var static_body = StaticBody3D.new()
	static_body.name = "PedestalCollision"
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = cube_size * 0.7
	shape.height = 0.04
	collision.shape = shape
	static_body.add_child(collision)
	static_body.position = Vector3(0, -0.02, 0)
	add_child(static_body)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, cube_size + 0.15, 0)
	_info_label.text = "JELLY CUBE\nTouch to deform"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.18, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Stiffness slider (0-1)
	_stiffness_slider = SLIDER_HORIZONTAL.instantiate()
	_stiffness_slider.name = "StiffnessSlider"
	_stiffness_slider.position = Vector3(-0.14, 0.04, 0)
	_stiffness_slider.rotation_degrees.x = -30
	var stiff_label = _stiffness_slider.get_node_or_null("Frame/LabelName")
	if stiff_label:
		stiff_label.text = "STIFF"
	_control_panel.add_child(_stiffness_slider)
	_stiffness_slider.slider_moved.connect(_on_stiffness_slider_moved)
	
	# Damping slider (0-0.1)
	_damping_slider = SLIDER_HORIZONTAL.instantiate()
	_damping_slider.name = "DampingSlider"
	_damping_slider.position = Vector3(0, 0.04, 0)
	_damping_slider.rotation_degrees.x = -30
	var damp_label = _damping_slider.get_node_or_null("Frame/LabelName")
	if damp_label:
		damp_label.text = "DAMP"
	_control_panel.add_child(_damping_slider)
	_damping_slider.slider_moved.connect(_on_damping_slider_moved)
	
	# Pressure slider (0-5)
	_pressure_slider = SLIDER_HORIZONTAL.instantiate()
	_pressure_slider.name = "PressureSlider"
	_pressure_slider.position = Vector3(0.14, 0.04, 0)
	_pressure_slider.rotation_degrees.x = -30
	var press_label = _pressure_slider.get_node_or_null("Frame/LabelName")
	if press_label:
		press_label.text = "PRESS"
	_control_panel.add_child(_pressure_slider)
	_pressure_slider.slider_moved.connect(_on_pressure_slider_moved)
	
	# Color cycle button
	var color_btn = PUSH_BUTTON.instantiate()
	color_btn.name = "ColorButton"
	color_btn.position = Vector3(-0.08, -0.04, 0)
	color_btn.rotation_degrees.x = -30
	_control_panel.add_child(color_btn)
	_add_button_label(color_btn, "COLOR")
	var color_area = color_btn.get_node_or_null("InteractableAreaButton")
	if color_area:
		color_area.button_pressed.connect(_on_color_pressed)
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0.08, -0.04, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RST")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_reset_physics)
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 10
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_stiffness_slider()
	_sync_damping_slider()
	_sync_pressure_slider()

func _sync_stiffness_slider():
	if _stiffness_slider and _stiffness_slider.has_method("set_normalized_value"):
		_stiffness_slider.set_normalized_value(stiffness)

func _sync_damping_slider():
	if _damping_slider and _damping_slider.has_method("set_normalized_value"):
		_damping_slider.set_normalized_value(damping / 0.1)

func _sync_pressure_slider():
	if _pressure_slider and _pressure_slider.has_method("set_normalized_value"):
		_pressure_slider.set_normalized_value(pressure / 5.0)

func _on_stiffness_slider_moved(_position):
	if _stiffness_slider and _stiffness_slider.has_method("get_normalized_value"):
		stiffness = _stiffness_slider.get_normalized_value()

func _on_damping_slider_moved(_position):
	if _damping_slider and _damping_slider.has_method("get_normalized_value"):
		damping = _damping_slider.get_normalized_value() * 0.1

func _on_pressure_slider_moved(_position):
	if _pressure_slider and _pressure_slider.has_method("get_normalized_value"):
		pressure = _pressure_slider.get_normalized_value() * 5.0

func _on_color_pressed(_button = null):  # Accept optional button arg
	_color_index = (_color_index + 1) % JELLY_COLORS.size()
	jelly_color = JELLY_COLORS[_color_index]

func _reset_physics(_button = null):  # Accept optional button arg
	stiffness = 0.5
	damping = 0.01
	pressure = 1.0

## Apply an impulse to the jelly (for poking)
func poke(_world_position: Vector3, _force: float = 2.0):
	if not _soft_body:
		return
	# SoftBody interaction handled by physics collision

func set_color(color: Color):
	jelly_color = color

func set_stiffness(value: float):
	stiffness = value

func set_pressure(value: float):
	pressure = value

func set_damping(value: float):
	damping = value