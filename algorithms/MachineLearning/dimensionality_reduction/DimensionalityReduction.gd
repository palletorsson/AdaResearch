extends Node3D
class_name DimensionalityReduction

var time: float = 0.0
var reduction_progress: float = 0.0
var variance_explained: float = 0.0
var reconstruction_error: float = 1.0
var particle_count: int = 25
var flow_particles: Array = []
var high_dim_particles: Array = []
var low_dim_particles: Array = []

func _ready():
	# Initialize Dimensionality Reduction visualization
	print("Dimensionality Reduction Visualization initialized")
	create_high_dimensional_particles()
	create_low_dimensional_particles()
	create_flow_particles()
	setup_reduction_metrics()

func _process(delta):
	time += delta
	
	# Simulate reduction progress
	reduction_progress = min(1.0, time * 0.1)
	variance_explained = reduction_progress * 0.9
	reconstruction_error = max(0.1, 1.0 - reduction_progress * 0.8)
	
	animate_high_dimensional_data(delta)
	animate_reduction_algorithm(delta)
	animate_low_dimensional_data(delta)
	animate_data_flow(delta)
	update_reduction_metrics(delta)

func create_high_dimensional_particles():
	# Create high-dimensional data particles
	var high_dim_particles_node = $HighDimensionalData/HighDimParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles in a complex 3D pattern (high-dimensional representation)
		var x = randf_range(-2, 2)
		var y = randf_range(-2, 2)
		var z = randf_range(-2, 2)
		particle.position = Vector3(x, y, z)
		
		high_dim_particles_node.add_child(particle)
		high_dim_particles.append(particle)

func create_low_dimensional_particles():
	# Create low-dimensional data particles
	var low_dim_particles_node = $LowDimensionalData/LowDimParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles in a simpler 2D pattern (low-dimensional representation)
		var x = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, 0, z)
		
		low_dim_particles_node.add_child(particle)
		low_dim_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the reduction flow path
		var progress = float(i) / 30
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 3) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_reduction_metrics():
	# Initialize reduction metrics
	var variance_indicator = $ReductionMetrics/VarianceExplained/VarianceIndicator
	var error_indicator = $ReductionMetrics/ReconstructionError/ErrorIndicator
	if variance_indicator:
		variance_indicator.position.x = 0  # Start at middle
	if error_indicator:
		error_indicator.position.x = 0  # Start at middle

func animate_high_dimensional_data(delta):
	# Animate high-dimensional particles
	for i in range(high_dim_particles.size()):
		var particle = high_dim_particles[i]
		if particle:
			# Move particles in a complex pattern
			var move_x = sin(time * 0.8 + i * 0.1) * 0.3
			var move_y = cos(time * 1.2 + i * 0.15) * 0.3
			var move_z = sin(time * 1.0 + i * 0.12) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 1.5)
			
			# Pulse particles based on reduction progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * reduction_progress
			particle.scale = Vector3.ONE * pulse

func animate_reduction_algorithm(delta):
	# Animate reduction algorithm core
	var algorithm_core = $ReductionAlgorithm/AlgorithmCore
	if algorithm_core:
		# Rotate algorithm
		algorithm_core.rotation.y += delta * 0.5
		
		# Pulse based on reduction progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * reduction_progress
		algorithm_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on reduction
		if algorithm_core.material_override:
			var intensity = 0.3 + reduction_progress * 0.7
			algorithm_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate PCA core
	var pca_core = $ReductionAlgorithm/ReductionProcess/PCACore
	if pca_core:
		pca_core.rotation.y += delta * 0.8
		var pca_activation = sin(time * 1.5) * 0.5 + 0.5
		pca_activation *= reduction_progress
		
		var pulse = 1.0 + pca_activation * 0.3
		pca_core.scale = Vector3.ONE * pulse
		
		if pca_core.material_override:
			var intensity = 0.3 + pca_activation * 0.7
			pca_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	# Animate t-SNE core
	var tsne_core = $ReductionAlgorithm/ReductionProcess/TSNECore
	if tsne_core:
		tsne_core.rotation.y += delta * 1.0
		var tsne_activation = cos(time * 1.8) * 0.5 + 0.5
		tsne_activation *= reduction_progress
		
		var pulse = 1.0 + tsne_activation * 0.3
		tsne_core.scale = Vector3.ONE * pulse
		
		if tsne_core.material_override:
			var intensity = 0.3 + tsne_activation * 0.7
			tsne_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_low_dimensional_data(delta):
	# Animate low-dimensional particles
	for i in range(low_dim_particles.size()):
		var particle = low_dim_particles[i]
		if particle:
			# Move particles in a simpler 2D pattern
			var move_x = sin(time * 0.6 + i * 0.08) * 0.2
			var move_z = cos(time * 0.8 + i * 0.1) * 0.2
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on reduction progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.15) * 0.2 * reduction_progress
			particle.scale = Vector3.ONE * pulse

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the reduction flow
			var progress = fmod(time * 0.25 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 3) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and reduction progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on reduction
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * reduction_progress
			particle.scale = Vector3.ONE * pulse

func update_reduction_metrics(delta):
	# Update variance explained meter
	var variance_indicator = $ReductionMetrics/VarianceExplained/VarianceIndicator
	if variance_indicator:
		var target_x = lerp(-2, 2, variance_explained)
		variance_indicator.position.x = lerp(variance_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on variance explained
		var green_component = 0.8 * variance_explained
		var red_component = 0.2 + 0.6 * (1.0 - variance_explained)
		variance_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update reconstruction error meter
	var error_indicator = $ReductionMetrics/ReconstructionError/ErrorIndicator
	if error_indicator:
		var target_x = lerp(-2, 2, 1.0 - reconstruction_error)
		error_indicator.position.x = lerp(error_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on reconstruction error (lower is better)
		var green_component = 0.8 * (1.0 - reconstruction_error)
		var red_component = 0.2 + 0.6 * reconstruction_error
		error_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_reduction_progress(progress: float):
	reduction_progress = clamp(progress, 0.0, 1.0)

func set_variance_explained(variance: float):
	variance_explained = clamp(variance, 0.0, 1.0)

func set_reconstruction_error(error: float):
	reconstruction_error = clamp(error, 0.1, 1.0)

func get_reduction_progress() -> float:
	return reduction_progress

func get_variance_explained() -> float:
	return variance_explained

func get_reconstruction_error() -> float:
	return reconstruction_error

func reset_reduction():
	time = 0.0
	reduction_progress = 0.0
	variance_explained = 0.0
	reconstruction_error = 1.0
