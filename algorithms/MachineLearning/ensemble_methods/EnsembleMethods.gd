extends Node3D
class_name EnsembleMethods

var time: float = 0.0
var ensemble_progress: float = 0.0
var accuracy_score: float = 0.0
var diversity_score: float = 0.0
var particle_count: int = 20
var flow_particles: Array = []
var model_particles: Array = []
var prediction_particles: Array = []
var vote_particles: Array = []

func _ready():
	# Initialize Ensemble Methods visualization
	print("Ensemble Methods Visualization initialized")
	create_model_particles()
	create_prediction_particles()
	create_vote_particles()
	create_flow_particles()
	setup_ensemble_metrics()

func _process(delta):
	time += delta
	
	# Simulate ensemble progress
	ensemble_progress = min(1.0, time * 0.1)
	accuracy_score = ensemble_progress * 0.95  # Ensembles typically have higher accuracy
	diversity_score = ensemble_progress * 0.8
	
	animate_base_models(delta)
	animate_ensemble_core(delta)
	animate_final_prediction(delta)
	animate_voting_system(delta)
	animate_data_flow(delta)
	update_ensemble_metrics(delta)

func create_model_particles():
	# Create base model particles
	var model_particles_node = $BaseModels/ModelParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		
		# Different colors for different base models
		var model_type = i % 4
		match model_type:
			0:  # Decision Tree
				particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			1:  # Random Forest
				particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			2:  # SVM
				particle.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
			3:  # Neural Network
				particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		
		particle.material_override.emission_enabled = true
		particle.material_override.emission = particle.material_override.albedo_color * 0.3
		
		# Position particles in model clusters
		var cluster = i / 5
		var pos_in_cluster = i % 5
		var angle = pos_in_cluster * PI * 2 / 5
		var radius = 1.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius + (cluster - 1) * 1.0
		var z = randf_range(-0.3, 0.3)
		particle.position = Vector3(x, y, z)
		
		model_particles_node.add_child(particle)
		model_particles.append(particle)

func create_prediction_particles():
	# Create final prediction particles
	var prediction_particles_node = $FinalPrediction/PredictionParticles
	for i in range(15):
		var particle = CSGSphere3D.new()
		particle.radius = 0.12
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position particles in final prediction arrangement
		var row = i / 5
		var col = i % 5
		var x = (col - 2) * 0.6
		var y = (row - 1) * 0.6
		var z = randf_range(-0.2, 0.2)
		particle.position = Vector3(x, y, z)
		
		prediction_particles_node.add_child(particle)
		prediction_particles.append(particle)

func create_vote_particles():
	# Create voting particles
	var votes_node = $VotingSystem/Votes
	for i in range(12):
		var particle = CSGBox3D.new()
		particle.size = Vector3(0.3, 0.3, 0.1)
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.2
		particle.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position voting particles in voting space
		var angle = float(i) / 12.0 * PI * 2
		var radius = 2.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.1, 0.1)
		particle.position = Vector3(x, y, z)
		
		votes_node.add_child(particle)
		vote_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(35):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the ensemble flow path
		var progress = float(i) / 35
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 5) * 2.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_ensemble_metrics():
	# Initialize ensemble metrics
	var accuracy_indicator = $EnsembleMetrics/AccuracyMeter/AccuracyIndicator
	var diversity_indicator = $EnsembleMetrics/DiversityMeter/DiversityIndicator
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle
	if diversity_indicator:
		diversity_indicator.position.x = 0  # Start at middle

func animate_base_models(delta):
	# Animate base model particles
	for i in range(model_particles.size()):
		var particle = model_particles[i]
		if particle:
			# Move particles in diverse model patterns
			var base_pos = particle.position
			var model_type = i % 4
			var type_offset = model_type * 0.5
			
			var move_x = base_pos.x + sin(time * (0.8 + type_offset) + i * 0.2) * 0.2
			var move_y = base_pos.y + cos(time * (1.0 + type_offset) + i * 0.15) * 0.2
			var move_z = base_pos.z + sin(time * (1.2 + type_offset) + i * 0.1) * 0.1
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on ensemble progress
			var pulse = 1.0 + sin(time * (2.0 + type_offset) + i * 0.3) * 0.2 * ensemble_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change emission based on model contribution
			var contribution = (sin(time * 1.5 + i * 0.2) * 0.5 + 0.5) * ensemble_progress
			if particle.material_override:
				particle.material_override.emission = particle.material_override.albedo_color * (0.3 + contribution * 0.4)

func animate_ensemble_core(delta):
	# Animate ensemble hub
	var ensemble_hub = $EnsembleCore/EnsembleHub
	if ensemble_hub:
		# Rotate ensemble hub
		ensemble_hub.rotation.y += delta * 0.5
		
		# Pulse based on ensemble progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * ensemble_progress
		ensemble_hub.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on ensemble
		if ensemble_hub.material_override:
			var intensity = 0.3 + ensemble_progress * 0.7
			ensemble_hub.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate ensemble method cores
	var bagging_core = $EnsembleCore/EnsembleMethods/BaggingCore
	if bagging_core:
		bagging_core.rotation.y += delta * 0.8
		var bagging_activation = sin(time * 1.5) * 0.5 + 0.5
		bagging_activation *= ensemble_progress
		
		var pulse = 1.0 + bagging_activation * 0.3
		bagging_core.scale = Vector3.ONE * pulse
		
		if bagging_core.material_override:
			var intensity = 0.3 + bagging_activation * 0.7
			bagging_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var boosting_core = $EnsembleCore/EnsembleMethods/BoostingCore
	if boosting_core:
		boosting_core.rotation.y += delta * 1.0
		var boosting_activation = cos(time * 1.8) * 0.5 + 0.5
		boosting_activation *= ensemble_progress
		
		var pulse = 1.0 + boosting_activation * 0.3
		boosting_core.scale = Vector3.ONE * pulse
		
		if boosting_core.material_override:
			var intensity = 0.3 + boosting_activation * 0.7
			boosting_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var voting_core = $EnsembleCore/EnsembleMethods/VotingCore
	if voting_core:
		voting_core.rotation.y += delta * 1.2
		var voting_activation = sin(time * 2.0) * 0.5 + 0.5
		voting_activation *= ensemble_progress
		
		var pulse = 1.0 + voting_activation * 0.3
		voting_core.scale = Vector3.ONE * pulse
		
		if voting_core.material_override:
			var intensity = 0.3 + voting_activation * 0.7
			voting_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var stacking_core = $EnsembleCore/EnsembleMethods/StackingCore
	if stacking_core:
		stacking_core.rotation.y += delta * 0.9
		var stacking_activation = cos(time * 1.6) * 0.5 + 0.5
		stacking_activation *= ensemble_progress
		
		var pulse = 1.0 + stacking_activation * 0.3
		stacking_core.scale = Vector3.ONE * pulse
		
		if stacking_core.material_override:
			var intensity = 0.3 + stacking_activation * 0.7
			stacking_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var blending_core = $EnsembleCore/EnsembleMethods/BlendingCore
	if blending_core:
		blending_core.rotation.y += delta * 1.1
		var blending_activation = sin(time * 1.7) * 0.5 + 0.5
		blending_activation *= ensemble_progress
		
		var pulse = 1.0 + blending_activation * 0.3
		blending_core.scale = Vector3.ONE * pulse
		
		if blending_core.material_override:
			var intensity = 0.3 + blending_activation * 0.7
			blending_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_final_prediction(delta):
	# Animate prediction particles
	for i in range(prediction_particles.size()):
		var particle = prediction_particles[i]
		if particle:
			# Move particles in a consensus pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.6 + i * 0.15) * 0.1
			var move_y = base_pos.y + cos(time * 0.8 + i * 0.2) * 0.1
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.1) * 0.05
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on ensemble progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.25) * 0.3 * ensemble_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on prediction confidence
			var confidence = (ensemble_progress + sin(time * 1.5 + i * 0.2) * 0.2) % 1.0
			var green_component = 0.8 * confidence
			var red_component = 0.2 + 0.6 * (1.0 - confidence)
			particle.material_override.albedo_color = Color(red_component, green_component, 0.8, 1)

func animate_voting_system(delta):
	# Animate voting system core
	var voting_core = $VotingSystem/VotingCore
	if voting_core:
		# Rotate voting system
		voting_core.rotation.y += delta * 0.3
		
		# Pulse based on ensemble progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * ensemble_progress
		voting_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on ensemble
		if voting_core.material_override:
			var intensity = 0.3 + ensemble_progress * 0.7
			voting_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate vote particles
	for i in range(vote_particles.size()):
		var vote = vote_particles[i]
		if vote:
			# Move votes in voting pattern
			var base_pos = vote.position
			var vote_strength = sin(time * 1.0 + i * 0.5) * 0.5 + 0.5
			vote_strength *= ensemble_progress
			
			var move_scale = 1.0 + vote_strength * 0.4
			vote.scale = Vector3.ONE * move_scale
			
			# Rotate votes slightly
			vote.rotation.y += delta * (0.2 + i * 0.05)
			
			# Change color based on vote confidence
			var vote_color = Color(0.8, 0.8, 0.2, 0.3 + vote_strength * 0.5)
			vote.material_override.albedo_color = vote_color
			vote.material_override.emission = Color(0.8, 0.8, 0.2, 1) * vote_strength * 0.3

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the ensemble flow
			var progress = (time * 0.25 + float(i) * 0.07) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 5) * 2.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and ensemble progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on ensemble
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * ensemble_progress
			particle.scale = Vector3.ONE * pulse

func update_ensemble_metrics(delta):
	# Update accuracy meter
	var accuracy_indicator = $EnsembleMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy_score)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy_score
		var red_component = 0.2 + 0.6 * (1.0 - accuracy_score)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update diversity meter
	var diversity_indicator = $EnsembleMetrics/DiversityMeter/DiversityIndicator
	if diversity_indicator:
		var target_x = lerp(-2, 2, diversity_score)
		diversity_indicator.position.x = lerp(diversity_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on diversity
		var green_component = 0.8 * diversity_score
		var red_component = 0.2 + 0.6 * (1.0 - diversity_score)
		diversity_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_ensemble_progress(progress: float):
	ensemble_progress = clamp(progress, 0.0, 1.0)

func set_accuracy_score(accuracy: float):
	accuracy_score = clamp(accuracy, 0.0, 1.0)

func set_diversity_score(diversity: float):
	diversity_score = clamp(diversity, 0.0, 1.0)

func get_ensemble_progress() -> float:
	return ensemble_progress

func get_accuracy_score() -> float:
	return accuracy_score

func get_diversity_score() -> float:
	return diversity_score

func reset_ensemble():
	time = 0.0
	ensemble_progress = 0.0
	accuracy_score = 0.0
	diversity_score = 0.0
