# coupled_pendulums.gd
# Two pendulums connected by a spring
# Shows energy transfer between oscillators
#
# QFEP: The λ dial controls coupling strength
# Weak coupling = slow transfer, strong = fast beats

extends Node3D

class_name CoupledPendulums

## Pendulum parameters
@export var pendulum_length: float = 0.5
@export var bob_radius: float = 0.04
@export var rod_thickness: float = 0.008

## Physics
@export var gravity: float = 9.8
@export var coupling_strength: float = 2.0:
	set(value):
		coupling_strength = clampf(value, 0.0, 10.0)
		_sync_coupling_slider()

@export var damping: float = 0.02

## Initial conditions (angles in degrees)
@export var initial_angle_1: float = 30.0
@export var initial_angle_2: float = 0.0

## Colors
@export var color_pendulum_1: Color = Color(1.0, 0.3, 0.3)  # Red
@export var color_pendulum_2: Color = Color(0.3, 0.5, 1.0)  # Blue
@export var color_spring: Color = Color(0.8, 0.8, 0.3)      # Yellow
@export var color_energy: Color = Color(0.3, 1.0, 0.5)      # Green

# State
var _angle_1: float = 0.0  # radians
var _angle_2: float = 0.0
var _velocity_1: float = 0.0
var _velocity_2: float = 0.0

# Visuals
var _pivot_1: Node3D
var _pivot_2: Node3D
var _rod_1: MeshInstance3D
var _rod_2: MeshInstance3D
var _bob_1: MeshInstance3D
var _bob_2: MeshInstance3D
var _spring: MeshInstance3D
var _energy_bar_1: MeshInstance3D
var _energy_bar_2: MeshInstance3D
var _info_label: Label3D
var _control_panel: Node3D
var _coupling_slider: Node

# Separation between pendulums
var _separation: float = 0.3

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_frame()
	_create_pendulums()
	_create_spring()
	_create_energy_bars()
	_create_labels()
	_create_vr_controls()
	_reset_simulation()

func _create_frame():
	# Support structure
	var frame = MeshInstance3D.new()
	frame.name = "Frame"
	var box = BoxMesh.new()
	box.size = Vector3(_separation * 2 + 0.1, 0.03, 0.03)
	frame.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	mat.metallic = 0.7
	frame.material_override = mat
	frame.position = Vector3(0, pendulum_length + 0.1, 0)
	add_child(frame)

func _create_pendulums():
	# Pendulum 1 (left)
	_pivot_1 = Node3D.new()
	_pivot_1.name = "Pivot1"
	_pivot_1.position = Vector3(-_separation / 2, pendulum_length + 0.1, 0)
	add_child(_pivot_1)
	
	_rod_1 = _create_rod(color_pendulum_1)
	_pivot_1.add_child(_rod_1)
	
	_bob_1 = _create_bob(color_pendulum_1)
	_bob_1.position = Vector3(0, -pendulum_length, 0)
	_pivot_1.add_child(_bob_1)
	
	# Pendulum 2 (right)
	_pivot_2 = Node3D.new()
	_pivot_2.name = "Pivot2"
	_pivot_2.position = Vector3(_separation / 2, pendulum_length + 0.1, 0)
	add_child(_pivot_2)
	
	_rod_2 = _create_rod(color_pendulum_2)
	_pivot_2.add_child(_rod_2)
	
	_bob_2 = _create_bob(color_pendulum_2)
	_bob_2.position = Vector3(0, -pendulum_length, 0)
	_pivot_2.add_child(_bob_2)

func _create_rod(color: Color) -> MeshInstance3D:
	var rod = MeshInstance3D.new()
	rod.name = "Rod"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = rod_thickness
	cylinder.bottom_radius = rod_thickness
	cylinder.height = pendulum_length
	rod.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color * 0.6
	mat.metallic = 0.5
	rod.material_override = mat
	rod.position = Vector3(0, -pendulum_length / 2, 0)
	
	return rod

func _create_bob(color: Color) -> MeshInstance3D:
	var bob = MeshInstance3D.new()
	bob.name = "Bob"
	var sphere = SphereMesh.new()
	sphere.radius = bob_radius
	sphere.height = bob_radius * 2
	bob.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	bob.material_override = mat
	
	return bob

func _create_spring():
	_spring = MeshInstance3D.new()
	_spring.name = "Spring"
	add_child(_spring)
	_update_spring()

func _update_spring():
	# Get bob world positions
	var pos1 = _pivot_1.global_position + _pivot_1.transform.basis * Vector3(0, -pendulum_length, 0)
	var pos2 = _pivot_2.global_position + _pivot_2.transform.basis * Vector3(0, -pendulum_length, 0)
	
	var direction = pos2 - pos1
	var length = direction.length()
	
	# Create spring coil appearance
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = length
	_spring.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	# Color intensity based on coupling strength
	var intensity = coupling_strength / 10.0
	mat.albedo_color = color_spring * (0.3 + intensity * 0.7)
	mat.emission_enabled = true
	mat.emission = color_spring
	mat.emission_energy_multiplier = intensity * 0.5
	_spring.material_override = mat
	
	_spring.global_position = (pos1 + pos2) / 2.0
	
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		_spring.look_at(_spring.global_position + direction, up)
		_spring.rotate_object_local(Vector3.RIGHT, PI/2)

func _create_energy_bars():
	# Energy bar for pendulum 1
	_energy_bar_1 = _create_energy_bar(color_pendulum_1)
	_energy_bar_1.position = Vector3(-_separation / 2 - 0.08, 0, 0.1)
	add_child(_energy_bar_1)
	
	# Energy bar for pendulum 2
	_energy_bar_2 = _create_energy_bar(color_pendulum_2)
	_energy_bar_2.position = Vector3(_separation / 2 + 0.08, 0, 0.1)
	add_child(_energy_bar_2)

func _create_energy_bar(color: Color) -> MeshInstance3D:
	var bar = MeshInstance3D.new()
	bar.name = "EnergyBar"
	var box = BoxMesh.new()
	box.size = Vector3(0.02, pendulum_length, 0.02)
	bar.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	bar.material_override = mat
	
	return bar

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, pendulum_length + 0.25, 0)
	_info_label.text = "COUPLED PENDULUMS"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.15, 0.25)
	_control_panel.rotation_degrees = Vector3(30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.14, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Coupling slider
	_coupling_slider = SLIDER_HORIZONTAL.instantiate()
	_coupling_slider.name = "CouplingSlider"
	_coupling_slider.position = Vector3(0, 0.03, 0)
	var coupling_label = _coupling_slider.get_node_or_null("Frame/LabelName")
	if coupling_label:
		coupling_label.text = "COUPLING"
	_control_panel.add_child(_coupling_slider)
	_coupling_slider.slider_moved.connect(_on_coupling_changed)
	
	# Preset buttons
	var presets = [
		["BEATS", 30.0, 0.0, 2.0],
		["SYNC", 20.0, 20.0, 5.0],
		["WEAK", 45.0, 0.0, 0.5],
		["CHAOS", 30.0, 15.0, 8.0]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.12 + i * 0.08, -0.035, 0)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var a1 = presets[i][1]
		var a2 = presets[i][2]
		var k = presets[i][3]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _apply_preset(a1, a2, k))
	
	call_deferred("_sync_coupling_slider")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.022, 0)
	btn.add_child(lbl)

func _sync_coupling_slider():
	if _coupling_slider and _coupling_slider.has_method("set_normalized_value"):
		_coupling_slider.set_normalized_value(coupling_strength / 10.0)

func _on_coupling_changed(_position):
	if _coupling_slider and _coupling_slider.has_method("get_normalized_value"):
		coupling_strength = _coupling_slider.get_normalized_value() * 10.0

func _apply_preset(a1: float, a2: float, k: float):
	initial_angle_1 = a1
	initial_angle_2 = a2
	coupling_strength = k
	_sync_coupling_slider()
	_reset_simulation()

func _reset_simulation():
	_angle_1 = deg_to_rad(initial_angle_1)
	_angle_2 = deg_to_rad(initial_angle_2)
	_velocity_1 = 0.0
	_velocity_2 = 0.0

func _physics_process(delta):
	# Equations of motion for coupled pendulums
	# θ1'' = -(g/L)sin(θ1) + k(θ2 - θ1) - d*θ1'
	# θ2'' = -(g/L)sin(θ2) + k(θ1 - θ2) - d*θ2'
	
	var omega_sq = gravity / pendulum_length
	var k = coupling_strength
	
	# Accelerations
	var accel_1 = -omega_sq * sin(_angle_1) + k * (_angle_2 - _angle_1) - damping * _velocity_1
	var accel_2 = -omega_sq * sin(_angle_2) + k * (_angle_1 - _angle_2) - damping * _velocity_2
	
	# Semi-implicit Euler integration
	_velocity_1 += accel_1 * delta
	_velocity_2 += accel_2 * delta
	_angle_1 += _velocity_1 * delta
	_angle_2 += _velocity_2 * delta
	
	# Update visuals
	_pivot_1.rotation = Vector3(0, 0, _angle_1)
	_pivot_2.rotation = Vector3(0, 0, _angle_2)
	
	_update_spring()
	_update_energy_bars()
	_update_info()

func _update_energy_bars():
	# Calculate energies (normalized)
	var max_angle = deg_to_rad(45)
	var max_energy = 0.5 * gravity / pendulum_length * max_angle * max_angle + 0.5 * max_angle * max_angle
	
	var energy_1 = 0.5 * _velocity_1 * _velocity_1 + 0.5 * gravity / pendulum_length * (1 - cos(_angle_1))
	var energy_2 = 0.5 * _velocity_2 * _velocity_2 + 0.5 * gravity / pendulum_length * (1 - cos(_angle_2))
	
	var norm_1 = clampf(energy_1 / max_energy, 0.0, 1.0)
	var norm_2 = clampf(energy_2 / max_energy, 0.0, 1.0)
	
	_energy_bar_1.scale = Vector3(1, norm_1, 1)
	_energy_bar_1.position.y = (norm_1 * pendulum_length) / 2.0
	
	_energy_bar_2.scale = Vector3(1, norm_2, 1)
	_energy_bar_2.position.y = (norm_2 * pendulum_length) / 2.0

func _update_info():
	var total_energy = 0.5 * _velocity_1 * _velocity_1 + 0.5 * _velocity_2 * _velocity_2
	total_energy += 0.5 * gravity / pendulum_length * ((1 - cos(_angle_1)) + (1 - cos(_angle_2)))
	total_energy += 0.5 * coupling_strength * pow(_angle_1 - _angle_2, 2)
	
	_info_label.text = "COUPLED PENDULUMS\nk = %.1f  E = %.3f" % [coupling_strength, total_energy]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(30.0, 0.0, 2.0)
			KEY_2: _apply_preset(20.0, 20.0, 5.0)
			KEY_3: _apply_preset(45.0, 0.0, 0.5)
			KEY_4: _apply_preset(30.0, 15.0, 8.0)
			KEY_R: _reset_simulation()
			KEY_UP: coupling_strength = minf(coupling_strength + 0.5, 10.0)
			KEY_DOWN: coupling_strength = maxf(coupling_strength - 0.5, 0.0)

func set_coupling(k: float):
	coupling_strength = k

func reset():
	_reset_simulation()
