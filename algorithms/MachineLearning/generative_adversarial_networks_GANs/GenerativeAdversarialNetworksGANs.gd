extends Node3D
class_name GenerativeAdversarialNetworksGANs

var time: float = 0.0
var training_progress: float = 0.0
var generator_loss: float = 1.0
var discriminator_loss: float = 1.0
var competition_level: float = 0.0
var particle_count: int = 20

func _ready():
	# Initialize GAN visualization
	print("Generative Adversarial Networks Visualization initialized")
	create_noise_particles()
	create_data_particles()
	create_feedback_particles()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate training progress
	training_progress = min(1.0, time * 0.1)
	competition_level = training_progress * 0.8
	
	# Simulate loss dynamics
	generator_loss = max(0.1, 1.0 - training_progress * 0.7)
	discriminator_loss = max(0.1, 0.5 + training_progress * 0.3)
	
	animate_generator(delta)
	animate_discriminator(delta)
	animate_competition(delta)
	animate_data_flow(delta)
	animate_feedback_loop(delta)
	update_training_metrics(delta)

func create_noise_particles():
	# Create noise particles for generator input
	var noise_particles = $Generator/GeneratorInput/NoiseParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Random positions around generator input
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		
		noise_particles.add_child(particle)

func create_data_particles():
	# Create real data particles
	var real_data = $Discriminator/DiscriminatorInput/RealData
	for i in range(particle_count / 2):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Random positions around discriminator input
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		
		real_data.add_child(particle)
	
	# Create generated data particles
	var generated_data = $Discriminator/DiscriminatorInput/GeneratedData
	for i in range(particle_count / 2):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Random positions around discriminator input
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		
		generated_data.add_child(particle)

func create_feedback_particles():
	# Create feedback loop particles
	var feedback_particles = $FeedbackLoop/FeedbackParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.03
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles in a circle around the competition area
		var angle = float(i) / particle_count * PI * 2
		var radius = 4.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		particle.position = Vector3(x, 0, z)
		
		feedback_particles.add_child(particle)

func setup_training_metrics():
	# Initialize loss meters
	var gen_loss_indicator = $TrainingMetrics/GeneratorLoss/GenLossIndicator
	var disc_loss_indicator = $TrainingMetrics/DiscriminatorLoss/DiscLossIndicator
	if gen_loss_indicator:
		gen_loss_indicator.position.x = 0  # Start at middle
	if disc_loss_indicator:
		disc_loss_indicator.position.x = 0  # Start at middle

func animate_generator(delta):
	# Animate generator core
	var generator_core = $Generator/GeneratorCore
	if generator_core:
		# Rotate generator
		generator_core.rotation.y += delta * 0.8
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 2.0) * 0.2 * training_progress
		generator_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if generator_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			generator_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate noise particles
	var noise_particles = $Generator/GeneratorInput/NoiseParticles
	for i in range(noise_particles.get_child_count()):
		var particle = noise_particles.get_child(i)
		if particle:
			# Move particles in a flowing pattern
			var flow_x = sin(time * 1.0 + i * 0.2) * 0.5
			var flow_y = cos(time * 1.5 + i * 0.3) * 0.5
			var flow_z = sin(time * 0.8 + i * 0.4) * 0.5
			
			particle.position.x = lerp(particle.position.x, flow_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, flow_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, flow_z, delta * 2.0)
			
			# Pulse particles
			var pulse = 1.0 + sin(time * 3.0 + i * 0.5) * 0.3
			particle.scale = Vector3.ONE * pulse

func animate_discriminator(delta):
	# Animate discriminator core
	var discriminator_core = $Discriminator/DiscriminatorCore
	if discriminator_core:
		# Rotate discriminator
		discriminator_core.rotation.y += delta * 1.2
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 2.5) * 0.2 * training_progress
		discriminator_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if discriminator_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			discriminator_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	# Animate data particles
	var real_data = $Discriminator/DiscriminatorInput/RealData
	var generated_data = $Discriminator/DiscriminatorInput/GeneratedData
	
	# Animate real data
	for i in range(real_data.get_child_count()):
		var particle = real_data.get_child(i)
		if particle:
			# Subtle movement
			var move_x = sin(time * 0.8 + i * 0.1) * 0.2
			var move_y = cos(time * 1.2 + i * 0.15) * 0.2
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
	
	# Animate generated data
	for i in range(generated_data.get_child_count()):
		var particle = generated_data.get_child(i)
		if particle:
			# More dynamic movement
			var move_x = sin(time * 1.5 + i * 0.2) * 0.3
			var move_y = cos(time * 2.0 + i * 0.25) * 0.3
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)

func animate_competition(delta):
	# Animate competition core
	var competition_core = $Competition/CompetitionCore
	if competition_core:
		# Rotate competition area
		competition_core.rotation.y += delta * 0.6
		
		# Scale based on competition level
		var target_scale = 3.0 + competition_level * 2.0
		competition_core.scale = Vector3.ONE * lerp(competition_core.scale.x, target_scale, delta * 2.0)
		
		# Change color based on competition intensity
		if competition_core.material_override:
			var red_component = 0.2 + competition_level * 0.6
			var blue_component = 0.2 + competition_level * 0.6
			competition_core.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)

func animate_data_flow(delta):
	# Animate data flowing from generator to competition
	var generator_to_competition = $DataFlow/GeneratorToCompetition
	# This would contain connection lines or particles showing data flow
	
	# Animate data flowing from competition to discriminator
	var competition_to_discriminator = $DataFlow/CompetitionToDiscriminator
	# This would contain connection lines or particles showing data flow

func animate_feedback_loop(delta):
	# Animate feedback particles
	var feedback_particles = $FeedbackLoop/FeedbackParticles
	for i in range(feedback_particles.get_child_count()):
		var particle = feedback_particles.get_child(i)
		if particle:
			# Move particles in a circular pattern
			var progress = (time * 0.3 + float(i) * 0.1) % 1.0
			var angle = progress * PI * 2
			var radius = 4.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.z = lerp(particle.position.z, z, delta * 2.0)
			
			# Change color based on position in feedback loop
			var color_progress = (progress + 0.5) % 1.0
			var green_component = 0.8 * (1.0 - color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + color_progress * 0.5)
			particle.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)
			particle.material_override.emission = Color(0.2, green_component, blue_component, 1) * 0.3
			
			# Pulse particles
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2
			particle.scale = Vector3.ONE * pulse

func update_training_metrics(delta):
	# Update generator loss meter
	var gen_loss_indicator = $TrainingMetrics/GeneratorLoss/GenLossIndicator
	if gen_loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - generator_loss)
		gen_loss_indicator.position.x = lerp(gen_loss_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on loss
		var green_component = 0.8 * (1.0 - generator_loss)
		var red_component = 0.2 + 0.6 * generator_loss
		gen_loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update discriminator loss meter
	var disc_loss_indicator = $TrainingMetrics/DiscriminatorLoss/DiscLossIndicator
	if disc_loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - discriminator_loss)
		disc_loss_indicator.position.x = lerp(disc_loss_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on loss
		var green_component = 0.8 * (1.0 - discriminator_loss)
		var red_component = 0.2 + 0.6 * discriminator_loss
		disc_loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_training_progress(progress: float):
	training_progress = clamp(progress, 0.0, 1.0)

func set_generator_loss(loss: float):
	generator_loss = clamp(loss, 0.1, 1.0)

func set_discriminator_loss(loss: float):
	discriminator_loss = clamp(loss, 0.1, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_generator_loss() -> float:
	return generator_loss

func get_discriminator_loss() -> float:
	return discriminator_loss

func reset_training():
	time = 0.0
	training_progress = 0.0
	generator_loss = 1.0
	discriminator_loss = 1.0
	competition_level = 0.0
