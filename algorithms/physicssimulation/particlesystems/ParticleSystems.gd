extends Node3D

@export var max_particles: int = 200
@export var emission_rate: float = 10.0
@export var particle_lifetime: float = 3.0
@export var particle_speed: float = 2.0
@export var gravity_strength: float = 9.8
@export var wind_strength: float = 1.0
@export var turbulence_strength: float = 0.5

class Particle:
	var position: Vector3
	var velocity: Vector3
	var lifetime: float
	var max_lifetime: float
	var size: float
	var color: Color
	var node: CSGSphere3D
	var trail: Array[Vector3] = []
	
	func _init(pos: Vector3, vel: Vector3, life: float, s: float, c: Color, n: CSGSphere3D):
		position = pos
		velocity = vel
		lifetime = life
		max_lifetime = life
		size = s
		color = c
		node = n
		trail = []
	
	func update(delta: float):
		lifetime -= delta
		position += velocity * delta
		
		# Update visual node
		if node:
			node.position = position
			node.scale = Vector3.ONE * (size * (lifetime / max_lifetime))
			
			# Fade out based on lifetime
			var alpha = lifetime / max_lifetime
			node.material.albedo_color.a = alpha
			node.material.emission.a = alpha
	
	func is_dead() -> bool:
		return lifetime <= 0

var smoke_particles: Array[Particle] = []
var fire_particles: Array[Particle] = []
var spark_particles: Array[Particle] = []
var weather_particles: Array[Particle] = []

var smoke_emitter_pos: Vector3
var fire_emitter_pos: Vector3
var spark_emitter_pos: Vector3
var weather_emitter_pos: Vector3

var time: float = 0.0
var emission_timer: float = 0.0

func _ready():
	smoke_emitter_pos = $ParticleEmitters/SmokeEmitter.global_position
	fire_emitter_pos = $ParticleEmitters/FireEmitter.global_position
	spark_emitter_pos = $ParticleEmitters/SparkEmitter.global_position
	weather_emitter_pos = $ParticleEmitters/WeatherEmitter.global_position
	
	# Initialize particle systems
	initialize_particle_systems()

func initialize_particle_systems():
	# Create initial particles for each system
	for i in range(max_particles // 4):
		create_smoke_particle()
		create_fire_particle()
		create_spark_particle()
		create_weather_particle()

func create_smoke_particle() -> Particle:
	var pos = smoke_emitter_pos + Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1)
	)
	
	var vel = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(1.0, 3.0),
		randf_range(-0.5, 0.5)
	)
	
	var size = randf_range(0.05, 0.15)
	var color = Color(0.5, 0.5, 0.5, 0.8)
	var node = create_particle_node(color, size)
	
	var particle = Particle.new(pos, vel, particle_lifetime * 2.0, size, color, node)
	$ParticleEmitters/SmokeEmitter/SmokeParticles.add_child(node)
	smoke_particles.append(particle)
	
	return particle

func create_fire_particle() -> Particle:
	var pos = fire_emitter_pos + Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1)
	)
	
	var vel = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(2.0, 5.0),
		randf_range(-1.0, 1.0)
	)
	
	var size = randf_range(0.03, 0.1)
	var color = Color(1.0, 0.3, 0.0, 1.0)
	var node = create_particle_node(color, size)
	
	var particle = Particle.new(pos, vel, particle_lifetime * 0.5, size, color, node)
	$ParticleEmitters/FireEmitter/FireParticles.add_child(node)
	fire_particles.append(particle)
	
	return particle

func create_spark_particle() -> Particle:
	var pos = spark_emitter_pos + Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1)
	)
	
	var vel = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(1.0, 4.0),
		randf_range(-3.0, 3.0)
	)
	
	var size = randf_range(0.02, 0.06)
	var color = Color(1.0, 1.0, 0.0, 1.0)
	var node = create_particle_node(color, size)
	
	var particle = Particle.new(pos, vel, particle_lifetime * 0.3, size, color, node)
	$ParticleEmitters/SparkEmitter/SparkParticles.add_child(node)
	spark_particles.append(particle)
	
	return particle

func create_weather_particle() -> Particle:
	var pos = weather_emitter_pos + Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-0.1, 0.1),
		randf_range(-0.5, 0.5)
	)
	
	var vel = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-2.0, -1.0),
		randf_range(-0.5, 0.5)
	)
	
	var size = randf_range(0.02, 0.08)
	var color = Color(0.7, 0.7, 1.0, 0.6)
	var node = create_particle_node(color, size)
	
	var particle = Particle.new(pos, vel, particle_lifetime * 1.5, size, color, node)
	$ParticleEmitters/WeatherEmitter/WeatherParticles.add_child(node)
	weather_particles.append(particle)
	
	return particle

func create_particle_node(color: Color, size: float) -> CSGSphere3D:
	var node = CSGSphere3D.new()
	node.radius = size
	node.material = StandardMaterial3D.new()
	node.material.albedo_color = color
	node.material.emission_enabled = true
	node.material.emission = color
	node.material.emission_energy_multiplier = 0.3
	return node

func _process(delta):
	time += delta
	emission_timer += delta
	
	# Emit new particles
	if emission_timer >= 1.0 / emission_rate:
		emission_timer = 0.0
		emit_new_particles()
	
	# Update all particle systems
	update_particle_system(smoke_particles, delta)
	update_particle_system(fire_particles, delta)
	update_particle_system(spark_particles, delta)
	update_particle_system(weather_particles, delta)
	
	# Animate emitters
	animate_emitters(delta)
	
	# Update particle controls
	animate_particle_controls(delta)
	
	# Handle environment collisions
	handle_environment_collisions()

func emit_new_particles():
	# Emit new particles if we have room
	if smoke_particles.size() < max_particles // 4:
		create_smoke_particle()
	if fire_particles.size() < max_particles // 4:
		create_fire_particle()
	if spark_particles.size() < max_particles // 4:
		create_spark_particle()
	if weather_particles.size() < max_particles // 4:
		create_weather_particle()

func update_particle_system(particles: Array[Particle], delta: float):
	var dead_particles: Array[Particle] = []
	
	for particle in particles:
		# Apply forces
		apply_particle_forces(particle, delta)
		
		# Update particle
		particle.update(delta)
		
		# Check if particle is dead
		if particle.is_dead():
			dead_particles.append(particle)
	
	# Remove dead particles
	for dead_particle in dead_particles:
		particles.erase(dead_particle)
		if dead_particle.node:
			dead_particle.node.queue_free()

func apply_particle_forces(particle: Particle, delta: float):
	# Apply gravity
	particle.velocity.y -= gravity_strength * delta
	
	# Apply wind
	var wind_force = Vector3(
		sin(time * 0.5) * wind_strength,
		0,
		cos(time * 0.3) * wind_strength
	)
	particle.velocity += wind_force * delta
	
	# Apply turbulence
	var turbulence = Vector3(
		sin(time * 2.0 + particle.position.x) * turbulence_strength,
		cos(time * 1.5 + particle.position.y) * turbulence_strength,
		sin(time * 2.5 + particle.position.z) * turbulence_strength
	)
	particle.velocity += turbulence * delta
	
	# Apply damping
	particle.velocity *= 0.99

func animate_emitters(delta: float):
	# Animate smoke emitter
	var smoke_source = $ParticleEmitters/SmokeEmitter/SmokeSource
	smoke_source.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.2)
	smoke_source.rotation.y += delta * 2.0
	
	# Animate fire emitter
	var fire_source = $ParticleEmitters/FireEmitter/FireSource
	fire_source.scale = Vector3.ONE * (1.0 + sin(time * 5.0) * 0.3)
	fire_source.material.emission_energy_multiplier = 0.5 + sin(time * 8.0) * 0.3
	
	# Animate spark emitter
	var spark_source = $ParticleEmitters/SparkEmitter/SparkSource
	spark_source.scale = Vector3.ONE * (1.0 + sin(time * 4.0) * 0.2)
	spark_source.rotation.z += delta * 3.0
	
	# Animate weather emitter
	var weather_source = $ParticleEmitters/WeatherEmitter/WeatherSource
	weather_source.position.y = weather_emitter_pos.y + sin(time * 0.5) * 0.3
	weather_source.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.1)

func animate_particle_controls(delta: float):
	# Animate emission rate control
	var emission_rate_node = $ParticleControls/EmissionRate
	emission_rate_node.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.1)
	emission_rate_node.rotation.y += delta * 1.0
	
	# Animate particle lifetime control
	var particle_lifetime_node = $ParticleControls/ParticleLifetime
	particle_lifetime_node.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.1)
	particle_lifetime_node.rotation.z += delta * 1.5
	
	# Animate particle speed control
	var particle_speed_node = $ParticleControls/ParticleSpeed
	particle_speed_node.scale = Vector3.ONE * (1.0 + sin(time * 4.0) * 0.1)
	particle_speed_node.rotation.x += delta * 2.0

func handle_environment_collisions():
	# Handle collisions with environment boundaries
	var boundary_min = Vector3(-5, -2, -5)
	var boundary_max = Vector3(5, 4, 5)
	
	handle_boundary_collisions(smoke_particles, boundary_min, boundary_max)
	handle_boundary_collisions(fire_particles, boundary_min, boundary_max)
	handle_boundary_collisions(spark_particles, boundary_min, boundary_max)
	handle_boundary_collisions(weather_particles, boundary_min, boundary_max)

func handle_boundary_collisions(particles: Array[Particle], min_bound: Vector3, max_bound: Vector3):
	for particle in particles:
		var new_pos = particle.position
		var new_vel = particle.velocity
		
		# Check X boundaries
		if particle.position.x < min_bound.x:
			new_pos.x = min_bound.x
			new_vel.x = -new_vel.x * 0.5
		elif particle.position.x > max_bound.x:
			new_pos.x = max_bound.x
			new_vel.x = -new_vel.x * 0.5
		
		# Check Y boundaries
		if particle.position.y < min_bound.y:
			new_pos.y = min_bound.y
			new_vel.y = -new_vel.y * 0.3
		elif particle.position.y > max_bound.y:
			new_pos.y = max_bound.y
			new_vel.y = -new_vel.y * 0.5
		
		# Check Z boundaries
		if particle.position.z < min_bound.z:
			new_pos.z = min_bound.z
			new_vel.z = -new_vel.z * 0.5
		elif particle.position.z > max_bound.z:
			new_pos.z = max_bound.z
			new_vel.z = -new_vel.z * 0.5
		
		particle.position = new_pos
		particle.velocity = new_vel
