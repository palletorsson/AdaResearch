extends Node3D

# Self-Organization Principles Visualization for VR
# Demonstrates concepts from Ashby, von Foerster, Atlan, and Prigogine
# 
# - Ashby: Systems evolve towards attractors (equilibrium states)
# - von Foerster: "Order from noise" - random perturbations help find strong attractors
# - Atlan: "Complexity from noise" - noise increases system complexity
# - Prigogine: "Order through fluctuations" or "Order out of chaos"

# Configuration parameters
@export_category("Simulation Settings")
@export var num_particles: int = 100
@export var simulation_speed: float = 1.0
@export var noise_strength: float = 0.5
@export var attractor_strength: float = 2.0
@export var attractor_radius: float = 0.5

@export_category("Display")
@export var show_phase_labels: bool = true
@export var auto_progress: bool = true  # Automatically move through phases
@export var phase_duration: float = 20.0  # Seconds per phase

# Attractors
@export_category("Attractors")
@export var num_attractors: int = 3
@export var attractor_spacing: float = 5.0

# Visual settings
@export_category("Visual")
@export var particle_size: float = 0.2
@export var particle_color: Color = Color(0.2, 0.7, 1.0, 0.8)
@export var attractor_color: Color = Color(1.0, 0.3, 0.3, 0.8)
@export var trail_enabled: bool = false  # Disabling trails by default since they're causing issues

# Node references
var particles = []
var attractors = []
var phase_label: Label3D
var info_panel: Node3D

# Simulation state
enum SimulationPhase {RANDOM, NOISE, ATTRACTOR, SELF_ORGANIZED}
var current_phase = SimulationPhase.RANDOM
var phase_timer: float = 0.0
var paused: bool = false

# Explanation texts for each phase
var phase_descriptions = {
	SimulationPhase.RANDOM: """Phase 1: Initial Random State
	
	The system begins in a state of disorder with particles
	randomly distributed throughout the space.
	
	This represents a system before any self-organization
	has occurred.""",
	
	SimulationPhase.NOISE: """Phase 2: Order from Noise (von Foerster)
	
	Random perturbations (noise) allow the system to explore 
	its state space more thoroughly.
	
	These fluctuations help the system discover the basins of 
	strong attractors, as proposed by Heinz von Foerster.""",
	
	SimulationPhase.ATTRACTOR: """Phase 3: Attractor Formation (Ashby)
	
	The system begins to evolve toward equilibrium states
	(attractors) as described by William Ross Ashby.
	
	Particles are drawn to basins of attraction, but noise
	still influences their behavior somewhat.""",
	
	SimulationPhase.SELF_ORGANIZED: """Phase 4: Self-Organization (Prigogine)
	
	The system reaches a self-organized state of order 
	emerging from previous chaos.
	
	This illustrates Ilya Prigogine's principle of "order
	through fluctuations" or "order out of chaos".
	
	Notice how particles have formed stable patterns
	around attractors, creating emergent structures."""
}

func _ready():
	randomize()
	
	# Create attractors
	create_attractors()
	
	# Create particles
	create_particles()
	
	# Create information display
	create_info_display()
	
	# Add ambient light
	var light = OmniLight3D.new()
	light.light_energy = 0.5
	light.omni_range = 50
	add_child(light)
	
	# Add environment
	create_environment()

func create_environment():
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Setup environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.05)
	environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	environment.ambient_light_energy = 1.0
	
	# Add fog for depth
	environment.fog_enabled = true
	environment.fog_density = 0.01
	#environment.fog_color = Color(0.05, 0.05, 0.1)
	
	# Add glow
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.2
	
	env.environment = environment
	add_child(env)

func create_info_display():
	# Create a panel for information
	info_panel = Node3D.new()
	info_panel.name = "InfoPanel"
	add_child(info_panel)
	
	# Position panel for VR viewing
	info_panel.position = Vector3(0, 2, -5)
	
	# Add background panel
	var panel_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(4, 3)
	panel_mesh.mesh = plane
	
	# Create material for panel
	var panel_material = StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.1, 0.1, 0.2, 0.8)
	panel_material.roughness = 0.4
	panel_mesh.material_override = panel_material
	
	info_panel.add_child(panel_mesh)
	
	# Create phase label
	phase_label = Label3D.new()
	phase_label.font_size = 16
	phase_label.text = phase_descriptions[current_phase]
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	phase_label.width = 300
	phase_label.position = Vector3(0, 0, 0.01)  # Just in front of panel
	phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	info_panel.add_child(phase_label)
	
	# Create title
	var title = Label3D.new()
	title.font_size = 24
	title.text = "Self-Organization Principles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3(0, 1.7, 0.01)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_panel.add_child(title)

func create_attractors():
	# Clear any existing attractors
	for attractor in attractors:
		if is_instance_valid(attractor):
			attractor.queue_free()
	attractors.clear()
	
	# Create new attractors
	for i in range(num_attractors):
		var attractor = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = attractor_radius
		sphere.height = attractor_radius * 2
		attractor.mesh = sphere
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = attractor_color
		material.emission_enabled = true
		material.emission = attractor_color
		material.emission_energy_multiplier = 2.0
		attractor.material_override = material
		
		# Position attractor
		var angle = TAU * i / num_attractors
		var distance = attractor_spacing
		attractor.position = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		add_child(attractor)
		attractors.append(attractor)

func create_particles():
	# Clear any existing particles
	for particle in particles:
		if is_instance_valid(particle):
			particle.queue_free()
	particles.clear()
	
	# Create new particles
	for i in range(num_particles):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = particle_size
		sphere.height = particle_size * 2
		particle.mesh = sphere
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = particle_color
		material.emission_enabled = true
		material.emission = particle_color
		material.emission_energy_multiplier = 1.0
		particle.material_override = material
		
		# Initial random position
		var max_position = 10.0
		particle.position = Vector3(
			randf_range(-max_position, max_position),
			randf_range(-max_position/2, max_position/2),  # Less vertical spread for VR comfort
			randf_range(-max_position, max_position)
		)
		
		add_child(particle)
		particles.append(particle)

func _process(delta):
	# Always update in VR mode (no pause)
	
	# Update phase timer if auto-progress is enabled
	if auto_progress:
		phase_timer += delta
		if phase_timer >= phase_duration:
			phase_timer = 0
			advance_phase()
	
	# Update particles based on current phase
	update_particles(delta)

func update_particles(delta):
	for i in range(particles.size()):
		var particle = particles[i]
		var velocity = Vector3.ZERO
		
		match current_phase:
			SimulationPhase.RANDOM:
				# Random movement
				velocity = random_movement()
			
			SimulationPhase.NOISE:
				# Strong random movement with a hint of attraction
				velocity = random_movement() * 2.0
				velocity += attraction_force(particle.position) * 0.1
			
			SimulationPhase.ATTRACTOR:
				# Medium attraction with some noise
				velocity = random_movement() * noise_strength
				velocity += attraction_force(particle.position)
			
			SimulationPhase.SELF_ORGANIZED:
				# Strong attraction with minimal noise
				velocity = random_movement() * (noise_strength * 0.1)
				velocity += attraction_force(particle.position) * attractor_strength
		
		# Apply movement
		particle.position += velocity * delta * simulation_speed

func random_movement() -> Vector3:
	return Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

func attraction_force(position: Vector3) -> Vector3:
	var force = Vector3.ZERO
	var closest_attractor = null
	var closest_distance = INF
	
	# Find the closest attractor
	for attractor in attractors:
		var dist = position.distance_to(attractor.position)
		if dist < closest_distance:
			closest_distance = dist
			closest_attractor = attractor
	
	if closest_attractor:
		# Direction to closest attractor
		var direction = closest_attractor.position - position
		var distance = direction.length()
		direction = direction.normalized()
		
		# Strength decreases with distance (inverse square law)
		var strength = 1.0 / max(1.0, distance * distance)
		force = direction * strength * attractor_strength
	
	return force

func advance_phase():
	current_phase = (current_phase + 1) % SimulationPhase.size()
	update_phase_display()

func update_phase_display():
	if phase_label:
		phase_label.text = phase_descriptions[current_phase]

func reset_simulation():
	# Recreate particles in random positions
	create_particles()
	
	# Reset timer
	phase_timer = 0.0
	
	# Reset phase
	current_phase = SimulationPhase.RANDOM
	update_phase_display()
