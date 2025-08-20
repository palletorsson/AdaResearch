extends Node3D
class_name OptimizationAlgorithms

var time: float = 0.0
var optimization_progress: float = 0.0
var loss_value: float = 1.0  # Start high, decrease over time
var learning_rate: float = 0.5
var particle_count: int = 25
var flow_particles: Array = []
var landscape_particles: Array = []
var convergence_particles: Array = []
var gradient_vectors: Array = []

func _ready():
	# Initialize Optimization Algorithms visualization
	print("Optimization Algorithms Visualization initialized")
	create_landscape_particles()
	create_convergence_particles()
	create_gradient_vectors()
	create_flow_particles()
	setup_optimization_metrics()

func _process(delta):
	time += delta
	
	# Simulate optimization progress
	optimization_progress = min(1.0, time * 0.1)
	loss_value = 1.0 - (optimization_progress * 0.9)  # Loss decreases as optimization progresses
	learning_rate = 0.1 + sin(time * 0.5) * 0.05  # Learning rate oscillates
	
	animate_loss_landscape(delta)
	animate_optimization_core(delta)
	animate_convergence(delta)
	animate_gradient_flow(delta)
	animate_data_flow(delta)
	update_optimization_metrics(delta)

func create_landscape_particles():
	# Create loss landscape particles representing the loss surface
	var landscape_particles_node = $LossLandscape/LandscapeParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles in a landscape pattern
		var grid_size = 5
		var row = i / grid_size
		var col = i % grid_size
		var x = (col - grid_size/2.0 + 0.5) * 0.8
		var z = (row - grid_size/2.0 + 0.5) * 0.8
		# Create a loss landscape with multiple local minima
		var y = sin(x * 2) * cos(z * 2) * 0.5 + sin(x * 0.5) * 0.3
		particle.position = Vector3(x, y, z)
		
		landscape_particles_node.add_child(particle)
		landscape_particles.append(particle)

func create_convergence_particles():
	# Create convergence particles showing optimization path
	var convergence_particles_node = $Convergence/ConvergenceParticles
	for i in range(20):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position particles along convergence path
		var progress = float(i) / 20
		var spiral_radius = 2.0 - progress * 1.5  # Spiral inward
		var angle = progress * PI * 4
		var x = cos(angle) * spiral_radius
		var y = sin(angle) * spiral_radius
		var z = (progress - 0.5) * 0.5
		particle.position = Vector3(x, y, z)
		
		convergence_particles_node.add_child(particle)
		convergence_particles.append(particle)

func create_gradient_vectors():
	# Create gradient vector particles
	var gradient_vectors_node = $GradientFlow/GradientVectors
	for i in range(15):
		var vector = CSGBox3D.new()
		vector.size = Vector3(0.1, 0.1, 0.8)
		vector.material_override = StandardMaterial3D.new()
		vector.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
		vector.material_override.emission_enabled = true
		vector.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.2
		vector.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position gradient vectors in flow space
		var angle = float(i) / 15.0 * PI * 2
		var radius = 2.0
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.2, 0.2)
		vector.position = Vector3(x, y, z)
		
		# Rotate vectors to point towards gradient direction
		vector.rotation.z = angle + PI/2
		
		gradient_vectors_node.add_child(vector)
		gradient_vectors.append(vector)

func create_flow_particles():
	# Create optimization flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(40):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the optimization flow path
		var progress = float(i) / 40
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 6) * 2.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_optimization_metrics():
	# Initialize optimization metrics
	var loss_indicator = $OptimizationMetrics/LossMeter/LossIndicator
	var lr_indicator = $OptimizationMetrics/LearningRateMeter/LearningRateIndicator
	if loss_indicator:
		loss_indicator.position.x = 2  # Start high (right side)
	if lr_indicator:
		lr_indicator.position.x = 0  # Start at middle

func animate_loss_landscape(delta):
	# Animate loss landscape particles
	for i in range(landscape_particles.size()):
		var particle = landscape_particles[i]
		if particle:
			# Move particles to show changing loss landscape
			var base_pos = particle.position
			var landscape_shift = sin(time * 0.5 + i * 0.1) * 0.1
			var move_y = base_pos.y + landscape_shift
			
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			
			# Pulse particles based on optimization progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * optimization_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on loss value at this point
			var local_loss = abs(base_pos.y) + 0.5
			var red_component = 0.8 * local_loss
			var blue_component = 0.8 * (1.0 - local_loss)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)

func animate_optimization_core(delta):
	# Animate optimizer hub
	var optimizer_hub = $OptimizationCore/OptimizerHub
	if optimizer_hub:
		# Rotate optimizer hub
		optimizer_hub.rotation.y += delta * 0.5
		
		# Pulse based on optimization progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * optimization_progress
		optimizer_hub.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on optimization
		if optimizer_hub.material_override:
			var intensity = 0.3 + optimization_progress * 0.7
			optimizer_hub.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate optimizer method cores
	var sgd_core = $OptimizationCore/OptimizerMethods/SGDCore
	if sgd_core:
		sgd_core.rotation.y += delta * 0.8
		var sgd_activation = sin(time * 1.5) * 0.5 + 0.5
		sgd_activation *= optimization_progress
		
		var pulse = 1.0 + sgd_activation * 0.3
		sgd_core.scale = Vector3.ONE * pulse
		
		if sgd_core.material_override:
			var intensity = 0.3 + sgd_activation * 0.7
			sgd_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var adam_core = $OptimizationCore/OptimizerMethods/AdamCore
	if adam_core:
		adam_core.rotation.y += delta * 1.0
		var adam_activation = cos(time * 1.8) * 0.5 + 0.5
		adam_activation *= optimization_progress
		
		var pulse = 1.0 + adam_activation * 0.3
		adam_core.scale = Vector3.ONE * pulse
		
		if adam_core.material_override:
			var intensity = 0.3 + adam_activation * 0.7
			adam_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var rmsprop_core = $OptimizationCore/OptimizerMethods/RMSpropCore
	if rmsprop_core:
		rmsprop_core.rotation.y += delta * 1.2
		var rmsprop_activation = sin(time * 2.0) * 0.5 + 0.5
		rmsprop_activation *= optimization_progress
		
		var pulse = 1.0 + rmsprop_activation * 0.3
		rmsprop_core.scale = Vector3.ONE * pulse
		
		if rmsprop_core.material_override:
			var intensity = 0.3 + rmsprop_activation * 0.7
			rmsprop_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var adagrad_core = $OptimizationCore/OptimizerMethods/AdagradCore
	if adagrad_core:
		adagrad_core.rotation.y += delta * 0.9
		var adagrad_activation = cos(time * 1.6) * 0.5 + 0.5
		adagrad_activation *= optimization_progress
		
		var pulse = 1.0 + adagrad_activation * 0.3
		adagrad_core.scale = Vector3.ONE * pulse
		
		if adagrad_core.material_override:
			var intensity = 0.3 + adagrad_activation * 0.7
			adagrad_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var momentum_core = $OptimizationCore/OptimizerMethods/MomentumCore
	if momentum_core:
		momentum_core.rotation.y += delta * 1.1
		var momentum_activation = sin(time * 1.7) * 0.5 + 0.5
		momentum_activation *= optimization_progress
		
		var pulse = 1.0 + momentum_activation * 0.3
		momentum_core.scale = Vector3.ONE * pulse
		
		if momentum_core.material_override:
			var intensity = 0.3 + momentum_activation * 0.7
			momentum_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_convergence(delta):
	# Animate convergence particles
	for i in range(convergence_particles.size()):
		var particle = convergence_particles[i]
		if particle:
			# Move particles along convergence spiral
			var progress = fmod(float(i) / 20 + time * 0.1, 1.0)
			var spiral_radius = 2.0 - progress * 1.5
			var angle = progress * PI * 4
			var move_x = cos(angle) * spiral_radius
			var move_y = sin(angle) * spiral_radius
			var move_z = (progress - 0.5) * 0.5
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on convergence
			var pulse = 1.0 + sin(time * 2.2 + i * 0.3) * 0.3 * optimization_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on convergence progress
			var convergence = 1.0 - spiral_radius / 2.0
			var green_component = 0.8 * convergence
			var red_component = 0.2 + 0.6 * (1.0 - convergence)
			particle.material_override.albedo_color = Color(red_component, green_component, 0.8, 1)

func animate_gradient_flow(delta):
	# Animate gradient flow core
	var gradient_core = $GradientFlow/GradientCore
	if gradient_core:
		# Rotate gradient flow
		gradient_core.rotation.y += delta * 0.3
		
		# Pulse based on optimization progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * optimization_progress
		gradient_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on optimization
		if gradient_core.material_override:
			var intensity = 0.3 + optimization_progress * 0.7
			gradient_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate gradient vectors
	for i in range(gradient_vectors.size()):
		var vector = gradient_vectors[i]
		if vector:
			# Move vectors in gradient flow pattern
			var base_pos = vector.position
			var gradient_strength = sin(time * 1.0 + i * 0.4) * 0.5 + 0.5
			gradient_strength *= optimization_progress
			
			var move_scale_z = 0.8 + gradient_strength * 0.6
			vector.scale.z = lerp(vector.scale.z, move_scale_z, delta * 2.0)
			
			# Rotate vectors based on gradient direction
			var rotation_speed = 0.1 + gradient_strength * 0.2
			vector.rotation.z += delta * rotation_speed
			
			# Change color based on gradient magnitude
			var gradient_color = Color(0.8, 0.8, 0.2, 0.3 + gradient_strength * 0.5)
			vector.material_override.albedo_color = gradient_color
			vector.material_override.emission = Color(0.8, 0.8, 0.2, 1) * gradient_strength * 0.4

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the optimization flow
			var progress = fmod(time * 0.25 + float(i) * 0.06, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 6) * 2.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and optimization progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on optimization
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * optimization_progress
			particle.scale = Vector3.ONE * pulse

func update_optimization_metrics(delta):
	# Update loss meter (inverted - lower loss is better, so higher on meter)
	var loss_indicator = $OptimizationMetrics/LossMeter/LossIndicator
	if loss_indicator:
		var target_x = lerp(2, -2, 1.0 - loss_value)  # Invert because lower loss is better
		loss_indicator.position.x = lerp(loss_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on loss (green for low loss, red for high loss)
		var green_component = 0.8 * (1.0 - loss_value)
		var red_component = 0.2 + 0.6 * loss_value
		loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update learning rate meter
	var lr_indicator = $OptimizationMetrics/LearningRateMeter/LearningRateIndicator
	if lr_indicator:
		var normalized_lr = (learning_rate - 0.05) / 0.1  # Normalize to 0-1
		var target_x = lerp(-2, 2, normalized_lr)
		lr_indicator.position.x = lerp(lr_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on learning rate
		var blue_component = 0.8 * normalized_lr
		var red_component = 0.2 + 0.6 * (1.0 - normalized_lr)
		lr_indicator.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)

func set_optimization_progress(progress: float):
	optimization_progress = clamp(progress, 0.0, 1.0)

func set_loss_value(loss: float):
	loss_value = clamp(loss, 0.0, 1.0)

func set_learning_rate(rate: float):
	learning_rate = clamp(rate, 0.01, 1.0)

func get_optimization_progress() -> float:
	return optimization_progress

func get_loss_value() -> float:
	return loss_value

func get_learning_rate() -> float:
	return learning_rate

func reset_optimization():
	time = 0.0
	optimization_progress = 0.0
	loss_value = 1.0
	learning_rate = 0.5
