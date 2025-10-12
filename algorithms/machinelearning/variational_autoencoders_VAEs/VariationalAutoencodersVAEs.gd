extends Node3D

var time: float = 0.0
var training_progress: float = 0.0
var reconstruction_loss: float = 1.0
var kl_divergence: float = 1.0
var particle_count: int = 20
var flow_particles: Array = []
var latent_particles: Array = []

func _ready():
	# Initialize VAE visualization
	print("Variational Autoencoders Visualization initialized")
	create_input_particles()
	create_output_particles()
	create_latent_particles()
	create_flow_particles()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate training progress
	training_progress = min(1.0, time * 0.1)
	reconstruction_loss = max(0.1, 1.0 - training_progress * 0.8)
	kl_divergence = max(0.1, 1.0 - training_progress * 0.6)
	
	animate_encoder(delta)
	animate_latent_space(delta)
	animate_decoder(delta)
	animate_reconstruction_loss(delta)
	animate_data_flow(delta)
	update_training_metrics(delta)

func create_input_particles():
	# Create input data particles
	var input_particles = $InputData/InputParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles in a cluster around input
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		input_particles.add_child(particle)

func create_output_particles():
	# Create output data particles
	var output_particles = $OutputData/OutputParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles in a cluster around output
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		output_particles.add_child(particle)

func create_latent_particles():
	# Create latent space particles
	var latent_particles_node = $LatentSpace/LatentParticles
	for i in range(15):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles in a spherical distribution around latent core
		var angle1 = randf_range(0, PI * 2)
		var angle2 = randf_range(0, PI)
		var radius = randf_range(0.5, 1.5)
		
		var x = cos(angle1) * sin(angle2) * radius
		var y = sin(angle1) * sin(angle2) * radius
		var z = cos(angle2) * radius
		
		particle.position = Vector3(x, y, z)
		
		latent_particles_node.add_child(particle)
		latent_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles along the VAE flow path
		var progress = float(i) / 25
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 2) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_training_metrics():
	# Initialize loss meters
	var loss_indicator = $TrainingMetrics/ReconstructionLossMeter/LossIndicator
	var kl_indicator = $TrainingMetrics/KLDivergenceMeter/KLIndicator
	if loss_indicator:
		loss_indicator.position.x = 0  # Start at middle
	if kl_indicator:
		kl_indicator.position.x = 0  # Start at middle

func animate_encoder(delta):
	# Animate encoder core
	var encoder_core = $Encoder/EncoderCore
	if encoder_core:
		# Rotate encoder
		encoder_core.rotation.y += delta * 0.6
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * training_progress
		encoder_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on training
		if encoder_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			encoder_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_latent_space(delta):
	# Animate latent space core
	var latent_core = $LatentSpace/LatentCore
	if latent_core:
		# Rotate latent space
		latent_core.rotation.y += delta * 0.4
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 1.8) * 0.15 * training_progress
		latent_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on training
		if latent_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			latent_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate latent particles
	for i in range(latent_particles.size()):
		var particle = latent_particles[i]
		if particle:
			# Move particles in a flowing pattern within latent space
			var flow_x = sin(time * 0.8 + i * 0.2) * 0.3
			var flow_y = cos(time * 1.2 + i * 0.3) * 0.3
			var flow_z = sin(time * 1.0 + i * 0.25) * 0.3
			
			particle.position.x = lerp(particle.position.x, flow_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, flow_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, flow_z, delta * 1.5)
			
			# Pulse particles based on training
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress
			particle.scale = Vector3.ONE * pulse

func animate_decoder(delta):
	# Animate decoder core
	var decoder_core = $Decoder/DecoderCore
	if decoder_core:
		# Rotate decoder
		decoder_core.rotation.y += delta * 0.7
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 2.2) * 0.1 * training_progress
		decoder_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on training
		if decoder_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			decoder_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_reconstruction_loss(delta):
	# Animate reconstruction loss core
	var loss_core = $ReconstructionLoss/LossCore
	if loss_core:
		# Rotate loss core
		loss_core.rotation.y += delta * 0.8
		
		# Pulse based on loss value
		var pulse = 1.0 + sin(time * 2.5) * 0.2 * (1.0 - reconstruction_loss)
		loss_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on loss
		if loss_core.material_override:
			var intensity = 0.3 + (1.0 - reconstruction_loss) * 0.7
			loss_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the VAE flow
			var progress = fmod(time * 0.25 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 2) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and training progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var green_component = 0.8 * (1.0 - color_progress * 0.5) * training_progress
			var blue_component = 0.8 * (0.5 + color_progress * 0.5) * training_progress
			particle.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)
			particle.material_override.emission = Color(0.2, green_component, blue_component, 1) * 0.3
			
			# Pulse particles based on training
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress
			particle.scale = Vector3.ONE * pulse

func update_training_metrics(delta):
	# Update reconstruction loss meter
	var loss_indicator = $TrainingMetrics/ReconstructionLossMeter/LossIndicator
	if loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - reconstruction_loss)
		loss_indicator.position.x = lerp(loss_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on loss
		var green_component = 0.8 * (1.0 - reconstruction_loss)
		var red_component = 0.2 + 0.6 * reconstruction_loss
		loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update KL divergence meter
	var kl_indicator = $TrainingMetrics/KLDivergenceMeter/KLIndicator
	if kl_indicator:
		var target_x = lerp(-2, 2, 1.0 - kl_divergence)
		kl_indicator.position.x = lerp(kl_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on KL divergence
		var green_component = 0.8 * (1.0 - kl_divergence)
		var red_component = 0.2 + 0.6 * kl_divergence
		kl_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_training_progress(progress: float):
	training_progress = clamp(progress, 0.0, 1.0)

func set_reconstruction_loss(loss: float):
	reconstruction_loss = clamp(loss, 0.1, 1.0)

func set_kl_divergence(kl: float):
	kl_divergence = clamp(kl, 0.1, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_reconstruction_loss() -> float:
	return reconstruction_loss

func get_kl_divergence() -> float:
	return kl_divergence

func reset_training():
	time = 0.0
	training_progress = 0.0
	reconstruction_loss = 1.0
	kl_divergence = 1.0
