class_name ParticleEmitter
extends Node3D

## Particle Emitter for Nature of Code VR
## Chapter 04: Particle Systems
## Emits and manages a collection of particles

# Particle management
var particles: Array[Particle] = []
@export var max_particles: int = 100
@export var emission_rate: float = 10.0  # particles per second
var emission_timer: float = 0.0

# Particle properties
@export var particle_lifetime: float = 4.0
@export var particle_size: float = 0.05
@export var initial_velocity: Vector3 = Vector3(0, 1, 0)
@export var velocity_randomness: float = 0.5

# Forces
@export var gravity: Vector3 = Vector3(0, -1.0, 0)
@export var wind: Vector3 = Vector3.ZERO

# Color
@export var particle_color: Color = Color(1.0, 0.6, 1.0, 1.0)

# Container for particles
var particle_container: Node3D

func _ready():
	# Create container for organized scene tree
	particle_container = Node3D.new()
	particle_container.name = "Particles"
	add_child(particle_container)

func _process(delta):
	# Emit new particles
	emission_timer += delta
	while emission_timer >= 1.0 / emission_rate and particles.size() < max_particles:
		emission_timer -= 1.0 / emission_rate
		emit_particle()

	# Update all particles
	update_particles(delta)

	# Clean up dead particles
	cleanup_dead_particles()

func emit_particle():
	"""Create and emit a new particle"""
	# Create particle
	var particle = create_particle()

	# Add to scene
	particle_container.add_child(particle)
	particles.append(particle)

func create_particle() -> Particle:
	"""Create a new particle instance (override for custom particles)"""
	# Random velocity variation
	var vel = initial_velocity + Vector3(
		randf_range(-velocity_randomness, velocity_randomness),
		randf_range(-velocity_randomness, velocity_randomness),
		randf_range(-velocity_randomness, velocity_randomness)
	)

	# Create particle at emitter position
	var particle = Particle.new(global_position, vel)
	particle.size = particle_size
	particle.max_lifespan = particle_lifetime * 60.0  # Convert to frames
	particle.lifespan = particle.max_lifespan
	particle.primary_pink = particle_color

	return particle

func update_particles(delta: float):
	"""Update all particles"""
	for particle in particles:
		# Apply forces
		particle.apply_force(gravity)
		particle.apply_force(wind)

		# Update particle
		particle.update(delta)

func cleanup_dead_particles():
	"""Remove dead particles"""
	var dead_particles: Array[Particle] = []

	for particle in particles:
		if particle.is_dead():
			dead_particles.append(particle)

	for particle in dead_particles:
		particles.erase(particle)
		particle.queue_free()

func clear_particles():
	"""Remove all particles"""
	for particle in particles:
		particle.queue_free()
	particles.clear()

func get_particle_count() -> int:
	"""Get current number of particles"""
	return particles.size()
