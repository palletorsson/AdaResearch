class_name Particle
extends Node3D

## Base Particle class for Nature of Code VR
## Chapter 04: Particle Systems
## Simple particle with physics (position, velocity, acceleration)

# Physics properties
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var mass: float = 1.0

# Lifespan (decreases over time, 0 = dead)
var lifespan: float = 255.0
var max_lifespan: float = 255.0

# Visual properties
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var size: float = 0.05

# Pink color palette
var primary_pink: Color = Color(1.0, 0.6, 1.0, 1.0)

# Fish tank reference
var fish_tank: Node3D = null

func _init(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO):
	position = pos
	velocity = vel
	acceleration = Vector3.ZERO
	lifespan = 255.0
	max_lifespan = 255.0

func _ready():
	# Find fish tank
	find_fish_tank()

	# Create visual representation
	if not mesh_instance:
		create_default_visual()

func find_fish_tank():
	"""Find FishTank parent in scene tree"""
	var node = get_parent()
	while node:
		if node.has_method("constrain_position"):  # Duck typing for FishTank
			fish_tank = node
			return
		node = node.get_parent()

func create_default_visual():
	"""Create default sphere mesh"""
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	mesh_instance.mesh = sphere

	material = StandardMaterial3D.new()
	material.albedo_color = primary_pink
	material.emission_enabled = true
	material.emission = primary_pink * 0.5
	material.emission_energy_multiplier = 0.6
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	mesh_instance.material_override = material
	add_child(mesh_instance)

func update(delta: float):
	"""Update particle physics"""
	# Update velocity
	velocity += acceleration * delta

	# Update position
	position += velocity * delta

	# Decrease lifespan
	lifespan -= delta * 60.0  # ~60 fps normalized

	# Clear acceleration for next frame
	acceleration = Vector3.ZERO

	# Update visual appearance
	update_visual()

func update_visual():
	"""Update visual based on lifespan"""
	if material:
		# Fade out as particle dies
		var alpha = lifespan / max_lifespan
		var color = primary_pink
		color.a = alpha
		material.albedo_color = color

		var emission = primary_pink * 0.5
		emission.a = alpha
		material.emission = emission

func apply_force(force: Vector3):
	"""Apply force to particle (F = ma, so a = F/m)"""
	var f = force / mass
	acceleration += f

func is_dead() -> bool:
	"""Check if particle should be removed"""
	return lifespan <= 0.0

func constrain_to_tank():
	"""Keep particle inside fish tank boundaries"""
	if not fish_tank:
		return

	var constrained = fish_tank.constrain_position(position)
	if constrained != position:
		position = constrained
		# Bounce off boundaries
		velocity *= -0.5
