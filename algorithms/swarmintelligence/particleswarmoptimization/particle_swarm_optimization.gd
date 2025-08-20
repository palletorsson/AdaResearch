extends Node3D
class_name ParticleSwarmOptimization

# Particle Swarm Optimization with Queer Collective Intelligence
# Explores how decentralized swarm behavior challenges heteronormative optimization narratives
# Each particle embodies collective intelligence and non-binary search strategies

@export_category("Swarm Configuration")
@export var particle_count: int = 50
@export var search_dimensions: int = 3
@export var search_space_size: float = 20.0
@export var max_velocity: float = 2.0
@export var inertia_weight: float = 0.7
@export var cognitive_coefficient: float = 1.5  # Personal best attraction
@export var social_coefficient: float = 1.5     # Global best attraction

@export_category("Queer Parameters")
@export var non_binary_exploration: bool = true  # Particles can exist between discrete states
@export var collective_memory_strength: float = 0.3  # How much swarm remembers past solutions
@export var diversity_preservation: float = 0.2      # Resistance to convergence pressure
@export var mutation_rate: float = 0.05             # Spontaneous behavioral changes

@export_category("Visual Settings")
@export var particle_trail_length: int = 20
@export var show_connections: bool = true
@export var adaptive_colors: bool = true
@export var performance_based_size: bool = true

@export_category("Optimization Function")
@export_enum("Rosenbrock", "Ackley", "Rastrigin", "Sphere", "Queer_Landscape") var objective_function: int = 4

# Internal structures
var particles = []
var global_best_position: Vector3
var global_best_fitness: float = INF
var swarm_diversity_history = []
var collective_memory = []

# Visual components
var particle_materials = []
var connection_lines = []
var landscape_mesh: MeshInstance3D
var performance_display: Label

# Theoretical framework
var heteronormative_pressure: float = 0.0  # Pressure toward single "optimal" solution
var queer_resistance: float = 0.0          # Collective resistance to normalization

class Particle:
	var position: Vector3
	var velocity: Vector3
	var personal_best_position: Vector3
	var personal_best_fitness: float = INF
	var mesh_instance: MeshInstance3D
	var trail_positions = []
	var identity_fluidity: float  # How much the particle resists fixed optimization
	var collective_influence: float  # How much it's influenced by swarm memory
	
	func _init(start_pos: Vector3):
		position = start_pos
		velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		personal_best_position = position
		identity_fluidity = randf_range(0.1, 0.9)
		collective_influence = randf_range(0.2, 0.8)

func _ready():
	setup_environment()
	initialize_swarm()
	create_visual_landscape()
	setup_ui()
	
func _process(delta):
	update_swarm(delta)
	update_visuals(delta)
	analyze_collective_behavior(delta)

func setup_environment():
	# Create ambient environment that reflects collective intelligence
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.05, 0.2)  # Deep space for exploration
	environment.ambient_light_color = Color(0.3, 0.2, 0.4)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)
	
	# Lighting that emphasizes collective rather than individual
	var light = DirectionalLight3D.new()
	light.light_color = Color(0.8, 0.6, 1.0)
	light.light_energy = 0.8
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)

func initialize_swarm():
	particles.clear()
	
	# Create particles with diverse starting conditions
	for i in range(particle_count):
		var start_pos = Vector3(
			randf_range(-search_space_size/2, search_space_size/2),
			randf_range(-search_space_size/2, search_space_size/2),
			randf_range(-search_space_size/2, search_space_size/2)
		)
		
		var particle = Particle.new(start_pos)
		particles.append(particle)
		
		# Create visual representation
		create_particle_visual(particle, i)
	
	# Initialize global best
	evaluate_all_particles()

func create_particle_visual(particle: Particle, index: int):
	particle.mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	particle.mesh_instance.mesh = sphere
	
	# Color based on identity fluidity and collective influence
	var material = StandardMaterial3D.new()
	var hue = particle.identity_fluidity * 0.8 + 0.1  # Purple to cyan spectrum
	var saturation = particle.collective_influence
	var brightness = 0.8
	material.albedo_color = Color.from_hsv(hue, saturation, brightness)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	material.emission_energy = 0.5
	particle.mesh_instance.material_override = material
	
	particle.mesh_instance.position = particle.position
	add_child(particle.mesh_instance)
	
	particle_materials.append(material)

func update_swarm(delta: float):
	# Update heteronormative pressure based on convergence
	update_social_pressures()
	
	for particle in particles:
		update_particle_velocity(particle)
		update_particle_position(particle, delta)
		
		# Apply queer resistance to normalization
		if non_binary_exploration:
			apply_non_binary_exploration(particle)
		
		# Collective memory influence
		apply_collective_memory(particle)
	
	# Evaluate fitness for all particles
	evaluate_all_particles()
	
	# Update collective memory
	update_collective_memory()
	
	# Preserve diversity if enabled
	if diversity_preservation > 0:
		apply_diversity_preservation()

func update_particle_velocity(particle: Particle):
	# Standard PSO velocity update with queer modifications
	var r1 = randf()
	var r2 = randf()
	
	# Cognitive component (personal experience)
	var cognitive = (particle.personal_best_position - particle.position) * cognitive_coefficient * r1
	
	# Social component (collective intelligence)
	var social = (global_best_position - particle.position) * social_coefficient * r2
	
	# Queer resistance component - resist pure convergence
	var resistance = Vector3.ZERO
	if heteronormative_pressure > diversity_preservation:
		var resistance_direction = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
		resistance = resistance_direction * particle.identity_fluidity * queer_resistance
	
	# Update velocity
	particle.velocity = particle.velocity * inertia_weight + cognitive + social + resistance
	
	# Clamp velocity
	if particle.velocity.length() > max_velocity:
		particle.velocity = particle.velocity.normalized() * max_velocity

func update_particle_position(particle: Particle, delta: float):
	particle.position += particle.velocity * delta
	
	# Boundary handling - reflective boundaries that preserve exploration
	for i in range(3):
		if abs(particle.position[i]) > search_space_size/2:
			particle.position[i] = sign(particle.position[i]) * search_space_size/2
			particle.velocity[i] *= -0.5  # Damped reflection
	
	# Update visual position
	particle.mesh_instance.position = particle.position
	
	# Update trail
	particle.trail_positions.append(particle.position)
	if particle.trail_positions.size() > particle_trail_length:
		particle.trail_positions.pop_front()

func apply_non_binary_exploration(particle: Particle):
	# Particles can exist in superposition of states, exploring multiple solutions
	if randf() < mutation_rate * particle.identity_fluidity:
		var quantum_jump = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1), 
			randf_range(-1, 1)
		) * search_space_size * 0.1
		particle.position += quantum_jump

func apply_collective_memory(particle: Particle):
	# Influence from collective memory of good solutions
	if collective_memory.size() > 0 and randf() < particle.collective_influence:
		var memory_solution = collective_memory[randi() % collective_memory.size()]
		var memory_influence = (memory_solution - particle.position) * collective_memory_strength
		particle.velocity += memory_influence

func update_collective_memory():
	# Store diverse good solutions, not just the best
	for particle in particles:
		if particle.personal_best_fitness < global_best_fitness * 1.1:  # Within 10% of best
			var too_close = false
			for memory_pos in collective_memory:
				if particle.personal_best_position.distance_to(memory_pos) < search_space_size * 0.1:
					too_close = true
					break
			
			if not too_close:
				collective_memory.append(particle.personal_best_position)
				if collective_memory.size() > 20:  # Limit memory size
					collective_memory.pop_front()

func evaluate_all_particles():
	for particle in particles:
		var fitness = evaluate_fitness(particle.position)
		
		# Update personal best
		if fitness < particle.personal_best_fitness:
			particle.personal_best_fitness = fitness
			particle.personal_best_position = particle.position
		
		# Update global best
		if fitness < global_best_fitness:
			global_best_fitness = fitness
			global_best_position = particle.position

func evaluate_fitness(position: Vector3) -> float:
	match objective_function:
		0: return rosenbrock_function(position)
		1: return ackley_function(position)
		2: return rastrigin_function(position)
		3: return sphere_function(position)
		4: return queer_landscape_function(position)
		_: return sphere_function(position)

func queer_landscape_function(pos: Vector3) -> float:
	# A complex landscape that rewards diversity and resists simple optimization
	# Multiple optima representing different "valid" solutions
	var x = pos.x
	var y = pos.y
	var z = pos.z
	
	# Multiple peaks representing diverse solutions
	var peak1 = exp(-((x-3)*(x-3) + (y-3)*(y-3) + z*z) * 0.5)
	var peak2 = exp(-((x+3)*(x+3) + (y-3)*(y-3) + z*z) * 0.5)
	var peak3 = exp(-((x)*(x) + (y+3)*(y+3) + z*z) * 0.5)
	var peak4 = exp(-(x*x + y*y + (z-3)*(z-3)) * 0.5)
	var peak5 = exp(-(x*x + y*y + (z+3)*(z+3)) * 0.5)
	
	# Valleys that connect different optima
	var connectivity = sin(x) * sin(y) * sin(z) * 0.1
	
	# Penalty for over-convergence (heteronormative pressure resistance)
	var convergence_penalty = 0.0
	if particles.size() > 0:
		var center_mass = Vector3.ZERO
		for p in particles:
			center_mass += p.position
		center_mass /= particles.size()
		var spread = 0.0
		for p in particles:
			spread += center_mass.distance_to(p.position)
		spread /= particles.size()
		if spread < search_space_size * 0.1:  # Too converged
			convergence_penalty = (search_space_size * 0.1 - spread) * 2.0
	
	# Return negative (since we're minimizing, but want to reward diverse peaks)
	return -(peak1 + peak2 + peak3 + peak4 + peak5 + connectivity) + convergence_penalty

func rosenbrock_function(pos: Vector3) -> float:
	var x = pos.x
	var y = pos.y
	var z = pos.z
	return 100*(y - x*x)*(y - x*x) + (1 - x)*(1 - x) + 100*(z - y*y)*(z - y*y) + (1 - y)*(1 - y)

func ackley_function(pos: Vector3) -> float:
	var x = pos.x
	var y = pos.y  
	var z = pos.z
	var a = 20
	var b = 0.2
	var c = 2 * PI
	var sum_sq = x*x + y*y + z*z
	var sum_cos = cos(c*x) + cos(c*y) + cos(c*z)
	return -a * exp(-b * sqrt(sum_sq/3)) - exp(sum_cos/3) + a + exp(1)

func sphere_function(pos: Vector3) -> float:
	return pos.x*pos.x + pos.y*pos.y + pos.z*pos.z

func rastrigin_function(pos: Vector3) -> float:
	var A = 10
	var n = 3
	return A * n + (pos.x*pos.x - A*cos(2*PI*pos.x)) + (pos.y*pos.y - A*cos(2*PI*pos.y)) + (pos.z*pos.z - A*cos(2*PI*pos.z))

func update_social_pressures():
	# Calculate heteronormative pressure (pressure to converge to single solution)
	var total_distance = 0.0
	var count = 0
	for i in range(particles.size()):
		for j in range(i+1, particles.size()):
			total_distance += particles[i].position.distance_to(particles[j].position)
			count += 1
	
	var average_distance = total_distance / count if count > 0 else search_space_size
	heteronormative_pressure = 1.0 - (average_distance / search_space_size)
	
	# Queer resistance builds when pressure is too high
	queer_resistance = max(0, heteronormative_pressure - (1.0 - diversity_preservation))

func apply_diversity_preservation():
	# If swarm is too converged, inject diversity
	if heteronormative_pressure > 0.8:
		var most_diverse_particles = particles.slice(0, particle_count / 4)
		for particle in most_diverse_particles:
			if randf() < diversity_preservation:
				# "Come out" - break away from conformity
				var breakaway_direction = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
				particle.position += breakaway_direction * search_space_size * 0.2
				particle.velocity = breakaway_direction * max_velocity * 0.5

func update_visuals(delta: float):
	# Update particle colors based on performance and diversity
	for i in range(particles.size()):
		var particle = particles[i]
		var material = particle_materials[i]
		
		if adaptive_colors:
			# Color shifts based on fitness and conformity pressure
			var fitness_normalized = clamp(1.0 - (particle.personal_best_fitness / (global_best_fitness + 1)), 0, 1)
			var diversity_factor = particle.identity_fluidity
			
			var hue = diversity_factor * 0.8 + 0.1
			var saturation = fitness_normalized * 0.8 + 0.2
			var brightness = 0.6 + fitness_normalized * 0.4
			
			# Pulse effect for high-performing diverse particles
			if fitness_normalized > 0.7 and diversity_factor > 0.5:
				brightness += sin(Time.get_time_dict_from_system()["unix"] * 4) * 0.2
			
			material.albedo_color = Color.from_hsv(hue, saturation, brightness)
			material.emission = material.albedo_color * 0.4
		
		if performance_based_size:
			var fitness_factor = clamp(1.0 - (particle.personal_best_fitness / (global_best_fitness + 1)), 0.5, 2.0)
			particle.mesh_instance.scale = Vector3.ONE * fitness_factor

func create_visual_landscape():
	# Create a visual representation of the fitness landscape
	landscape_mesh = MeshInstance3D.new()
	
	# For now, just create a grid that will be updated to show the landscape
	var plane = PlaneMesh.new()
	plane.size = Vector2(search_space_size, search_space_size)
	plane.subdivide_width = 20
	plane.subdivide_depth = 20
	landscape_mesh.mesh = plane
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.1, 0.3, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	landscape_mesh.material_override = material
	landscape_mesh.position.y = -search_space_size/2
	
	add_child(landscape_mesh)

func setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	performance_display = Label.new()
	performance_display.position = Vector2(20, 20)
	performance_display.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(performance_display)

func analyze_collective_behavior(delta: float):
	# Update diversity metrics
	var current_diversity = calculate_swarm_diversity()
	swarm_diversity_history.append(current_diversity)
	if swarm_diversity_history.size() > 100:
		swarm_diversity_history.pop_front()
	
	# Update UI
	if performance_display:
		var diversity_avg = 0.0
		for d in swarm_diversity_history:
			diversity_avg += d
		diversity_avg /= swarm_diversity_history.size()
		
		performance_display.text = "Global Best: %.3f\n" % global_best_fitness
		performance_display.text += "Diversity: %.3f\n" % current_diversity
		performance_display.text += "Heteronormative Pressure: %.3f\n" % heteronormative_pressure
		performance_display.text += "Queer Resistance: %.3f\n" % queer_resistance
		performance_display.text += "Collective Memory: %d solutions" % collective_memory.size()

func calculate_swarm_diversity() -> float:
	if particles.size() < 2:
		return 0.0
	
	var total_distance = 0.0
	var count = 0
	for i in range(particles.size()):
		for j in range(i+1, particles.size()):
			total_distance += particles[i].position.distance_to(particles[j].position)
			count += 1
	
	return total_distance / count if count > 0 else 0.0 