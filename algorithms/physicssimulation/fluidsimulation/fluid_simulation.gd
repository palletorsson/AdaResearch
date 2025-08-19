extends Node3D

# Simple Fluid Simulation using Particle-Based Method
# Demonstrates basic fluid dynamics with attraction/repulsion forces

@export_category("Fluid Parameters")
@export var particle_count: int = 200
@export var container_size: Vector3 = Vector3(10, 8, 10)
@export var gravity: float = -9.8
@export var viscosity: float = 0.8
@export var surface_tension: float = 2.0
@export var pressure_force: float = 1.5

@export_category("Particle Properties")
@export var particle_radius: float = 0.1
@export var particle_mass: float = 1.0
@export var interaction_radius: float = 0.5
@export var rest_density: float = 1.0

@export_category("Visualization")
@export var show_particles: bool = true
@export var show_forces: bool = false
@export var color_by_velocity: bool = true
@export var particle_trails: bool = false

# Simulation state
var particles: Array = []
var container_walls: Array = []
var time_step: float = 0.016  # ~60 FPS

# Visual elements
var particle_meshes: Array = []
var container_mesh: MeshInstance3D
var force_lines: Array = []

# Particle class
class FluidParticle:
	var position: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var density: float = 1.0
	var pressure: float = 0.0
	var mass: float = 1.0
	var radius: float = 0.1
	var mesh_instance: MeshInstance3D
	var neighbors: Array = []
	
	func _init(pos: Vector3, m: float, r: float):
		position = pos
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		mass = m
		radius = r
	
	func apply_force(force: Vector3):
		acceleration += force / mass
	
	func update(delta: float):
		# Integrate using Verlet integration for stability
		velocity += acceleration * delta
		position += velocity * delta
		
		# Reset acceleration for next frame
		acceleration = Vector3.ZERO
	
	func calculate_density(all_particles: Array, interaction_radius: float):
		density = 0.0
		neighbors.clear()
		
		for other in all_particles:
			if other == self:
				continue
			
			var distance = position.distance_to(other.position)
			if distance < interaction_radius:
				neighbors.append(other)
				# Simple density kernel
				var influence = max(0, interaction_radius - distance)
				density += other.mass * influence * influence
	
	func calculate_pressure(rest_density: float, pressure_constant: float = 1.0):
		pressure = pressure_constant * (density - rest_density)

func _ready():
	setup_environment()
	initialize_particles()
	create_container()
	setup_camera()

func _process(delta):
	simulate_fluid(delta)
	update_visuals()

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.15)
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

func initialize_particles():
	particles.clear()
	particle_meshes.clear()
	
	# Create particles in a grid formation inside container
	var spacing = particle_radius * 2.5
	var particles_per_row = int(container_size.x / spacing)
	var particles_per_column = int(container_size.z / spacing)
	var layers = int(min(particle_count / (particles_per_row * particles_per_column), container_size.y / spacing))
	
	var created_particles = 0
	
	for layer in range(layers):
		for row in range(particles_per_row):
			for col in range(particles_per_column):
				if created_particles >= particle_count:
					break
				
				var pos = Vector3(
					-container_size.x/2 + spacing * row + spacing/2,
					-container_size.y/2 + spacing * layer + spacing/2,
					-container_size.z/2 + spacing * col + spacing/2
				)
				
				var particle = FluidParticle.new(pos, particle_mass, particle_radius)
				particles.append(particle)
				
				if show_particles:
					create_particle_visual(particle)
				
				created_particles += 1

func create_particle_visual(particle: FluidParticle):
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = particle.radius
	sphere.height = particle.radius * 2
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.9, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.1, 0.3, 0.5)
	mesh_instance.material_override = material
	
	mesh_instance.position = particle.position
	particle.mesh_instance = mesh_instance
	add_child(mesh_instance)
	particle_meshes.append(mesh_instance)

func create_container():
	# Create container walls as invisible collision boundaries
	container_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = container_size
	container_mesh.mesh = box
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.2, 0.3, 0.1)
	material.flags_unshaded = true
	container_mesh.material_override = material
	
	add_child(container_mesh)

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 5, 15)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)

func simulate_fluid(delta):
	# Use fixed time step for stability
	var fixed_delta = time_step
	
	# Calculate densities and pressures
	for particle in particles:
		particle.calculate_density(particles, interaction_radius)
		particle.calculate_pressure(rest_density)
	
	# Apply forces
	for particle in particles:
		apply_gravity(particle)
		apply_pressure_forces(particle)
		apply_viscosity_forces(particle)
		apply_surface_tension(particle)
	
	# Update particle positions
	for particle in particles:
		particle.update(fixed_delta)
		apply_boundary_constraints(particle)

func apply_gravity(particle: FluidParticle):
	var gravity_force = Vector3(0, gravity * particle.mass, 0)
	particle.apply_force(gravity_force)

func apply_pressure_forces(particle: FluidParticle):
	for neighbor in particle.neighbors:
		var direction = particle.position - neighbor.position
		var distance = direction.length()
		
		if distance > 0:
			direction = direction.normalized()
			var pressure_diff = particle.pressure + neighbor.pressure
			var force_magnitude = pressure_diff * pressure_force / (distance * distance)
			particle.apply_force(direction * force_magnitude)

func apply_viscosity_forces(particle: FluidParticle):
	var viscosity_force = Vector3.ZERO
	
	for neighbor in particle.neighbors:
		var velocity_diff = neighbor.velocity - particle.velocity
		var distance = particle.position.distance_to(neighbor.position)
		
		if distance > 0:
			var influence = max(0, interaction_radius - distance)
			viscosity_force += velocity_diff * influence * viscosity
	
	particle.apply_force(viscosity_force)

func apply_surface_tension(particle: FluidParticle):
	if particle.neighbors.size() < 6:  # Surface particles have fewer neighbors
		var surface_normal = Vector3.ZERO
		
		for neighbor in particle.neighbors:
			var direction = particle.position - neighbor.position
			surface_normal += direction.normalized()
		
		if surface_normal.length() > 0:
			surface_normal = surface_normal.normalized()
			particle.apply_force(surface_normal * surface_tension)

func apply_boundary_constraints(particle: FluidParticle):
	var half_size = container_size / 2
	var damping = 0.7  # Energy loss on collision
	
	# X boundaries
	if particle.position.x < -half_size.x + particle.radius:
		particle.position.x = -half_size.x + particle.radius
		particle.velocity.x = abs(particle.velocity.x) * damping
	elif particle.position.x > half_size.x - particle.radius:
		particle.position.x = half_size.x - particle.radius
		particle.velocity.x = -abs(particle.velocity.x) * damping
	
	# Y boundaries
	if particle.position.y < -half_size.y + particle.radius:
		particle.position.y = -half_size.y + particle.radius
		particle.velocity.y = abs(particle.velocity.y) * damping
	elif particle.position.y > half_size.y - particle.radius:
		particle.position.y = half_size.y - particle.radius
		particle.velocity.y = -abs(particle.velocity.y) * damping
	
	# Z boundaries
	if particle.position.z < -half_size.z + particle.radius:
		particle.position.z = -half_size.z + particle.radius
		particle.velocity.z = abs(particle.velocity.z) * damping
	elif particle.position.z > half_size.z - particle.radius:
		particle.position.z = half_size.z - particle.radius
		particle.velocity.z = -abs(particle.velocity.z) * damping

func update_visuals():
	for i in range(particles.size()):
		var particle = particles[i]
		if particle.mesh_instance:
			particle.mesh_instance.position = particle.position
			
			# Color by velocity if enabled
			if color_by_velocity:
				var speed = particle.velocity.length()
				var normalized_speed = clamp(speed / 5.0, 0.0, 1.0)  # Normalize to 0-1
				
				var material = particle.mesh_instance.material_override
				material.albedo_color = Color(
					0.3 + normalized_speed * 0.7,  # More red with higher speed
					0.6 - normalized_speed * 0.3,  # Less green with higher speed
					0.9 - normalized_speed * 0.4,  # Less blue with higher speed
					0.8
				) 