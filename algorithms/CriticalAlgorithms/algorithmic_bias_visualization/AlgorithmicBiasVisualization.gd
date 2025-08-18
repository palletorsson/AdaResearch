extends Node3D
class_name AlgorithmicBiasVisualization

var time: float = 0.0
var bias_level: float = 0.0
var fairness_score: float = 1.0
var data_flow_rate: float = 2.0
var particle_count: int = 25

func _ready():
	# Initialize algorithmic bias visualization
	print("Algorithmic Bias Visualization initialized")
	create_data_groups()
	create_bias_indicators()
	create_impact_visualization()
	setup_bias_metrics()

func _process(delta):
	time += delta
	
	# Simulate bias dynamics
	bias_level = min(1.0, time * 0.08)
	fairness_score = max(0.1, 1.0 - bias_level * 0.8)
	
	animate_data_groups(delta)
	animate_algorithm(delta)
	animate_bias_indicators(delta)
	animate_data_flow(delta)
	animate_impact_visualization(delta)
	update_bias_metrics(delta)

func create_data_groups():
	# Create Group A particles
	var group_a_particles = $DataGroups/GroupA/GroupAParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position particles in a cluster
		var x = randf_range(-2, 2)
		var y = randf_range(-2, 2)
		var z = randf_range(-2, 2)
		particle.position = Vector3(x, y, z)
		
		group_a_particles.add_child(particle)
	
	# Create Group B particles
	var group_b_particles = $DataGroups/GroupB/GroupBParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
		
		# Position particles in a different cluster
		var x = randf_range(-2, 2)
		var y = randf_range(-2, 2)
		var z = randf_range(-2, 2)
		particle.position = Vector3(x, y, z)
		
		group_b_particles.add_child(particle)

func create_bias_indicators():
	# Create bias arrows
	var bias_arrows = $BiasIndicators/BiasArrows
	for i in range(8):
		var arrow = CSGCylinder3D.new()
		arrow.radius = 0.1
		arrow.height = 0.8
		arrow.material_override = StandardMaterial3D.new()
		arrow.material_override.albedo_color = Color(0.8, 0.2, 0.8, 0.8)
		arrow.material_override.emission_enabled = true
		arrow.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position arrows around the decision boundary
		var angle = float(i) / 8 * PI * 2
		var radius = 8.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		arrow.position = Vector3(x, 0, z)
		arrow.rotation.y = angle + PI
		
		bias_arrows.add_child(arrow)

func create_impact_visualization():
	# Create impact spheres
	var impact_spheres = $ImpactVisualization/ImpactSpheres
	for i in range(12):
		var sphere = CSGSphere3D.new()
		sphere.radius = 0.15
		sphere.material_override = StandardMaterial3D.new()
		sphere.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
		sphere.material_override.emission_enabled = true
		sphere.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position spheres in a grid pattern
		var row = i / 4
		var col = i % 4
		var x = (col - 1.5) * 3
		var z = (row - 1.5) * 3
		sphere.position = Vector3(x, 0, z)
		
		impact_spheres.add_child(sphere)

func setup_bias_metrics():
	# Initialize fairness and bias meters
	var fairness_indicator = $BiasMetrics/FairnessScore/FairnessIndicator
	var bias_indicator = $BiasMetrics/BiasScore/BiasIndicator
	if fairness_indicator:
		fairness_indicator.position.x = 0  # Start at middle
	if bias_indicator:
		bias_indicator.position.x = 0  # Start at middle

func animate_data_groups(delta):
	# Animate Group A particles
	var group_a_particles = $DataGroups/GroupA/GroupAParticles
	for i in range(group_a_particles.get_child_count()):
		var particle = group_a_particles.get_child(i)
		if particle:
			# Subtle movement
			var move_x = sin(time * 0.8 + i * 0.1) * 0.3
			var move_y = cos(time * 1.2 + i * 0.15) * 0.3
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			
			# Pulse particles
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2
			particle.scale = Vector3.ONE * pulse
	
	# Animate Group B particles
	var group_b_particles = $DataGroups/GroupB/GroupBParticles
	for i in range(group_b_particles.get_child_count()):
		var particle = group_b_particles.get_child(i)
		if particle:
			# More dynamic movement
			var move_x = sin(time * 1.5 + i * 0.2) * 0.4
			var move_y = cos(time * 2.0 + i * 0.25) * 0.4
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			
			# Pulse particles
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2
			particle.scale = Vector3.ONE * pulse

func animate_algorithm(delta):
	# Animate algorithm core
	var algorithm_core = $Algorithm/AlgorithmCore
	if algorithm_core:
		# Rotate algorithm
		algorithm_core.rotation.y += delta * 0.5
		
		# Scale based on bias level
		var target_scale = 4.0 + bias_level * 2.0
		algorithm_core.scale = Vector3.ONE * lerp(algorithm_core.scale.x, target_scale, delta * 2.0)
		
		# Change color based on bias
		if algorithm_core.material_override:
			var red_component = 0.2 + bias_level * 0.6
			var blue_component = 0.2 + bias_level * 0.6
			algorithm_core.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)

func animate_bias_indicators(delta):
	# Animate bias arrows
	var bias_arrows = $BiasIndicators/BiasArrows
	for i in range(bias_arrows.get_child_count()):
		var arrow = bias_arrows.get_child(i)
		if arrow:
			# Pulse arrows based on bias level
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.3 * bias_level
			arrow.scale = Vector3.ONE * pulse
			
			# Change emission intensity
			if arrow.material_override:
				var intensity = 0.3 + bias_level * 0.7
				arrow.material_override.emission = Color(0.8, 0.2, 0.8, 1) * intensity

func animate_data_flow(delta):
	# Animate data flow particles
	var flow_particles = $DataFlow/FlowParticles
	if flow_particles:
		for i in range(flow_particles.get_child_count()):
			var particle = flow_particles.get_child(i)
			if particle:
				# Move particles through the system
				var progress = fmod(time * data_flow_rate + float(i) * 0.1, 1.0)
				var x = lerp(-8, 8, progress)
				var y = sin(progress * PI * 2) * 2
				
				particle.position.x = lerp(particle.position.x, x, delta * 2.0)
				particle.position.y = lerp(particle.position.y, y, delta * 2.0)
				
				# Change color based on position and bias
				var color_progress = fmod((progress + 0.5), 1.0)
				var green_component = 0.8 * (1.0 - color_progress * 0.5) * (1.0 - bias_level * 0.5)
				var red_component = 0.2 + 0.6 * color_progress + bias_level * 0.3
				particle.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
				particle.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3

func animate_impact_visualization(delta):
	# Animate impact spheres
	var impact_spheres = $ImpactVisualization/ImpactSpheres
	for i in range(impact_spheres.get_child_count()):
		var sphere = impact_spheres.get_child(i)
		if sphere:
			# Scale based on bias impact
			var impact_scale = 1.0 + bias_level * 0.5
			sphere.scale = Vector3.ONE * lerp(sphere.scale.x, impact_scale, delta * 2.0)
			
			# Move spheres up and down
			var y_offset = sin(time * 1.5 + i * 0.4) * 0.3 * bias_level
			sphere.position.y = y_offset
			
			# Change emission intensity
			if sphere.material_override:
				var intensity = 0.3 + bias_level * 0.7
				sphere.material_override.emission = Color(0.8, 0.8, 0.2, 1) * intensity

func update_bias_metrics(delta):
	# Update fairness score meter
	var fairness_indicator = $BiasMetrics/FairnessScore/FairnessIndicator
	if fairness_indicator:
		var target_x = lerp(-2, 2, fairness_score)
		fairness_indicator.position.x = lerp(fairness_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on fairness
		var green_component = 0.8 * fairness_score
		var red_component = 0.2 + 0.6 * (1.0 - fairness_score)
		fairness_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update bias score meter
	var bias_indicator = $BiasMetrics/BiasScore/BiasIndicator
	if bias_indicator:
		var target_x = lerp(-2, 2, bias_level)
		bias_indicator.position.x = lerp(bias_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on bias
		var red_component = 0.8 * bias_level
		var green_component = 0.2 + 0.6 * (1.0 - bias_level)
		bias_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_bias_level(level: float):
	bias_level = clamp(level, 0.0, 1.0)

func set_fairness_score(score: float):
	fairness_score = clamp(score, 0.1, 1.0)

func get_bias_level() -> float:
	return bias_level

func get_fairness_score() -> float:
	return fairness_score

func reset_bias():
	time = 0.0
	bias_level = 0.0
	fairness_score = 1.0
