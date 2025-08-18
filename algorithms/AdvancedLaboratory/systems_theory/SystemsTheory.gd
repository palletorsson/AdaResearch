extends Node3D
class_name SystemsTheory

var time: float = 0.0
var system_complexity: float = 0.0
var interaction_strength: float = 1.0
var emergent_behavior: float = 0.0
var particle_count: int = 30

func _ready():
	# Initialize systems theory visualization
	print("Systems Theory Visualization initialized")
	create_flow_particles()
	setup_system_metrics()

func _process(delta):
	time += delta
	
	# Gradually increase system complexity
	system_complexity = min(1.0, time * 0.08)
	emergent_behavior = system_complexity * 0.8
	
	animate_system_network(delta)
	animate_data_flow(delta)
	animate_emergent_properties(delta)
	update_system_metrics(delta)

func create_flow_particles():
	# Create data flow particles
	var flow_particles = $DataFlow/FlowParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position particles in a network pattern
		var angle = float(i) / particle_count * PI * 2
		var radius = 6.0 + sin(angle * 3) * 2.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = 2.0 + sin(angle * 2) * 1.0
		particle.position = Vector3(x, y, z)
		
		flow_particles.add_child(particle)

func setup_system_metrics():
	# Initialize complexity meter
	var meter_indicator = $SystemMetrics/ComplexityMeter/MeterIndicator
	if meter_indicator:
		meter_indicator.position.x = -6  # Start at low complexity

func animate_system_network(delta):
	# Animate central system
	var central_core = $SystemNetwork/CentralSystem/CentralCore
	if central_core:
		central_core.rotation.y += delta * 0.3
		central_core.scale = Vector3.ONE * (1.0 + sin(time * 1.0) * 0.05)
	
	# Animate subsystems
	var subsystems = [
		$SystemNetwork/Subsystem1/Subsystem1Core,
		$SystemNetwork/Subsystem2/Subsystem2Core,
		$SystemNetwork/Subsystem3/Subsystem3Core,
		$SystemNetwork/Subsystem4/Subsystem4Core
	]
	
	for i in range(subsystems.size()):
		var subsystem = subsystems[i]
		if subsystem:
			# Rotate subsystems
			subsystem.rotation.y += delta * (0.5 + i * 0.2)
			
			# Scale based on interaction strength
			var scale_factor = 1.0 + sin(time * (1.5 + i * 0.5)) * 0.1 * interaction_strength
			subsystem.scale = Vector3.ONE * scale_factor
			
			# Change color based on activity
			var activity = sin(time * (2.0 + i * 0.3)) * 0.5 + 0.5
			var green_component = 0.8 * (0.5 + activity * 0.5)
			subsystem.material_override.albedo_color = Color(0.2, green_component, 0.2, 1)
			subsystem.material_override.emission = Color(0.2, green_component, 0.2, 1) * 0.3

func animate_data_flow(delta):
	# Animate flow particles through the network
	var flow_particles = $DataFlow/FlowParticles
	for i in range(flow_particles.get_child_count()):
		var particle = flow_particles.get_child(i)
		if particle:
			# Create flowing motion through the network
			var progress = (time * 0.5 + float(i) * 0.1) % 1.0
			var angle = progress * PI * 2
			var radius = 6.0 + sin(angle * 3) * 2.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			var y = 2.0 + sin(angle * 2) * 1.0
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, z, delta * 2.0)
			
			# Change color based on position in network
			var color_progress = (progress + 0.3) % 1.0
			var green_component = 0.8 * (1.0 - color_progress * 0.5)
			var blue_component = 0.2 + 0.6 * color_progress
			particle.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)
			particle.material_override.emission = Color(0.2, green_component, blue_component, 1) * 0.3

func animate_emergent_properties(delta):
	# Animate emergent behavior sphere
	var emergent_sphere = $EmergentProperties/EmergentSphere
	if emergent_sphere:
		# Scale based on emergent behavior level
		var target_scale = 0.8 + emergent_behavior * 0.4
		emergent_sphere.scale = Vector3.ONE * lerp(emergent_sphere.scale.x, target_scale, delta * 2.0)
		
		# Rotate and pulse
		emergent_sphere.rotation.y += delta * 1.5
		var pulse = 1.0 + sin(time * 3.0) * 0.2 * emergent_behavior
		emergent_sphere.scale *= pulse
		
		# Change color based on emergent behavior
		var red_component = 0.8 * emergent_behavior
		var green_component = 0.2 + 0.6 * (1.0 - emergent_behavior)
		emergent_sphere.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
		emergent_sphere.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3

func update_system_metrics(delta):
	# Update complexity meter
	var meter_indicator = $SystemMetrics/ComplexityMeter/MeterIndicator
	if meter_indicator:
		var target_x = lerp(-6, 6, system_complexity)
		meter_indicator.position.x = lerp(meter_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on complexity
		var green_component = 0.8 * (1.0 - system_complexity)
		var red_component = 0.2 + 0.6 * system_complexity
		meter_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update connection line intensities based on interaction strength
	var connection_lines = $SystemNetwork/ConnectionNetwork
	for i in range(connection_lines.get_child_count()):
		var line = connection_lines.get_child(i)
		if line and line.material_override:
			var intensity = 0.3 + interaction_strength * 0.7
			line.material_override.albedo_color.a = intensity

func set_interaction_strength(strength: float):
	interaction_strength = clamp(strength, 0.1, 2.0)

func get_system_complexity() -> float:
	return system_complexity

func get_emergent_behavior() -> float:
	return emergent_behavior

func reset_system():
	time = 0.0
	system_complexity = 0.0
	emergent_behavior = 0.0
	
	# Reset all particles to initial positions
	var flow_particles = $DataFlow/FlowParticles
	for i in range(flow_particles.get_child_count()):
		var particle = flow_particles.get_child(i)
		if particle:
			var angle = float(i) / particle_count * PI * 2
			var radius = 6.0 + sin(angle * 3) * 2.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			var y = 2.0 + sin(angle * 2) * 1.0
			particle.position = Vector3(x, y, z)
			particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
