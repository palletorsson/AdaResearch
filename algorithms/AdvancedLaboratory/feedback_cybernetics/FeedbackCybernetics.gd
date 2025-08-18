extends Node3D
class_name FeedbackCybernetics

var time: float = 0.0
var feedback_strength: float = 0.5
var system_stability: float = 1.0
var data_flow_rate: float = 2.0
var particle_count: int = 20

func _ready():
	# Initialize feedback cybernetics system
	print("Feedback Cybernetics System initialized")
	create_data_particles()
	setup_control_parameters()

func _process(delta):
	time += delta
	
	animate_control_system(delta)
	animate_data_flow(delta)
	animate_signal_waves(delta)
	update_system_stability(delta)

func create_data_particles():
	# Create data flow particles
	var data_particles = $DataFlow/DataParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the control flow path
		var progress = float(i) / particle_count
		var angle = progress * PI * 2
		var radius = 6.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		particle.position = Vector3(x, 0, z)
		
		data_particles.add_child(particle)

func setup_control_parameters():
	# Initialize control parameter slider
	var slider_indicator = $ControlParameters/ParameterSlider/SliderIndicator
	if slider_indicator:
		slider_indicator.position.x = lerp(-4, 4, feedback_strength)

func animate_control_system(delta):
	# Animate input node
	var input_sphere = $ControlSystem/InputNode/InputSphere
	if input_sphere:
		input_sphere.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.1)
		input_sphere.rotation.y += delta * 1.0
	
	# Animate process node
	var process_cube = $ControlSystem/ProcessNode/ProcessCube
	if process_cube:
		process_cube.rotation.y += delta * 0.5
		process_cube.scale = Vector3.ONE * (1.0 + sin(time * 1.5) * 0.05)
	
	# Animate output node
	var output_sphere = $ControlSystem/OutputNode/OutputSphere
	if output_sphere:
		output_sphere.scale = Vector3.ONE * (1.0 + sin(time * 2.5) * 0.1)
		output_sphere.rotation.y += delta * 1.5
	
	# Animate feedback node
	var feedback_sphere = $ControlSystem/FeedbackLoop/FeedbackSphere
	if feedback_sphere:
		feedback_sphere.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.15)
		feedback_sphere.rotation.y += delta * 2.0

func animate_data_flow(delta):
	# Animate data particles flowing through the system
	var data_particles = $DataFlow/DataParticles
	for i in range(data_particles.get_child_count()):
		var particle = data_particles.get_child(i)
		if particle:
			# Move particles along the control flow path
			var progress = (time * data_flow_rate + float(i) * 0.1) % 1.0
			var angle = progress * PI * 2
			var radius = 6.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			
			particle.position.x = lerp(particle.position.x, x, delta * 3.0)
			particle.position.z = lerp(particle.position.z, z, delta * 3.0)
			
			# Change color based on position in the flow
			var color_progress = (progress + 0.5) % 1.0
			var green_component = 0.8 * (1.0 - color_progress)
			var red_component = 0.2 + 0.6 * color_progress
			particle.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
			particle.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3

func animate_signal_waves(delta):
	# Animate signal propagation waves
	var waves = $SignalWaves
	for i in range(waves.get_child_count()):
		var wave = waves.get_child(i)
		if wave:
			# Expand waves outward
			var expansion = time * 0.5 + i * 0.5
			wave.scale = Vector3.ONE * (1.0 + expansion)
			
			# Fade out as waves expand
			if wave.material_override:
				var alpha = max(0.0, 1.0 - expansion * 0.1)
				wave.material_override.albedo_color.a = alpha
			
			# Reset wave when it gets too large
			if wave.scale.x > 8.0:
				wave.scale = Vector3.ONE
				wave.material_override.albedo_color.a = 1.0

func update_system_stability(delta):
	# Update system stability based on feedback strength
	var target_stability = 1.0 - feedback_strength * 0.5
	system_stability = lerp(system_stability, target_stability, delta * 0.5)
	
	# Update control parameter slider
	var slider_indicator = $ControlParameters/ParameterSlider/SliderIndicator
	if slider_indicator:
		var target_x = lerp(-4, 4, feedback_strength)
		slider_indicator.position.x = lerp(slider_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on feedback strength
		var green_component = 0.8 * (1.0 - feedback_strength)
		var red_component = 0.2 + 0.6 * feedback_strength
		slider_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update connection line intensities based on stability
	var connection_lines = $ControlSystem/ConnectionLines
	for i in range(connection_lines.get_child_count()):
		var line = connection_lines.get_child(i)
		if line and line.material_override:
			var intensity = 0.5 + system_stability * 0.5
			line.material_override.albedo_color.a = intensity

func set_feedback_strength(strength: float):
	feedback_strength = clamp(strength, 0.0, 1.0)

func set_data_flow_rate(rate: float):
	data_flow_rate = clamp(rate, 0.5, 5.0)

func get_system_stability() -> float:
	return system_stability

func reset_system():
	time = 0.0
	feedback_strength = 0.5
	system_stability = 1.0
	
	# Reset all particles to initial positions
	var data_particles = $DataFlow/DataParticles
	for i in range(data_particles.get_child_count()):
		var particle = data_particles.get_child(i)
		if particle:
			var progress = float(i) / particle_count
			var angle = progress * PI * 2
			var radius = 6.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			particle.position = Vector3(x, 0, z)
			particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
