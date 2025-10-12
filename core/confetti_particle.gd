class_name ConfettiParticle
extends Particle

## Confetti Particle - Polymorphism example
## Chapter 04: Particle Systems
## Specialized particle that spins and uses box shape

# Rotation properties
var angular_velocity: Vector3 = Vector3.ZERO
var angular_acceleration: Vector3 = Vector3.ZERO

func _init(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO):
	super(pos, vel)

	# Random angular velocity for spinning
	angular_velocity = Vector3(
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0)
	)

	# Smaller size for confetti
	size = randf_range(0.03, 0.06)

func _ready():
	super()
	# Override visual with box mesh for confetti
	create_confetti_visual()

func create_confetti_visual():
	"""Create rectangular confetti piece"""
	# Remove old mesh if exists
	if mesh_instance:
		mesh_instance.queue_free()

	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()

	# Thin rectangular shape
	box.size = Vector3(
		size * randf_range(1.5, 3.0),  # Width
		size * 0.3,                     # Thickness
		size * randf_range(1.0, 2.0)   # Depth
	)
	mesh_instance.mesh = box

	material = StandardMaterial3D.new()

	# Random bright color
	var colors = [
		Color(1.0, 0.6, 1.0, 1.0),   # Pink
		Color(0.5, 0.5, 1.0, 1.0),   # Blue
		Color(0.5, 1.0, 0.5, 1.0),   # Green
		Color(1.0, 1.0, 0.5, 1.0),   # Yellow
		Color(1.0, 0.5, 0.5, 1.0),   # Red
		Color(0.5, 1.0, 1.0, 1.0),   # Cyan
	]

	var color = colors[randi() % colors.size()]
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.6
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.5
	material.roughness = 0.3

	mesh_instance.material_override = material
	add_child(mesh_instance)

func update(delta: float):
	"""Update confetti with rotation"""
	# Call parent update
	super.update(delta)

	# Update rotation
	angular_velocity += angular_acceleration * delta
	rotation += angular_velocity * delta

	# Apply air resistance to rotation
	angular_velocity *= 0.98

	# Clear angular acceleration
	angular_acceleration = Vector3.ZERO

func apply_force(force: Vector3):
	"""Apply force (also creates torque for rotation)"""
	super.apply_force(force)

	# Random torque from force
	var torque = force.cross(Vector3.UP) * 0.5
	angular_acceleration += torque
