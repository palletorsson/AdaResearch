# ============================================================================
# Generative Adversarial Networks (GAN) Visualization
# Interactive 3D visualization of the GAN architecture showing generator,
# discriminator, adversarial competition, noise input, real/fake data
# distribution, and feedback loops with live training metrics.
# ============================================================================
extends Node3D
class_name GANShowcase

# --- Runtime UI Controls ---
@export_category("Data Settings")
@export_range(10, 40, 1) var particle_count: int = 20 : set = _set_particle_count

@export_category("Animation")
@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export_range(0.5, 3.0, 0.1) var pulse_intensity: float = 1.0
@export_range(0.1, 1.0, 0.05) var competition_speed: float = 0.3

@export_category("Training Simulation")
@export_range(0.01, 0.5, 0.01) var training_rate: float = 0.1
@export var auto_train: bool = true

@export_category("Colors")
@export var color_noise := Color(1.0, 0.85, 0.2, 1.0)       # Gold for noise input
@export var color_real_data := Color(0.3, 0.85, 0.4, 1.0)    # Green for real data
@export var color_fake_data := Color(0.8, 0.3, 0.9, 1.0)     # Purple for generated data
@export var color_generator := Color(0.3, 0.85, 0.4, 1.0)    # Green for generator
@export var color_discriminator := Color(0.9, 0.3, 0.3, 1.0)  # Red for discriminator
@export var color_feedback := Color(0.3, 0.85, 0.85, 1.0)    # Cyan for feedback loop
@export var color_competition := Color(1.0, 0.85, 0.2, 1.0)  # Gold for competition

# --- Internal State ---
var time: float = 0.0
var training_progress: float = 0.0
var generator_loss: float = 1.0
var discriminator_loss: float = 1.0
var competition_level: float = 0.0
var _stats_label: Label3D
var _competition_label: Label3D

func _set_particle_count(v: int) -> void:
	particle_count = v
	if not is_node_ready():
		return
	_clear_children($Generator/GeneratorInput/NoiseParticles)
	_clear_children($Discriminator/DiscriminatorInput/RealData)
	_clear_children($Discriminator/DiscriminatorInput/GeneratedData)
	_clear_children($FeedbackLoop/FeedbackParticles)
	create_noise_particles()
	create_data_particles()
	create_feedback_particles()

func _ready() -> void:
	print("Generative Adversarial Networks Visualization initialized")
	create_noise_particles()
	create_data_particles()
	create_feedback_particles()
	setup_training_metrics()
	_create_stats_labels()

func _process(delta: float) -> void:
	var scaled_delta = delta * animation_speed
	time += scaled_delta
	
	# Simulate training progress and adversarial dynamics
	if auto_train:
		training_progress = min(1.0, time * training_rate)
		competition_level = training_progress * 0.8
		generator_loss = max(0.1, 1.0 - training_progress * 0.7)
		discriminator_loss = max(0.1, 0.5 + training_progress * 0.3)
	
	animate_generator(scaled_delta)
	animate_discriminator(scaled_delta)
	animate_competition(scaled_delta)
	animate_data_flow(scaled_delta)
	animate_feedback_loop(scaled_delta)
	update_training_metrics(scaled_delta)
	_update_stats_labels()

# ============================================================================
# Particle Creation — Noise, Real/Fake Data, Feedback
# ============================================================================

func create_noise_particles() -> void:
	## Create noise particles for generator input — gold sparks
	var noise_particles = $Generator/GeneratorInput/NoiseParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_noise
		mat.emission_enabled = true
		mat.emission = color_noise * 0.6
		mat.emission_energy_multiplier = 1.8
		mat.metallic = 0.4
		mat.roughness = 0.3
		particle.material_override = mat
		
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		particle.scale = Vector3.ZERO
		noise_particles.add_child(particle)
		var tween = create_tween()
		tween.tween_property(particle, "scale", Vector3.ONE, 0.3).set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_data_particles() -> void:
	## Create real data particles (green) and generated data particles (purple)
	var real_data = $Discriminator/DiscriminatorInput/RealData
	for i in range(particle_count / 2):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_real_data
		mat.emission_enabled = true
		mat.emission = color_real_data * 0.5
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.5
		mat.roughness = 0.3
		particle.material_override = mat
		
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		real_data.add_child(particle)
	
	var generated_data = $Discriminator/DiscriminatorInput/GeneratedData
	for i in range(particle_count / 2):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_fake_data
		mat.emission_enabled = true
		mat.emission = color_fake_data * 0.5
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.3
		mat.roughness = 0.4
		particle.material_override = mat
		
		var x = randf_range(-1, 1)
		var y = randf_range(-1, 1)
		var z = randf_range(-1, 1)
		particle.position = Vector3(x, y, z)
		generated_data.add_child(particle)

func create_feedback_particles() -> void:
	## Create feedback loop particles — cyan glow in a ring
	var feedback_particles = $FeedbackLoop/FeedbackParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.03
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_feedback
		mat.emission_enabled = true
		mat.emission = color_feedback * 0.6
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.8
		particle.material_override = mat
		
		var angle = float(i) / particle_count * PI * 2
		var radius = 4.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		particle.position = Vector3(x, 0, z)
		
		feedback_particles.add_child(particle)

func setup_training_metrics() -> void:
	## Initialize loss meter positions
	var gen_loss_indicator = $TrainingMetrics/GeneratorLoss/GenLossIndicator
	var disc_loss_indicator = $TrainingMetrics/DiscriminatorLoss/DiscLossIndicator
	if gen_loss_indicator:
		gen_loss_indicator.position.x = 0
	if disc_loss_indicator:
		disc_loss_indicator.position.x = 0

# ============================================================================
# Animation — Generator, Discriminator, Competition, Feedback
# ============================================================================

func animate_generator(delta) -> void:
	## Animate generator core — green glow, noise particles swirl
	var generator_core = $Generator/GeneratorCore
	if generator_core:
		generator_core.rotation.y += delta * 0.8
		var pulse = 1.0 + sin(time * 2.0) * 0.2 * training_progress * pulse_intensity
		generator_core.scale = Vector3.ONE * pulse
		if generator_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			generator_core.material_override.emission = color_generator * intensity
			generator_core.material_override.emission_energy_multiplier = 1.0 + training_progress
	
	## Animate noise particles in a turbulent swirl pattern
	var noise_particles = $Generator/GeneratorInput/NoiseParticles
	for i in range(noise_particles.get_child_count()):
		var particle = noise_particles.get_child(i)
		if particle:
			var flow_x = sin(time * 1.0 + i * 0.2) * 0.5
			var flow_y = cos(time * 1.5 + i * 0.3) * 0.5
			var flow_z = sin(time * 0.8 + i * 0.4) * 0.5
			particle.position.x = lerp(particle.position.x, flow_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, flow_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, flow_z, delta * 2.0)
			var pulse = 1.0 + sin(time * 3.0 + i * 0.5) * 0.3 * pulse_intensity
			particle.scale = Vector3.ONE * pulse

func animate_discriminator(delta) -> void:
	## Animate discriminator core — red glow, data particles converge
	var discriminator_core = $Discriminator/DiscriminatorCore
	if discriminator_core:
		discriminator_core.rotation.y += delta * 1.2
		var pulse = 1.0 + sin(time * 2.5) * 0.2 * training_progress * pulse_intensity
		discriminator_core.scale = Vector3.ONE * pulse
		if discriminator_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			discriminator_core.material_override.emission = color_discriminator * intensity
			discriminator_core.material_override.emission_energy_multiplier = 1.0 + training_progress
	
	## Animate real data — subtle, stable movement (established distribution)
	var real_data = $Discriminator/DiscriminatorInput/RealData
	for i in range(real_data.get_child_count()):
		var particle = real_data.get_child(i)
		if particle:
			var move_x = sin(time * 0.8 + i * 0.1) * 0.2
			var move_y = cos(time * 1.2 + i * 0.15) * 0.2
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
	
	## Animate generated data — more dynamic, converging toward real data as training progresses
	var generated_data = $Discriminator/DiscriminatorInput/GeneratedData
	for i in range(generated_data.get_child_count()):
		var particle = generated_data.get_child(i)
		if particle:
			# As training progresses, generated data moves more like real data
			var chaos = 1.0 - training_progress * 0.6
			var move_x = sin(time * 1.5 + i * 0.2) * 0.3 * chaos
			var move_y = cos(time * 2.0 + i * 0.25) * 0.3 * chaos
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			# Shift color from purple toward green as generator improves
			if particle.material_override:
				var blend_color = color_fake_data.lerp(color_real_data, training_progress * 0.5)
				particle.material_override.emission = blend_color * (0.3 + training_progress * 0.4)

func animate_competition(delta) -> void:
	## Animate competition core — pulsing gold arena
	var competition_core = $Competition/CompetitionCore
	if competition_core:
		competition_core.rotation.y += delta * 0.6 * (1.0 + competition_level)
		var target_scale = 3.0 + competition_level * 2.0
		competition_core.scale = Vector3.ONE * lerp(competition_core.scale.x, target_scale, delta * 2.0)
		if competition_core.material_override:
			# Warm gold that intensifies with competition
			var comp_color = color_competition * (0.3 + competition_level * 0.7)
			competition_core.material_override.albedo_color = Color(
				0.2 + competition_level * 0.6,
				0.2 + competition_level * 0.3,
				0.2, 1.0
			)
			competition_core.material_override.emission = comp_color
			competition_core.material_override.emission_energy_multiplier = 1.0 + competition_level

func animate_data_flow(_delta) -> void:
	## Placeholder for data flow connections (generator → discriminator)
	pass

func animate_feedback_loop(delta) -> void:
	## Animate feedback particles in an orbiting ring pattern
	var feedback_particles = $FeedbackLoop/FeedbackParticles
	for i in range(feedback_particles.get_child_count()):
		var particle = feedback_particles.get_child(i)
		if particle:
			var progress = fmod(time * competition_speed + float(i) * 0.1, 1.0)
			var angle = progress * PI * 2
			var radius = 4.0
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.z = lerp(particle.position.z, z, delta * 2.0)
			
			# Color shifts through the feedback loop
			var color_progress = fmod((progress + 0.5), 1.0)
			var loop_color = color_generator.lerp(color_discriminator, color_progress)
			particle.material_override.albedo_color = Color(loop_color.r, loop_color.g, loop_color.b, 0.8)
			particle.material_override.emission = loop_color * 0.6
			
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * pulse_intensity
			particle.scale = Vector3.ONE * pulse

# ============================================================================
# Training Metrics — Generator and discriminator loss meters
# ============================================================================

func update_training_metrics(delta) -> void:
	## Update generator loss meter
	var gen_loss_indicator = $TrainingMetrics/GeneratorLoss/GenLossIndicator
	if gen_loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - generator_loss)
		gen_loss_indicator.position.x = lerp(gen_loss_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * (1.0 - generator_loss)
		var red_component = 0.2 + 0.6 * generator_loss
		gen_loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	## Update discriminator loss meter
	var disc_loss_indicator = $TrainingMetrics/DiscriminatorLoss/DiscLossIndicator
	if disc_loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - discriminator_loss)
		disc_loss_indicator.position.x = lerp(disc_loss_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * (1.0 - discriminator_loss)
		var red_component = 0.2 + 0.6 * discriminator_loss
		disc_loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

# ============================================================================
# Public API
# ============================================================================

func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func set_generator_loss(loss: float) -> void:
	generator_loss = clamp(loss, 0.1, 1.0)

func set_discriminator_loss(loss: float) -> void:
	discriminator_loss = clamp(loss, 0.1, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_generator_loss() -> float:
	return generator_loss

func get_discriminator_loss() -> float:
	return discriminator_loss

func reset_training() -> void:
	## Reset all training state with visual feedback
	time = 0.0
	training_progress = 0.0
	generator_loss = 1.0
	discriminator_loss = 1.0
	competition_level = 0.0
	if _stats_label:
		var tween = create_tween()
		tween.tween_property(_stats_label, "modulate", Color(1.0, 0.85, 0.2), 0.15)
		tween.tween_property(_stats_label, "modulate", Color.WHITE, 0.3)

# ============================================================================
# Stats Labels — Live HUD in 3D space
# ============================================================================

func _create_stats_labels() -> void:
	_stats_label = Label3D.new()
	_stats_label.text = "Gen Loss: 1.000 | Disc Loss: 1.000"
	_stats_label.font_size = 28
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 5.0, 0)
	add_child(_stats_label)
	
	_competition_label = Label3D.new()
	_competition_label.text = "GAN — Adversarial Training"
	_competition_label.font_size = 22
	_competition_label.outline_size = 3
	_competition_label.modulate = Color(1.0, 0.85, 0.7)
	_competition_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_competition_label.position = Vector3(0, 5.8, 0)
	add_child(_competition_label)

func _update_stats_labels() -> void:
	if _stats_label:
		_stats_label.text = "Gen Loss: %.3f | Disc Loss: %.3f" % [generator_loss, discriminator_loss]
		# Generator health = low gen loss, Discriminator health = balanced
		var gen_health = 1.0 - generator_loss
		_stats_label.modulate = Color(
			0.9 - gen_health * 0.6,
			0.3 + gen_health * 0.65,
			0.2, 1.0
		)
	if _competition_label:
		var balance = "Balanced" if abs(generator_loss - discriminator_loss) < 0.3 else "Imbalanced"
		_competition_label.text = "GAN | Competition: %.0f%% | %s" % [competition_level * 100.0, balance]

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
