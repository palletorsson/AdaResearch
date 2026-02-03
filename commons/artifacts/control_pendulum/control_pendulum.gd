# control_pendulum.gd
# Grabbable pendulum that controls oscillation parameters
# When grabbed: oscillation stops. When released: resumes from current position.
# Swing harder = faster oscillation. Higher amplitude = bigger movements.

extends Node3D

class_name ControlPendulum

signal oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float)
signal grabbed
signal released

@export var pendulum_length: float = 0.6
@export var bob_radius: float = 0.06
@export var gravity: float = 9.8
@export var damping: float = 0.995

var _pivot: Node3D
var _rod: MeshInstance3D
var _bob: MeshInstance3D
var _bob_body: RigidBody3D
var _label: Label3D

var _angle: float = 0.3  # Starting angle (radians)
var _angular_velocity: float = 0.0
var _is_grabbed: bool = false
var _grab_point: Node3D

# Output values for the controlled cube
var current_y_offset: float = 0.0
var current_angular_velocity: float = 0.0
var current_amplitude: float = 0.0

func _ready():
	_create_pivot()
	_create_rod()
	_create_bob()
	_create_label()

func _create_pivot():
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	
	# Pivot point visual
	var pivot_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	pivot_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5)
	mat.metallic = 0.8
	pivot_mesh.material_override = mat
	_pivot.add_child(pivot_mesh)

func _create_rod():
	_rod = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = pendulum_length
	_rod.mesh = cylinder
	_rod.position.y = -pendulum_length / 2
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.55, 0.5)
	mat.metallic = 0.6
	_rod.material_override = mat
	_pivot.add_child(_rod)

func _create_bob():
	_bob = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = bob_radius
	sphere.height = bob_radius * 2
	_bob.mesh = sphere
	_bob.position.y = -pendulum_length
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.2, 0.1)
	mat.emission_energy_multiplier = 0.4
	mat.metallic = 0.4
	mat.roughness = 0.3
	_bob.material_override = mat
	_pivot.add_child(_bob)
	
	# Make bob grabbable
	var area = Area3D.new()
	area.name = "GrabArea"
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = bob_radius * 1.5
	collision.shape = shape
	area.add_child(collision)
	_bob.add_child(area)
	
	# XR grabbable setup
	if has_node("/root/XRToolsInteractableArea"):
		# Add XRTools interactable if available
		pass

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "GRAB & SWING"
	_label.position = Vector3(0, 0.1, 0)
	_label.modulate = Color(0.7, 0.7, 0.8)
	add_child(_label)

func _physics_process(delta):
	if _is_grabbed:
		# When grabbed, pendulum stops
		_angular_velocity = 0.0
		_update_label("GRABBED\nRelease to swing")
	else:
		# Simple pendulum physics
		var angular_acceleration = -(gravity / pendulum_length) * sin(_angle)
		_angular_velocity += angular_acceleration * delta
		_angular_velocity *= damping
		_angle += _angular_velocity * delta
		
		# Clamp angle
		_angle = clampf(_angle, -PI * 0.45, PI * 0.45)
		
		_update_label("Swing: %.2f\nSpeed: %.2f" % [rad_to_deg(_angle), abs(_angular_velocity)])
	
	# Update visual rotation
	_pivot.rotation.z = _angle
	
	# Calculate output values
	current_y_offset = sin(_angle) * pendulum_length  # Y position from angle
	current_angular_velocity = _angular_velocity
	current_amplitude = abs(_angle) / (PI * 0.45)  # Normalized 0-1
	
	# Emit signal for connected objects
	oscillation_updated.emit(current_y_offset, current_angular_velocity, current_amplitude)

func _update_label(text: String):
	if _label:
		_label.text = text

func grab():
	_is_grabbed = true
	grabbed.emit()
	
	# Visual feedback
	var mat = _bob.material_override as StandardMaterial3D
	mat.emission_energy_multiplier = 0.8

func release():
	_is_grabbed = false
	released.emit()
	
	# Visual feedback
	var mat = _bob.material_override as StandardMaterial3D
	mat.emission_energy_multiplier = 0.4

func push(impulse: float):
	# Add angular velocity (for VR swing gesture)
	_angular_velocity += impulse

# For manual control (click/drag or XR grab)
func set_angle_from_position(world_pos: Vector3):
	var local_pos = to_local(world_pos)
	_angle = atan2(local_pos.x, -local_pos.y)
	_angle = clampf(_angle, -PI * 0.45, PI * 0.45)
