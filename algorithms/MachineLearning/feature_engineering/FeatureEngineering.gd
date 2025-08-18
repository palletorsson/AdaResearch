extends Node3D
class_name FeatureEngineering

var time: float = 0.0
var engineering_progress: float = 0.0
var feature_quality: float = 0.0
var feature_relevance: float = 0.0
var particle_count: int = 30
var flow_particles: Array = []
var raw_particles: Array = []
var engineered_particles: Array = []

func _ready():
	# Initialize Feature Engineering visualization
	print("Feature Engineering Visualization initialized")
	create_raw_particles()
	create_engineered_particles()
	create_flow_particles()
	setup_engineering_metrics()

func _process(delta):
	time += delta
	
	# Simulate engineering progress
	engineering_progress = min(1.0, time * 0.1)
	feature_quality = engineering_progress * 0.9
	feature_relevance = engineering_progress * 0.85
	
	animate_raw_features(delta)
	animate_transformation_pipeline(delta)
	animate_engineered_features(delta)
	animate_feature_selection(delta)
	animate_data_flow(delta)
	update_engineering_metrics(delta)

func create_raw_particles():
	# Create raw feature particles
	var raw_particles_node = $RawFeatures/RawParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		
		# Different colors for different feature types
		var feature_type = i % 5
		match feature_type:
			0:  # Numerical
				particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			1:  # Categorical
				particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			2:  # Binary
				particle.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
			3:  # Ordinal
				particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
			4:  # Text
				particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		
		particle.material_override.emission_enabled = true
		particle.material_override.emission = particle.material_override.albedo_color * 0.3
		
		# Position particles in raw feature space
		var grid_size = 6
		var row = i / grid_size
		var col = i % grid_size
		var x = (col - grid_size/2.0 + 0.5) * 0.5
		var y = (row - grid_size/2.0 + 0.5) * 0.5
		var z = randf_range(-0.3, 0.3)
		particle.position = Vector3(x, y, z)
		
		raw_particles_node.add_child(particle)
		raw_particles.append(particle)

func create_engineered_particles():
	# Create engineered feature particles
	var engineered_particles_node = $EngineereddFeatures/EngineeredParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position particles in engineered feature space
		var row = i / 5
		var col = i % 5
		var x = (col - 2) * 0.6
		var y = (row - 2) * 0.6
		var z = randf_range(-0.2, 0.2)
		particle.position = Vector3(x, y, z)
		
		engineered_particles_node.add_child(particle)
		engineered_particles.append(particle)

func create_flow_particles():
	# Create feature flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(35):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the engineering flow path
		var progress = float(i) / 35
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 5) * 2.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_engineering_metrics():
	# Initialize engineering metrics
	var quality_indicator = $EngineeringMetrics/QualityMeter/QualityIndicator
	var relevance_indicator = $EngineeringMetrics/RelevanceMeter/RelevanceIndicator
	if quality_indicator:
		quality_indicator.position.x = 0  # Start at middle
	if relevance_indicator:
		relevance_indicator.position.x = 0  # Start at middle

func animate_raw_features(delta):
	# Animate raw feature particles
	for i in range(raw_particles.size()):
		var particle = raw_particles[i]
		if particle:
			# Move particles in raw data patterns
			var base_pos = particle.position
			var feature_type = i % 5
			var type_offset = feature_type * 0.3
			
			var move_x = base_pos.x + sin(time * (0.8 + type_offset) + i * 0.1) * 0.1
			var move_y = base_pos.y + cos(time * (1.0 + type_offset) + i * 0.12) * 0.1
			var move_z = base_pos.z + sin(time * (1.2 + type_offset) + i * 0.08) * 0.05
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on engineering progress
			var pulse = 1.0 + sin(time * (2.0 + type_offset) + i * 0.2) * 0.2 * engineering_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change emission based on feature importance
			var importance = (sin(time * 1.5 + i * 0.15) * 0.5 + 0.5) * engineering_progress
			if particle.material_override:
				particle.material_override.emission = particle.material_override.albedo_color * (0.3 + importance * 0.4)

func animate_transformation_pipeline(delta):
	# Animate transformation pipeline core
	var pipeline_core = $TransformationPipeline/PipelineCore
	if pipeline_core:
		# Rotate pipeline
		pipeline_core.rotation.y += delta * 0.5
		
		# Pulse based on engineering progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * engineering_progress
		pipeline_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on engineering
		if pipeline_core.material_override:
			var intensity = 0.3 + engineering_progress * 0.7
			pipeline_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate transformation method cores
	var scaling_core = $TransformationPipeline/TransformationMethods/ScalingCore
	if scaling_core:
		scaling_core.rotation.y += delta * 0.8
		var scaling_activation = sin(time * 1.5) * 0.5 + 0.5
		scaling_activation *= engineering_progress
		
		var pulse = 1.0 + scaling_activation * 0.3
		scaling_core.scale = Vector3.ONE * pulse
		
		if scaling_core.material_override:
			var intensity = 0.3 + scaling_activation * 0.7
			scaling_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var normalization_core = $TransformationPipeline/TransformationMethods/NormalizationCore
	if normalization_core:
		normalization_core.rotation.y += delta * 1.0
		var normalization_activation = cos(time * 1.8) * 0.5 + 0.5
		normalization_activation *= engineering_progress
		
		var pulse = 1.0 + normalization_activation * 0.3
		normalization_core.scale = Vector3.ONE * pulse
		
		if normalization_core.material_override:
			var intensity = 0.3 + normalization_activation * 0.7
			normalization_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var encoding_core = $TransformationPipeline/TransformationMethods/EncodingCore
	if encoding_core:
		encoding_core.rotation.y += delta * 1.2
		var encoding_activation = sin(time * 2.0) * 0.5 + 0.5
		encoding_activation *= engineering_progress
		
		var pulse = 1.0 + encoding_activation * 0.3
		encoding_core.scale = Vector3.ONE * pulse
		
		if encoding_core.material_override:
			var intensity = 0.3 + encoding_activation * 0.7
			encoding_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var polynomial_core = $TransformationPipeline/TransformationMethods/PolynomialCore
	if polynomial_core:
		polynomial_core.rotation.y += delta * 0.9
		var polynomial_activation = cos(time * 1.6) * 0.5 + 0.5
		polynomial_activation *= engineering_progress
		
		var pulse = 1.0 + polynomial_activation * 0.3
		polynomial_core.scale = Vector3.ONE * pulse
		
		if polynomial_core.material_override:
			var intensity = 0.3 + polynomial_activation * 0.7
			polynomial_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var binning_core = $TransformationPipeline/TransformationMethods/BinningCore
	if binning_core:
		binning_core.rotation.y += delta * 1.1
		var binning_activation = sin(time * 1.7) * 0.5 + 0.5
		binning_activation *= engineering_progress
		
		var pulse = 1.0 + binning_activation * 0.3
		binning_core.scale = Vector3.ONE * pulse
		
		if binning_core.material_override:
			var intensity = 0.3 + binning_activation * 0.7
			binning_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_engineered_features(delta):
	# Animate engineered feature particles
	for i in range(engineered_particles.size()):
		var particle = engineered_particles[i]
		if particle:
			# Move particles in enhanced feature patterns
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.6 + i * 0.15) * 0.15
			var move_y = base_pos.y + cos(time * 0.8 + i * 0.2) * 0.15
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.1) * 0.08
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on engineering progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.25) * 0.3 * engineering_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on feature quality
			var quality = (engineering_progress + sin(time * 1.5 + i * 0.2) * 0.2) % 1.0
			var green_component = 0.8 * quality
			var red_component = 0.2 + 0.6 * (1.0 - quality)
			particle.material_override.albedo_color = Color(red_component, green_component, 0.8, 1)

func animate_feature_selection(delta):
	# Animate feature selection core
	var selection_core = $FeatureSelection/SelectionCore
	if selection_core:
		# Rotate selection system
		selection_core.rotation.y += delta * 0.3
		
		# Pulse based on engineering progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * engineering_progress
		selection_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on engineering
		if selection_core.material_override:
			var intensity = 0.3 + engineering_progress * 0.7
			selection_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate selection method cores
	var univariate_core = $FeatureSelection/SelectionMethods/UnivariateCore
	if univariate_core:
		univariate_core.rotation.y += delta * 0.7
		var univariate_activation = sin(time * 1.4) * 0.5 + 0.5
		univariate_activation *= engineering_progress
		
		var pulse = 1.0 + univariate_activation * 0.3
		univariate_core.scale = Vector3.ONE * pulse
		
		if univariate_core.material_override:
			var intensity = 0.3 + univariate_activation * 0.7
			univariate_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var recursive_core = $FeatureSelection/SelectionMethods/RecursiveCore
	if recursive_core:
		recursive_core.rotation.y += delta * 0.9
		var recursive_activation = cos(time * 1.7) * 0.5 + 0.5
		recursive_activation *= engineering_progress
		
		var pulse = 1.0 + recursive_activation * 0.3
		recursive_core.scale = Vector3.ONE * pulse
		
		if recursive_core.material_override:
			var intensity = 0.3 + recursive_activation * 0.7
			recursive_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var lasso_core = $FeatureSelection/SelectionMethods/LassoCore
	if lasso_core:
		lasso_core.rotation.y += delta * 1.1
		var lasso_activation = sin(time * 1.9) * 0.5 + 0.5
		lasso_activation *= engineering_progress
		
		var pulse = 1.0 + lasso_activation * 0.3
		lasso_core.scale = Vector3.ONE * pulse
		
		if lasso_core.material_override:
			var intensity = 0.3 + lasso_activation * 0.7
			lasso_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the engineering flow
			var progress = (time * 0.25 + float(i) * 0.07) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 5) * 2.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and engineering progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on engineering
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * engineering_progress
			particle.scale = Vector3.ONE * pulse

func update_engineering_metrics(delta):
	# Update feature quality meter
	var quality_indicator = $EngineeringMetrics/QualityMeter/QualityIndicator
	if quality_indicator:
		var target_x = lerp(-2, 2, feature_quality)
		quality_indicator.position.x = lerp(quality_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on quality
		var green_component = 0.8 * feature_quality
		var red_component = 0.2 + 0.6 * (1.0 - feature_quality)
		quality_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update feature relevance meter
	var relevance_indicator = $EngineeringMetrics/RelevanceMeter/RelevanceIndicator
	if relevance_indicator:
		var target_x = lerp(-2, 2, feature_relevance)
		relevance_indicator.position.x = lerp(relevance_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on relevance
		var green_component = 0.8 * feature_relevance
		var red_component = 0.2 + 0.6 * (1.0 - feature_relevance)
		relevance_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_engineering_progress(progress: float):
	engineering_progress = clamp(progress, 0.0, 1.0)

func set_feature_quality(quality: float):
	feature_quality = clamp(quality, 0.0, 1.0)

func set_feature_relevance(relevance: float):
	feature_relevance = clamp(relevance, 0.0, 1.0)

func get_engineering_progress() -> float:
	return engineering_progress

func get_feature_quality() -> float:
	return feature_quality

func get_feature_relevance() -> float:
	return feature_relevance

func reset_engineering():
	time = 0.0
	engineering_progress = 0.0
	feature_quality = 0.0
	feature_relevance = 0.0
