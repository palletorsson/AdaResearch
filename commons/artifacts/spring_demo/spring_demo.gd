# spring_demo.gd
# Interactive Spring-Mass System demonstration
# Shows F = -kx (Hooke's Law) with physics simulation
# Sliders control Spring Constant (k), Mass, Damping
extends Node3D

class_name SpringDemo

## Slider paths
@export var stiffness_slider_path: NodePath = "ControlPanel/StiffnessSlider"
@export var mass_slider_path: NodePath = "ControlPanel/MassSlider"
@export var damping_slider_path: NodePath = "ControlPanel/DampingSlider"

## Visual elements
@onready var mass_node: MeshInstance3D = $Mass
@onready var spring_mesh: MeshInstance3D = $SpringMesh
@onready var anchor: MeshInstance3D = $Anchor
@onready var formula_label: Label3D = $FormulaLabel
@onready var values_label: Label3D = $ValuesLabel
@onready var force_arrow: Node3D = $ForceArrow

## Sliders
var stiffness_slider
var mass_slider
var damping_slider

## Physics parameters
var spring_k: float = 10.0      # Spring constant (N/m)
var mass: float = 1.0           # Mass (kg)
var damping_c: float = 0.2      # Damping coefficient

## State
var position_y: float = 0.0     # Displacement from equilibrium
var velocity_y: float = 0.0     # Velocity
var rest_position: float = 0.0  # Equilibrium position
var initial_displacement: float = 0.5

## Spring visual
var spring_coils: int = 12
var spring_radius: float = 0.05

## Trail for phase space visualization
var trail_points: Array[Vector2] = []  # (position, velocity)
const MAX_TRAIL = 300

signal parameters_changed(k: float, m: float, c: float)

func _ready() -> void:
	_setup_sliders()
	_reset_simulation()

func _setup_sliders() -> void:
	stiffness_slider = get_node_or_null(stiffness_slider_path)
	if stiffness_slider:
		stiffness_slider.set_range(1.0, 50.0)
		stiffness_slider.set_param_name("k")
		stiffness_slider.set_normalized_value(0.2)
		stiffness_slider.slider_moved.connect(_on_stiffness_changed)
	
	mass_slider = get_node_or_null(mass_slider_path)
	if mass_slider:
		mass_slider.set_range(0.1, 5.0)
		mass_slider.set_param_name("MASS")
		mass_slider.set_normalized_value(0.2)
		mass_slider.slider_moved.connect(_on_mass_changed)
	
	damping_slider = get_node_or_null(damping_slider_path)
	if damping_slider:
		damping_slider.set_range(0.0, 2.0)
		damping_slider.set_param_name("DAMP")
		damping_slider.set_normalized_value(0.1)
		damping_slider.slider_moved.connect(_on_damping_changed)

func _reset_simulation() -> void:
	position_y = initial_displacement
	velocity_y = 0.0
	trail_points.clear()

func _physics_process(delta: float) -> void:
	# Hooke's Law: F = -kx
	# With damping: F = -kx - cv
	# Newton: a = F/m
	
	var spring_force = -spring_k * position_y
	var damping_force = -damping_c * velocity_y
	var total_force = spring_force + damping_force
	var acceleration = total_force / mass
	
	# Euler integration (simple but stable enough for demo)
	velocity_y += acceleration * delta
	position_y += velocity_y * delta
	
	# Update visuals
	_update_mass_position()
	_update_spring_visual()
	_update_force_arrow(spring_force)
	_update_labels(spring_force, acceleration)
	_update_trail()

func _update_mass_position() -> void:
	if mass_node:
		mass_node.position.y = rest_position + position_y
		# Scale mass visual based on mass parameter
		var scale_factor = 0.5 + mass * 0.3
		mass_node.scale = Vector3.ONE * scale_factor

func _update_spring_visual() -> void:
	if not spring_mesh:
		return
	
	var mesh = ImmediateMesh.new()
	
	var anchor_y = 0.5  # Top anchor position
	var mass_y = rest_position + position_y
	var spring_length = anchor_y - mass_y
	
	# Need at least 2 points
	if spring_coils < 1:
		spring_mesh.mesh = mesh
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Generate coil points
	var points_per_coil = 8
	var total_points = spring_coils * points_per_coil
	
	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * spring_coils * TAU
		var y = anchor_y - t * spring_length
		var x = sin(angle) * spring_radius
		var z = cos(angle) * spring_radius
		
		# Color based on tension
		var tension = abs(position_y) / initial_displacement
		var color = Color(0.5 + tension * 0.5, 0.5, 0.5 - tension * 0.3)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, y, z))
	
	mesh.surface_end()
	spring_mesh.mesh = mesh

func _update_force_arrow(force: float) -> void:
	if not force_arrow:
		return
	
	# Arrow points in direction of force
	var arrow_scale = abs(force) * 0.05
	force_arrow.scale = Vector3(arrow_scale, arrow_scale, arrow_scale)
	force_arrow.position.y = rest_position + position_y
	
	# Flip arrow based on force direction
	if force > 0:
		force_arrow.rotation.z = 0
	else:
		force_arrow.rotation.z = PI

func _update_labels(force: float, accel: float) -> void:
	if formula_label:
		formula_label.text = "F = -kx - cv"
	
	if values_label:
		var omega = sqrt(spring_k / mass) if mass > 0 else 0
		var period = TAU / omega if omega > 0 else 0
		values_label.text = "k=%.1f  m=%.2f  c=%.2f\nx=%.3f  v=%.3f\nF=%.2f  T=%.2fs" % [
			spring_k, mass, damping_c, position_y, velocity_y, force, period
		]

func _update_trail() -> void:
	# Store phase space point (position vs velocity)
	trail_points.append(Vector2(position_y, velocity_y))
	if trail_points.size() > MAX_TRAIL:
		trail_points.pop_front()

# Slider callbacks

func _on_stiffness_changed(_value) -> void:
	if stiffness_slider:
		spring_k = lerp(1.0, 50.0, stiffness_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

func _on_mass_changed(_value) -> void:
	if mass_slider:
		mass = lerp(0.1, 5.0, mass_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

func _on_damping_changed(_value) -> void:
	if damping_slider:
		damping_c = lerp(0.0, 2.0, damping_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

# Public API

func reset() -> void:
	_reset_simulation()

func pull_and_release(displacement: float = 0.5) -> void:
	position_y = displacement
	velocity_y = 0.0
	trail_points.clear()

func get_natural_frequency() -> float:
	return sqrt(spring_k / mass) / TAU if mass > 0 else 0

func get_period() -> float:
	var omega = sqrt(spring_k / mass) if mass > 0 else 0
	return TAU / omega if omega > 0 else 0

func is_underdamped() -> bool:
	# Critical damping: c_crit = 2*sqrt(k*m)
	var c_crit = 2.0 * sqrt(spring_k * mass)
	return damping_c < c_crit
