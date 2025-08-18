extends Node3D

var time = 0.0
var particles = []
var landscape_nodes = []
var particle_count = 25
var search_space = 8.0
var landscape_size = 20

# PSO parameters
var inertia_weight = 0.7
var cognitive_coefficient = 1.5
var social_coefficient = 1.5
var global_best_position = Vector2.ZERO
var global_best_fitness = -INF

class Particle:
	var position: Vector2
	var velocity: Vector2
	var personal_best_position: Vector2
	var personal_best_fitness: float
	var visual_object: CSGSphere3D
	
	func _init(start_pos: Vector2):
		position = start_pos
		velocity = Vector2(randf() * 2 - 1, randf() * 2 - 1)
		personal_best_position = start_pos
		personal_best_fitness = -INF

func _ready():
	create_fitness_landscape()
	create_particles()
	setup_materials()

func create_fitness_landscape():
	var landscape_parent = $FitnessLandscape
	
	for x in range(landscape_size):
		landscape_nodes.append([])
		for y in range(landscape_size):
			var landscape_point = CSGSphere3D.new()
			landscape_point.radius = 0.05
			
			var world_x = -search_space + (x / float(landscape_size - 1)) * 2 * search_space
			var world_y = -search_space + (y / float(landscape_size - 1)) * 2 * search_space
			var fitness = fitness_function(Vector2(world_x, world_y))
			
			landscape_point.position = Vector3(world_x, world_y, fitness * 0.5 - 1)
			landscape_parent.add_child(landscape_point)
			landscape_nodes[x].append(landscape_point)

func create_particles():
	var particle_parent = $Particles
	
	for i in range(particle_count):
		var start_pos = Vector2(
			randf() * 2 * search_space - search_space,
			randf() * 2 * search_space - search_space
		)
		
		var particle = Particle.new(start_pos)
		
		# Create visual representation
		var particle_sphere = CSGSphere3D.new()
		particle_sphere.radius = 0.1
		particle_sphere.position = Vector3(start_pos.x, start_pos.y, 1)
		particle_parent.add_child(particle_sphere)
		particle.visual_object = particle_sphere
		
		particles.append(particle)

func setup_materials():
	# Landscape materials (height-based coloring)
	for x in range(landscape_size):
		for y in range(landscape_size):
			var point = landscape_nodes[x][y]
			var height = point.position.z + 1  # Normalize height
			
			var landscape_material = StandardMaterial3D.new()
			landscape_material.albedo_color = Color(
				height * 0.8,
				0.3 + (1.0 - height) * 0.7,
				0.2 + height * 0.6,
				0.8
			)
			landscape_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			landscape_material.emission_enabled = true
			landscape_material.emission = landscape_material.albedo_color * 0.3
			point.material_override = landscape_material
	
	# Particle materials
	var particle_material = StandardMaterial3D.new()
	particle_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	particle_material.emission_enabled = true
	particle_material.emission = Color(0.3, 0.1, 0.5, 1.0)
	
	for particle in particles:
		particle.visual_object.material_override = particle_material
	
	# Global best material
	var global_best_material = StandardMaterial3D.new()
	global_best_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	global_best_material.emission_enabled = true
	global_best_material.emission = Color(0.8, 0.4, 0.1, 1.0)
	$GlobalBest.material_override = global_best_material
	
	# Control materials
	var inertia_material = StandardMaterial3D.new()
	inertia_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	inertia_material.emission_enabled = true
	inertia_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$InertiaWeight.material_override = inertia_material
	
	var convergence_material = StandardMaterial3D.new()
	convergence_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	convergence_material.emission_enabled = true
	convergence_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$SwarmConvergence.material_override = convergence_material

func _process(delta):
	time += delta
	
	# Update PSO parameters
	inertia_weight = 0.9 - 0.4 * sin(time * 0.2)  # Decreasing inertia over time
	
	update_particles(delta)
	animate_swarm()
	animate_indicators()

func update_particles(delta):
	# Update each particle
	for particle in particles:
		# Calculate fitness
		var current_fitness = fitness_function(particle.position)
		
		# Update personal best
		if current_fitness > particle.personal_best_fitness:
			particle.personal_best_fitness = current_fitness
			particle.personal_best_position = particle.position
		
		# Update global best
		if current_fitness > global_best_fitness:
			global_best_fitness = current_fitness
			global_best_position = particle.position
		
		# Update velocity (PSO formula)
		var r1 = randf()
		var r2 = randf()
		
		var cognitive_component = (particle.personal_best_position - particle.position) * cognitive_coefficient * r1
		var social_component = (global_best_position - particle.position) * social_coefficient * r2
		
		particle.velocity = particle.velocity * inertia_weight + cognitive_component + social_component
		
		# Limit velocity
		var max_velocity = 2.0
		if particle.velocity.length() > max_velocity:
			particle.velocity = particle.velocity.normalized() * max_velocity
		
		# Update position
		particle.position += particle.velocity * delta
		
		# Keep within bounds
		particle.position.x = clamp(particle.position.x, -search_space, search_space)
		particle.position.y = clamp(particle.position.y, -search_space, search_space)
		
		# Update visual position
		var fitness_height = fitness_function(particle.position) * 0.5
		particle.visual_object.position = Vector3(particle.position.x, particle.position.y, fitness_height + 0.5)
	
	# Update global best marker
	var global_best_height = fitness_function(global_best_position) * 0.5
	$GlobalBest.position = Vector3(global_best_position.x, global_best_position.y, global_best_height + 1)

func fitness_function(pos: Vector2) -> float:
	# Multi-modal optimization function (Rastrigin-like)
	var x = pos.x
	var y = pos.y
	
	# Multiple peaks with global maximum
	var f1 = 3.0 * exp(-(x*x + y*y) / 8.0)  # Central peak
	var f2 = 2.0 * exp(-((x-3)*(x-3) + (y-2)*(y-2)) / 4.0)  # Secondary peak
	var f3 = 1.5 * exp(-((x+2)*(x+2) + (y+3)*(y+3)) / 6.0)  # Tertiary peak
	var f4 = 2.5 * exp(-((x-1)*(x-1) + (y+2)*(y+2)) / 3.0)  # Another peak
	
	# Add some noise and oscillations
	var noise = 0.5 * sin(x * 2) * cos(y * 2)
	
	return f1 + f2 + f3 + f4 + noise

func animate_swarm():
	# Animate particles
	for i in range(particles.size()):
		var particle = particles[i]
		var pulse = 1.0 + sin(time * 5.0 + i * 0.3) * 0.3
		particle.visual_object.scale = Vector3.ONE * pulse
		
		# Color based on fitness
		var fitness = fitness_function(particle.position)
		var material = particle.visual_object.material_override as StandardMaterial3D
		if material:
			var intensity = (fitness + 2) / 8.0  # Normalize fitness
			material.albedo_color = Color(
				0.8 + intensity * 0.2,
				0.2 + intensity * 0.6,
				1.0 - intensity * 0.5,
				1.0
			)
			material.emission = material.albedo_color * (0.4 + intensity * 0.6)
	
	# Animate global best
	var global_pulse = 1.0 + sin(time * 8.0) * 0.5
	$GlobalBest.scale = Vector3.ONE * global_pulse
	
	# Animate landscape
	for x in range(landscape_size):
		for y in range(landscape_size):
			var point = landscape_nodes[x][y]
			var wave = sin(time * 3.0 + x * 0.2 + y * 0.3) * 0.05
			point.position.z += wave

func animate_indicators():
	# Inertia weight indicator
	var inertia_height = inertia_weight * 2.0 + 0.5
	$InertiaWeight.size.y = inertia_height
	$InertiaWeight.position.y = -3 + inertia_height/2
	
	# Swarm convergence indicator
	var avg_distance_to_global = 0.0
	for particle in particles:
		avg_distance_to_global += particle.position.distance_to(global_best_position)
	avg_distance_to_global /= particles.size()
	
	var convergence = 1.0 / (1.0 + avg_distance_to_global)  # Higher when more converged
	var convergence_height = convergence * 2.0 + 0.5
	$SwarmConvergence.size.y = convergence_height
	$SwarmConvergence.position.y = -3 + convergence_height/2
	
	# Update convergence color
	var convergence_material = $SwarmConvergence.material_override as StandardMaterial3D
	if convergence_material:
		convergence_material.albedo_color = Color(
			0.2 + convergence * 0.8,
			1.0 - convergence * 0.5,
			0.8,
			1.0
		)
		convergence_material.emission = convergence_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$InertiaWeight.scale.x = pulse
	$SwarmConvergence.scale.x = pulse

func get_optimization_info() -> Dictionary:
	return {
		"global_best_fitness": global_best_fitness,
		"global_best_position": global_best_position,
		"inertia_weight": inertia_weight,
		"particle_count": particle_count
	}
