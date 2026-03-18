# ============================================================================
# Variational Autoencoders (VAE) Visualization
# Interactive 3D visualization of the VAE architecture showing encoder,
# latent space distribution, decoder, reconstruction quality, and data flow
# with live training metrics for reconstruction loss and KL divergence.
# ============================================================================
extends Node3D
class_name VAEShowcase

# --- Runtime UI Controls ---
@export_category("Data Settings")
@export_range(10, 40, 1) var particle_count: int = 20 : set = _set_particle_count
@export_range(5, 25, 1) var latent_particle_count: int = 15

@export_category("Animation")
@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export_range(0.5, 3.0, 0.1) var pulse_intensity: float = 1.0
@export_range(0.5, 3.0, 0.1) var latent_spread: float = 1.5

@export_category("Training Simulation")
@export_range(0.01, 0.5, 0.01) var training_rate: float = 0.1
@export var auto_train: bool = true

@export_category("Colors")
@export var color_input := Color(1.0, 0.85, 0.2, 1.0)        # Gold for input data
@export var color_output := Color(0.3, 0.5, 0.9, 1.0)        # Blue for output
@export var color_encoder := Color(0.3, 0.85, 0.4, 1.0)      # Green for encoder
@export var color_latent := Color(0.8, 0.3, 0.9, 1.0)        # Purple for latent space
@export var color_decoder := Color(0.9, 0.3, 0.3, 1.0)       # Red for decoder
@export var color_flow := Color(0.3, 0.85, 0.85, 1.0)        # Cyan for data flow

# --- Internal State ---
var time: float = 0.0
var training_progress: float = 0.0
var reconstruction_loss: float = 1.0
var kl_divergence: float = 1.0
var flow_particles: Array = []
var latent_particles: Array = []
var _stats_label: Label3D
var _loss_label: Label3D

func _set_particle_count(v: int) -> void:
	particle_count = v
	if not is_node_ready():
		return
	_clear_children($InputData/InputParticles)
	_clear_children($OutputData/OutputParticles)
	create_input_particles()
	create_output_particles()

func _ready() -> void:
	print("Variational Autoencoders Visualization initialized")
	create_input_particles()
	create_output_particles()
	create_latent_particles()
	create_flow_particles()
	setup_training_metrics()
	_create_stats_labels()

func _process(delta: float) -> void:
	var scaled_delta = delta * animation_speed
	time += scaled_delta
	
	# Simulate training progress with configurable rate
	if auto_train:
		training_progress = min(1.0, time * training_rate)
		reconstruction_loss = max(0.1, 1.0 - training_progress * 0.8)
		kl_divergence = max(0.1, 1.0 - training_progress * 0.6)
	
	animate_encoder(scaled_delta)
	animate_latent_space(scaled_delta)
	animate_decoder(scaled_delta)
	animate_reconstruction_loss(scaled_delta)
	animate_data_flow(scaled_delta)
	update_training_metrics(scaled_delta)
	_update_stats_labels()

# ============================================================================
# Particle Creation — Input, Output, Latent, and Flow
# ============================================================================

func create_input_particles() -> void:
	## Create input data particles with gold metallic materials
	var input_particles = $InputData/InputParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_input
		mat.emission_enabled = true
		mat.emission = color_input * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.5
		mat.roughness = 0.35
		particle.material_override = mat
		
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		# Staggered pop-in animation
		particle.scale = Vector3.ZERO
		input_particles.add_child(particle)
		var tween = create_tween()
		tween.tween_property(particle, "scale", Vector3.ONE, 0.3).set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_output_particles() -> void:
	## Create output/reconstructed data particles with blue materials
	var output_particles = $OutputData/OutputParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_output
		mat.emission_enabled = true
		mat.emission = color_output * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.5
		mat.roughness = 0.35
		particle.material_override = mat
		
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		particle.scale = Vector3.ZERO
		output_particles.add_child(particle)
		var tween = create_tween()
		tween.tween_property(particle, "scale", Vector3.ONE, 0.3).set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_latent_particles() -> void:
	## Create latent space particles — purple glow, spherical distribution
	var latent_particles_node = $LatentSpace/LatentParticles
	for i in range(latent_particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_latent
		mat.emission_enabled = true
		mat.emission = color_latent * 0.6
		mat.emission_energy_multiplier = 2.0
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.9
		particle.material_override = mat
		
		# Spherical distribution around latent core
		var angle1 = randf_range(0, PI * 2)
		var angle2 = randf_range(0, PI)
		var radius = randf_range(0.5, latent_spread)
		var x = cos(angle1) * sin(angle2) * radius
		var y = sin(angle1) * sin(angle2) * radius
		var z = cos(angle2) * radius
		particle.position = Vector3(x, y, z)
		
		latent_particles_node.add_child(particle)
		latent_particles.append(particle)

func create_flow_particles() -> void:
	## Create data flow particles with glowing cyan trail
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_flow
		mat.emission_enabled = true
		mat.emission = color_flow * 0.6
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.8
		particle.material_override = mat
		
		var progress = float(i) / 25
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 2) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_training_metrics() -> void:
	## Initialize loss and KL divergence meter positions
	var loss_indicator = $TrainingMetrics/ReconstructionLossMeter/LossIndicator
	var kl_indicator = $TrainingMetrics/KLDivergenceMeter/KLIndicator
	if loss_indicator:
		loss_indicator.position.x = 0
	if kl_indicator:
		kl_indicator.position.x = 0

# ============================================================================
# Animation — Encoder, Latent Space, Decoder, Reconstruction
# ============================================================================

func animate_encoder(delta) -> void:
	## Animate encoder core — green glow intensifies with training
	var encoder_core = $Encoder/EncoderCore
	if encoder_core:
		encoder_core.rotation.y += delta * 0.6
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * training_progress * pulse_intensity
		encoder_core.scale = Vector3.ONE * pulse
		if encoder_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			encoder_core.material_override.emission = color_encoder * intensity
			encoder_core.material_override.emission_energy_multiplier = 1.0 + training_progress

func animate_latent_space(delta) -> void:
	## Animate latent space core and distribution particles
	var latent_core = $LatentSpace/LatentCore
	if latent_core:
		latent_core.rotation.y += delta * 0.4
		var pulse = 1.0 + sin(time * 1.8) * 0.15 * training_progress * pulse_intensity
		latent_core.scale = Vector3.ONE * pulse
		if latent_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			latent_core.material_override.emission = color_latent * intensity
			latent_core.material_override.emission_energy_multiplier = 1.0 + training_progress * 0.8
	
	# Animate latent distribution particles — tighten distribution as training progresses
	for i in range(latent_particles.size()):
		var particle = latent_particles[i]
		if particle:
			# Particles converge toward center as KL divergence decreases
			var convergence = 1.0 - kl_divergence * 0.5
			var flow_x = sin(time * 0.8 + i * 0.2) * 0.3 * latent_spread * (1.0 + kl_divergence)
			var flow_y = cos(time * 1.2 + i * 0.3) * 0.3 * latent_spread * (1.0 + kl_divergence)
			var flow_z = sin(time * 1.0 + i * 0.25) * 0.3 * latent_spread * (1.0 + kl_divergence)
			
			particle.position.x = lerp(particle.position.x, flow_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, flow_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, flow_z, delta * 1.5)
			
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress * pulse_intensity
			particle.scale = Vector3.ONE * pulse

func animate_decoder(delta) -> void:
	## Animate decoder core — red glow intensifies with training
	var decoder_core = $Decoder/DecoderCore
	if decoder_core:
		decoder_core.rotation.y += delta * 0.7
		var pulse = 1.0 + sin(time * 2.2) * 0.1 * training_progress * pulse_intensity
		decoder_core.scale = Vector3.ONE * pulse
		if decoder_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			decoder_core.material_override.emission = color_decoder * intensity
			decoder_core.material_override.emission_energy_multiplier = 1.0 + training_progress

func animate_reconstruction_loss(delta) -> void:
	## Animate reconstruction loss indicator
	var loss_core = $ReconstructionLoss/LossCore
	if loss_core:
		loss_core.rotation.y += delta * 0.8
		var pulse = 1.0 + sin(time * 2.5) * 0.2 * (1.0 - reconstruction_loss) * pulse_intensity
		loss_core.scale = Vector3.ONE * pulse
		if loss_core.material_override:
			# Shift from red (high loss) to green (low loss)
			var health = 1.0 - reconstruction_loss
			var loss_color = color_decoder.lerp(color_encoder, health)
			loss_core.material_override.emission = loss_color * (0.3 + health * 0.7)
			loss_core.material_override.emission_energy_multiplier = 1.0 + health

func animate_data_flow(delta) -> void:
	## Animate flow particles through encoder → latent → decoder pipeline
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			var progress = fmod(time * 0.25 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 2) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Color shifts through the pipeline: gold → purple → blue
			var flow_color: Color
			if progress < 0.33:
				flow_color = color_input.lerp(color_latent, progress / 0.33)
			elif progress < 0.66:
				flow_color = color_latent.lerp(color_output, (progress - 0.33) / 0.33)
			else:
				flow_color = color_output
			
			particle.material_override.albedo_color = Color(flow_color.r, flow_color.g, flow_color.b, 0.8)
			particle.material_override.emission = flow_color * 0.6 * training_progress
			
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress * pulse_intensity
			particle.scale = Vector3.ONE * pulse

# ============================================================================
# Training Metrics — Loss and KL divergence meters
# ============================================================================

func update_training_metrics(delta) -> void:
	## Update reconstruction loss meter
	var loss_indicator = $TrainingMetrics/ReconstructionLossMeter/LossIndicator
	if loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - reconstruction_loss)
		loss_indicator.position.x = lerp(loss_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * (1.0 - reconstruction_loss)
		var red_component = 0.2 + 0.6 * reconstruction_loss
		loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	## Update KL divergence meter
	var kl_indicator = $TrainingMetrics/KLDivergenceMeter/KLIndicator
	if kl_indicator:
		var target_x = lerp(-2, 2, 1.0 - kl_divergence)
		kl_indicator.position.x = lerp(kl_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * (1.0 - kl_divergence)
		var red_component = 0.2 + 0.6 * kl_divergence
		kl_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

# ============================================================================
# Public API
# ============================================================================

func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func set_reconstruction_loss(loss: float) -> void:
	reconstruction_loss = clamp(loss, 0.1, 1.0)

func set_kl_divergence(kl: float) -> void:
	kl_divergence = clamp(kl, 0.1, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_reconstruction_loss() -> float:
	return reconstruction_loss

func get_kl_divergence() -> float:
	return kl_divergence

func reset_training() -> void:
	## Reset all training state with visual feedback
	time = 0.0
	training_progress = 0.0
	reconstruction_loss = 1.0
	kl_divergence = 1.0
	if _stats_label:
		var tween = create_tween()
		tween.tween_property(_stats_label, "modulate", Color(0.8, 0.3, 0.9), 0.15)
		tween.tween_property(_stats_label, "modulate", Color.WHITE, 0.3)

# ============================================================================
# Stats Labels — Live HUD in 3D space
# ============================================================================

func _create_stats_labels() -> void:
	_stats_label = Label3D.new()
	_stats_label.text = "Recon Loss: 1.000 | KL: 1.000"
	_stats_label.font_size = 28
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 4.5, 0)
	add_child(_stats_label)
	
	_loss_label = Label3D.new()
	_loss_label.text = "VAE Architecture"
	_loss_label.font_size = 22
	_loss_label.outline_size = 3
	_loss_label.modulate = Color(0.8, 0.7, 0.9)
	_loss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_loss_label.position = Vector3(0, 5.2, 0)
	add_child(_loss_label)

func _update_stats_labels() -> void:
	if _stats_label:
		_stats_label.text = "Recon Loss: %.3f | KL Div: %.3f" % [reconstruction_loss, kl_divergence]
		var health = 1.0 - (reconstruction_loss + kl_divergence) * 0.5
		_stats_label.modulate = Color(
			0.9 - health * 0.6,
			0.3 + health * 0.65,
			0.2 + health * 0.3, 1.0
		)
	if _loss_label:
		var total_loss = reconstruction_loss + kl_divergence * 0.5
		_loss_label.text = "VAE | Progress: %.0f%% | Total Loss: %.3f" % [training_progress * 100.0, total_loss]

# ============================================================================
# Utility
# ============================================================================

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
