extends Node3D

class_name MassPoint

var is_fixed: bool = false
var initial_position: Vector3
var velocity: Vector3 = Vector3.ZERO
var current_force: Vector3 = Vector3.ZERO
var damping: float = 0.8
var mass: float = 1.0

func _ready():
	initial_position = position
	_create_mass_point_mesh()

func _create_mass_point_mesh():
	# Create the mass point sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.1
	
	var material = StandardMaterial3D.new()
	if is_fixed:
		material.albedo_color = Color.RED
		material.emission_enabled = true
		material.emission = Color.RED * 0.3
	else:
		material.albedo_color = Color.BLUE
		material.emission_enabled = true
		material.emission = Color.BLUE * 0.2
	
	sphere.material = material
	add_child(sphere)

func apply_force(force: Vector3):
	current_force += force

func update_physics(delta: float, gravity: Vector3):
	if is_fixed:
		return
	
	# Apply gravity
	current_force += gravity * mass
	
	# Apply force to velocity (F = ma)
	velocity += current_force / mass * delta
	
	# Apply damping
	velocity *= damping
	
	# Update position
	position += velocity * delta
	
	# Reset force for next frame
	current_force = Vector3.ZERO

func reset_to_initial():
	position = initial_position
	velocity = Vector3.ZERO
	current_force = Vector3.ZERO
