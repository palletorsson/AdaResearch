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

# Agent-PerformanceEngineer: MultiMesh instancing (Phase 2)
# NOTE: Disabled by default until ParticleResources singleton is set up as autoload
@export var use_instancing: bool = false  # Enable MultiMesh optimization
var multimesh_instance: MultiMeshInstance3D = null
var available_instance_ids: Array[int] = []  # Pool of reusable instance IDs
var next_instance_id: int = 0

func _ready():
	# Create container for organized scene tree
	particle_container = Node3D.new()
	particle_container.name = "Particles"
	add_child(particle_container)
	
	# Agent-PerformanceEngineer: Initialize MultiMesh if instancing enabled
	if use_instancing:
		setup_multimesh()

func setup_multimesh():
	"""Initialize MultiMesh for instanced rendering"""
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "ParticleInstances"
	
	# Create MultiMesh with shared sphere mesh
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = max_particles
	multimesh.visible_instance_count = 0  # Start with 0 visible
	multimesh.mesh = ParticleResources.get_sphere_mesh()
	
	# Enable per-instance data
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	
	multimesh_instance.multimesh = multimesh
	multimesh_instance.material_override = ParticleResources.get_particle_material()
	
	add_child(multimesh_instance)
	
	print("ParticleEmitter: MultiMesh instancing enabled (%d max instances)" % max_particles)

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
	particle.max_lifespan = particle_lifetime  # Already in seconds
	particle.lifespan = particle.max_lifespan
	particle.primary_pink = particle_color
	
	# Agent-PerformanceEngineer: Configure for MultiMesh if enabled
	if use_instancing and multimesh_instance:
		particle.use_multimesh = true
		particle.multimesh_instance = multimesh_instance
		
		# Assign instance ID (reuse from pool or create new)
		if available_instance_ids.size() > 0:
			particle.instance_id = available_instance_ids.pop_back()
		else:
			particle.instance_id = next_instance_id
			next_instance_id += 1
		
		# Increment visible instance count
		multimesh_instance.multimesh.visible_instance_count = min(
			multimesh_instance.multimesh.visible_instance_count + 1,
			max_particles
		)

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
	"""Remove dead particles (optimized O(n) swap-and-pop)"""
	# Agent-PerformanceEngineer: Replaced O(n²) nested loop with O(n) algorithm
	var i = 0
	while i < particles.size():
		if particles[i].is_dead():
			# Agent-PerformanceEngineer: Recycle instance ID if using MultiMesh
			if use_instancing and particles[i].instance_id >= 0:
				available_instance_ids.append(particles[i].instance_id)
				
				# Hide this instance (move far away)
				if multimesh_instance:
					multimesh_instance.multimesh.set_instance_transform(
						particles[i].instance_id,
						Transform3D(Basis(), Vector3(1000, 1000, 1000))  # Far away
					)
			
			# Free the particle
			particles[i].queue_free()
			
			# Swap with last element (O(1))
			particles[i] = particles[particles.size() - 1]
			
			# Remove last element (O(1))
			particles.pop_back()
			
			# Don't increment i - check the swapped element next
		else:
			i += 1

func clear_particles():
	"""Remove all particles"""
	for particle in particles:
		particle.queue_free()
	particles.clear()

func get_particle_count() -> int:
	"""Get current number of particles"""
	return particles.size()
