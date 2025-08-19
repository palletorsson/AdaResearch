extends Node3D

class_name FluidSimParticle

var velocity: Vector3 = Vector3.ZERO
var current_force: Vector3 = Vector3.ZERO
var density: float = 0.0
var mass: float = 1.0

func _ready():
	_create_particle_mesh()

func _create_particle_mesh():
	# Create the fluid particle sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.15
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 0.5, 1, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0, 0.5, 1, 0.3)
	
	sphere.material = material
	add_child(sphere)

func apply_force(force: Vector3):
	current_force += force

func update_physics(delta: float, gravity: Vector3):
	# Apply gravity
	current_force += gravity * mass
	
	# Apply force to velocity (F = ma)
	velocity += current_force / mass * delta
	
	# Apply damping
	velocity *= 0.98
	
	# Update position
	position += velocity * delta
	
	# Reset force for next frame
	current_force = Vector3.ZERO
	
	# Update particle appearance based on density
	_update_appearance()

func _update_appearance():
	# Change particle size and color based on density
	var sphere = get_child(0) as CSGSphere3D
	var material = sphere.material as StandardMaterial3D
	
	# Scale based on density
	var density_ratio = density / 1000.0  # Normalize to rest density
	var scale_factor = clamp(density_ratio * 0.5 + 0.5, 0.3, 1.5)
	sphere.scale = Vector3.ONE * scale_factor
	
	# Color based on density
	var color = Color.WHITE
	if density_ratio > 1.2:
		color = Color.BLUE  # High density
	elif density_ratio < 0.8:
		color = Color.CYAN  # Low density
	else:
		color = Color(0, 0.5, 1, 0.8)  # Normal density
	
	material.albedo_color = color
	material.emission = color * 0.3
