extends Node3D
class_name EntropyVisualization

var time: float = 0.0
var entropy_level: float = 0.0
var particle_count: int = 64
var ordered_particles: Array = []
var disordered_particles: Array = []

func _ready():
	# Initialize entropy visualization
	print("Entropy Visualization initialized")
	create_particle_systems()
	setup_entropy_meter()

func _process(delta):
	time += delta
	
	# Gradually increase entropy over time
	entropy_level = min(1.0, time * 0.1)
	
	animate_entropy_transition(delta)
	update_entropy_meter()
	animate_energy_flow(delta)

func create_particle_systems():
	# Create ordered system (low entropy)
	var ordered_system = $EntropyContainer/OrderedSystem/OrderedParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.15
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position in a perfect grid
		var x = (i % 8 - 4) * 1.0
		var y = (i / 8 - 4) * 1.0
		var z = 0
		particle.position = Vector3(x, y, z)
		
		ordered_system.add_child(particle)
		ordered_particles.append(particle)
	
	# Create disordered system (high entropy)
	var disordered_system = $EntropyContainer/DisorderedSystem/DisorderedParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.15
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
		
		# Random positions for disorder
		var x = randf_range(-4, 4)
		var y = randf_range(-4, 4)
		var z = 0
		particle.position = Vector3(x, y, z)
		
		disordered_system.add_child(particle)
		disordered_particles.append(particle)

func setup_entropy_meter():
	# Initialize the entropy meter
	var meter_indicator = $EntropyMeter/MeterIndicator
	if meter_indicator:
		meter_indicator.position.x = -6  # Start at low entropy

func animate_entropy_transition(delta):
	# Animate particles from ordered to disordered state
	for i in range(ordered_particles.size()):
		var particle = ordered_particles[i]
		if particle:
			var base_x = (i % 8 - 4) * 1.0
			var base_y = (i / 8 - 4) * 1.0
			
			# Interpolate between ordered and random positions
			var target_x = base_x + (randf_range(-2, 2) - base_x) * entropy_level
			var target_y = base_y + (randf_range(-2, 2) - base_y) * entropy_level
			
			particle.position.x = lerp(particle.position.x, target_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, target_y, delta * 2.0)
			
			# Add some random movement
			particle.position.x += sin(time * 3.0 + i) * delta * 0.5 * entropy_level
			particle.position.y += cos(time * 3.0 + i) * delta * 0.5 * entropy_level
			
			# Keep within bounds
			particle.position.x = clamp(particle.position.x, -6, 6)
			particle.position.y = clamp(particle.position.y, -6, 6)
			
			# Change color based on entropy
			var green_component = 0.8 * (1.0 - entropy_level)
			var red_component = 0.2 + 0.6 * entropy_level
			particle.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
			particle.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3

func update_entropy_meter():
	# Update the entropy meter indicator
	var meter_indicator = $EntropyMeter/MeterIndicator
	if meter_indicator:
		# Move indicator from left (low entropy) to right (high entropy)
		var target_x = lerp(-6, 6, entropy_level)
		meter_indicator.position.x = target_x
		
		# Change color based on entropy level
		var green_component = 0.8 * (1.0 - entropy_level)
		var red_component = 0.2 + 0.6 * entropy_level
		meter_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func animate_energy_flow(delta):
	# Animate energy flow between systems
	var flow_lines = $EnergyFlow/FlowLines
	for i in range(flow_lines.get_child_count()):
		var line = flow_lines.get_child(i)
		if line:
			# Pulse the flow lines
			var pulse = 1.0 + sin(time * 2.0 + i * PI) * 0.3
			line.scale.y = pulse
			
			# Change intensity based on entropy
			if line.material_override:
				var intensity = 0.5 + entropy_level * 0.5
				line.material_override.albedo_color.a = intensity

func set_entropy_level(level: float):
	entropy_level = clamp(level, 0.0, 1.0)

func reset_simulation():
	time = 0.0
	entropy_level = 0.0
	
	# Reset ordered particles to grid
	for i in range(ordered_particles.size()):
		var particle = ordered_particles[i]
		if particle:
			var x = (i % 8 - 4) * 1.0
			var y = (i / 8 - 4) * 1.0
			particle.position = Vector3(x, y, 0)
			particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
	
	# Reset disordered particles to random positions
	for i in range(disordered_particles.size()):
		var particle = disordered_particles[i]
		if particle:
			var x = randf_range(-4, 4)
			var y = randf_range(-4, 4)
			particle.position = Vector3(x, y, 0)
			particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			particle.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3

func get_entropy_level() -> float:
	return entropy_level
