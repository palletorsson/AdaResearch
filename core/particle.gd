class_name Particle
extends Node3D

## Base Particle class for Nature of Code VR
## Chapter 04: Particle Systems
## Simple particle with physics (position, velocity, acceleration)

# Physics properties
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var mass: float = 1.0

# Agent-ParticlePhysicist: Parametric physics controls for pedagogy
@export var damping: float = 0.98  # Air resistance (0.0 = full drag, 1.0 = no drag)
@export var restitution: float = 0.5  # Bounce coefficient (0.0 = no bounce, 1.0 = perfect bounce)

# Lifespan (in seconds, frame-rate independent!)
var lifespan: float = 4.0
var max_lifespan: float = 4.0
@export var decay_rate: float = 1.0  # Units per second

# Visual properties (legacy - kept for compatibility)
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var size: float = 0.05

# Agent-PerformanceEngineer: MultiMesh instancing support
var multimesh_instance: MultiMeshInstance3D = null
var instance_id: int = -1
var use_multimesh: bool = false  # Set by emitter

# Pink color palette
var primary_pink: Color = Color(1.0, 0.6, 1.0, 1.0)

# Fish tank reference
var fish_tank: Node3D = null

func _init(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO):
	position = pos
	velocity = vel
	acceleration = Vector3.ZERO
	lifespan = 4.0  # 4 seconds
	max_lifespan = 4.0

func _ready():
	# Find fish tank
	find_fish_tank()

	# Create visual representation
	# Agent-PerformanceEngineer: Only create legacy mesh if not using MultiMesh
	if not use_multimesh and not mesh_instance:
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
	# Agent-ParticlePhysicist: Apply damping (air resistance)
	velocity *= damping
	
	# Update velocity
	velocity += acceleration * delta

	# Update position
	position += velocity * delta

	# Decrease lifespan (frame-rate independent!)
	lifespan -= decay_rate * delta

	# Clear acceleration for next frame
	acceleration = Vector3.ZERO

	# Update visual appearance
	update_visual()

func update_visual():
	"""Update visual based on lifespan"""
	var alpha = lifespan / max_lifespan
	
	# Agent-PerformanceEngineer: MultiMesh mode
	if use_multimesh and multimesh_instance and instance_id >= 0:
		# Update transform
		multimesh_instance.multimesh.set_instance_transform(instance_id, Transform3D(Basis(), global_position))
		
		# Update color/alpha via instance color
		var color = primary_pink
		color.a = alpha
		multimesh_instance.multimesh.set_instance_color(instance_id, color)
		
		# Store emission strength in custom data (x component)
		var custom_data = Color(alpha, 0, 0, 0)  # Use alpha for emission strength
		multimesh_instance.multimesh.set_instance_custom_data(instance_id, custom_data)
	
	# Legacy material mode
	elif material:
		# Fade out as particle dies
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
		# Agent-ParticlePhysicist: Parametric bounce with restitution coefficient
		velocity *= -restitution
